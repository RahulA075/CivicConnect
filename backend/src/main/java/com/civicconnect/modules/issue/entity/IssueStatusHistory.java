package com.civicconnect.modules.issue.entity;

import com.civicconnect.common.enums.IssuePriority;
import com.civicconnect.common.enums.IssueStatus;
import com.civicconnect.common.enums.UserRole;
import com.civicconnect.modules.iam.entity.User;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.UUID;

/** Immutable append-only log of every status/priority change on an issue. */
@Entity
@Table(name = "issue_status_history")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class IssueStatusHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "issue_id", nullable = false)
    private Issue issue;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "changed_by")
    private User changedBy;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(name = "changed_by_role", columnDefinition = "user_role")
    private UserRole changedByRole;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(name = "old_status", columnDefinition = "issue_status")
    private IssueStatus oldStatus;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(name = "new_status", nullable = false, columnDefinition = "issue_status")
    private IssueStatus newStatus;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(name = "old_priority", columnDefinition = "issue_priority")
    private IssuePriority oldPriority;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(name = "new_priority", columnDefinition = "issue_priority")
    private IssuePriority newPriority;

    @Column(columnDefinition = "TEXT")
    private String note;

    @Column(name = "is_system", nullable = false)
    @Builder.Default
    private boolean system = false;

    @Column(name = "department_id")
    private UUID departmentId;

    @Column(name = "assigned_to")
    private UUID assignedTo;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
        private Instant createdAt = Instant.now();
}
