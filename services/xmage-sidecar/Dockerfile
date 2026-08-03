FROM maven:3.9.16-eclipse-temurin-17-noble@sha256:1ed5d1f54416b706707b4f3238f63a20bb06aab27c6d240090a2bb9ad895ed45 AS build

ARG XMAGE_COMMIT=2c43ec8cdb5cd475d47e6b555a4077151f476a3b
ARG XMAGE_PATCH_COMMIT=991948742f840cd88493a4ea8cb3f4ed192e4742
ARG XMAGE_PATCH_TREE=cacc9649f20ddf450528073251acd91e1d41c152
ARG XMAGE_PATCH_SHA256=24f6e88e082a222b60e2fb890898e43d3c7ef971ee6e38550aa476f371733642
ARG XMAGE_PATCH_REPOSITORY=https://github.com/softwarePredador/mage.git

RUN apt-get update \
    && apt-get install -y --no-install-recommends git unzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY docs/qa/evidence/LOREHOLD_CANDIDATE_FOCUSED_TESTS_2026-07-29.patch /tmp/lorehold.patch
RUN test "$(sha256sum /tmp/lorehold.patch | awk '{print $1}')" = "$XMAGE_PATCH_SHA256" \
    && git init -q xmage \
    && cd xmage \
    && git remote add upstream https://github.com/magefree/mage.git \
    && git fetch --depth 1 upstream "$XMAGE_COMMIT" \
    && git checkout -q --detach FETCH_HEAD \
    && test "$(git rev-parse HEAD)" = "$XMAGE_COMMIT" \
    && git apply --check --unidiff-zero /tmp/lorehold.patch \
    && git apply --unidiff-zero --whitespace=nowarn /tmp/lorehold.patch \
    && git add -A \
    && test "$(git write-tree)" = "$XMAGE_PATCH_TREE" \
    && git reset --hard -q "$XMAGE_COMMIT" \
    && git remote add governed "$XMAGE_PATCH_REPOSITORY" \
    && git fetch --depth 2 governed "$XMAGE_PATCH_COMMIT" \
    && test "$(git rev-parse FETCH_HEAD)" = "$XMAGE_PATCH_COMMIT" \
    && test "$(git rev-parse FETCH_HEAD^)" = "$XMAGE_COMMIT" \
    && test "$(git rev-parse FETCH_HEAD^{tree})" = "$XMAGE_PATCH_TREE" \
    && git checkout -q --detach FETCH_HEAD \
    && test "$(git rev-parse HEAD)" = "$XMAGE_PATCH_COMMIT" \
    && rm /tmp/lorehold.patch

WORKDIR /build/xmage
RUN grep -A2 '<artifactId>sqlite-jdbc</artifactId>' Mage.Server/pom.xml | grep '3.53.2.0' \
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
