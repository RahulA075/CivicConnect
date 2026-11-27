package com.civicconnect.modules.operations.controller;

import com.civicconnect.common.response.ApiResponse;
import com.civicconnect.common.response.PagedResponse;
import com.civicconnect.common.security.CurrentUser;
import com.civicconnect.modules.iam.dto.WorkerResponse;
import com.civicconnect.modules.iam.entity.User;
import com.civicconnect.modules.iam.repository.UserRepository;
import com.civicconnect.modules.issue.dto.IssueResponse;
import com.civicconnect.modules.issue.dto.IssueStatusUpdateRequest;
import com.civicconnect.modules.issue.service.IssueService;
import com.civicconnect.modules.operations.dto.AssignRequest;
import com.civicconnect.modules.operations.dto.EscalateRequest;
import com.civicconnect.modules.operations.service.AssignmentService;
import com.civicconnect.common.enums.IssueStatus;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Department supervisor operations — queue management, assignment, escalation.
 * Base path: /api/v1/operations
 */
@RestController
@RequestMapping("/api/v1/operations")
@RequiredArgsConstructor
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Operations", description = "Supervisor issue queue, assignment and escalation")
public class OperationsController {

    private final IssueService      issueService;
    private final AssignmentService assignmentService;
    private final UserRepository    userRepository;

    @Operation(summary = "Get department issue queue")
    @GetMapping("/departments/{departmentId}/issues")
    @PreAuthorize("hasAnyRole('DEPT_SUPERVISOR','MUNICIPAL_ADMIN','SYSTEM_ADMIN','FIELD_WORKER')")
    public ResponseEntity<ApiResponse<PagedResponse<IssueResponse>>> getDepartmentQueue(
            @PathVariable UUID departmentId,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0")  int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(
            PagedResponse.toApiResponse(
                issueService.getByDepartment(departmentId, status,
                    PageRequest.of(page, size, Sort.by(Sort.Direction.ASC, "slaDeadline")))));
    }

    @Operation(summary = "Assign issue to a field worker")
    @PostMapping("/issues/{issueId}/assign")
    @PreAuthorize("hasAnyRole('DEPT_SUPERVISOR','MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<IssueResponse>> assign(
            @PathVariable UUID issueId,
            @Valid @RequestBody AssignRequest request,
            @CurrentUser UserDetails principal) {
        UUID userId = UUID.fromString(principal.getUsername());
        return ResponseEntity.ok(ApiResponse.success(
            issueService.assign(issueId, request.getAssignedToId(), userId, request.getNote())));
    }

    @Operation(summary = "Accept a submitted issue (move to IN_PROGRESS)")
    @PostMapping("/issues/{issueId}/accept")
    @PreAuthorize("hasAnyRole('FIELD_WORKER','DEPT_SUPERVISOR','MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<IssueResponse>> accept(
            @PathVariable UUID issueId,
            @CurrentUser UserDetails principal) {
        UUID userId = UUID.fromString(principal.getUsername());
        var req = new IssueStatusUpdateRequest();
        req.setStatus(IssueStatus.IN_PROGRESS);
        req.setNote("Accepted by officer");
        return ResponseEntity.ok(ApiResponse.success(
            issueService.updateStatus(issueId, req, userId)));
    }

    @Operation(summary = "Escalate an issue")
    @PostMapping("/issues/{issueId}/escalate")
    @PreAuthorize("hasAnyRole('FIELD_WORKER','DEPT_SUPERVISOR','MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<Void>> escalate(
            @PathVariable UUID issueId,
            @Valid @RequestBody EscalateRequest request,
            @CurrentUser UserDetails principal) {
        UUID userId = UUID.fromString(principal.getUsername());
        assignmentService.escalate(issueId, userId, request.getReason());
        return ResponseEntity.ok(ApiResponse.ok("Issue escalated"));
    }

    @Operation(summary = "Reject an issue with a mandatory reason")
    @PostMapping("/issues/{issueId}/reject")
    @PreAuthorize("hasAnyRole('DEPT_SUPERVISOR','MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<Void>> reject(
            @PathVariable UUID issueId,
            @Valid @RequestBody EscalateRequest request,
            @CurrentUser UserDetails principal) {
        UUID userId = UUID.fromString(principal.getUsername());
        assignmentService.reject(issueId, userId, request.getReason());
        return ResponseEntity.ok(ApiResponse.ok("Issue rejected"));
    }

    @Operation(summary = "Merge a duplicate issue into a primary issue")
    @PostMapping("/issues/{primaryId}/merge/{duplicateId}")
    @PreAuthorize("hasAnyRole('DEPT_SUPERVISOR','MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<Void>> merge(
            @PathVariable UUID primaryId,
            @PathVariable UUID duplicateId,
            @CurrentUser UserDetails principal) {
        UUID userId = UUID.fromString(principal.getUsername());
        issueService.merge(primaryId, duplicateId, userId);
        return ResponseEntity.ok(ApiResponse.ok("Issues merged"));
    }

    @Operation(summary = "List field workers in a department")
    @GetMapping("/departments/{departmentId}/workers")
    @PreAuthorize("hasAnyRole('DEPT_SUPERVISOR','MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<List<WorkerResponse>>> getWorkers(
            @PathVariable UUID departmentId,
            @RequestParam UUID municipalityId) {
        List<WorkerResponse> workers = userRepository
                .findAuthorityUsers(municipalityId, departmentId, PageRequest.of(0, 100))
                .stream()
                .map(u -> WorkerResponse.builder()
                        .id(u.getId())
                        .fullName(u.getFullName())
                        .email(u.getEmail())
                        .role(u.getRole().getName().name())
                        .avatarUrl(u.getAvatarUrl())
                        .build())
                .collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.success(workers));
    }
}
