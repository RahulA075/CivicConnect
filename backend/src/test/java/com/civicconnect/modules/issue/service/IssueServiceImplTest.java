package com.civicconnect.modules.issue.service;

import com.civicconnect.common.enums.IssuePriority;
import com.civicconnect.common.enums.IssueStatus;
import com.civicconnect.common.exception.BusinessRuleException;
import com.civicconnect.common.exception.ResourceNotFoundException;
import com.civicconnect.common.util.TrackingIdGenerator;
import com.civicconnect.modules.admin.entity.Department;
import com.civicconnect.modules.admin.entity.Municipality;
import com.civicconnect.modules.geospatial.repository.WardRepository;
import com.civicconnect.modules.iam.entity.Role;
import com.civicconnect.modules.iam.entity.User;
import com.civicconnect.modules.iam.repository.UserRepository;
import com.civicconnect.modules.issue.dto.*;
import com.civicconnect.modules.issue.entity.*;
import com.civicconnect.modules.issue.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.locationtech.jts.geom.*;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for {@link IssueServiceImpl}.
 * All repos and external dependencies are mocked.
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("IssueServiceImpl")
class IssueServiceImplTest {

    @Mock private IssueRepository                issueRepository;
    @Mock private IssueCategoryRepository        categoryRepository;
    @Mock private VoteRepository                 voteRepository;
    @Mock private IssueStatusHistoryRepository   historyRepository;
    @Mock private UserRepository                 userRepository;
    @Mock private WardRepository                 wardRepository;
    @Mock private TrackingIdGenerator            trackingIdGenerator;
    @Mock private ApplicationEventPublisher      eventPublisher;

    private IssueServiceImpl service;

    private static final UUID USER_ID     = UUID.randomUUID();
    private static final UUID ISSUE_ID    = UUID.randomUUID();
    private static final UUID CATEGORY_ID = UUID.randomUUID();
    private static final UUID MUNI_ID     = UUID.randomUUID();

    private static final GeometryFactory GEO =
            new GeometryFactory(new PrecisionModel(), 4326);

    @BeforeEach
    void setUp() {
        service = new IssueServiceImpl(
                issueRepository, categoryRepository, voteRepository,
                historyRepository, userRepository, wardRepository,
                trackingIdGenerator, eventPublisher);
    }

    // ── submit ─────────────────────────────────────────────────────────────

    @Test
    @DisplayName("submit() saves issue and publishes event")
    void submit_savesAndPublishesEvent() {
        IssueSubmitRequest req = buildSubmitRequest();
        User reporter = buildUser();
        IssueCategory category = buildCategory();
        Issue savedIssue = buildIssue(category, reporter);

        when(userRepository.findActiveById(USER_ID)).thenReturn(Optional.of(reporter));
        when(categoryRepository.findById(CATEGORY_ID)).thenReturn(Optional.of(category));
        when(wardRepository.findByContainingPoint(any(), anyDouble(), anyDouble()))
                .thenReturn(Optional.empty());
        when(trackingIdGenerator.generate()).thenReturn("CC-20250001");
        when(issueRepository.save(any(Issue.class))).thenReturn(savedIssue);
        when(historyRepository.save(any())).thenAnswer(i -> i.getArgument(0));
        when(voteRepository.existsByIssueIdAndUserId(any(), any())).thenReturn(false);

        IssueResponse resp = service.submit(req, USER_ID);

        assertThat(resp).isNotNull();
        assertThat(resp.getTrackingId()).isEqualTo("CC-20250001");
        verify(eventPublisher).publishEvent(any());
        verify(issueRepository).save(any(Issue.class));
    }

