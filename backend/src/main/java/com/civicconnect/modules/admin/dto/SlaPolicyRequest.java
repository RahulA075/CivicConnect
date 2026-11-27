package com.civicconnect.modules.admin.dto;

import com.civicconnect.common.enums.IssuePriority;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.util.UUID;

@Data
public class SlaPolicyRequest {
    private UUID          categoryId;        // null = applies to all categories
    @NotNull private IssuePriority priority;
    @Min(1)  private int  resolutionHours;
    @Min(1)  private int  warningHours;
    @Min(1)  private int  escalationHours;
}
