# iPhone 15 Simulator Runtime Handoff - Realtime Notifications

## Status

Verdict: `PASS WITH RISKS`

## Runtime Environment

- Date/time: `2026-05-11 09:03 -03`
- Simulator: `iPhone 15`
- Simulator id: `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`
- Runtime: `com.apple.CoreSimulator.SimRuntime.iOS-17-4`
- Backend URL used by app: `http://127.0.0.1:8081`
- Backend health: `{"status":"healthy","service":"mtgia-server","environment":"development"}`

## Device Discovery Summary

`flutter devices` listed:

- `iPhone 15 (mobile) • F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF • ios • com.apple.CoreSimulator.SimRuntime.iOS-17-4 (simulator)`
- `macOS`
- `Chrome`

`xcrun simctl list devices available | grep -E "iPhone 15|Booted"` listed:

- `iPhone 15 (F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF) (Booted)`
- other iPhone 15 family simulators available but shutdown.

## Commands Executed

Backend:

```bash
cd server
PORT=8081 dart run .dart_frog/server.dart
curl -sS http://127.0.0.1:8081/health
```

Runtime:

```bash
cd app
flutter test integration_test/realtime_notifications_runtime_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8081 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8081 \
  --dart-define=DISABLE_PUSH_INIT=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded \
  --no-version-check
```

Result: `00:37 +1: All tests passed!`

Server live notification contracts:

```bash
cd server
TEST_API_BASE_URL=http://127.0.0.1:8081 dart test -P live test/social_trading_live_test.dart --reporter expanded
```

Result: `03:01 +169 ~3: All tests passed!`

## Scope Proven

Real device/UI/backend:

- iPhone 15 Simulator executed a Flutter integration test against the live local
  Dart Frog backend on `127.0.0.1:8081`.
- Two QA users were registered through the backend.
- User B stayed in `NotificationScreen`; user A sent a direct message.
- Simulated foreground FCM payload `direct_message` with real `conversationId`
  refreshed notification badge/list without leaving the screen.
- Simulated FCM tap navigated to `/messages/:conversationId`; the chat loaded
  the real backend message and marked it read.
- User B stayed in `TradeDetailScreen`; user A accepted and shipped a sale trade.
- Simulated foreground FCM payloads `trade_accepted` and `trade_shipped`
  refreshed the active trade detail to `Aceito` and `Enviado`; provider timeline
  contained `shipped`.

Mocked/controlled:

- Real APNs/FCM delivery was not used. The runtime injects the same payload shape
  (`type`, `reference_id`) into `RealtimeNotificationCoordinator` to prove the
  app-side foreground/tap behavior deterministically.
- `DISABLE_PUSH_INIT=true` and `DISABLE_FIREBASE_PERFORMANCE_INIT=true` were used
  to isolate native Firebase startup from the app-side realtime contract.

## Observations

- No crash, modal stuck state, raw 4xx/5xx copy, timeout failure or overflow was
  observed in the final passing runtime.
- Xcode printed the known Apple Silicon/iOS simulator warning about several
  plugins not declaring arm64 simulator support, but the build completed and the
  test passed.
- Screenshots were not captured for this run; evidence is the expanded Flutter
  test output and backend/live test output in the session logs.

## Blockers / Risks

- Real APNs/FCM delivery remains environment-dependent and was not proven on this
  simulator run.
- System app-icon badge semantics are best-effort through FCM; the proven badge
  contract here is the in-app notification/message badge and contextual lists.

## Smallest Next Actions

1. Run the same app-side flow with real FCM delivery after APNs/Firebase
   provisioning is available.
2. Add screenshot capture checkpoints if visual artifact proof is required in a
   later QA pass.
