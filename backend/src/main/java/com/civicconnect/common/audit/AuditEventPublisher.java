package com.civicconnect.common.audit;

import com.civicconnect.modules.admin.service.AuditLogService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.util.UUID;

/**
 * Central helper for publishing audit log entries from any service layer class.
 *
 * <p>All calls are fire-and-forget ({@code @Async}) — they never block the
 * business transaction that triggered them.
 *
 * <p>Resolves the client IP automatically from the current HTTP request when
 * no explicit IP is supplied.
 */
@Component
@RequiredArgsConstructor
public class AuditEventPublisher {

    private final AuditLogService auditLogService;

    // ── Auth events ────────────────────────────────────────────────────────────

    @Async("taskExecutor")
    public void loginSuccess(UUID userId, String userName, UUID municipalityId) {
        auditLogService.log(municipalityId, userId, userName,
            "LOGIN_SUCCESS", "User", userId.toString(),
            "Successful login", resolveIp());
    }

    @Async("taskExecutor")
    public void loginFailure(String identifier) {
        auditLogService.log(null, null, identifier,
            "LOGIN_FAILURE", "User", null,
            "Failed login attempt for: " + identifier, resolveIp());
    }

    @Async("taskExecutor")
    public void logout(UUID userId, String userName, UUID municipalityId) {
        auditLogService.log(municipalityId, userId, userName,
            "LOGOUT", "User", userId.toString(),
            "User logged out", resolveIp());
    }

    @Async("taskExecutor")
    public void passwordChanged(UUID userId, String userName) {
        auditLogService.log(null, userId, userName,
            "PASSWORD_CHANGED", "User", userId.toString(),
            "Password changed", resolveIp());
    }

    // ── Issue events ───────────────────────────────────────────────────────────

    @Async("taskExecutor")
    public void issueSubmitted(UUID municipalityId, UUID userId, String userName,
                               String issueId, String trackingId) {
        auditLogService.log(municipalityId, userId, userName,
            "ISSUE_SUBMITTED", "Issue", issueId,
            "Submitted issue " + trackingId, resolveIp());
    }

    @Async("taskExecutor")
    public void issueStatusChanged(UUID municipalityId, UUID userId, String userName,
                                   String issueId, String trackingId,
                                   String oldStatus, String newStatus) {
        auditLogService.log(municipalityId, userId, userName,
            "ISSUE_STATUS_CHANGED", "Issue", issueId,
            trackingId + ": " + oldStatus + " → " + newStatus, resolveIp());
    }

    @Async("taskExecutor")
    public void issueAssigned(UUID municipalityId, UUID performedBy, String performedByName,
                              String issueId, String trackingId, String assigneeName) {
        auditLogService.log(municipalityId, performedBy, performedByName,
            "ISSUE_ASSIGNED", "Issue", issueId,
            trackingId + " assigned to " + assigneeName, resolveIp());
    }

    @Async("taskExecutor")
    public void issueMerged(UUID municipalityId, UUID performedBy, String performedByName,
                            String primaryId, String duplicateId) {
        auditLogService.log(municipalityId, performedBy, performedByName,
            "ISSUE_MERGED", "Issue", primaryId,
            "Merged duplicate " + duplicateId + " → " + primaryId, resolveIp());
    }

    // ── Security events ────────────────────────────────────────────────────────

    @Async("taskExecutor")
    public void accessDenied(UUID userId, String path) {
        auditLogService.log(null, userId, userId != null ? userId.toString() : "anonymous",
            "ACCESS_DENIED", "Endpoint", path,
            "Unauthorized access attempt to " + path, resolveIp());
    }

    @Async("taskExecutor")
    public void spamFlagged(UUID municipalityId, UUID userId, String issueId) {
        auditLogService.log(municipalityId, userId, userId != null ? userId.toString() : "unknown",
            "SPAM_FLAGGED", "Issue", issueId,
            "AI flagged issue as spam", resolveIp());
    }

    // ── Helpers ────────────────────────────────────────────────────────────────

    private String resolveIp() {
        try {
            var attrs = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
            if (attrs == null) return "internal";
            HttpServletRequest req = attrs.getRequest();
            String xff = req.getHeader("X-Forwarded-For");
            if (xff != null && !xff.isBlank()) return xff.split(",")[0].trim();
            return req.getRemoteAddr();
        } catch (Exception e) {
            return "unknown";
        }
    }
}
