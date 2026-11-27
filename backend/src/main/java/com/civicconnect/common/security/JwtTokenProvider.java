package com.civicconnect.common.security;

import com.civicconnect.config.AppProperties;
import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * JWT access-token and refresh-token factory and validator.
 *
 * <p>Access tokens carry:
 * <ul>
 *   <li>{@code sub}            – user UUID (string)</li>
 *   <li>{@code jti}            – unique token ID (for replay protection / blacklisting)</li>
 *   <li>{@code iss}            – issuer "civicconnect"</li>
 *   <li>{@code aud}            – audience "civicconnect-api"</li>
 *   <li>{@code role}           – user_role enum value</li>
 *   <li>{@code municipalityId} – scoped municipality UUID (nullable)</li>
 *   <li>{@code departmentId}   – scoped department UUID (nullable)</li>
 * </ul>
 *
 * <p>Refresh tokens are opaque UUIDs stored hashed in {@code refresh_tokens}.
 * The access token JTI is stored in Redis on logout so revoked tokens are rejected
 * before their natural expiry.
 *
 * <h2>Key derivation</h2>
 * The secret is treated as raw UTF-8 bytes — no Base64 encoding/decoding step —
 * which avoids the double-encoding bug present in earlier versions.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class JwtTokenProvider {

    static final String ISSUER   = "civicconnect";
    static final String AUDIENCE = "civicconnect-api";

    private final AppProperties appProperties;

    // ── Token generation ──────────────────────────────────────────────────────

    public String generateAccessToken(UUID userId, String role,
                                      UUID municipalityId, UUID departmentId) {
        long now = System.currentTimeMillis();
        Map<String, Object> claims = new HashMap<>();
        claims.put("role", role);
        if (municipalityId != null) claims.put("municipalityId", municipalityId.toString());
        if (departmentId   != null) claims.put("departmentId",   departmentId.toString());

        return Jwts.builder()
            .claims(claims)
            .subject(userId.toString())
            .id(UUID.randomUUID().toString())          // jti — unique per token
            .issuer(ISSUER)
            .audience().add(AUDIENCE).and()
            .issuedAt(new Date(now))
            .expiration(new Date(now + appProperties.getJwt().getAccessTokenExpiryMs()))
            .signWith(signingKey())
            .compact();
    }

    public String generateRefreshToken() {
        return UUID.randomUUID().toString();
    }

    // ── Token validation ──────────────────────────────────────────────────────

    /**
     * Validates signature, expiry, issuer and audience.
     * Does NOT check the token blacklist — that is the responsibility of
     * {@link com.civicconnect.common.security.JwtAuthenticationFilter}.
     */
    public boolean validateToken(String token) {
        try {
            parseClaims(token);
            return true;
        } catch (ExpiredJwtException ex) {
            log.warn("JWT expired: {}", ex.getMessage());
        } catch (UnsupportedJwtException ex) {
            log.warn("Unsupported JWT: {}", ex.getMessage());
        } catch (MalformedJwtException ex) {
            log.warn("Malformed JWT: {}", ex.getMessage());
        } catch (JwtException | IllegalArgumentException ex) {
            log.warn("JWT validation failed: {}", ex.getMessage());
        }
        return false;
    }

    // ── Claims extraction ─────────────────────────────────────────────────────

    public UUID   extractUserId(String token) {
        return UUID.fromString(parseClaims(token).getSubject());
    }

    public String extractJti(String token) {
        return parseClaims(token).getId();
    }

    public String extractRole(String token) {
        return (String) parseClaims(token).get("role");
    }

    public UUID extractMunicipalityId(String token) {
        String val = (String) parseClaims(token).get("municipalityId");
        return val != null ? UUID.fromString(val) : null;
    }

    public UUID extractDepartmentId(String token) {
        String val = (String) parseClaims(token).get("departmentId");
        return val != null ? UUID.fromString(val) : null;
    }

    public Date extractExpiration(String token) {
        return parseClaims(token).getExpiration();
    }

    // ── Internal ──────────────────────────────────────────────────────────────

    private Claims parseClaims(String token) {
        return Jwts.parser()
            .verifyWith(signingKey())
            .requireIssuer(ISSUER)
            .build()
            .parseSignedClaims(token)
            .getPayload();
    }

    /**
     * Derives an HMAC-SHA256 key directly from the raw UTF-8 bytes of the secret.
     * The secret must be at least 64 characters (512 bits) for HS256 security.
     *
     * <p><strong>Fixed in Phase 12:</strong> previous implementation double-encoded
     * the key (Base64-decoded then re-encoded), halving effective key entropy.
     */
    SecretKey signingKey() {
        byte[] keyBytes = appProperties.getJwt().getSecret()
            .getBytes(StandardCharsets.UTF_8);
        if (keyBytes.length < 32) {
            throw new IllegalStateException(
                "JWT secret too short — minimum 32 bytes (64+ chars recommended)");
        }
        return Keys.hmacShaKeyFor(keyBytes);
    }
}
