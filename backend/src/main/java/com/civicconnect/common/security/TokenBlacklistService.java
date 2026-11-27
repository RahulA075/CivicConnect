package com.civicconnect.common.security;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.Date;

/**
 * Redis-backed access-token blacklist.
 *
 * <p>When a user logs out or a token is force-revoked, the token's JTI
 * (JWT ID) is stored in Redis with a TTL equal to the token's remaining
 * lifetime. Subsequent requests carrying that JTI are rejected even though
 * the token signature is still valid.
 *
 * <p>Key format: {@code jti:<jti>} → value "1"
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class TokenBlacklistService {

    private static final String KEY_PREFIX = "jti:";
    private final StringRedisTemplate redisTemplate;

    /**
     * Blacklists a token by its JTI until the token would naturally expire.
     *
     * @param jti       the JWT ID claim value
     * @param expiry    the token expiry {@link Date}
     */
    public void blacklist(String jti, Date expiry) {
        long ttlMs = expiry.getTime() - System.currentTimeMillis();
        if (ttlMs <= 0) return; // Already expired — no need to blacklist

        try {
            redisTemplate.opsForValue()
                .set(KEY_PREFIX + jti, "1", Duration.ofMillis(ttlMs));
            log.debug("Blacklisted token jti={} for {}ms", jti, ttlMs);
        } catch (Exception e) {
            // Redis failure must not block the logout response
            log.error("Failed to blacklist token jti={}: {}", jti, e.getMessage());
        }
    }

    /**
     * Returns {@code true} if this JTI has been blacklisted.
     */
    public boolean isBlacklisted(String jti) {
        try {
            return Boolean.TRUE.equals(
                redisTemplate.hasKey(KEY_PREFIX + jti));
        } catch (Exception e) {
            // On Redis failure, fail open (don't block legitimate requests)
            log.error("Redis blacklist check failed for jti={}: {}", jti, e.getMessage());
            return false;
        }
    }
}
