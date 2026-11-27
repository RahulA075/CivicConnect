package com.civicconnect.common.exception;

import com.civicconnect.common.response.ApiResponse;
import com.civicconnect.common.response.ErrorDetail;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.NoHandlerFoundException;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Centralised exception → HTTP response mapping.
 *
 * <p>All responses follow the {@link ApiResponse} envelope:
 * <pre>
 * {
 *   "success": false,
 *   "errorCode": "VALIDATION_ERROR",
 *   "message": "...",
 *   "errors": [...],   // only for validation failures
 *   "path": "/api/v1/...",
 *   "timestamp": "..."
 * }
 * </pre>
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    // ── Application-layer exceptions ─────────────────────────────────

    @ExceptionHandler(ApiException.class)
    public ResponseEntity<ApiResponse<Void>> handleApiException(
            ApiException ex, HttpServletRequest request) {

        log.warn("API exception [{}] on {}: {}",
            ex.getErrorCode(), request.getRequestURI(), ex.getMessage());

        return ResponseEntity.status(ex.getStatus())
            .body(ApiResponse.error(ex.getErrorCode(), ex.getMessage(),
                request.getRequestURI()));
    }

    // ── Validation exceptions ────────────────────────────────────────

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Void>> handleValidationException(
            MethodArgumentNotValidException ex, HttpServletRequest request) {

        List<ErrorDetail> errors = ex.getBindingResult().getAllErrors().stream()
            .map(error -> {
                if (error instanceof FieldError fe) {
                    return new ErrorDetail(fe.getField(), fe.getDefaultMessage());
                }
                return new ErrorDetail(error.getObjectName(), error.getDefaultMessage());
            })
            .collect(Collectors.toList());

        log.warn("Validation failed on {}: {} errors", request.getRequestURI(), errors.size());

        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
            .body(ApiResponse.validationError(errors, request.getRequestURI()));
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ApiResponse<Void>> handleMalformedJson(
            HttpMessageNotReadableException ex, HttpServletRequest request) {

        log.warn("Malformed JSON on {}: {}", request.getRequestURI(), ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
            .body(ApiResponse.error("MALFORMED_REQUEST",
                "Request body is malformed or missing.", request.getRequestURI()));
    }

    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<ApiResponse<Void>> handleMissingParam(
            MissingServletRequestParameterException ex, HttpServletRequest request) {

        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
            .body(ApiResponse.error("MISSING_PARAMETER",
                "Required parameter '" + ex.getParameterName() + "' is missing.",
                request.getRequestURI()));
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ApiResponse<Void>> handleTypeMismatch(
            MethodArgumentTypeMismatchException ex, HttpServletRequest request) {

        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
            .body(ApiResponse.error("TYPE_MISMATCH",
                "Parameter '" + ex.getName() + "' has an invalid value.",
                request.getRequestURI()));
    }

    // ── Security exceptions ──────────────────────────────────────────

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiResponse<Void>> handleSpringAccessDenied(
            AccessDeniedException ex, HttpServletRequest request) {

        log.warn("Access denied on {}", request.getRequestURI());
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
            .body(ApiResponse.error("ACCESS_DENIED",
                "You do not have permission to perform this action.",
                request.getRequestURI()));
    }

    @ExceptionHandler({BadCredentialsException.class, DisabledException.class})
    public ResponseEntity<ApiResponse<Void>> handleAuthErrors(
            Exception ex, HttpServletRequest request) {

        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
            .body(ApiResponse.error("AUTHENTICATION_FAILED",
                "Authentication failed. Check your credentials.",
                request.getRequestURI()));
    }

    // ── 404 ──────────────────────────────────────────────────────────

    @ExceptionHandler(NoHandlerFoundException.class)
    public ResponseEntity<ApiResponse<Void>> handleNotFound(
            NoHandlerFoundException ex, HttpServletRequest request) {

        return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(ApiResponse.error("ENDPOINT_NOT_FOUND",
                "Endpoint not found: " + ex.getRequestURL(),
                request.getRequestURI()));
    }

    // ── Fallback ─────────────────────────────────────────────────────

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleUnexpected(
            Exception ex, HttpServletRequest request) {

        log.error("Unexpected error on {}: {}", request.getRequestURI(), ex.getMessage(), ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(ApiResponse.error("INTERNAL_ERROR",
                "An unexpected error occurred. Please try again.",
                request.getRequestURI()));
    }
}
