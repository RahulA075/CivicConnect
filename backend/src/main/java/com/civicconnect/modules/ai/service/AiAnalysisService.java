package com.civicconnect.modules.ai.service;

import com.civicconnect.modules.ai.dto.*;

import java.util.List;
import java.util.UUID;

public interface AiAnalysisService {

    /**
     * Full AI analysis of an issue — category, severity, spam, summary, suggestions.
     * If an imageUrl is included, image classification is also run.
     * Results are persisted to {@code ai_issue_analysis} if issueId is provided.
     */
    AiAnalysisResponse analyzeText(AiTextAnalysisRequest request);

    /**
     * Duplicate check against nearby open issues in the same municipality.
     * Uses text similarity via AI to score each candidate.
     */
    DuplicateCheckResponse checkDuplicate(DuplicateCheckRequest request);

    /**
     * Returns 1–3 smart suggestions for a partially typed issue.
     * Designed for real-time use — fast, cheap model.
     */
    List<String> getSmartSuggestions(SmartSuggestRequest request);

    /**
     * Retrieves the stored AI analysis for an issue.
     * Returns null if not yet analysed.
     */
    AiAnalysisResponse getAnalysisForIssue(UUID issueId);

    /**
     * Triggers (or re-triggers) full analysis for an already-submitted issue.
     * Called asynchronously from the issue submission event listener.
     */
    void analyzeIssueAsync(UUID issueId);
}
