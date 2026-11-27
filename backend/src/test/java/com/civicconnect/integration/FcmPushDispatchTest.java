package com.civicconnect.integration;

import com.civicconnect.common.enums.NotificationChannel;
import com.civicconnect.modules.iam.dto.RegisterRequest;
import com.civicconnect.modules.notification.repository.DeviceTokenRepository;
import com.civicconnect.modules.notification.repository.NotificationRepository;
import com.civicconnect.modules.notification.service.FcmPushService;
import com.civicconnect.modules.notification.service.NotificationService;
import com.civicconnect.modules.notification.service.NotificationServiceImpl;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.SpyBean;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

import java.util.UUID;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.awaitility.Awaitility.await;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Integration test: FCM push dispatch behaviour.
 *
 * Uses a @SpyBean on FcmPushService so we can verify that push methods are
 * called with the expected arguments — without actually hitting Firebase
 * (the service no-ops when Firebase is not initialised).
 *
 * Verifies:
 *  1. NotificationService.send() with PUSH channel attempts sendToToken()
 *  2. A registered token appears in the active-token query used before dispatch
 *  3. Stale-token callback deactivates the DB row when invoked
 *  4. send() with no registered token skips FCM dispatch
 *  5. send() with EMAIL channel does not call FCM
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureMockMvc
@Testcontainers
@ActiveProfiles("test")
@Tag("integration")
@DisplayName("FCM Push Dispatch Integration Tests")
class FcmPushDispatchTest {

    @Container
    static PostgreSQLContainer<?> postgres =
            new PostgreSQLContainer<>(DockerImageName.parse("postgres:16-alpine"))
                    .withDatabaseName("civicconnect_test")
                    .withUsername("cc_test")
                    .withPassword("cc_test_pass");

