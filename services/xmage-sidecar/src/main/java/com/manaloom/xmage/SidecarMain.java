package com.manaloom.xmage;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.concurrent.atomic.AtomicBoolean;
import java.time.Instant;
import java.util.UUID;

public final class SidecarMain {
    static final String XMAGE_COMMIT = "2c43ec8cdb5cd475d47e6b555a4077151f476a3b";
    static final String XMAGE_VERSION = "1.4.60";
    static final String EXECUTION_SCHEMA = "external_battle_execution_v2";
    static final String REQUEST_SCHEMA = "external_battle_request_v2";
    static final String DECK_HASH_SCHEMA = "external_battle_deck_hash_v1";
    static final String SIDECAR_PROTOCOL = "external_battle_sidecar_v2";
    static final String AI_PROFILE = "computer_mad";
    static final String SEED_SEMANTICS = "request_correlation_only_server_rng_uncontrolled";
    static final String BUILD_IDENTITY = "xmage-sidecar-v2@" + XMAGE_COMMIT;

    private static final Gson GSON = new Gson();
    static final int MAX_REQUEST_BYTES = 8 * 1024 * 1024;
    static final String PROCESS_ID = UUID.randomUUID().toString();
    static final String STARTED_AT = Instant.now().toString();
    private static final long DEFAULT_SIMULATION_TIMEOUT_MS = 120000L;
    private static final long MIN_SIMULATION_TIMEOUT_MS = 1000L;
    private static final long MAX_SIMULATION_TIMEOUT_MS = 900000L;
    private static final long HARD_TIMEOUT_GRACE_MS = 5000L;
    private static final AtomicBoolean RESTART_SCHEDULED = new AtomicBoolean();
    private static final ExecutorService SIMULATION_EXECUTOR = Executors.newSingleThreadExecutor(task -> {
        Thread thread = new Thread(task, "xmage-simulation");
        thread.setDaemon(true);
        return thread;
    });

    private SidecarMain() {
    }

    public static void main(String[] args) throws Exception {
        String xmageHost = env("XMAGE_SERVER_HOST", "127.0.0.1");
        int xmagePort = envInt("XMAGE_SERVER_PORT", 17171);
        int httpPort = envInt("PORT", 8080);
        String runtimeMode = env("XMAGE_RUNTIME_MODE", "batch")
                .toLowerCase(java.util.Locale.ROOT);
        if (!"batch".equals(runtimeMode)
                && !"interactive".equals(runtimeMode)) {
            throw new IllegalArgumentException(
                    "XMAGE_RUNTIME_MODE must be batch or interactive"
            );
        }
        BattleLiveRegistry liveRegistry = new BattleLiveRegistry();
        XmageBattleService battleService =
                new XmageBattleService(xmageHost, xmagePort, liveRegistry);
        battleService.warmUp();
        InteractiveBattleRegistry interactiveRegistry =
                "interactive".equals(runtimeMode)
                        ? new InteractiveBattleRegistry(
                        xmageHost,
                        xmagePort,
                        envInt("XMAGE_INTERACTIVE_MAX_ACTIVE", 1)
                )
                        : null;

        HttpServer server = HttpServer.create(new InetSocketAddress("0.0.0.0", httpPort), 32);
        server.createContext("/health", exchange -> {
            if (!"GET".equals(exchange.getRequestMethod())) {
                send(exchange, 405, singleton("error", "method_not_allowed"));
                return;
            }
            Map<String, Object> body = new LinkedHashMap<>();
            body.put("status", "ok");
            body.put("engine", "xmage");
            body.put("engine_version", XMAGE_VERSION);
            body.put("engine_commit", XMAGE_COMMIT);
            body.put("xmage_host", xmageHost);
            body.put("xmage_port", xmagePort);
            body.put("catalog_ready", true);
            body.put("indexed_names", battleService.catalogSize());
            body.put("runtime_mode", runtimeMode);
            body.put(
                    "batch_simulation_available",
                    "batch".equals(runtimeMode)
            );
            if ("batch".equals(runtimeMode)) {
                body.put("battle_live", liveRegistry.metrics());
            } else {
                body.put(
                        "interactive_battle",
                        interactiveRegistry.metrics()
                );
            }
            send(exchange, 200, body);
        });
        if ("batch".equals(runtimeMode)) {
            server.createContext(
                    "/cards/coverage",
                    exchange -> handleCardCoverage(exchange, battleService)
            );
            server.createContext(
                    "/coverage",
                    exchange -> handleCoverage(exchange, battleService)
            );
            server.createContext(
                    "/simulate",
                    exchange -> handleSimulation(
                            exchange,
                            battleService,
                            liveRegistry
                    )
            );
            server.createContext(
                    "/live/",
                    exchange -> handleLive(exchange, liveRegistry)
            );
        } else {
            server.createContext(
                    "/interactive/sessions",
                    exchange -> handleInteractive(
                            exchange,
                            interactiveRegistry
                    )
            );
            Runtime.getRuntime().addShutdownHook(
                    new Thread(
                            interactiveRegistry::close,
                            "xmage-interactive-shutdown"
                    )
            );
        }
        server.setExecutor(
                Executors.newFixedThreadPool(
                        "interactive".equals(runtimeMode) ? 8 : 4
                )
        );
        server.start();
        System.out.println(
                "ManaLoom XMage sidecar listening on port "
                        + httpPort
                        + " mode="
                        + runtimeMode
        );
    }

