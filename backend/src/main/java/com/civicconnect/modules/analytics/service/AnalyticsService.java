package com.civicconnect.modules.analytics.service;

import com.civicconnect.modules.analytics.dto.DashboardSummaryResponse;
import com.civicconnect.modules.analytics.dto.HeatmapDataResponse;
import com.civicconnect.modules.analytics.dto.IssueTrendResponse;

import java.time.LocalDate;
import java.util.UUID;

/** Analytics service contract. */
public interface AnalyticsService {
    DashboardSummaryResponse getDashboardSummary(UUID municipalityId);
    HeatmapDataResponse      getHeatmapData(UUID municipalityId, LocalDate from, LocalDate to);
    IssueTrendResponse       getIssueTrend(UUID municipalityId, int days, UUID departmentId);
}
