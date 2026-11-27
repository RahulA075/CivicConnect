package com.civicconnect.modules.notification.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/** Request body for POST /notifications/device-token */
@Data
public class RegisterTokenRequest {
    @NotBlank private String token;
    private String platform = "android"; // android | ios | web
}
