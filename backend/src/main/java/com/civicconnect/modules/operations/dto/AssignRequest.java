package com.civicconnect.modules.operations.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.UUID;

@Data
public class AssignRequest {
    @NotNull(message = "assignedToId is required")
    private UUID assignedToId;
    private String note;
}
