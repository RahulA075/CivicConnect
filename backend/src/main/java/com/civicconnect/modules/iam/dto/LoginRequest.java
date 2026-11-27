package com.civicconnect.modules.iam.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/** Request body for POST /api/v1/auth/login */
@Data
public class LoginRequest {

    @NotBlank(message = "Identifier (email or phone) is required")
    private String identifier;   // email or phone

    @NotBlank(message = "Password is required")
    private String password;
}
