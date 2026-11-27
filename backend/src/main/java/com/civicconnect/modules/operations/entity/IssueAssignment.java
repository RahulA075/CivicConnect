package com.civicconnect.modules.operations.entity;

import com.civicconnect.modules.iam.entity.User;
import com.civicconnect.modules.issue.entity.Issue;
import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

/** Full assignment history per issue. Only one row per issue has is_active=true. */
@Entity
@Table(name = "issue_assignments")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class IssueAssignment {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "issue_id", nullable = false)
    private Issue issue;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "assigned_by", nullable = false)
    private User assignedBy;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "assigned_to", nullable = false)
    private User assignedTo;

    @Column(name = "assignment_note", columnDefinition = "TEXT")
    private String assignmentNote;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private boolean active = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
        private Instant createdAt = Instant.now();

    @Column(name = "revoked_at")
    private Instant revokedAt;
}
