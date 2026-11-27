package com.civicconnect.modules.analytics.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDate;
import java.util.List;

@Data
@Builder
public class IssueTrendResponse {
    private List<TrendPoint> data;

    @Data
    @Builder
    public static class TrendPoint {
        private LocalDate day;
        private long      submitted;
        private long      resolved;
        private long      overdueCount;
    }
}
