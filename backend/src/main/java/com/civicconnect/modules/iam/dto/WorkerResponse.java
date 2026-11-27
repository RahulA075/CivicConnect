package com.civicconnect.modules.iam.dto;

import lombok.Builder;
import lombok.Data;

import java.util.UUID;

/** Lightweight worker profile for the officer assignment dropdown. */
@Data
@Builder
public class WorkerResponse {
    private UUID   id;
    private String fullName;
    private String email;
    private String role;
    private String avatarUrl;
}
