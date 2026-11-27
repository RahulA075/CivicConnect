package com.civicconnect.modules.analytics.dto;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class DashboardSummaryResponse {
    private long   totalOpen;
    private long   totalInProgress;
    private long   totalResolved;
    private long   totalOverdue;
    private long   totalClosed;
    private double avgCitizenRating;
    private List<DepartmentStatDto> departmentStats;

    @Data
    @Builder
    public static class DepartmentStatDto {
        private String departmentName;
        private long   openCount;
        private long   overdueCount;
        private double slaCompliancePct;
        private double avgResolutionHours;
    }
}
