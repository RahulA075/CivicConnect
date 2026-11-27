package com.civicconnect.modules.admin.controller;

import com.civicconnect.common.response.ApiResponse;
import com.civicconnect.common.response.PagedResponse;
import com.civicconnect.common.security.CurrentUser;
import com.civicconnect.modules.admin.dto.*;
import com.civicconnect.modules.admin.entity.Municipality;
import com.civicconnect.modules.admin.service.*;
import com.civicconnect.modules.iam.dto.UserResponse;
import com.civicconnect.modules.iam.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Platform and municipality administration endpoints.
 * Base path: /api/v1/admin
 */
@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Admin", description = "Municipality, department and user management")
public class AdminController {

    private final MunicipalityService    municipalityService;
    private final DepartmentService      departmentService;
    private final UserService            userService;
    private final SlaPolicyService       slaPolicyService;
    private final EscalationRuleService  escalationRuleService;
    private final CategoryAdminService   categoryAdminService;
    private final EmergencyAlertService  emergencyAlertService;
    private final AuditLogService        auditLogService;

    // ── Municipalities ─────────────────────────────────────────────────────────

    @Operation(summary = "List all municipalities (SYSTEM_ADMIN)")
    @GetMapping("/municipalities")
    @PreAuthorize("hasRole('SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<PagedResponse<Municipality>>> getMunicipalities(
            @RequestParam(defaultValue = "0")  int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(
            PagedResponse.toApiResponse(
                municipalityService.getAll(PageRequest.of(page, size))));
    }

    @Operation(summary = "Get municipality by ID")
    @GetMapping("/municipalities/{id}")
    @PreAuthorize("hasAnyRole('MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<Municipality>> getMunicipality(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.success(municipalityService.getById(id)));
    }

    // ── Departments ────────────────────────────────────────────────────────────

    @Operation(summary = "List departments for a municipality")
    @GetMapping("/municipalities/{municipalityId}/departments")
    @PreAuthorize("hasAnyRole('DEPT_SUPERVISOR','MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<List<DepartmentResponse>>> getDepartments(
            @PathVariable UUID municipalityId) {
        // Map entities to DTOs
        var depts = departmentService.getByMunicipality(municipalityId).stream()
                .map(d -> DepartmentResponse.builder()
                        .id(d.getId())
                        .municipalityId(d.getMunicipality().getId())
                        .name(d.getName())
                        .description(d.getDescription())
                        .iconName(d.getIconName())
                        .colorHex(d.getColorHex())
                        .contactEmail(d.getContactEmail())
                        .contactPhone(d.getContactPhone())
                        .active(d.isActive())
                        .build())
                .toList();
        return ResponseEntity.ok(ApiResponse.success(depts));
    }

    @Operation(summary = "Get department by ID")
    @GetMapping("/departments/{id}")
    @PreAuthorize("hasAnyRole('DEPT_SUPERVISOR','MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<DepartmentResponse>> getDepartment(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.success(departmentService.getById(id)));
    }

    @Operation(summary = "Create a department in a municipality")
    @PostMapping("/municipalities/{municipalityId}/departments")
    @PreAuthorize("hasAnyRole('MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<DepartmentResponse>> createDepartment(
            @PathVariable UUID municipalityId,
            @Valid @RequestBody CreateDepartmentRequest request,
            @CurrentUser UserDetails principal,
            HttpServletRequest httpRequest) {
        UUID performedBy = UUID.fromString(principal.getUsername());
        DepartmentResponse dept = departmentService.create(request, municipalityId, performedBy);
        auditLogService.log(municipalityId, performedBy, principal.getUsername(),
                "CREATE_DEPARTMENT", "Department", dept.getId().toString(),
                "Created department: " + dept.getName(), httpRequest.getRemoteAddr());
        return ResponseEntity.ok(ApiResponse.success(dept));
    }

    @Operation(summary = "Update a department")
    @PutMapping("/departments/{id}")
    @PreAuthorize("hasAnyRole('MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<DepartmentResponse>> updateDepartment(
            @PathVariable UUID id,
            @Valid @RequestBody CreateDepartmentRequest request,
            @CurrentUser UserDetails principal,
            HttpServletRequest httpRequest) {
        UUID performedBy = UUID.fromString(principal.getUsername());
        DepartmentResponse dept = departmentService.update(id, request, performedBy);
        auditLogService.log(dept.getMunicipalityId(), performedBy, principal.getUsername(),
                "UPDATE_DEPARTMENT", "Department", id.toString(),
                "Updated department: " + dept.getName(), httpRequest.getRemoteAddr());
        return ResponseEntity.ok(ApiResponse.success(dept));
    }

