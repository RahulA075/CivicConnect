package com.civicconnect.modules.admin.entity;

import com.civicconnect.common.audit.AuditableEntity;
import com.civicconnect.common.enums.IssuePriority;
import com.civicconnect.modules.issue.entity.IssueCategory;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.util.UUID;

/**
 * SLA resolution targets per municipality / category / priority combination.
 * category = NULL means the policy applies to all categories in the municipality.
 */
@Entity
@Table(name = "sla_policies")
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SlaPolicy extends AuditableEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "municipality_id", nullable = false)
    private Municipality municipality;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private IssueCategory category;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(nullable = false, columnDefinition = "issue_priority")
    private IssuePriority priority;

    @Column(name = "resolution_hours", nullable = false)
    private int resolutionHours;

    @Column(name = "warning_hours", nullable = false)
    private int warningHours;

    @Column(name = "escalation_hours", nullable = false)
    private int escalationHours;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
        private boolean active = true;

    @Column(name = "created_by")
    private UUID createdBy;
}
