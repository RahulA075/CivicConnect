package com.civicconnect.modules.analytics.dto;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class HeatmapDataResponse {
    private List<HeatmapPoint> points;

    @Data
    @Builder
    public static class HeatmapPoint {
        private double latitude;
        private double longitude;
        private int    weight;
    }
}
