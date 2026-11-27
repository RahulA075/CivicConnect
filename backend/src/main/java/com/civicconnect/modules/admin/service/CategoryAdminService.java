package com.civicconnect.modules.admin.service;

import com.civicconnect.modules.admin.dto.CategoryRequest;
import com.civicconnect.modules.admin.dto.CategoryResponse;

import java.util.List;
import java.util.UUID;

public interface CategoryAdminService {
    List<CategoryResponse> getByMunicipality(UUID municipalityId);
    CategoryResponse create(UUID municipalityId, CategoryRequest request, UUID createdBy);
    CategoryResponse update(UUID id, CategoryRequest request, UUID updatedBy);
    void deactivate(UUID id, UUID performedBy);
}
