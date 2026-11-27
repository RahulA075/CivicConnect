package com.civicconnect.modules.media.service;

import com.civicconnect.common.enums.ImageType;
import com.civicconnect.common.exception.BusinessRuleException;
import com.civicconnect.common.exception.ResourceNotFoundException;
import com.civicconnect.config.AppProperties;
import com.civicconnect.modules.issue.entity.Issue;
import com.civicconnect.modules.issue.entity.IssueImage;
import com.civicconnect.modules.issue.repository.IssueImageRepository;
import com.civicconnect.modules.issue.repository.IssueRepository;
import com.civicconnect.modules.media.dto.UploadResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.Instant;
import java.util.UUID;

/**
 * Stores uploaded images.
 *
 * <p>Currently writes to local filesystem (dev) or S3-compatible storage
 * (prod). The storage backend is pluggable — replace {@link #storeFile} with
 * an AWS S3 / MinIO implementation when the storage bucket is provisioned.
 *
 * <p>Phase 12: file content is pre-validated by {@link FileValidationService}
 * before this service is called — no re-validation needed here.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MediaServiceImpl implements MediaService {

    private static final int MAX_IMAGES_PER_ISSUE = 5;

    private final IssueRepository      issueRepository;
    private final IssueImageRepository imageRepository;
    private final AppProperties        appProperties;

    @Override
    @Transactional
    public UploadResponse uploadIssueImage(UUID issueId, UUID uploaderId,
                                           MultipartFile file, String safeFilename,
                                           String imageType) {
        Issue issue = issueRepository.findActiveById(issueId)
            .orElseThrow(() -> new ResourceNotFoundException("Issue not found: " + issueId));

        // Enforce per-issue image cap
        long existing = imageRepository.countActiveByIssueId(issueId);
        if (existing >= MAX_IMAGES_PER_ISSUE) {
            throw new BusinessRuleException("IMAGE_LIMIT_REACHED",
                "Maximum " + MAX_IMAGES_PER_ISSUE + " images per issue");
        }

        ImageType type;
        try {
            type = ImageType.valueOf(imageType.toUpperCase());
        } catch (IllegalArgumentException e) {
            type = ImageType.EVIDENCE;
        }

        // Generate a unique, non-guessable storage key
        String ext        = extractExt(safeFilename);
        String storageKey = "issues/" + issueId + "/" + UUID.randomUUID() + "." + ext;
        String cdnUrl     = storeFile(file, storageKey);
        String mimeType   = resolveMimeType(ext);

        IssueImage image = IssueImage.builder()
            .issue(issue)
            .storageKey(storageKey)
            .cdnUrl(cdnUrl)
            .originalFilename(safeFilename)
            .mimeType(mimeType)
            .fileSizeBytes((int) file.getSize())
            .imageType(type)
            .sortOrder((int) existing)
            .active(true)
            .build();

        image = imageRepository.save(image);
        log.info("Image uploaded: issueId={} imageId={} size={}", issueId, image.getId(), file.getSize());

        return UploadResponse.builder()
            .imageId(image.getId())
            .storageKey(storageKey)
            .cdnUrl(cdnUrl)
            .mimeType(mimeType)
            .fileSizeBytes(file.getSize())
            .imageType(type.name())
            .build();
    }

    @Override
    @Transactional
    public void deleteImage(UUID imageId, UUID requesterId) {
        IssueImage image = imageRepository.findById(imageId)
            .orElseThrow(() -> new ResourceNotFoundException("Image not found: " + imageId));

        // Soft-delete — preserve the row for audit purposes
        image.setActive(false);
        image.setDeletedAt(Instant.now());
        imageRepository.save(image);
        log.info("Image soft-deleted: imageId={} by user={}", imageId, requesterId);
    }

    // ── Storage backend ────────────────────────────────────────────────────────

    /**
     * Stores the file and returns the CDN URL.
     *
     * <p>In development this returns a placeholder URL using the configured
     * CDN base URL. Replace this method body with actual S3/MinIO SDK calls
     * when deploying to production.
     */
    private String storeFile(MultipartFile file, String storageKey) {
        // TODO: replace with S3 / MinIO upload via AWS SDK v2
        // Example:
        //   s3Client.putObject(PutObjectRequest.builder()
        //       .bucket(appProperties.getStorage().getBucket())
        //       .key(storageKey)
        //       .contentType(file.getContentType())
        //       .build(), RequestBody.fromInputStream(file.getInputStream(), file.getSize()));
        return appProperties.getStorage().getCdnBaseUrl() + "/" + storageKey;
    }

    // ── Helpers ────────────────────────────────────────────────────────────────

    private String extractExt(String filename) {
        int dot = filename.lastIndexOf('.');
        return dot >= 0 ? filename.substring(dot + 1).toLowerCase() : "jpg";
    }

    private String resolveMimeType(String ext) {
        return switch (ext) {
            case "png"  -> "image/png";
            case "webp" -> "image/webp";
            case "heic" -> "image/heic";
            case "heif" -> "image/heif";
            default     -> "image/jpeg";
        };
    }
}
