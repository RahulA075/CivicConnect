package com.civicconnect.modules.admin.repository;

import com.civicconnect.modules.admin.entity.Municipality;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface MunicipalityRepository extends JpaRepository<Municipality, UUID> {
    Optional<Municipality> findByCodeIgnoreCase(String code);
    boolean existsByCodeIgnoreCase(String code);
}
