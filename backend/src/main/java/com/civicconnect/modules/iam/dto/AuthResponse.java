package com.civicconnect.modules.iam.dto;

import lombok.Builder;
import lombok.Data;

import java.util.UUID;

/** Response body for login and register endpoints. */
@Data
@Builder
public class AuthResponse {
    private String  accessToken;
    private String  refreshToken;
    private String  tokenType;
    private long    expiresIn;       // seconds
    private UUID    userId;
    private String  role;
    private String  fullName;
    private String  email;
    private UUID    municipalityId;
    private UUID    departmentId;
}
