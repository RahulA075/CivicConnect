package com.civicconnect.modules.ai.dto;

import lombok.Builder;
import lombok.Data;

import java.util.List;

/** Response for POST /api/v1/ai/check-duplicate */
@Data
@Builder
public class DuplicateCheckResponse {

    private boolean         hasPotentialDuplicates;
    private List<Candidate> candidates;

    @Data
    @Builder
    public static class Candidate {
        private String trackingId;
        private String issueId;
        private String title;
        private String status;
        private double latitude;
        private double longitude;
        private double distanceMetres;
        /** 0.0–1.0 text similarity score from AI comparison. */
        private double similarityScore;
        /** Human-readable reason, e.g. "Same pothole description and location." */
        private String reason;
    }
}
