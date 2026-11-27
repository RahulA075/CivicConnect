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

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Security integration tests: JWT lifecycle, blacklist, headers, rate limiting.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureMockMvc
@Testcontainers
@ActiveProfiles("test")
@Tag("integration")
@DisplayName("Security Integration Tests")
class SecurityIntegrationTest {

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

    // ── Security headers ───────────────────────────────────────────────────

    @Test
    @DisplayName("Every response includes Content-Security-Policy header")
    void everyResponse_hasCSPHeader() throws Exception {
        MvcResult result = mockMvc.perform(get("/api/v1/auth/health-check-nonexistent"))
                .andReturn();

        // CSP should be present regardless of the status code
        String csp = result.getResponse().getHeader("Content-Security-Policy");
        assertThat(csp).isNotNull();
        assertThat(csp).contains("default-src 'self'");
    }

    @Test
    @DisplayName("Every response includes X-Frame-Options: DENY")
    void everyResponse_hasXFrameOptions() throws Exception {
        MvcResult result = mockMvc.perform(get("/actuator/health")).andReturn();
        // Either from SecurityHeadersFilter or Spring Security headers layer
        String xfo = result.getResponse().getHeader("X-Frame-Options");
        assertThat(xfo).isNotNull().isEqualToIgnoringCase("DENY");
    }

    @Test
    @DisplayName("Every response includes X-Content-Type-Options: nosniff")
    void everyResponse_hasXContentTypeOptions() throws Exception {
        MvcResult result = mockMvc.perform(get("/actuator/health")).andReturn();
        assertThat(result.getResponse().getHeader("X-Content-Type-Options"))
                .isEqualToIgnoringCase("nosniff");
    }

    // ── JWT validation ─────────────────────────────────────────────────────

    @Test
    @DisplayName("Malformed Bearer token → 401")
    void malformedToken_returns401() throws Exception {
        mockMvc.perform(get("/api/v1/issues/my")
                        .header("Authorization", "Bearer this.is.not.a.valid.jwt"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("Missing Authorization header → 401 for protected endpoint")
    void noToken_returns401() throws Exception {
        mockMvc.perform(get("/api/v1/issues/my"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("Wrong Authorization scheme → 401")
    void wrongScheme_returns401() throws Exception {
        mockMvc.perform(get("/api/v1/issues/my")
                        .header("Authorization", "Basic dXNlcjpwYXNz"))
                .andExpect(status().isUnauthorized());
    }

    // ── Logout + blacklist ─────────────────────────────────────────────────

    @Test
    @DisplayName("Logout then reuse access token → 401 (blacklisted)")
    void logout_thenReuseToken_returns401() throws Exception {
        String email = "logout_test_" + System.nanoTime() + "@example.com";

        // Register
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                            {"email":"%s","password":"Logout@Test123!","fullName":"Logout User"}
                            """.formatted(email)))
                .andExpect(status().isCreated());

        // Login
        MvcResult loginResult = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                            {"identifier":"%s","password":"Logout@Test123!"}
                            """.formatted(email)))
                .andExpect(status().isOk())
                .andReturn();

        var loginNode = objectMapper.readTree(loginResult.getResponse().getContentAsString());
        String accessToken  = loginNode.at("/data/accessToken").asText();
        String refreshToken = loginNode.at("/data/refreshToken").asText();

        // Verify token works before logout
        mockMvc.perform(get("/api/v1/issues/my")
                        .header("Authorization", "Bearer " + accessToken))
                .andExpect(status().isOk());

        // Logout — blacklists access token
        mockMvc.perform(post("/api/v1/auth/logout")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refreshToken\":\"" + refreshToken + "\"}")
                        .header("Authorization", "Bearer " + accessToken))
                .andExpect(status().isOk());

        // Same access token should now be rejected
        mockMvc.perform(get("/api/v1/issues/my")
                        .header("Authorization", "Bearer " + accessToken))
                .andExpect(status().isUnauthorized());
    }

    // ── Public endpoints ───────────────────────────────────────────────────

    @Test
    @DisplayName("Public endpoints accessible without token")
    void publicEndpoints_accessibleWithoutToken() throws Exception {
        mockMvc.perform(get("/actuator/health"))
                .andExpect(status().isOk());
    }

    @Test
    @DisplayName("Actuator metrics endpoint locked down for unauthenticated")
    void actuatorMetrics_lockedDown() throws Exception {
        mockMvc.perform(get("/actuator/prometheus"))
                .andExpect(status().isUnauthorized());
    }
}
