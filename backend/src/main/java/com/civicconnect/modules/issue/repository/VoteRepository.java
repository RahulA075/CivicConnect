package com.civicconnect.modules.issue.repository;

import com.civicconnect.modules.issue.entity.Vote;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface VoteRepository extends JpaRepository<Vote, UUID> {
    Optional<Vote> findByIssueIdAndUserId(UUID issueId, UUID userId);
    boolean existsByIssueIdAndUserId(UUID issueId, UUID userId);
}
