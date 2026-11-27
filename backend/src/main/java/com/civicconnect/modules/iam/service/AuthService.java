package com.civicconnect.modules.iam.service;

import com.civicconnect.modules.iam.dto.*;

/**
 * Authentication service contract.
 * Business logic will be implemented in Phase 4.
 */
public interface AuthService {

    /** Register a new citizen account. Sends OTP for verification. */
    AuthResponse register(RegisterRequest request);

    /** Authenticate with email/phone + password. Returns JWT pair. */
    AuthResponse login(LoginRequest request);

    /** Exchange a valid refresh token for a new access + refresh token pair. */
    AuthResponse refreshToken(RefreshTokenRequest request);

    /** Revoke the given refresh token (logout from one device). */
    void logout(String refreshToken);

    /** Verify OTP and activate account / complete password reset. */
    void verifyOtp(OtpVerifyRequest request);

    /** Trigger OTP send for forgot-password flow. */
    void forgotPassword(String identifier);
}
