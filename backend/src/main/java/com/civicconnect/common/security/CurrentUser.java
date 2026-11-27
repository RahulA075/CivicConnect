package com.civicconnect.common.security;

import org.springframework.security.core.annotation.AuthenticationPrincipal;

import java.lang.annotation.*;

/**
 * Convenience annotation to inject the currently authenticated
 * {@link org.springframework.security.core.userdetails.UserDetails}
 * into controller method parameters.
 *
 * <pre>
 * {@code
 * @GetMapping("/me")
 * public ResponseEntity<?> getMe(@CurrentUser UserDetails principal) { ... }
 * }
 * </pre>
 */
@Target(ElementType.PARAMETER)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@AuthenticationPrincipal
public @interface CurrentUser {
}
