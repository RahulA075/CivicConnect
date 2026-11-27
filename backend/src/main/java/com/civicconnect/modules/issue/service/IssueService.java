package com.civicconnect.modules.issue.service;

import com.civicconnect.modules.issue.dto.*;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.UUID;

/** Issue lifecycle service contract. Business logic implemented in Phase 4. */
public interface IssueService {

    IssueResponse submit(IssueSubmitRequest request, UUID reportedById);

    IssueResponse getById(UUID id, UUID requestingUserId);

    IssueResponse getByTrackingId(String trackingId);

    Page<IssueResponse> getMyIssues(UUID userId, Pageable pageable);

    Page<IssueResponse> getByDepartment(UUID departmentId, String status, Pageable pageable);

    Page<IssueResponse> getPublicFeed(UUID municipalityId, String categoryId,
                                      String status, Pageable pageable);

    List<NearbyIssueResponse> getNearby(double lat, double lng,
                                        int radiusMetres, UUID municipalityId);

    List<NearbyIssueResponse> getMapIssues(double lat, double lng,
                                            int radiusMetres, UUID municipalityId,
                                            String status, String categoryId);

    IssueResponse updateStatus(UUID issueId, IssueStatusUpdateRequest request, UUID changedById);

    IssueResponse verify(UUID issueId, IssueVerifyRequest request, UUID citizenId);

    IssueResponse upvote(UUID issueId, UUID userId);

    IssueResponse assign(UUID issueId, UUID assignedToId, UUID assignedById, String note);

    IssueResponse changePriority(UUID issueId, String priority, UUID changedById);

    void merge(UUID primaryIssueId, UUID duplicateIssueId, UUID performedById);

    List<IssueStatusHistoryResponse> getStatusHistory(UUID issueId);

    List<IssueResponse> getTasksForWorker(UUID workerId);
}
