# Relatorio Pre-Release QA ManaLoom — 2026-05-04

## Resultado go/no-go

**PASS WITH RISKS.** Os fluxos core pre-release passaram no iPhone 15 Simulator contra backend local real em `http://127.0.0.1:8082`. Scanner fisico/camera/OCR ficou explicitamente **DEFERRED / NOT PROVEN** e nao deve ser considerado aprovado por simulador.

## Ambiente e devices

| Item | Valor |
|---|---|
| Branch alvo | `master` |
| Janela | `2026-05-04T14:56-03:00` a `2026-05-04T15:29-03:00` |
| Backend temporario | `cd server && PORT=8082 dart run .dart_frog/server.dart` |
| Backend URL usado pelo app | `http://127.0.0.1:8082` via `API_BASE_URL` e `PUBLIC_API_BASE_URL` |
| Backend health | `{"status":"healthy","service":"mtgia-server","environment":"development","version":"1.0.0"}` |
| iPhone 15 Simulator | `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF` |
| Runtime iOS | `com.apple.CoreSimulator.SimRuntime.iOS-17-4` |
| iPhone fisico detectado | `Rafa (wireless) • 00008130-001C152922BA001C • iOS 26.5 23F5043k` |
| iPhone fisico usado | `NOT PROVEN`; nao foi necessario para fechar os fluxos sem scanner fisico |

Device discovery exigido:

```text
flutter devices:
iPhone 15 (mobile) • F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF • ios • com.apple.CoreSimulator.SimRuntime.iOS-17-4 (simulator)
Rafa (wireless) (mobile) • 00008130-001C152922BA001C • ios • iOS 26.5 23F5043k

xcrun simctl list devices available | grep -E "iPhone 15|Booted":
iPhone 15 Pro (F3C5B123-673F-4ACC-84B2-489957CB81C8) (Shutdown)
iPhone 15 Pro Max (DABB9D79-2FDB-4585-94DB-E31F1288EE74) (Shutdown)
iPhone 15 (F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF) (Booted)
iPhone 15 Plus (6A3E5508-0190-48AC-B6D1-E4BA8A94FFD9) (Shutdown)
```

## Comandos executados

| Area | Comando | Resultado |
|---|---|---|
| Status/devices | `git status --short && flutter devices && xcrun simctl list devices available \| grep -E "iPhone 15\|Booted"` | PASS; iPhone 15 bootado. |
| Backend | `cd server && PORT=8082 dart run .dart_frog/server.dart` + `curl -sS http://127.0.0.1:8082/health` | PASS; health `healthy`. |
| Deck focused tests | `cd app && flutter test test/features/decks/screens/deck_runtime_widget_flow_test.dart test/features/decks/screens/deck_details_screen_smoke_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart --no-version-check` | PASS; `67 passed`. |
| Cards/Colecoes analyze | `cd app && flutter analyze lib/features/cards lib/features/collection test/features/cards test/features/collection --no-version-check` | PASS; no issues. |
| Cards/Colecoes tests | `cd app && flutter test test/features/cards test/features/collection --no-version-check` | PASS; `7 passed`. |
| Sets catalog runtime | `cd app && flutter test integration_test/sets_catalog_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check` | PASS; `00:32 +1`. |
| Search/Sets runtime | `cd app && flutter test integration_test/sets_search_catalog_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check` | PASS; `00:35 +1`. |
| Deck runtime | `cd app && flutter test integration_test/deck_runtime_m2006_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check` | PASS; `01:38 +1`, screenshot final `10_complete_validated`. |
| Binder dashboard runtime | `cd app && flutter test integration_test/binder_dashboard_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check` | PASS; `00:59 +1`. |
| Marketplace/Trades/Messages/Notifications | `cd app && flutter test integration_test/binder_marketplace_trade_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check` | PASS; `01:51 +2`. |
| Life Counter/Lotus | `cd app && flutter test integration_test/life_counter_lotus_visual_runtime_proof_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check` | First attempt failed by concurrent build/DDS; retry PASS `00:27 +1`. |
| Visual P2/P3 proof | `cd app && flutter test integration_test/app_full_non_life_counter_visual_capture_smoke_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check` | Initial stale harness failed; patched labels and retry PASS `01:05 +1`. |
| Patched harness analyze | `cd app && flutter analyze integration_test/app_full_non_life_counter_visual_capture_smoke_test.dart --no-version-check` | PASS; no issues. |
| Performance smoke legado | `cd server && BASE_URL=http://127.0.0.1:8082 dart run bin/qa/performance_smoke.dart` | PASS; revelou latencias altas em deck card writes. |
| Performance p50/p95/p99 | scripts temporarios em `/tmp/mtgia-prerelease-qa/` usando 5 amostras por endpoint | PASS com riscos de performance listados abaixo. |