    @Operation(summary = "Deactivate a department")
    @PostMapping("/departments/{id}/deactivate")
    @PreAuthorize("hasAnyRole('MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deactivateDepartment(
            @PathVariable UUID id,
            @CurrentUser UserDetails principal,
            HttpServletRequest httpRequest) {
        UUID performedBy = UUID.fromString(principal.getUsername());
        departmentService.deactivate(id, performedBy);
        auditLogService.log(null, performedBy, principal.getUsername(),
                "DEACTIVATE_DEPARTMENT", "Department", id.toString(),
                null, httpRequest.getRemoteAddr());
        return ResponseEntity.ok(ApiResponse.ok("Department deactivated"));
    }

    // ── Authority Users ────────────────────────────────────────────────────────

    @Operation(summary = "List authority users for a municipality")
    @GetMapping("/municipalities/{municipalityId}/users")
    @PreAuthorize("hasAnyRole('MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<PagedResponse<UserResponse>>> getUsers(
            @PathVariable UUID municipalityId,
            @RequestParam(required = false) UUID departmentId,
            @RequestParam(defaultValue = "0")  int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(
            PagedResponse.toApiResponse(
                userService.getAuthorityUsers(municipalityId, departmentId,
                    PageRequest.of(page, size))));
    }

    @Operation(summary = "Invite a new officer or supervisor account")
    @PostMapping("/municipalities/{municipalityId}/users/invite")
    @PreAuthorize("hasAnyRole('MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<UserResponse>> inviteUser(
            @PathVariable UUID municipalityId,
            @Valid @RequestBody InviteUserRequest request,
            @CurrentUser UserDetails principal,
            HttpServletRequest httpRequest) {
        UUID performedBy = UUID.fromString(principal.getUsername());
        UserResponse user = userService.inviteUser(municipalityId, request, performedBy);
        auditLogService.log(municipalityId, performedBy, principal.getUsername(),
                "INVITE_USER", "User", user.getId().toString(),
                "Invited user: " + user.getEmail() + " role=" + user.getRole(),
                httpRequest.getRemoteAddr());
        return ResponseEntity.ok(ApiResponse.success(user));
    }

    @Operation(summary = "Deactivate a user account")
    @PostMapping("/users/{userId}/deactivate")
    @PreAuthorize("hasAnyRole('MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deactivateUser(
            @PathVariable UUID userId,
            @CurrentUser UserDetails principal,
            HttpServletRequest httpRequest) {
        UUID performedBy = UUID.fromString(principal.getUsername());
        userService.deactivateUser(userId, performedBy);
        auditLogService.log(null, performedBy, principal.getUsername(),
                "DEACTIVATE_USER", "User", userId.toString(),
                null, httpRequest.getRemoteAddr());
        return ResponseEntity.ok(ApiResponse.ok("User deactivated"));
    }

    @Operation(summary = "Reactivate a user account")
    @PostMapping("/users/{userId}/reactivate")
    @PreAuthorize("hasAnyRole('MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<Void>> reactivateUser(
            @PathVariable UUID userId,
            @CurrentUser UserDetails principal,
            HttpServletRequest httpRequest) {
        UUID performedBy = UUID.fromString(principal.getUsername());
        userService.reactivateUser(userId, performedBy);
        auditLogService.log(null, performedBy, principal.getUsername(),
                "REACTIVATE_USER", "User", userId.toString(),
                null, httpRequest.getRemoteAddr());
        return ResponseEntity.ok(ApiResponse.ok("User reactivated"));
    }

    // ── Categories ─────────────────────────────────────────────────────────────

    @Operation(summary = "List issue categories for a municipality")
    @GetMapping("/municipalities/{municipalityId}/categories")
    @PreAuthorize("hasAnyRole('MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<List<CategoryResponse>>> getCategories(
            @PathVariable UUID municipalityId) {
        return ResponseEntity.ok(
                ApiResponse.success(categoryAdminService.getByMunicipality(municipalityId)));
    }

