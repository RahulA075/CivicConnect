package com.civicconnect.common.security;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link SecurityHeadersFilter}.
 */
@DisplayName("SecurityHeadersFilter")
class SecurityHeadersFilterTest {

    private SecurityHeadersFilter filter;

    @BeforeEach
    void setUp() {
        filter = new SecurityHeadersFilter();
    }

    @Test
    @DisplayName("sets Content-Security-Policy header")
    void setsCSP() throws Exception {
        MockHttpServletResponse resp = invoke();
        assertThat(resp.getHeader("Content-Security-Policy")).isNotBlank();
        assertThat(resp.getHeader("Content-Security-Policy")).contains("default-src 'self'");
        assertThat(resp.getHeader("Content-Security-Policy")).contains("frame-ancestors 'none'");
    }

    @Test
    @DisplayName("sets X-Content-Type-Options: nosniff")
    void setsNoSniff() throws Exception {
        assertThat(invoke().getHeader("X-Content-Type-Options")).isEqualTo("nosniff");
    }

    @Test
    @DisplayName("sets X-Frame-Options: DENY")
    void setsFrameOptionsDeny() throws Exception {
        assertThat(invoke().getHeader("X-Frame-Options")).isEqualTo("DENY");
    }

    @Test
    @DisplayName("sets Strict-Transport-Security with max-age")
    void setsHSTS() throws Exception {
        String hsts = invoke().getHeader("Strict-Transport-Security");
        assertThat(hsts).isNotBlank();
        assertThat(hsts).contains("max-age=31536000");
        assertThat(hsts).contains("includeSubDomains");
    }

    @Test
    @DisplayName("sets Referrer-Policy header")
    void setsReferrerPolicy() throws Exception {
        assertThat(invoke().getHeader("Referrer-Policy"))
                .isEqualTo("strict-origin-when-cross-origin");
    }

    @Test
    @DisplayName("sets Permissions-Policy header")
    void setsPermissionsPolicy() throws Exception {
        assertThat(invoke().getHeader("Permissions-Policy")).isNotBlank();
    }

    @Test
    @DisplayName("blanks the Server header")
    void blanksServerHeader() throws Exception {
        assertThat(invoke().getHeader("Server")).isEqualTo("");
    }

    @Test
    @DisplayName("X-XSS-Protection is set to 0 (CSP replaces it)")
    void setsXxssProtectionToZero() throws Exception {
        assertThat(invoke().getHeader("X-XSS-Protection")).isEqualTo("0");
    }

    @Test
    @DisplayName("filter chain continues after headers are set")
    void filterChainContinues() throws Exception {
        MockFilterChain chain = new MockFilterChain();
        filter.doFilter(new MockHttpServletRequest(), new MockHttpServletResponse(), chain);
        assertThat(chain.getRequest()).isNotNull();
    }

    // ── Helper ─────────────────────────────────────────────────────────────

    private MockHttpServletResponse invoke() throws Exception {
        MockHttpServletResponse resp = new MockHttpServletResponse();
        filter.doFilter(new MockHttpServletRequest(), resp, new MockFilterChain());
        return resp;
    }
}
