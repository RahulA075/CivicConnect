package com.civicconnect.modules.iam.dto;

import lombok.Builder;
import lombok.Data;

import java.time.Instant;
import java.util.UUID;

@Data
@Builder
public class UserResponse {
    private UUID    id;
    private String  fullName;
    private String  email;
    private String  phone;
    private String  role;
    private String  avatarUrl;
    private String  city;
    private boolean emailVerified;
    private boolean active;
    private UUID    municipalityId;
    private UUID    departmentId;
    private Instant createdAt;
}
