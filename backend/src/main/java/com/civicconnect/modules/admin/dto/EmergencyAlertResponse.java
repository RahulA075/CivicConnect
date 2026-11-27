package com.civicconnect.modules.admin.dto;

import lombok.Builder;
import lombok.Data;
import java.time.Instant;
import java.util.UUID;

@Data @Builder
public class EmergencyAlertResponse {
    private UUID    id;
    private UUID    municipalityId;
    private UUID    targetDepartmentId;
    private String  departmentName;
    private String  title;
    private String  message;
    private String  severity;
    private boolean active;
    private UUID    createdById;
    private String  createdByName;
    private Instant createdAt;
    private Instant expiresAt;
}
