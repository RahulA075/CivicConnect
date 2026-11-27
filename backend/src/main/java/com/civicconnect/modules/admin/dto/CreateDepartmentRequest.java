package com.civicconnect.modules.admin.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/** Request body for POST /admin/municipalities/{id}/departments */
@Data
public class CreateDepartmentRequest {
    @NotBlank private String name;
    private String description;
    private String iconName;
    private String colorHex;
    private String contactEmail;
    private String contactPhone;
}
