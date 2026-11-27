package com.civicconnect.modules.ai.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.UUID;

/**
 * Request body for POST /api/v1/ai/analyze-text.
 * Sent before or after issue submission to get AI suggestions.
 */
@Data
public class AiTextAnalysisRequest {

    /** The issue title being analysed. */
    @NotBlank(message = "Title is required")
    @Size(max = 300, message = "Title must be ≤ 300 characters")
    private String title;

    /** The issue description being analysed. */
    @NotBlank(message = "Description is required")
    @Size(max = 2000, message = "Description must be ≤ 2000 characters")
    private String description;

    /**
     * Municipality ID — used to scope category suggestions to the correct
     * set of categories configured for that municipality.
     */
    private UUID municipalityId;

    /**
     * Optional issue ID — if provided, the analysis is persisted to the
     * {@code ai_issue_analysis} table for this issue.
     */
    private UUID issueId;

    /**
     * Optional image CDN URL — if provided, the image is also sent to the
     * vision model for label extraction.
     */
    private String imageUrl;
}
