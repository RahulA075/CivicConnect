package com.civicconnect.modules.admin.service;

import com.civicconnect.modules.admin.dto.AuditLogResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.time.Instant;
import java.util.UUID;

public interface AuditLogService {
    Page<AuditLogResponse> search(UUID municipalityId, String action,
                                  Instant from, Instant to, Pageable pageable);

    void log(UUID municipalityId, UUID performedById, String performedByName,
             String action, String entityType, String entityId,
             String detail, String ipAddress);
}
