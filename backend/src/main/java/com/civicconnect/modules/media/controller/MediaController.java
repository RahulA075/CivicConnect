package com.civicconnect.modules.media.controller;

import com.civicconnect.common.response.ApiResponse;
import com.civicconnect.common.security.CurrentUser;
import com.civicconnect.modules.media.dto.UploadResponse;
import com.civicconnect.modules.media.service.FileValidationService;
import com.civicconnect.modules.media.service.MediaService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.UUID;

/**
 * Secure media upload endpoints.
 *
 * <p>Every upload goes through {@link FileValidationService} which checks:
 * extension whitelist, magic-byte signature, and size limit (10 MB).
 *
 * <p>Base path: /api/v1/media
 */
@RestController
@RequestMapping("/api/v1/media")
@RequiredArgsConstructor
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Media", description = "Secure image upload for issue evidence")
public class MediaController {

    private final MediaService         mediaService;
    private final FileValidationService validationService;

    @Operation(
        summary = "Upload an image for an issue",
        description = "Accepts JPEG, PNG, WebP, HEIC — max 10 MB. " +
                      "Returns a CDN URL and storage key for the uploaded image."
    )
    @PostMapping(value = "/issues/{issueId}/images",
                 consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasAnyRole('CITIZEN','FIELD_WORKER','DEPT_SUPERVISOR','MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<UploadResponse>> uploadIssueImage(
            @PathVariable UUID issueId,
            @RequestParam("file") MultipartFile file,
            @RequestParam(defaultValue = "EVIDENCE") String imageType,
            @CurrentUser UserDetails principal) {

        UUID uploaderId = UUID.fromString(principal.getUsername());

        // Validate before touching storage
        String safeFilename = validationService.validate(file);

        UploadResponse result = mediaService.uploadIssueImage(
            issueId, uploaderId, file, safeFilename, imageType);

        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.success(result, "Image uploaded successfully"));
    }

    @Operation(summary = "Delete an image from an issue")
    @DeleteMapping("/images/{imageId}")
    @PreAuthorize("hasAnyRole('CITIZEN','FIELD_WORKER','DEPT_SUPERVISOR','MUNICIPAL_ADMIN','SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteImage(
            @PathVariable UUID imageId,
            @CurrentUser UserDetails principal) {
        UUID requesterId = UUID.fromString(principal.getUsername());
        mediaService.deleteImage(imageId, requesterId);
        return ResponseEntity.ok(ApiResponse.ok("Image deleted"));
    }
}
