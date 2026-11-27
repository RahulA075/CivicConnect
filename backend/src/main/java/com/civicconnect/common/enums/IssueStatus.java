package com.civicconnect.common.enums;

/** Maps to the PostgreSQL {@code issue_status} ENUM. */
public enum IssueStatus {
    DRAFT,
    SUBMITTED,
    ASSIGNED,
    IN_PROGRESS,
    RESOLVED,
    VERIFIED,
    REOPENED,
    CLOSED,
    REJECTED
}
