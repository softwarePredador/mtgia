# Deck Runtime iPhone 15 Simulator - 2026-04-29

## Resultado

Verdict: `Approved for audited runtime paths / broader social-trade-message flows not proven`.

Quatro integration tests principais passaram no iPhone 15 Simulator com backend local real em `http://127.0.0.1:8082`. O fluxo de deck Commander cobriu register/auth, Home, deck, optimize, preview/apply e validate. O runtime encontrou uma pendencia nao fatal: `GET /market/movers?limit=5&min_price=1.0` excedeu timeout de 15s durante o fluxo e tambem ficou pendurado em probe isolado por mais de 60s.

## Data/hora

- Inicio da auditoria: `2026-04-29T09:38:49-03:00`
- Evidencia final de health: `2026-04-29 09:52:11 -0300`

## Simulator

```text
iPhone 15 (mobile) • F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF • ios • com.apple.CoreSimulator.SimRuntime.iOS-17-4 (simulator)
```

`xcrun simctl list devices available | grep -E "iPhone 15|Booted"`:

```text
iPhone 15 Pro (F3C5B123-673F-4ACC-84B2-489957CB81C8) (Shutdown)
iPhone 15 Pro Max (DABB9D79-2FDB-4585-94DB-E31F1288EE74) (Shutdown)
iPhone 15 (F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF) (Booted)
iPhone 15 Plus (6A3E5508-0190-48AC-B6D1-E4BA8A94FFD9) (Shutdown)
```

## Backend

- URL usada pelo app: `http://127.0.0.1:8082`
- Comando: `cd server && PORT=8082 dart run .dart_frog/server.dart`
- Health:

```json
{"status":"healthy","service":"mtgia-server","timestamp":"2026-04-29T09:52:11.753065","environment":"development","version":"1.0.0","git_sha":null,"checks":{"process":{"status":"healthy"}}}
```

## Comandos exatos de runtime

```bash
cd app
flutter test integration_test/sets_catalog_runtime_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --reporter expanded \
  --no-version-check

flutter test integration_test/sets_search_catalog_runtime_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --reporter expanded \
  --no-version-check

flutter test integration_test/collection_entrypoints_runtime_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --reporter expanded \
  --no-version-check

flutter test integration_test/deck_runtime_m2006_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --reporter expanded \
  --no-version-check
```

## Resultado por teste

| Test | Resultado | Log |
| --- | --- | --- |
| `sets_catalog_runtime_test.dart` | Passou, `All tests passed`, exit 0 | `app/doc/runtime_flow_proofs_2026-04-29_iphone15_simulator_audit/sets_catalog_runtime_test.log` |
| `sets_search_catalog_runtime_test.dart` | Passou, `All tests passed`, exit 0 | `app/doc/runtime_flow_proofs_2026-04-29_iphone15_simulator_audit/sets_search_catalog_runtime_test.log` |
| `collection_entrypoints_runtime_test.dart` | Passou, `All tests passed`, exit 0 | `app/doc/runtime_flow_proofs_2026-04-29_iphone15_simulator_audit/collection_entrypoints_runtime_test.log` |
| `deck_runtime_m2006_test.dart` | Passou, `All tests passed`, exit 0 | `app/doc/runtime_flow_proofs_2026-04-29_iphone15_simulator_audit/deck_runtime_m2006_test.log` |

## O que foi real

- iPhone 15 Simulator real (`F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`).
- Flutter app real instalado/executado via `flutter test -d "iPhone 15"`.
- Backend Dart Frog real local em `PORT=8082`.
- API real via `API_BASE_URL=http://127.0.0.1:8082` e `PUBLIC_API_BASE_URL=http://127.0.0.1:8082`.
- Fluxos de UI automatizados para Sets, Search, Collection entrypoints e Deck Runtime.

## O que foi mockado/controlado

- Nenhum mock de API foi usado nos quatro integration tests listados.
- Scanner camera/OCR real nao foi exercitado neste handoff; usar `app/doc/runtime_flow_handoffs/scanner_runtime_2026-04-29.md` para a prova controlada de OCR parser/provider/backend fallback.
- Alguns testes podem usar dados/fixtures internos do proprio harness para criar usuario/deck, mas as chamadas HTTP foram contra backend real.

## Blockers e pendencias

| Severidade | Pendencia | Evidencia | Owner |
| --- | --- | --- | --- |
| P0/P1 | `/market/movers` lento/hung | Runtime: `TimeoutException after 0:00:15`; probe isolado `curl` pendurado >60s | Backend market/performance |
| P1 | Social/trades/messages/notifications completos nao provados | Apenas entrypoints de Collection/Trades sem crash foram cobertos | App QA + backend contracts |
| P1 | Scanner camera/OCR real not proven | Simulador nao prova camera fisica; handoff scanner cobre harness controlado | Mobile runtime/device QA |
| P2 | Test name `deck_runtime_m2006_test.dart` confunde prova iPhone 15 | O test rodou no iPhone 15, mas nome ainda remete a Android M2006 | App test maintenance |

## Smallest next actions

1. Corrigir/otimizar `GET /market/movers?limit=5&min_price=1.0` e adicionar budget de latencia.
2. Criar runtime iPhone 15 dedicado para Binder CRUD, Marketplace -> Trade, Messages e Notifications.
3. Renomear ou duplicar o harness `deck_runtime_m2006_test.dart` para nome neutro de runtime Commander.
4. Provar scanner camera/OCR em device fisico com permissao/carta controlada.

