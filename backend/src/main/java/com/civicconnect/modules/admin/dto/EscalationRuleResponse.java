package com.civicconnect.modules.admin.dto;

import com.civicconnect.common.enums.UserRole;
import lombok.Builder;
import lombok.Data;
import java.util.UUID;

@Data @Builder
public class EscalationRuleResponse {
    private UUID     id;
    private UUID     municipalityId;
    private UUID     departmentId;
    private String   departmentName;
    private int      triggerAfterHours;
    private UserRole escalateToRole;
    private String   notificationMessage;
    private boolean  active;
}
