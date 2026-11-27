package com.civicconnect.config;

import com.civicconnect.common.security.JwtAuthenticationFilter;
import com.civicconnect.common.security.UserDetailsServiceImpl;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.annotation.web.configurers.HeadersConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.web.header.writers.ReferrerPolicyHeaderWriter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

/**
 * Spring Security 6 configuration — Phase 12 hardened.
 *
 * <ul>
 *   <li>Stateless JWT authentication (no sessions)</li>
 *   <li>JWT token blacklist check in filter chain</li>
 *   <li>HTTP security headers (CSP, HSTS, X-Frame-Options, etc.)</li>
 *   <li>CORS configured from {@link AppProperties}</li>
 *   <li>CSRF disabled (stateless REST API)</li>
 *   <li>Method-level security enabled via {@code @PreAuthorize}</li>
 *   <li>Actuator endpoints locked down to SYSTEM_ADMIN</li>
 *   <li>BCrypt cost factor 12</li>
 * </ul>
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final UserDetailsServiceImpl  userDetailsService;
    private final AppProperties           appProperties;

    /** Fully public endpoints — no JWT required. */
    private static final String[] PUBLIC_GET_ENDPOINTS = {
        "/api/v1/public/**",
        "/api/v1/ai/suggest",          // smart suggestions (lightweight, no auth)
        "/api-docs/**",
        "/swagger-ui/**",
        "/swagger-ui.html",
        "/actuator/health",
        "/actuator/info"
    };

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            // ── CORS ──────────────────────────────────────────────────────────
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))

            // ── CSRF (disabled — stateless JWT API) ───────────────────────────
            .csrf(AbstractHttpConfigurer::disable)

            // ── Session (stateless) ───────────────────────────────────────────
            .sessionManagement(sm ->
                sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))

            // ── Security headers ──────────────────────────────────────────────
            // Note: fine-grained CSP is set in SecurityHeadersFilter; here we
            // add Spring Security's built-in defaults as a second layer.
            .headers(headers -> headers
                .frameOptions(HeadersConfigurer.FrameOptionsConfig::deny)
                .contentTypeOptions(ct -> {})           // X-Content-Type-Options: nosniff
                .httpStrictTransportSecurity(hsts -> hsts
                    .includeSubDomains(true)
                    .maxAgeInSeconds(31_536_000)
                    .preload(true))
                .referrerPolicy(rp -> rp
                    .policy(ReferrerPolicyHeaderWriter.ReferrerPolicy.STRICT_ORIGIN_WHEN_CROSS_ORIGIN))
            )

            // ── URL authorisation rules ────────────────────────────────────────
            .authorizeHttpRequests(auth -> auth
                // Auth endpoints — public
                .requestMatchers("/api/v1/auth/**").permitAll()
                // Public read endpoints
                .requestMatchers(HttpMethod.GET, PUBLIC_GET_ENDPOINTS).permitAll()
                .requestMatchers(PUBLIC_GET_ENDPOINTS).permitAll()
                // OPTIONS pre-flight
                .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                // Actuator management — SYSTEM_ADMIN only (except health/info above)
                .requestMatchers("/actuator/**").hasRole("SYSTEM_ADMIN")
                // Everything else requires authentication
                .anyRequest().authenticated()
            )

            // ── Auth provider + JWT filter ─────────────────────────────────────
            .authenticationProvider(authenticationProvider())
            .addFilterBefore(jwtAuthenticationFilter,
                UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public AuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider provider = new DaoAuthenticationProvider();
        provider.setUserDetailsService(userDetailsService);
        provider.setPasswordEncoder(passwordEncoder());
        return provider;
    }

    @Bean
    public AuthenticationManager authenticationManager(
            AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    /**
     * BCrypt with cost factor 12 (~250 ms on modern hardware).
     * Deliberately slow to resist offline brute-force attacks.
     */
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder(12);
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        List<String> origins = List.of(
            appProperties.getCors().getAllowedOrigins().split(","));
        config.setAllowedOrigins(origins);
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        // Explicitly whitelist headers instead of wildcard when credentials are sent
        config.setAllowedHeaders(List.of(
            "Authorization", "Content-Type", "X-Request-Id", "X-Forwarded-For", "Accept"));
        config.setExposedHeaders(List.of("Authorization", "X-Request-Id", "X-Rate-Limit-Remaining"));
        config.setAllowCredentials(true);
        config.setMaxAge(appProperties.getCors().getMaxAgeSeconds());

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}
