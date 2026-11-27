package com.civicconnect.common.security;

import com.civicconnect.config.AppProperties;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.*;

/**
 * Unit tests for {@link JwtTokenProvider}.
 * No Spring context — pure POJO tests.
 */
@DisplayName("JwtTokenProvider")
class JwtTokenProviderTest {

    private static final String SECRET =
            "TestSecretKeyForJwtSigningThatIsAtLeast64CharactersLongForHmacSha256!!";

    private JwtTokenProvider provider;

    @BeforeEach
    void setUp() {
        AppProperties props = new AppProperties();
        props.getJwt().setSecret(SECRET);
        props.getJwt().setAccessTokenExpiryMs(3_600_000L); // 1h
        props.getJwt().setRefreshTokenExpiryMs(86_400_000L);
        provider = new JwtTokenProvider(props);
    }

    // ── generateAccessToken ────────────────────────────────────────────────

    @Test
    @DisplayName("generates a non-blank access token")
    void generateAccessToken_returnsToken() {
        UUID userId = UUID.randomUUID();
        String token = provider.generateAccessToken(userId, "CITIZEN", null, null);
        assertThat(token).isNotBlank();
    }

    @Test
    @DisplayName("generated token is valid")
    void generateAccessToken_tokenIsValid() {
        UUID userId = UUID.randomUUID();
        String token = provider.generateAccessToken(userId, "CITIZEN", null, null);
        assertThat(provider.validateToken(token)).isTrue();
    }

    @Test
    @DisplayName("extracts correct userId from token")
    void extractUserId_returnsExpectedUserId() {
        UUID userId = UUID.randomUUID();
        String token = provider.generateAccessToken(userId, "CITIZEN", null, null);
        assertThat(provider.extractUserId(token)).isEqualTo(userId);
    }

    @Test
    @DisplayName("extracts correct role from token")
    void extractRole_returnsExpectedRole() {
        UUID userId = UUID.randomUUID();
        String token = provider.generateAccessToken(userId, "DEPT_SUPERVISOR", null, null);
        assertThat(provider.extractRole(token)).isEqualTo("DEPT_SUPERVISOR");
    }

    @Test
    @DisplayName("extracts municipalityId when provided")
    void extractMunicipalityId_returnsValue() {
        UUID userId       = UUID.randomUUID();
        UUID municipality = UUID.randomUUID();
        String token = provider.generateAccessToken(userId, "CITIZEN", municipality, null);
        assertThat(provider.extractMunicipalityId(token)).isEqualTo(municipality);
    }

    @Test
    @DisplayName("municipalityId is null when not provided")
    void extractMunicipalityId_nullWhenAbsent() {
        UUID userId = UUID.randomUUID();
        String token = provider.generateAccessToken(userId, "CITIZEN", null, null);
        assertThat(provider.extractMunicipalityId(token)).isNull();
    }

    @Test
    @DisplayName("extracts departmentId when provided")
    void extractDepartmentId_returnsValue() {
        UUID userId   = UUID.randomUUID();
        UUID deptId   = UUID.randomUUID();
        String token = provider.generateAccessToken(userId, "FIELD_WORKER", null, deptId);
        assertThat(provider.extractDepartmentId(token)).isEqualTo(deptId);
    }

    @Test
    @DisplayName("extracts a non-blank JTI")
    void extractJti_returnsNonBlankValue() {
        UUID userId = UUID.randomUUID();
        String token = provider.generateAccessToken(userId, "CITIZEN", null, null);
        assertThat(provider.extractJti(token)).isNotBlank();
    }

    @Test
    @DisplayName("each token has a unique JTI")
    void eachTokenHasUniqueJti() {
        UUID userId = UUID.randomUUID();
        String t1 = provider.generateAccessToken(userId, "CITIZEN", null, null);
        String t2 = provider.generateAccessToken(userId, "CITIZEN", null, null);
        assertThat(provider.extractJti(t1)).isNotEqualTo(provider.extractJti(t2));
    }

    // ── validateToken ──────────────────────────────────────────────────────

    @Test
    @DisplayName("returns false for a tampered token")
    void validateToken_returnsFalseForTamperedToken() {
        UUID userId = UUID.randomUUID();
        String token = provider.generateAccessToken(userId, "CITIZEN", null, null);
        // Flip a character in the signature
        String tampered = token.substring(0, token.length() - 4) + "XXXX";
        assertThat(provider.validateToken(tampered)).isFalse();
    }

    @Test
    @DisplayName("returns false for a blank token")
    void validateToken_returnsFalseForBlank() {
        assertThat(provider.validateToken("")).isFalse();
    }

    @Test
    @DisplayName("returns false for a completely invalid string")
    void validateToken_returnsFalseForGarbage() {
        assertThat(provider.validateToken("not.a.jwt")).isFalse();
    }

    @Test
    @DisplayName("expired token fails validation")
    void validateToken_returnsFalseForExpiredToken() {
        AppProperties shortProps = new AppProperties();
        shortProps.getJwt().setSecret(SECRET);
        shortProps.getJwt().setAccessTokenExpiryMs(-1000L); // already expired
        JwtTokenProvider shortProvider = new JwtTokenProvider(shortProps);

        UUID userId = UUID.randomUUID();
        String token = shortProvider.generateAccessToken(userId, "CITIZEN", null, null);
        assertThat(shortProvider.validateToken(token)).isFalse();
    }

    // ── generateRefreshToken ───────────────────────────────────────────────

    @Test
    @DisplayName("refresh token is a non-blank UUID-shaped string")
    void generateRefreshToken_returnsNonBlankString() {
        String rt = provider.generateRefreshToken();
        assertThat(rt).isNotBlank();
        // Should parse as UUID without exception
        assertThatCode(() -> UUID.fromString(rt)).doesNotThrowAnyException();
    }

    @Test
    @DisplayName("each refresh token is unique")
    void generateRefreshToken_isUnique() {
        assertThat(provider.generateRefreshToken())
                .isNotEqualTo(provider.generateRefreshToken());
    }

    // ── signingKey edge case ───────────────────────────────────────────────

    @Test
    @DisplayName("short secret throws IllegalStateException")
    void signingKey_throwsForShortSecret() {
        AppProperties badProps = new AppProperties();
        badProps.getJwt().setSecret("short");
        JwtTokenProvider badProvider = new JwtTokenProvider(badProps);
        assertThatThrownBy(badProvider::signingKey)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("JWT secret too short");
    }
}
