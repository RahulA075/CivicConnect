package com.civicconnect.modules.admin.dto;

import com.civicconnect.common.enums.UserRole;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.util.UUID;

@Data
public class EscalationRuleRequest {
    private UUID     departmentId;
    @Min(1) private int triggerAfterHours;
    @NotNull private UserRole escalateToRole;
    private String   notificationMessage;
}
