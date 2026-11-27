package com.civicconnect.modules.admin.service;

import com.civicconnect.modules.admin.dto.EscalationRuleRequest;
import com.civicconnect.modules.admin.dto.EscalationRuleResponse;

import java.util.List;
import java.util.UUID;

public interface EscalationRuleService {
    List<EscalationRuleResponse> getByMunicipality(UUID municipalityId);
    EscalationRuleResponse create(UUID municipalityId, EscalationRuleRequest request, UUID createdBy);
    EscalationRuleResponse update(UUID id, EscalationRuleRequest request, UUID updatedBy);
    void deactivate(UUID id, UUID performedBy);
}
