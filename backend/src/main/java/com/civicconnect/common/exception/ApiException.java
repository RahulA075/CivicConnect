package com.civicconnect.common.exception;

import lombok.Getter;
import org.springframework.http.HttpStatus;

/**
 * Base class for all CivicConnect application exceptions.
 * Carries an HTTP status so the global handler can respond correctly.
 */
@Getter
public class ApiException extends RuntimeException {

    private final HttpStatus status;
    private final String     errorCode;

    public ApiException(HttpStatus status, String errorCode, String message) {
        super(message);
        this.status    = status;
        this.errorCode = errorCode;
    }

    public ApiException(HttpStatus status, String errorCode,
                        String message, Throwable cause) {
        super(message, cause);
        this.status    = status;
        this.errorCode = errorCode;
    }
}
