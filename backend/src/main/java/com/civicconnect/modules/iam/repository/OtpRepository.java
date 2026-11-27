package com.civicconnect.modules.iam.repository;

import com.civicconnect.modules.iam.entity.OtpVerification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface OtpRepository extends JpaRepository<OtpVerification, UUID> {

    @Query("""
        SELECT o FROM OtpVerification o
        WHERE o.identifier = :identifier
          AND o.purpose    = :purpose
          AND o.used       = false
          AND o.expiresAt  > :now
        ORDER BY o.createdAt DESC
        """)
    Optional<OtpVerification> findValidOtp(
        @Param("identifier") String identifier,
        @Param("purpose")    OtpVerification.Purpose purpose,
        @Param("now")        Instant now);

    @Modifying
    @Query("DELETE FROM OtpVerification o WHERE o.expiresAt < :cutoff")
    int deleteExpiredBefore(@Param("cutoff") Instant cutoff);
}
