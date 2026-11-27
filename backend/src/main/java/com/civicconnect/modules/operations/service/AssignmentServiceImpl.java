package com.civicconnect.modules.operations.service;

import com.civicconnect.common.enums.IssueStatus;
import com.civicconnect.common.exception.ResourceNotFoundException;
import com.civicconnect.modules.issue.dto.IssueStatusUpdateRequest;
import com.civicconnect.modules.issue.service.IssueService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class AssignmentServiceImpl implements AssignmentService {

    private final IssueService issueService;

    @Override
    public void assign(UUID issueId, UUID assignedToId, UUID assignedById, String note) {
        issueService.assign(issueId, assignedToId, assignedById, note);
    }

    @Override
    public void reassign(UUID issueId, UUID newAssigneeId, UUID performedById, String note) {
        issueService.assign(issueId, newAssigneeId, performedById, note);
    }

    @Override
    public void escalate(UUID issueId, UUID performedById, String reason) {
        var req = new IssueStatusUpdateRequest();
        req.setStatus(IssueStatus.SUBMITTED);
        req.setNote("ESCALATED: " + reason);
        issueService.updateStatus(issueId, req, performedById);
        log.info("Issue {} escalated by {}", issueId, performedById);
    }

    @Override
    public void reject(UUID issueId, UUID performedById, String reason) {
        var req = new IssueStatusUpdateRequest();
        req.setStatus(IssueStatus.REJECTED);
        req.setNote(reason);
        issueService.updateStatus(issueId, req, performedById);
        log.info("Issue {} rejected by {}", issueId, performedById);
    }
}
