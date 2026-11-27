package com.civicconnect.modules.issue.controller;

import com.civicconnect.common.response.ApiResponse;
import com.civicconnect.common.response.PagedResponse;
import com.civicconnect.modules.issue.dto.IssueResponse;
import com.civicconnect.modules.issue.entity.IssueCategory;
import com.civicconnect.modules.issue.repository.IssueCategoryRepository;
import com.civicconnect.modules.issue.service.IssueService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Public issue endpoints — no authentication required.
 * Base path: /api/v1/public/issues
 */
@RestController
@RequestMapping("/api/v1/public/issues")
@RequiredArgsConstructor
@Tag(name = "Public Issues", description = "Public issue feed — no authentication required")
public class IssuePublicController {

    private final IssueService            issueService;
    private final IssueCategoryRepository categoryRepository;

    @Operation(summary = "Public issue feed for a municipality")
    @GetMapping
    public ResponseEntity<ApiResponse<PagedResponse<IssueResponse>>> getFeed(
            @RequestParam UUID municipalityId,
            @RequestParam(required = false) String categoryId,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0")  int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(
            PagedResponse.toApiResponse(
                issueService.getPublicFeed(municipalityId, categoryId, status,
                    PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt")))));
    }

    @Operation(summary = "Get a single issue by tracking ID (public)")
    @GetMapping("/track/{trackingId}")
    public ResponseEntity<ApiResponse<IssueResponse>> getByTrackingId(
            @PathVariable String trackingId) {
        return ResponseEntity.ok(ApiResponse.success(issueService.getByTrackingId(trackingId)));
    }

    @Operation(summary = "Get issue categories for a municipality")
    @GetMapping("/categories")
    public ResponseEntity<ApiResponse<List<IssueCategory>>> getCategories(
            @RequestParam UUID municipalityId) {
        return ResponseEntity.ok(ApiResponse.success(
                categoryRepository.findTopLevelByMunicipality(municipalityId)));
    }

    @Operation(summary = "Get map issues within radius (public) — includes lat/lng for markers")
    @GetMapping("/map")
    public ResponseEntity<ApiResponse<List<com.civicconnect.modules.issue.dto.NearbyIssueResponse>>> getMapIssues(
            @RequestParam UUID   municipalityId,
            @RequestParam double lat,
            @RequestParam double lng,
            @RequestParam(defaultValue = "5000") int    radius,
            @RequestParam(required = false)      String status,
            @RequestParam(required = false)      String categoryId) {
        return ResponseEntity.ok(ApiResponse.success(
                issueService.getMapIssues(lat, lng, radius, municipalityId, status, categoryId)));
    }
}
