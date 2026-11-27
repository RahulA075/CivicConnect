package com.civicconnect.modules.iam.controller;

import com.civicconnect.common.response.ApiResponse;
import com.civicconnect.common.security.TokenBlacklistService;
import com.civicconnect.modules.iam.dto.*;
import com.civicconnect.modules.iam.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;

/**
 * Authentication endpoints — all public (no JWT required).
 * Base path: /api/v1/auth
 */
@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
@Tag(name = "Authentication", description = "Register, login, OTP verification, token refresh")
public class AuthController {

    private final AuthService            authService;
    private final TokenBlacklistService  blacklistService;

    @Operation(summary = "Register a new citizen account")
    @PostMapping("/register")
    public ResponseEntity<ApiResponse<AuthResponse>> register(
            @Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.success(authService.register(request), "Account created successfully"));
    }

    @Operation(summary = "Login with email/phone + password")
    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(
            @Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(ApiResponse.success(authService.login(request)));
    }

    @Operation(summary = "Refresh access token using refresh token")
    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<AuthResponse>> refresh(
            @Valid @RequestBody RefreshTokenRequest request) {
        return ResponseEntity.ok(ApiResponse.success(authService.refreshToken(request)));
    }

    @Operation(summary = "Logout — revoke refresh token and blacklist access token")
    @PostMapping("/logout")
    @SecurityRequirement(name = "bearerAuth")
    public ResponseEntity<ApiResponse<Void>> logout(
            @Valid @RequestBody RefreshTokenRequest request,
            HttpServletRequest httpRequest) {
        // Revoke the refresh token
        authService.logout(request.getRefreshToken());
        // Blacklist the current access token so it cannot be reused until expiry
        String jti    = (String) httpRequest.getAttribute("jwtJti");
        Object expiry = httpRequest.getAttribute("jwtExpiry");
        if (StringUtils.hasText(jti) && expiry instanceof java.util.Date expiryDate) {
            blacklistService.blacklist(jti, expiryDate);
        }
        return ResponseEntity.ok(ApiResponse.ok("Logged out successfully"));
    }

    @Operation(summary = "Verify OTP for registration or password reset")
    @PostMapping("/verify-otp")
    public ResponseEntity<ApiResponse<Void>> verifyOtp(
            @Valid @RequestBody OtpVerifyRequest request) {
        authService.verifyOtp(request);
        return ResponseEntity.ok(ApiResponse.ok("OTP verified successfully"));
    }

    @Operation(summary = "Request password reset OTP")
    @PostMapping("/forgot-password")
    public ResponseEntity<ApiResponse<Void>> forgotPassword(
            @RequestParam String identifier) {
        authService.forgotPassword(identifier);
        return ResponseEntity.ok(ApiResponse.ok("OTP sent to your registered email/phone"));
    }
}
