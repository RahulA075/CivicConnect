package com.civicconnect.modules.notification.entity;

import com.civicconnect.modules.iam.entity.User;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.Instant;
import java.util.UUID;

/** FCM device registration token per user/device combination. */
@Entity
@Table(name = "device_tokens", indexes = {
    @Index(name = "idx_device_token_user", columnList = "user_id"),
    @Index(name = "idx_device_token_token", columnList = "token", unique = true)
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class DeviceToken {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    /** FCM registration token — refreshed by the mobile client. */
    @Column(nullable = false, length = 500)
    private String token;

    /** android | ios | web */
    @Column(nullable = false, length = 20)
    @Builder.Default
    private String platform = "android";

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private boolean active = true;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "last_used_at")
    private Instant lastUsedAt;
}
