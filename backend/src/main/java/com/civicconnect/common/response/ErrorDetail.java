package com.civicconnect.common.response;

import lombok.AllArgsConstructor;
import lombok.Getter;

/** A single field-level validation error returned inside {@link ApiResponse}. */
@Getter
@AllArgsConstructor
public class ErrorDetail {
    private final String field;
    private final String message;
}
