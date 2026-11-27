package com.civicconnect.common.logging;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.slf4j.MDC;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.util.UUID;

/**
 * Servlet filter that:
 * <ol>
 *   <li>Assigns a unique {@code X-Request-Id} to every request</li>
 *   <li>Populates MDC with {@code requestId}, {@code method}, {@code uri}</li>
 *   <li>Logs request start and completion with duration</li>
 * </ol>
 *
 * <p>MDC keys are cleared after every request to prevent leakage
 * across thread-pool reuse.
 */
@Slf4j
@Component
@Order(1)
public class RequestLoggingFilter implements Filter {

    private static final String REQUEST_ID_HEADER = "X-Request-Id";
    private static final String MDC_REQUEST_ID    = "requestId";
    private static final String MDC_METHOD        = "method";
    private static final String MDC_URI           = "uri";

    @Override
    public void doFilter(ServletRequest request,
                         ServletResponse response,
                         FilterChain chain) throws IOException, ServletException {

        HttpServletRequest  httpReq = (HttpServletRequest)  request;
        HttpServletResponse httpRes = (HttpServletResponse) response;

        String requestId = httpReq.getHeader(REQUEST_ID_HEADER);
        if (requestId == null || requestId.isBlank()) {
            requestId = UUID.randomUUID().toString();
        }

        MDC.put(MDC_REQUEST_ID, requestId);
        MDC.put(MDC_METHOD,     httpReq.getMethod());
        MDC.put(MDC_URI,        httpReq.getRequestURI());

        httpRes.setHeader(REQUEST_ID_HEADER, requestId);

        long start = System.currentTimeMillis();
        log.info("→ {} {}", httpReq.getMethod(), httpReq.getRequestURI());

        try {
            chain.doFilter(request, response);
        } finally {
            long duration = System.currentTimeMillis() - start;
            log.info("← {} {} | status={} | {}ms",
                httpReq.getMethod(), httpReq.getRequestURI(),
                httpRes.getStatus(), duration);
            MDC.clear();
        }
    }
}
