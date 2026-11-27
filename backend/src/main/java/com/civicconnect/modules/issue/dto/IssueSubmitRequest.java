package com.civicconnect.modules.issue.dto;

import com.civicconnect.common.enums.IssuePriority;
import jakarta.validation.constraints.*;
import lombok.Data;

/** Request body for POST /api/v1/issues */
@Data
public class IssueSubmitRequest {

    @NotNull(message = "Category ID is required")
    private java.util.UUID categoryId;

    @NotBlank(message = "Title is required")
    @Size(min = 5, max = 300, message = "Title must be 5–300 characters")
    private String title;

    @NotBlank(message = "Description is required")
    @Size(min = 10, max = 2000, message = "Description must be 10–2000 characters")
    private String description;

    @NotNull(message = "Latitude is required")
    @DecimalMin(value = "-90.0",  message = "Latitude must be ≥ -90")
    @DecimalMax(value = "90.0",   message = "Latitude must be ≤ 90")
    private Double latitude;

    @NotNull(message = "Longitude is required")
    @DecimalMin(value = "-180.0", message = "Longitude must be ≥ -180")
    @DecimalMax(value = "180.0",  message = "Longitude must be ≤ 180")
    private Double longitude;

    private String addressText;

    private IssuePriority priority = IssuePriority.MEDIUM;

    private boolean anonymous = false;
}
