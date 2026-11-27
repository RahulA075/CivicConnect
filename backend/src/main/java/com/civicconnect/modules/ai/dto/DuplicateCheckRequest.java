package com.civicconnect.modules.ai.dto;

import jakarta.validation.constraints.*;
import lombok.Data;

import java.util.UUID;

/**
 * Request body for POST /api/v1/ai/check-duplicate.
 * Client sends this during issue composition, before submitting.
 */
@Data
public class DuplicateCheckRequest {

    @NotBlank(message = "Title is required")
    @Size(max = 300)
    private String title;

    @NotBlank(message = "Description is required")
    @Size(max = 2000)
    private String description;

    @NotNull(message = "Latitude is required")
    @DecimalMin("-90.0") @DecimalMax("90.0")
    private Double latitude;

    @NotNull(message = "Longitude is required")
    @DecimalMin("-180.0") @DecimalMax("180.0")
    private Double longitude;

    @NotNull(message = "Municipality ID is required")
    private UUID municipalityId;

    /**
     * Search radius in metres — how far to look for existing similar issues.
     * Default 500 m is suitable for urban areas.
     */
    @Positive
    private int radiusMetres = 500;
}
