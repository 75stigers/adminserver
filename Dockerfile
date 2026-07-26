FROM maven:3.9-eclipse-temurin-21 AS build

WORKDIR /workspace

COPY pom.xml ./
RUN mvn dependency:go-offline -B

COPY src ./src
RUN mvn clean package -B

FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

RUN addgroup -S -g 10001 adminserver \
    && adduser -S -D -H -u 10001 -G adminserver adminserver

COPY --from=build --chown=adminserver:adminserver \
    /workspace/target/adminserver-*.jar app.jar

USER 10001:10001
EXPOSE 8085

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
