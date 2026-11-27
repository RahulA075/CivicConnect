package com.civicconnect.modules.admin.service;

import com.civicconnect.modules.admin.dto.EmergencyAlertRequest;
import com.civicconnect.modules.admin.dto.EmergencyAlertResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.UUID;

public interface EmergencyAlertService {
    Page<EmergencyAlertResponse> getByMunicipality(UUID municipalityId, boolean activeOnly, Pageable pageable);
    EmergencyAlertResponse create(UUID municipalityId, EmergencyAlertRequest request, UUID createdBy);
    void deactivate(UUID id, UUID performedBy);
}
