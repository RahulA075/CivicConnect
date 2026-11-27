package com.civicconnect.modules.iam.repository;

import com.civicconnect.modules.iam.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserRepository extends JpaRepository<User, UUID> {

    @Query("SELECT u FROM User u WHERE u.id = :id AND u.active = true AND u.deletedAt IS NULL")
    Optional<User> findActiveById(@Param("id") UUID id);

    @Query("SELECT u FROM User u WHERE LOWER(u.email) = LOWER(:email) AND u.deletedAt IS NULL")
    Optional<User> findByEmailIgnoreCase(@Param("email") String email);

    Optional<User> findByPhoneAndDeletedAtIsNull(String phone);

    Optional<User> findByProviderIdAndDeletedAtIsNull(String providerId);

    boolean existsByEmailIgnoreCaseAndDeletedAtIsNull(String email);

    boolean existsByPhoneAndDeletedAtIsNull(String phone);

    @Query("""
        SELECT u FROM User u
        WHERE u.municipality.id = :municipalityId
          AND u.deletedAt IS NULL
          AND (:departmentId IS NULL OR u.department.id = :departmentId)
        """)
    Page<User> findAuthorityUsers(@Param("municipalityId") UUID municipalityId,
                                   @Param("departmentId")   UUID departmentId,
                                   Pageable pageable);
}
