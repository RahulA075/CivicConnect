package com.civicconnect.modules.iam.service;

import com.civicconnect.common.audit.AuditEventPublisher;
import com.civicconnect.common.enums.AuthProvider;
import com.civicconnect.common.enums.UserRole;
import com.civicconnect.common.exception.AuthenticationException;
import com.civicconnect.common.exception.BusinessRuleException;
import com.civicconnect.common.exception.ConflictException;
import com.civicconnect.common.exception.ResourceNotFoundException;
import com.civicconnect.common.security.JwtTokenProvider;
import com.civicconnect.common.util.HashUtils;
import com.civicconnect.config.AppProperties;
import com.civicconnect.modules.iam.dto.*;
import com.civicconnect.modules.iam.entity.OtpVerification;
import com.civicconnect.modules.iam.entity.RefreshToken;
import com.civicconnect.modules.iam.entity.Role;
import com.civicconnect.modules.iam.entity.User;
import com.civicconnect.modules.iam.repository.OtpRepository;
import com.civicconnect.modules.iam.repository.RefreshTokenRepository;
import com.civicconnect.modules.iam.repository.RoleRepository;
import com.civicconnect.modules.iam.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.security.SecureRandom;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

/**
 * Full implementation of all authentication flows:
 * <ul>
 *   <li>Register (citizen) → stores user, sends OTP for email verification</li>
 *   <li>Login (email or phone + password) → returns JWT pair</li>
 *   <li>Refresh token → validates hashed token, issues new pair</li>
 *   <li>Logout → revokes refresh token</li>
 *   <li>Verify OTP → activates account or completes password reset</li>
 *   <li>Forgot password → sends reset OTP</li>
 * </ul>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

    private final UserRepository         userRepository;
    private final RoleRepository         roleRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final OtpRepository          otpRepository;
    private final PasswordEncoder        passwordEncoder;
    private final JwtTokenProvider       jwtTokenProvider;
    private final AppProperties          appProperties;
    private final JavaMailSender         mailSender;
    private final AuditEventPublisher    auditEventPublisher;

    private static final SecureRandom RANDOM = new SecureRandom();

    // ── Register ─────────────────────────────────────────────────────────────

    @Override
    @Transactional
    public AuthResponse register(RegisterRequest request) {
        // Validate uniqueness
        if (StringUtils.hasText(request.getEmail())
                && userRepository.existsByEmailIgnoreCaseAndDeletedAtIsNull(request.getEmail())) {
            throw new ConflictException("EMAIL_TAKEN", "Email address is already registered");
        }
        if (StringUtils.hasText(request.getPhone())
                && userRepository.existsByPhoneAndDeletedAtIsNull(request.getPhone())) {
            throw new ConflictException("PHONE_TAKEN", "Phone number is already registered");
        }

        Role citizenRole = roleRepository.findByName(UserRole.CITIZEN)
            .orElseThrow(() -> new ResourceNotFoundException("Role CITIZEN not found — check DB seeding"));

        User user = User.builder()
            .fullName(request.getFullName())
            .email(request.getEmail() != null ? request.getEmail().toLowerCase() : null)
            .phone(request.getPhone())
            .passwordHash(passwordEncoder.encode(request.getPassword()))
            .authProvider(AuthProvider.LOCAL)
            .city(request.getCity())
            .role(citizenRole)
            .emailVerified(false)
            .active(true)
            .build();

        user = userRepository.save(user);

        // Send OTP for email verification
        String identifier = StringUtils.hasText(request.getEmail())
            ? request.getEmail().toLowerCase()
            : request.getPhone();
        sendOtp(identifier, OtpVerification.Purpose.REGISTRATION);

        log.info("Registered new citizen user id={}", user.getId());

        // Return tokens so the app can immediately use the API
        // (account is active but email not yet verified)
        return buildAuthResponse(user);
    }

    // ── Login ────────────────────────────────────────────────────────────────

    @Override
    @Transactional
    public AuthResponse login(LoginRequest request) {
        String identifier = request.getIdentifier().trim().toLowerCase();

        User user = findUserByIdentifier(identifier)
            .orElseThrow(() -> {
                auditEventPublisher.loginFailure(identifier);
                return new AuthenticationException("INVALID_CREDENTIALS", "Invalid credentials");
            });

        if (!user.isActive()) {
            throw new AuthenticationException("ACCOUNT_DEACTIVATED", "Account is deactivated. Contact support.");
        }
        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            auditEventPublisher.loginFailure(identifier);
            throw new AuthenticationException("INVALID_CREDENTIALS", "Invalid credentials");
        }

        user.setLastLoginAt(Instant.now());
        user.setLoginCount(user.getLoginCount() + 1);
        userRepository.save(user);

        log.info("User logged in id={} role={}", user.getId(), user.getRole().getName());

        UUID municipalityId = user.getMunicipality() != null ? user.getMunicipality().getId() : null;
        auditEventPublisher.loginSuccess(user.getId(), user.getFullName(), municipalityId);

        return buildAuthResponse(user);
    }

    // ── Refresh token ────────────────────────────────────────────────────────

    @Override
    @Transactional
    public AuthResponse refreshToken(RefreshTokenRequest request) {
        String rawToken  = request.getRefreshToken();
        String tokenHash = HashUtils.sha256Hex(rawToken);

        RefreshToken stored = refreshTokenRepository
            .findByTokenHashAndRevokedFalse(tokenHash)
            .orElseThrow(() -> new AuthenticationException("INVALID_TOKEN", "Invalid or expired refresh token"));

        if (stored.getExpiresAt().isBefore(Instant.now())) {
            stored.setRevoked(true);
            stored.setRevokedAt(Instant.now());
            stored.setRevocationReason("expired");
            refreshTokenRepository.save(stored);
            throw new AuthenticationException("TOKEN_EXPIRED", "Refresh token has expired. Please log in again.");
        }

        // Rotate: revoke old, issue new
        stored.setRevoked(true);
        stored.setRevokedAt(Instant.now());
        stored.setRevocationReason("rotated");
        refreshTokenRepository.save(stored);

        User user = stored.getUser();
        if (!user.isActive()) {
            throw new AuthenticationException("ACCOUNT_DEACTIVATED", "Account is deactivated.");
        }

        return buildAuthResponse(user);
    }

    // ── Logout ───────────────────────────────────────────────────────────────

    @Override
    @Transactional
    public void logout(String refreshToken) {
        String tokenHash = HashUtils.sha256Hex(refreshToken);
        refreshTokenRepository.findByTokenHashAndRevokedFalse(tokenHash)
            .ifPresent(t -> {
                t.setRevoked(true);
                t.setRevokedAt(Instant.now());
                t.setRevocationReason("logout");
                refreshTokenRepository.save(t);
            });
    }

    // ── Verify OTP ───────────────────────────────────────────────────────────

    @Override
    @Transactional
    public void verifyOtp(OtpVerifyRequest request) {
        OtpVerification.Purpose purpose = parsePurpose(request.getPurpose());
        String identifier = request.getIdentifier().trim().toLowerCase();

        OtpVerification otp = otpRepository
            .findValidOtp(identifier, purpose, Instant.now())
            .orElseThrow(() -> new BusinessRuleException("OTP_INVALID", "OTP is invalid or has expired"));

        if (otp.getAttempts() >= otp.getMaxAttempts()) {
            throw new BusinessRuleException("OTP_MAX_ATTEMPTS", "Maximum OTP attempts exceeded. Request a new OTP.");
        }

        String inputHash = HashUtils.sha256Hex(request.getOtp());
        otp.setAttempts(otp.getAttempts() + 1);

        if (!inputHash.equals(otp.getOtpHash())) {
            otpRepository.save(otp);
            throw new BusinessRuleException("OTP_INCORRECT", "Incorrect OTP");
        }

        otp.setUsed(true);
        otpRepository.save(otp);

        if (purpose == OtpVerification.Purpose.REGISTRATION) {
            userRepository.findByEmailIgnoreCase(identifier).ifPresent(u -> {
                u.setEmailVerified(true);
                userRepository.save(u);
            });
        }
    }

    // ── Forgot password ───────────────────────────────────────────────────────

    @Override
    @Transactional
    public void forgotPassword(String identifier) {
        identifier = identifier.trim().toLowerCase();
        // Only send OTP if the account exists — don't leak existence
        boolean exists = userRepository.findByEmailIgnoreCase(identifier).isPresent()
            || userRepository.findByPhoneAndDeletedAtIsNull(identifier).isPresent();

        if (exists) {
            sendOtp(identifier, OtpVerification.Purpose.PASSWORD_RESET);
        }
        // Always return success to prevent account enumeration
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private AuthResponse buildAuthResponse(User user) {
        UUID municipalityId = user.getMunicipality() != null ? user.getMunicipality().getId() : null;
        UUID departmentId   = user.getDepartment()   != null ? user.getDepartment().getId()   : null;

        String accessToken  = jwtTokenProvider.generateAccessToken(
            user.getId(), user.getRole().getName().name(), municipalityId, departmentId);
        String rawRefresh   = jwtTokenProvider.generateRefreshToken();

        // Store hashed refresh token
        RefreshToken rt = RefreshToken.builder()
            .user(user)
            .tokenHash(HashUtils.sha256Hex(rawRefresh))
            .expiresAt(Instant.now().plusMillis(appProperties.getJwt().getRefreshTokenExpiryMs()))
            .build();
        refreshTokenRepository.save(rt);

        return AuthResponse.builder()
            .accessToken(accessToken)
            .refreshToken(rawRefresh)
            .tokenType("Bearer")
            .expiresIn(appProperties.getJwt().getAccessTokenExpiryMs() / 1000)
            .userId(user.getId())
            .role(user.getRole().getName().name())
            .fullName(user.getFullName())
            .email(user.getEmail())
            .municipalityId(municipalityId)
            .departmentId(departmentId)
            .build();
    }

    private void sendOtp(String identifier, OtpVerification.Purpose purpose) {
        String rawOtp    = generateNumericOtp(6);
        String otpHash   = HashUtils.sha256Hex(rawOtp);
        int    expiryMin = appProperties.getNotification().getOtpExpiryMinutes();

        OtpVerification record = OtpVerification.builder()
            .identifier(identifier)
            .purpose(purpose)
            .otpHash(otpHash)
            .maxAttempts(appProperties.getNotification().getOtpMaxAttempts())
            .expiresAt(Instant.now().plusSeconds(expiryMin * 60L))
            .build();
        otpRepository.save(record);

        // Send email
        try {
            SimpleMailMessage mail = new SimpleMailMessage();
            mail.setTo(identifier);
            mail.setSubject("CivicConnect — Your OTP");
            mail.setText(String.format(
                "Your OTP is: %s%nIt expires in %d minutes.%nDo not share it with anyone.",
                rawOtp, expiryMin));
            mailSender.send(mail);
            log.info("OTP sent to {} for purpose {}", identifier, purpose);
        } catch (Exception e) {
            log.error("Failed to send OTP email to {}: {}", identifier, e.getMessage());
            // Don't throw — OTP is stored; user can request resend
        }
    }

    private String generateNumericOtp(int length) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < length; i++) {
            sb.append(RANDOM.nextInt(10));
        }
        return sb.toString();
    }

    private Optional<User> findUserByIdentifier(String identifier) {
        if (identifier.contains("@")) {
            return userRepository.findByEmailIgnoreCase(identifier);
        }
        return userRepository.findByPhoneAndDeletedAtIsNull(identifier);
    }

    private OtpVerification.Purpose parsePurpose(String raw) {
        try {
            return OtpVerification.Purpose.valueOf(raw.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new BusinessRuleException("UNKNOWN_PURPOSE", "Unknown OTP purpose: " + raw);
        }
    }
}
