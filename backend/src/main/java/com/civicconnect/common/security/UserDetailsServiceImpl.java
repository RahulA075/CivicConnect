package com.civicconnect.common.security;

import com.civicconnect.modules.iam.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Loads {@link UserDetails} by user UUID (stored as the JWT {@code sub} claim).
 *
 * <p>The username here is the user's UUID string, not an email or login name.
 * Spring Security uses this to populate the security context after JWT validation.
 */
@Service
@RequiredArgsConstructor
public class UserDetailsServiceImpl implements UserDetailsService {

    private final UserRepository userRepository;

    @Override
    @Transactional(readOnly = true)
    public UserDetails loadUserByUsername(String userId)
            throws UsernameNotFoundException {

        com.civicconnect.modules.iam.entity.User user =
            userRepository.findActiveById(java.util.UUID.fromString(userId))
                .orElseThrow(() -> new UsernameNotFoundException(
                    "User not found or inactive: " + userId));

        String roleName = "ROLE_" + user.getRole().getName().name();

        return new User(
            user.getId().toString(),
            user.getPasswordHash() != null ? user.getPasswordHash() : "",
            user.isActive(),
            true, true, true,
            List.of(new SimpleGrantedAuthority(roleName))
        );
    }
}
