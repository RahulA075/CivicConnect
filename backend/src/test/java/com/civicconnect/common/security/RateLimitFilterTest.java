package com.civicconnect.common.security;

import com.civicconnect.config.AppProperties;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link RateLimitFilter}.
 * Tests bucket creation, per-IP separation, and 429 response.
 */
@DisplayName("RateLimitFilter")
class RateLimitFilterTest {

    private RateLimitFilter filter;

    @BeforeEach
    void setUp() {
        AppProperties props = new AppProperties();
        props.getRateLimit().setCapacity(5);
        props.getRateLimit().setRefillTokens(5);
        props.getRateLimit().setRefillDurationSeconds(60);
        filter = new RateLimitFilter(props, new ObjectMapper());
    }

    @Test
    @DisplayName("first request passes through normally")
    void firstRequest_passes() throws Exception {
        MockHttpServletRequest req  = new MockHttpServletRequest("GET", "/api/v1/issues");
        req.setRemoteAddr("10.0.0.1");
        MockHttpServletResponse resp = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();

        filter.doFilter(req, resp, chain);

        assertThat(resp.getStatus()).isEqualTo(200);
        assertThat(chain.getRequest()).isNotNull(); // chain was invoked
    }

    @Test
    @DisplayName("sets X-Rate-Limit-Remaining header")
    void setsRateLimitRemainingHeader() throws Exception {
        MockHttpServletRequest req  = new MockHttpServletRequest("GET", "/api/v1/issues");
        req.setRemoteAddr("10.0.0.2");
        MockHttpServletResponse resp = new MockHttpServletResponse();

        filter.doFilter(req, resp, new MockFilterChain());

        assertThat(resp.getHeader("X-Rate-Limit-Remaining")).isNotNull();
    }

    @Test
    @DisplayName("returns 429 after capacity exhausted")
    void returns429AfterCapacityExhausted() throws Exception {
        String ip = "10.0.0.99";
        MockHttpServletResponse lastResp = null;

        // Exhaust the 5-token bucket
        for (int i = 0; i <= 5; i++) {
            MockHttpServletRequest req = new MockHttpServletRequest("GET", "/api/v1/issues");
            req.setRemoteAddr(ip);
            lastResp = new MockHttpServletResponse();
            filter.doFilter(req, lastResp, new MockFilterChain());
        }

        assertThat(lastResp.getStatus()).isEqualTo(429);
        assertThat(lastResp.getHeader("Retry-After")).isNotNull();
    }

    @Test
    @DisplayName("auth tier uses its own separate bucket from standard API")
    void authTier_hasSeparateBucket() throws Exception {
        // Auth capacity is 10, standard is 5 (from props).
        // Exhaust standard bucket for IP
        String ip = "10.0.0.50";
        for (int i = 0; i < 5; i++) {
            MockHttpServletRequest req = new MockHttpServletRequest("POST", "/api/v1/issues");
            req.setRemoteAddr(ip);
            filter.doFilter(req, new MockHttpServletResponse(), new MockFilterChain());
        }

        // The 6th standard request should be throttled
        MockHttpServletRequest stdReq = new MockHttpServletRequest("POST", "/api/v1/issues");
        stdReq.setRemoteAddr(ip);
        MockHttpServletResponse stdResp = new MockHttpServletResponse();
        filter.doFilter(stdReq, stdResp, new MockFilterChain());
        assertThat(stdResp.getStatus()).isEqualTo(429);

        // But auth tier should still have its own bucket
        MockHttpServletRequest authReq = new MockHttpServletRequest("POST", "/api/v1/auth/login");
        authReq.setRemoteAddr(ip);
        MockHttpServletResponse authResp = new MockHttpServletResponse();
        filter.doFilter(authReq, authResp, new MockFilterChain());
        assertThat(authResp.getStatus()).isEqualTo(200);
    }

    @Test
    @DisplayName("extracts IP from X-Forwarded-For header")
    void extractsIpFromXForwardedFor() throws Exception {
        MockHttpServletRequest req = new MockHttpServletRequest("GET", "/api/v1/issues");
        req.addHeader("X-Forwarded-For", "203.0.113.5, 10.0.0.1");
        req.setRemoteAddr("127.0.0.1");
        MockHttpServletResponse resp = new MockHttpServletResponse();

        filter.doFilter(req, resp, new MockFilterChain());
        // Should pass — just verifying it doesn't throw
        assertThat(resp.getStatus()).isEqualTo(200);
    }

    @Test
    @DisplayName("different IPs have independent buckets")
    void differentIps_haveIndependentBuckets() throws Exception {
        // Exhaust bucket for ip1
        for (int i = 0; i < 5; i++) {
            MockHttpServletRequest req = new MockHttpServletRequest("GET", "/api/v1/issues");
            req.setRemoteAddr("192.168.1.1");
            filter.doFilter(req, new MockHttpServletResponse(), new MockFilterChain());
        }

        // ip2 should still be fine
        MockHttpServletRequest req2 = new MockHttpServletRequest("GET", "/api/v1/issues");
        req2.setRemoteAddr("192.168.1.2");
        MockHttpServletResponse resp2 = new MockHttpServletResponse();
        filter.doFilter(req2, resp2, new MockFilterChain());
        assertThat(resp2.getStatus()).isEqualTo(200);
    }
}
