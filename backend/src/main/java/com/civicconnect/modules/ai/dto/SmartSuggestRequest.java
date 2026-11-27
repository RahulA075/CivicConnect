package com.civicconnect.modules.ai.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.UUID;

/**
 * Request body for POST /api/v1/ai/suggest.
 * Lightweight — used for real-time smart suggestions as the citizen types.
 */
@Data
public class SmartSuggestRequest {

    /** Partial or complete title typed by the citizen. */
    @NotBlank
    @Size(max = 300)
    private String title;

    /** Partial or complete description (may be empty early in typing). */
    @Size(max = 2000)
    private String description;

    private UUID municipalityId;
}
