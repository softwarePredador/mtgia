package com.manaloom.xmage;

import mage.interfaces.MageClient;
import mage.interfaces.callback.ClientCallback;
import mage.remote.Session;
import mage.utils.MageVersion;
import mage.view.ChatMessage;
import mage.view.GameClientMessage;
import mage.view.GameEndView;
import mage.view.GameView;
import mage.view.TableClientMessage;
import org.jsoup.Jsoup;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

final class TrackingMageClient implements MageClient {
    private static final MageVersion VERSION = new MageVersion(MageClient.class);

    private final List<GameView> views = Collections.synchronizedList(new ArrayList<GameView>());
    private final List<Map<String, Object>> messages =
            Collections.synchronizedList(new ArrayList<Map<String, Object>>());
    private volatile Session session;
    private volatile UUID gameId;
    private volatile GameView lastView;
    private volatile boolean gameOver;
    private volatile boolean won;
    private volatile String lastFingerprint = "";

    void setSession(Session session) {
        this.session = session;
    }

    GameView getLastView() {
        return lastView;
    }

    boolean isGameOver() {
        return gameOver;
    }

    boolean hasWon() {
        return won;
    }

    List<GameView> copyViews() {
        synchronized (views) {
            return new ArrayList<>(views);
        }
    }

    List<Map<String, Object>> copyMessages() {
        synchronized (messages) {
            return new ArrayList<>(messages);
        }
    }

    @Override
    public MageVersion getVersion() {
        return VERSION;
    }

    @Override
    public void connected(String message) {
    }

    @Override
    public void disconnected(boolean askToReconnect, boolean keepMySessionActive) {
    }

    @Override
    public void showMessage(String message) {
        addMessage("client_message", message, null, null);
    }

    @Override
    public void showError(String message) {
        addMessage("client_error", message, null, null);
    }

    @Override
    public void onNewConnection() {
    }

    @Override
    public void onCallback(ClientCallback callback) {
        try {
            callback.decompressData();
            switch (callback.getMethod()) {
                case GAME_INIT:
                    gameId = callback.getObjectId();
                    break;
                case START_GAME:
                    TableClientMessage start = (TableClientMessage) callback.getData();
                    gameId = start.getGameId();
                    if (session != null) {
                        session.joinGame(gameId);
                    }
                    break;
                case GAME_UPDATE:
                    recordView((GameView) callback.getData());
                    break;
                case GAME_UPDATE_AND_INFORM:
                case GAME_INFORM_PERSONAL:
                    recordGameMessage(callback.getMethod().name(), (GameClientMessage) callback.getData());
                    break;
                case CHATMESSAGE:
                    ChatMessage chat = (ChatMessage) callback.getData();
                    addMessage("chat", Jsoup.parse(chat.getMessage()).text(), null, null);
                    break;
                case GAME_ERROR:
                case SERVER_MESSAGE:
                case SHOW_USERMESSAGE:
                    addMessage(callback.getMethod().name().toLowerCase(), String.valueOf(callback.getData()), null, null);
                    break;
                case END_GAME_INFO:
                    GameEndView result = (GameEndView) callback.getData();
                    won = result.hasWon();
                    break;
                case GAME_OVER:
                    gameOver = true;
                    break;
                default:
                    break;
            }
        } catch (Throwable error) {
            addMessage("callback_error", error.toString(), null, null);
        }
    }

    private void recordGameMessage(String kind, GameClientMessage message) {
        if (message == null) {
            return;
        }
        recordView(message.getGameView());
        addMessage(kind.toLowerCase(), message.getMessage(), message.getTargets(), message.getGameView());
    }

    private void recordView(GameView view) {
        if (view == null) {
            return;
        }
        lastView = view;
        String fingerprint = ReplayNormalizer.fingerprint(view);
        if (!fingerprint.equals(lastFingerprint)) {
            lastFingerprint = fingerprint;
            views.add(view);
        }
    }

    private void addMessage(String kind, String message, Set<UUID> targets, GameView view) {
        if (message == null || message.trim().isEmpty()) {
            return;
        }
        GameView context = view == null ? lastView : view;
        Map<String, Object> event = new LinkedHashMap<>();
        event.put("action", kind);
        event.put("message", message);
        if (context != null) {
            event.put("turn", context.getTurn());
            event.put("phase", context.getPhase() == null ? null : context.getPhase().toString());
            event.put("step", context.getStep() == null ? null : context.getStep().toString());
            event.put("active_player", context.getActivePlayerName());
        }
        if (targets != null && !targets.isEmpty()) {
            List<String> targetIds = new ArrayList<>();
            for (UUID target : targets) {
                targetIds.add(target.toString());
            }
            event.put("target_ids", targetIds);
        }
        messages.add(event);
    }
}
