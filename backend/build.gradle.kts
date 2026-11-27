import org.springframework.boot.gradle.tasks.bundling.BootJar

plugins {
    java
    id("org.springframework.boot")         version "3.3.2"
    id("io.spring.dependency-management")  version "1.1.5"
}

group   = "com.civicconnect"
version = "1.0.0"

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(17)
    }
}

configurations {
    compileOnly {
        extendsFrom(configurations.annotationProcessor.get())
    }
}

repositories {
    mavenCentral()
}

dependencies {
    // ── Spring Boot Starters ─────────────────────────────────────
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-security")
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-validation")
    implementation("org.springframework.boot:spring-boot-starter-actuator")
    implementation("org.springframework.boot:spring-boot-starter-mail")
    implementation("org.springframework.boot:spring-boot-starter-cache")
    implementation("org.springframework.boot:spring-boot-starter-data-redis")
    implementation("org.springframework.boot:spring-boot-starter-amqp")
    implementation("org.springframework.boot:spring-boot-starter-aop")

    // ── Database ─────────────────────────────────────────────────
    runtimeOnly("org.postgresql:postgresql")
    implementation("org.flywaydb:flyway-core")
    implementation("org.flywaydb:flyway-database-postgresql")

    // ── Hibernate Spatial (PostGIS) ───────────────────────────────
    implementation("org.hibernate.orm:hibernate-spatial")

    // ── JWT ──────────────────────────────────────────────────────
    implementation("io.jsonwebtoken:jjwt-api:0.12.6")
    runtimeOnly("io.jsonwebtoken:jjwt-impl:0.12.6")
    runtimeOnly("io.jsonwebtoken:jjwt-jackson:0.12.6")

    // ── OpenAPI / Swagger ────────────────────────────────────────
    implementation("org.springdoc:springdoc-openapi-starter-webmvc-ui:2.6.0")

    // ── MapStruct ────────────────────────────────────────────────
    implementation("org.mapstruct:mapstruct:1.6.0")
    annotationProcessor("org.mapstruct:mapstruct-processor:1.6.0")

    // ── Lombok ───────────────────────────────────────────────────
    compileOnly("org.projectlombok:lombok")
    annotationProcessor("org.projectlombok:lombok")
    // Lombok + MapStruct combined processor ordering
    annotationProcessor("org.projectlombok:lombok-mapstruct-binding:0.2.0")

    // ── Observability ────────────────────────────────────────────
    implementation("io.micrometer:micrometer-registry-prometheus")
    implementation("io.micrometer:micrometer-tracing-bridge-otel")
    implementation("io.opentelemetry:opentelemetry-exporter-otlp")

    // ── Firebase Admin SDK (FCM push notifications) ───────────────
    implementation("com.google.firebase:firebase-admin:9.3.0")

    // ── Security Hardening (Phase 12) ────────────────────────────
    // Bucket4j rate limiting — core library (in-process ConcurrentHashMap store)
    implementation("com.bucket4j:bucket4j-core:8.10.1")
    // HTML sanitization for XSS prevention
    implementation("org.jsoup:jsoup:1.18.1")

    // ── Utility ──────────────────────────────────────────────────
    implementation("com.fasterxml.jackson.module:jackson-module-afterburner")
    implementation("com.fasterxml.jackson.datatype:jackson-datatype-jsr310")

    // ── Testing ──────────────────────────────────────────────────
    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testImplementation("org.awaitility:awaitility:4.2.2")
    testImplementation("org.springframework.security:spring-security-test")
    testImplementation("org.testcontainers:junit-jupiter")
    testImplementation("org.testcontainers:postgresql")
    testImplementation("org.testcontainers:rabbitmq")
    // OkHttp transport for docker-java: httpclient5 (zerodep default) sends HTTP/1.1
    // keep-alive requests that Docker Desktop's TCP shim rejects with HTTP 400.
    // OkHttp sends Connection: close which the shim passes through to the real daemon.
    testImplementation("com.github.docker-java:docker-java-transport-okhttp:3.4.2")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
    // H2 for lightweight context-load tests (no containers required)
    testRuntimeOnly("com.h2database:h2")
}

dependencyManagement {
    imports {
        // 1.21.3 pulls docker-java 3.4.2 which supports Docker Engine 29.x (API >= 1.44).
        // docker-java 3.4.0 (in 1.20.1) sent a sub-1.44 API version and received HTTP 400.
        mavenBom("org.testcontainers:testcontainers-bom:1.21.3")
    }
}

tasks.withType<Test> {
    useJUnitPlatform()
    jvmArgs("-XX:+EnableDynamicAgentLoading")
}

// Default test task excludes integration tests (require Docker)
tasks.named<Test>("test") {
    useJUnitPlatform {
        excludeTags("integration")
    }
}

// Run integration tests separately: ./gradlew integrationTest
tasks.register<Test>("integrationTest") {
    description = "Runs Testcontainers integration tests (requires Docker)"
    group       = "verification"
    useJUnitPlatform {
        includeTags("integration")
    }
    jvmArgs("-XX:+EnableDynamicAgentLoading")
    // Docker Engine 29.x requires API >= 1.44. docker-java 3.4.2 (via TC 1.21.3 BOM) handles
    // this correctly. tc.host=tcp://localhost:2375 is set in ~/testcontainers.properties.
    //
    // Docker Desktop configures an HTTP proxy at http.docker.internal:3128 in its daemon.
    // The shaded Apache HttpClient 5 inside docker-java uses java.net.ProxySelector.getDefault(),
    // which reads the JVM http.proxyHost / http.nonProxyHosts system properties.
    // Without nonProxyHosts, the httpclient routes localhost:2375 through the proxy and gets
    // a Docker Desktop stub response (HTTP 400, empty daemon info).
    systemProperty("http.nonProxyHosts", "localhost|127.*|[::1]")
    systemProperty("https.nonProxyHosts", "localhost|127.*|[::1]")
}

tasks.named<BootJar>("bootJar") {
    archiveFileName.set("civicconnect.jar")
}
