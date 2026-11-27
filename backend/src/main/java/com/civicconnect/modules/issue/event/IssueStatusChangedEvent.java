package com.civicconnect.modules.issue.event;

import com.civicconnect.common.enums.IssueStatus;
import lombok.Getter;
import org.springframework.context.ApplicationEvent;

import java.util.UUID;

/**
 * Published whenever an issue changes status.
 * Consumed by: NotificationModule (push/email), AnalyticsModule.
 */
@Getter
public class IssueStatusChangedEvent extends ApplicationEvent {

    private final UUID        issueId;
    private final UUID        municipalityId;
    private final UUID        reportedById;
    private final String      trackingId;
    private final IssueStatus oldStatus;
    private final IssueStatus newStatus;
    private final UUID        changedById;

    public IssueStatusChangedEvent(Object source, UUID issueId,
                                   UUID municipalityId, UUID reportedById,
                                   String trackingId,
                                   IssueStatus oldStatus, IssueStatus newStatus,
                                   UUID changedById) {
        super(source);
        this.issueId        = issueId;
        this.municipalityId = municipalityId;
        this.reportedById   = reportedById;
        this.trackingId     = trackingId;
        this.oldStatus      = oldStatus;
        this.newStatus      = newStatus;
        this.changedById    = changedById;
    }
}
