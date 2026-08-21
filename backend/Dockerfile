FROM maven:3.9.16-eclipse-temurin-21-alpine AS builder

WORKDIR /app

COPY pom.xml .
RUN mvn -B dependency:go-offline

COPY src ./src
RUN mvn -B package

FROM eclipse-temurin:21-jre-alpine AS runtime

RUN addgroup -S holdly && adduser -S holdly -G holdly

WORKDIR /app
COPY --from=builder --chown=holdly:holdly /app/target/*.jar /app/app.jar

USER holdly

EXPOSE 8080
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75"

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/api/health || exit 1

ENTRYPOINT ["java", "-jar", "/app/app.jar"]