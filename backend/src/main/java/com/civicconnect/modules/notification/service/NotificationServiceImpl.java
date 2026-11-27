package com.civicconnect.modules.notification.service;

import com.civicconnect.common.enums.NotificationChannel;
import com.civicconnect.common.exception.ResourceNotFoundException;
import com.civicconnect.modules.iam.repository.UserRepository;
import com.civicconnect.modules.notification.dto.NotificationPreferenceRequest;
import com.civicconnect.modules.notification.dto.NotificationPreferenceResponse;
import com.civicconnect.modules.notification.dto.NotificationResponse;
import com.civicconnect.modules.notification.entity.DeviceToken;
import com.civicconnect.modules.notification.entity.Notification;
import com.civicconnect.modules.notification.entity.NotificationPreference;
import com.civicconnect.modules.notification.repository.DeviceTokenRepository;
import com.civicconnect.modules.notification.repository.NotificationPreferenceRepository;
import com.civicconnect.modules.notification.repository.NotificationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.annotation.PostConstruct;
import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationServiceImpl implements NotificationService {

    private final NotificationRepository           notificationRepository;
    private final DeviceTokenRepository            deviceTokenRepository;
    private final NotificationPreferenceRepository preferenceRepository;
    private final UserRepository                   userRepository;
    private final FcmPushService                   fcmPushService;

    // Wire the stale-token deactivation callback into FcmPushService at startup
    @PostConstruct
    void wireStaleTokenCallback() {
        fcmPushService.setStaleTokenCallback(this::deactivateStaleToken);
    }

    /**
     * Deactivates a stale/invalid FCM token in the database.
     * Called by FcmPushService when Firebase returns UNREGISTERED or INVALID_ARGUMENT.
     */
    public void deactivateStaleToken(String token) {
        log.warn("Notification: deactivating stale FCM token {}…", token.length() > 8 ? token.substring(0, 8) : token);
        deviceTokenRepository.deactivateByToken(token);
    }
    // FCM topic prefixes
    private static final String TOPIC_MUNICIPALITY = "municipality_";
    private static final String TOPIC_EMERGENCY    = "emergency_";
    private static final String TOPIC_NEARBY       = "nearby_";
    private static final String TOPIC_ANNOUNCEMENT = "announcement_";

    // ── Sending ───────────────────────────────────────────────────────────────

    @Override
    @Async
    @Transactional
    public void send(UUID userId, String eventType, NotificationChannel channel,
                     String title, String body, UUID issueId) {
        // 1. Check user preferences
        NotificationPreference prefs = preferenceRepository.findByUserId(userId)
                .orElse(null);

        boolean pushOk = prefs == null || prefs.isPushEnabled();
        if (prefs != null && prefs.getEventOverrides() != null) {
            Object override = prefs.getEventOverrides().get(eventType);
            if (Boolean.FALSE.equals(override)) pushOk = false;
        }

        // 2. Persist inbox record
        var user = userRepository.findActiveById(userId).orElse(null);
        if (user == null) {
            log.warn("Notification: user {} not found, skipping", userId);
            return;
        }

        Notification notif = Notification.builder()
                .user(user)
                .issueId(issueId)
                .eventType(eventType)
                .channel(channel)
                .title(title)
                .body(body)
                .actionUrl(issueId != null ? "/issues/" + issueId : null)
                .build();
        notificationRepository.save(notif);

        // 3. Send push if enabled and channel is PUSH
        if (channel == NotificationChannel.PUSH && pushOk) {
            sendPushToUser(userId, title, body, buildData(eventType, issueId, null));
        }
    }

    @Override
    @Async
    public void sendEmergencyAlert(UUID municipalityId, String title, String body,
                                   String severity, UUID alertId) {
        String topic = TOPIC_EMERGENCY + municipalityId.toString().replace("-", "_");
        Map<String, String> data = new HashMap<>();
        data.put("type",       "EMERGENCY_ALERT");
        data.put("alertId",    alertId != null ? alertId.toString() : "");
        data.put("severity",   severity);
        data.put("actionUrl",  "/admin/alerts");

        boolean sent = fcmPushService.sendToTopic(topic, title, body, data);
        log.info("Emergency alert topic '{}' → sent={}", topic, sent);
    }

    @Override
    @Async
    public void sendNearbyIssue(UUID municipalityId, UUID issueId,
                                String categoryName, String locationHint) {
        String topic = TOPIC_NEARBY + municipalityId.toString().replace("-", "_");
        String title = "New Issue Nearby";
        String body  = categoryName + (locationHint != null ? " — " + locationHint : "");

        Map<String, String> data = buildData("NEARBY_ISSUE", issueId, null);
        fcmPushService.sendToTopic(topic, title, body, data);
    }

    @Override
    @Async
    public void sendAnnouncement(UUID municipalityId, String title, String body,
                                 UUID referenceId) {
        String topic = TOPIC_ANNOUNCEMENT + municipalityId.toString().replace("-", "_");
        Map<String, String> data = buildData("ANNOUNCEMENT", null, referenceId);
        fcmPushService.sendToTopic(topic, title, body, data);
    }

    // ── Inbox ─────────────────────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public Page<NotificationResponse> getInbox(UUID userId, Pageable pageable) {
        return notificationRepository
                .findByUserIdOrderByCreatedAtDesc(userId, pageable)
                .map(this::toDto);
    }

    @Override
    @Cacheable(value = "unreadCount", key = "#userId")
    public long getUnreadCount(UUID userId) {
        return notificationRepository.countByUserIdAndReadFalse(userId);
    }

    @Override
    @Transactional
    @CacheEvict(value = "unreadCount", key = "#userId")
    public void markRead(UUID notificationId, UUID userId) {
        Notification n = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Notification not found: " + notificationId));
        if (!n.getUser().getId().equals(userId)) return; // security: own only
        n.setRead(true);
        n.setReadAt(Instant.now());
        notificationRepository.save(n);
    }

    @Override
    @Transactional
    @CacheEvict(value = "unreadCount", key = "#userId")
    public void markAllRead(UUID userId) {
        notificationRepository.markAllReadForUser(userId);
    }

    // ── Device Tokens ─────────────────────────────────────────────────────────

    @Override
    @Transactional
    public void registerToken(UUID userId, String token, String platform) {
        // Upsert: deactivate any existing row with same token, then create fresh
        deviceTokenRepository.findByToken(token).ifPresent(existing -> {
            existing.setActive(false);
            deviceTokenRepository.save(existing);
        });

        var user = userRepository.findActiveById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userId));

        DeviceToken dt = DeviceToken.builder()
                .user(user)
                .token(token)
                .platform(platform != null ? platform : "android")
                .lastUsedAt(Instant.now())
                .build();
        deviceTokenRepository.save(dt);

        // Subscribe to municipality topics
        if (user.getMunicipality() != null) {
            UUID mid = user.getMunicipality().getId();
            String midStr = mid.toString().replace("-", "_");
            fcmPushService.subscribeToTopic(List.of(token),
                    TOPIC_NEARBY + midStr);
            fcmPushService.subscribeToTopic(List.of(token),
                    TOPIC_ANNOUNCEMENT + midStr);
            if (user.getRole().getName().name().contains("ADMIN")
                    || user.getRole().getName().name().contains("SUPERVISOR")
                    || user.getRole().getName().name().contains("WORKER")) {
                fcmPushService.subscribeToTopic(List.of(token),
                        TOPIC_EMERGENCY + midStr);
            }
        }

        log.info("Device token registered for user {}", userId);
    }

    @Override
    @Transactional
    public void removeToken(UUID userId, String token) {
        deviceTokenRepository.deactivateByToken(token);
        // Unsubscribe from all topics
        var user = userRepository.findById(userId).orElse(null);
        if (user != null && user.getMunicipality() != null) {
            String midStr = user.getMunicipality().getId().toString().replace("-", "_");
            fcmPushService.unsubscribeFromTopic(List.of(token), TOPIC_NEARBY + midStr);
            fcmPushService.unsubscribeFromTopic(List.of(token), TOPIC_ANNOUNCEMENT + midStr);
            fcmPushService.unsubscribeFromTopic(List.of(token), TOPIC_EMERGENCY + midStr);
        }
    }

    // ── Preferences ───────────────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public NotificationPreferenceResponse getPreferences(UUID userId) {
        NotificationPreference prefs = preferenceRepository.findByUserId(userId)
                .orElseGet(() -> NotificationPreference.builder().build());
        return toPrefsDto(prefs);
    }

    @Override
    @Transactional
    public NotificationPreferenceResponse updatePreferences(UUID userId,
                                                            NotificationPreferenceRequest req) {
        NotificationPreference prefs = preferenceRepository.findByUserId(userId)
                .orElseGet(() -> {
                    var user = userRepository.findActiveById(userId)
                            .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userId));
                    return NotificationPreference.builder().user(user).build();
                });

        if (req.getPushEnabled()  != null) prefs.setPushEnabled(req.getPushEnabled());
        if (req.getEmailEnabled() != null) prefs.setEmailEnabled(req.getEmailEnabled());
        if (req.getSmsEnabled()   != null) prefs.setSmsEnabled(req.getSmsEnabled());
        if (req.getEventOverrides() != null) prefs.setEventOverrides(req.getEventOverrides());
        prefs.setUpdatedAt(Instant.now());

        return toPrefsDto(preferenceRepository.save(prefs));
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private void sendPushToUser(UUID userId, String title, String body,
                                Map<String, String> data) {
        List<DeviceToken> tokens = deviceTokenRepository.findByUserIdAndActiveTrue(userId);
        if (tokens.isEmpty()) return;

        if (tokens.size() == 1) {
            fcmPushService.sendToToken(tokens.get(0).getToken(), title, body, data);
        } else {
            fcmPushService.sendMulticast(
                    tokens.stream().map(DeviceToken::getToken).toList(),
                    title, body, data);
        }
    }

    private Map<String, String> buildData(String eventType, UUID issueId, UUID referenceId) {
        Map<String, String> data = new HashMap<>();
        data.put("type", eventType);
        if (issueId    != null) data.put("issueId",     issueId.toString());
        if (referenceId != null) data.put("referenceId", referenceId.toString());
        return data;
    }

    private NotificationResponse toDto(Notification n) {
        return NotificationResponse.builder()
                .id(n.getId())
                .eventType(n.getEventType())
                .channel(n.getChannel().name())
                .title(n.getTitle())
                .body(n.getBody())
                .actionUrl(n.getActionUrl())
                .read(n.isRead())
                .issueId(n.getIssueId())
                .createdAt(n.getCreatedAt())
                .readAt(n.getReadAt())
                .build();
    }

    private NotificationPreferenceResponse toPrefsDto(NotificationPreference p) {
        return NotificationPreferenceResponse.builder()
                .pushEnabled(p.isPushEnabled())
                .emailEnabled(p.isEmailEnabled())
                .smsEnabled(p.isSmsEnabled())
                .eventOverrides(p.getEventOverrides())
                .build();
    }
}