## PASS / FAIL / NOT PROVEN / DEFERRED por modulo

| Modulo | Status | Evidencia |
|---|---|---|
| Login/Register | PASS | App runtime registrou usuarios QA reais contra `/auth/register` com 201. |
| Search Cards | PASS | `/cards?name=Black+Lotus` e `/cards?name=Sol Ring` retornaram 200. |
| Search -> Cards/Colecoes | PASS | `sets_search_catalog_runtime_test.dart` abriu cards, colecoes e detalhe de set. |
| Colecao -> Colecoes -> Set detail | PASS | `sets_catalog_runtime_test.dart` abriu `MSH`, `OM2`; `/cards?set=...` 200. |
| Deck create/detail/import | PASS | `deck_runtime_m2006_test.dart` criou deck, abriu detalhe e importou comandante. |
| Deck optimize/apply/validate | PASS | `/ai/archetypes`, `/ai/optimize`, polling job e bulk apply chegaram a `10_complete_validated`. |
| AI Generate visual | PASS | `app_full_non_life_counter_visual_capture_smoke_test.dart` capturou `06_generate_preview`; `/ai/generate` 200. |
| Binder dashboard | PASS | `/binder`, `/binder/stats`, add/edit/delete com 200/201/204. |
| Marketplace | PASS | `/community/marketplace` 200 com busca e trust/price surfaces no runtime social. |
| Trades | PASS | Create/respond/status/detail/messages com 200/201 no runtime social. |
| Messages | PASS | Conversations inbox/read/messages/poll com 200/201. |
| Notifications | PASS | List/read/read-all/count com 200. |
| Life Counter/Lotus | PASS | Runtime Lotus abriu/reabriu e screenshots foram extraidas. |
| Scanner fisico/camera/OCR | DEFERRED / NOT PROVEN | Fora do escopo desta rodada; nenhum fluxo de camera/OCR fisico foi executado. |
| iPhone fisico sem scanner | NOT PROVEN | Device fisico estava visivel via wireless, mas simulador cobriu os fluxos sem necessidade de device fisico. |

## Performance p50/p95/p99

Amostras: 5 por endpoint, backend local real `8082`, payloads QA sem dados sensiveis. Os tempos incluem latencia do banco remoto e ambiente local de desenvolvimento.

| Endpoint | Statuses | p50 | p95 | p99 | Classificacao |
|---|---:|---:|---:|---:|---|
| `GET /cards?name=Sol Ring&limit=20` | `200x5` | 561 ms | 1126 ms | 1126 ms | P3: aceitavel com primeiro hit lento. |
| `GET /sets?limit=50&page=1` | `200x5` | 2 ms | 702 ms | 702 ms | PASS; cache/DB aquecido muito rapido. |
| `GET /binder?page=1&limit=20` | `200x5` | 599 ms | 603 ms | 603 ms | PASS. |
| `GET /community/marketplace?search=Sol Ring` | `200x5` | 627 ms | 629 ms | 629 ms | PASS. |
| `GET /trades?page=1&limit=20&role=all` | `200x5` | 602 ms | 602 ms | 602 ms | PASS. |
| `GET /trades/:id` | `200x5` | 1192 ms | 1227 ms | 1227 ms | P3: detalhe social acima de 1s, mas sem falha. |
| `POST /ai/generate` | `200x5` | 9475 ms | 10203 ms | 10203 ms | P2 aceito: IA sincrona demora ~9-10s. |
| `POST /ai/optimize` | `202/200` | 4518 ms | 4825 ms | 4825 ms | P2 aceito: criacao/pedido de job ainda >4s. |
| `GET /ai/optimize/jobs/:id` | `200x5` | 1196 ms | 1199 ms | 1199 ms | P3: polling em ~1.2s. |

Smoke legado adicional:

| Operacao | Tempo observado | Classificacao |
|---|---:|---|
| `POST /decks/:id/cards` sequencial | 6461-6995 ms | P2/P3: gargalo conhecido de escrita carta-a-carta; app core usa bulk apply no optimize. |
| `GET /market/movers?limit=5&min_price=1.0` no Home | ~4074-4283 ms | P2: lento em tela inicial; nao bloqueou runtime. |
| `/binder/stats` em cold-ish runs | 2523-4095 ms | P2: stats pode travar percepcao se nao houver loading bom. |

## Observabilidade, Sentry e logs

- Backend inicializou Sentry em ambiente staging/desenvolvimento sem expor DSN nos artefatos.
- Logs app emitiram breadcrumbs estruturados `api_slow_request` com `method`, `endpoint`, `status_code`, `duration_ms`, `request_id` e `response_request_id`.
- Backend emitiu `http_observability` para slow/client/server errors e `social_notification slow_deferred` para notificacoes sociais/trades.
- Firebase Performance ficou indisponivel na sessao de integration test por falta de Firebase default app inicializado; HTTP metrics do plugin ficaram desativadas, mas breadcrumbs/logs proprios cobriram visibilidade basica.
- Artefatos persistidos foram sanitizados para emails, tokens, bearer/JWT e screenshot chunks em logs textuais.

