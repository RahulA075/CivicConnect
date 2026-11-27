package com.civicconnect.common.exception;

import org.springframework.http.HttpStatus;

/** Thrown when a user attempts an action beyond their role's permissions. */
public class AccessDeniedException extends ApiException {

    public AccessDeniedException() {
        super(HttpStatus.FORBIDDEN, "ACCESS_DENIED",
              "You do not have permission to perform this action.");
    }

    public AccessDeniedException(String message) {
        super(HttpStatus.FORBIDDEN, "ACCESS_DENIED", message);
    }
}
