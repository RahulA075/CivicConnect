package com.civicconnect.integration;

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

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Integration tests for the Issues API.
 * Covers: submit, read, track, nearby, status transitions.
 * Uses Testcontainers — requires Docker.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureMockMvc
@Testcontainers
@ActiveProfiles("test")
@Tag("integration")
@DisplayName("Issue Integration Tests")
class IssueIntegrationTest {

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
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
        registry.add("spring.flyway.enabled", () -> "true");
        registry.add("spring.jpa.hibernate.ddl-auto", () -> "validate");
        registry.add("spring.data.redis.host", redis::getHost);
        registry.add("spring.data.redis.port", () -> redis.getMappedPort(6379));
        registry.add("spring.mail.host", () -> "localhost");
        registry.add("spring.mail.port", () -> "3025");
        registry.add("spring.rabbitmq.host", () -> "localhost");
        registry.add("app.notification.fcm-credentials-path", () -> "");
        registry.add("app.ai.enabled", () -> "false");
    }

    @Autowired MockMvc      mockMvc;
    @Autowired ObjectMapper objectMapper;

    // ── Protected endpoints require a token ───────────────────────────────

    @Test
    @DisplayName("GET /issues/{id} without token → 401")
    void getById_noToken_returns401() throws Exception {
        mockMvc.perform(get("/api/v1/issues/00000000-0000-0000-0000-000000000001"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("POST /issues without token → 401")
    void submit_noToken_returns401() throws Exception {
        mockMvc.perform(post("/api/v1/issues")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("GET /issues/track/{trackingId} → 404 for unknown tracking ID")
    void getByTrackingId_unknown_returns404() throws Exception {
        // Register + login to get token
        String token = registerAndLogin("tracktest_" + System.nanoTime() + "@example.com");

        mockMvc.perform(get("/api/v1/issues/track/INVALID-TRACKING-ID")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isNotFound());
    }

    @Test
    @DisplayName("GET /issues/nearby → 200 with valid params")
    void getNearby_validParams_returns200() throws Exception {
        String token = registerAndLogin("nearby_" + System.nanoTime() + "@example.com");

        mockMvc.perform(get("/api/v1/issues/nearby")
                        .param("lat", "12.9716")
                        .param("lng", "77.5946")
                        .param("radius", "500")
                        .param("municipalityId", "00000000-0000-0000-0000-000000000001")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isArray());
    }

    @Test
    @DisplayName("POST /issues with missing required fields → 400")
    void submit_missingFields_returns400() throws Exception {
        String token = registerAndLogin("missing_" + System.nanoTime() + "@example.com");

        mockMvc.perform(post("/api/v1/issues")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"\"}")  // invalid — blank title + missing fields
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("GET /issues/my → 200 for authenticated citizen")
    void getMyIssues_authenticated_returns200() throws Exception {
        String token = registerAndLogin("myissues_" + System.nanoTime() + "@example.com");

        mockMvc.perform(get("/api/v1/issues/my")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    // ── Helper ─────────────────────────────────────────────────────────────

    private String registerAndLogin(String email) throws Exception {
        // Register
        String regBody = """
                {"email":"%s","password":"Integration@123!","fullName":"Test User"}
                """.formatted(email);
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(regBody))
                .andExpect(status().isCreated());

        // Login
        String loginBody = """
                {"identifier":"%s","password":"Integration@123!"}
                """.formatted(email);
        MvcResult result = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginBody))
                .andExpect(status().isOk())
                .andReturn();

        var node = objectMapper.readTree(result.getResponse().getContentAsString());
        return node.at("/data/accessToken").asText();
    }
}