    private static void handleInteractive(
            HttpExchange exchange,
            InteractiveBattleRegistry registry
    ) throws IOException {
        exchange.getResponseHeaders().set("Cache-Control", "no-store");
        exchange.getResponseHeaders().set(
                "X-Content-Type-Options",
                "nosniff"
        );
        String path = exchange.getRequestURI().getPath();
        String prefix = "/interactive/sessions";
        if (!path.startsWith(prefix)) {
            send(exchange, 404, singleton("error", "session_not_found"));
            return;
        }
        String suffix = path.substring(prefix.length());
        try {
            Map<String, Object> result;
            if (suffix.isEmpty() || "/".equals(suffix)) {
                if (!"POST".equals(exchange.getRequestMethod())) {
                    send(
                            exchange,
                            405,
                            singleton("error", "method_not_allowed")
                    );
                    return;
                }
                JsonObject request = JsonParser
                        .parseString(readBody(exchange))
                        .getAsJsonObject();
                result = registry.create(request);
                send(exchange, 201, result);
                return;
            }

            String[] parts = suffix.substring(1).split("/");
            if (parts.length < 1
                    || parts.length > 2
                    || !InteractiveBattleRegistry.isRuntimeId(parts[0])) {
                throw new InteractiveBattleRegistry.NotFoundException();
            }
            String runtimeId = parts[0];
            if (parts.length == 1) {
                if (!"GET".equals(exchange.getRequestMethod())) {
                    send(
                            exchange,
                            405,
                            singleton("error", "method_not_allowed")
                    );
                    return;
                }
                result = registry.read(runtimeId);
                send(exchange, 200, result);
                return;
            }
            if (!"POST".equals(exchange.getRequestMethod())) {
                send(
                        exchange,
                        405,
                        singleton("error", "method_not_allowed")
                );
                return;
            }
            JsonObject request = JsonParser
                    .parseString(readBody(exchange))
                    .getAsJsonObject();
            if ("actions".equals(parts[1])) {
                result = registry.respond(runtimeId, request);
            } else if ("concede".equals(parts[1])) {
                result = registry.concede(runtimeId, request);
            } else {
                throw new InteractiveBattleRegistry.NotFoundException();
            }
            send(exchange, 200, result);
        } catch (InteractiveBattleRegistry.NotFoundException error) {
            send(exchange, 404, singleton("error", "session_not_found"));
        } catch (InteractiveBattleRegistry.CapacityException error) {
            send(exchange, 429, singleton("error", "interactive_capacity"));
        } catch (InteractiveBattleRegistry.ConflictException error) {
            send(exchange, 409, singleton("error", error.code));
        } catch (XmageBattleService.UnsupportedCardsException error) {
            Map<String, Object> body = errorBody(
                    "xmage_coverage_incomplete",
                    error.getMessage()
            );
            body.put("unsupported_cards", error.getUnsupportedCards());
            send(exchange, 422, body);
        } catch (IllegalArgumentException error) {
            send(
                    exchange,
                    400,
                    errorBody("invalid_request", error.getMessage())
            );
        } catch (Exception error) {
            error.printStackTrace(System.err);
            send(
                    exchange,
                    500,
                    errorBody("interactive_failed", error.getMessage())
            );
        }
    }

