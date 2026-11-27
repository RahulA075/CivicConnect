package com.civicconnect.modules.admin.service;

import com.civicconnect.common.exception.ConflictException;
import com.civicconnect.common.exception.ResourceNotFoundException;
import com.civicconnect.modules.admin.dto.CreateDepartmentRequest;
import com.civicconnect.modules.admin.dto.DepartmentResponse;
import com.civicconnect.modules.admin.entity.Department;
import com.civicconnect.modules.admin.repository.DepartmentRepository;
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
public class DepartmentServiceImpl implements DepartmentService {

    private final DepartmentRepository   departmentRepository;
    private final MunicipalityRepository municipalityRepository;

    @Override
    @Transactional(readOnly = true)
    public List<Department> getByMunicipality(UUID municipalityId) {
        return departmentRepository.findByMunicipalityIdAndActiveTrue(municipalityId);
    }

    @Override
    @Transactional(readOnly = true)
    public DepartmentResponse getById(UUID id) {
        return toDto(find(id));
    }

    @Override
    @Transactional
    public DepartmentResponse create(CreateDepartmentRequest req, UUID municipalityId, UUID createdBy) {
        if (departmentRepository.existsByMunicipalityIdAndNameIgnoreCase(municipalityId, req.getName())) {
            throw new ConflictException("DEPT_DUPLICATE",
                    "Department '" + req.getName() + "' already exists in this municipality");
        }
        var municipality = municipalityRepository.findById(municipalityId)
                .orElseThrow(() -> new ResourceNotFoundException("Municipality not found: " + municipalityId));

        Department dept = Department.builder()
                .municipality(municipality)
                .name(req.getName())
                .description(req.getDescription())
                .iconName(req.getIconName())
                .colorHex(req.getColorHex())
                .contactEmail(req.getContactEmail())
                .contactPhone(req.getContactPhone())
                .createdBy(createdBy)
                .build();

        return toDto(departmentRepository.save(dept));
    }

    @Override
    @Transactional
    public DepartmentResponse update(UUID id, CreateDepartmentRequest req, UUID updatedBy) {
        Department dept = find(id);
        dept.setName(req.getName());
        dept.setDescription(req.getDescription());
        dept.setIconName(req.getIconName());
        dept.setColorHex(req.getColorHex());
        dept.setContactEmail(req.getContactEmail());
        dept.setContactPhone(req.getContactPhone());
        return toDto(departmentRepository.save(dept));
    }

    @Override
    @Transactional
    public void deactivate(UUID id, UUID performedBy) {
        Department dept = find(id);
        dept.setActive(false);
        departmentRepository.save(dept);
        log.info("Department {} deactivated by {}", id, performedBy);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private Department find(UUID id) {
        return departmentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Department not found: " + id));
    }

    private DepartmentResponse toDto(Department d) {
        return DepartmentResponse.builder()
                .id(d.getId())
                .municipalityId(d.getMunicipality().getId())
                .name(d.getName())
                .description(d.getDescription())
                .iconName(d.getIconName())
                .colorHex(d.getColorHex())
                .contactEmail(d.getContactEmail())
                .contactPhone(d.getContactPhone())
                .active(d.isActive())
                .build();
    }
}
