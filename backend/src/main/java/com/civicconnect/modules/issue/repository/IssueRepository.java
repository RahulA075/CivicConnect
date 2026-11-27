package com.civicconnect.modules.issue.repository;

import com.civicconnect.common.enums.IssueStatus;
import com.civicconnect.modules.issue.entity.Issue;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface IssueRepository extends JpaRepository<Issue, UUID>,
        JpaSpecificationExecutor<Issue> {

    Optional<Issue> findByTrackingIdAndDeletedAtIsNull(String trackingId);

    @Query("SELECT i FROM Issue i WHERE i.id = :id AND i.deletedAt IS NULL")
    Optional<Issue> findActiveById(@Param("id") UUID id);

    @Query("""
        SELECT i FROM Issue i
        WHERE i.reportedBy.id = :userId
          AND i.deletedAt IS NULL
          AND i.merged = false
        ORDER BY i.createdAt DESC
        """)
    Page<Issue> findByReportedBy(@Param("userId") UUID userId, Pageable pageable);

    @Query("""
        SELECT i FROM Issue i
        WHERE i.assignedTo.id = :workerId
          AND i.deletedAt IS NULL
          AND i.status NOT IN ('CLOSED','VERIFIED','REJECTED')
        ORDER BY i.slaDeadline ASC NULLS LAST
        """)
    List<Issue> findActiveTasksForWorker(@Param("workerId") UUID workerId);

    @Query("""
        SELECT i FROM Issue i
        WHERE i.department.id = :deptId
          AND i.deletedAt IS NULL
          AND i.merged = false
          AND (:status IS NULL OR i.status = :status)
        ORDER BY i.createdAt DESC
        """)
    Page<Issue> findByDepartment(@Param("deptId") UUID deptId,
                                  @Param("status") IssueStatus status,
                                  Pageable pageable);

    @Modifying
    @Query("UPDATE Issue i SET i.overdue = true, i.updatedAt = :now WHERE i.overdue = false AND i.slaDeadline < :now AND i.status NOT IN ('CLOSED','VERIFIED','REJECTED') AND i.deletedAt IS NULL")
    int markOverdueIssues(@Param("now") Instant now);

    @Query("SELECT COUNT(i) FROM Issue i WHERE i.municipality.id = :municipalityId AND i.status NOT IN ('CLOSED','VERIFIED','REJECTED') AND i.deletedAt IS NULL")
    long countOpenByMunicipality(@Param("municipalityId") UUID municipalityId);
}