    private static void handleSimulation(
            HttpExchange exchange,
            XmageBattleService battleService,
            BattleLiveRegistry liveRegistry
    )
            throws IOException {
        if (!"POST".equals(exchange.getRequestMethod())) {
            send(exchange, 405, singleton("error", "method_not_allowed"));
            return;
        }

        Future<Map<String, Object>> simulation = null;
        JsonObject request = null;
        try {
            JsonObject parsedRequest = JsonParser.parseString(readBody(exchange)).getAsJsonObject();
            request = parsedRequest;
            long timeoutMs = simulationTimeoutMillis(parsedRequest);
            simulation = SIMULATION_EXECUTOR.submit(() -> battleService.simulate(parsedRequest));
            Map<String, Object> result;
            try {
                result = simulation.get(timeoutMs + HARD_TIMEOUT_GRACE_MS, TimeUnit.MILLISECONDS);
            } catch (ExecutionException error) {
                throw unwrapSimulationFailure(error);
            }
            send(exchange, 200, result);
        } catch (XmageBattleService.UnsupportedCardsException error) {
            finishLive(liveRegistry, request, "coverage_error", "xmage_coverage_incomplete");
            Map<String, Object> body = errorBody("xmage_coverage_incomplete", error.getMessage());
            body.put("unsupported_cards", error.getUnsupportedCards());
            body.putAll(requestMetadata(battleService, request, "coverage_incomplete"));
            send(exchange, 422, body);
        } catch (IllegalArgumentException error) {
            finishLive(liveRegistry, request, "engine_error", "invalid_request");
            send(exchange, 400, errorBody("invalid_request", error.getMessage()));
        } catch (TimeoutException error) {
            finishLive(liveRegistry, request, "timeout", "simulation_timeout");
            if (simulation != null) {
                simulation.cancel(true);
            }
            try {
                Map<String, Object> body = errorBody("simulation_timeout", error.getMessage());
                body.put("restart_required", true);
                body.putAll(requestMetadata(battleService, request, "timeout"));
                send(exchange, 504, body);
            } finally {
                restartAfterTimeout();
            }
        } catch (Exception error) {
            finishLive(liveRegistry, request, "engine_error", "simulation_failed");
            error.printStackTrace(System.err);
            Map<String, Object> body = errorBody("simulation_failed", error.getMessage());
            body.putAll(requestMetadata(battleService, request, "failed"));
            send(exchange, 500, body);
        }
    }

