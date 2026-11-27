package com.civicconnect.modules.admin.service;

import com.civicconnect.modules.admin.entity.Municipality;
import com.civicconnect.modules.admin.repository.MunicipalityRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class MunicipalityServiceImpl implements MunicipalityService {

    private final MunicipalityRepository municipalityRepository;

    @Override
    public Municipality getById(UUID id) { throw new UnsupportedOperationException("Not implemented yet"); }
    @Override
    public Page<Municipality> getAll(Pageable pageable) { return municipalityRepository.findAll(pageable); }
    @Override
    public Municipality create(Object request, UUID createdBy) { throw new UnsupportedOperationException("Not implemented yet"); }
    @Override
    public Municipality update(UUID id, Object request, UUID updatedBy) { throw new UnsupportedOperationException("Not implemented yet"); }
    @Override
    public void deactivate(UUID id, UUID performedBy) { throw new UnsupportedOperationException("Not implemented yet"); }
}
