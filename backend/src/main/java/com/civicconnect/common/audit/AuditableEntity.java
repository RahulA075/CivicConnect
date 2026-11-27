package com.civicconnect.common.audit;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.Instant;
import java.util.UUID;

/**
 * Base class for all JPA entities.
 * Provides common audit columns: created_at, updated_at, created_by, updated_by.
 *
 * <p>Enable JPA auditing by adding {@code @EnableJpaAuditing} — done in
 * {@link com.civicconnect.config.JpaConfig}.
 */
@Getter
@Setter
@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
public abstract class AuditableEntity {

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    /** Set by application before persist/merge — not auto-populated. */
    @Column(name = "updated_by")
    private UUID updatedBy;
}
