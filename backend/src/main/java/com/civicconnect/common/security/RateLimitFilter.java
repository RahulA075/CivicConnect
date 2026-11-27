package com.civicconnect.common.security;

import com.civicconnect.config.AppProperties;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.github.bucket4j.*;
import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.time.Duration;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Servlet filter implementing per-IP rate limiting using Bucket4j with an
 * in-process {@link ConcurrentHashMap} bucket store.
 *
 * <h2>Tier definitions</h2>
 * <ul>
 *   <li><strong>Auth endpoints</strong> ({@code /api/v1/auth/**}):
 *       10 requests / minute — guards against credential stuffing</li>
 *   <li><strong>AI endpoints</strong> ({@code /api/v1/ai/**}):
 *       20 requests / minute — guards against expensive LLM abuse</li>
 *   <li><strong>Standard API</strong> (everything else):
 *       configured via {@code app.rate-limit.*} (default 100 / minute)</li>
 * </ul>
 *
 * <p>The bucket key is {@code <tier>:<clientIp>}. Stale buckets for IPs that
 * have not made a request in over 2× the window are eligible for GC.
 *
 * <p><strong>Cluster note:</strong> This implementation is per-instance.
 * For multi-node deployments replace the ConcurrentHashMap with the
 * {@code bucket4j_jdk17-lettuce} distributed proxy manager.
 */
@Slf4j
@Component
@Order(2) // runs after RequestLoggingFilter (Order=1)
public class RateLimitFilter implements Filter {

    private static final int      AUTH_CAPACITY = 10;
    private static final int      AI_CAPACITY   = 20;
    private static final Duration WINDOW        = Duration.ofMinutes(1);

    private final ConcurrentHashMap<String, Bucket> buckets = new ConcurrentHashMap<>();
    private final AppProperties appProperties;
    private final ObjectMapper  objectMapper;

    public RateLimitFilter(AppProperties appProperties, ObjectMapper objectMapper) {
        this.appProperties = appProperties;
        this.objectMapper  = objectMapper;
    }

    @Override
    public void doFilter(ServletRequest request,
                         ServletResponse response,
                         FilterChain chain) throws IOException, ServletException {

        HttpServletRequest  httpReq = (HttpServletRequest)  request;
        HttpServletResponse httpRes = (HttpServletResponse) response;

        String ip      = resolveClientIp(httpReq);
        String path    = httpReq.getRequestURI();
        String tierKey = resolveTierKey(path, ip);

        Bucket bucket = buckets.computeIfAbsent(tierKey, k -> buildBucket(path));
        ConsumptionProbe probe = bucket.tryConsumeAndReturnRemaining(1);

        httpRes.setHeader("X-Rate-Limit-Remaining",
            String.valueOf(Math.max(0, probe.getRemainingTokens())));

        if (probe.isConsumed()) {
            chain.doFilter(request, response);
        } else {
            long retryAfterSeconds = probe.getNanosToWaitForRefill() / 1_000_000_000L;
            httpRes.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
            httpRes.setContentType(MediaType.APPLICATION_JSON_VALUE);
            httpRes.setHeader("Retry-After", String.valueOf(retryAfterSeconds + 1));

            log.warn("Rate limit exceeded: ip={} path={} retryAfter={}s",
                ip, path, retryAfterSeconds + 1);

            String body = objectMapper.writeValueAsString(Map.of(
                "success",   false,
                "errorCode", "RATE_LIMIT_EXCEEDED",
                "message",   "Too many requests. Please try again in "
                             + (retryAfterSeconds + 1) + " second(s)."
            ));
            httpRes.getWriter().write(body);
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private String resolveTierKey(String path, String ip) {
        if (path.startsWith("/api/v1/auth/")) return "rl:auth:" + ip;
        if (path.startsWith("/api/v1/ai/"))  return "rl:ai:"   + ip;
        return "rl:api:" + ip;
    }

    private Bucket buildBucket(String path) {
        Bandwidth limit;
        if (path.startsWith("/api/v1/auth/")) {
            limit = Bandwidth.builder()
                .capacity(AUTH_CAPACITY)
                .refillGreedy(AUTH_CAPACITY, WINDOW)
                .build();
        } else if (path.startsWith("/api/v1/ai/")) {
            limit = Bandwidth.builder()
                .capacity(AI_CAPACITY)
                .refillGreedy(AI_CAPACITY, WINDOW)
                .build();
        } else {
            AppProperties.RateLimit rl = appProperties.getRateLimit();
            limit = Bandwidth.builder()
                .capacity(rl.getCapacity())
                .refillGreedy(rl.getRefillTokens(),
                    Duration.ofSeconds(rl.getRefillDurationSeconds()))
                .build();
        }
        return Bucket.builder().addLimit(limit).build();
    }

    private String resolveClientIp(HttpServletRequest request) {
        String xff = request.getHeader("X-Forwarded-For");
        if (xff != null && !xff.isBlank()) return xff.split(",")[0].trim();
        String realIp = request.getHeader("X-Real-IP");
        if (realIp != null && !realIp.isBlank()) return realIp.trim();
        return request.getRemoteAddr();
    }
}
