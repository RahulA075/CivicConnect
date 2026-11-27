package com.civicconnect.common.exception;

import org.springframework.http.HttpStatus;

/**
 * Thrown when a business rule is violated.
 * Examples: invalid state transition, duplicate upvote, SLA policy conflict.
 */
public class BusinessRuleException extends ApiException {

    public BusinessRuleException(String errorCode, String message) {
        super(HttpStatus.UNPROCESSABLE_ENTITY, errorCode, message);
    }
}
