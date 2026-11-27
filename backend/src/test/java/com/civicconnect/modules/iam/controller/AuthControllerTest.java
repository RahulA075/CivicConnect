package com.civicconnect.modules.iam.controller;

import com.civicconnect.common.exception.GlobalExceptionHandler;
import com.civicconnect.common.security.JwtAuthenticationFilter;
import com.civicconnect.common.security.JwtTokenProvider;
import com.civicconnect.common.security.TokenBlacklistService;
import com.civicconnect.common.security.UserDetailsServiceImpl;
import com.civicconnect.config.TestSecurityConfig;
import com.civicconnect.modules.iam.dto.*;
import com.civicconnect.modules.iam.service.AuthService;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.io.IOException;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Controller slice tests for {@link AuthController}.
 * {@link TestSecurityConfig} replaces real security with permit-all + no-op props.
 */
@WebMvcTest(AuthController.class)
@Import({TestSecurityConfig.class, GlobalExceptionHandler.class})
@ActiveProfiles("test")
@DisplayName("AuthController API")
class AuthControllerTest {

    @Autowired MockMvc      mockMvc;
    @Autowired ObjectMapper objectMapper;

    // Service beans under test
    @MockBean AuthService             authService;
    @MockBean TokenBlacklistService   blacklistService;
    @MockBean JwtAuthenticationFilter jwtAuthenticationFilter;
    @MockBean JwtTokenProvider        jwtTokenProvider;
    @MockBean UserDetailsServiceImpl  userDetailsService;

    @BeforeEach
    void configureFilterPassThrough() throws ServletException, IOException {
        // The mocked filter must pass requests through to the controller
        doAnswer(inv -> {
            FilterChain chain = inv.getArgument(2);
            chain.doFilter(inv.getArgument(0), inv.getArgument(1));
            return null;
        }).when(jwtAuthenticationFilter)
          .doFilter(any(HttpServletRequest.class),
                    any(HttpServletResponse.class),
                    any(FilterChain.class));
    }

    private static final String BASE = "/api/v1/auth";

    // ── POST /register ─────────────────────────────────────────────────────

    @Test
    @DisplayName("POST /register → 201 with valid payload")
    void register_returns201() throws Exception {
        when(authService.register(any(RegisterRequest.class)))
                .thenReturn(buildAuthResponse());

        mockMvc.perform(post(BASE + "/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(buildRegisterRequest())))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.accessToken").value("access.token.here"));
    }

    @Test
    @DisplayName("POST /register → 400 when fullName missing")
    void register_returns400WhenFullNameMissing() throws Exception {
        RegisterRequest req = buildRegisterRequest();
        req.setFullName(null);

        mockMvc.perform(post(BASE + "/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("POST /register → 400 when password too weak")
    void register_returns400WhenPasswordWeak() throws Exception {
        RegisterRequest req = buildRegisterRequest();
        req.setPassword("weak");

        mockMvc.perform(post(BASE + "/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest());
    }

    // ── POST /login ────────────────────────────────────────────────────────

    @Test
    @DisplayName("POST /login → 200 with valid credentials")
    void login_returns200() throws Exception {
        when(authService.login(any(LoginRequest.class))).thenReturn(buildAuthResponse());

        LoginRequest req = new LoginRequest();
        req.setIdentifier("test@example.com");
        req.setPassword("Password@123!");

        mockMvc.perform(post(BASE + "/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.accessToken").exists());
    }

    @Test
    @DisplayName("POST /login → 400 when identifier blank")
    void login_returns400WhenIdentifierBlank() throws Exception {
        LoginRequest req = new LoginRequest();
        req.setIdentifier("");
        req.setPassword("Password@123!");

        mockMvc.perform(post(BASE + "/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest());
    }

    // ── POST /refresh ──────────────────────────────────────────────────────

    @Test
    @DisplayName("POST /refresh → 200 with valid token")
    void refresh_returns200() throws Exception {
        when(authService.refreshToken(any(RefreshTokenRequest.class)))
                .thenReturn(buildAuthResponse());

        RefreshTokenRequest req = new RefreshTokenRequest();
        req.setRefreshToken(UUID.randomUUID().toString());

        mockMvc.perform(post(BASE + "/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.accessToken").value("access.token.here"));
    }

    // ── POST /verify-otp ───────────────────────────────────────────────────

    @Test
    @DisplayName("POST /verify-otp → 200 with valid payload")
    void verifyOtp_returns200() throws Exception {
        doNothing().when(authService).verifyOtp(any(OtpVerifyRequest.class));

        OtpVerifyRequest req = new OtpVerifyRequest();
        req.setIdentifier("test@example.com");
        req.setOtp("123456");
        req.setPurpose("REGISTRATION");

        mockMvc.perform(post(BASE + "/verify-otp")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    // ── POST /forgot-password ──────────────────────────────────────────────

    @Test
    @DisplayName("POST /forgot-password → 200 regardless of account existence")
    void forgotPassword_returns200() throws Exception {
        doNothing().when(authService).forgotPassword(anyString());

        mockMvc.perform(post(BASE + "/forgot-password")
                        .param("identifier", "anyone@example.com"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    // ── Helpers ────────────────────────────────────────────────────────────

    private RegisterRequest buildRegisterRequest() {
        RegisterRequest req = new RegisterRequest();
        req.setEmail("test@example.com");
        req.setPassword("SecurePass@123!");
        req.setFullName("Test User");
        return req;
    }

    private AuthResponse buildAuthResponse() {
        return AuthResponse.builder()
                .accessToken("access.token.here")
                .refreshToken(UUID.randomUUID().toString())
                .tokenType("Bearer")
                .expiresIn(900L)
                .userId(UUID.randomUUID())
                .role("CITIZEN")
                .fullName("Test User")
                .email("test@example.com")
                .build();
    }
}
