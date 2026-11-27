package com.civicconnect.config;

import com.civicconnect.common.security.RateLimitFilter;
import com.civicconnect.common.security.SecurityHeadersFilter;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.web.SecurityFilterChain;

/**
 * Security configuration for {@code @WebMvcTest} slices.
 *
 * Disables CSRF and permits all requests so controller logic — not
 * authentication — is the focus of the test.
 *
 * Also provides no-op replacements for the custom servlet filters
 * that require {@link AppProperties} at construction time.
 */
@TestConfiguration
public class TestSecurityConfig {

    /** Permit-all, no CSRF — used in @WebMvcTest slices. */
    @Bean
    @Primary
    public SecurityFilterChain testSecurityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(AbstractHttpConfigurer::disable)
            .authorizeHttpRequests(auth -> auth.anyRequest().permitAll());
        return http.build();
    }

    /** No-op AppProperties so RateLimitFilter and others can construct. */
    @Bean
    @Primary
    public AppProperties testAppProperties() {
        AppProperties props = new AppProperties();
        props.getJwt().setSecret(
            "TestSecretKeyForJwtSigningThatIsAtLeast64CharactersLongForHmacSha256!!");
        props.getJwt().setAccessTokenExpiryMs(3_600_000L);
        props.getJwt().setRefreshTokenExpiryMs(86_400_000L);
        props.getRateLimit().setCapacity(1000);
        props.getRateLimit().setRefillTokens(1000);
        props.getRateLimit().setRefillDurationSeconds(60);
        props.getCors().setAllowedOrigins("http://localhost:3000");
        props.getNotification().setFcmCredentialsPath("");
        return props;
    }
}