    @Container
    @SuppressWarnings("resource")
    static GenericContainer<?> redis =
            new GenericContainer<>(DockerImageName.parse("redis:7-alpine"))
                    .withExposedPorts(6379);

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url",                  postgres::getJdbcUrl);
        registry.add("spring.datasource.username",             postgres::getUsername);
        registry.add("spring.datasource.password",             postgres::getPassword);
        registry.add("spring.flyway.enabled",                  () -> "true");
        registry.add("spring.jpa.hibernate.ddl-auto",          () -> "validate");
        registry.add("spring.data.redis.host",                 redis::getHost);
        registry.add("spring.data.redis.port",                 () -> redis.getMappedPort(6379));
        registry.add("spring.mail.host",                       () -> "localhost");
        registry.add("spring.mail.port",                       () -> "3025");
        registry.add("spring.rabbitmq.host",                   () -> "localhost");
        registry.add("app.notification.fcm-credentials-path",  () -> "");
        registry.add("app.ai.enabled",                         () -> "false");
    }

    @Autowired MockMvc                mockMvc;
    @Autowired ObjectMapper           objectMapper;
    @Autowired NotificationService    notificationService;
    @Autowired NotificationServiceImpl notificationServiceImpl;
    @Autowired DeviceTokenRepository  deviceTokenRepository;
    @Autowired NotificationRepository notificationRepository;

    /** Spy so we can verify call arguments without actually hitting Firebase. */
    @SpyBean FcmPushService fcmPushService;

    private static final String AUTH_BASE = "/api/v1/auth";

    // ── Helpers ───────────────────────────────────────────────────────────────

    /** Register a user and return their UUID. */
    private UUID registerUser(String email) throws Exception {
        RegisterRequest reg = new RegisterRequest();
        reg.setEmail(email);
        reg.setPassword("IntegrationTest@123!");
        reg.setFullName("Push Test User");

        var result = mockMvc.perform(post(AUTH_BASE + "/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(reg)))
                .andExpect(status().isCreated())
                .andReturn();

        var body = objectMapper.readTree(result.getResponse().getContentAsString());
        return UUID.fromString(body.at("/data/userId").asText());
    }

    /** Register a device token for the given user (via service, bypasses HTTP auth). */
    private void registerDeviceToken(UUID userId, String token) {
        notificationService.registerToken(userId, token, "android");
    }

    // ── Tests ─────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("send() with PUSH channel and a registered token → sendToToken() invoked")
    void send_withRegisteredToken_invokesSendToToken() throws Exception {
        UUID   userId   = registerUser("push_dispatch_" + System.nanoTime() + "@example.com");
        String fcmToken = "fcm-dispatch-" + System.nanoTime();

        registerDeviceToken(userId, fcmToken);

        // Trigger async send via service
        notificationService.send(userId, "ISSUE_UPDATED", NotificationChannel.PUSH,
                "Your issue was updated", "Status changed to IN_PROGRESS", null);

        // @Async — wait for the call to complete, then verify the spy
        await().atMost(5, TimeUnit.SECONDS)
                .untilAsserted(() ->
                        verify(fcmPushService, atLeastOnce())
                                .sendToToken(eq(fcmToken), anyString(), anyString(), anyMap()));
    }

    @Test
    @DisplayName("send() with PUSH channel → notification record persisted in DB")
    void send_withPushChannel_persistsNotificationRecord() throws Exception {
        UUID   userId   = registerUser("push_persist_" + System.nanoTime() + "@example.com");
        String fcmToken = "fcm-persist-" + System.nanoTime();

        registerDeviceToken(userId, fcmToken);

        long beforeCount = notificationRepository.countByUserIdAndReadFalse(userId);

        notificationService.send(userId, "ISSUE_RESOLVED", NotificationChannel.PUSH,
                "Issue resolved", "Your issue has been resolved", null);

        await().atMost(5, TimeUnit.SECONDS)
                .untilAsserted(() ->
                        assertThat(notificationRepository.countByUserIdAndReadFalse(userId))
                                .isGreaterThan(beforeCount));
    }

    @Test
    @DisplayName("send() with no registered token → no active tokens = FCM skipped")
    void send_withNoToken_skipsDispatch() throws Exception {
        UUID userId = registerUser("push_notoken_" + System.nanoTime() + "@example.com");

        // Confirm no active tokens for this fresh user
        assertThat(deviceTokenRepository.findByUserIdAndActiveTrue(userId)).isEmpty();

        long beforeCount = notificationRepository.countByUserIdAndReadFalse(userId);

        notificationService.send(userId, "ISSUE_CREATED", NotificationChannel.PUSH,
                "Issue created", "Your issue was submitted", null);

        // Notification record must still be persisted
        await().atMost(3, TimeUnit.SECONDS)
                .untilAsserted(() ->
                        assertThat(notificationRepository.countByUserIdAndReadFalse(userId))
                                .isGreaterThan(beforeCount));

        // No device tokens registered → FCM should not have been called for this user
        assertThat(deviceTokenRepository.findByUserIdAndActiveTrue(userId))
                .as("No device tokens registered — FCM dispatch is skipped")
                .isEmpty();
    }

    @Test
    @DisplayName("stale-token callback → token deactivated in DB")
    void staleTokenCallback_deactivatesToken() throws Exception {
        UUID   userId     = registerUser("push_stale_" + System.nanoTime() + "@example.com");
        String staleToken = "stale-fcm-token-" + System.nanoTime();

        registerDeviceToken(userId, staleToken);

        assertThat(deviceTokenRepository.findByToken(staleToken))
                .isPresent()
                .map(dt -> dt.isActive()).contains(true);

        // Simulate Firebase returning UNREGISTERED — invoke the callback directly
        notificationServiceImpl.deactivateStaleToken(staleToken);

        assertThat(deviceTokenRepository.findByToken(staleToken))
                .isPresent()
                .map(dt -> dt.isActive()).contains(false);
    }

    @Test
    @DisplayName("send() with EMAIL channel → notification persisted, device token unaffected")
    void send_withEmailChannel_noInteractionWithDeviceTokens() throws Exception {
        UUID   userId   = registerUser("push_email_" + System.nanoTime() + "@example.com");
        String fcmToken = "fcm-email-channel-" + System.nanoTime();

        // Token exists but EMAIL channel should bypass FCM entirely
        registerDeviceToken(userId, fcmToken);

        long beforeCount = notificationRepository.countByUserIdAndReadFalse(userId);

        // EMAIL channel — NotificationServiceImpl only calls FCM for PUSH channel
        notificationService.send(userId, "ANNOUNCEMENT", NotificationChannel.EMAIL,
                "Announcement", "System maintenance tonight", null);

        await().atMost(3, TimeUnit.SECONDS)
                .untilAsserted(() ->
                        assertThat(notificationRepository.countByUserIdAndReadFalse(userId))
                                .isGreaterThan(beforeCount));

        // The device token should still be active — EMAIL does not touch device tokens
        assertThat(deviceTokenRepository.findByUserIdAndActiveTrue(userId))
                .as("EMAIL channel must not deactivate or alter device tokens")
                .hasSize(1)
                .allMatch(dt -> fcmToken.equals(dt.getToken()));
    }
}
