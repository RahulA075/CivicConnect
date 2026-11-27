package com.civicconnect.modules.admin.service;

import com.civicconnect.modules.admin.entity.Municipality;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.UUID;

public interface MunicipalityService {
    Municipality getById(UUID id);
    Page<Municipality> getAll(Pageable pageable);
    Municipality create(Object request, UUID createdBy);
    Municipality update(UUID id, Object request, UUID updatedBy);
    void deactivate(UUID id, UUID performedBy);
}
