package com.civicconnect.modules.ai.dto;

import com.civicconnect.common.enums.IssuePriority;
import lombok.Builder;
import lombok.Data;

import java.util.List;
import java.util.UUID;

/**
 * AI analysis result returned to the Flutter client.
 * All fields are nullable — clients must handle partial results gracefully.
 */
@Data
@Builder
public class AiAnalysisResponse {

    // ── Category suggestion ───────────────────────────────────────────────
    private UUID    suggestedCategoryId;
    private String  suggestedCategoryName;
    /** 0.0–1.0 confidence. Show suggestion in UI only if ≥ 0.6. */
    private Double  categoryConfidence;

    // ── Severity / priority ───────────────────────────────────────────────
    private IssuePriority suggestedPriority;
    private Double        severityConfidence;
    /** Human-readable reasoning, e.g. "Blocked road poses traffic safety risk." */
    private String        severityReasoning;

    // ── Duplicate detection ───────────────────────────────────────────────
    private boolean             potentialDuplicate;
    private UUID                duplicateOfIssueId;
    private String              duplicateOfTrackingId;
    private String              duplicateOfTitle;
    private Double              duplicateSimilarity;

    // ── Spam detection ────────────────────────────────────────────────────
    private boolean spamFlagged;
    private Double  spamConfidence;
    private String  spamReason;

    // ── Image classification ──────────────────────────────────────────────
    /** Ordered by confidence descending. */
    private List<ImageLabel> imageLabels;
    /** Best category name inferred from the image alone. */
    private String           imageCategoryHint;

    // ── AI summary ────────────────────────────────────────────────────────
    /** 2–3 sentence summary of the complaint for officer quick-read. */
    private String complaintSummary;

    // ── Smart suggestions ─────────────────────────────────────────────────
    /** 1–3 actionable tips shown to the citizen on the submission form. */
    private List<String> smartSuggestions;

    // ── Meta ──────────────────────────────────────────────────────────────
    private String modelUsed;
    private int    analysisDurationMs;

    @Data
    @Builder
    public static class ImageLabel {
        private String label;
        private double confidence;
    }
}
