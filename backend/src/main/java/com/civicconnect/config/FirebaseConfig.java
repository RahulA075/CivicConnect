package com.civicconnect.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;
import org.springframework.util.StringUtils;

import jakarta.annotation.PostConstruct;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;

/**
 * Initialises the Firebase Admin SDK once at startup.
 * <p>
 * Resolution order for credentials:
 * <ol>
 *   <li>Explicit file path via {@code app.notification.fcm-credentials-path}</li>
 *   <li>Classpath resource {@code firebase-service-account.json}</li>
 *   <li>Application Default Credentials (ADC) — works in GCP/Cloud Run</li>
 * </ol>
 * If none are available (local dev without Firebase) the SDK is left
 * uninitialised and push notifications silently no-op.
 */
@Slf4j
@Configuration
@RequiredArgsConstructor
public class FirebaseConfig {

    private final AppProperties appProperties;

    @PostConstruct
    public void init() {
        if (!FirebaseApp.getApps().isEmpty()) return; // already initialised

        try {
            GoogleCredentials credentials = resolveCredentials();
            if (credentials == null) {
                log.warn("FCM: no credentials found — push notifications disabled. " +
                         "Set FCM_CREDENTIALS_PATH or add firebase-service-account.json to classpath.");
                return;
            }

            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(credentials)
                    .build();
            FirebaseApp.initializeApp(options);
            log.info("FCM: Firebase Admin SDK initialised successfully");

        } catch (Exception e) {
            log.error("FCM: Failed to initialise Firebase Admin SDK — push notifications disabled. Error: {}",
                    e.getMessage());
        }
    }

    private GoogleCredentials resolveCredentials() throws IOException {
        // 1. Explicit file path
        String path = appProperties.getNotification().getFcmCredentialsPath();
        if (StringUtils.hasText(path)) {
            log.info("FCM: loading credentials from file: {}", path);
            try (InputStream is = new FileInputStream(path)) {
                return GoogleCredentials.fromStream(is)
                        .createScoped("https://www.googleapis.com/auth/firebase.messaging");
            }
        }

        // 2. Classpath resource
        ClassPathResource resource = new ClassPathResource("firebase-service-account.json");
        if (resource.exists()) {
            log.info("FCM: loading credentials from classpath resource");
            try (InputStream is = resource.getInputStream()) {
                return GoogleCredentials.fromStream(is)
                        .createScoped("https://www.googleapis.com/auth/firebase.messaging");
            }
        }

        // 3. Application Default Credentials
        try {
            log.info("FCM: attempting Application Default Credentials");
            return GoogleCredentials.getApplicationDefault()
                    .createScoped("https://www.googleapis.com/auth/firebase.messaging");
        } catch (Exception e) {
            log.debug("FCM: ADC not available: {}", e.getMessage());
            return null;
        }
    }
}
