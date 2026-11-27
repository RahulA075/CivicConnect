package com.civicconnect.modules.admin.dto;

import com.civicconnect.common.enums.UserRole;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.util.UUID;

/** Request body for POST /admin/municipalities/{id}/users/invite */
@Data
public class InviteUserRequest {
    @NotBlank  private String   fullName;
    @NotBlank @Email private String email;
    private String   phone;
    @NotNull   private UserRole role;
    private UUID     departmentId;
}