    @Test
    @DisplayName("submit() throws ResourceNotFoundException for inactive category")
    void submit_throwsForInactiveCategory() {
        IssueSubmitRequest req = buildSubmitRequest();
        User reporter = buildUser();
        IssueCategory inactiveCategory = buildCategory();
        inactiveCategory.setActive(false);

        when(userRepository.findActiveById(USER_ID)).thenReturn(Optional.of(reporter));
        when(categoryRepository.findById(CATEGORY_ID)).thenReturn(Optional.of(inactiveCategory));

        assertThatThrownBy(() -> service.submit(req, USER_ID))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    // ── getById ────────────────────────────────────────────────────────────

    @Test
    @DisplayName("getById() returns issue response")
    void getById_returnsResponse() {
        User reporter = buildUser();
        IssueCategory category = buildCategory();
        Issue issue = buildIssue(category, reporter);

        when(issueRepository.findActiveById(ISSUE_ID)).thenReturn(Optional.of(issue));
        when(voteRepository.existsByIssueIdAndUserId(any(), any())).thenReturn(false);

        IssueResponse resp = service.getById(ISSUE_ID, USER_ID);
        assertThat(resp.getId()).isEqualTo(ISSUE_ID);
        assertThat(resp.getTrackingId()).isEqualTo("CC-20250001");
    }

    @Test
    @DisplayName("getById() throws ResourceNotFoundException for unknown issue")
    void getById_throwsForUnknownIssue() {
        when(issueRepository.findActiveById(ISSUE_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.getById(ISSUE_ID, USER_ID))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    // ── upvote ─────────────────────────────────────────────────────────────

    @Test
    @DisplayName("upvote() increments count and saves vote")
    void upvote_incrementsCount() {
        User reporter = buildUser();
        IssueCategory category = buildCategory();
        Issue issue = buildIssue(category, reporter);
        User voter = buildUser();

        when(issueRepository.findActiveById(ISSUE_ID)).thenReturn(Optional.of(issue));
        when(userRepository.findActiveById(USER_ID)).thenReturn(Optional.of(voter));
        when(voteRepository.existsByIssueIdAndUserId(ISSUE_ID, USER_ID)).thenReturn(false);
        when(voteRepository.save(any())).thenAnswer(i -> i.getArgument(0));
        when(issueRepository.save(any(Issue.class))).thenReturn(issue);

        IssueResponse resp = service.upvote(ISSUE_ID, USER_ID);
        assertThat(issue.getUpvoteCount()).isEqualTo(1);
    }

    @Test
    @DisplayName("upvote() throws BusinessRuleException if already voted")
    void upvote_throwsIfAlreadyVoted() {
        User reporter = buildUser();
        IssueCategory category = buildCategory();
        Issue issue = buildIssue(category, reporter);
        User voter = buildUser();

        when(issueRepository.findActiveById(ISSUE_ID)).thenReturn(Optional.of(issue));
        when(userRepository.findActiveById(USER_ID)).thenReturn(Optional.of(voter));
        when(voteRepository.existsByIssueIdAndUserId(ISSUE_ID, USER_ID)).thenReturn(true);

        assertThatThrownBy(() -> service.upvote(ISSUE_ID, USER_ID))
                .isInstanceOf(BusinessRuleException.class)
                .satisfies(ex -> assertThat(((BusinessRuleException) ex).getErrorCode())
                        .isEqualTo("ALREADY_VOTED"));
    }

    // ── updateStatus ───────────────────────────────────────────────────────

    @Test
    @DisplayName("updateStatus() transitions issue status correctly")
    void updateStatus_changesStatus() {
        User reporter = buildUser();
        IssueCategory category = buildCategory();
        Issue issue = buildIssue(category, reporter);
        User officer = buildUser();

        IssueStatusUpdateRequest req = new IssueStatusUpdateRequest();
        req.setStatus(IssueStatus.IN_PROGRESS);
        req.setNote("Working on it");

        when(issueRepository.findActiveById(ISSUE_ID)).thenReturn(Optional.of(issue));
        when(userRepository.findActiveById(USER_ID)).thenReturn(Optional.of(officer));
        when(issueRepository.save(any(Issue.class))).thenReturn(issue);
        when(historyRepository.save(any())).thenAnswer(i -> i.getArgument(0));
        when(voteRepository.existsByIssueIdAndUserId(any(), any())).thenReturn(false);

        IssueResponse resp = service.updateStatus(ISSUE_ID, req, USER_ID);

        assertThat(issue.getStatus()).isEqualTo(IssueStatus.IN_PROGRESS);
        verify(eventPublisher).publishEvent(any());
    }

    // ── merge ──────────────────────────────────────────────────────────────

    @Test
    @DisplayName("merge() marks duplicate as merged and sets status CLOSED")
    void merge_marksIssueAsMerged() {
        User reporter = buildUser();
        IssueCategory category = buildCategory();
        Issue primary   = buildIssue(category, reporter);
        UUID duplicateId = UUID.randomUUID();
        Issue duplicate = buildIssue(category, reporter);
        duplicate.setId(duplicateId);

        when(issueRepository.findActiveById(ISSUE_ID)).thenReturn(Optional.of(primary));
        when(issueRepository.findActiveById(duplicateId)).thenReturn(Optional.of(duplicate));
        when(issueRepository.save(any(Issue.class))).thenReturn(duplicate);

        service.merge(ISSUE_ID, duplicateId, USER_ID);

        assertThat(duplicate.isMerged()).isTrue();
        assertThat(duplicate.getStatus()).isEqualTo(IssueStatus.CLOSED);
    }

    // ── haversine distance ─────────────────────────────────────────────────

    @Test
    @DisplayName("getNearby() returns only issues within radius")
    void getNearby_filtersOutOfRadiusIssues() {
        // With no issues in repo, result should be empty
        when(issueRepository.findAll(any(org.springframework.data.jpa.domain.Specification.class)))
                .thenReturn(java.util.List.of());

        var results = service.getNearby(12.9716, 77.5946, 500, MUNI_ID);

        assertThat(results).isEmpty();
    }

    // ── verify ────────────────────────────────────────────────────────────

    @Test
    @DisplayName("verify() throws BusinessRuleException when issue is not RESOLVED")
    void verify_throwsWhenNotResolved() {
        User reporter = buildUser();
        IssueCategory category = buildCategory();
        Issue issue = buildIssue(category, reporter);
        issue.setStatus(IssueStatus.IN_PROGRESS); // Not RESOLVED

        IssueVerifyRequest req = new IssueVerifyRequest();
        req.setResolved(true);

        when(issueRepository.findActiveById(ISSUE_ID)).thenReturn(Optional.of(issue));

        assertThatThrownBy(() -> service.verify(ISSUE_ID, req, USER_ID))
                .isInstanceOf(BusinessRuleException.class)
                .satisfies(ex -> assertThat(((BusinessRuleException) ex).getErrorCode())
                        .isEqualTo("INVALID_STATE"));
    }

    // ── Helpers ────────────────────────────────────────────────────────────

    private IssueSubmitRequest buildSubmitRequest() {
        IssueSubmitRequest req = new IssueSubmitRequest();
        req.setCategoryId(CATEGORY_ID);
        req.setTitle("Pothole on main road");
        req.setDescription("Large pothole causing accidents near bus stop");
        req.setLatitude(12.9716);
        req.setLongitude(77.5946);
        req.setAddressText("MG Road, near bus stop");
        req.setPriority(IssuePriority.HIGH);
        return req;
    }

    private User buildUser() {
        com.civicconnect.common.enums.UserRole roleEnum = com.civicconnect.common.enums.UserRole.CITIZEN;
        Role role = new Role();
        role.setName(roleEnum);
        return User.builder()
                .id(USER_ID)
                .email("reporter@example.com")
                .fullName("Reporter User")
                .role(role)
                .active(true)
                .loginCount(0)
                .build();
    }

    private Municipality buildMunicipality() {
        return Municipality.builder()
                .id(MUNI_ID)
                .name("Test City")
                .code("TC001")
                .state("Test State")
                .country("India")
                .timezone("Asia/Kolkata")
                .build();
    }

    private IssueCategory buildCategory() {
        Municipality muni = buildMunicipality();
        Department dept = Department.builder()
                .id(UUID.randomUUID())
                .name("Roads Dept")
                .municipality(muni)
                .build();
        return IssueCategory.builder()
                .id(CATEGORY_ID)
                .name("Pothole")
                .iconName("pothole")
                .colorHex("#FF5733")
                .municipality(muni)
                .department(dept)
                .active(true)
                .build();
    }

    private Issue buildIssue(IssueCategory category, User reporter) {
        Point pt = GEO.createPoint(new Coordinate(77.5946, 12.9716));
        pt.setSRID(4326);
        Issue issue = Issue.builder()
                .id(ISSUE_ID)
                .trackingId("CC-20250001")
                .title("Pothole on main road")
                .description("Large pothole causing accidents")
                .location(pt)
                .status(IssueStatus.SUBMITTED)
                .priority(IssuePriority.HIGH)
                .category(category)
                .municipality(category.getMunicipality())
                .department(category.getDepartment())
                .reportedBy(reporter)
                .upvoteCount(0)
                .commentCount(0)
                .merged(false)
                .anonymous(false)
                .overdue(false)
                .build();
        issue.setId(ISSUE_ID);
        return issue;
    }
}
