package com.civicconnect.modules.issue.controller;

import com.civicconnect.common.enums.IssuePriority;
import com.civicconnect.common.enums.IssueStatus;
import com.civicconnect.common.exception.GlobalExceptionHandler;
import com.civicconnect.common.security.JwtAuthenticationFilter;
import com.civicconnect.common.security.JwtTokenProvider;
import com.civicconnect.common.security.UserDetailsServiceImpl;
import com.civicconnect.config.TestSecurityConfig;
import com.civicconnect.modules.issue.dto.*;
import com.civicconnect.modules.issue.service.IssueService;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.io.IOException;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Controller slice tests for {@link IssueController}.
 * {@link TestSecurityConfig} replaces real security with permit-all + no-op props.
 */
@WebMvcTest(IssueController.class)
@Import({TestSecurityConfig.class, GlobalExceptionHandler.class})
@ActiveProfiles("test")
@DisplayName("IssueController API")
class IssueControllerTest {

    @Autowired MockMvc      mockMvc;
    @Autowired ObjectMapper objectMapper;

    @MockBean IssueService            issueService;
    @MockBean JwtAuthenticationFilter jwtAuthenticationFilter;
    @MockBean JwtTokenProvider        jwtTokenProvider;
    @MockBean UserDetailsServiceImpl  userDetailsService;

    @BeforeEach
    void configureFilterPassThrough() throws ServletException, IOException {
        doAnswer(inv -> {
            FilterChain chain = inv.getArgument(2);
            chain.doFilter(inv.getArgument(0), inv.getArgument(1));
            return null;
        }).when(jwtAuthenticationFilter)
          .doFilter(any(HttpServletRequest.class),
                    any(HttpServletResponse.class),
                    any(FilterChain.class));
    }

    private static final String BASE     = "/api/v1/issues";
    private static final UUID   ISSUE_ID = UUID.randomUUID();

    // ── POST / (submit) ────────────────────────────────────────────────────

