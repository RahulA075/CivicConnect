package com.civicconnect.modules.issue.repository;

import com.civicconnect.modules.issue.entity.IssueImage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface IssueImageRepository extends JpaRepository<IssueImage, UUID> {

    @Query("""
        SELECT i FROM IssueImage i
        WHERE i.issue.id = :issueId
          AND i.active = true
          AND i.deletedAt IS NULL
        ORDER BY i.sortOrder ASC
        """)
    List<IssueImage> findActiveByIssueId(@Param("issueId") UUID issueId);

    @Query("""
        SELECT COUNT(i) FROM IssueImage i
        WHERE i.issue.id = :issueId
          AND i.active = true
          AND i.deletedAt IS NULL
        """)
    long countActiveByIssueId(@Param("issueId") UUID issueId);
}
