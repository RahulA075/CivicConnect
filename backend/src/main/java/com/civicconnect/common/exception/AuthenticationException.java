package com.civicconnect.common.exception;

import org.springframework.http.HttpStatus;

/** Thrown for authentication failures: bad credentials, expired OTP, revoked token. */
public class AuthenticationException extends ApiException {

    public AuthenticationException(String errorCode, String message) {
        super(HttpStatus.UNAUTHORIZED, errorCode, message);
    }
}
