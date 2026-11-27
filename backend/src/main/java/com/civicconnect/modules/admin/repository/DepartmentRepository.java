package com.civicconnect.modules.admin.repository;

import com.civicconnect.modules.admin.entity.Department;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface DepartmentRepository extends JpaRepository<Department, UUID> {
    List<Department> findByMunicipalityIdAndActiveTrue(UUID municipalityId);
    boolean existsByMunicipalityIdAndNameIgnoreCase(UUID municipalityId, String name);
}
