package com.civicconnect.modules.iam.service;

import com.civicconnect.common.audit.AuditEventPublisher;
import com.civicconnect.common.enums.AuthProvider;
import com.civicconnect.common.enums.UserRole;
import com.civicconnect.common.exception.AuthenticationException;
import com.civicconnect.common.exception.BusinessRuleException;
import com.civicconnect.common.exception.ConflictException;
import com.civicconnect.common.security.JwtTokenProvider;
import com.civicconnect.common.util.HashUtils;
import com.civicconnect.config.AppProperties;
import com.civicconnect.modules.iam.dto.*;
import com.civicconnect.modules.iam.entity.*;
import com.civicconnect.modules.iam.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.mockito.Mockito.lenient;

/**
 * Unit tests for {@link AuthServiceImpl}.
 * All dependencies are mocked — no Spring context, no DB.
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("AuthServiceImpl")
class AuthServiceImplTest {

    @Mock private UserRepository         userRepository;
    @Mock private RoleRepository         roleRepository;
    @Mock private RefreshTokenRepository refreshTokenRepository;
    @Mock private OtpRepository          otpRepository;
    @Mock private PasswordEncoder        passwordEncoder;
    @Mock private JwtTokenProvider       jwtTokenProvider;
    @Mock private JavaMailSender         mailSender;
    @Mock private AuditEventPublisher    auditEventPublisher;

    private AuthServiceImpl authService;

    private static final UUID   USER_ID    = UUID.randomUUID();
    private static final String USER_EMAIL = "test@example.com";
    private static final String USER_PASS  = "Password@123!";
    private static final String HASH       = "$2a$10$hashedpassword";

    @BeforeEach
    void setUp() {
        AppProperties props = new AppProperties();
        props.getJwt().setSecret("TestSecretKeyForJwtSigningThatIsAtLeast64CharactersLong!!");
        props.getJwt().setAccessTokenExpiryMs(900_000L);
        props.getJwt().setRefreshTokenExpiryMs(86_400_000L);
        props.getNotification().setOtpExpiryMinutes(10);
        props.getNotification().setOtpMaxAttempts(5);

        authService = new AuthServiceImpl(
                userRepository, roleRepository, refreshTokenRepository,
                otpRepository, passwordEncoder, jwtTokenProvider,
                props, mailSender, auditEventPublisher);
    }

    // ── register ───────────────────────────────────────────────────────────

    @Test
    @DisplayName("register() creates user and returns auth response")
    void register_success() {
        RegisterRequest req = buildRegisterRequest();

        when(userRepository.existsByEmailIgnoreCaseAndDeletedAtIsNull(anyString())).thenReturn(false);
        lenient().when(userRepository.existsByPhoneAndDeletedAtIsNull(anyString())).thenReturn(false);

        Role citizenRole = buildRole(UserRole.CITIZEN);
        when(roleRepository.findByName(UserRole.CITIZEN)).thenReturn(Optional.of(citizenRole));

        User savedUser = buildUser(citizenRole);
        when(userRepository.save(any(User.class))).thenReturn(savedUser);

        when(passwordEncoder.encode(anyString())).thenReturn(HASH);
        when(jwtTokenProvider.generateAccessToken(any(), anyString(), any(), any()))
                .thenReturn("access.token");
        when(jwtTokenProvider.generateRefreshToken()).thenReturn(UUID.randomUUID().toString());
        when(refreshTokenRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        AuthResponse resp = authService.register(req);

        assertThat(resp).isNotNull();
        assertThat(resp.getAccessToken()).isEqualTo("access.token");
        assertThat(resp.getEmail()).isEqualTo(USER_EMAIL);
        verify(userRepository).save(any(User.class));
        verify(otpRepository).save(any());  // OTP sent
    }

    @Test
    @DisplayName("register() throws ConflictException when email is already taken")
    void register_throwsConflictWhenEmailTaken() {
        RegisterRequest req = buildRegisterRequest();
        when(userRepository.existsByEmailIgnoreCaseAndDeletedAtIsNull(USER_EMAIL)).thenReturn(true);

        assertThatThrownBy(() -> authService.register(req))
                .isInstanceOf(ConflictException.class)
                .satisfies(ex -> assertThat(((ConflictException) ex).getErrorCode())
                        .isEqualTo("EMAIL_TAKEN"));
    }

    // ── login ──────────────────────────────────────────────────────────────

    @Test
    @DisplayName("login() returns auth response for valid credentials")
    void login_success() {
        LoginRequest req = new LoginRequest();
        req.setIdentifier(USER_EMAIL);
        req.setPassword(USER_PASS);

        Role citizenRole = buildRole(UserRole.CITIZEN);
        User user = buildUser(citizenRole);
        user.setActive(true);

        when(userRepository.findByEmailIgnoreCase(USER_EMAIL)).thenReturn(Optional.of(user));
        when(passwordEncoder.matches(USER_PASS, HASH)).thenReturn(true);
        when(userRepository.save(any(User.class))).thenReturn(user);
        when(jwtTokenProvider.generateAccessToken(any(), anyString(), any(), any()))
                .thenReturn("access.token");
        when(jwtTokenProvider.generateRefreshToken()).thenReturn(UUID.randomUUID().toString());
        when(refreshTokenRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        AuthResponse resp = authService.login(req);

        assertThat(resp.getAccessToken()).isEqualTo("access.token");
        verify(auditEventPublisher).loginSuccess(any(), anyString(), any());
    }

    @Test
    @DisplayName("login() throws AuthenticationException for wrong password")
    void login_throwsForWrongPassword() {
        LoginRequest req = new LoginRequest();
        req.setIdentifier(USER_EMAIL);
        req.setPassword("WrongPassword!");

        Role citizenRole = buildRole(UserRole.CITIZEN);
        User user = buildUser(citizenRole);
        user.setActive(true);

        when(userRepository.findByEmailIgnoreCase(USER_EMAIL)).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("WrongPassword!", HASH)).thenReturn(false);

        assertThatThrownBy(() -> authService.login(req))
                .isInstanceOf(AuthenticationException.class)
                .satisfies(ex -> assertThat(((AuthenticationException) ex).getErrorCode())
                        .isEqualTo("INVALID_CREDENTIALS"));
        verify(auditEventPublisher).loginFailure(USER_EMAIL);
    }

    @Test
    @DisplayName("login() throws AuthenticationException for unknown user")
    void login_throwsForUnknownUser() {
        LoginRequest req = new LoginRequest();
        req.setIdentifier("unknown@example.com");
        req.setPassword(USER_PASS);

        when(userRepository.findByEmailIgnoreCase("unknown@example.com"))
                .thenReturn(Optional.empty());

        assertThatThrownBy(() -> authService.login(req))
                .isInstanceOf(AuthenticationException.class);
        verify(auditEventPublisher).loginFailure("unknown@example.com");
    }

    @Test
    @DisplayName("login() throws AuthenticationException for deactivated account")
    void login_throwsForDeactivatedAccount() {
        LoginRequest req = new LoginRequest();
        req.setIdentifier(USER_EMAIL);
        req.setPassword(USER_PASS);

        Role citizenRole = buildRole(UserRole.CITIZEN);
        User user = buildUser(citizenRole);
        user.setActive(false);

        when(userRepository.findByEmailIgnoreCase(USER_EMAIL)).thenReturn(Optional.of(user));

        assertThatThrownBy(() -> authService.login(req))
                .isInstanceOf(AuthenticationException.class)
                .satisfies(ex -> assertThat(((AuthenticationException) ex).getErrorCode())
                        .isEqualTo("ACCOUNT_DEACTIVATED"));
    }

    // ── refreshToken ──────────────────────────────────────────────────────

    @Test
    @DisplayName("refreshToken() returns new auth response for valid token")
    void refreshToken_success() {
        String rawToken = UUID.randomUUID().toString();
        String tokenHash = HashUtils.sha256Hex(rawToken);

        Role citizenRole = buildRole(UserRole.CITIZEN);
        User user = buildUser(citizenRole);
        user.setActive(true);

        RefreshToken stored = RefreshToken.builder()
                .user(user)
                .tokenHash(tokenHash)
                .expiresAt(Instant.now().plusSeconds(3600))
                .revoked(false)
                .build();

        when(refreshTokenRepository.findByTokenHashAndRevokedFalse(tokenHash))
                .thenReturn(Optional.of(stored));
        when(refreshTokenRepository.save(any())).thenAnswer(i -> i.getArgument(0));
        when(jwtTokenProvider.generateAccessToken(any(), anyString(), any(), any()))
                .thenReturn("new.access.token");
        when(jwtTokenProvider.generateRefreshToken()).thenReturn(UUID.randomUUID().toString());

        RefreshTokenRequest req = new RefreshTokenRequest();
        req.setRefreshToken(rawToken);

        AuthResponse resp = authService.refreshToken(req);
        assertThat(resp.getAccessToken()).isEqualTo("new.access.token");
        // Old token must be revoked
        assertThat(stored.isRevoked()).isTrue();
        assertThat(stored.getRevocationReason()).isEqualTo("rotated");
    }

    @Test
    @DisplayName("refreshToken() throws for invalid token")
    void refreshToken_throwsForInvalidToken() {
        String rawToken = UUID.randomUUID().toString();
        String tokenHash = HashUtils.sha256Hex(rawToken);

        when(refreshTokenRepository.findByTokenHashAndRevokedFalse(tokenHash))
                .thenReturn(Optional.empty());

        RefreshTokenRequest req = new RefreshTokenRequest();
        req.setRefreshToken(rawToken);

        assertThatThrownBy(() -> authService.refreshToken(req))
                .isInstanceOf(AuthenticationException.class)
                .satisfies(ex -> assertThat(((AuthenticationException) ex).getErrorCode())
                        .isEqualTo("INVALID_TOKEN"));
    }

    @Test
    @DisplayName("refreshToken() throws for expired token")
    void refreshToken_throwsForExpiredToken() {
        String rawToken = UUID.randomUUID().toString();
        String tokenHash = HashUtils.sha256Hex(rawToken);

        Role citizenRole = buildRole(UserRole.CITIZEN);
        User user = buildUser(citizenRole);

        RefreshToken stored = RefreshToken.builder()
                .user(user)
                .tokenHash(tokenHash)
                .expiresAt(Instant.now().minusSeconds(3600)) // already expired
                .revoked(false)
                .build();

        when(refreshTokenRepository.findByTokenHashAndRevokedFalse(tokenHash))
                .thenReturn(Optional.of(stored));
        when(refreshTokenRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        RefreshTokenRequest req = new RefreshTokenRequest();
        req.setRefreshToken(rawToken);

        assertThatThrownBy(() -> authService.refreshToken(req))
                .isInstanceOf(AuthenticationException.class)
                .satisfies(ex -> assertThat(((AuthenticationException) ex).getErrorCode())
                        .isEqualTo("TOKEN_EXPIRED"));
    }

    // ── logout ─────────────────────────────────────────────────────────────

    @Test
    @DisplayName("logout() revokes the refresh token")
    void logout_revokesRefreshToken() {
        String rawToken = UUID.randomUUID().toString();
        String tokenHash = HashUtils.sha256Hex(rawToken);

        Role citizenRole = buildRole(UserRole.CITIZEN);
        User user = buildUser(citizenRole);

        RefreshToken stored = RefreshToken.builder()
                .user(user)
                .tokenHash(tokenHash)
                .expiresAt(Instant.now().plusSeconds(3600))
                .revoked(false)
                .build();

        when(refreshTokenRepository.findByTokenHashAndRevokedFalse(tokenHash))
                .thenReturn(Optional.of(stored));
        when(refreshTokenRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        authService.logout(rawToken);

        assertThat(stored.isRevoked()).isTrue();
        assertThat(stored.getRevocationReason()).isEqualTo("logout");
    }

    @Test
    @DisplayName("logout() is idempotent when token is already revoked")
    void logout_idempotentForAlreadyRevokedToken() {
        String rawToken = UUID.randomUUID().toString();
        String tokenHash = HashUtils.sha256Hex(rawToken);

        when(refreshTokenRepository.findByTokenHashAndRevokedFalse(tokenHash))
                .thenReturn(Optional.empty());

        // Should not throw
        assertThatCode(() -> authService.logout(rawToken)).doesNotThrowAnyException();
        verify(refreshTokenRepository, never()).save(any());
    }

    // ── Helpers ────────────────────────────────────────────────────────────

    private RegisterRequest buildRegisterRequest() {
        RegisterRequest req = new RegisterRequest();
        req.setEmail(USER_EMAIL);
        req.setPassword(USER_PASS);
        req.setFullName("Test User");
        return req;
    }

    private Role buildRole(UserRole role) {
        Role r = new Role();
        r.setName(role);
        return r;
    }

    private User buildUser(Role role) {
        return User.builder()
                .id(USER_ID)
                .email(USER_EMAIL)
                .fullName("Test User")
                .passwordHash(HASH)
                .authProvider(AuthProvider.LOCAL)
                .role(role)
                .active(true)
                .emailVerified(false)
                .loginCount(0)
                .build();
    }
}
