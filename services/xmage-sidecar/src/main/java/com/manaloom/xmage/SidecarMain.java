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
import java.util.concurrent.Executors;
import java.util.concurrent.TimeoutException;

public final class SidecarMain {
    static final String XMAGE_COMMIT = "34d81ea4995ce15d7e1a788dc6d2a3595d35bcec";
    static final String XMAGE_VERSION = "1.4.60";

    private static final Gson GSON = new Gson();
    private static final int MAX_REQUEST_BYTES = 2 * 1024 * 1024;

    private SidecarMain() {
    }

    public static void main(String[] args) throws Exception {
        String xmageHost = env("XMAGE_SERVER_HOST", "127.0.0.1");
        int xmagePort = envInt("XMAGE_SERVER_PORT", 17171);
        int httpPort = envInt("PORT", 8080);
        XmageBattleService battleService = new XmageBattleService(xmageHost, xmagePort);

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
            send(exchange, 200, body);
        });
        server.createContext("/cards/coverage", exchange -> handleCardCoverage(exchange, battleService));
        server.createContext("/coverage", exchange -> handleCoverage(exchange, battleService));
        server.createContext("/simulate", exchange -> handleSimulation(exchange, battleService));
        server.setExecutor(Executors.newFixedThreadPool(4));
        server.start();
        System.out.println("ManaLoom XMage sidecar listening on port " + httpPort);
    }

    private static void handleSimulation(HttpExchange exchange, XmageBattleService battleService)
            throws IOException {
        if (!"POST".equals(exchange.getRequestMethod())) {
            send(exchange, 405, singleton("error", "method_not_allowed"));
            return;
        }

        try {
            JsonObject request = JsonParser.parseString(readBody(exchange)).getAsJsonObject();
            send(exchange, 200, battleService.simulate(request));
        } catch (XmageBattleService.UnsupportedCardsException error) {
            Map<String, Object> body = errorBody("xmage_coverage_incomplete", error.getMessage());
            body.put("unsupported_cards", error.getUnsupportedCards());
            send(exchange, 422, body);
        } catch (IllegalArgumentException error) {
            send(exchange, 400, errorBody("invalid_request", error.getMessage()));
        } catch (TimeoutException error) {
            send(exchange, 504, errorBody("simulation_timeout", error.getMessage()));
        } catch (Exception error) {
            error.printStackTrace(System.err);
            send(exchange, 500, errorBody("simulation_failed", error.getMessage()));
        }
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
                    throw new IllegalArgumentException("request body exceeds 2 MiB");
                }
                output.write(buffer, 0, read);
            }
            return new String(output.toByteArray(), StandardCharsets.UTF_8);
        }
    }

    private static void send(HttpExchange exchange, int status, Object body) throws IOException {
        byte[] payload = GSON.toJson(body).getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", "application/json; charset=utf-8");
        exchange.sendResponseHeaders(status, payload.length);
        try (OutputStream output = exchange.getResponseBody()) {
            output.write(payload);
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
