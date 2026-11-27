package com.civicconnect.modules.ai.entity;

import com.civicconnect.common.enums.IssuePriority;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Stores the AI-generated analysis for a single issue.
 * One row per issue — upserted whenever analysis runs or re-runs.
 *
 * <p>JSONB columns use Hypersistence Utils for clean mapping.
 * If that dependency is not present, change {@code @Type(JsonBinaryType.class)}
 * to {@code @Column(columnDefinition = "jsonb")} and use String + manual Jackson.
 */
@Entity
@Table(name = "ai_issue_analysis")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AiIssueAnalysis {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "issue_id", nullable = false, unique = true)
    private UUID issueId;

    // ── Category suggestion ────────────────────────────────────────────────

    @Column(name = "suggested_category_id")
    private UUID suggestedCategoryId;

    @Column(name = "suggested_category_name", length = 200)
    private String suggestedCategoryName;

    @Column(name = "category_confidence", columnDefinition = "numeric(5,4)")
    private Double categoryConfidence;

    // ── Priority / severity ────────────────────────────────────────────────

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(name = "suggested_priority", columnDefinition = "issue_priority")
    private IssuePriority suggestedPriority;

    @Column(name = "severity_confidence", columnDefinition = "numeric(5,4)")
    private Double severityConfidence;

    @Column(name = "severity_reasoning", columnDefinition = "TEXT")
    private String severityReasoning;

    // ── Duplicate detection ────────────────────────────────────────────────

    @Column(name = "is_potential_duplicate", nullable = false)
    @Builder.Default
    private boolean potentialDuplicate = false;

    @Column(name = "duplicate_of_issue_id")
    private UUID duplicateOfIssueId;

    @Column(name = "duplicate_similarity", columnDefinition = "numeric(5,4)")
    private Double duplicateSimilarity;

    // ── Spam detection ────────────────────────────────────────────────────

    @Column(name = "is_spam_flagged", nullable = false)
    @Builder.Default
    private boolean spamFlagged = false;

    @Column(name = "spam_confidence", columnDefinition = "numeric(5,4)")
    private Double spamConfidence;

    @Column(name = "spam_reason", columnDefinition = "TEXT")
    private String spamReason;

    // ── Image classification ──────────────────────────────────────────────

    /**
     * List of image labels with confidence scores.
     * Example: [{"label":"pothole","confidence":0.92},{"label":"road damage","confidence":0.88}]
     */
    @Column(name = "image_labels", columnDefinition = "jsonb")
    @Builder.Default
    private String imageLabelsJson = "[]";

    @Column(name = "image_category_hint", length = 200)
    private String imageCategoryHint;

    // ── Summary & suggestions ─────────────────────────────────────────────

    @Column(name = "complaint_summary", columnDefinition = "TEXT")
    private String complaintSummary;

    /**
     * Smart suggestions for the citizen.
     * Example: ["Add a photo to help officers respond faster","2 similar issues exist nearby"]
     */
    @Column(name = "smart_suggestions", columnDefinition = "jsonb")
    @Builder.Default
    private String smartSuggestionsJson = "[]";

    // ── Auto-apply flags ──────────────────────────────────────────────────

    @Column(name = "category_auto_applied", nullable = false)
    @Builder.Default
    private boolean categoryAutoApplied = false;

    @Column(name = "priority_auto_applied", nullable = false)
    @Builder.Default
    private boolean priorityAutoApplied = false;

    // ── Meta ──────────────────────────────────────────────────────────────

    @Column(name = "model_used", length = 100)
    private String modelUsed;

    @Column(name = "analysis_duration_ms")
    private Integer analysisDurationMs;

    @Column(name = "analyzed_at", nullable = false)
    @Builder.Default
    private Instant analyzedAt = Instant.now();

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    @Builder.Default
    private Instant updatedAt = Instant.now();
}
