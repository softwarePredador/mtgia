# Relatorio Final Regression ManaLoom — 2026-05-04

## Resultado geral

**PASS com scanner fisico NOT PROVEN.** Backend offline, backend live, app analyze/test e runtimes iPhone 15 solicitados passaram contra backend local real em `http://127.0.0.1:8082`. Scanner fisico/camera nao foi executado nesta rodada e fica explicitamente `NOT PROVEN`, sem mascarar como PASS por testes controlados/simulador.

## Ambiente

| Item | Valor |
|---|---|
| Branch | `master` |
| Janela | `2026-05-04T13:38-03:00` a `2026-05-04T13:55-03:00` |
| Backend local | `PORT=8082 dart run .dart_frog/server.dart` |
| App backend URL | `http://127.0.0.1:8082` via `API_BASE_URL` e `PUBLIC_API_BASE_URL` |
| iPhone 15 Simulator | `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF` |
| iOS runtime | `com.apple.CoreSimulator.SimRuntime.iOS-17-4` |
| Backend PID observado | `7167` |

## Device discovery

`flutter devices` confirmou:

```text
iPhone 15 (mobile) • F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF • ios • com.apple.CoreSimulator.SimRuntime.iOS-17-4 (simulator)
macOS (desktop) • macos • darwin-arm64
Chrome (web) • chrome • web-javascript
Rafa (wireless) (mobile) • 00008130-001C152922BA001C • ios • iOS 26.5 23F5043k
```

`xcrun simctl list devices available | grep -E "iPhone 15|Booted"` confirmou:

```text
iPhone 15 Pro (F3C5B123-673F-4ACC-84B2-489957CB81C8) (Shutdown)
iPhone 15 Pro Max (DABB9D79-2FDB-4585-94DB-E31F1288EE74) (Shutdown)
iPhone 15 (F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF) (Booted)
iPhone 15 Plus (6A3E5508-0190-48AC-B6D1-E4BA8A94FFD9) (Shutdown)
```

## Backend health

Command:

```bash
curl -sS http://127.0.0.1:8082/health
```

Result:

```json
{"status":"healthy","service":"mtgia-server","timestamp":"2026-05-04T13:38:55.431347","environment":"development","version":"1.0.0","git_sha":null,"checks":{"process":{"status":"healthy"}}}
```

## Command matrix

| Area | Command | Result |
|---|---|---|
| Initial repo/device discovery | `git status --short && flutter devices && xcrun simctl list devices available \| grep -E "iPhone 15\|Booted"` | PASS; branch `master`, iPhone 15 booted. |
| Backend start | `cd server && PORT=8082 dart run .dart_frog/server.dart` | PASS; backend served `/health` on 8082. |
| Backend offline | `cd server && dart analyze lib routes bin test && dart test -r expanded` | PASS; analyze no issues, `00:04 +558: All tests passed!`. |
| Backend live | `cd server && TEST_API_BASE_URL=http://127.0.0.1:8082 dart test -P live -r expanded` | PASS; `02:49 +167 ~3: All tests passed!`. |
| App analyze/test | `cd app && flutter analyze lib test integration_test --no-version-check && flutter test test --no-version-check` | PASS; analyze no issues, `00:41 +530: All tests passed!`. |
| Sets/Search runtime | `cd app && flutter test integration_test/sets_search_catalog_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check` | PASS; `/cards`, `/sets`, `/cards?set=ECC` returned 200; `00:25 +1`. |
| Deck runtime | `cd app && flutter test integration_test/deck_runtime_m2006_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check` | PASS; `01:24 +1`, final screenshot `10_complete_validated`. |
| Binder dashboard runtime | `cd app && flutter test integration_test/binder_dashboard_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check` | PASS; binder CRUD/stats returned 200/201/204; `00:37 +1`. |
| Marketplace/trades runtime | `cd app && flutter test integration_test/binder_marketplace_trade_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check` | PASS; marketplace, trade lifecycle, messages and notifications returned 200/201/204; `01:47 +2`. |
| Life Counter/Lotus runtime | `cd app && flutter test integration_test/life_counter_lotus_visual_runtime_proof_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check` | PASS; Lotus ready/reopen probes passed; `00:29 +1`. |

