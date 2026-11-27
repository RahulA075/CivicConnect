package com.civicconnect.modules.ai.repository;

import com.civicconnect.modules.ai.entity.AiIssueAnalysis;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface AiIssueAnalysisRepository extends JpaRepository<AiIssueAnalysis, UUID> {

    Optional<AiIssueAnalysis> findByIssueId(UUID issueId);

    @Query("SELECT a FROM AiIssueAnalysis a WHERE a.spamFlagged = true ORDER BY a.analyzedAt DESC")
    List<AiIssueAnalysis> findSpamFlagged();

    @Query("SELECT a FROM AiIssueAnalysis a WHERE a.potentialDuplicate = true ORDER BY a.analyzedAt DESC")
    List<AiIssueAnalysis> findPotentialDuplicates();

    void deleteByIssueId(UUID issueId);

    @Query("""
        SELECT a FROM AiIssueAnalysis a
        WHERE a.issueId IN :issueIds
        """)
    List<AiIssueAnalysis> findByIssueIds(@Param("issueIds") List<UUID> issueIds);
}