    @Operation(summary = "Create an issue category")
    @PostMapping("/municipalities/{municipalityId}/categories")
    @PreAuthorize("hasAnyRole('MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<CategoryResponse>> createCategory(
            @PathVariable UUID municipalityId,
            @Valid @RequestBody CategoryRequest request,
            @CurrentUser UserDetails principal,
            HttpServletRequest httpRequest) {
        UUID performedBy = UUID.fromString(principal.getUsername());
        CategoryResponse cat = categoryAdminService.create(municipalityId, request, performedBy);
        auditLogService.log(municipalityId, performedBy, principal.getUsername(),
                "CREATE_CATEGORY", "IssueCategory", cat.getId().toString(),
                "Created category: " + cat.getName(), httpRequest.getRemoteAddr());
        return ResponseEntity.ok(ApiResponse.success(cat));
    }

    @Operation(summary = "Update an issue category")
    @PutMapping("/categories/{id}")
    @PreAuthorize("hasAnyRole('MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<CategoryResponse>> updateCategory(
            @PathVariable UUID id,
            @Valid @RequestBody CategoryRequest request,
            @CurrentUser UserDetails principal,
            HttpServletRequest httpRequest) {
        UUID performedBy = UUID.fromString(principal.getUsername());
        CategoryResponse cat = categoryAdminService.update(id, request, performedBy);
        auditLogService.log(cat.getMunicipalityId(), performedBy, principal.getUsername(),
                "UPDATE_CATEGORY", "IssueCategory", id.toString(),
                "Updated category: " + cat.getName(), httpRequest.getRemoteAddr());
        return ResponseEntity.ok(ApiResponse.success(cat));
    }

    @Operation(summary = "Deactivate an issue category")
    @PostMapping("/categories/{id}/deactivate")
    @PreAuthorize("hasAnyRole('MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deactivateCategory(
            @PathVariable UUID id,
            @CurrentUser UserDetails principal,
            HttpServletRequest httpRequest) {
        UUID performedBy = UUID.fromString(principal.getUsername());
        categoryAdminService.deactivate(id, performedBy);
        auditLogService.log(null, performedBy, principal.getUsername(),
                "DEACTIVATE_CATEGORY", "IssueCategory", id.toString(),
                null, httpRequest.getRemoteAddr());
        return ResponseEntity.ok(ApiResponse.ok("Category deactivated"));
    }

    // ── SLA Policies ───────────────────────────────────────────────────────────

    @Operation(summary = "List SLA policies for a municipality")
    @GetMapping("/municipalities/{municipalityId}/sla-policies")
    @PreAuthorize("hasAnyRole('MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<List<SlaPolicyResponse>>> getSlaPolicies(
            @PathVariable UUID municipalityId) {
        return ResponseEntity.ok(
                ApiResponse.success(slaPolicyService.getByMunicipality(municipalityId)));
    }

    @Operation(summary = "Create an SLA policy")
    @PostMapping("/municipalities/{municipalityId}/sla-policies")
    @PreAuthorize("hasAnyRole('MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<SlaPolicyResponse>> createSlaPolicy(
            @PathVariable UUID municipalityId,
            @Valid @RequestBody SlaPolicyRequest request,
            @CurrentUser UserDetails principal,
            HttpServletRequest httpRequest) {
        UUID performedBy = UUID.fromString(principal.getUsername());
        SlaPolicyResponse policy = slaPolicyService.create(municipalityId, request, performedBy);
        auditLogService.log(municipalityId, performedBy, principal.getUsername(),
                "CREATE_SLA_POLICY", "SlaPolicy", policy.getId().toString(),
                "Created SLA policy priority=" + policy.getPriority(), httpRequest.getRemoteAddr());
        return ResponseEntity.ok(ApiResponse.success(policy));
    }

    @Operation(summary = "Update an SLA policy")
    @PutMapping("/sla-policies/{id}")
    @PreAuthorize("hasAnyRole('MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<SlaPolicyResponse>> updateSlaPolicy(
            @PathVariable UUID id,
            @Valid @RequestBody SlaPolicyRequest request,
            @CurrentUser UserDetails principal,
            HttpServletRequest httpRequest) {
        UUID performedBy = UUID.fromString(principal.getUsername());
        SlaPolicyResponse policy = slaPolicyService.update(id, request, performedBy);
        auditLogService.log(policy.getMunicipalityId(), performedBy, principal.getUsername(),
                "UPDATE_SLA_POLICY", "SlaPolicy", id.toString(),
                null, httpRequest.getRemoteAddr());
        return ResponseEntity.ok(ApiResponse.success(policy));
    }

