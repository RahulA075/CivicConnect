package com.civicconnect.modules.media.service;

import com.civicconnect.common.exception.BusinessRuleException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;

import static org.assertj.core.api.Assertions.*;

/**
 * Unit tests for {@link FileValidationService}.
 * No Spring context — pure POJO tests with MockMultipartFile.
 */
@DisplayName("FileValidationService")
class FileValidationServiceTest {

    // JPEG magic bytes: FF D8 FF E0
    private static final byte[] JPEG_MAGIC = new byte[]{
            (byte)0xFF, (byte)0xD8, (byte)0xFF, (byte)0xE0,
            0, 0, 0, 0, 0, 0, 0, 0};

    // PNG magic bytes: 89 50 4E 47 0D 0A 1A 0A
    private static final byte[] PNG_MAGIC = new byte[]{
            (byte)0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
            0, 0, 0, 0};

    // WebP magic: RIFF....WEBP
    private static final byte[] WEBP_MAGIC = new byte[]{
            0x52, 0x49, 0x46, 0x46,   // RIFF
            0x00, 0x00, 0x00, 0x00,   // size (ignored)
            0x57, 0x45, 0x42, 0x50}; // WEBP

    // HEIC ftyp box at bytes 4-7
    private static final byte[] HEIC_MAGIC = new byte[]{
            0x00, 0x00, 0x00, 0x18,
            0x66, 0x74, 0x79, 0x70,   // ftyp
            0x68, 0x65, 0x69, 0x63}; // heic

    private FileValidationService service;

    @BeforeEach
    void setUp() {
        service = new FileValidationService();
    }

    // ── Valid files ────────────────────────────────────────────────────────

    @Test
    @DisplayName("accepts a valid JPEG file")
    void validate_acceptsJpeg() {
        MockMultipartFile file = new MockMultipartFile(
                "file", "photo.jpg", "image/jpeg", JPEG_MAGIC);
        assertThatCode(() -> service.validate(file)).doesNotThrowAnyException();
    }

    @Test
    @DisplayName("accepts a valid PNG file")
    void validate_acceptsPng() {
        MockMultipartFile file = new MockMultipartFile(
                "file", "image.png", "image/png", PNG_MAGIC);
        assertThatCode(() -> service.validate(file)).doesNotThrowAnyException();
    }

    @Test
    @DisplayName("accepts a valid WebP file")
    void validate_acceptsWebP() {
        MockMultipartFile file = new MockMultipartFile(
                "file", "photo.webp", "image/webp", WEBP_MAGIC);
        assertThatCode(() -> service.validate(file)).doesNotThrowAnyException();
    }

    @Test
    @DisplayName("accepts a valid HEIC file")
    void validate_acceptsHeic() {
        MockMultipartFile file = new MockMultipartFile(
                "file", "photo.heic", "image/heic", HEIC_MAGIC);
        assertThatCode(() -> service.validate(file)).doesNotThrowAnyException();
    }

    @Test
    @DisplayName("returns sanitized filename")
    void validate_returnsSanitizedFilename() {
        MockMultipartFile file = new MockMultipartFile(
                "file", "my photo.jpeg", "image/jpeg", JPEG_MAGIC);
        String name = service.validate(file);
        assertThat(name).isEqualTo("my photo.jpeg");
    }

    // ── Rejections ────────────────────────────────────────────────────────

    @Test
    @DisplayName("rejects empty file")
    void validate_rejectsEmptyFile() {
        MockMultipartFile file = new MockMultipartFile(
                "file", "empty.jpg", "image/jpeg", new byte[0]);
        assertThatThrownBy(() -> service.validate(file))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("empty");
    }

    @Test
    @DisplayName("rejects null file")
    void validate_rejectsNullFile() {
        assertThatThrownBy(() -> service.validate(null))
                .isInstanceOf(BusinessRuleException.class);
    }

    @Test
    @DisplayName("rejects file exceeding 10 MB")
    void validate_rejectsOversizedFile() {
        byte[] bigContent = new byte[(int)(FileValidationService.MAX_FILE_BYTES + 1)];
        System.arraycopy(JPEG_MAGIC, 0, bigContent, 0, JPEG_MAGIC.length);
        MockMultipartFile file = new MockMultipartFile(
                "file", "big.jpg", "image/jpeg", bigContent);
        assertThatThrownBy(() -> service.validate(file))
                .isInstanceOf(BusinessRuleException.class)
                .satisfies(ex -> assertThat(((BusinessRuleException) ex).getErrorCode())
                        .isEqualTo("FILE_TOO_LARGE"));
    }

    @Test
    @DisplayName("rejects disallowed extension (.gif)")
    void validate_rejectsDisallowedExtension() {
        MockMultipartFile file = new MockMultipartFile(
                "file", "anim.gif", "image/gif", JPEG_MAGIC);
        assertThatThrownBy(() -> service.validate(file))
                .isInstanceOf(BusinessRuleException.class)
                .satisfies(ex -> assertThat(((BusinessRuleException) ex).getErrorCode())
                        .isEqualTo("UNSUPPORTED_FILE_TYPE"));
    }

    @Test
    @DisplayName("rejects executable disguised as JPEG")
    void validate_rejectsMagicByteMismatch() {
        byte[] exeContent = new byte[]{0x4D, 0x5A, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}; // MZ (exe)
        MockMultipartFile file = new MockMultipartFile(
                "file", "malware.jpg", "image/jpeg", exeContent);
        assertThatThrownBy(() -> service.validate(file))
                .isInstanceOf(BusinessRuleException.class)
                .satisfies(ex -> assertThat(((BusinessRuleException) ex).getErrorCode())
                        .isEqualTo("INVALID_FILE_CONTENT"));
    }

    @Test
    @DisplayName("strips path traversal from filename")
    void validate_stripsPathTraversalFromFilename() {
        MockMultipartFile file = new MockMultipartFile(
                "file", "../../../etc/passwd.jpg", "image/jpeg", JPEG_MAGIC);
        String name = service.validate(file);
        assertThat(name).doesNotContain("..");
        assertThat(name).doesNotContain("/");
    }

    @Test
    @DisplayName("rejects file without extension")
    void validate_rejectsMissingExtension() {
        MockMultipartFile file = new MockMultipartFile(
                "file", "noextension", "image/jpeg", JPEG_MAGIC);
        assertThatThrownBy(() -> service.validate(file))
                .isInstanceOf(BusinessRuleException.class)
                .satisfies(ex -> assertThat(((BusinessRuleException) ex).getErrorCode())
                        .isEqualTo("MISSING_EXTENSION"));
    }
}
