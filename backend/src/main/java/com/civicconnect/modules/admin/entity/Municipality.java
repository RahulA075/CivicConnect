package com.civicconnect.modules.admin.entity;

import com.civicconnect.common.audit.AuditableEntity;
import jakarta.persistence.*;
import lombok.*;
import org.locationtech.jts.geom.MultiPolygon;

import java.util.UUID;

/**
 * Represents a municipal corporation / city onboarded onto the platform.
 * Top-level tenant — every business entity carries a reference to this.
 */
@Entity
@Table(name = "municipalities")
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Municipality extends AuditableEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, length = 200)
    private String name;

    @Column(nullable = false, length = 20, unique = true)
    private String code;

    @Column(nullable = false, length = 100)
    private String state;

    @Column(nullable = false, length = 100)
    private String country;

    @Column(nullable = false, length = 60)
    private String timezone;

    @Column(name = "contact_email")
    private String contactEmail;

    @Column(name = "contact_phone", length = 20)
    private String contactPhone;

    @Column(name = "website_url", length = 500)
    private String websiteUrl;

    /** PostGIS MULTIPOLYGON — outer boundary of the municipality. */
    @Column(columnDefinition = "geometry(MultiPolygon, 4326)")
    private MultiPolygon boundary;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
        private boolean active = true;

    @Column(name = "logo_url", length = 500)
    private String logoUrl;
}