## 4xx/5xx, crashes, overflows e timeouts observados

| Evento | Origem | Classificacao |
|---|---|---|
| `GET /trades/None -> 500` | Primeiro script temporario de performance usou id invalido porque o payload inicial de trade estava errado. | P3 backend hardening/backlog: validar UUID e retornar 400 em vez de 500. Nao ocorreu nos runtimes app PASS. |
| `POST /ai/optimize -> 400` | Primeiro script temporario enviou payload simplificado com `mode` explicito inadequado para a amostra. | QA harness corrigido; medicao final `POST /ai/optimize` retornou `202/200`. |
| Life Counter primeira tentativa | Xcode/DDS falhou apos aviso de builds concorrentes. | Ambiental; retry limpo PASS. |
| Visual proof primeira tentativa | Harness stale tocava `Gerar Deck` e esperava `Preview do Deck`. | Corrigido em `app/integration_test/app_full_non_life_counter_visual_capture_smoke_test.dart`; retry PASS. |
| Crashes/overflows/timeouts user-facing | Runtimes iPhone 15 PASS | Nao observados como residuais. |

## Polimento P2/P3 auditado

| Pendencia | Status |
|---|---|
| Search global | Backlog/produto P3; Search Cards/Colecoes passou, busca global unificada nao foi implementada nesta rodada. |
| Meta Deck Intelligence visual | Backlog P2/P3; optimize preview atual mostra IA/meta surfaces existentes, mas dashboard visual dedicado nao foi alterado. |
| Life Counter/Lotus melhorias | PASS funcional; P3 restante para copy/skin/perfiling visual adicional. |
| Screenshots Home/Deck/IA/Binder/Marketplace | PASS parcial/aceito: screenshots extraidas de Home, Decks, Deck Detail, Generate/Preview, Community/Collection/Profile, Deck Optimize e Life Counter. Marketplace/Binder possuem logs runtime PASS; screenshot dedicado de Marketplace fica backlog visual P3. |

## Evidencias

- Handoff runtime: `app/doc/runtime_flow_handoffs/deck_runtime_iphone15_simulator_2026-05-04.md`.
- Proof folder local ignorado por git: `app/doc/runtime_flow_proofs_2026-05-04_iphone15_simulator/`.
- Logs sanitizados principais:
  - `iphone15_deck_runtime_m2006_test.log`
  - `iphone15_sets_catalog_runtime.log`
  - `iphone15_sets_search_runtime.log`
  - `iphone15_binder_dashboard_runtime_test.log`
  - `iphone15_binder_marketplace_trade_runtime_test.log`
  - `iphone15_life_counter_lotus_visual_runtime_proof_test_retry.log`
  - `iphone15_app_full_non_life_counter_visual_capture_smoke_test_retry.log`
  - `pre_release_endpoint_metrics.log`
  - `pre_release_endpoint_metrics_corrections.log`
  - `pre_release_optimize_metrics_correction.log`
- Screenshots extraidos:
  - `01_login.png`, `03_home.png`, `04_decks.png`, `04b_deck_details.png`
  - `05_generate.png`, `06_generate_preview.png`
  - `08_optimize_sheet.png`, `09_preview.png`, `10_complete_validated.png`
  - `life_counter_lotus_runtime_initial.png`, `life_counter_lotus_runtime_after_plus.png`

## Checklist go/no-go

| Criterio | Resultado |
|---|---|
| Scanner fisico marcado como DEFERRED/NOT PROVEN | PASS |
| Fluxos core pre-release classificados | PASS |
| Performance p50/p95/p99 medida | PASS |
| Observabilidade validada ou NOT PROVEN com motivo | PASS com observacao Firebase Performance indisponivel no integration test |
| P2/P3 auditados | PASS WITH RISKS |
| Backend 8082 encerrado ao final | PASS; `kill 63570` e porta `8082` livre |
| Worktree limpo apos commit/push | A validar no fechamento da sessao |

## Menores proximas acoes

1. P2: investigar `POST /decks/:id/cards` carta-a-carta, `/market/movers` e `/binder/stats` para reduzir p95 percebido.
2. P3: adicionar validacao de UUID em `GET /trades/:id` para trocar 500 por 400 em input invalido.
3. P3: criar screenshot dedicado para Marketplace/Binder visual, separado do runtime funcional.
4. DEFERRED: executar scanner fisico/camera/OCR em device fisico quando o escopo voltar a incluir scanner.
