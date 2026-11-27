package com.civicconnect.modules.issue.entity;

import com.civicconnect.common.audit.AuditableEntity;
import com.civicconnect.modules.admin.entity.Department;
import com.civicconnect.modules.admin.entity.Municipality;
import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

/** Issue category (and subcategory via self-referencing parent). */
@Entity
@Table(name = "issue_categories")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class IssueCategory extends AuditableEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "municipality_id", nullable = false)
    private Municipality municipality;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "department_id", nullable = false)
    private Department department;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_id")
    private IssueCategory parent;

    @Column(nullable = false, length = 200)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "icon_name", nullable = false, length = 100)
    private String iconName;

    @Column(name = "color_hex", nullable = false, length = 7)
    @Builder.Default
    private String colorHex = "#1565C0";

    @Column(name = "sort_order", nullable = false)
    @Builder.Default
    private int sortOrder = 0;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private boolean active = true;

    @Column(name = "created_by")
    private UUID createdBy;
}
