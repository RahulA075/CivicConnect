package com.civicconnect;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;

import com.civicconnect.common.security.UserDetailsServiceImpl;
import com.civicconnect.common.security.TokenBlacklistService;

/**
 * Smoke test — verifies the Spring application context loads without errors.
 *
 * Uses the "test" profile (H2 in-memory DB, no Flyway, no Redis/RabbitMQ required).
 * Mocks infrastructure beans that need external services at startup.
 */
@SpringBootTest
@ActiveProfiles("test")
@TestPropertySource(properties = {
    "spring.flyway.enabled=false",
    "spring.jpa.hibernate.ddl-auto=none",
    "spring.datasource.url=jdbc:h2:mem:civicconnect_smoke;MODE=PostgreSQL;DB_CLOSE_DELAY=-1",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "spring.jpa.properties.hibernate.validator.apply_to_ddl=false",
    "spring.data.redis.host=localhost",
    "spring.data.redis.port=6379",
    "spring.rabbitmq.host=localhost",
    "spring.rabbitmq.port=5672",
    "app.notification.fcm-credentials-path=",
    "app.ai.enabled=false"
})
class CivicConnectApplicationTest {

    // Mock beans that require external services at startup
    @MockBean TokenBlacklistService  tokenBlacklistService;

    @Test
    void contextLoads() {
        // Spring context loaded successfully — all beans wired correctly.
    }
}
