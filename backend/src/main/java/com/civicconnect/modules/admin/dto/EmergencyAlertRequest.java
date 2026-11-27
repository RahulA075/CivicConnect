package com.civicconnect.modules.admin.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.time.Instant;
import java.util.UUID;

@Data
public class EmergencyAlertRequest {
    @NotBlank private String  title;
    @NotBlank private String  message;
    @NotNull  private String  severity;   // LOW | MEDIUM | HIGH | CRITICAL
    private UUID     targetDepartmentId;  // null = broadcast to whole municipality
    private Instant  expiresAt;
}
