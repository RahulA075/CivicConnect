package com.civicconnect.modules.media.service;

import com.civicconnect.common.exception.BusinessRuleException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.util.Arrays;
import java.util.Set;

/**
 * Validates uploaded files for MIME type (via magic bytes), size, and filename safety.
 *
 * <p><strong>Defence layers:</strong>
 * <ol>
 *   <li>Extension whitelist — reject disallowed extensions</li>
 *   <li>Magic-byte check — read first 12 bytes and compare to known signatures;
 *       prevents Content-Type spoofing</li>
 *   <li>File-size limit — enforced before any storage write</li>
 *   <li>Filename sanitization — strip path traversal characters</li>
 * </ol>
 */
@Slf4j
@Service
public class FileValidationService {

    // Max 10 MB per file — matches DB CHECK constraint
    public static final long MAX_FILE_BYTES = 10 * 1024 * 1024L;

    private static final Set<String> ALLOWED_EXTENSIONS =
        Set.of("jpg", "jpeg", "png", "webp", "heic", "heif");

    /**
     * Validates a multipart file upload.
     * Throws {@link BusinessRuleException} if any check fails.
     *
     * @param file the uploaded file
     * @return the sanitized original filename (safe for storage)
     */
    public String validate(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new BusinessRuleException("EMPTY_FILE", "File is empty or missing");
        }

        // 1. Size check
        if (file.getSize() > MAX_FILE_BYTES) {
            throw new BusinessRuleException("FILE_TOO_LARGE",
                "File exceeds the maximum allowed size of 10 MB");
        }

        // 2. Original filename sanitization
        String originalName = sanitizeFilename(file.getOriginalFilename());

        // 3. Extension whitelist
        String ext = extractExtension(originalName).toLowerCase();
        if (!ALLOWED_EXTENSIONS.contains(ext)) {
            throw new BusinessRuleException("UNSUPPORTED_FILE_TYPE",
                "Unsupported file type '" + ext + "'. Allowed: " +
                String.join(", ", ALLOWED_EXTENSIONS));
        }

        // 4. Magic-byte (file signature) validation
        validateMagicBytes(file, ext);

        log.debug("File validation passed: name={} size={} ext={}",
            originalName, file.getSize(), ext);

        return originalName;
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private void validateMagicBytes(MultipartFile file, String ext) {
        try (InputStream is = file.getInputStream()) {
            byte[] header = is.readNBytes(12);
            if (!isAllowedImageSignature(header, ext)) {
                throw new BusinessRuleException("INVALID_FILE_CONTENT",
                    "File content does not match the declared file type. " +
                    "Only JPEG, PNG, WebP and HEIC images are accepted.");
            }
        } catch (BusinessRuleException e) {
            throw e;
        } catch (IOException e) {
            throw new BusinessRuleException("FILE_READ_ERROR",
                "Could not read uploaded file: " + e.getMessage());
        }
    }

    private boolean isAllowedImageSignature(byte[] header, String ext) {
        if (header == null || header.length < 4) return false;

        // JPEG: FF D8 FF
        if (header[0] == (byte)0xFF && header[1] == (byte)0xD8 && header[2] == (byte)0xFF) {
            return true;
        }
        // PNG: 89 50 4E 47 0D 0A 1A 0A
        if (header[0] == (byte)0x89 && header[1] == (byte)0x50 &&
            header[2] == (byte)0x4E && header[3] == (byte)0x47) {
            return true;
        }
        // WebP: 52 49 46 46 xx xx xx xx 57 45 42 50
        if (header.length >= 12 &&
            header[0] == (byte)0x52 && header[1] == (byte)0x49 &&
            header[2] == (byte)0x46 && header[3] == (byte)0x46 &&
            header[8] == (byte)0x57 && header[9] == (byte)0x45 &&
            header[10] == (byte)0x42 && header[11] == (byte)0x50) {
            return true;
        }
        // HEIC/HEIF: ftyp box — bytes 4–7 = "ftyp"
        if (header.length >= 8 &&
            header[4] == (byte)0x66 && header[5] == (byte)0x74 &&
            header[6] == (byte)0x79 && header[7] == (byte)0x70) {
            return true;
        }
        return false;
    }

    private String sanitizeFilename(String filename) {
        if (filename == null || filename.isBlank()) return "upload";
        // Strip directory traversal, null bytes, and shell metacharacters
        return filename
            .replaceAll("[\\x00/\\\\:*?\"<>|]", "_")
            .replaceAll("\\.{2,}", ".")
            .trim();
    }

    private String extractExtension(String filename) {
        int dot = filename.lastIndexOf('.');
        if (dot < 0 || dot == filename.length() - 1) {
            throw new BusinessRuleException("MISSING_EXTENSION",
                "File has no extension. Please upload a JPEG, PNG, WebP or HEIC image.");
        }
        return filename.substring(dot + 1);
    }
}
