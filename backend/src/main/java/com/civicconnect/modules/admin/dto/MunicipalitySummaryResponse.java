package com.civicconnect.modules.admin.dto;

import lombok.Builder;
import lombok.Data;
import java.util.UUID;

/** Minimal municipality info for public pickers (e.g. citizen sign-up). */
@Data @Builder
public class MunicipalitySummaryResponse {
    private UUID   id;
    private String name;
    private String state;
}
