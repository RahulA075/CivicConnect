package com.civicconnect.modules.issue.service;

import com.civicconnect.common.enums.IssueStatus;
import com.civicconnect.common.enums.IssuePriority;
import com.civicconnect.common.enums.UserRole;
import com.civicconnect.common.exception.BusinessRuleException;
import com.civicconnect.common.exception.ResourceNotFoundException;
import com.civicconnect.common.util.InputSanitizer;
import com.civicconnect.common.util.TrackingIdGenerator;
import com.civicconnect.modules.geospatial.repository.WardRepository;
import com.civicconnect.modules.iam.entity.User;
import com.civicconnect.modules.iam.repository.UserRepository;
import com.civicconnect.modules.issue.dto.*;
import com.civicconnect.modules.issue.entity.*;
import com.civicconnect.modules.issue.event.IssueStatusChangedEvent;
import com.civicconnect.modules.issue.event.IssueSubmittedEvent;
import com.civicconnect.modules.issue.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.persistence.criteria.Predicate;
import java.time.Instant;
import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class IssueServiceImpl implements IssueService {

    private final IssueRepository            issueRepository;
    private final IssueCategoryRepository    categoryRepository;
    private final VoteRepository             voteRepository;
    private final IssueImageRepository       imageRepository;
    private final IssueStatusHistoryRepository historyRepository;
    private final UserRepository             userRepository;
    private final WardRepository             wardRepository;
    private final TrackingIdGenerator        trackingIdGenerator;
    private final ApplicationEventPublisher  eventPublisher;

    private static final GeometryFactory GEO_FACTORY =
            new GeometryFactory(new PrecisionModel(), 4326);

    // ── Submit ────────────────────────────────────────────────────────────────

    @Override
    @Transactional
    public IssueResponse submit(IssueSubmitRequest request, UUID reportedById) {
        User reporter = findActiveUser(reportedById);

        IssueCategory category = categoryRepository.findById(request.getCategoryId())
                .filter(IssueCategory::isActive)
                .orElseThrow(() -> new ResourceNotFoundException("Category not found: " + request.getCategoryId()));

        Point location = GEO_FACTORY.createPoint(
                new Coordinate(request.getLongitude(), request.getLatitude()));
        location.setSRID(4326);

        // Auto-detect ward from GPS
        var ward = wardRepository.findByContainingPoint(
                category.getMunicipality().getId(),
                request.getLatitude(), request.getLongitude()).orElse(null);

        String trackingId = trackingIdGenerator.generate();

        Issue issue = Issue.builder()
                .municipality(category.getMunicipality())
                .category(category)
                .department(category.getDepartment())
                .ward(ward)
                .reportedBy(reporter)
                .trackingId(trackingId)
                .title(InputSanitizer.sanitize(request.getTitle()))
                .description(InputSanitizer.sanitizeMultiline(request.getDescription()))
                .location(location)
                .addressText(InputSanitizer.sanitize(request.getAddressText()))
                .priority(request.getPriority() != null ? request.getPriority() : IssuePriority.MEDIUM)
                .status(IssueStatus.SUBMITTED)
                .anonymous(request.isAnonymous())
                .build();

        issue = issueRepository.save(issue);

        // Record initial status history
        recordHistory(issue, null, IssueStatus.SUBMITTED, reporter, null);

        eventPublisher.publishEvent(new IssueSubmittedEvent(
                this, issue.getId(), reportedById,
                issue.getMunicipality().getId(), trackingId));

        log.info("Issue submitted: {} by user {}", trackingId, reportedById);
        return toResponse(issue, reportedById);
    }

    // ── Get by ID ─────────────────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public IssueResponse getById(UUID id, UUID requestingUserId) {
        Issue issue = issueRepository.findActiveById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Issue not found: " + id));
        return toResponse(issue, requestingUserId);
    }

    // ── Get by tracking ID ────────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public IssueResponse getByTrackingId(String trackingId) {
        Issue issue = issueRepository.findByTrackingIdAndDeletedAtIsNull(trackingId)
                .orElseThrow(() -> new ResourceNotFoundException("Issue not found: " + trackingId));
        return toResponse(issue, null);
    }

    // ── My issues ─────────────────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public Page<IssueResponse> getMyIssues(UUID userId, Pageable pageable) {
        return issueRepository.findByReportedBy(userId, pageable)
                .map(i -> toResponse(i, userId));
    }

    // ── By department ─────────────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public Page<IssueResponse> getByDepartment(UUID departmentId, String status, Pageable pageable) {
        IssueStatus st = status != null ? IssueStatus.valueOf(status.toUpperCase()) : null;
        return issueRepository.findByDepartment(departmentId, st, pageable)
                .map(i -> toResponse(i, null));
    }

    // ── Public feed ───────────────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public Page<IssueResponse> getPublicFeed(UUID municipalityId, String categoryId,
                                              String status, Pageable pageable) {
        Specification<Issue> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            predicates.add(cb.equal(root.get("municipality").get("id"), municipalityId));
            predicates.add(cb.isNull(root.get("deletedAt")));
            predicates.add(cb.isFalse(root.get("merged")));
            if (categoryId != null) {
                predicates.add(cb.equal(root.get("category").get("id"),
                        UUID.fromString(categoryId)));
            }
            if (status != null) {
                predicates.add(cb.equal(root.get("status"),
                        IssueStatus.valueOf(status.toUpperCase())));
            }
            return cb.and(predicates.toArray(new Predicate[0]));
        };
        return issueRepository.findAll(spec, pageable).map(i -> toResponse(i, null));
    }

    // ── Nearby issues ─────────────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public List<NearbyIssueResponse> getNearby(double lat, double lng,
                                               int radiusMetres, UUID municipalityId) {
        // Use Haversine approximation: 1 degree ≈ 111,320 metres
        double delta = radiusMetres / 111_320.0;

        Specification<Issue> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            predicates.add(cb.equal(root.get("municipality").get("id"), municipalityId));
            predicates.add(cb.isNull(root.get("deletedAt")));
            predicates.add(cb.notEqual(root.get("status"), IssueStatus.CLOSED));
            predicates.add(cb.notEqual(root.get("status"), IssueStatus.REJECTED));
            return cb.and(predicates.toArray(new Predicate[0]));
        };

        return issueRepository.findAll(spec).stream()
                .filter(i -> {
                    double iLat = i.getLocation().getY();
                    double iLng = i.getLocation().getX();
                    return Math.abs(iLat - lat) <= delta && Math.abs(iLng - lng) <= delta;
                })
                .map(i -> {
                    double iLat = i.getLocation().getY();
                    double iLng = i.getLocation().getX();
                    double dist = haversine(lat, lng, iLat, iLng);
                    return NearbyIssueResponse.builder()
                            .id(i.getId())
                            .trackingId(i.getTrackingId())
                            .title(i.getTitle())
                            .status(i.getStatus())
                            .categoryName(i.getCategory().getName())
                            .categoryColor(i.getCategory().getColorHex())
                            .latitude(iLat)
                            .longitude(iLng)
                            .addressText(i.getAddressText())
                            .priority(i.getPriority().name())
                            .distanceMetres(dist)
                            .upvoteCount(i.getUpvoteCount())
                            .build();
                })
                .filter(r -> r.getDistanceMetres() <= radiusMetres)
                .sorted(Comparator.comparingDouble(NearbyIssueResponse::getDistanceMetres))
                .toList();
    }

    // ── Map issues (public, bounding box) ────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public List<NearbyIssueResponse> getMapIssues(double lat, double lng,
                                                   int radiusMetres, UUID municipalityId,
                                                   String status, String categoryId) {
        double delta = radiusMetres / 111_320.0;

        Specification<Issue> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            predicates.add(cb.equal(root.get("municipality").get("id"), municipalityId));
            predicates.add(cb.isNull(root.get("deletedAt")));
            predicates.add(cb.isFalse(root.get("merged")));
            if (status != null && !status.isBlank()) {
                predicates.add(cb.equal(root.get("status"),
                        IssueStatus.valueOf(status.toUpperCase())));
            }
            if (categoryId != null && !categoryId.isBlank()) {
                predicates.add(cb.equal(root.get("category").get("id"),
                        UUID.fromString(categoryId)));
            }
            return cb.and(predicates.toArray(new Predicate[0]));
        };

        return issueRepository.findAll(spec).stream()
                .filter(i -> {
                    double iLat = i.getLocation().getY();
                    double iLng = i.getLocation().getX();
                    return Math.abs(iLat - lat) <= delta && Math.abs(iLng - lng) <= delta;
                })
                .map(i -> {
                    double iLat = i.getLocation().getY();
                    double iLng = i.getLocation().getX();
                    double dist = haversine(lat, lng, iLat, iLng);
                    return NearbyIssueResponse.builder()
                            .id(i.getId())
                            .trackingId(i.getTrackingId())
                            .title(i.getTitle())
                            .status(i.getStatus())
                            .categoryName(i.getCategory().getName())
                            .categoryColor(i.getCategory().getColorHex())
                            .latitude(iLat)
                            .longitude(iLng)
                            .addressText(i.getAddressText())
                            .priority(i.getPriority().name())
                            .distanceMetres(dist)
                            .upvoteCount(i.getUpvoteCount())
                            .build();
                })
                .filter(r -> r.getDistanceMetres() <= radiusMetres)
                .sorted(Comparator.comparingDouble(NearbyIssueResponse::getDistanceMetres))
                .toList();
    }

    // ── Update status ─────────────────────────────────────────────────────────

    @Override
    @Transactional
    public IssueResponse updateStatus(UUID issueId, IssueStatusUpdateRequest request, UUID changedById) {
        Issue issue = findActive(issueId);
        User changer = findActiveUser(changedById);

        IssueStatus old = issue.getStatus();
        issue.setStatus(request.getStatus());

        if (request.getStatus() == IssueStatus.RESOLVED) {
            issue.setResolvedAt(Instant.now());
        }
        issue = issueRepository.save(issue);

        recordHistory(issue, old, request.getStatus(), changer, request.getNote());

        eventPublisher.publishEvent(new IssueStatusChangedEvent(
                this, issue.getId(), issue.getMunicipality().getId(),
                issue.getReportedBy() != null ? issue.getReportedBy().getId() : null,
                issue.getTrackingId(), old, request.getStatus(), changedById));

        return toResponse(issue, changedById);
    }

    // ── Citizen verify ────────────────────────────────────────────────────────

    @Override
    @Transactional
    public IssueResponse verify(UUID issueId, IssueVerifyRequest request, UUID citizenId) {
        Issue issue = findActive(issueId);

        if (issue.getStatus() != IssueStatus.RESOLVED) {
            throw new BusinessRuleException("INVALID_STATE",
                    "Only RESOLVED issues can be verified");
        }
        if (issue.getReportedBy() == null ||
                !issue.getReportedBy().getId().equals(citizenId)) {
            throw new BusinessRuleException("NOT_REPORTER",
                    "Only the original reporter can verify this issue");
        }

        IssueStatus newStatus = Boolean.TRUE.equals(request.getResolved())
                ? IssueStatus.VERIFIED
                : IssueStatus.REOPENED;

        IssueStatus old = issue.getStatus();
        issue.setStatus(newStatus);
        if (Boolean.TRUE.equals(request.getResolved())) {
            issue.setVerifiedAt(Instant.now());
            issue.setClosedAt(Instant.now());
        }
        if (request.getRating()  != null) issue.setCitizenRating(request.getRating());
        if (request.getComment() != null) issue.setCitizenComment(request.getComment());
        issue = issueRepository.save(issue);

        User citizen = findActiveUser(citizenId);
        recordHistory(issue, old, newStatus, citizen, request.getRejectionReason());

        return toResponse(issue, citizenId);
    }

    // ── Upvote ────────────────────────────────────────────────────────────────

    @Override
    @Transactional
    public IssueResponse upvote(UUID issueId, UUID userId) {
        Issue issue = findActive(issueId);
        User  user  = findActiveUser(userId);

        if (voteRepository.existsByIssueIdAndUserId(issueId, userId)) {
            throw new BusinessRuleException("ALREADY_VOTED", "You have already upvoted this issue");
        }

        Vote vote = Vote.builder().issue(issue).user(user).build();
        voteRepository.save(vote);
        issue.setUpvoteCount(issue.getUpvoteCount() + 1);
        issueRepository.save(issue);

        return toResponse(issue, userId);
    }

    // ── Assign ────────────────────────────────────────────────────────────────

    @Override
    @Transactional
    public IssueResponse assign(UUID issueId, UUID assignedToId, UUID assignedById, String note) {
        Issue issue    = findActive(issueId);
        User  worker   = findActiveUser(assignedToId);
        User  assigner = findActiveUser(assignedById);

        IssueStatus old = issue.getStatus();
        issue.setAssignedTo(worker);
        issue.setStatus(IssueStatus.ASSIGNED);
        issue = issueRepository.save(issue);

        recordHistory(issue, old, IssueStatus.ASSIGNED, assigner, note);
        return toResponse(issue, assignedById);
    }

    // ── Change priority ───────────────────────────────────────────────────────

    @Override
    @Transactional
    public IssueResponse changePriority(UUID issueId, String priority, UUID changedById) {
        Issue issue = findActive(issueId);
        IssuePriority newPriority = IssuePriority.valueOf(priority.toUpperCase());
        issue.setPriority(newPriority);
        issueRepository.save(issue);
        return toResponse(issue, changedById);
    }

    // ── Status history ────────────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public List<IssueStatusHistoryResponse> getStatusHistory(UUID issueId) {
        return historyRepository.findByIssueIdOrderByCreatedAtAsc(issueId).stream()
                .map(h -> IssueStatusHistoryResponse.builder()
                        .id(h.getId())
                        .oldStatus(h.getOldStatus())
                        .newStatus(h.getNewStatus())
                        .changedByName(h.getChangedBy() != null
                                ? h.getChangedBy().getFullName() : "System")
                        .changedByRole(h.getChangedByRole())
                        .note(h.getNote())
                        .createdAt(h.getCreatedAt())
                        .build())
                .toList();
    }

    // ── Worker task list ──────────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public List<IssueResponse> getTasksForWorker(UUID workerId) {
        return issueRepository.findActiveTasksForWorker(workerId).stream()
                .map(i -> toResponse(i, workerId))
                .toList();
    }

    // ── Merge ─────────────────────────────────────────────────────────────────

    @Override
    @Transactional
    public void merge(UUID primaryIssueId, UUID duplicateIssueId, UUID performedById) {
        Issue primary   = findActive(primaryIssueId);
        Issue duplicate = findActive(duplicateIssueId);

        duplicate.setMerged(true);
        duplicate.setMergedInto(primary);
        duplicate.setStatus(IssueStatus.CLOSED);
        duplicate.setClosedAt(Instant.now());
        issueRepository.save(duplicate);

        log.info("Issue {} merged into {} by {}", duplicateIssueId, primaryIssueId, performedById);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private Issue findActive(UUID id) {
        return issueRepository.findActiveById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Issue not found: " + id));
    }

    private User findActiveUser(UUID id) {
        return userRepository.findActiveById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + id));
    }

    private void recordHistory(Issue issue, IssueStatus oldStatus,
                               IssueStatus newStatus, User changedBy, String note) {
        UserRole role = changedBy != null ? changedBy.getRole().getName() : null;
        IssueStatusHistory h = IssueStatusHistory.builder()
                .issue(issue)
                .changedBy(changedBy)
                .changedByRole(role)
                .oldStatus(oldStatus)
                .newStatus(newStatus)
                .note(note)
                .build();
        historyRepository.save(h);
    }

    private IssueResponse toResponse(Issue issue, UUID requestingUserId) {
        boolean upvoted = requestingUserId != null &&
                voteRepository.existsByIssueIdAndUserId(issue.getId(), requestingUserId);
        List<String> imageUrls = issue.getId() == null ? List.of()
                : imageRepository.findActiveByIssueId(issue.getId()).stream()
                        .map(IssueImage::getCdnUrl)
                        .filter(Objects::nonNull)
                        .toList();

        return IssueResponse.builder()
                .id(issue.getId())
                .trackingId(issue.getTrackingId())
                .title(issue.getTitle())
                .description(issue.getDescription())
                .status(issue.getStatus())
                .priority(issue.getPriority())
                .overdue(issue.isOverdue())
                .upvoteCount(issue.getUpvoteCount())
                .commentCount(issue.getCommentCount())
                .latitude(issue.getLocation().getY())
                .longitude(issue.getLocation().getX())
                .addressText(issue.getAddressText())
                .slaDeadline(issue.getSlaDeadline())
                .createdAt(issue.getCreatedAt())
                .resolvedAt(issue.getResolvedAt())
                .categoryName(issue.getCategory().getName())
                .categoryIcon(issue.getCategory().getIconName())
                .categoryColor(issue.getCategory().getColorHex())
                .categoryId(issue.getCategory().getId())
                .departmentName(issue.getDepartment() != null
                        ? issue.getDepartment().getName() : null)
                .departmentId(issue.getDepartment() != null
                        ? issue.getDepartment().getId() : null)
                .wardName(issue.getWard() != null ? issue.getWard().getName() : null)
                .wardId(issue.getWard() != null ? issue.getWard().getId() : null)
                .reporterName(issue.isAnonymous() ? "Anonymous"
                        : (issue.getReportedBy() != null
                                ? issue.getReportedBy().getFullName() : null))
                .previewImageUrl(imageUrls.isEmpty() ? null : imageUrls.get(0))
                .imageUrls(imageUrls)
                .assignedTo(issue.getAssignedTo() != null
                        ? issue.getAssignedTo().getFullName() : null)
                .assignedToId(issue.getAssignedTo() != null
                        ? issue.getAssignedTo().getId() : null)
                .municipalityName(issue.getMunicipality() != null
                        ? issue.getMunicipality().getName() : null)
                .upvotedByMe(upvoted)
                .citizenRating(issue.getCitizenRating())
                .build();
    }

    /** Haversine formula — returns distance in metres. */
    private static double haversine(double lat1, double lng1, double lat2, double lng2) {
        final double R = 6_371_000.0;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLng = Math.toRadians(lng2 - lng1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLng / 2) * Math.sin(dLng / 2);
        return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }
}
