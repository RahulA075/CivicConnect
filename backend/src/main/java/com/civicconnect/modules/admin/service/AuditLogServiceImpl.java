package com.civicconnect.modules.admin.service;

import com.civicconnect.modules.admin.dto.AuditLogResponse;
import com.civicconnect.modules.admin.entity.AuditLog;
import com.civicconnect.modules.admin.repository.AuditLogRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuditLogServiceImpl implements AuditLogService {

    private final AuditLogRepository auditLogRepository;

    @Override
    @Transactional(readOnly = true)
    public Page<AuditLogResponse> search(UUID municipalityId, String action,
                                         Instant from, Instant to, Pageable pageable) {
        return auditLogRepository.search(municipalityId, action, from, to, pageable)
                .map(this::toDto);
    }

    @Override
    @Async
    @Transactional
    public void log(UUID municipalityId, UUID performedById, String performedByName,
                    String action, String entityType, String entityId,
                    String detail, String ipAddress) {
        AuditLog entry = AuditLog.builder()
                .municipalityId(municipalityId)
                .performedById(performedById)
                .performedByName(performedByName)
                .action(action)
                .entityType(entityType)
                .entityId(entityId)
                .detail(detail)
                .ipAddress(ipAddress)
                .build();
        auditLogRepository.save(entry);
    }

    // ── Mapper ────────────────────────────────────────────────────────────────

    private AuditLogResponse toDto(AuditLog a) {
        return AuditLogResponse.builder()
                .id(a.getId())
                .performedById(a.getPerformedById())
                .performedByName(a.getPerformedByName())
                .action(a.getAction())
                .entityType(a.getEntityType())
                .entityId(a.getEntityId())
                .detail(a.getDetail())
                .ipAddress(a.getIpAddress())
                .createdAt(a.getCreatedAt())
                .build();
    }
}
