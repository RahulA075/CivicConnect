package com.civicconnect.common.exception;

import org.springframework.http.HttpStatus;

/** Thrown on duplicate resource creation (e.g. email already registered). */
public class ConflictException extends ApiException {

    public ConflictException(String errorCode, String message) {
        super(HttpStatus.CONFLICT, errorCode, message);
    }
}
