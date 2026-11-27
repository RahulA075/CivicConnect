package com.civicconnect.modules.iam.dto;

import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

/** Request body for PATCH /api/v1/users/me. Null fields are left unchanged. */
@Data
public class UpdateProfileRequest {

    @Size(max = 200, message = "Full name must be 2–200 characters")
    @Pattern(regexp = "^\\s*\\S.*\\S\\s*$", message = "Full name must be 2–200 characters")
    private String fullName;

    @Pattern(regexp = "^\\+?[1-9]\\d{6,14}$", message = "Must be a valid phone number")
    private String phone;

    @Size(max = 100, message = "City must be ≤ 100 characters")
    private String city;
}
