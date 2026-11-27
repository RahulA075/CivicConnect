package com.civicconnect.modules.analytics.service;

import com.civicconnect.common.enums.IssueStatus;
import com.civicconnect.modules.analytics.dto.DashboardSummaryResponse;
import com.civicconnect.modules.analytics.dto.DashboardSummaryResponse.DepartmentStatDto;
import com.civicconnect.modules.analytics.dto.HeatmapDataResponse;
import com.civicconnect.modules.analytics.dto.HeatmapDataResponse.HeatmapPoint;
import com.civicconnect.modules.analytics.dto.IssueTrendResponse;
import com.civicconnect.modules.analytics.dto.IssueTrendResponse.TrendPoint;
import com.civicconnect.modules.issue.entity.Issue;
import com.civicconnect.modules.issue.repository.IssueRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.persistence.criteria.Predicate;
import java.time.*;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class AnalyticsServiceImpl implements AnalyticsService {

    private final IssueRepository issueRepository;

    // ── Dashboard summary ─────────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public DashboardSummaryResponse getDashboardSummary(UUID municipalityId) {
        Specification<Issue> base = municipalitySpec(municipalityId);
        List<Issue> all = issueRepository.findAll(base);

        long totalOpen       = all.stream().filter(i -> isOpen(i.getStatus())).count();
        long totalInProgress = all.stream().filter(i -> i.getStatus() == IssueStatus.IN_PROGRESS).count();
        long totalResolved   = all.stream().filter(i -> i.getStatus() == IssueStatus.RESOLVED ||
                                                        i.getStatus() == IssueStatus.VERIFIED).count();
        long totalOverdue    = all.stream().filter(Issue::isOverdue).count();
        long totalClosed     = all.stream().filter(i -> i.getStatus() == IssueStatus.CLOSED).count();

        double avgRating = all.stream()
                .filter(i -> i.getCitizenRating() != null)
                .mapToInt(Issue::getCitizenRating)
                .average()
                .orElse(0);

        // Per-department stats
        Map<String, List<Issue>> byDept = all.stream()
                .filter(i -> i.getDepartment() != null)
                .collect(Collectors.groupingBy(i -> i.getDepartment().getName()));

        List<DepartmentStatDto> deptStats = byDept.entrySet().stream()
                .map(e -> {
                    List<Issue> issues = e.getValue();
                    long open    = issues.stream().filter(i -> isOpen(i.getStatus())).count();
                    long overdue = issues.stream().filter(Issue::isOverdue).count();
                    long total   = issues.size();
                    long onTime  = issues.stream()
                            .filter(i -> i.getStatus() == IssueStatus.RESOLVED ||
                                         i.getStatus() == IssueStatus.VERIFIED)
                            .filter(i -> i.getSlaDeadline() == null ||
                                         (i.getResolvedAt() != null &&
                                          i.getResolvedAt().isBefore(i.getSlaDeadline())))
                            .count();
                    double slaCompliance = total > 0 ? (onTime * 100.0 / total) : 100.0;

                    double avgResHours = issues.stream()
                            .filter(i -> i.getResolvedAt() != null && i.getCreatedAt() != null)
                            .mapToLong(i -> ChronoUnit.HOURS.between(
                                    i.getCreatedAt(), i.getResolvedAt()))
                            .average()
                            .orElse(0);

                    return DepartmentStatDto.builder()
                            .departmentName(e.getKey())
                            .openCount(open)
                            .overdueCount(overdue)
                            .slaCompliancePct(slaCompliance)
                            .avgResolutionHours(avgResHours)
                            .build();
                })
                .sorted(Comparator.comparingLong(DepartmentStatDto::getOverdueCount).reversed())
                .collect(Collectors.toList());

        return DashboardSummaryResponse.builder()
                .totalOpen(totalOpen)
                .totalInProgress(totalInProgress)
                .totalResolved(totalResolved)
                .totalOverdue(totalOverdue)
                .totalClosed(totalClosed)
                .avgCitizenRating(avgRating)
                .departmentStats(deptStats)
                .build();
    }

    // ── Heatmap ───────────────────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public HeatmapDataResponse getHeatmapData(UUID municipalityId, LocalDate from, LocalDate to) {
        Instant fromInstant = from.atStartOfDay(ZoneOffset.UTC).toInstant();
        Instant toInstant   = to.plusDays(1).atStartOfDay(ZoneOffset.UTC).toInstant();

        Specification<Issue> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            predicates.add(cb.equal(root.get("municipality").get("id"), municipalityId));
            predicates.add(cb.isNull(root.get("deletedAt")));
            predicates.add(cb.greaterThanOrEqualTo(root.get("createdAt"), fromInstant));
            predicates.add(cb.lessThan(root.get("createdAt"), toInstant));
            return cb.and(predicates.toArray(new Predicate[0]));
        };

        List<HeatmapPoint> points = issueRepository.findAll(spec).stream()
                .map(i -> HeatmapPoint.builder()
                        .latitude(i.getLocation().getY())
                        .longitude(i.getLocation().getX())
                        .weight(1 + i.getUpvoteCount())
                        .build())
                .collect(Collectors.toList());

        return HeatmapDataResponse.builder().points(points).build();
    }

    // ── Trend ─────────────────────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public IssueTrendResponse getIssueTrend(UUID municipalityId, int days, UUID departmentId) {
        Instant from = Instant.now().minus(days, ChronoUnit.DAYS);

        Specification<Issue> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            predicates.add(cb.equal(root.get("municipality").get("id"), municipalityId));
            predicates.add(cb.isNull(root.get("deletedAt")));
            predicates.add(cb.greaterThanOrEqualTo(root.get("createdAt"), from));
            if (departmentId != null) {
                predicates.add(cb.equal(root.get("department").get("id"), departmentId));
            }
            return cb.and(predicates.toArray(new Predicate[0]));
        };

        List<Issue> issues = issueRepository.findAll(spec);

        // Build per-day buckets
        Map<LocalDate, List<Issue>> byDay = issues.stream()
                .collect(Collectors.groupingBy(i ->
                        i.getCreatedAt().atZone(ZoneOffset.UTC).toLocalDate()));

        List<TrendPoint> trend = new ArrayList<>();
        for (int d = days - 1; d >= 0; d--) {
            LocalDate day  = LocalDate.now(ZoneOffset.UTC).minusDays(d);
            List<Issue> dayIssues = byDay.getOrDefault(day, List.of());
            trend.add(TrendPoint.builder()
                    .day(day)
                    .submitted(dayIssues.size())
                    .resolved(dayIssues.stream()
                            .filter(i -> i.getStatus() == IssueStatus.RESOLVED ||
                                         i.getStatus() == IssueStatus.VERIFIED).count())
                    .overdueCount(dayIssues.stream().filter(Issue::isOverdue).count())
                    .build());
        }

        return IssueTrendResponse.builder().data(trend).build();
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private Specification<Issue> municipalitySpec(UUID municipalityId) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            predicates.add(cb.equal(root.get("municipality").get("id"), municipalityId));
            predicates.add(cb.isNull(root.get("deletedAt")));
            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }

    private boolean isOpen(IssueStatus status) {
        return status == IssueStatus.SUBMITTED || status == IssueStatus.ASSIGNED ||
               status == IssueStatus.IN_PROGRESS || status == IssueStatus.REOPENED;
    }
}
