package com.civicconnect.modules.admin.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.Instant;
import java.util.UUID;

/**
 * Immutable audit trail record.
 * Never updated after insert — use append-only writes.
 */
@Entity
@Table(name = "admin_audit_logs", indexes = {
    @Index(name = "idx_admin_audit_municipality", columnList = "municipality_id"),
    @Index(name = "idx_admin_audit_performed_by", columnList = "performed_by_id"),
    @Index(name = "idx_admin_audit_entity",       columnList = "entity_type, entity_id")
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AuditLog {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "municipality_id")
    private UUID municipalityId;

    @Column(name = "performed_by_id")
    private UUID performedById;

    @Column(name = "performed_by_name", length = 200)
    private String performedByName;

    /** E.g. DEACTIVATE_USER, CREATE_DEPARTMENT, SEND_ALERT */
    @Column(nullable = false, length = 100)
    private String action;

    @Column(name = "entity_type", length = 100)
    private String entityType;

    @Column(name = "entity_id", length = 100)
    private String entityId;

    @Column(columnDefinition = "TEXT")
    private String detail;

    @Column(name = "ip_address", length = 45)
    private String ipAddress;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;
}
