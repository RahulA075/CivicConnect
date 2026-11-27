package com.civicconnect.common.security;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

import java.time.Duration;
import java.util.Date;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.mockito.Mockito.lenient;

/**
 * Unit tests for {@link TokenBlacklistService}.
 * Redis is mocked — no container required.
 * Uses lenient() stubs where needed to avoid UnnecessaryStubbingException.
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("TokenBlacklistService")
class TokenBlacklistServiceTest {

    @Mock
    private StringRedisTemplate redisTemplate;

    @Mock
    private ValueOperations<String, String> valueOps;

    private TokenBlacklistService service;

    @BeforeEach
    void setUp() {
        // lenient: not every test exercises opsForValue()
        lenient().when(redisTemplate.opsForValue()).thenReturn(valueOps);
        service = new TokenBlacklistService(redisTemplate);
    }

    // ── blacklist ──────────────────────────────────────────────────────────

    @Test
    @DisplayName("blacklist() calls Redis set with correct key and positive TTL")
    void blacklist_callsRedisSet() {
        String jti = UUID.randomUUID().toString();
        Date expiry = new Date(System.currentTimeMillis() + 60_000); // 1 min future

        service.blacklist(jti, expiry);

        verify(valueOps).set(eq("jti:" + jti), eq("1"), any(Duration.class));
    }

    @Test
    @DisplayName("blacklist() skips Redis when token is already expired")
    void blacklist_skipsWhenAlreadyExpired() {
        String jti = UUID.randomUUID().toString();
        Date expiry = new Date(System.currentTimeMillis() - 5_000); // 5s in the past

        service.blacklist(jti, expiry);

        verifyNoInteractions(valueOps);
    }

    @Test
    @DisplayName("blacklist() swallows Redis failure gracefully")
    void blacklist_swallowsRedisFailure() {
        String jti = UUID.randomUUID().toString();
        Date expiry = new Date(System.currentTimeMillis() + 60_000);

        doThrow(new RuntimeException("Redis connection refused"))
                .when(valueOps).set(anyString(), anyString(), any(Duration.class));

        // Should not throw
        service.blacklist(jti, expiry);
    }

    // ── isBlacklisted ──────────────────────────────────────────────────────

    @Test
    @DisplayName("isBlacklisted() returns true when Redis has the key")
    void isBlacklisted_returnsTrueWhenKeyExists() {
        String jti = UUID.randomUUID().toString();
        when(redisTemplate.hasKey("jti:" + jti)).thenReturn(Boolean.TRUE);

        assertThat(service.isBlacklisted(jti)).isTrue();
    }

    @Test
    @DisplayName("isBlacklisted() returns false when Redis does not have the key")
    void isBlacklisted_returnsFalseWhenKeyAbsent() {
        String jti = UUID.randomUUID().toString();
        when(redisTemplate.hasKey("jti:" + jti)).thenReturn(Boolean.FALSE);

        assertThat(service.isBlacklisted(jti)).isFalse();
    }

    @Test
    @DisplayName("isBlacklisted() returns false on Redis failure (fail-open)")
    void isBlacklisted_returnsFalseOnRedisFailure() {
        String jti = UUID.randomUUID().toString();
        when(redisTemplate.hasKey(anyString()))
                .thenThrow(new RuntimeException("Redis down"));

        assertThat(service.isBlacklisted(jti)).isFalse();
    }
}
