package com.civicconnect.integration;

import com.civicconnect.modules.iam.dto.LoginRequest;
import com.civicconnect.modules.iam.dto.RegisterRequest;
import com.civicconnect.modules.notification.repository.DeviceTokenRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Integration test: FCM device-token registration and removal.
 *
 * Verifies that an authenticated user can:
 *  1. POST /api/v1/notifications/device-token  → token persisted as active
 *  2. POST again with the same token            → upsert: still one active row
 *  3. DELETE /api/v1/notifications/device-token → token deactivated
 *  4. POST without a Bearer token               → 401 Unauthorized
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureMockMvc
@Testcontainers
@ActiveProfiles("test")
@Tag("integration")
@DisplayName("FCM Token Registration Integration Tests")
class FcmTokenRegistrationTest {

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
        registry.add("spring.datasource.url",            postgres::getJdbcUrl);
        registry.add("spring.datasource.username",       postgres::getUsername);
        registry.add("spring.datasource.password",       postgres::getPassword);
        registry.add("spring.flyway.enabled",            () -> "true");
        registry.add("spring.jpa.hibernate.ddl-auto",   () -> "validate");
        registry.add("spring.data.redis.host",           redis::getHost);
        registry.add("spring.data.redis.port",           () -> redis.getMappedPort(6379));
        registry.add("spring.mail.host",                 () -> "localhost");
        registry.add("spring.mail.port",                 () -> "3025");
        registry.add("spring.rabbitmq.host",             () -> "localhost");
        registry.add("app.notification.fcm-credentials-path", () -> "");
        registry.add("app.ai.enabled",                   () -> "false");
    }

    @Autowired MockMvc              mockMvc;
    @Autowired ObjectMapper         objectMapper;
    @Autowired DeviceTokenRepository deviceTokenRepository;

    private static final String AUTH_BASE  = "/api/v1/auth";
    private static final String NOTIF_BASE = "/api/v1/notifications";

    // ── Helpers ───────────────────────────────────────────────────────────────

    /** Register a fresh user and return its Bearer access token. */
    private String registerAndLogin(String email) throws Exception {
        RegisterRequest reg = new RegisterRequest();
        reg.setEmail(email);
        reg.setPassword("IntegrationTest@123!");
        reg.setFullName("FCM Test User");

        mockMvc.perform(post(AUTH_BASE + "/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(reg)))
                .andExpect(status().isCreated());

        LoginRequest login = new LoginRequest();
        login.setIdentifier(email);
        login.setPassword("IntegrationTest@123!");

        MvcResult loginResult = mockMvc.perform(post(AUTH_BASE + "/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(login)))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode body = objectMapper.readTree(loginResult.getResponse().getContentAsString());
        return body.at("/data/accessToken").asText();
    }

    // ── Tests ─────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("register FCM token → persisted as active in DB")
    void registerToken_persistsActiveRow() throws Exception {
        String token      = "fcm-test-token-" + System.nanoTime();
        String bearerToken = registerAndLogin("fcm_reg_" + System.nanoTime() + "@example.com");

        mockMvc.perform(post(NOTIF_BASE + "/device-token")
                        .header("Authorization", "Bearer " + bearerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"token\":\"" + token + "\",\"platform\":\"android\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Device token registered"));

        // DB assertion: exactly one active row for this token
        var saved = deviceTokenRepository.findByToken(token);
        assertThat(saved).isPresent();
        assertThat(saved.get().isActive()).isTrue();
        assertThat(saved.get().getPlatform()).isEqualTo("android");
    }

    @Test
    @DisplayName("register same token twice → upsert: still exactly one active row")
    void registerSameToken_upsert_singleActiveRow() throws Exception {
        String token       = "fcm-upsert-token-" + System.nanoTime();
        String bearerToken = registerAndLogin("fcm_upsert_" + System.nanoTime() + "@example.com");

        String body = "{\"token\":\"" + token + "\",\"platform\":\"android\"}";

        // First registration
        mockMvc.perform(post(NOTIF_BASE + "/device-token")
                        .header("Authorization", "Bearer " + bearerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk());

        // Second registration with the same token — should upsert, not duplicate
        mockMvc.perform(post(NOTIF_BASE + "/device-token")
                        .header("Authorization", "Bearer " + bearerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk());

        // DB assertion: exactly one active row (the old inactive row + new active row — unique token)
        var activeTokens = deviceTokenRepository.findByToken(token);
        assertThat(activeTokens).isPresent();
        assertThat(activeTokens.get().isActive()).isTrue();
    }

    @Test
    @DisplayName("remove FCM token → deactivated in DB")
    void removeToken_deactivatesRow() throws Exception {
        String token       = "fcm-remove-token-" + System.nanoTime();
        String bearerToken = registerAndLogin("fcm_remove_" + System.nanoTime() + "@example.com");

        String body = "{\"token\":\"" + token + "\",\"platform\":\"android\"}";

        // Register the token
        mockMvc.perform(post(NOTIF_BASE + "/device-token")
                        .header("Authorization", "Bearer " + bearerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk());

        assertThat(deviceTokenRepository.findByToken(token))
                .isPresent()
                .map(dt -> dt.isActive()).contains(true);

        // Remove the token
        mockMvc.perform(delete(NOTIF_BASE + "/device-token")
                        .header("Authorization", "Bearer " + bearerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Device token removed"));

        // DB assertion: token now inactive
        assertThat(deviceTokenRepository.findByToken(token))
                .isPresent()
                .map(dt -> dt.isActive()).contains(false);
    }

    @Test
    @DisplayName("register token without auth → 401 Unauthorized")
    void registerToken_noAuth_returns401() throws Exception {
        mockMvc.perform(post(NOTIF_BASE + "/device-token")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"token\":\"no-auth-token\",\"platform\":\"android\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("register token with blank token value → 400 Bad Request")
    void registerToken_blankToken_returns400() throws Exception {
        String bearerToken = registerAndLogin("fcm_blank_" + System.nanoTime() + "@example.com");

        mockMvc.perform(post(NOTIF_BASE + "/device-token")
                        .header("Authorization", "Bearer " + bearerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"token\":\"\",\"platform\":\"android\"}"))
                .andExpect(status().isBadRequest());
    }
}
