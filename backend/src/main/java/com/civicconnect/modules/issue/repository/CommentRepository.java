package com.civicconnect.modules.issue.repository;

import com.civicconnect.modules.issue.entity.Comment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface CommentRepository extends JpaRepository<Comment, UUID> {

    @Query("SELECT c FROM Comment c WHERE c.issue.id = :issueId AND c.internal = false AND c.deleted = false ORDER BY c.createdAt ASC")
    List<Comment> findPublicByIssueId(@Param("issueId") UUID issueId);

    @Query("SELECT c FROM Comment c WHERE c.issue.id = :issueId AND c.deleted = false ORDER BY c.createdAt ASC")
    List<Comment> findAllByIssueId(@Param("issueId") UUID issueId);
}
