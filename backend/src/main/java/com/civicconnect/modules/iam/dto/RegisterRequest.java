package com.civicconnect.modules.iam.dto;

import jakarta.validation.constraints.*;
import lombok.Data;

import java.util.UUID;

/**
 * Request body for POST /api/v1/auth/register
 *
 * <h2>Password policy (Phase 12)</h2>
 * <ul>
 *   <li>Minimum 10 characters</li>
 *   <li>At least one uppercase letter</li>
 *   <li>At least one lowercase letter</li>
 *   <li>At least one digit</li>
 *   <li>At least one special character: {@code !@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?}</li>
 * </ul>
 */
@Data
public class RegisterRequest {

    @NotBlank(message = "Full name is required")
    @Size(min = 2, max = 200, message = "Full name must be 2–200 characters")
    // Strip leading/trailing whitespace at validation layer to prevent whitespace-only names
    @Pattern(regexp = ".*\\S.*", message = "Full name cannot be blank")
    private String fullName;

    @Email(message = "Must be a valid email address")
    @Size(max = 255, message = "Email must be ≤ 255 characters")
    private String email;

    @Pattern(regexp = "^\\+?[1-9]\\d{6,14}$", message = "Must be a valid phone number")
    private String phone;

    /**
     * Password must be 10–100 characters and contain at least one uppercase letter,
     * one lowercase letter, one digit, and one special character.
     */
    @NotBlank(message = "Password is required")
    @Size(min = 10, max = 100, message = "Password must be 10–100 characters")
    @Pattern(
        regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>\\/?]).{10,}$",
        message = "Password must contain at least one uppercase letter, one lowercase letter, one digit, and one special character"
    )
    private String password;

    @Size(max = 100, message = "City must be ≤ 100 characters")
    private String city;

    /** Municipality the citizen belongs to; optional but required for local issue feeds. */
    private UUID municipalityId;
}
