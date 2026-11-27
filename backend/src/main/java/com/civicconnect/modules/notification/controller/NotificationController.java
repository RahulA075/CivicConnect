package com.civicconnect.modules.notification.controller;

import com.civicconnect.common.response.ApiResponse;
import com.civicconnect.common.response.PagedResponse;
import com.civicconnect.common.security.CurrentUser;
import com.civicconnect.modules.notification.dto.*;
import com.civicconnect.modules.notification.service.NotificationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

/**
 * Notification inbox + device token + preference endpoints.
 * Base path: /api/v1/notifications
 */
@RestController
@RequestMapping("/api/v1/notifications")
@RequiredArgsConstructor
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Notifications", description = "Notification inbox, FCM tokens and preferences")
public class NotificationController {

    private final NotificationService notificationService;

    // ── Inbox ──────────────────────────────────────────────────────────────────

    @Operation(summary = "Get notification inbox (paginated)")
    @GetMapping
    public ResponseEntity<ApiResponse<PagedResponse<NotificationResponse>>> getInbox(
            @CurrentUser UserDetails principal,
            @RequestParam(defaultValue = "0")  int page,
            @RequestParam(defaultValue = "20") int size) {
        UUID userId = UUID.fromString(principal.getUsername());
        return ResponseEntity.ok(
            PagedResponse.toApiResponse(
                notificationService.getInbox(userId,
                    PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt")))));
    }

    @Operation(summary = "Get unread notification count")
    @GetMapping("/unread-count")
    public ResponseEntity<ApiResponse<Map<String, Long>>> getUnreadCount(
            @CurrentUser UserDetails principal) {
        UUID userId = UUID.fromString(principal.getUsername());
        return ResponseEntity.ok(ApiResponse.success(
            Map.of("unreadCount", notificationService.getUnreadCount(userId))));
    }

    @Operation(summary = "Mark a single notification as read")
    @PatchMapping("/{id}/read")
    public ResponseEntity<ApiResponse<Void>> markRead(
            @PathVariable UUID id,
            @CurrentUser UserDetails principal) {
        notificationService.markRead(id, UUID.fromString(principal.getUsername()));
        return ResponseEntity.ok(ApiResponse.ok("Notification marked as read"));
    }

    @Operation(summary = "Mark all notifications as read")
    @PostMapping("/read-all")
    public ResponseEntity<ApiResponse<Void>> markAllRead(
            @CurrentUser UserDetails principal) {
        notificationService.markAllRead(UUID.fromString(principal.getUsername()));
        return ResponseEntity.ok(ApiResponse.ok("All notifications marked as read"));
    }

    // ── Device Tokens ──────────────────────────────────────────────────────────

    @Operation(summary = "Register an FCM device token")
    @PostMapping("/device-token")
    public ResponseEntity<ApiResponse<Void>> registerToken(
            @Valid @RequestBody RegisterTokenRequest request,
            @CurrentUser UserDetails principal) {
        UUID userId = UUID.fromString(principal.getUsername());
        notificationService.registerToken(userId, request.getToken(), request.getPlatform());
        return ResponseEntity.ok(ApiResponse.ok("Device token registered"));
    }

    @Operation(summary = "Remove an FCM device token (logout / uninstall)")
    @DeleteMapping("/device-token")
    public ResponseEntity<ApiResponse<Void>> removeToken(
            @Valid @RequestBody RegisterTokenRequest request,
            @CurrentUser UserDetails principal) {
        UUID userId = UUID.fromString(principal.getUsername());
        notificationService.removeToken(userId, request.getToken());
        return ResponseEntity.ok(ApiResponse.ok("Device token removed"));
    }

    // ── Preferences ────────────────────────────────────────────────────────────

    @Operation(summary = "Get notification preferences")
    @GetMapping("/preferences")
    public ResponseEntity<ApiResponse<NotificationPreferenceResponse>> getPreferences(
            @CurrentUser UserDetails principal) {
        UUID userId = UUID.fromString(principal.getUsername());
        return ResponseEntity.ok(ApiResponse.success(
                notificationService.getPreferences(userId)));
    }

    @Operation(summary = "Update notification preferences")
    @PutMapping("/preferences")
    public ResponseEntity<ApiResponse<NotificationPreferenceResponse>> updatePreferences(
            @RequestBody NotificationPreferenceRequest request,
            @CurrentUser UserDetails principal) {
        UUID userId = UUID.fromString(principal.getUsername());
        return ResponseEntity.ok(ApiResponse.success(
                notificationService.updatePreferences(userId, request)));
    }
}
