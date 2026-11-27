package com.civicconnect.modules.notification.listener;

import com.civicconnect.common.enums.NotificationChannel;
import com.civicconnect.modules.issue.event.IssueStatusChangedEvent;
import com.civicconnect.modules.issue.event.IssueSubmittedEvent;
import com.civicconnect.modules.notification.service.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

/**
 * Listens to internal Spring application events from the Issue module
 * and dispatches notifications asynchronously via {@link NotificationService}.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class IssueEventListener {

    private final NotificationService notificationService;

    // ── Issue submitted ────────────────────────────────────────────────────────

    @Async
    @EventListener
    public void onIssueSubmitted(IssueSubmittedEvent event) {
        log.info("EVENT: issue submitted trackingId={}", event.getTrackingId());

        // 1. Confirmation push to the citizen who filed the issue
        notificationService.send(
                event.getReportedById(),
                "ISSUE_SUBMITTED",
                NotificationChannel.PUSH,
                "Issue Received ✓",
                "Your issue #" + event.getTrackingId() +
                        " has been received and is under review.",
                event.getIssueId()
        );

        // 2. Nearby-issue broadcast to other citizens in the municipality
        notificationService.sendNearbyIssue(
                event.getMunicipalityId(),
                event.getIssueId(),
                "New Issue Reported",
                null
        );
    }

    // ── Issue status changed ───────────────────────────────────────────────────

    @Async
    @EventListener
    public void onIssueStatusChanged(IssueStatusChangedEvent event) {
        log.info("EVENT: issue {} status {} → {}",
                event.getTrackingId(), event.getOldStatus(), event.getNewStatus());

        String title = buildTitle(event.getNewStatus().name());
        String body  = "Issue #" + event.getTrackingId() +
                " status updated to " + friendlyStatus(event.getNewStatus().name()) + ".";

        // Notify the citizen who reported
        notificationService.send(
                event.getReportedById(),
                "STATUS_CHANGE",
                NotificationChannel.PUSH,
                title,
                body,
                event.getIssueId()
        );
    }

    // ── Helpers ────────────────────────────────────────────────────────────────

    private String buildTitle(String status) {
        return switch (status) {
            case "VERIFIED"    -> "Issue Verified ✓";
            case "IN_PROGRESS" -> "Work Started 🔧";
            case "RESOLVED"    -> "Issue Resolved ✅";
            case "CLOSED"      -> "Issue Closed";
            case "REJECTED"    -> "Issue Rejected";
            default            -> "Issue Update";
        };
    }

    private String friendlyStatus(String status) {
        return switch (status) {
            case "PENDING"     -> "Pending Review";
            case "VERIFIED"    -> "Verified";
            case "IN_PROGRESS" -> "In Progress";
            case "RESOLVED"    -> "Resolved";
            case "CLOSED"      -> "Closed";
            case "REJECTED"    -> "Rejected";
            default            -> status;
        };
    }
}
