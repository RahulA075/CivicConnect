package com.civicconnect.modules.ai.controller;

import com.civicconnect.common.response.ApiResponse;
import com.civicconnect.common.security.CurrentUser;
import com.civicconnect.modules.ai.dto.*;
import com.civicconnect.modules.ai.service.AiAnalysisService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * AI-powered analysis endpoints for the CivicConnect platform.
 *
 * <p>All endpoints degrade gracefully — if AI is disabled or the API key
 * is missing, they return empty/null data rather than errors.
 *
 * <p>Base path: /api/v1/ai
 */
@RestController
@RequestMapping("/api/v1/ai")
@RequiredArgsConstructor
@Tag(name = "AI Analysis", description = "AI-powered issue analysis, duplicate detection, and smart suggestions")
public class AiController {

    private final AiAnalysisService aiAnalysisService;

    // ── Full text + optional image analysis ─────────────────────────────────

    @Operation(
        summary     = "Analyse issue text (and optionally an image) with AI",
        description = "Returns category suggestion, severity, spam flag, complaint summary, and smart tips. "
                    + "Pass issueId to persist the result. Pass imageUrl for image classification."
    )
    @PostMapping("/analyze-text")
    @PreAuthorize("isAuthenticated()")
    @SecurityRequirement(name = "bearerAuth")
    public ResponseEntity<ApiResponse<AiAnalysisResponse>> analyzeText(
            @Valid @RequestBody AiTextAnalysisRequest request) {
        AiAnalysisResponse result = aiAnalysisService.analyzeText(request);
        return ResponseEntity.ok(ApiResponse.success(result, "Analysis complete"));
    }

    // ── Duplicate detection ──────────────────────────────────────────────────

    @Operation(
        summary     = "Check for duplicate issues near a location",
        description = "Finds nearby open issues and uses AI text similarity to detect duplicates. "
                    + "Call before submitting to warn citizens about existing reports."
    )
    @PostMapping("/check-duplicate")
    @PreAuthorize("isAuthenticated()")
    @SecurityRequirement(name = "bearerAuth")
    public ResponseEntity<ApiResponse<DuplicateCheckResponse>> checkDuplicate(
            @Valid @RequestBody DuplicateCheckRequest request) {
        DuplicateCheckResponse result = aiAnalysisService.checkDuplicate(request);
        return ResponseEntity.ok(ApiResponse.success(result));
    }

    // ── Smart suggestions ────────────────────────────────────────────────────

    @Operation(
        summary     = "Get smart suggestions for a partially typed issue",
        description = "Lightweight endpoint for real-time tips as the citizen types. "
                    + "No auth required — available on the public submit form."
    )
    @PostMapping("/suggest")
    public ResponseEntity<ApiResponse<List<String>>> suggest(
            @Valid @RequestBody SmartSuggestRequest request) {
        List<String> suggestions = aiAnalysisService.getSmartSuggestions(request);
        return ResponseEntity.ok(ApiResponse.success(suggestions));
    }

    // ── Get stored analysis for an issue ────────────────────────────────────

    @Operation(
        summary     = "Get stored AI analysis for a specific issue",
        description = "Returns previously computed AI analysis results. Returns null if not yet analysed."
    )
    @GetMapping("/issues/{issueId}/analysis")
    @PreAuthorize("isAuthenticated()")
    @SecurityRequirement(name = "bearerAuth")
    public ResponseEntity<ApiResponse<AiAnalysisResponse>> getAnalysis(
            @PathVariable UUID issueId) {
        AiAnalysisResponse result = aiAnalysisService.getAnalysisForIssue(issueId);
        return ResponseEntity.ok(ApiResponse.success(result));
    }

    // ── Trigger re-analysis ──────────────────────────────────────────────────

    @Operation(
        summary     = "Re-trigger AI analysis for an existing issue",
        description = "Admin/supervisor endpoint to re-run AI analysis on an issue (e.g. after image upload)."
    )
    @PostMapping("/issues/{issueId}/re-analyze")
    @PreAuthorize("hasAnyRole('DEPT_SUPERVISOR','MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    @SecurityRequirement(name = "bearerAuth")
    public ResponseEntity<ApiResponse<Void>> reAnalyze(
            @PathVariable UUID issueId) {
        aiAnalysisService.analyzeIssueAsync(issueId);
        return ResponseEntity.accepted()
            .body(ApiResponse.ok("AI re-analysis triggered"));
    }
}
