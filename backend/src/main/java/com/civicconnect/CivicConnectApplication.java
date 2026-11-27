package com.civicconnect;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * CivicConnect – Production-ready civic issue management platform.
 *
 * <p>Modular monolith architecture. Modules live under
 * {@code com.civicconnect.modules.*} and share infrastructure
 * from {@code com.civicconnect.common.*}.
 */
@SpringBootApplication
@ConfigurationPropertiesScan
@EnableCaching
@EnableAsync
@EnableScheduling
public class CivicConnectApplication {

    public static void main(String[] args) {
        SpringApplication.run(CivicConnectApplication.class, args);
    }
}
