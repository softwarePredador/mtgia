# Marketplace / Trades Trust Intelligence Runtime - iPhone 15 Simulator - 2026-05-04

## Target

- iPhone 15 Simulator -> Marketplace -> item com referencia/tendencia/confianca -> criar proposta -> revisar desequilibrio -> seller aceitar/enviar -> buyer confirmar entrega/finalizar -> timeline/mensagens/notificacoes.

## Runtime Owner

Agent: `GitHub Copilot CLI`

## Fix Owner

Agent: `GitHub Copilot CLI`

## Status

Verdict: `PASS`

## Runtime Environment

| Item | Valor |
| --- | --- |
| Date | `2026-05-04` |
| Device type | `iPhone 15 Simulator` |
| Device id | `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF` |
| Runtime | `com.apple.CoreSimulator.SimRuntime.iOS-17-4` |
| Backend target | `http://127.0.0.1:8082` |
| Backend command | `cd server && PORT=8082 dart run .dart_frog/server.dart` |
| Health | `{"status":"healthy","service":"mtgia-server","environment":"development","version":"1.0.0","checks":{"process":{"status":"healthy"}}}` |
| Launch command | `cd app && flutter test integration_test/binder_marketplace_trade_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check` |

## Account Used

Identifier: generated QA users with marker prefix `qa_bmt_*` and `qa_dm_*`.

How it was created: runtime harness registers/authenticates test users through the real local backend and creates binder/trade/message data through API calls.

## Navigation Path

1. Login as buyer.
2. Open binder setup path and ensure buyer inventory can support the trade flow.
3. Open Marketplace and search `Sol Ring`.
4. Assert marketplace item shows internal reference copy, insufficient trend history copy, owner/trust signals and seller identity.
5. Tap `Quero comprar`, review proposal, fill trade-scoped message and submit.
6. Login as seller, open trade detail, accept, send message, mark as shipped.
7. Login as buyer, open trade detail, confirm delivery and finalize.
8. Assert completed status, trade messages context and notifications.

## Evidence

Fresh evidence captured this round: Yes.

- Runtime result: `01:45 +2: All tests passed!`.
- Backend health: healthy on `http://127.0.0.1:8082`.
- Internal API probes: PASS for `/community/marketplace`, `/trades`, `/trades/:id`, `/trades/:id/messages`.
- Runtime trade id sample: `5ddbf073-c6df-4e55-98a7-9511cc38468e`.
- External runtime calls from mobile: none added; app consumed only configured backend URL.

## Observed Result

Marketplace loaded real internal items and displayed price/trust intelligence without external mobile calls. Trade proposal creation, value imbalance review, seller acceptance/shipping, buyer delivery/finalization, timeline, trade-scoped messages and notifications completed against the backend on port `8082`.

## Stop Point

None. Flow completed.

## Findings

### Finding 1 - Apple Silicon simulator architecture warning

Severity: `informational`

Area: `iOS simulator tooling`

Problem: Flutter/Xcode printed the existing warning that several plugins do not support arm64 for Apple Silicon iOS 26+ simulators.

Evidence: warning appears before build, but iPhone 15 iOS 17.4 build and runtime completed.

Likely owner: platform/tooling.

Likely file/module: iOS pods/plugins, not this sprint.

Smallest next action: keep monitoring when upgrading simulator runtime to iOS 26+.

## Commands Run

```bash
cd server && dart analyze routes/market routes/trades routes/community routes/users lib test
cd server && dart test -r expanded
cd server && PORT=8082 dart run .dart_frog/server.dart
curl -s http://127.0.0.1:8082/health
```

```bash
cd app && flutter analyze lib/features/market lib/features/trades lib/features/binder lib/features/profile test/features/market test/features/trades test/features/binder --no-version-check
cd app && flutter test test/features/market test/features/trades test/features/binder --no-version-check
cd app && flutter analyze integration_test/binder_marketplace_trade_runtime_test.dart --no-version-check
cd app && flutter test integration_test/binder_marketplace_trade_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check
```

## Validation Notes

- Simulator validated: `PASS`.
- Physical device validated: `not required/not proven`; Android sanity is non-blocking for this sprint.
- Marketplace trust/price trend reached: `PASS`.
- Trade imbalance reached: `PASS`.
- Trade lifecycle completed: `PASS`.
- Backend mocked: `No`.
- Mobile external price APIs: `No`.

## Reproduction Notes For Fix Agent

Start backend on `8082`, keep iPhone 15 Simulator booted, then run the integration command above. The harness creates isolated QA users and data, so no manual seed is required.
