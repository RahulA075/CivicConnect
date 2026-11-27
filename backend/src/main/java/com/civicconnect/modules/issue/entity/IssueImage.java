package com.civicconnect.modules.issue.entity;

import com.civicconnect.common.enums.ImageType;
import com.civicconnect.modules.iam.entity.User;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.UUID;

/** Image metadata attached to an issue (evidence, progress, or resolution proof). */
@Entity
@Table(name = "issue_images")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class IssueImage {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "issue_id", nullable = false)
    private Issue issue;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "uploaded_by")
    private User uploadedBy;

    @Column(name = "storage_key", nullable = false, unique = true, length = 500)
    private String storageKey;

    @Column(name = "cdn_url", nullable = false, length = 500)
    private String cdnUrl;

    @Column(name = "original_filename", length = 255)
    private String originalFilename;

    @Column(name = "mime_type", nullable = false, length = 50)
    @Builder.Default
    private String mimeType = "image/jpeg";

    @Column(name = "file_size_bytes")
    private Integer fileSizeBytes;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(name = "image_type", nullable = false, columnDefinition = "image_type")
    @Builder.Default
    private ImageType imageType = ImageType.EVIDENCE;

    @Column(name = "sort_order", nullable = false)
    @Builder.Default
    private int sortOrder = 0;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private boolean active = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
        private Instant createdAt = Instant.now();

    @Column(name = "deleted_at")
    private Instant deletedAt;
}
