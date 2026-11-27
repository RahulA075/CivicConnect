package com.civicconnect.common.security;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Optional;
import java.util.UUID;

/**
 * Static helpers to extract the current authenticated user's context
 * from the Spring Security context in non-component classes (e.g., entities).
 */
public final class SecurityUtils {

    private SecurityUtils() {}

    public static Optional<UUID> getCurrentUserId() {
        return getCurrentPrincipal()
            .map(u -> UUID.fromString(u.getUsername()));
    }

    public static Optional<String> getCurrentUserRole() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) return Optional.empty();
        return auth.getAuthorities().stream()
            .map(GrantedAuthority::getAuthority)
            .filter(a -> a.startsWith("ROLE_"))
            .map(a -> a.substring(5))
            .findFirst();
    }

    public static boolean hasRole(String role) {
        return getCurrentUserRole()
            .map(r -> r.equalsIgnoreCase(role))
            .orElse(false);
    }

    private static Optional<UserDetails> getCurrentPrincipal() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) return Optional.empty();
        Object principal = auth.getPrincipal();
        if (principal instanceof UserDetails ud) return Optional.of(ud);
        return Optional.empty();
    }
}
