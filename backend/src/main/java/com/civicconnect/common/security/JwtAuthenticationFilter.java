package com.civicconnect.common.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * Intercepts every request, extracts the Bearer token, validates it,
 * checks it against the blacklist, and sets the Spring Security context.
 *
 * <p>Phase 12 changes:
 * <ul>
 *   <li>Checks token JTI against the Redis blacklist before accepting it</li>
 *   <li>Propagates JTI as a request attribute for use in logout</li>
 *   <li>Structured error logging with distinct warn messages per failure type</li>
 * </ul>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private static final String BEARER_PREFIX  = "Bearer ";
    private static final String AUTH_HEADER    = "Authorization";

    private final JwtTokenProvider       tokenProvider;
    private final UserDetailsServiceImpl userDetailsService;
    private final TokenBlacklistService  blacklistService;

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest  request,
                                    @NonNull HttpServletResponse response,
                                    @NonNull FilterChain         filterChain)
            throws ServletException, IOException {

        String token = extractToken(request);

        if (StringUtils.hasText(token) && tokenProvider.validateToken(token)) {
            try {
                // ── Blacklist check ──────────────────────────────────
                String jti = tokenProvider.extractJti(token);
                if (blacklistService.isBlacklisted(jti)) {
                    log.warn("Rejected blacklisted token jti={}", jti);
                    filterChain.doFilter(request, response);
                    return;
                }

                // ── Load user and set context ────────────────────────
                String userId = tokenProvider.extractUserId(token).toString();
                UserDetails userDetails = userDetailsService.loadUserByUsername(userId);

                UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(
                        userDetails, null, userDetails.getAuthorities());
                authentication.setDetails(
                    new WebAuthenticationDetailsSource().buildDetails(request));

                SecurityContextHolder.getContext().setAuthentication(authentication);

                // Propagate claims for downstream use
                request.setAttribute("jwtUserId",         userId);
                request.setAttribute("jwtJti",            jti);
                request.setAttribute("jwtRole",           tokenProvider.extractRole(token));
                request.setAttribute("jwtMunicipalityId", tokenProvider.extractMunicipalityId(token));
                request.setAttribute("jwtDepartmentId",   tokenProvider.extractDepartmentId(token));
                request.setAttribute("jwtExpiry",         tokenProvider.extractExpiration(token));

            } catch (Exception ex) {
                log.warn("Could not set user authentication from JWT: {}", ex.getMessage());
                SecurityContextHolder.clearContext();
            }
        }

        filterChain.doFilter(request, response);
    }

    private String extractToken(HttpServletRequest request) {
        String header = request.getHeader(AUTH_HEADER);
        if (StringUtils.hasText(header) && header.startsWith(BEARER_PREFIX)) {
            return header.substring(BEARER_PREFIX.length());
        }
        return null;
    }
}
