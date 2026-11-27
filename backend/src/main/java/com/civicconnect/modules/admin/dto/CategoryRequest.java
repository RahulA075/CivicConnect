package com.civicconnect.modules.admin.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.util.UUID;

/** Request body for creating or updating an IssueCategory. */
@Data
public class CategoryRequest {
    @NotNull  private UUID   departmentId;
    private UUID   parentId;          // null = top-level category
    @NotBlank private String name;
    private String description;
    @NotBlank private String iconName;
    private String colorHex = "#1565C0";
    private int    sortOrder = 0;
}