    @Operation(summary = "Deactivate an SLA policy")
    @PostMapping("/sla-policies/{id}/deactivate")
    @PreAuthorize("hasAnyRole('MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deactivateSlaPolicy(
            @PathVariable UUID id,
            @CurrentUser UserDetails principal,
            HttpServletRequest httpRequest) {
        UUID performedBy = UUID.fromString(principal.getUsername());
        slaPolicyService.deactivate(id, performedBy);
        auditLogService.log(null, performedBy, principal.getUsername(),
                "DEACTIVATE_SLA_POLICY", "SlaPolicy", id.toString(),
                null, httpRequest.getRemoteAddr());
        return ResponseEntity.ok(ApiResponse.ok("SLA policy deactivated"));
    }

    // ── Escalation Rules ───────────────────────────────────────────────────────

    @Operation(summary = "List escalation rules for a municipality")
    @GetMapping("/municipalities/{municipalityId}/escalation-rules")
    @PreAuthorize("hasAnyRole('MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<List<EscalationRuleResponse>>> getEscalationRules(
            @PathVariable UUID municipalityId) {
        return ResponseEntity.ok(
                ApiResponse.success(escalationRuleService.getByMunicipality(municipalityId)));
    }

    @Operation(summary = "Create an escalation rule")
    @PostMapping("/municipalities/{municipalityId}/escalation-rules")
    @PreAuthorize("hasAnyRole('MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<EscalationRuleResponse>> createEscalationRule(
            @PathVariable UUID municipalityId,
            @Valid @RequestBody EscalationRuleRequest request,
            @CurrentUser UserDetails principal,
            HttpServletRequest httpRequest) {
        UUID performedBy = UUID.fromString(principal.getUsername());
        EscalationRuleResponse rule = escalationRuleService.create(municipalityId, request, performedBy);
        auditLogService.log(municipalityId, performedBy, principal.getUsername(),
                "CREATE_ESCALATION_RULE", "EscalationRule", rule.getId().toString(),
                "Trigger after " + rule.getTriggerAfterHours() + "h → " + rule.getEscalateToRole(),
                httpRequest.getRemoteAddr());
        return ResponseEntity.ok(ApiResponse.success(rule));
    }

    @Operation(summary = "Update an escalation rule")
    @PutMapping("/escalation-rules/{id}")
    @PreAuthorize("hasAnyRole('MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<EscalationRuleResponse>> updateEscalationRule(
            @PathVariable UUID id,
            @Valid @RequestBody EscalationRuleRequest request,
            @CurrentUser UserDetails principal,
            HttpServletRequest httpRequest) {
        UUID performedBy = UUID.fromString(principal.getUsername());
        EscalationRuleResponse rule = escalationRuleService.update(id, request, performedBy);
        auditLogService.log(rule.getMunicipalityId(), performedBy, principal.getUsername(),
                "UPDATE_ESCALATION_RULE", "EscalationRule", id.toString(),
                null, httpRequest.getRemoteAddr());
        return ResponseEntity.ok(ApiResponse.success(rule));
    }

    @Operation(summary = "Deactivate an escalation rule")
    @PostMapping("/escalation-rules/{id}/deactivate")
    @PreAuthorize("hasAnyRole('MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deactivateEscalationRule(
            @PathVariable UUID id,
            @CurrentUser UserDetails principal,
            HttpServletRequest httpRequest) {
        UUID performedBy = UUID.fromString(principal.getUsername());
        escalationRuleService.deactivate(id, performedBy);
        auditLogService.log(null, performedBy, principal.getUsername(),
                "DEACTIVATE_ESCALATION_RULE", "EscalationRule", id.toString(),
                null, httpRequest.getRemoteAddr());
        return ResponseEntity.ok(ApiResponse.ok("Escalation rule deactivated"));
    }

    // ── Emergency Alerts ───────────────────────────────────────────────────────

