package com.civicconnect.integration;

import com.civicconnect.modules.iam.dto.LoginRequest;
import com.civicconnect.modules.iam.dto.RegisterRequest;
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
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Full-stack integration tests for authentication flows.
 * Uses Testcontainers for real PostgreSQL + Redis.
 * Flyway migrations are applied automatically.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureMockMvc
@Testcontainers
@ActiveProfiles("test")
@Tag("integration")
@DisplayName("Auth Integration Tests")
class AuthIntegrationTest {

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

    @Autowired MockMvc     mockMvc;
    @Autowired ObjectMapper objectMapper;

    private static final String AUTH_BASE = "/api/v1/auth";

    // ── Register flow ──────────────────────────────────────────────────────

    @Test
    @DisplayName("register → login → refresh full flow succeeds")
    void registerLoginRefresh_fullFlow() throws Exception {
        String uniqueEmail = "it_user_" + System.nanoTime() + "@example.com";

        // 1. Register
        RegisterRequest regReq = new RegisterRequest();
        regReq.setEmail(uniqueEmail);
        regReq.setPassword("IntegrationTest@123!");
        regReq.setFullName("Integration Test User");

        MvcResult regResult = mockMvc.perform(post(AUTH_BASE + "/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(regReq)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.accessToken").isNotEmpty())
                .andReturn();

        var regBody = objectMapper.readTree(regResult.getResponse().getContentAsString());
        String refreshToken = regBody.at("/data/refreshToken").asText();
        assertThat(refreshToken).isNotBlank();

        // 2. Login with same credentials
        LoginRequest loginReq = new LoginRequest();
        loginReq.setIdentifier(uniqueEmail);
        loginReq.setPassword("IntegrationTest@123!");

        MvcResult loginResult = mockMvc.perform(post(AUTH_BASE + "/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.role").value("CITIZEN"))
                .andReturn();

        var loginBody = objectMapper.readTree(loginResult.getResponse().getContentAsString());
        String loginRefresh = loginBody.at("/data/refreshToken").asText();
        assertThat(loginRefresh).isNotBlank();

        // 3. Refresh token
        mockMvc.perform(post(AUTH_BASE + "/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refreshToken\":\"" + loginRefresh + "\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.accessToken").isNotEmpty());
    }

    @Test
    @DisplayName("register → duplicate email → 409 Conflict")
    void register_duplicateEmail_returns409() throws Exception {
        String email = "dup_" + System.nanoTime() + "@example.com";

        RegisterRequest req = new RegisterRequest();
        req.setEmail(email);
        req.setPassword("IntegrationTest@123!");
        req.setFullName("First User");

        // First registration succeeds
        mockMvc.perform(post(AUTH_BASE + "/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isCreated());

        // Second with same email → conflict
        req.setFullName("Second User");
        mockMvc.perform(post(AUTH_BASE + "/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isConflict());
    }

    @Test
    @DisplayName("login with wrong password → 401")
    void login_wrongPassword_returns401() throws Exception {
        LoginRequest req = new LoginRequest();
        req.setIdentifier("nonexistent@example.com");
        req.setPassword("WrongPassword@1!");

        mockMvc.perform(post(AUTH_BASE + "/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("weak password at registration → 400")
    void register_weakPassword_returns400() throws Exception {
        RegisterRequest req = new RegisterRequest();
        req.setEmail("weakpass@example.com");
        req.setPassword("short"); // fails policy
        req.setFullName("Weak Pass User");

        mockMvc.perform(post(AUTH_BASE + "/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("refresh with invalid token → 401")
    void refresh_invalidToken_returns401() throws Exception {
        mockMvc.perform(post(AUTH_BASE + "/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refreshToken\":\"not-a-real-token\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("forgot-password for unknown email → 200 (no enumeration)")
    void forgotPassword_unknownEmail_returns200() throws Exception {
        mockMvc.perform(post(AUTH_BASE + "/forgot-password")
                        .param("identifier", "nobody@unknown.com"))
                .andExpect(status().isOk());
    }
}