    @Test
    @DisplayName("POST /issues → 201 with valid payload")
    void submit_returns201() throws Exception {
        when(issueService.submit(any(IssueSubmitRequest.class), any(UUID.class)))
                .thenReturn(buildIssueResponse());

        mockMvc.perform(post(BASE)
                        .with(user("00000000-0000-0000-0000-000000000001").roles("CITIZEN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(buildSubmitRequest())))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.trackingId").value("CC-TEST-0001"));
    }

    @Test
    @DisplayName("POST /issues → 400 when title too short")
    void submit_returns400WhenTitleTooShort() throws Exception {
        IssueSubmitRequest req = buildSubmitRequest();
        req.setTitle("Hi"); // < 5 chars

        mockMvc.perform(post(BASE)
                        .with(user("00000000-0000-0000-0000-000000000001").roles("CITIZEN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("POST /issues → 400 when latitude missing")
    void submit_returns400WhenLatitudeMissing() throws Exception {
        IssueSubmitRequest req = buildSubmitRequest();
        req.setLatitude(null);

        mockMvc.perform(post(BASE)
                        .with(user("00000000-0000-0000-0000-000000000001").roles("CITIZEN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest());
    }

    // ── GET /{id} ──────────────────────────────────────────────────────────

    @Test
    @DisplayName("GET /issues/{id} → 200")
    void getById_returns200() throws Exception {
        when(issueService.getById(eq(ISSUE_ID), any()))
                .thenReturn(buildIssueResponse());

        mockMvc.perform(get(BASE + "/" + ISSUE_ID)
                        .with(user("00000000-0000-0000-0000-000000000001").roles("CITIZEN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(ISSUE_ID.toString()));
    }

    // ── GET /track/{trackingId} ────────────────────────────────────────────

    @Test
    @DisplayName("GET /issues/track/{trackingId} → 200")
    void getByTrackingId_returns200() throws Exception {
        when(issueService.getByTrackingId("CC-TEST-0001"))
                .thenReturn(buildIssueResponse());

        mockMvc.perform(get(BASE + "/track/CC-TEST-0001"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.trackingId").value("CC-TEST-0001"));
    }

    // ── GET /my ────────────────────────────────────────────────────────────

    @Test
    @DisplayName("GET /issues/my → 200 for authenticated citizen")
    void getMyIssues_returns200() throws Exception {
        Page<IssueResponse> page = new PageImpl<>(List.of(buildIssueResponse()));
        when(issueService.getMyIssues(any(UUID.class), any())).thenReturn(page);

        mockMvc.perform(get(BASE + "/my")
                        .with(user("00000000-0000-0000-0000-000000000001").roles("CITIZEN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    // ── GET /nearby ────────────────────────────────────────────────────────

    @Test
    @DisplayName("GET /issues/nearby → 200")
    void getNearby_returns200() throws Exception {
        when(issueService.getNearby(anyDouble(), anyDouble(), anyInt(), any()))
                .thenReturn(List.of());

        mockMvc.perform(get(BASE + "/nearby")
                        .param("lat", "12.9716")
                        .param("lng", "77.5946")
                        .param("radius", "500")
                        .param("municipalityId", UUID.randomUUID().toString()))
                .andExpect(status().isOk());
    }

    // ── PATCH /{id}/status ─────────────────────────────────────────────────

    @Test
    @DisplayName("PATCH /issues/{id}/status → 200 for officer")
    void updateStatus_returns200() throws Exception {
        IssueStatusUpdateRequest req = new IssueStatusUpdateRequest();
        req.setStatus(IssueStatus.IN_PROGRESS);

        when(issueService.updateStatus(eq(ISSUE_ID), any(), any()))
                .thenReturn(buildIssueResponse());

        mockMvc.perform(patch(BASE + "/" + ISSUE_ID + "/status")
                        .with(user("00000000-0000-0000-0000-000000000001").roles("FIELD_WORKER"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk());
    }

    // ── POST /{id}/upvote ──────────────────────────────────────────────────

    @Test
    @DisplayName("POST /issues/{id}/upvote → 200")
    void upvote_returns200() throws Exception {
        when(issueService.upvote(eq(ISSUE_ID), any())).thenReturn(buildIssueResponse());

        mockMvc.perform(post(BASE + "/" + ISSUE_ID + "/upvote")
                        .with(user("00000000-0000-0000-0000-000000000001").roles("CITIZEN")))
                .andExpect(status().isOk());
    }

    // ── GET /{id}/history ──────────────────────────────────────────────────

    @Test
    @DisplayName("GET /issues/{id}/history → 200")
    void getHistory_returns200() throws Exception {
        when(issueService.getStatusHistory(ISSUE_ID)).thenReturn(List.of());

        mockMvc.perform(get(BASE + "/" + ISSUE_ID + "/history"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isArray());
    }

    // ── Helpers ────────────────────────────────────────────────────────────

    private IssueSubmitRequest buildSubmitRequest() {
        IssueSubmitRequest req = new IssueSubmitRequest();
        req.setCategoryId(UUID.randomUUID());
        req.setTitle("Pothole near bus stop");
        req.setDescription("Large pothole causing road accidents near bus stop 42");
        req.setLatitude(12.9716);
        req.setLongitude(77.5946);
        req.setAddressText("MG Road, Bengaluru");
        req.setPriority(IssuePriority.HIGH);
        return req;
    }

    private IssueResponse buildIssueResponse() {
        return IssueResponse.builder()
                .id(ISSUE_ID)
                .trackingId("CC-TEST-0001")
                .title("Pothole near bus stop")
                .description("Large pothole causing road accidents")
                .status(IssueStatus.SUBMITTED)
                .priority(IssuePriority.HIGH)
                .latitude(12.9716)
                .longitude(77.5946)
                .addressText("MG Road, Bengaluru")
                .categoryName("Roads")
                .categoryColor("#FF5733")
                .categoryIcon("road")
                .upvoteCount(0)
                .commentCount(0)
                .createdAt(Instant.now())
                .build();
    }
}
