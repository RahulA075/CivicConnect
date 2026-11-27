package com.civicconnect.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

/**
 * Springdoc OpenAPI 3.0 configuration.
 * Accessible at /swagger-ui.html in dev/staging.
 */
@Configuration
public class OpenApiConfig {

    private static final String SECURITY_SCHEME_NAME = "bearerAuth";

    @Value("${spring.application.name}")
    private String appName;

    @Bean
    public OpenAPI civicConnectOpenApi() {
        return new OpenAPI()
            .info(apiInfo())
            .servers(List.of(
                new Server().url("/").description("Current server"),
                new Server().url("http://localhost:8080").description("Local development")
            ))
            .addSecurityItem(new SecurityRequirement().addList(SECURITY_SCHEME_NAME))
            .components(new Components()
                .addSecuritySchemes(SECURITY_SCHEME_NAME, jwtSecurityScheme()));
    }

    private Info apiInfo() {
        return new Info()
            .title("CivicConnect API")
            .version("v1.0.0")
            .description("""
                REST API for the CivicConnect civic issue reporting platform.

                **Authentication:** All protected endpoints require a Bearer JWT token
                obtained from `POST /api/v1/auth/login` or `POST /api/v1/auth/register`.

                **Roles:** CITIZEN | FIELD_WORKER | DEPT_SUPERVISOR | MUNICIPAL_ADMIN | SYSTEM_ADMIN
                """)
            .contact(new Contact()
                .name("CivicConnect Engineering")
                .email("engineering@civicconnect.in"))
            .license(new License()
                .name("Proprietary")
                .url("https://civicconnect.in/terms"));
    }

    private SecurityScheme jwtSecurityScheme() {
        return new SecurityScheme()
            .type(SecurityScheme.Type.HTTP)
            .scheme("bearer")
            .bearerFormat("JWT")
            .name(SECURITY_SCHEME_NAME)
            .description("Provide the JWT access token. Format: `Bearer <token>`");
    }
}
