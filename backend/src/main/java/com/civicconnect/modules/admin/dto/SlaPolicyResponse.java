package com.civicconnect.modules.admin.dto;

import com.civicconnect.common.enums.IssuePriority;
import lombok.Builder;
import lombok.Data;
import java.util.UUID;

@Data @Builder
public class SlaPolicyResponse {
    private UUID          id;
    private UUID          municipalityId;
    private UUID          categoryId;
    private String        categoryName;
    private IssuePriority priority;
    private int           resolutionHours;
    private int           warningHours;
    private int           escalationHours;
    private boolean       active;
}
