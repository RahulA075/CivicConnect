package com.civicconnect.modules.issue.controller;

import com.civicconnect.common.response.ApiResponse;
import com.civicconnect.common.response.PagedResponse;
import com.civicconnect.common.security.CurrentUser;
import com.civicconnect.modules.issue.dto.*;
import com.civicconnect.modules.issue.service.IssueService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Issue lifecycle endpoints (authenticated).
 * Base path: /api/v1/issues
 */
@RestController
@RequestMapping("/api/v1/issues")
@RequiredArgsConstructor
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Issues", description = "Issue submission, tracking, and management")
public class IssueController {

    private final IssueService issueService;

    @Operation(summary = "Submit a new civic issue report")
    @PostMapping
    @PreAuthorize("hasAnyRole('CITIZEN','FIELD_WORKER','DEPT_SUPERVISOR','MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<IssueResponse>> submit(
            @Valid @RequestBody IssueSubmitRequest request,
            @CurrentUser UserDetails principal) {
        UUID userId = UUID.fromString(principal.getUsername());
        IssueResponse response = issueService.submit(request, userId);
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.success(response, "Issue submitted successfully"));
    }

    @Operation(summary = "Get issue by ID")
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<IssueResponse>> getById(
            @PathVariable UUID id,
            @CurrentUser UserDetails principal) {
        UUID userId = principal != null ? UUID.fromString(principal.getUsername()) : null;
        return ResponseEntity.ok(ApiResponse.success(issueService.getById(id, userId)));
    }

    @Operation(summary = "Get issue by tracking ID")
    @GetMapping("/track/{trackingId}")
    public ResponseEntity<ApiResponse<IssueResponse>> getByTrackingId(
            @PathVariable String trackingId) {
        return ResponseEntity.ok(ApiResponse.success(issueService.getByTrackingId(trackingId)));
    }

    @Operation(summary = "Get current user's submitted issues")
    @GetMapping("/my")
    @PreAuthorize("hasRole('CITIZEN')")
    public ResponseEntity<ApiResponse<PagedResponse<IssueResponse>>> getMyIssues(
            @CurrentUser UserDetails principal,
            @RequestParam(defaultValue = "0")  int page,
            @RequestParam(defaultValue = "20") int size) {
        UUID userId = UUID.fromString(principal.getUsername());
        return ResponseEntity.ok(
            PagedResponse.toApiResponse(
                issueService.getMyIssues(userId, PageRequest.of(page, size,
                    Sort.by(Sort.Direction.DESC, "createdAt")))));
    }

    @Operation(summary = "Get nearby open issues for duplicate detection")
    @GetMapping("/nearby")
    public ResponseEntity<ApiResponse<List<NearbyIssueResponse>>> getNearby(
            @RequestParam double lat,
            @RequestParam double lng,
            @RequestParam(defaultValue = "200") int radius,
            @RequestParam UUID municipalityId) {
        return ResponseEntity.ok(
            ApiResponse.success(issueService.getNearby(lat, lng, radius, municipalityId)));
    }

    @Operation(summary = "Update issue status (field workers and supervisors)")
    @PatchMapping("/{id}/status")
    @PreAuthorize("hasAnyRole('FIELD_WORKER','DEPT_SUPERVISOR','MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<IssueResponse>> updateStatus(
            @PathVariable UUID id,
            @Valid @RequestBody IssueStatusUpdateRequest request,
            @CurrentUser UserDetails principal) {
        UUID userId = UUID.fromString(principal.getUsername());
        return ResponseEntity.ok(
            ApiResponse.success(issueService.updateStatus(id, request, userId)));
    }

    @Operation(summary = "Citizen verifies or rejects a resolved issue")
    @PostMapping("/{id}/verify")
    @PreAuthorize("hasRole('CITIZEN')")
    public ResponseEntity<ApiResponse<IssueResponse>> verify(
            @PathVariable UUID id,
            @Valid @RequestBody IssueVerifyRequest request,
            @CurrentUser UserDetails principal) {
        UUID userId = UUID.fromString(principal.getUsername());
        return ResponseEntity.ok(
            ApiResponse.success(issueService.verify(id, request, userId)));
    }

    @Operation(summary = "Upvote an existing issue")
    @PostMapping("/{id}/upvote")
    @PreAuthorize("hasRole('CITIZEN')")
    public ResponseEntity<ApiResponse<IssueResponse>> upvote(
            @PathVariable UUID id,
            @CurrentUser UserDetails principal) {
        UUID userId = UUID.fromString(principal.getUsername());
        return ResponseEntity.ok(ApiResponse.success(issueService.upvote(id, userId)));
    }

    @Operation(summary = "Get full status timeline for an issue")
    @GetMapping("/{id}/history")
    public ResponseEntity<ApiResponse<List<IssueStatusHistoryResponse>>> getHistory(
            @PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.success(issueService.getStatusHistory(id)));
    }
}