    @Operation(summary = "List emergency alerts for a municipality")
    @GetMapping("/municipalities/{municipalityId}/alerts")
    @PreAuthorize("hasAnyRole('DEPT_SUPERVISOR','MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<PagedResponse<EmergencyAlertResponse>>> getAlerts(
            @PathVariable UUID municipalityId,
            @RequestParam(defaultValue = "false") boolean activeOnly,
            @RequestParam(defaultValue = "0")  int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(
                PagedResponse.toApiResponse(
                        emergencyAlertService.getByMunicipality(municipalityId, activeOnly,
                                PageRequest.of(page, size, Sort.by("createdAt").descending()))));
    }

    @Operation(summary = "Broadcast an emergency alert")
    @PostMapping("/municipalities/{municipalityId}/alerts")
    @PreAuthorize("hasAnyRole('MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<EmergencyAlertResponse>> createAlert(
            @PathVariable UUID municipalityId,
            @Valid @RequestBody EmergencyAlertRequest request,
            @CurrentUser UserDetails principal,
            HttpServletRequest httpRequest) {
        UUID performedBy = UUID.fromString(principal.getUsername());
        EmergencyAlertResponse alert = emergencyAlertService.create(municipalityId, request, performedBy);
        auditLogService.log(municipalityId, performedBy, principal.getUsername(),
                "SEND_EMERGENCY_ALERT", "EmergencyAlert", alert.getId().toString(),
                "Alert: " + alert.getTitle() + " severity=" + alert.getSeverity(),
                httpRequest.getRemoteAddr());
        return ResponseEntity.ok(ApiResponse.success(alert));
    }

    @Operation(summary = "Deactivate / cancel an emergency alert")
    @PostMapping("/alerts/{id}/deactivate")
    @PreAuthorize("hasAnyRole('MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deactivateAlert(
            @PathVariable UUID id,
            @CurrentUser UserDetails principal,
            HttpServletRequest httpRequest) {
        UUID performedBy = UUID.fromString(principal.getUsername());
        emergencyAlertService.deactivate(id, performedBy);
        auditLogService.log(null, performedBy, principal.getUsername(),
                "DEACTIVATE_ALERT", "EmergencyAlert", id.toString(),
                null, httpRequest.getRemoteAddr());
        return ResponseEntity.ok(ApiResponse.ok("Alert deactivated"));
    }

    // ── Audit Logs ─────────────────────────────────────────────────────────────

    @Operation(summary = "Search audit logs for a municipality")
    @GetMapping("/municipalities/{municipalityId}/audit-logs")
    @PreAuthorize("hasAnyRole('MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<PagedResponse<AuditLogResponse>>> getAuditLogs(
            @PathVariable UUID municipalityId,
            @RequestParam(required = false) String action,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant to,
            @RequestParam(defaultValue = "0")  int page,
            @RequestParam(defaultValue = "50") int size) {
        return ResponseEntity.ok(
                PagedResponse.toApiResponse(
                        auditLogService.search(municipalityId, action, from, to,
                                PageRequest.of(page, size))));
    }

    // ── CSV Export ─────────────────────────────────────────────────────────────

    @Operation(summary = "Export audit logs as CSV")
    @GetMapping("/municipalities/{municipalityId}/audit-logs/export")
    @PreAuthorize("hasAnyRole('MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public void exportAuditLogsCsv(
            @PathVariable UUID municipalityId,
            @RequestParam(required = false) String action,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant to,
            HttpServletResponse response) throws Exception {

        response.setContentType("text/csv; charset=UTF-8");
        response.setHeader(HttpHeaders.CONTENT_DISPOSITION,
                "attachment; filename=\"audit-logs.csv\"");
        response.setCharacterEncoding(StandardCharsets.UTF_8.name());

        var logs = auditLogService.search(municipalityId, action, from, to,
                PageRequest.of(0, 10_000));

        try (PrintWriter writer = response.getWriter()) {
            writer.println("id,performedBy,action,entityType,entityId,detail,ipAddress,createdAt");
            for (var log : logs) {
                writer.printf("%s,%s,%s,%s,%s,\"%s\",%s,%s%n",
                        safe(log.getId()),
                        safe(log.getPerformedByName()),
                        safe(log.getAction()),
                        safe(log.getEntityType()),
                        safe(log.getEntityId()),
                        safe(log.getDetail()),
                        safe(log.getIpAddress()),
                        log.getCreatedAt() != null ? log.getCreatedAt().toString() : "");
            }
        }
    }

    // ── Helper ─────────────────────────────────────────────────────────────────

    private String safe(Object val) {
        return val == null ? "" : val.toString().replace("\"", "\"\"");
    }
}
