package com.civicconnect.modules.admin.dto;

import lombok.Builder;
import lombok.Data;
import java.time.Instant;
import java.util.UUID;

@Data @Builder
public class AuditLogResponse {
    private UUID    id;
    private UUID    performedById;
    private String  performedByName;
    private String  action;           // e.g. "DEACTIVATE_USER", "CREATE_DEPARTMENT"
    private String  entityType;       // e.g. "User", "Department"
    private String  entityId;
    private String  detail;
    private String  ipAddress;
    private Instant createdAt;
}
