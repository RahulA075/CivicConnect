package com.civicconnect.modules.operations.controller;

import com.civicconnect.common.response.ApiResponse;
import com.civicconnect.common.security.CurrentUser;
import com.civicconnect.modules.issue.dto.IssueResponse;
import com.civicconnect.modules.issue.dto.IssueStatusUpdateRequest;
import com.civicconnect.modules.issue.service.IssueService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Field worker task management endpoints.
 * Base path: /api/v1/field-worker
 */
@RestController
@RequestMapping("/api/v1/field-worker")
@RequiredArgsConstructor
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Field Worker", description = "Task list and status update for field workers")
@PreAuthorize("hasAnyRole('FIELD_WORKER','DEPT_SUPERVISOR','MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
public class FieldWorkerController {

    private final IssueService issueService;

    @Operation(summary = "Get my assigned tasks")
    @GetMapping("/tasks")
    public ResponseEntity<ApiResponse<List<IssueResponse>>> getMyTasks(
            @CurrentUser UserDetails principal) {
        UUID userId = UUID.fromString(principal.getUsername());
        return ResponseEntity.ok(ApiResponse.success(issueService.getTasksForWorker(userId)));
    }

    @Operation(summary = "Update status of an assigned task")
    @PatchMapping("/tasks/{issueId}/status")
    public ResponseEntity<ApiResponse<IssueResponse>> updateTaskStatus(
            @PathVariable UUID issueId,
            @Valid @RequestBody IssueStatusUpdateRequest request,
            @CurrentUser UserDetails principal) {
        UUID userId = UUID.fromString(principal.getUsername());
        return ResponseEntity.ok(
            ApiResponse.success(issueService.updateStatus(issueId, request, userId)));
    }
}