## PASS / FAIL / NOT PROVEN por area

| Area | Status | Evidencia |
|---|---|---|
| Backend offline | PASS | Analyze sem issues; 558 testes offline passaram. |
| Backend live app-facing | PASS | Profile live passou com 167 testes e 3 skips declarados. |
| AI generate/optimize/decks | PASS | Live backend e runtime deck no iPhone 15 completaram preview/apply/validate. |
| Deck details/runtime navigation | PASS | `deck_runtime_m2006_test.dart` chegou a `10_complete_validated`. |
| Search cards | PASS | Runtime Sets/Search buscou `Black Lotus` por `/cards` com 200. |
| Sets/Colecoes | PASS | Runtime Sets/Search abriu detalhe via `/sets` e `/cards?set=ECC`, ambos 200. |
| Binder dashboard | PASS | CRUD/stats reais em `/binder` e `/binder/stats` com 200/201/204. |
| Marketplace/trades | PASS | Marketplace, proposta, aceite, status, mensagens, notificacoes e direct messages passaram. |
| Life Counter/Lotus | PASS | Probes WebView/JS e screenshots `life_counter_lotus_runtime_initial/after_plus` passaram. |
| Scanner controlado | PASS indireto | Testes app unitarios/controlados de scanner passaram dentro de `flutter test test`; nao e prova fisica. |
| Scanner fisico/camera | NOT PROVEN | Nenhum runtime fisico com camera/OCR foi executado nesta rodada. iPhone 15 Simulator nao prova camera fisica. |
| Sentry/log visibility | PASS com observacao | Backend inicializou Sentry sem expor DSN; nao houve evento de erro runtime capturado nos paths PASS. |

## Erros, avisos e riscos observados

- Nenhum 4xx/5xx, timeout, overflow ou crash permaneceu nos runtimes iPhone 15 aprovados.
- `flutter test test` inclui logs esperados de testes unitarios que simulam 401/403/404/500 para validar tratamento de erro; esses eventos nao sao regressao runtime.
- Os runtimes iOS emitiram aviso local de Xcode sobre targets/pods sem suporte `arm64` para simuladores Apple Silicon iOS 26+. O iPhone 15 iOS 17.4 buildou e os testes passaram; manter como risco ambiental se a maquina migrar exclusivamente para simuladores iOS 26+.
- Firebase Performance avisou que nao ha Firebase default app inicializado na sessao de integration test; metricas HTTP foram desativadas, mas o fluxo runtime passou.
- Scanner fisico permanece pendente porque nao houve captura real por camera fisica nesta rodada.

## Evidencias

- Handoff deck iPhone 15: `app/doc/runtime_flow_handoffs/deck_runtime_iphone15_simulator_2026-05-04.md`.
- Proof folder local ignorado: `app/doc/runtime_flow_proofs_2026-05-04_iphone15_simulator/`.
- Logs persistidos localmente no proof folder:
  - `backend_offline_analyze_test.log`
  - `backend_live_test.log`
  - `app_analyze_test.log`
  - `deck_runtime_m2006_iphone15.log`
  - `life_counter_lotus_visual_runtime.log`
- Screenshots persistidos localmente no proof folder:
  - `01_login.png` a `10_complete_validated.png`
  - `life_counter_lotus_runtime_initial.png`
  - `life_counter_lotus_runtime_after_plus.png`

## Pendencias

1. Executar scanner fisico com camera/OCR em device fisico desbloqueado e registrar como prova propria, sem reutilizar o PASS do simulador.
2. Se Xcode/iOS runtime for atualizado para iOS 26+ Simulator, revisar pods/plugins listados no warning de `arm64` antes de tratar falha de build como regressao app.

## Encerramento

Backend 8082 foi encerrado ao final da rodada com `kill 7167`; `lsof -nP -iTCP:8082 -sTCP:LISTEN` nao retornou listener.
