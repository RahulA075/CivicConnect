package com.civicconnect.integration;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

import java.sql.Connection;
import java.sql.DriverManager;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Minimal smoke test: verifies that Testcontainers can start a PostgreSQL
 * container using the configured Docker endpoint.
 * If this fails with HTTP 400, the Docker endpoint is still wrong.
 */
@Testcontainers
@Tag("integration")
@DisplayName("Docker Smoke Test — PostgreSQL container starts")
class DockerSmokeTest {

    @Container
    static PostgreSQLContainer<?> postgres =
            new PostgreSQLContainer<>(DockerImageName.parse("postgres:16-alpine"))
                    .withDatabaseName("smoke_test")
                    .withUsername("smoke")
                    .withPassword("smoke");

    @Test
    @DisplayName("PostgreSQL container is running and accepts JDBC connections")
    void postgresContainerStarts() throws Exception {
        assertThat(postgres.isRunning()).isTrue();

        try (Connection conn = DriverManager.getConnection(
                postgres.getJdbcUrl(),
                postgres.getUsername(),
                postgres.getPassword())) {
            assertThat(conn.isValid(2)).isTrue();
        }
    }
}
