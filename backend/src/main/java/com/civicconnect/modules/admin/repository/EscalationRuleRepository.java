package com.civicconnect.modules.admin.repository;

import com.civicconnect.modules.admin.entity.EscalationRule;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface EscalationRuleRepository extends JpaRepository<EscalationRule, UUID> {

    List<EscalationRule> findByMunicipalityIdAndActiveTrue(UUID municipalityId);

    List<EscalationRule> findByMunicipalityIdAndDepartmentIdAndActiveTrue(
            UUID municipalityId, UUID departmentId);
}
