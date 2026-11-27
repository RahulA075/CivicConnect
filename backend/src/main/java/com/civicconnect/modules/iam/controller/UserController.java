package com.civicconnect.modules.iam.controller;

import com.civicconnect.common.response.ApiResponse;
import com.civicconnect.common.security.CurrentUser;
import com.civicconnect.modules.iam.dto.UserResponse;
import com.civicconnect.modules.iam.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

/**
 * User profile endpoints.
 * Base path: /api/v1/users
 */
@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Users", description = "User profile management")
public class UserController {

    private final UserService userService;

    @Operation(summary = "Get current user profile")
    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserResponse>> getMe(
            @CurrentUser UserDetails principal) {
        UUID userId = UUID.fromString(principal.getUsername());
        return ResponseEntity.ok(ApiResponse.success(userService.getMe(userId)));
    }

    @Operation(summary = "Get user by ID (admin/supervisor only)")
    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('DEPT_SUPERVISOR','MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<UserResponse>> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.success(userService.getById(id)));
    }
}