    private static void handleLive(
            HttpExchange exchange,
            BattleLiveRegistry liveRegistry
    ) throws IOException {
        exchange.getResponseHeaders().set("Cache-Control", "no-store");
        exchange.getResponseHeaders().set("X-Content-Type-Options", "nosniff");
        if (!"GET".equals(exchange.getRequestMethod())) {
            send(exchange, 405, singleton("error", "method_not_allowed"));
            return;
        }
        String path = exchange.getRequestURI().getPath();
        String requestId = path.startsWith("/live/") ? path.substring("/live/".length()) : "";
        if (!BattleLiveRegistry.isRequestId(requestId)) {
            send(exchange, 404, singleton("error", "live_stream_not_found"));
            return;
        }
        int afterSequence = -1;
        int limit = 200;
        try {
            Map<String, String> query = parseLiveQuery(exchange.getRequestURI().getRawQuery());
            if (query.containsKey("after")) {
                afterSequence = Integer.parseInt(query.get("after"));
            }
            if (query.containsKey("limit")) {
                limit = Integer.parseInt(query.get("limit"));
            }
        } catch (IllegalArgumentException error) {
            send(exchange, 400, singleton("error", "invalid_live_page"));
            return;
        }
        Map<String, Object> body;
        try {
            body = liveRegistry.read(requestId, afterSequence, limit);
        } catch (IllegalArgumentException error) {
            send(exchange, 400, singleton("error", "invalid_live_page"));
            return;
        }
        if (body == null) {
            send(exchange, 404, singleton("error", "live_stream_not_found"));
            return;
        }
        send(exchange, 200, body);
    }

    private static Map<String, String> parseLiveQuery(String rawQuery) {
        Map<String, String> result = new LinkedHashMap<>();
        if (rawQuery == null || rawQuery.isEmpty()) {
            return result;
        }
        for (String part : rawQuery.split("&")) {
            int separator = part.indexOf('=');
            if (separator <= 0 || separator == part.length() - 1) {
                throw new IllegalArgumentException("invalid Live query");
            }
            String key = part.substring(0, separator);
            String value = part.substring(separator + 1);
            if (!"after".equals(key) && !"limit".equals(key)) {
                throw new IllegalArgumentException("unknown Live query");
            }
            if (result.put(key, value) != null) {
                throw new IllegalArgumentException("duplicate Live query");
            }
        }
        return result;
    }

    private static void finishLive(
            BattleLiveRegistry liveRegistry,
            JsonObject request,
            String status,
            String reason
    ) {
        if (request == null
                || !request.has("request_id")
                || request.get("request_id").isJsonNull()
                || !request.get("request_id").isJsonPrimitive()
                || !request.get("request_id").getAsJsonPrimitive().isString()) {
            return;
        }
        liveRegistry.finish(request.get("request_id").getAsString(), status, reason);
    }

    static long simulationTimeoutMillis(JsonObject request) {
        long requested = request.has("timeout_ms") && !request.get("timeout_ms").isJsonNull()
                ? request.get("timeout_ms").getAsLong()
                : DEFAULT_SIMULATION_TIMEOUT_MS;
        return Math.max(MIN_SIMULATION_TIMEOUT_MS, Math.min(requested, MAX_SIMULATION_TIMEOUT_MS));
    }

    private static Exception unwrapSimulationFailure(ExecutionException error) {
        Throwable cause = error.getCause();
        if (cause instanceof Exception) {
            return (Exception) cause;
        }
        if (cause instanceof Error) {
            throw (Error) cause;
        }
        return error;
    }

    private static void restartAfterTimeout() {
        if (!RESTART_SCHEDULED.compareAndSet(false, true)) {
            return;
        }
        Thread restart = new Thread(() -> {
            try {
                Thread.sleep(1000L);
            } catch (InterruptedException ignored) {
                Thread.currentThread().interrupt();
            }
            System.err.println("Restarting XMage sidecar after simulation timeout");
            System.exit(70);
        }, "xmage-timeout-restart");
        restart.setDaemon(false);
        restart.start();
    }

    private static void handleCoverage(HttpExchange exchange, XmageBattleService battleService)
            throws IOException {
        if (!"POST".equals(exchange.getRequestMethod())) {
            send(exchange, 405, singleton("error", "method_not_allowed"));
            return;
        }

        try {
            JsonObject request = JsonParser.parseString(readBody(exchange)).getAsJsonObject();
            send(exchange, 200, battleService.coverage(request));
        } catch (IllegalArgumentException error) {
            send(exchange, 400, errorBody("invalid_request", error.getMessage()));
        } catch (Exception error) {
            error.printStackTrace(System.err);
            send(exchange, 500, errorBody("coverage_failed", error.getMessage()));
        }
    }

