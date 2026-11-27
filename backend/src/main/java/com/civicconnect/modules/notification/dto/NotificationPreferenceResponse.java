package com.civicconnect.modules.notification.dto;

import lombok.Builder;
import lombok.Data;
import java.util.Map;

@Data @Builder
public class NotificationPreferenceResponse {
    private boolean pushEnabled;
    private boolean emailEnabled;
    private boolean smsEnabled;
    private Map<String, Object> eventOverrides;
}
