package com.civicconnect.modules.ai.service;

import com.civicconnect.common.enums.IssuePriority;
import com.civicconnect.config.AppProperties;
import com.civicconnect.modules.ai.client.OpenAiClient;
import com.civicconnect.modules.ai.dto.*;
import com.civicconnect.modules.ai.entity.AiIssueAnalysis;
import com.civicconnect.modules.ai.repository.AiIssueAnalysisRepository;
import com.civicconnect.modules.issue.entity.Issue;
import com.civicconnect.modules.issue.entity.IssueCategory;
import com.civicconnect.modules.issue.repository.IssueCategoryRepository;
import com.civicconnect.modules.issue.repository.IssueRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import jakarta.persistence.criteria.Predicate;
import java.time.Instant;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class AiAnalysisServiceImpl implements AiAnalysisService {

    private final OpenAiClient               openAiClient;
    private final AiIssueAnalysisRepository  analysisRepository;
    private final IssueRepository            issueRepository;
    private final IssueCategoryRepository    categoryRepository;
    private final ObjectMapper               objectMapper;
    private final AppProperties              appProperties;

    // ── Full text + optional image analysis ─────────────────────────────────

    @Override
    @Transactional
    public AiAnalysisResponse analyzeText(AiTextAnalysisRequest request) {
        long start = System.currentTimeMillis();
        AppProperties.Ai cfg = appProperties.getAi();

        if (!cfg.isEnabled()) {
            return buildDisabledResponse();
        }

        // Load categories for the municipality to give the model valid options
        List<IssueCategory> categories = request.getMunicipalityId() != null
            ? categoryRepository.findActiveCategoriesForMunicipality(request.getMunicipalityId())
            : List.of();

        String categoryList = buildCategoryList(categories);

        // ── 1. Text analysis (category + severity + spam + summary + suggestions) ──
        String textPrompt = buildTextAnalysisPrompt(request.getTitle(),
                request.getDescription(), categoryList);
        String textResult = openAiClient.chat(cfg.getTextModel(), textAnalysisSystemPrompt(), textPrompt);

        // ── 2. Image analysis (if URL provided) ─────────────────────────────────
        String imageResult = null;
        if (StringUtils.hasText(request.getImageUrl())) {
            imageResult = openAiClient.vision(
                cfg.getVisionModel(),
                imageAnalysisSystemPrompt(),
                "Analyse this civic complaint image.",
                request.getImageUrl());
        }

        // ── 3. Parse responses ───────────────────────────────────────────────────
        AiAnalysisResponse response = parseTextAnalysis(textResult, categories);
        if (imageResult != null) {
            mergeImageAnalysis(response, parseImageAnalysis(imageResult));
        }

        int durationMs = (int) (System.currentTimeMillis() - start);
        response.setModelUsed(cfg.getTextModel());
        response.setAnalysisDurationMs(durationMs);

        // ── 4. Persist if issueId is provided ────────────────────────────────────
        if (request.getIssueId() != null) {
            persistAnalysis(request.getIssueId(), response, durationMs, cfg.getTextModel());
        }

        return response;
    }

    // ── Duplicate check ──────────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public DuplicateCheckResponse checkDuplicate(DuplicateCheckRequest request) {
        if (!appProperties.getAi().isEnabled()) {
            return DuplicateCheckResponse.builder()
                .hasPotentialDuplicates(false)
                .candidates(List.of())
                .build();
        }

        // 1. Load nearby open issues (bounding-box approximation)
        double delta = request.getRadiusMetres() / 111_320.0;
        Specification<Issue> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            predicates.add(cb.equal(root.get("municipality").get("id"), request.getMunicipalityId()));
            predicates.add(cb.isNull(root.get("deletedAt")));
            predicates.add(cb.isFalse(root.get("merged")));
            predicates.add(cb.notEqual(root.get("status"),
                com.civicconnect.common.enums.IssueStatus.CLOSED));
            predicates.add(cb.notEqual(root.get("status"),
                com.civicconnect.common.enums.IssueStatus.REJECTED));
            return cb.and(predicates.toArray(new Predicate[0]));
        };

        List<Issue> nearbyIssues = issueRepository.findAll(spec).stream()
            .filter(i -> {
                double iLat = i.getLocation().getY();
                double iLng = i.getLocation().getX();
                return Math.abs(iLat - request.getLatitude()) <= delta
                    && Math.abs(iLng - request.getLongitude()) <= delta;
            })
            .limit(appProperties.getAi().getDuplicateCheckMaxCandidates())
            .toList();

        if (nearbyIssues.isEmpty()) {
            return DuplicateCheckResponse.builder()
                .hasPotentialDuplicates(false)
                .candidates(List.of())
                .build();
        }

        // 2. Ask AI to score each candidate
        String prompt = buildDuplicateCheckPrompt(request.getTitle(),
                request.getDescription(), nearbyIssues);
        String result = openAiClient.chat(appProperties.getAi().getTextModel(),
                duplicateCheckSystemPrompt(), prompt);

        List<DuplicateCheckResponse.Candidate> candidates = parseDuplicateResult(result, nearbyIssues);
        return DuplicateCheckResponse.builder()
            .hasPotentialDuplicates(!candidates.isEmpty())
            .candidates(candidates)
            .build();
    }

    // ── Smart suggestions ────────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public List<String> getSmartSuggestions(SmartSuggestRequest request) {
        if (!appProperties.getAi().isEnabled()) return List.of();

        String prompt = String.format("""
            Title: %s
            Description: %s
            Provide 2-3 concise tips to improve this civic complaint report.
            Return JSON: {"suggestions": ["tip1","tip2"]}
            """, request.getTitle(),
            StringUtils.hasText(request.getDescription()) ? request.getDescription() : "(not yet typed)");

        String result = openAiClient.chat(appProperties.getAi().getTextModel(),
            "You are a helpful assistant for a civic issue reporting app. " +
            "Give short, actionable tips to help citizens submit better reports. " +
            "Return only valid JSON.", prompt);

        return parseSmartSuggestions(result);
    }

    // ── Get stored analysis ──────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public AiAnalysisResponse getAnalysisForIssue(UUID issueId) {
        return analysisRepository.findByIssueId(issueId)
            .map(this::toResponse)
            .orElse(null);
    }

    // ── Async post-submit analysis ───────────────────────────────────────────

    @Override
    @Async("taskExecutor")
    @Transactional
    public void analyzeIssueAsync(UUID issueId) {
        if (!appProperties.getAi().isEnabled()) return;

        try {
            Issue issue = issueRepository.findActiveById(issueId).orElse(null);
            if (issue == null) {
                log.warn("AI async analysis: issue {} not found", issueId);
                return;
            }

            log.debug("Starting async AI analysis for issue {}", issueId);

            // Get the first evidence image URL if available
            String imageUrl = null;
            // (media module not yet wired — future hook point)

            AiTextAnalysisRequest req = new AiTextAnalysisRequest();
            req.setTitle(issue.getTitle());
            req.setDescription(issue.getDescription());
            req.setMunicipalityId(issue.getMunicipality().getId());
            req.setIssueId(issueId);
            req.setImageUrl(imageUrl);

            AiAnalysisResponse result = analyzeText(req);

            // Auto-apply high-confidence category if the category wasn't already manually set
            if (result.getSuggestedCategoryId() != null
                    && result.getCategoryConfidence() != null
                    && result.getCategoryConfidence() >= appProperties.getAi().getAutoApplyConfidenceThreshold()) {
                categoryRepository.findById(result.getSuggestedCategoryId()).ifPresent(cat -> {
                    issue.setCategory(cat);
                    if (cat.getDepartment() != null) issue.setDepartment(cat.getDepartment());
                    issueRepository.save(issue);
                    log.info("AI auto-applied category '{}' to issue {} (confidence: {})",
                        cat.getName(), issueId, result.getCategoryConfidence());

                    analysisRepository.findByIssueId(issueId).ifPresent(a -> {
                        a.setCategoryAutoApplied(true);
                        analysisRepository.save(a);
                    });
                });
            }

            // Auto-apply high-confidence priority
            if (result.getSuggestedPriority() != null
                    && result.getSeverityConfidence() != null
                    && result.getSeverityConfidence() >= appProperties.getAi().getAutoApplyConfidenceThreshold()) {
                issue.setPriority(result.getSuggestedPriority());
                issueRepository.save(issue);
                log.info("AI auto-applied priority {} to issue {} (confidence: {})",
                    result.getSuggestedPriority(), issueId, result.getSeverityConfidence());

                analysisRepository.findByIssueId(issueId).ifPresent(a -> {
                    a.setPriorityAutoApplied(true);
                    analysisRepository.save(a);
                });
            }

            log.info("Async AI analysis completed for issue {} in {}ms",
                issueId, result.getAnalysisDurationMs());

        } catch (Exception e) {
            log.error("Async AI analysis failed for issue {}: {}", issueId, e.getMessage(), e);
        }
    }

    // ── Prompt builders ──────────────────────────────────────────────────────

    private String textAnalysisSystemPrompt() {
        return """
            You are an AI assistant for a civic issue reporting platform used by municipal governments.
            Analyse citizen-submitted complaints and respond ONLY with valid JSON.
            Do not include any explanation outside the JSON object.
            """;
    }

    private String imageAnalysisSystemPrompt() {
        return """
            You are an AI assistant for a civic issue reporting platform.
            Analyse the provided image of a civic complaint and return ONLY valid JSON.
            """;
    }

    private String duplicateCheckSystemPrompt() {
        return """
            You are an AI assistant that detects duplicate civic complaints.
            Compare the new complaint against existing ones and return ONLY valid JSON.
            """;
    }

    private String buildTextAnalysisPrompt(String title, String description, String categoryList) {
        return String.format("""
            Analyse this civic complaint:
            Title: %s
            Description: %s

            Available categories: %s

            Return JSON with this exact structure:
            {
              "suggestedCategoryName": "string or null",
              "categoryConfidence": 0.0-1.0,
              "suggestedPriority": "LOW|MEDIUM|HIGH|CRITICAL",
              "severityConfidence": 0.0-1.0,
              "severityReasoning": "1-2 sentence explanation",
              "isSpam": false,
              "spamConfidence": 0.0-1.0,
              "spamReason": "string or null",
              "complaintSummary": "2-3 sentence summary for officers",
              "smartSuggestions": ["tip1", "tip2"]
            }

            Spam criteria: test data, profanity, clearly fictional, or irrelevant content.
            Priority criteria: CRITICAL=immediate safety risk, HIGH=significant disruption,
            MEDIUM=notable issue, LOW=minor inconvenience.
            """, title, description, categoryList);
    }

    private String buildDuplicateCheckPrompt(String title, String description,
                                              List<Issue> candidates) {
        StringBuilder sb = new StringBuilder();
        sb.append("New complaint:\n");
        sb.append("Title: ").append(title).append("\n");
        sb.append("Description: ").append(description).append("\n\n");
        sb.append("Existing open issues:\n");

        for (int i = 0; i < candidates.size(); i++) {
            Issue c = candidates.get(i);
            sb.append(String.format("[%d] trackingId=%s title=\"%s\" description=\"%s\"\n",
                i + 1, c.getTrackingId(), c.getTitle(),
                c.getDescription().substring(0, Math.min(200, c.getDescription().length()))));
        }

        sb.append("""
            \nReturn JSON with candidates that have similarity score >= 0.6:
            {
              "duplicates": [
                {
                  "index": 1,
                  "similarityScore": 0.0-1.0,
                  "reason": "explanation"
                }
              ]
            }
            Return empty array if no strong matches.
            """);

        return sb.toString();
    }

    private String buildCategoryList(List<IssueCategory> categories) {
        if (categories.isEmpty()) return "(no categories available)";
        return categories.stream()
            .map(c -> c.getName() + (c.getDescription() != null ? " (" + c.getDescription() + ")" : ""))
            .collect(Collectors.joining(", "));
    }

    // ── Response parsers ─────────────────────────────────────────────────────

    private AiAnalysisResponse parseTextAnalysis(String json, List<IssueCategory> categories) {
        AiAnalysisResponse.AiAnalysisResponseBuilder builder = AiAnalysisResponse.builder();

        if (json == null) {
            log.warn("AI returned null — returning empty analysis");
            return builder.smartSuggestions(List.of()).imageLabels(List.of()).build();
        }

        try {
            JsonNode node = objectMapper.readTree(extractJson(json));

            // Category matching — find by name
            String catName = nullableString(node, "suggestedCategoryName");
            if (catName != null) {
                categories.stream()
                    .filter(c -> c.getName().equalsIgnoreCase(catName))
                    .findFirst()
                    .ifPresent(c -> {
                        builder.suggestedCategoryId(c.getId());
                        builder.suggestedCategoryName(c.getName());
                    });
                if (!StringUtils.hasText(catName)) builder.suggestedCategoryName(catName);
            }
            builder.categoryConfidence(nullableDouble(node, "categoryConfidence"));

            // Priority
            String priority = nullableString(node, "suggestedPriority");
            if (priority != null) {
                try { builder.suggestedPriority(IssuePriority.valueOf(priority.toUpperCase())); }
                catch (IllegalArgumentException ignored) { builder.suggestedPriority(IssuePriority.MEDIUM); }
            }
            builder.severityConfidence(nullableDouble(node, "severityConfidence"));
            builder.severityReasoning(nullableString(node, "severityReasoning"));

            // Spam
            boolean spam = node.has("isSpam") && node.get("isSpam").asBoolean(false);
            builder.spamFlagged(spam);
            builder.spamConfidence(nullableDouble(node, "spamConfidence"));
            builder.spamReason(nullableString(node, "spamReason"));

            // Summary
            builder.complaintSummary(nullableString(node, "complaintSummary"));

            // Smart suggestions
            List<String> suggestions = new ArrayList<>();
            if (node.has("smartSuggestions") && node.get("smartSuggestions").isArray()) {
                for (JsonNode s : node.get("smartSuggestions")) {
                    suggestions.add(s.asText());
                }
            }
            builder.smartSuggestions(suggestions);
            builder.imageLabels(List.of());

        } catch (Exception e) {
            log.error("Failed to parse AI text analysis response: {}", e.getMessage());
            builder.smartSuggestions(List.of()).imageLabels(List.of());
        }

        return builder.build();
    }

    private AiAnalysisResponse.AiAnalysisResponseBuilder parseImageAnalysis(String json) {
        AiAnalysisResponse.AiAnalysisResponseBuilder builder = AiAnalysisResponse.builder();

        if (json == null) return builder.imageLabels(List.of());

        try {
            JsonNode node = objectMapper.readTree(extractJson(json));
            List<AiAnalysisResponse.ImageLabel> labels = new ArrayList<>();

            if (node.has("labels") && node.get("labels").isArray()) {
                for (JsonNode labelNode : node.get("labels")) {
                    labels.add(AiAnalysisResponse.ImageLabel.builder()
                        .label(labelNode.has("label") ? labelNode.get("label").asText() : "")
                        .confidence(labelNode.has("confidence") ? labelNode.get("confidence").asDouble(0) : 0)
                        .build());
                }
            }
            builder.imageLabels(labels);
            builder.imageCategoryHint(nullableString(node, "categoryHint"));

        } catch (Exception e) {
            log.error("Failed to parse AI image analysis response: {}", e.getMessage());
            builder.imageLabels(List.of());
        }

        return builder;
    }

    private void mergeImageAnalysis(AiAnalysisResponse target,
                                     AiAnalysisResponse.AiAnalysisResponseBuilder imageBuilder) {
        AiAnalysisResponse imageResult = imageBuilder.build();
        if (imageResult.getImageLabels() != null) {
            target.setImageLabels(imageResult.getImageLabels());
        }
        if (imageResult.getImageCategoryHint() != null) {
            target.setImageCategoryHint(imageResult.getImageCategoryHint());
        }
    }

    private List<DuplicateCheckResponse.Candidate> parseDuplicateResult(String json,
                                                                          List<Issue> candidates) {
        if (json == null) return List.of();

        try {
            JsonNode node = objectMapper.readTree(extractJson(json));
            List<DuplicateCheckResponse.Candidate> result = new ArrayList<>();

            if (node.has("duplicates") && node.get("duplicates").isArray()) {
                for (JsonNode d : node.get("duplicates")) {
                    int idx = d.has("index") ? d.get("index").asInt(0) - 1 : -1;
                    double score = d.has("similarityScore") ? d.get("similarityScore").asDouble(0) : 0;
                    String reason = d.has("reason") ? d.get("reason").asText() : "";

                    if (idx >= 0 && idx < candidates.size() && score >= 0.6) {
                        Issue candidate = candidates.get(idx);
                        double dist = haversine(
                            candidate.getLocation().getY(), candidate.getLocation().getX(), 0, 0);
                        result.add(DuplicateCheckResponse.Candidate.builder()
                            .trackingId(candidate.getTrackingId())
                            .issueId(candidate.getId().toString())
                            .title(candidate.getTitle())
                            .status(candidate.getStatus().name())
                            .latitude(candidate.getLocation().getY())
                            .longitude(candidate.getLocation().getX())
                            .distanceMetres(dist)
                            .similarityScore(score)
                            .reason(reason)
                            .build());
                    }
                }
            }
            return result;

        } catch (Exception e) {
            log.error("Failed to parse AI duplicate check response: {}", e.getMessage());
            return List.of();
        }
    }

    private List<String> parseSmartSuggestions(String json) {
        if (json == null) return List.of();
        try {
            JsonNode node = objectMapper.readTree(extractJson(json));
            if (node.has("suggestions") && node.get("suggestions").isArray()) {
                List<String> suggestions = new ArrayList<>();
                for (JsonNode s : node.get("suggestions")) {
                    suggestions.add(s.asText());
                }
                return suggestions;
            }
        } catch (Exception e) {
            log.error("Failed to parse smart suggestions: {}", e.getMessage());
        }
        return List.of();
    }

    // ── Persistence helpers ──────────────────────────────────────────────────

    @Transactional
    protected void persistAnalysis(UUID issueId, AiAnalysisResponse response,
                                    int durationMs, String model) {
        try {
            // Upsert — find existing or create new
            AiIssueAnalysis entity = analysisRepository.findByIssueId(issueId)
                .orElse(AiIssueAnalysis.builder().issueId(issueId).build());

            entity.setSuggestedCategoryId(response.getSuggestedCategoryId());
            entity.setSuggestedCategoryName(response.getSuggestedCategoryName());
            entity.setCategoryConfidence(response.getCategoryConfidence());
            entity.setSuggestedPriority(response.getSuggestedPriority());
            entity.setSeverityConfidence(response.getSeverityConfidence());
            entity.setSeverityReasoning(response.getSeverityReasoning());
            entity.setPotentialDuplicate(response.isPotentialDuplicate());
            entity.setDuplicateOfIssueId(response.getDuplicateOfIssueId());
            entity.setDuplicateSimilarity(response.getDuplicateSimilarity());
            entity.setSpamFlagged(response.isSpamFlagged());
            entity.setSpamConfidence(response.getSpamConfidence());
            entity.setSpamReason(response.getSpamReason());
            entity.setComplaintSummary(response.getComplaintSummary());
            entity.setModelUsed(model);
            entity.setAnalysisDurationMs(durationMs);
            entity.setAnalyzedAt(Instant.now());
            entity.setUpdatedAt(Instant.now());

            // Serialize JSONB fields
            if (response.getImageLabels() != null) {
                entity.setImageLabelsJson(objectMapper.writeValueAsString(response.getImageLabels()));
            }
            if (response.getSmartSuggestions() != null) {
                entity.setSmartSuggestionsJson(objectMapper.writeValueAsString(response.getSmartSuggestions()));
            }

            analysisRepository.save(entity);
            log.debug("Persisted AI analysis for issue {}", issueId);

        } catch (JsonProcessingException e) {
            log.error("Failed to serialize AI analysis for persistence: {}", e.getMessage());
        }
    }

    private AiAnalysisResponse toResponse(AiIssueAnalysis entity) {
        List<AiAnalysisResponse.ImageLabel> labels = List.of();
        List<String> suggestions = List.of();

        try {
            if (StringUtils.hasText(entity.getImageLabelsJson())
                    && !entity.getImageLabelsJson().equals("[]")) {
                labels = objectMapper.readValue(entity.getImageLabelsJson(),
                    new TypeReference<>() {});
            }
            if (StringUtils.hasText(entity.getSmartSuggestionsJson())
                    && !entity.getSmartSuggestionsJson().equals("[]")) {
                suggestions = objectMapper.readValue(entity.getSmartSuggestionsJson(),
                    new TypeReference<>() {});
            }
        } catch (JsonProcessingException e) {
            log.error("Failed to deserialize AI analysis JSONB: {}", e.getMessage());
        }

        return AiAnalysisResponse.builder()
            .suggestedCategoryId(entity.getSuggestedCategoryId())
            .suggestedCategoryName(entity.getSuggestedCategoryName())
            .categoryConfidence(entity.getCategoryConfidence())
            .suggestedPriority(entity.getSuggestedPriority())
            .severityConfidence(entity.getSeverityConfidence())
            .severityReasoning(entity.getSeverityReasoning())
            .potentialDuplicate(entity.isPotentialDuplicate())
            .duplicateOfIssueId(entity.getDuplicateOfIssueId())
            .duplicateSimilarity(entity.getDuplicateSimilarity())
            .spamFlagged(entity.isSpamFlagged())
            .spamConfidence(entity.getSpamConfidence())
            .spamReason(entity.getSpamReason())
            .complaintSummary(entity.getComplaintSummary())
            .imageLabels(labels)
            .imageCategoryHint(entity.getImageCategoryHint())
            .smartSuggestions(suggestions)
            .modelUsed(entity.getModelUsed())
            .analysisDurationMs(entity.getAnalysisDurationMs() != null ? entity.getAnalysisDurationMs() : 0)
            .build();
    }

    private AiAnalysisResponse buildDisabledResponse() {
        return AiAnalysisResponse.builder()
            .imageLabels(List.of())
            .smartSuggestions(List.of())
            .build();
    }

    // ── Utilities ────────────────────────────────────────────────────────────

    /**
     * Extracts the JSON object from AI output that may contain markdown code fences.
     */
    private String extractJson(String raw) {
        if (raw == null) return "{}";
        String trimmed = raw.trim();
        // Strip markdown code fences if present (```json ... ```)
        if (trimmed.startsWith("```")) {
            int start = trimmed.indexOf('\n');
            int end   = trimmed.lastIndexOf("```");
            if (start != -1 && end > start) {
                return trimmed.substring(start + 1, end).trim();
            }
        }
        return trimmed;
    }

    private String nullableString(JsonNode node, String field) {
        return node.has(field) && !node.get(field).isNull()
            ? node.get(field).asText() : null;
    }

    private Double nullableDouble(JsonNode node, String field) {
        return node.has(field) && !node.get(field).isNull()
            ? node.get(field).asDouble() : null;
    }

    private static double haversine(double lat1, double lng1, double lat2, double lng2) {
        final double R = 6_371_000.0;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLng = Math.toRadians(lng2 - lng1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLng / 2) * Math.sin(dLng / 2);
        return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }
}
