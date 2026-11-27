package com.civicconnect.modules.admin.repository;

import com.civicconnect.common.enums.IssuePriority;
import com.civicconnect.modules.admin.entity.SlaPolicy;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface SlaPolicyRepository extends JpaRepository<SlaPolicy, UUID> {

    List<SlaPolicy> findByMunicipalityIdAndActiveTrue(UUID municipalityId);

    Optional<SlaPolicy> findByMunicipalityIdAndCategoryIdAndPriorityAndActiveTrue(
            UUID municipalityId, UUID categoryId, IssuePriority priority);

    boolean existsByMunicipalityIdAndCategoryIdAndPriority(
            UUID municipalityId, UUID categoryId, IssuePriority priority);
}
