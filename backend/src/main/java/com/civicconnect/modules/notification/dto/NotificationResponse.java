package com.civicconnect.modules.notification.dto;

import lombok.Builder;
import lombok.Data;
import java.time.Instant;
import java.util.UUID;

@Data @Builder
public class NotificationResponse {
    private UUID    id;
    private String  eventType;
    private String  channel;
    private String  title;
    private String  body;
    private String  actionUrl;
    private boolean read;
    private UUID    issueId;
    private Instant createdAt;
    private Instant readAt;
}
