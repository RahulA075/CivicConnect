# ── Stage 1: Build ────────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /workspace

# Cache Gradle dependencies separately from source code
COPY build.gradle.kts settings.gradle.kts ./
COPY gradle ./gradle
COPY gradlew ./
RUN chmod +x gradlew && ./gradlew dependencies --no-daemon -q || true

# Copy source and build
COPY src ./src
RUN ./gradlew bootJar --no-daemon -x test

# ── Stage 2: Runtime ─────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jre-alpine AS runtime

LABEL maintainer="engineering@civicconnect.in"
LABEL version="1.0.0"

# Create non-root user
RUN addgroup -S civicconnect && adduser -S civicconnect -G civicconnect

WORKDIR /app

# Copy built JAR
COPY --from=builder /workspace/build/libs/civicconnect.jar app.jar

# Set ownership
RUN chown civicconnect:civicconnect app.jar
USER civicconnect

# JVM tuning for containers with virtual threads
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75 \
               -XX:+UseG1GC \
               -XX:+ExitOnOutOfMemoryError \
               -Djava.security.egd=file:/dev/./urandom"

EXPOSE 8080

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
