package com.civicconnect.modules.issue.dto;

import com.civicconnect.common.enums.IssueStatus;
import lombok.Builder;
import lombok.Data;

import java.util.UUID;

/** Lightweight response for nearby-issues / map endpoints */
@Data
@Builder
public class NearbyIssueResponse {
    private UUID        id;
    private String      trackingId;
    private String      title;
    private IssueStatus status;
    private String      categoryName;
    private String      categoryColor;
    private double      latitude;
    private double      longitude;
    private String      addressText;
    private double      distanceMetres;
    private int         upvoteCount;
    private String      priority;
}
