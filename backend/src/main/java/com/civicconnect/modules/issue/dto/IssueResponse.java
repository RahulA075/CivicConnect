package com.civicconnect.modules.issue.dto;

import com.civicconnect.common.enums.IssuePriority;
import com.civicconnect.common.enums.IssueStatus;
import lombok.Builder;
import lombok.Data;

import java.time.Instant;
import java.util.UUID;

/** Response body for issue read endpoints */
@Data
@Builder
public class IssueResponse {
    private UUID          id;
    private String        trackingId;
    private String        title;
    private String        description;
    private IssueStatus   status;
    private IssuePriority priority;
    private boolean       overdue;
    private int           upvoteCount;
    private int           commentCount;
    private double        latitude;
    private double        longitude;
    private String        addressText;
    private Instant       slaDeadline;
    private Instant       createdAt;
    private Instant       resolvedAt;
    private String        categoryName;
    private String        categoryIcon;
    private String        categoryColor;
    private UUID          categoryId;
    private String        departmentName;
    private UUID          departmentId;
    private String        wardName;
    private UUID          wardId;
    private String        reporterName;
    private String        previewImageUrl;
    private Integer       citizenRating;
}
