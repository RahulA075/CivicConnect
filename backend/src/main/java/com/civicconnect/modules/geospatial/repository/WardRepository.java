package com.civicconnect.modules.geospatial.repository;

import com.civicconnect.modules.geospatial.entity.Ward;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface WardRepository extends JpaRepository<Ward, UUID> {

    List<Ward> findByMunicipalityIdAndActiveTrue(UUID municipalityId);

    @Query(value = """
        SELECT * FROM wards
        WHERE municipality_id = :municipalityId
          AND is_active = true
          AND ST_Contains(boundary, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326))
        LIMIT 1
        """, nativeQuery = true)
    Optional<Ward> findByContainingPoint(
        @Param("municipalityId") UUID municipalityId,
        @Param("lat") double lat,
        @Param("lng") double lng);
}
