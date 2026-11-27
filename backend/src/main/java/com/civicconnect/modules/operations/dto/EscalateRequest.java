package com.civicconnect.modules.operations.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class EscalateRequest {
    @NotBlank(message = "Reason is required")
    private String reason;
}
