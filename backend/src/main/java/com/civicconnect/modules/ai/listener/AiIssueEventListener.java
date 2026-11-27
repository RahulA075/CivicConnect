package com.civicconnect.modules.ai.listener;

import com.civicconnect.modules.ai.service.AiAnalysisService;
import com.civicconnect.modules.issue.event.IssueSubmittedEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

/**
 * Listens to domain events from the issue module and triggers
 * asynchronous AI analysis in the background.
 *
 * <p>Runs on the {@code taskExecutor} thread pool (see AsyncConfig) so the
 * main issue-submission request returns immediately, without waiting for
 * the AI API round-trip.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class AiIssueEventListener {

    private final AiAnalysisService aiAnalysisService;

    /**
     * Triggered after every new issue submission.
     * Kicks off background AI analysis (category, severity, spam, summary).
     */
    @Async("taskExecutor")
    @EventListener
    public void onIssueSubmitted(IssueSubmittedEvent event) {
        log.debug("AI listener: received IssueSubmittedEvent for issue {}", event.getIssueId());
        try {
            aiAnalysisService.analyzeIssueAsync(event.getIssueId());
        } catch (Exception e) {
            // Never let AI failures bubble up and affect the submission flow
            log.error("AI analysis failed for issue {}: {}", event.getIssueId(), e.getMessage(), e);
        }
    }
}
