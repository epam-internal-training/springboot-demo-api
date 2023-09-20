FROM ubuntu:20.04 as newrelic

WORKDIR /tmp

RUN apt-get update && \
    apt-get install unzip  curl && \
    curl -O https://download.newrelic.com/newrelic/java-agent/newrelic-agent/current/newrelic-java.zip && \
    unzip newrelic-java.zip

FROM gradle:jdk20 as CI

WORKDIR /tmp

COPY ./ /tmp

RUN ./gradlew build

FROM openjdk:20-jdk-slim as production

WORKDIR /tmp

COPY --from=newrelic /tmp/newrelic/newrelic.jar /usr/local/newrelic/
COPY --from=newrelic /tmp/newrelic/newrelic.yml /usr/local/newrelic/

COPY --from=ci /tmp/build/libs/demo-0.0.1-SNAPSHOT.jar /tmp

ENV JAVA_AGENT_OPTS="-javaagent:/usr/local/newrelic/newrelic.jar -Dnewrelic.config.app_name=${NEW_RELIC_APP_NAME} -Dnewrelic.config.license_key=${NEW_RELIC_LICENSE_KEY} -Dnewrelic.config.log_file_name=STDOUT"

EXPOSE 8080

ENTRYPOINT ["sh", "-c", "java ${JAVA_AGENT_OPTS} -jar demo-0.0.1-SNAPSHOT.jar"]


