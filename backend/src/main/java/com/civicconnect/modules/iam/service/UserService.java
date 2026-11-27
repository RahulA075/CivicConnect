package com.civicconnect.modules.iam.service;

import com.civicconnect.modules.admin.dto.InviteUserRequest;
import com.civicconnect.modules.iam.dto.UserResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.UUID;

/** User account management service contract. */
public interface UserService {
    UserResponse getById(UUID userId);
    UserResponse getMe(UUID currentUserId);
    Page<UserResponse> getAuthorityUsers(UUID municipalityId, UUID departmentId, Pageable pageable);
    UserResponse updateProfile(UUID userId, Object updateRequest);
    void deactivateUser(UUID userId, UUID performedBy);
    void reactivateUser(UUID userId, UUID performedBy);
    UserResponse inviteUser(UUID municipalityId, InviteUserRequest request, UUID invitedBy);
}
