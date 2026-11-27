package com.civicconnect.modules.admin.service;

import com.civicconnect.modules.admin.dto.SlaPolicyRequest;
import com.civicconnect.modules.admin.dto.SlaPolicyResponse;

import java.util.List;
import java.util.UUID;

public interface SlaPolicyService {
    List<SlaPolicyResponse> getByMunicipality(UUID municipalityId);
    SlaPolicyResponse create(UUID municipalityId, SlaPolicyRequest request, UUID createdBy);
    SlaPolicyResponse update(UUID id, SlaPolicyRequest request, UUID updatedBy);
    void deactivate(UUID id, UUID performedBy);
}
