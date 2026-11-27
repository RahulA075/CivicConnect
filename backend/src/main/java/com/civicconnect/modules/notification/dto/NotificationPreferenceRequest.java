package com.civicconnect.modules.notification.dto;

import lombok.Data;
import java.util.Map;

/** Request body for PUT /notifications/preferences */
@Data
public class NotificationPreferenceRequest {
    private Boolean pushEnabled;
    private Boolean emailEnabled;
    private Boolean smsEnabled;
    private Map<String, Object> eventOverrides; // e.g. {"NEARBY_ISSUE": false}
}
