package com.civicconnect.modules.issue.dto;

import com.civicconnect.common.enums.IssueStatus;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/** Request body for PATCH /api/v1/issues/{id}/status */
@Data
public class IssueStatusUpdateRequest {

    @NotNull(message = "Status is required")
    private IssueStatus status;

    private String note;
}
