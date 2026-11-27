package com.civicconnect.modules.issue.repository;

import com.civicconnect.modules.issue.entity.IssueCategory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface IssueCategoryRepository extends JpaRepository<IssueCategory, UUID> {

    @Query("""
        SELECT c FROM IssueCategory c
        WHERE c.municipality.id = :municipalityId
          AND c.parent IS NULL
          AND c.active = true
        ORDER BY c.sortOrder, c.name
        """)
    List<IssueCategory> findTopLevelByMunicipality(@Param("municipalityId") UUID municipalityId);

    List<IssueCategory> findByParentIdAndActiveTrue(UUID parentId);

    /**
     * Returns all active categories (top-level and sub) for a municipality.
     * Used by the AI analysis service to give the model a complete list of
     * valid category names for the municipality.
     */
    @Query("""
        SELECT c FROM IssueCategory c
        WHERE c.municipality.id = :municipalityId
          AND c.active = true
        ORDER BY c.sortOrder, c.name
        """)
    List<IssueCategory> findActiveCategoriesForMunicipality(@Param("municipalityId") UUID municipalityId);
}
