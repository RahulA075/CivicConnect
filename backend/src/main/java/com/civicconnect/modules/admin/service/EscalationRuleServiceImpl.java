package com.civicconnect.modules.admin.service;

import com.civicconnect.common.exception.ResourceNotFoundException;
import com.civicconnect.modules.admin.dto.EscalationRuleRequest;
import com.civicconnect.modules.admin.dto.EscalationRuleResponse;
import com.civicconnect.modules.admin.entity.Department;
import com.civicconnect.modules.admin.entity.EscalationRule;
import com.civicconnect.modules.admin.repository.DepartmentRepository;
import com.civicconnect.modules.admin.repository.EscalationRuleRepository;
import com.civicconnect.modules.admin.repository.MunicipalityRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class EscalationRuleServiceImpl implements EscalationRuleService {

    private final EscalationRuleRepository escalationRuleRepository;
    private final MunicipalityRepository   municipalityRepository;
    private final DepartmentRepository     departmentRepository;

    @Override
    @Transactional(readOnly = true)
    public List<EscalationRuleResponse> getByMunicipality(UUID municipalityId) {
        return escalationRuleRepository.findByMunicipalityIdAndActiveTrue(municipalityId)
                .stream().map(this::toDto).toList();
    }

    @Override
    @Transactional
    public EscalationRuleResponse create(UUID municipalityId, EscalationRuleRequest req, UUID createdBy) {
        var municipality = municipalityRepository.findById(municipalityId)
                .orElseThrow(() -> new ResourceNotFoundException("Municipality not found: " + municipalityId));

        Department department = null;
        if (req.getDepartmentId() != null) {
            department = departmentRepository.findById(req.getDepartmentId())
                    .orElseThrow(() -> new ResourceNotFoundException("Department not found: " + req.getDepartmentId()));
        }

        EscalationRule rule = EscalationRule.builder()
                .municipality(municipality)
                .department(department)
                .triggerAfterHours(req.getTriggerAfterHours())
                .escalateToRole(req.getEscalateToRole())
                .notificationMessage(req.getNotificationMessage())
                .createdBy(createdBy)
                .build();

        return toDto(escalationRuleRepository.save(rule));
    }

    @Override
    @Transactional
    public EscalationRuleResponse update(UUID id, EscalationRuleRequest req, UUID updatedBy) {
        EscalationRule rule = escalationRuleRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Escalation rule not found: " + id));

        Department department = null;
        if (req.getDepartmentId() != null) {
            department = departmentRepository.findById(req.getDepartmentId())
                    .orElseThrow(() -> new ResourceNotFoundException("Department not found: " + req.getDepartmentId()));
        }

        rule.setDepartment(department);
        rule.setTriggerAfterHours(req.getTriggerAfterHours());
        rule.setEscalateToRole(req.getEscalateToRole());
        rule.setNotificationMessage(req.getNotificationMessage());

        return toDto(escalationRuleRepository.save(rule));
    }

    @Override
    @Transactional
    public void deactivate(UUID id, UUID performedBy) {
        EscalationRule rule = escalationRuleRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Escalation rule not found: " + id));
        rule.setActive(false);
        escalationRuleRepository.save(rule);
        log.info("Escalation rule {} deactivated by {}", id, performedBy);
    }

    // ── Mapper ────────────────────────────────────────────────────────────────

    private EscalationRuleResponse toDto(EscalationRule r) {
        return EscalationRuleResponse.builder()
                .id(r.getId())
                .municipalityId(r.getMunicipality().getId())
                .departmentId(r.getDepartment() != null ? r.getDepartment().getId() : null)
                .departmentName(r.getDepartment() != null ? r.getDepartment().getName() : null)
                .triggerAfterHours(r.getTriggerAfterHours())
                .escalateToRole(r.getEscalateToRole())
                .notificationMessage(r.getNotificationMessage())
                .active(r.isActive())
                .build();
    }
}
