package com.civicconnect.modules.notification.service;

import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.*;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.function.Consumer;
/**
 * Wraps the Firebase Admin SDK for sending FCM push notifications.
 * All methods silently no-op when Firebase is not initialised
 * (local dev without credentials).
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class FcmPushService {

    /**
     * Called whenever a token is found to be stale (UNREGISTERED / INVALID_ARGUMENT).
     * Wired by NotificationServiceImpl via @PostConstruct to deactivate the DB row.
     */
    @Setter
    private Consumer<String> staleTokenCallback = token -> {};

    private boolean isAvailable() {
        return !FirebaseApp.getApps().isEmpty();
    }

    /**
     * Send a data + notification message to a single FCM registration token.
     *
     * @param token     FCM registration token
     * @param title     Notification title
     * @param body      Notification body
     * @param data      Extra key/value data payload (forwarded to the app)
     * @return true if delivered successfully
     */
    public boolean sendToToken(String token, String title, String body,
                               Map<String, String> data) {
        if (!isAvailable()) {
            log.debug("FCM: SDK not initialised — skipping push to token {}", abbrev(token));
            return false;
        }
        try {
            Message message = Message.builder()
                    .setToken(token)
                    .setNotification(Notification.builder()
                            .setTitle(title)
                            .setBody(body)
                            .build())
                    .putAllData(data)
                    .setAndroidConfig(AndroidConfig.builder()
                            .setPriority(AndroidConfig.Priority.HIGH)
                            .setNotification(AndroidNotification.builder()
                                    .setSound("default")
                                    .build())
                            .build())
                    .setApnsConfig(ApnsConfig.builder()
                            .setAps(Aps.builder()
                                    .setSound("default")
                                    .setBadge(1)
                                    .build())
                            .build())
                    .build();

            String messageId = FirebaseMessaging.getInstance().send(message);
            log.debug("FCM: sent to token {} → messageId={}", abbrev(token), messageId);
            return true;
        } catch (FirebaseMessagingException e) {
            handleFcmError(token, e);
            return false;
        }
    }

    /**
     * Multicast send to up to 500 tokens at once.
     * Returns the number of successful deliveries.
     */
    public int sendMulticast(List<String> tokens, String title, String body,
                             Map<String, String> data) {
        if (!isAvailable() || tokens.isEmpty()) return 0;

        try {
            MulticastMessage message = MulticastMessage.builder()
                    .addAllTokens(tokens)
                    .setNotification(Notification.builder()
                            .setTitle(title)
                            .setBody(body)
                            .build())
                    .putAllData(data)
                    .setAndroidConfig(AndroidConfig.builder()
                            .setPriority(AndroidConfig.Priority.HIGH)
                            .build())
                    .setApnsConfig(ApnsConfig.builder()
                            .setAps(Aps.builder()
                                    .setSound("default")
                                    .build())
                            .build())
                    .build();

            BatchResponse response = FirebaseMessaging.getInstance().sendEachForMulticast(message);
            log.info("FCM multicast: {}/{} sent successfully",
                    response.getSuccessCount(), tokens.size());

            // Deactivate any stale tokens identified in failed responses
            List<SendResponse> responses = response.getResponses();
            for (int i = 0; i < responses.size(); i++) {
                SendResponse sr = responses.get(i);
                if (!sr.isSuccessful() && sr.getException() != null) {
                    MessagingErrorCode code = sr.getException().getMessagingErrorCode();
                    if (code == MessagingErrorCode.UNREGISTERED
                            || code == MessagingErrorCode.INVALID_ARGUMENT) {
                        String staleToken = tokens.get(i);
                        log.warn("FCM: stale/invalid token {} in multicast — removing from DB",
                                abbrev(staleToken));
                        staleTokenCallback.accept(staleToken);
                    }
                }
            }

            return response.getSuccessCount();
        } catch (FirebaseMessagingException e) {
            log.error("FCM multicast failed: {}", e.getMessage());
            return 0;
        }
    }

    /**
     * Send to a named topic (e.g. "municipality_UUID_NEARBY" or "emergency_UUID").
     */
    public boolean sendToTopic(String topic, String title, String body,
                               Map<String, String> data) {
        if (!isAvailable()) {
            log.debug("FCM: SDK not initialised — skipping topic push to {}", topic);
            return false;
        }
        try {
            Message message = Message.builder()
                    .setTopic(topic)
                    .setNotification(Notification.builder()
                            .setTitle(title)
                            .setBody(body)
                            .build())
                    .putAllData(data)
                    .setAndroidConfig(AndroidConfig.builder()
                            .setPriority(AndroidConfig.Priority.HIGH)
                            .build())
                    .build();

            String messageId = FirebaseMessaging.getInstance().send(message);
            log.info("FCM topic '{}' → messageId={}", topic, messageId);
            return true;
        } catch (FirebaseMessagingException e) {
            log.error("FCM topic '{}' failed: {}", topic, e.getMessage());
            return false;
        }
    }

    /**
     * Subscribe a list of tokens to a named topic.
     */
    public void subscribeToTopic(List<String> tokens, String topic) {
        if (!isAvailable() || tokens.isEmpty()) return;
        try {
            TopicManagementResponse resp =
                    FirebaseMessaging.getInstance().subscribeToTopic(tokens, topic);
            log.debug("FCM topic subscribe '{}': {}/{} success",
                    topic, resp.getSuccessCount(), tokens.size());
        } catch (FirebaseMessagingException e) {
            log.error("FCM topic subscribe '{}' failed: {}", topic, e.getMessage());
        }
    }

    /**
     * Unsubscribe tokens from a topic.
     */
    public void unsubscribeFromTopic(List<String> tokens, String topic) {
        if (!isAvailable() || tokens.isEmpty()) return;
        try {
            FirebaseMessaging.getInstance().unsubscribeFromTopic(tokens, topic);
        } catch (FirebaseMessagingException e) {
            log.error("FCM topic unsubscribe '{}' failed: {}", topic, e.getMessage());
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private void handleFcmError(String token, FirebaseMessagingException e) {
        MessagingErrorCode code = e.getMessagingErrorCode();
        if (code == MessagingErrorCode.UNREGISTERED
                || code == MessagingErrorCode.INVALID_ARGUMENT) {
            log.warn("FCM: stale/invalid token {} — removing from DB", abbrev(token));
            staleTokenCallback.accept(token);
        } else {
            log.error("FCM: send to {} failed [{}]: {}", abbrev(token), code, e.getMessage());
        }
    }

    private String abbrev(String token) {
        return token != null && token.length() > 12
                ? token.substring(0, 8) + "…" : token;
    }
}
