package com.civicconnect.common.exception;

import org.springframework.http.HttpStatus;

/** Thrown when a requested entity does not exist or has been soft-deleted. */
public class ResourceNotFoundException extends ApiException {

    public ResourceNotFoundException(String resourceName, Object id) {
        super(HttpStatus.NOT_FOUND,
              "RESOURCE_NOT_FOUND",
              resourceName + " not found: " + id);
    }

    public ResourceNotFoundException(String message) {
        super(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", message);
    }
}
