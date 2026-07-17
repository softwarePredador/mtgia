FROM maven:3.9.16-eclipse-temurin-17-noble@sha256:1ed5d1f54416b706707b4f3238f63a20bb06aab27c6d240090a2bb9ad895ed45 AS build

ARG XMAGE_COMMIT=34d81ea4995ce15d7e1a788dc6d2a3595d35bcec

RUN apt-get update \
    && apt-get install -y --no-install-recommends git unzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN git clone https://github.com/magefree/mage.git xmage \
    && cd xmage \
    && git checkout "$XMAGE_COMMIT" \
    && test "$(git rev-parse HEAD)" = "$XMAGE_COMMIT"

WORKDIR /build/xmage
RUN sed -i 's/<version>3\.32\.3\.2<\/version>/<version>3.50.2.0<\/version>/' Mage.Server/pom.xml \
    && grep -A2 '<artifactId>sqlite-jdbc</artifactId>' Mage.Server/pom.xml | grep '3.50.2.0' \
    && mvn -pl Mage.Server -am install -DskipTests -Djacoco.skip=true -B \
    && mvn -pl Mage.Server package assembly:single -DskipTests -Djacoco.skip=true -B

WORKDIR /build/sidecar
COPY services/xmage-sidecar/pom.xml ./
COPY services/xmage-sidecar/src ./src
RUN mvn package -DskipTests -B

FROM eclipse-temurin:17.0.19_10-jre-noble@sha256:543aebd60ff1deb9e906a8d4b117a7eda68a7f8e0d71041db2b5839d7fa057b8

RUN apt-get update \
    && apt-get install -y --no-install-recommends unzip \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/xmage /opt/manaloom
COPY --from=build /build/xmage/Mage.Server/target/mage-server.zip /tmp/mage-server.zip
RUN unzip -q /tmp/mage-server.zip -d /opt/xmage \
    && rm /tmp/mage-server.zip
COPY --from=build /build/sidecar/target/xmage-sidecar.jar /opt/manaloom/xmage-sidecar.jar
COPY services/xmage-sidecar/entrypoint.sh /opt/manaloom/entrypoint.sh
RUN chmod 0755 /opt/manaloom/entrypoint.sh

ENV PORT=8080 \
    XMAGE_SERVER_HOST=127.0.0.1 \
    XMAGE_SERVER_PORT=17171 \
    XMAGE_SERVER_JAVA_OPTS="-Xms256m -Xmx2g" \
    XMAGE_SIDECAR_JAVA_OPTS="-Xms128m -Xmx512m" \
    JAVA_TOOL_OPTIONS="-Djava.awt.headless=true -Djava.net.preferIPv4Stack=true"

EXPOSE 8080
ENTRYPOINT ["/opt/manaloom/entrypoint.sh"]
