package com.civicconnect.modules.issue.entity;

import com.civicconnect.common.audit.AuditableEntity;
import com.civicconnect.common.enums.IssuePriority;
import com.civicconnect.common.enums.IssueStatus;
import com.civicconnect.modules.admin.entity.Department;
import com.civicconnect.modules.admin.entity.Municipality;
import com.civicconnect.modules.geospatial.entity.Ward;
import com.civicconnect.modules.iam.entity.User;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import org.locationtech.jts.geom.Point;

import java.time.Instant;
import java.util.UUID;

/** Core domain entity — a civic issue report. */
@Entity
@Table(name = "issues")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Issue extends AuditableEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "municipality_id", nullable = false)
    private Municipality municipality;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "category_id", nullable = false)
    private IssueCategory category;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ward_id")
    private Ward ward;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "department_id")
    private Department department;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reported_by")
    private User reportedBy;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assigned_to")
    private User assignedTo;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "merged_into_id")
    private Issue mergedInto;

    @Column(name = "tracking_id", nullable = false, unique = true, length = 20)
    private String trackingId;

    @Column(nullable = false, length = 300)
    private String title;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String description;

    /** PostGIS POINT (longitude, latitude) in WGS-84. */
    @Column(columnDefinition = "geometry(Point,4326)", nullable = false)
    private Point location;

    @Column(name = "address_text", length = 500)
    private String addressText;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(nullable = false, columnDefinition = "issue_status")
    @Builder.Default
    private IssueStatus status = IssueStatus.SUBMITTED;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(nullable = false, columnDefinition = "issue_priority")
    @Builder.Default
    private IssuePriority priority = IssuePriority.MEDIUM;

    @Column(name = "sla_deadline")
    private Instant slaDeadline;

    @Column(name = "is_overdue", nullable = false)
    @Builder.Default
    private boolean overdue = false;

    @Column(name = "upvote_count", nullable = false)
    @Builder.Default
    private int upvoteCount = 0;

    @Column(name = "comment_count", nullable = false)
    @Builder.Default
    private int commentCount = 0;

    @Column(name = "is_anonymous", nullable = false)
    @Builder.Default
    private boolean anonymous = false;

    @Column(name = "resolved_at")
    private Instant resolvedAt;

    @Column(name = "resolution_note", columnDefinition = "TEXT")
    private String resolutionNote;

    @Column(name = "verified_at")
    private Instant verifiedAt;

    @Column(name = "rejection_reason", columnDefinition = "TEXT")
    private String rejectionReason;

    @Column(name = "citizen_rating")
    private Integer citizenRating;

    @Column(name = "citizen_comment", columnDefinition = "TEXT")
    private String citizenComment;

    @Column(name = "closed_at")
    private Instant closedAt;

    @Column(name = "is_merged", nullable = false)
    @Builder.Default
    private boolean merged = false;

    @Column(name = "sla_policy_id")
    private UUID slaPolicyId;

    @Column(name = "deleted_at")
    private Instant deletedAt;
}
