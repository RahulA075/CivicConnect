package com.civicconnect.modules.operations.repository;

import com.civicconnect.modules.operations.entity.IssueAssignment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface IssueAssignmentRepository extends JpaRepository<IssueAssignment, UUID> {

    Optional<IssueAssignment> findByIssueIdAndActiveTrue(UUID issueId);

    @Modifying
    @Query("UPDATE IssueAssignment a SET a.active = false, a.revokedAt = :now WHERE a.issue.id = :issueId AND a.active = true")
    int deactivateForIssue(@Param("issueId") UUID issueId, @Param("now") Instant now);
}
