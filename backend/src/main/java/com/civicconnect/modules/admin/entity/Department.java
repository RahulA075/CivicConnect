package com.civicconnect.modules.admin.entity;

import com.civicconnect.common.audit.AuditableEntity;
import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

/**
 * Government department within a municipality.
 * Owns a set of issue categories and handles their resolution.
 */
@Entity
@Table(name = "departments")
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Department extends AuditableEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "municipality_id", nullable = false)
    private Municipality municipality;

    @Column(nullable = false, length = 200)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "icon_name", length = 100)
    private String iconName;

    @Column(name = "color_hex", length = 7)
    private String colorHex;

    @Column(name = "contact_email")
    private String contactEmail;

    @Column(name = "contact_phone", length = 20)
    private String contactPhone;

    /** FK to users — resolved lazily to avoid circular dependency at startup. */
    @Column(name = "head_user_id")
    private UUID headUserId;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
        private boolean active = true;

    @Column(name = "created_by")
    private UUID createdBy;
}
