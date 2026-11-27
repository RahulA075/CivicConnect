package com.civicconnect.modules.admin.repository;

import com.civicconnect.modules.admin.entity.EmergencyAlert;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface EmergencyAlertRepository extends JpaRepository<EmergencyAlert, UUID> {

    Page<EmergencyAlert> findByMunicipalityIdOrderByCreatedAtDesc(
            UUID municipalityId, Pageable pageable);

    Page<EmergencyAlert> findByMunicipalityIdAndActiveTrueOrderByCreatedAtDesc(
            UUID municipalityId, Pageable pageable);
}
