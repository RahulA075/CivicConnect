package com.civicconnect.modules.issue.dto;

import com.civicconnect.common.enums.IssueStatus;
import com.civicconnect.common.enums.UserRole;
import lombok.Builder;
import lombok.Data;

import java.time.Instant;
import java.util.UUID;

/** One entry in an issue's status history timeline. */
@Data
@Builder
public class IssueStatusHistoryResponse {
    private UUID        id;
    private IssueStatus oldStatus;
    private IssueStatus newStatus;
    private String      changedByName;
    private UserRole    changedByRole;
    private String      note;
    private Instant     createdAt;
}