    private static void handleCardCoverage(HttpExchange exchange, XmageBattleService battleService)
            throws IOException {
        if (!"POST".equals(exchange.getRequestMethod())) {
            send(exchange, 405, singleton("error", "method_not_allowed"));
            return;
        }

        try {
            JsonObject request = JsonParser.parseString(readBody(exchange)).getAsJsonObject();
            send(exchange, 200, battleService.cardCoverage(request));
        } catch (IllegalArgumentException error) {
            send(exchange, 400, errorBody("invalid_request", error.getMessage()));
        } catch (Exception error) {
            error.printStackTrace(System.err);
            send(exchange, 500, errorBody("coverage_failed", error.getMessage()));
        }
    }

    private static String readBody(HttpExchange exchange) throws IOException {
        try (InputStream input = exchange.getRequestBody();
             ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            byte[] buffer = new byte[8192];
            int total = 0;
            int read;
            while ((read = input.read(buffer)) >= 0) {
                total += read;
                if (total > MAX_REQUEST_BYTES) {
                    throw new IllegalArgumentException("request body exceeds 8 MiB");
                }
                output.write(buffer, 0, read);
            }
            return new String(output.toByteArray(), StandardCharsets.UTF_8);
        }
    }

    private static void send(HttpExchange exchange, int status, Object body) throws IOException {
        byte[] payload = GSON.toJson(withProcessMetadata(body)).getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", "application/json; charset=utf-8");
        exchange.sendResponseHeaders(status, payload.length);
        try (OutputStream output = exchange.getResponseBody()) {
            output.write(payload);
        }
    }

    @SuppressWarnings("unchecked")
    private static Object withProcessMetadata(Object body) {
        if (!(body instanceof Map)) {
            return body;
        }
        Map<String, Object> result = new LinkedHashMap<>((Map<String, Object>) body);
        result.put("schema_version", EXECUTION_SCHEMA);
        result.put("engine", "xmage");
        result.put("engine_version", XMAGE_VERSION);
        result.put("engine_commit", XMAGE_COMMIT);
        result.put("sidecar_protocol_version", SIDECAR_PROTOCOL);
        result.put("sidecar_build_identity", BUILD_IDENTITY);
        result.put("sidecar_process_id", PROCESS_ID);
        result.put("sidecar_started_at", STARTED_AT);
        result.put("ai_profile", AI_PROFILE);
        result.put("normalizer_version", ReplayNormalizer.VERSION);
        result.put("seed_semantics", SEED_SEMANTICS);
        result.put("deterministic", false);
        result.putIfAbsent("fallback_reason", "none");
        return result;
    }

    private static Map<String, Object> requestMetadata(
            XmageBattleService battleService,
            JsonObject request,
            String status
    ) {
        if (request == null) {
            return new LinkedHashMap<>();
        }
        try {
            return battleService.requestMetadata(request, status);
        } catch (RuntimeException ignored) {
            return new LinkedHashMap<>();
        }
    }

    private static Map<String, Object> errorBody(String code, String message) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("error", code);
        body.put("message", message == null ? code : message);
        return body;
    }

    private static Map<String, Object> singleton(String key, Object value) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put(key, value);
        return result;
    }

    private static String env(String name, String fallback) {
        String value = System.getenv(name);
        return value == null || value.trim().isEmpty() ? fallback : value.trim();
    }

    private static int envInt(String name, int fallback) {
        try {
            return Integer.parseInt(env(name, Integer.toString(fallback)));
        } catch (NumberFormatException ignored) {
            return fallback;
        }
    }
}
