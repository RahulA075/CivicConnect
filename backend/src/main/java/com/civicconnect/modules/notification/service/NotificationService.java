package com.civicconnect.modules.notification.service;

import com.civicconnect.common.enums.NotificationChannel;
import com.civicconnect.modules.notification.dto.NotificationPreferenceRequest;
import com.civicconnect.modules.notification.dto.NotificationPreferenceResponse;
import com.civicconnect.modules.notification.dto.NotificationResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.UUID;

/** Notification service contract. */
public interface NotificationService {

    // ── Sending ───────────────────────────────────────────────────────────────

    /** Persist inbox record and send via FCM push (if enabled). */
    void send(UUID userId, String eventType, NotificationChannel channel,
              String title, String body, UUID issueId);

    /** Send an emergency alert to all active tokens in a municipality. */
    void sendEmergencyAlert(UUID municipalityId, String title, String body,
                            String severity, UUID alertId);

    /** Send a nearby-issue notification to a municipality topic. */
    void sendNearbyIssue(UUID municipalityId, UUID issueId,
                         String categoryName, String locationHint);

    /** Send a government announcement to a municipality topic. */
    void sendAnnouncement(UUID municipalityId, String title, String body,
                          UUID referenceId);

    // ── Inbox ─────────────────────────────────────────────────────────────────

    Page<NotificationResponse> getInbox(UUID userId, Pageable pageable);

    long getUnreadCount(UUID userId);

    void markRead(UUID notificationId, UUID userId);

    void markAllRead(UUID userId);

    // ── Device Tokens ─────────────────────────────────────────────────────────

    void registerToken(UUID userId, String token, String platform);

    void removeToken(UUID userId, String token);

    // ── Preferences ───────────────────────────────────────────────────────────

    NotificationPreferenceResponse getPreferences(UUID userId);

    NotificationPreferenceResponse updatePreferences(UUID userId,
                                                     NotificationPreferenceRequest req);
}
