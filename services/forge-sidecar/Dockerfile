FROM maven:3.9.9-eclipse-temurin-17 AS forge-build

ARG FORGE_COMMIT=a62915f500c2411484689294659c6bb84ea215f8

RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --filter=blob:none https://github.com/Card-Forge/forge.git forge \
    && cd forge \
    && git checkout --detach "${FORGE_COMMIT}" \
    && test "$(git rev-parse HEAD)" = "${FORGE_COMMIT}"

WORKDIR /src/forge
RUN mvn -pl forge-gui-desktop -am package \
    -DskipTests \
    -Dcheckstyle.skip=true \
    -B

COPY services/forge-sidecar/SeededForgeMain.java /tmp/bootstrap/com/manaloom/forge/SeededForgeMain.java
RUN mkdir -p /tmp/bootstrap-classes \
    && javac \
      -cp forge-gui-desktop/target/forge-gui-desktop-2.0.14-SNAPSHOT-jar-with-dependencies.jar \
      -d /tmp/bootstrap-classes \
      /tmp/bootstrap/com/manaloom/forge/SeededForgeMain.java \
    && jar --create --file /tmp/forge-bootstrap.jar -C /tmp/bootstrap-classes .

FROM eclipse-temurin:17-jre

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      fontconfig \
      libfreetype6 \
      libx11-6 \
      libxext6 \
      libxi6 \
      libxrender1 \
      libxtst6 \
      python3 \
      xauth \
      xvfb \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=forge-build /src/forge/forge-gui/res /app/res
COPY --from=forge-build /src/forge/forge-gui-desktop/target/forge-gui-desktop-*-jar-with-dependencies.jar /app/forge.jar
COPY --from=forge-build /tmp/forge-bootstrap.jar /app/forge-bootstrap.jar
COPY services/forge-sidecar/FORGE_COMMIT /app/FORGE_COMMIT
COPY services/forge-sidecar/forge.profile.properties /app/forge.profile.properties
COPY services/forge-sidecar/sidecar.py /app/sidecar.py

RUN mkdir -p \
      /tmp/forge/decks/commander \
      /tmp/forge/cache \
      /app/forge-gui \
      /app/forge-gui-desktop \
    && ln -s /app/res /app/forge-gui/res \
    && ln -s /app/forge.profile.properties /app/forge-gui/forge.profile.properties \
    && ln -s /app/res /app/forge-gui-desktop/res \
    && ln -s /app/forge.profile.properties /app/forge-gui-desktop/forge.profile.properties

ENV FORGE_HOME=/app/forge-gui-desktop \
    FORGE_JAR=/app/forge.jar \
    FORGE_BOOTSTRAP_JAR=/app/forge-bootstrap.jar \
    FORGE_JAVA_COMMAND="xvfb-run -a java -Xms128m -Xmx1536m" \
    FORGE_CARD_SCRIPTS=/app/res/cardsfolder \
    FORGE_DECK_DIR=/tmp/forge/decks/commander \
    FORGE_COMMIT_FILE=/app/FORGE_COMMIT \
    PORT=8080

EXPOSE 8080
CMD ["python3", "/app/sidecar.py"]
