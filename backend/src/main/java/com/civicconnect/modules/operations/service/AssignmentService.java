package com.civicconnect.modules.operations.service;

import java.util.UUID;

/** Department operations: assignment, escalation, workload. */
public interface AssignmentService {
    void assign(UUID issueId, UUID assignedToId, UUID assignedById, String note);
    void reassign(UUID issueId, UUID newAssigneeId, UUID performedById, String note);
    void escalate(UUID issueId, UUID performedById, String reason);
    void reject(UUID issueId, UUID performedById, String reason);
}
