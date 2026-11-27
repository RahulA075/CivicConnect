package com.civicconnect.modules.notification.entity;

import com.civicconnect.modules.iam.entity.User;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/** Per-user notification channel preferences. */
@Entity
@Table(name = "notification_preferences")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class NotificationPreference {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(name = "push_enabled", nullable = false)
    @Builder.Default
    private boolean pushEnabled = true;

    @Column(name = "email_enabled", nullable = false)
    @Builder.Default
    private boolean emailEnabled = true;

    @Column(name = "sms_enabled", nullable = false)
    @Builder.Default
    private boolean smsEnabled = false;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "event_overrides", columnDefinition = "jsonb")
    @Builder.Default
    private Map<String, Object> eventOverrides = new java.util.HashMap<>();

    @Column(name = "updated_at", nullable = false)
    @Builder.Default
        private Instant updatedAt = Instant.now();
}
