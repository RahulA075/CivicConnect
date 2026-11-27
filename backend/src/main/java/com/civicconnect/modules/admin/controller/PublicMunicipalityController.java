package com.civicconnect.modules.admin.controller;

import com.civicconnect.common.response.ApiResponse;
import com.civicconnect.modules.admin.dto.MunicipalitySummaryResponse;
import com.civicconnect.modules.admin.repository.MunicipalityRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.List;

@RestController
@RequestMapping("/api/v1/public/municipalities")
@RequiredArgsConstructor
@Tag(name = "Public Municipalities")
public class PublicMunicipalityController {

    private final MunicipalityRepository municipalityRepository;

    @Operation(summary = "List active municipalities (used by citizen sign-up)")
    @GetMapping
    public ResponseEntity<ApiResponse<List<MunicipalitySummaryResponse>>> list() {
        return ResponseEntity.ok(ApiResponse.success(
                municipalityRepository.findByActiveTrueOrderByNameAsc().stream()
                        .map(m -> MunicipalitySummaryResponse.builder()
                                .id(m.getId())
                                .name(m.getName())
                                .state(m.getState())
                                .build())
                        .toList()));
    }
}
