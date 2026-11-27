package com.civicconnect.modules.admin.dto;

import lombok.Builder;
import lombok.Data;
import java.util.UUID;

@Data @Builder
public class DepartmentResponse {
    private UUID   id;
    private String name;
    private String description;
    private String iconName;
    private String colorHex;
    private String contactEmail;
    private String contactPhone;
    private boolean active;
    private UUID   municipalityId;
}
