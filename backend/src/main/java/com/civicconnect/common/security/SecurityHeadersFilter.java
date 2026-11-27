package com.civicconnect.common.security;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.io.IOException;

/**
 * Adds security response headers to every HTTP response.
 *
 * <ul>
 *   <li><b>Content-Security-Policy</b> — restricts resource loading to same origin;
 *       restricts inline scripts/styles; blocks framing</li>
 *   <li><b>X-Content-Type-Options: nosniff</b> — prevents MIME-type sniffing</li>
 *   <li><b>X-Frame-Options: DENY</b> — blocks clickjacking</li>
 *   <li><b>X-XSS-Protection: 0</b> — disables the broken browser XSS auditor
 *       (modern browsers should use CSP instead)</li>
 *   <li><b>Referrer-Policy: strict-origin-when-cross-origin</b></li>
 *   <li><b>Permissions-Policy</b> — restricts browser feature access</li>
 *   <li><b>Strict-Transport-Security</b> — enforces HTTPS for 1 year</li>
 * </ul>
 *
 * <p>Runs at {@code Order(3)} — after request logging (1) and rate limiting (2).
 */
@Component
@Order(3)
public class SecurityHeadersFilter implements Filter {

    private static final String CSP =
        "default-src 'self'; " +
        "script-src 'self'; " +
        "style-src 'self' 'unsafe-inline'; " +
        "img-src 'self' data: https:; " +
        "font-src 'self'; " +
        "connect-src 'self'; " +
        "frame-ancestors 'none'; " +
        "base-uri 'self'; " +
        "form-action 'self'";

    @Override
    public void doFilter(ServletRequest request,
                         ServletResponse response,
                         FilterChain chain) throws IOException, ServletException {

        HttpServletResponse httpRes = (HttpServletResponse) response;

        httpRes.setHeader("Content-Security-Policy",            CSP);
        httpRes.setHeader("X-Content-Type-Options",             "nosniff");
        httpRes.setHeader("X-Frame-Options",                    "DENY");
        httpRes.setHeader("X-XSS-Protection",                   "0");
        httpRes.setHeader("Referrer-Policy",                    "strict-origin-when-cross-origin");
        httpRes.setHeader("Permissions-Policy",
                          "geolocation=(), camera=(), microphone=()");
        httpRes.setHeader("Strict-Transport-Security",
                          "max-age=31536000; includeSubDomains; preload");
        // Remove server identification header
        httpRes.setHeader("Server", "");

        chain.doFilter(request, response);
    }
}
