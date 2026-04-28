# iPhone 15 Simulator Runtime Handoff — 2026-04-28

## Resultado

Verdict: `Approved for Sets/Colecoes runtime path / deck live-backend iPhone path not proven`

O QA geral de Sets/Colecoes passou no iPhone 15 Simulator com backend real em `http://127.0.0.1:8082`. A execucao encontrou e corrigiu um overflow pequeno no estado vazio de set futuro/parcial (`AppStatePanel`), depois rerodou a prova no simulador com sucesso.

## Ambiente

- Date/time: `2026-04-28 14:55:50 -03`
- Device: `iPhone 15`
- Simulator id: `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`
- Runtime: `com.apple.CoreSimulator.SimRuntime.iOS-17-4`
- Backend URL usado pelo app: `http://127.0.0.1:8082`
- Proof folder: `app/doc/runtime_flow_proofs_2026-04-28_iphone15_simulator/`

## Descoberta de device

`flutter devices` summary:

```text
Found 3 connected devices:
  iPhone 15 (mobile) • F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF • ios • com.apple.CoreSimulator.SimRuntime.iOS-17-4 (simulator)
  macOS (desktop)    • macos                                • darwin-arm64 • macOS 26.2 25C56 darwin-arm64
  Chrome (web)       • chrome                               • web-javascript • Google Chrome 147.0.7727.102
```

`xcrun simctl list devices available | grep -E "iPhone 15|Booted"`:

```text
iPhone 15 Pro (F3C5B123-673F-4ACC-84B2-489957CB81C8) (Shutdown)
iPhone 15 Pro Max (DABB9D79-2FDB-4585-94DB-E31F1288EE74) (Shutdown)
iPhone 15 (F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF) (Booted)
iPhone 15 Plus (6A3E5508-0190-48AC-B6D1-E4BA8A94FFD9) (Shutdown)
```

## Backend real

Start command:

```bash
cd server
PORT=8082 dart run .dart_frog/server.dart
```

Health:

```json
{"status":"healthy","service":"mtgia-server","timestamp":"2026-04-28T14:55:50.905191","environment":"development","version":"1.0.0","git_sha":null,"checks":{"process":{"status":"healthy"}}}
```

## Comandos executados

```bash
cd app
flutter analyze lib/features/cards lib/features/collection test/features/cards test/features/collection --no-version-check
flutter test test/features/cards test/features/collection --no-version-check
flutter test integration_test/sets_catalog_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check
flutter test integration_test/sets_search_catalog_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check
flutter test integration_test/collection_entrypoints_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check
flutter test test/features/decks/screens/deck_runtime_widget_flow_test.dart --no-version-check
flutter test test/features/decks/screens/deck_details_screen_smoke_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart --no-version-check
```

## Resultados

| Area | Resultado |
| --- | --- |
| Analyze Cards/Colecoes | Passed, no issues |
| Unit/widget Cards/Colecoes | Passed, `5 passed / 0 failed` |
| `sets_catalog_runtime_test.dart` | Passed on iPhone 15, live backend |
| `sets_search_catalog_runtime_test.dart` | Passed on iPhone 15, live backend |
| `collection_entrypoints_runtime_test.dart` | Passed on iPhone 15, live backend |
| Deck generate/optimize/apply/validate widget suite | Passed, `67 passed / 0 failed` |

## Fluxos provados no iPhone 15 + backend real

- `Colecao -> Colecoes -> buscar Marvel -> abrir Marvel Super Heroes -> cards do set -> voltar`.
- `Colecao -> Colecoes -> buscar OM2 -> abrir Through the Omenpaths 2 -> estado "Dados parciais de set futuro" -> voltar`.
- `Search -> Cards -> buscar Black Lotus` via `GET /cards?name=Black+Lotus`.
- `Search -> Colecoes -> buscar ECC -> abrir Lorwyn Eclipsed Commander -> cards do set -> voltar`.
- Hub `Colecao` renderiza entrada `Fichario` e alterna para `Colecoes` sem crash.

## Backend contracts observados

- `GET /sets?limit=50&page=1` -> 200.
- `GET /sets?limit=50&page=1&q=Marvel` -> 200.
- `GET /cards?set=MSH&limit=100&page=1&dedupe=true` -> 200.
- `GET /sets?limit=50&page=1&q=OM2` -> 200.
- `GET /cards?set=OM2&limit=100&page=1&dedupe=true` -> 200, lista vazia esperada para set futuro/parcial.
- `GET /cards?name=Black+Lotus&limit=50&page=1` -> 200.
- `GET /sets?limit=50&page=1&q=ECC` -> 200.
- `GET /cards?set=ECC&limit=100&page=1&dedupe=true` -> 200.
- `GET /binder...` e `GET /binder/stats` -> 401 esperado no teste de entrypoint sem login; o objetivo ali foi provar renderizacao/navegacao do hub sem crash, nao CRUD autenticado.

## O que foi real e o que foi mockado

- Real: iPhone 15 Simulator, Flutter UI, navegacao de tabs/back, backend local Dart Frog em `127.0.0.1:8082`, endpoints `/health`, `/sets`, `/cards` e chamadas nao autenticadas de `/binder`.
- Mockado/controlado: nada nos integration tests de Sets/Colecoes.
- Deck generate/optimize/apply/validate: validado por widget/runtime suite com `ApiClient` mockado; nao foi provado como live backend no iPhone 15 nesta rodada porque nao havia integration test live-backend existente para esse fluxo.
- Login/register: nao aplicavel aos fluxos de Sets/Colecoes; entrypoint de binder foi tocado sem sessao e retornou 401 esperado.

## Artefatos

- `app/doc/runtime_flow_proofs_2026-04-28_iphone15_simulator/sets_catalog_runtime_test.txt`
- `app/doc/runtime_flow_proofs_2026-04-28_iphone15_simulator/sets_search_catalog_runtime_test.txt`
- `app/doc/runtime_flow_proofs_2026-04-28_iphone15_simulator/collection_entrypoints_runtime_test.txt`
- `app/doc/runtime_flow_proofs_2026-04-28_iphone15_simulator/backend_8082.txt`

Screenshots: nao capturados nesta execucao; os logs expanded dos testes de integracao foram preservados.

## Bug encontrado e corrigido

- Sintoma: overflow vertical ao abrir set futuro/parcial sem cartas locais (`OM2`) no iPhone 15.
- Fix: `AppStatePanel` agora usa `LayoutBuilder + SingleChildScrollView + ConstrainedBox`, mantendo centralizacao quando ha espaco e permitindo scroll em areas compactas.
- Cobertura: `app/test/core/widgets/app_state_panel_test.dart` passou a limitar altura para reproduzir o cenario compacto.

## Pendencias reais

1. Provar `register/login -> decks/generate/optimize/apply/validate` em iPhone 15 com backend real quando existir integration test live-backend para esse fluxo.
2. Provar CRUD autenticado de `Fichario/Binder` no iPhone 15 se a task exigir sessao real; nesta rodada apenas o entrypoint e comportamento sem crash foram cobertos.
