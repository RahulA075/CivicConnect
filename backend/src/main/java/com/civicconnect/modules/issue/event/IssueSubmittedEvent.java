package com.civicconnect.modules.issue.event;

import lombok.Getter;
import org.springframework.context.ApplicationEvent;

import java.util.UUID;

/**
 * Published to the internal Spring ApplicationEvent bus when a new issue is submitted.
 * Consumed by: NotificationModule, AnalyticsModule.
 */
@Getter
public class IssueSubmittedEvent extends ApplicationEvent {

    private final UUID   issueId;
    private final UUID   reportedById;
    private final UUID   municipalityId;
    private final String trackingId;

    public IssueSubmittedEvent(Object source, UUID issueId,
                               UUID reportedById, UUID municipalityId,
                               String trackingId) {
        super(source);
        this.issueId        = issueId;
        this.reportedById   = reportedById;
        this.municipalityId = municipalityId;
        this.trackingId     = trackingId;
    }
}
