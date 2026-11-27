package com.civicconnect.modules.admin.service;

import com.civicconnect.modules.admin.dto.CreateDepartmentRequest;
import com.civicconnect.modules.admin.dto.DepartmentResponse;
import com.civicconnect.modules.admin.entity.Department;

import java.util.List;
import java.util.UUID;

public interface DepartmentService {
    List<Department> getByMunicipality(UUID municipalityId);
    DepartmentResponse getById(UUID id);
    DepartmentResponse create(CreateDepartmentRequest request, UUID municipalityId, UUID createdBy);
    DepartmentResponse update(UUID id, CreateDepartmentRequest request, UUID updatedBy);
    void deactivate(UUID id, UUID performedBy);
}
