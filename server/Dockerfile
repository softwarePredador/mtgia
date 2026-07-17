FROM dart:3.12.2@sha256:13140e26d84f4fda57cea31942222112aeb2eec10e5e6874c1c0f70beed189ab AS build

WORKDIR /app/server

# Hooks Mason compilados não são portáveis entre versões do kernel Dart.
# Mantenha este namespace alinhado ao SDK fixado acima para impedir que um
# cache compartilhado reutilize snapshots produzidos por outro runtime.
ENV MASON_CACHE=/tmp/manaloom-mason-cache-dart-3.12.2

COPY tools/manaloom_lints /app/tools/manaloom_lints
COPY server/pubspec.yaml server/pubspec.lock ./
RUN dart pub get --enforce-lockfile

COPY server/ .

# Gera o servidor de produção com o CLI resolvido pelo pubspec.lock.
RUN mkdir -p /out \
  && dart run dart_frog_cli:dart_frog build \
  && dart compile exe build/bin/server.dart -o /out/manaloom-server

# O runtime recebe somente o executável AOT. Código-fonte, testes, ferramentas
# de build e qualquer fixture de desenvolvimento ficam fora da imagem final.
FROM dart:3.12.2@sha256:13140e26d84f4fda57cea31942222112aeb2eec10e5e6874c1c0f70beed189ab AS runtime

WORKDIR /app/server
COPY --from=build --chown=10001:10001 /out/manaloom-server /app/server/manaloom-server

ENV PORT=8080
EXPOSE 8080

USER 10001:10001

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl --fail --silent --show-error --max-time 3 \
    "http://127.0.0.1:${PORT:-8080}/health/live" || exit 1

# Easypanel costuma injetar PORT; fallback para 8080.
CMD ["/bin/sh", "-c", "exec /app/server/manaloom-server --hostname 0.0.0.0 --port ${PORT:-8080}"]
