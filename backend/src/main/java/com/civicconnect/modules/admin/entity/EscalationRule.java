package com.civicconnect.modules.admin.entity;

import com.civicconnect.common.audit.AuditableEntity;
import com.civicconnect.common.enums.UserRole;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.util.UUID;

/** Auto-escalation rule triggered when an issue exceeds SLA by a configured threshold. */
@Entity
@Table(name = "escalation_rules")
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EscalationRule extends AuditableEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "municipality_id", nullable = false)
    private Municipality municipality;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "department_id")
    private Department department;

    @Column(name = "trigger_after_hours", nullable = false)
    private int triggerAfterHours;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(name = "escalate_to_role", nullable = false, columnDefinition = "user_role")
    private UserRole escalateToRole;

    @Column(name = "notification_message", columnDefinition = "TEXT")
    private String notificationMessage;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
        private boolean active = true;

    @Column(name = "created_by")
    private UUID createdBy;
}
