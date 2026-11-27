package com.civicconnect.common.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Getter;

import java.time.Instant;
import java.util.List;

/**
 * Standard API response envelope for all endpoints.
 *
 * <p>Success:
 * <pre>
 * { "success": true, "data": { ... }, "timestamp": "..." }
 * </pre>
 *
 * <p>Error:
 * <pre>
 * { "success": false, "errorCode": "...", "message": "...",
 *   "errors": [...], "path": "...", "timestamp": "..." }
 * </pre>
 *
 * @param <T> type of the {@code data} payload (Void for error responses)
 */
@Getter
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiResponse<T> {

    private final boolean   success;
    private final T         data;
    private final String    errorCode;
    private final String    message;
    private final List<ErrorDetail> errors;
    private final String    path;
    private final Instant   timestamp;

    // ── Private constructor ──────────────────────────────────────────

    private ApiResponse(boolean success, T data, String errorCode,
                        String message, List<ErrorDetail> errors, String path) {
        this.success   = success;
        this.data      = data;
        this.errorCode = errorCode;
        this.message   = message;
        this.errors    = errors;
        this.path      = path;
        this.timestamp = Instant.now();
    }

    // ── Factory methods ──────────────────────────────────────────────

    public static <T> ApiResponse<T> success(T data) {
        return new ApiResponse<>(true, data, null, null, null, null);
    }

    public static <T> ApiResponse<T> success(T data, String message) {
        return new ApiResponse<>(true, data, null, message, null, null);
    }

    public static ApiResponse<Void> ok(String message) {
        return new ApiResponse<>(true, null, null, message, null, null);
    }

    public static ApiResponse<Void> error(String errorCode, String message, String path) {
        return new ApiResponse<>(false, null, errorCode, message, null, path);
    }

    public static ApiResponse<Void> validationError(List<ErrorDetail> errors, String path) {
        return new ApiResponse<>(false, null, "VALIDATION_ERROR",
            "Request validation failed. See 'errors' for details.", errors, path);
    }
}
