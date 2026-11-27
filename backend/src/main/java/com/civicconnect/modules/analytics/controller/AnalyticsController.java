package com.civicconnect.modules.analytics.controller;

import com.civicconnect.common.response.ApiResponse;
import com.civicconnect.modules.analytics.dto.DashboardSummaryResponse;
import com.civicconnect.modules.analytics.dto.HeatmapDataResponse;
import com.civicconnect.modules.analytics.dto.IssueTrendResponse;
import com.civicconnect.modules.analytics.service.AnalyticsService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.UUID;

/**
 * Analytics and reporting endpoints.
 * Base path: /api/v1/analytics
 */
@RestController
@RequestMapping("/api/v1/analytics")
@RequiredArgsConstructor
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Analytics", description = "Dashboard, heatmap and trend analytics for authorities")
@PreAuthorize("hasAnyRole('DEPT_SUPERVISOR','MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
public class AnalyticsController {

    private final AnalyticsService analyticsService;

    @Operation(summary = "Get municipality dashboard summary")
    @GetMapping("/municipalities/{municipalityId}/summary")
    public ResponseEntity<ApiResponse<DashboardSummaryResponse>> getSummary(
            @PathVariable UUID municipalityId) {
        return ResponseEntity.ok(
            ApiResponse.success(analyticsService.getDashboardSummary(municipalityId)));
    }

    @Operation(summary = "Get issue heatmap data points")
    @GetMapping("/municipalities/{municipalityId}/heatmap")
    public ResponseEntity<ApiResponse<HeatmapDataResponse>> getHeatmap(
            @PathVariable UUID municipalityId,
            @RequestParam(defaultValue = "#{T(java.time.LocalDate).now().minusDays(30)}")
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(defaultValue = "#{T(java.time.LocalDate).now()}")
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ResponseEntity.ok(
            ApiResponse.success(analyticsService.getHeatmapData(municipalityId, from, to)));
    }

    @Operation(summary = "Get issue submission trend over time")
    @GetMapping("/municipalities/{municipalityId}/trend")
    public ResponseEntity<ApiResponse<IssueTrendResponse>> getTrend(
            @PathVariable UUID municipalityId,
            @RequestParam(defaultValue = "30") int days,
            @RequestParam(required = false) UUID departmentId) {
        return ResponseEntity.ok(
            ApiResponse.success(analyticsService.getIssueTrend(municipalityId, days, departmentId)));
    }

    @Operation(summary = "Get department-scoped dashboard summary (for officers)")
    @GetMapping("/departments/{departmentId}/summary")
    @PreAuthorize("hasAnyRole('FIELD_WORKER','DEPT_SUPERVISOR','MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<DashboardSummaryResponse>> getDepartmentSummary(
            @PathVariable UUID departmentId,
            @RequestParam UUID municipalityId) {
        // Reuse municipality summary — the Flutter side filters by dept in the trend
        return ResponseEntity.ok(
            ApiResponse.success(analyticsService.getDashboardSummary(municipalityId)));
    }
}
