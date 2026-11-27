package com.civicconnect.modules.admin.service;

import com.civicconnect.common.exception.ResourceNotFoundException;
import com.civicconnect.modules.admin.dto.EmergencyAlertRequest;
import com.civicconnect.modules.admin.dto.EmergencyAlertResponse;
import com.civicconnect.modules.admin.entity.Department;
import com.civicconnect.modules.admin.entity.EmergencyAlert;
import com.civicconnect.modules.admin.repository.DepartmentRepository;
import com.civicconnect.modules.admin.repository.EmergencyAlertRepository;
import com.civicconnect.modules.admin.repository.MunicipalityRepository;
import com.civicconnect.modules.iam.repository.UserRepository;
import com.civicconnect.modules.notification.service.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class EmergencyAlertServiceImpl implements EmergencyAlertService {

    private final EmergencyAlertRepository alertRepository;
    private final MunicipalityRepository   municipalityRepository;
    private final DepartmentRepository     departmentRepository;
    private final UserRepository           userRepository;
    private final NotificationService      notificationService;

    @Override
    @Transactional(readOnly = true)
    public Page<EmergencyAlertResponse> getByMunicipality(
            UUID municipalityId, boolean activeOnly, Pageable pageable) {
        var page = activeOnly
                ? alertRepository.findByMunicipalityIdAndActiveTrueOrderByCreatedAtDesc(municipalityId, pageable)
                : alertRepository.findByMunicipalityIdOrderByCreatedAtDesc(municipalityId, pageable);
        return page.map(this::toDto);
    }

    @Override
    @Transactional
    public EmergencyAlertResponse create(UUID municipalityId, EmergencyAlertRequest req, UUID createdBy) {
        var municipality = municipalityRepository.findById(municipalityId)
                .orElseThrow(() -> new ResourceNotFoundException("Municipality not found: " + municipalityId));

        Department department = null;
        if (req.getTargetDepartmentId() != null) {
            department = departmentRepository.findById(req.getTargetDepartmentId())
                    .orElseThrow(() -> new ResourceNotFoundException("Department not found: " + req.getTargetDepartmentId()));
        }

        EmergencyAlert alert = EmergencyAlert.builder()
                .municipality(municipality)
                .targetDepartment(department)
                .title(req.getTitle())
                .message(req.getMessage())
                .severity(req.getSeverity())
                .createdBy(createdBy)
                .expiresAt(req.getExpiresAt())
                .build();

        EmergencyAlert saved = alertRepository.save(alert);
        log.info("Emergency alert '{}' created by {} for municipality {}", req.getTitle(), createdBy, municipalityId);

        // Fire FCM push to municipality emergency topic
        notificationService.sendEmergencyAlert(
                municipalityId,
                req.getTitle(),
                req.getMessage(),
                req.getSeverity(),
                saved.getId()
        );

        return toDto(saved);
    }

    @Override
    @Transactional
    public void deactivate(UUID id, UUID performedBy) {
        EmergencyAlert alert = alertRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Emergency alert not found: " + id));
        alert.setActive(false);
        alertRepository.save(alert);
        log.info("Emergency alert {} deactivated by {}", id, performedBy);
    }

    // ── Mapper ────────────────────────────────────────────────────────────────

    private EmergencyAlertResponse toDto(EmergencyAlert a) {
        // Resolve creator name lazily — avoid N+1 by accepting null if user not found
        String createdByName = null;
        if (a.getCreatedBy() != null) {
            createdByName = userRepository.findActiveById(a.getCreatedBy())
                    .map(u -> u.getFullName()).orElse(null);
        }

        return EmergencyAlertResponse.builder()
                .id(a.getId())
                .municipalityId(a.getMunicipality().getId())
                .targetDepartmentId(a.getTargetDepartment() != null ? a.getTargetDepartment().getId() : null)
                .departmentName(a.getTargetDepartment() != null ? a.getTargetDepartment().getName() : null)
                .title(a.getTitle())
                .message(a.getMessage())
                .severity(a.getSeverity())
                .active(a.isActive())
                .createdById(a.getCreatedBy())
                .createdByName(createdByName)
                .createdAt(a.getCreatedAt())
                .expiresAt(a.getExpiresAt())
                .build();
    }
}
