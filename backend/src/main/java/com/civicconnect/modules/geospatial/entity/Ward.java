package com.civicconnect.modules.geospatial.entity;

import com.civicconnect.common.audit.AuditableEntity;
import com.civicconnect.modules.admin.entity.Municipality;
import jakarta.persistence.*;
import lombok.*;
import org.locationtech.jts.geom.Polygon;

import java.util.UUID;

/** Administrative ward / sub-division of a municipality. Issues are geo-tagged to a ward. */
@Entity
@Table(name = "wards")
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Ward extends AuditableEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "municipality_id", nullable = false)
    private Municipality municipality;

    @Column(nullable = false, length = 200)
    private String name;

    @Column(nullable = false, length = 20)
    private String code;

    @Column(columnDefinition = "TEXT")
    private String description;

    /** PostGIS POLYGON boundary — used for point-in-polygon ward detection. */
    @Column(columnDefinition = "geometry(Polygon, 4326)")
    private Polygon boundary;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
        private boolean active = true;
}
