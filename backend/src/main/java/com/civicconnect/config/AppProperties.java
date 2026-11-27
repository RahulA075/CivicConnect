package com.civicconnect.config;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;
import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

/**
 * Strongly-typed binding for all {@code app.*} properties in application.yml.
 * Validated at startup — missing required values fail fast.
 */
@Getter
@Setter
@Validated
@ConfigurationProperties(prefix = "app")
public class AppProperties {

    private final Jwt jwt = new Jwt();
    private final Cors cors = new Cors();
    private final RateLimit rateLimit = new RateLimit();
    private final Storage storage = new Storage();
    private final Sla sla = new Sla();
    private final Notification notification = new Notification();
    private final Ai ai = new Ai();

    @Getter @Setter
    public static class Jwt {
        @NotBlank
        private String secret;

        @Positive
        private long accessTokenExpiryMs = 900_000L;

        @Positive
        private long refreshTokenExpiryMs = 2_592_000_000L;
    }

    @Getter @Setter
    public static class Cors {
        private String allowedOrigins = "http://localhost:3000";
        private long maxAgeSeconds = 3600L;
    }

    @Getter @Setter
    public static class RateLimit {
        @Positive private int capacity = 100;
        @Positive private int refillTokens = 100;
        @Positive private int refillDurationSeconds = 60;
    }

    @Getter @Setter
    public static class Storage {
        private String bucket;
        private String region;
        private String cdnBaseUrl;
    }

    @Getter @Setter
    public static class Sla {
        @Positive private int defaultResolutionHours = 72;
    }

    @Getter @Setter
    public static class Notification {
        @Positive private int otpExpiryMinutes = 10;
        @Positive private int otpMaxAttempts = 5;
        private String fcmCredentialsPath = "";  // path to service-account JSON, or empty to skip
    }

    @Getter @Setter
    public static class Ai {
        /** OpenAI-compatible API key (works with OpenAI, Azure OpenAI, or any compatible provider). */
        private String apiKey = "";

        /** Model to use for text analysis (e.g. gpt-4o-mini, gpt-3.5-turbo). */
        private String textModel = "gpt-4o-mini";

        /** Model to use for vision/image analysis (e.g. gpt-4o). */
        private String visionModel = "gpt-4o";

        /** Base URL for the OpenAI-compatible API. Override for Azure or self-hosted models. */
        private String baseUrl = "https://api.openai.com/v1";

        /** Request timeout in seconds. */
        @Positive private int timeoutSeconds = 30;

        /**
         * Minimum confidence (0.0–1.0) required for the AI suggestion to auto-apply.
         * Below this threshold the suggestion is returned for human review only.
         */
        private double autoApplyConfidenceThreshold = 0.85;

        /**
         * Maximum number of existing issues to compare when checking for duplicates.
         * Higher values are more accurate but slower.
         */
        @Positive private int duplicateCheckMaxCandidates = 50;

        /**
         * Whether AI analysis is enabled at all. Set false to disable without removing config.
         */
        private boolean enabled = true;
    }
}
