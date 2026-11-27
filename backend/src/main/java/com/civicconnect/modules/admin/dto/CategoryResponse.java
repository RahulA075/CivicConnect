package com.civicconnect.modules.admin.dto;

import lombok.Builder;
import lombok.Data;
import java.util.UUID;

@Data @Builder
public class CategoryResponse {
    private UUID   id;
    private UUID   municipalityId;
    private UUID   departmentId;
    private String departmentName;
    private UUID   parentId;
    private String parentName;
    private String name;
    private String description;
    private String iconName;
    private String colorHex;
    private int    sortOrder;
    private boolean active;
}
