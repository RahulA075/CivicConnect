package com.civicconnect.modules.admin.service;

import com.civicconnect.common.exception.ConflictException;
import com.civicconnect.common.exception.ResourceNotFoundException;
import com.civicconnect.modules.admin.dto.SlaPolicyRequest;
import com.civicconnect.modules.admin.dto.SlaPolicyResponse;
import com.civicconnect.modules.admin.entity.SlaPolicy;
import com.civicconnect.modules.admin.repository.MunicipalityRepository;
import com.civicconnect.modules.admin.repository.SlaPolicyRepository;
import com.civicconnect.modules.issue.entity.IssueCategory;
import com.civicconnect.modules.issue.repository.IssueCategoryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class SlaPolicyServiceImpl implements SlaPolicyService {

    private final SlaPolicyRepository     slaPolicyRepository;
    private final MunicipalityRepository  municipalityRepository;
    private final IssueCategoryRepository categoryRepository;

    @Override
    @Transactional(readOnly = true)
    public List<SlaPolicyResponse> getByMunicipality(UUID municipalityId) {
        return slaPolicyRepository.findByMunicipalityIdAndActiveTrue(municipalityId)
                .stream().map(this::toDto).toList();
    }

    @Override
    @Transactional
    public SlaPolicyResponse create(UUID municipalityId, SlaPolicyRequest req, UUID createdBy) {
        if (slaPolicyRepository.existsByMunicipalityIdAndCategoryIdAndPriority(
                municipalityId, req.getCategoryId(), req.getPriority())) {
            throw new ConflictException("SLA_DUPLICATE",
                "SLA policy already exists for this municipality / category / priority combination");
        }

        var municipality = municipalityRepository.findById(municipalityId)
                .orElseThrow(() -> new ResourceNotFoundException("Municipality not found: " + municipalityId));

        IssueCategory category = null;
        if (req.getCategoryId() != null) {
            category = categoryRepository.findById(req.getCategoryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Category not found: " + req.getCategoryId()));
        }

        SlaPolicy policy = SlaPolicy.builder()
                .municipality(municipality)
                .category(category)
                .priority(req.getPriority())
                .resolutionHours(req.getResolutionHours())
                .warningHours(req.getWarningHours())
                .escalationHours(req.getEscalationHours())
                .createdBy(createdBy)
                .build();

        return toDto(slaPolicyRepository.save(policy));
    }

    @Override
    @Transactional
    public SlaPolicyResponse update(UUID id, SlaPolicyRequest req, UUID updatedBy) {
        SlaPolicy policy = slaPolicyRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("SLA policy not found: " + id));

        IssueCategory category = null;
        if (req.getCategoryId() != null) {
            category = categoryRepository.findById(req.getCategoryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Category not found: " + req.getCategoryId()));
        }

        policy.setCategory(category);
        policy.setPriority(req.getPriority());
        policy.setResolutionHours(req.getResolutionHours());
        policy.setWarningHours(req.getWarningHours());
        policy.setEscalationHours(req.getEscalationHours());

        return toDto(slaPolicyRepository.save(policy));
    }

    @Override
    @Transactional
    public void deactivate(UUID id, UUID performedBy) {
        SlaPolicy policy = slaPolicyRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("SLA policy not found: " + id));
        policy.setActive(false);
        slaPolicyRepository.save(policy);
        log.info("SLA policy {} deactivated by {}", id, performedBy);
    }

    // ── Mapper ────────────────────────────────────────────────────────────────

    private SlaPolicyResponse toDto(SlaPolicy p) {
        return SlaPolicyResponse.builder()
                .id(p.getId())
                .municipalityId(p.getMunicipality().getId())
                .categoryId(p.getCategory() != null ? p.getCategory().getId() : null)
                .categoryName(p.getCategory() != null ? p.getCategory().getName() : null)
                .priority(p.getPriority())
                .resolutionHours(p.getResolutionHours())
                .warningHours(p.getWarningHours())
                .escalationHours(p.getEscalationHours())
                .active(p.isActive())
                .build();
    }
}
