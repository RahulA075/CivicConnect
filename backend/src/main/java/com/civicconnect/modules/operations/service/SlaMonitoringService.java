package com.civicconnect.modules.operations.service;

import com.civicconnect.modules.issue.repository.IssueRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;

/**
 * Scheduled job that flags overdue issues every 15 minutes.
 * Runs the same logic as the PostgreSQL {@code mark_overdue_issues()} procedure
 * from the application layer for visibility and testability.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class SlaMonitoringService {

    private final IssueRepository issueRepository;

    @Scheduled(fixedDelayString = "PT15M", initialDelayString = "PT1M")
    @Transactional
    public void markOverdueIssues() {
        int updated = issueRepository.markOverdueIssues(Instant.now());
        if (updated > 0) {
            log.info("SLA Monitor: marked {} issue(s) as overdue", updated);
        }
    }
}
