package com.civicconnect.modules.iam.service;

import com.civicconnect.common.enums.AuthProvider;
import com.civicconnect.common.exception.ConflictException;
import com.civicconnect.common.exception.ResourceNotFoundException;
import com.civicconnect.modules.admin.dto.InviteUserRequest;
import com.civicconnect.modules.admin.entity.Department;
import com.civicconnect.modules.admin.entity.Municipality;
import com.civicconnect.modules.admin.repository.DepartmentRepository;
import com.civicconnect.modules.admin.repository.MunicipalityRepository;
import com.civicconnect.modules.iam.dto.UserResponse;
import com.civicconnect.modules.iam.entity.Role;
import com.civicconnect.modules.iam.entity.User;
import com.civicconnect.modules.iam.repository.RoleRepository;
import com.civicconnect.modules.iam.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {

    private final UserRepository         userRepository;
    private final RoleRepository         roleRepository;
    private final MunicipalityRepository municipalityRepository;
    private final DepartmentRepository   departmentRepository;
    private final PasswordEncoder        passwordEncoder;

    @Override
    @Transactional(readOnly = true)
    public UserResponse getById(UUID userId) {
        return toDto(findActive(userId));
    }

    @Override
    @Transactional(readOnly = true)
    public UserResponse getMe(UUID currentUserId) {
        return toDto(findActive(currentUserId));
    }

    @Override
    @Transactional(readOnly = true)
    public Page<UserResponse> getAuthorityUsers(UUID municipalityId, UUID departmentId, Pageable pageable) {
        return userRepository.findAuthorityUsers(municipalityId, departmentId, pageable)
            .map(this::toDto);
    }

    @Override
    @Transactional
    public UserResponse updateProfile(UUID userId, Object updateRequest) {
        // Generic update handled in ProfileController — placeholder for admin use
        throw new UnsupportedOperationException("Use PATCH /api/v1/users/me for profile updates");
    }

    @Override
    @Transactional
    public UserResponse inviteUser(UUID municipalityId, InviteUserRequest req, UUID invitedBy) {
        if (userRepository.existsByEmailIgnoreCaseAndDeletedAtIsNull(req.getEmail())) {
            throw new ConflictException("EMAIL_TAKEN", "Email address is already registered");
        }

        Municipality municipality = municipalityRepository.findById(municipalityId)
                .orElseThrow(() -> new ResourceNotFoundException("Municipality not found: " + municipalityId));

        Role role = roleRepository.findByName(req.getRole())
                .orElseThrow(() -> new ResourceNotFoundException("Role not found: " + req.getRole()));

        Department department = null;
        if (req.getDepartmentId() != null) {
            department = departmentRepository.findById(req.getDepartmentId())
                    .orElseThrow(() -> new ResourceNotFoundException("Department not found: " + req.getDepartmentId()));
        }

        // Generate a temporary password — admin should share out-of-band or via email
        String tempPassword = UUID.randomUUID().toString().replace("-", "").substring(0, 12);

        User user = User.builder()
                .fullName(req.getFullName())
                .email(req.getEmail().toLowerCase())
                .phone(req.getPhone())
                .passwordHash(passwordEncoder.encode(tempPassword))
                .authProvider(AuthProvider.LOCAL)
                .municipality(municipality)
                .department(department)
                .role(role)
                .emailVerified(false)
                .active(true)
                .build();

        user = userRepository.save(user);
        log.info("User {} invited to municipality {} by {} with role {}",
                user.getId(), municipalityId, invitedBy, req.getRole());

        return toDto(user);
    }

    @Override
    @Transactional
    public void deactivateUser(UUID userId, UUID performedBy) {
        User user = findActive(userId);
        user.setActive(false);
        user.setDeletedAt(Instant.now());
        userRepository.save(user);
        log.info("User {} deactivated by {}", userId, performedBy);
    }

    @Override
    @Transactional
    public void reactivateUser(UUID userId, UUID performedBy) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userId));
        user.setActive(true);
        user.setDeletedAt(null);
        userRepository.save(user);
        log.info("User {} reactivated by {}", userId, performedBy);
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private User findActive(UUID userId) {
        return userRepository.findActiveById(userId)
            .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userId));
    }

    private UserResponse toDto(User user) {
        return UserResponse.builder()
            .id(user.getId())
            .fullName(user.getFullName())
            .email(user.getEmail())
            .phone(user.getPhone())
            .role(user.getRole().getName().name())
            .avatarUrl(user.getAvatarUrl())
            .city(user.getCity())
            .emailVerified(user.isEmailVerified())
            .active(user.isActive())
            .municipalityId(user.getMunicipality() != null ? user.getMunicipality().getId() : null)
            .departmentId(user.getDepartment()   != null ? user.getDepartment().getId()   : null)
            .createdAt(user.getCreatedAt())
            .build();
    }
}
