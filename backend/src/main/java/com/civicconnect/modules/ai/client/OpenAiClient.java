package com.civicconnect.modules.ai.client;

import com.civicconnect.config.AppProperties;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.time.Duration;
import java.util.List;
import java.util.Map;

/**
 * Low-level HTTP client for the OpenAI Chat Completions API.
 *
 * <p>Compatible with any OpenAI-spec endpoint (OpenAI, Azure OpenAI,
 * Google Gemini via compat layer, or self-hosted Ollama).
 *
 * <p>Does NOT throw if AI is disabled or the API key is missing —
 * it returns {@code null} so callers degrade gracefully.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class OpenAiClient {

    private final AppProperties appProperties;
    private final ObjectMapper  objectMapper;

    // ── Public API ───────────────────────────────────────────────────────────

    /**
     * Sends a chat-completion request with a system prompt + user prompt.
     *
     * @param model      model identifier (e.g. "gpt-4o-mini")
     * @param systemMsg  system role message
     * @param userMsg    user role message
     * @return parsed assistant reply string, or {@code null} on failure
     */
    public String chat(String model, String systemMsg, String userMsg) {
        if (!isAvailable()) return null;

        ChatRequest req = buildTextRequest(model, systemMsg, userMsg);
        return callApi(req);
    }

    /**
     * Sends a vision request: text + image URL for image analysis.
     *
     * @param model      vision-capable model (e.g. "gpt-4o")
     * @param systemMsg  system role message
     * @param textMsg    text part of the user message
     * @param imageUrl   publicly accessible image URL
     * @return parsed assistant reply string, or {@code null} on failure
     */
    public String vision(String model, String systemMsg, String textMsg, String imageUrl) {
        if (!isAvailable() || !StringUtils.hasText(imageUrl)) return null;

        ChatRequest req = buildVisionRequest(model, systemMsg, textMsg, imageUrl);
        return callApi(req);
    }

    // ── Private helpers ──────────────────────────────────────────────────────

    private boolean isAvailable() {
        AppProperties.Ai ai = appProperties.getAi();
        if (!ai.isEnabled()) {
            log.debug("AI analysis disabled by configuration");
            return false;
        }
        if (!StringUtils.hasText(ai.getApiKey())) {
            log.debug("AI_API_KEY not configured — skipping AI call");
            return false;
        }
        return true;
    }

    private String callApi(ChatRequest request) {
        AppProperties.Ai ai = appProperties.getAi();
        long start = System.currentTimeMillis();
        try {
            String requestBody = objectMapper.writeValueAsString(request);

            RestClient client = RestClient.builder()
                .baseUrl(ai.getBaseUrl())
                .defaultHeader(HttpHeaders.AUTHORIZATION, "Bearer " + ai.getApiKey())
                .defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                .build();

            String responseBody = client.post()
                .uri("/chat/completions")
                .body(requestBody)
                .retrieve()
                .body(String.class);

            ChatResponse response = objectMapper.readValue(responseBody, ChatResponse.class);
            if (response.getChoices() != null && !response.getChoices().isEmpty()) {
                String content = response.getChoices().get(0).getMessage().getContent();
                log.debug("AI call completed in {}ms", System.currentTimeMillis() - start);
                return content;
            }
        } catch (JsonProcessingException e) {
            log.error("Failed to serialize/deserialize AI request: {}", e.getMessage());
        } catch (RestClientException e) {
            log.error("AI API call failed ({}ms): {}", System.currentTimeMillis() - start, e.getMessage());
        } catch (Exception e) {
            log.error("Unexpected error in AI client: {}", e.getMessage(), e);
        }
        return null;
    }

    private ChatRequest buildTextRequest(String model, String systemMsg, String userMsg) {
        return ChatRequest.builder()
            .model(model)
            .messages(List.of(
                Map.of("role", "system", "content", systemMsg),
                Map.of("role", "user",   "content", userMsg)
            ))
            .temperature(0.1)          // low temperature for deterministic structured output
            .maxTokens(1024)
            .responseFormat(Map.of("type", "json_object"))
            .build();
    }

    private ChatRequest buildVisionRequest(String model, String systemMsg,
                                            String textMsg, String imageUrl) {
        List<Map<String, Object>> userContent = List.of(
            Map.of("type", "text", "text", textMsg),
            Map.of("type", "image_url", "image_url", Map.of("url", imageUrl, "detail", "low"))
        );
        return ChatRequest.builder()
            .model(model)
            .messages(List.of(
                Map.of("role", "system", "content", systemMsg),
                Map.of("role", "user",   "content", userContent)
            ))
            .temperature(0.1)
            .maxTokens(512)
            .responseFormat(Map.of("type", "json_object"))
            .build();
    }

    // ── Inner request/response classes ───────────────────────────────────────

    @Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    static class ChatRequest {
        private String  model;
        private List<?> messages;
        @lombok.Builder.Default
        private double  temperature = 0.1;
        @JsonProperty("max_tokens")
        @lombok.Builder.Default
        private int     maxTokens   = 1024;
        @JsonProperty("response_format")
        private Map<String, String> responseFormat;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    static class ChatResponse {
        private List<Choice> choices;

        @Data
        @JsonIgnoreProperties(ignoreUnknown = true)
        static class Choice {
            private Message message;
        }

        @Data
        @JsonIgnoreProperties(ignoreUnknown = true)
        static class Message {
            private String content;
        }
    }
}
