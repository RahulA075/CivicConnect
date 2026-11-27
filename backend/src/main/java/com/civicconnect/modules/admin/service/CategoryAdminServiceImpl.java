package com.civicconnect.modules.admin.service;

import com.civicconnect.common.exception.ResourceNotFoundException;
import com.civicconnect.modules.admin.dto.CategoryRequest;
import com.civicconnect.modules.admin.dto.CategoryResponse;
import com.civicconnect.modules.admin.entity.Department;
import com.civicconnect.modules.admin.repository.DepartmentRepository;
import com.civicconnect.modules.admin.repository.MunicipalityRepository;
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
public class CategoryAdminServiceImpl implements CategoryAdminService {

    private final IssueCategoryRepository categoryRepository;
    private final MunicipalityRepository  municipalityRepository;
    private final DepartmentRepository    departmentRepository;

    @Override
    @Transactional(readOnly = true)
    public List<CategoryResponse> getByMunicipality(UUID municipalityId) {
        return categoryRepository.findTopLevelByMunicipality(municipalityId)
                .stream().map(this::toDto).toList();
    }

    @Override
    @Transactional
    public CategoryResponse create(UUID municipalityId, CategoryRequest req, UUID createdBy) {
        var municipality = municipalityRepository.findById(municipalityId)
                .orElseThrow(() -> new ResourceNotFoundException("Municipality not found: " + municipalityId));

        Department department = departmentRepository.findById(req.getDepartmentId())
                .orElseThrow(() -> new ResourceNotFoundException("Department not found: " + req.getDepartmentId()));

        IssueCategory parent = null;
        if (req.getParentId() != null) {
            parent = categoryRepository.findById(req.getParentId())
                    .orElseThrow(() -> new ResourceNotFoundException("Parent category not found: " + req.getParentId()));
        }

        IssueCategory category = IssueCategory.builder()
                .municipality(municipality)
                .department(department)
                .parent(parent)
                .name(req.getName())
                .description(req.getDescription())
                .iconName(req.getIconName())
                .colorHex(req.getColorHex() != null ? req.getColorHex() : "#1565C0")
                .sortOrder(req.getSortOrder())
                .createdBy(createdBy)
                .build();

        return toDto(categoryRepository.save(category));
    }

    @Override
    @Transactional
    public CategoryResponse update(UUID id, CategoryRequest req, UUID updatedBy) {
        IssueCategory category = categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Category not found: " + id));

        Department department = departmentRepository.findById(req.getDepartmentId())
                .orElseThrow(() -> new ResourceNotFoundException("Department not found: " + req.getDepartmentId()));

        IssueCategory parent = null;
        if (req.getParentId() != null) {
            parent = categoryRepository.findById(req.getParentId())
                    .orElseThrow(() -> new ResourceNotFoundException("Parent category not found: " + req.getParentId()));
        }

        category.setDepartment(department);
        category.setParent(parent);
        category.setName(req.getName());
        category.setDescription(req.getDescription());
        category.setIconName(req.getIconName());
        category.setColorHex(req.getColorHex() != null ? req.getColorHex() : "#1565C0");
        category.setSortOrder(req.getSortOrder());

        return toDto(categoryRepository.save(category));
    }

    @Override
    @Transactional
    public void deactivate(UUID id, UUID performedBy) {
        IssueCategory category = categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Category not found: " + id));
        category.setActive(false);
        categoryRepository.save(category);
        log.info("Category {} deactivated by {}", id, performedBy);
    }

    // ── Mapper ────────────────────────────────────────────────────────────────

    private CategoryResponse toDto(IssueCategory c) {
        return CategoryResponse.builder()
                .id(c.getId())
                .municipalityId(c.getMunicipality().getId())
                .departmentId(c.getDepartment().getId())
                .departmentName(c.getDepartment().getName())
                .parentId(c.getParent() != null ? c.getParent().getId() : null)
                .parentName(c.getParent() != null ? c.getParent().getName() : null)
                .name(c.getName())
                .description(c.getDescription())
                .iconName(c.getIconName())
                .colorHex(c.getColorHex())
                .sortOrder(c.getSortOrder())
                .active(c.isActive())
                .build();
    }
}
