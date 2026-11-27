package com.civicconnect.modules.issue.dto;

import jakarta.validation.constraints.*;
import lombok.Data;

/** Request body for POST /api/v1/issues/{id}/verify */
@Data
public class IssueVerifyRequest {

    @NotNull(message = "resolved field is required")
    private Boolean resolved;

    /** Required when resolved=false (citizen rejection) */
    private String rejectionReason;

    @Min(1) @Max(5)
    private Integer rating;

    private String comment;
}
