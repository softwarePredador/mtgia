# Relatorio Commander Optimize Flow Audit - 2026-04-27

## Escopo

- Repo: `softwarePredador/mtgia`
- Pasta auditada: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia`
- Commits auditados:
  - `da4aa8d` - runtime iPhone 15 Simulator
  - `c7b1b82` - Sentry ampliado + QA iPhone 15
  - `06ddb45` - referencias Commander competitivas no optimize
  - `11d0fe2` - sprint final do pipeline commander meta
  - `210353a` - runtime Commander-only apply gravado nos artifacts

## Veredito

**Aprovado com ajustes nao bloqueantes.** O fluxo novo de Commander optimize ficou coerente de ponta a ponta para:

- `optimize` sincrono com shortlist deterministico;
- `complete` assincrono com job polling;
- `needs_repair -> rebuild_guided`;
- `preview/apply/validate` no app;
- telemetria de tempos, cache, Sentry/logs e validacao final Commander.

Nao encontrei regressao funcional bloqueante nem bug pequeno provado que exigisse patch de codigo nesta rodada.

## Documentos lidos

- `.github/agents/commander-optimize-flow-auditor.agent.md`
- `server/manual-de-instrucao.md`
- `server/doc/DECK_CREATION_VALIDATIONS.md`
- `server/doc/DECK_ENGINE_CONSISTENCY_FLOW.md`
- `server/doc/RELATORIO_META_DECK_INTELLIGENCE_2026-04-24.md`
- `app/doc/runtime_flow_handoffs/deck_runtime_iphone15_simulator_2026-04-27.md`

## Comandos executados

```bash
cd server && dart analyze lib/ai routes/ai bin test
cd server && dart test test/ai_optimize_flow_test.dart test/optimization_quality_gate_test.dart test/optimization_pipeline_integration_test.dart test/optimize_complete_support_test.dart test/external_commander_meta_promotion_support_test.dart
cd server && dart run bin/run_commander_only_optimization_validation.dart --dry-run

cd app && flutter analyze lib/features/decks test/features/decks
cd app && flutter test test/features/decks/screens/deck_details_screen_smoke_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart

cd server && PORT=8082 dart run .dart_frog/server.dart
cd server && TEST_API_BASE_URL=http://127.0.0.1:8082 dart run bin/run_commander_only_optimization_validation.dart --dry-run
cd app && flutter test integration_test/deck_runtime_m2006_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check
```

## Resultado dos checks

| Check | Resultado |
|---|---|
| `dart analyze lib/ai routes/ai bin test` | OK |
| testes server focados em optimize | OK |
| `flutter analyze lib/features/decks test/features/decks` | OK |
| testes app focados em decks/optimize | OK |
| `run_commander_only_optimization_validation --dry-run` em `8082` | OK |
| integration test no `iPhone 15` com backend real `8082` | OK |

## Matriz de caminhos auditados

| Caminho | Evidencia principal | Resultado | Observacao |
|---|---|---|---|
| `optimize` sync com `deterministic_first` | `server/lib/ai/optimize_runtime_support.dart`, `server/test/optimize_learning_pipeline_test.dart` | OK | fallback para IA so ocorre quando `strategy_source=deterministic_first` e o erro e `OPTIMIZE_NO_SAFE_SWAPS` ou `OPTIMIZE_QUALITY_REJECTED` |
| `needs_repair -> rebuild_guided` | `server/routes/ai/optimize/index.dart`, `app/test/features/decks/screens/deck_details_screen_smoke_test.dart`, `server/test/artifacts/optimization_resolution_suite/latest_summary.json` | OK | resposta `422` com `outcome_code=needs_repair`, `quality_error.code=OPTIMIZE_NEEDS_REPAIR` e `next_action.type=rebuild_guided` |
| `complete` async com `202 + polling` | `server/routes/ai/optimize/index.dart`, `server/routes/ai/optimize/jobs/[id].dart`, runtime iPhone 15, log backend | OK | live rerun: `POST /ai/optimize -> 202`, job completou apos `4` polls |
| `safe_no_change` protegido | `server/test/artifacts/optimization_resolution_suite/latest_summary.json` | OK | suite fechou `16` casos `safe_no_change` e `3` `rebuild_guided`, `0` unresolved |
| cache de optimize | `server/routes/ai/optimize/index.dart`, `server/lib/ai/optimize_runtime_support.dart` | OK | key `v6:<stableHash>` carregada cedo; payload devolve `cache.hit=true`; TTL real atual `6h` |
| legalidade Commander | `server/lib/ai/optimize_runtime_support.dart`, `server/lib/ai/optimize_complete_support.dart`, `POST /decks/:id/validate` | OK | fillers e prioridades respeitam legalidade Commander e o deck final segue por `validate` |
| color identity | filtros backend + `DeckProvider.applyOptimizationWithIds()` + testes app | OK | protecao dupla: backend filtra candidatos e app refiltra additions por `color_identity` antes do `PUT /decks/:id` |
| referencias cEDH/meta | `resolveCommanderOptimizeMetaScope(...)`, `preferExternalCompetitive: true`, artifact `auntie_ool_cursewretch.json` | OK | referencias competitivas so entram para `format=commander` e `bracket>=3`; artifact live mostra `competitive_model_stage_used=true` em bracket `4` |
| preview -> apply -> validate no app | `DeckProvider`, `deck_provider_support_ai.dart`, `deck_provider_support_mutation.dart`, smoke test + iPhone handoff | OK | app pede optimize, abre preview, persiste deck e chama `POST /decks/:id/validate` apos salvar |
| telemetry, timings, Sentry/logs | `OptimizeStageTelemetry`, `/tmp/mtgia-optimize-audit-server.log`, Sentry init | OK | logs stage-by-stage presentes; Sentry iniciou no backend; nao houve crash novo no runtime auditado |

## Tempos observados

### 1. Commander-only apply corpus ja versionado (`HEAD`)

Base: `server/doc/RELATORIO_COMMANDER_ONLY_OPTIMIZATION_VALIDATION_2026-04-21.md`

- amostras: `19`
- `total_ms` minimo: `9852`
- `total_ms` medio: `12541.95`
- `total_ms` maximo: `31543`

Medias por etapa:

- `complete.fill_remainder`: `3782.58ms`
- `complete.ai_suggestion_loop`: `3655.63ms`
- `complete.build_final_response`: `1199.26ms`
- `complete.prepare_commander_seed`: `794.63ms`
- `complete.build_intermediate_payload`: `0.11ms`
- `complete.rebalance_land_deficit`: `0.05ms`

Leitura: o custo dominante continua em `fill_remainder` e no loop de sugestoes/seed, nao no empacotamento da resposta.

### 2. Rerun live da auditoria (`iPhone 15` + backend local `8082`)

Do log do app:

- `POST /ai/archetypes -> 200 (8495ms)`
- `POST /ai/optimize -> 202 (5718ms)`
- job completou apos `4` polls em `/ai/optimize/jobs/<jobId>` (cerca de `1.2s` por poll)
- preview capturado como `09_preview`
- tela final validada capturada como `10_complete_validated`

Do log backend:

- `request.user_preferences=602ms`
- `request.deck_context=1859ms`
- `request.cache_lookup=600ms`
- `request.commander_reference_cache=599ms`
- `request.commander_live_edhrec=782ms`
- `request.deterministic_shortlist=2ms`
- `request.async_job_create=1198ms`
- `complete.prepare_commander_seed=597ms`
- `complete.ai_suggestion_loop=2438ms`
- `complete.fill_remainder=3457ms`
- `complete.build_final_response=1217ms`
- `[OPTIMIZE_TIMING] total_ms=10710`

Leitura: a experiencia live bate com o desenho do pipeline - a requisicao inicial gasta o setup/contexto e o restante vai para o job async, com tempo total de complete proximo de `10.7s`.

## Findings

### 1. O caminho `complete_async` esta saudavel

- O backend retorna `202`, `poll_url`, `poll_interval_ms` e `total_stages`.
- O app transforma isso em polling estruturado e fecha com o `result` final.
- O integration test no iPhone 15 confirmou o fluxo real com backend local e sem mock do optimize.

### 2. `needs_repair` ficou bem amarrado

- O backend nao tenta micro-swap em deck estruturalmente ruim.
- Em vez disso, devolve `422` com `repair_plan`, `recommended_mode` e payload pronto para `/ai/rebuild`.
- O app ja cobre esse contrato e abre o draft rebuild com sucesso.

### 3. Legalidade Commander e color identity tem defesa em duas camadas

- Backend: fillers e prioridades passam por `shouldKeepCommanderFillerCandidate(...)` e checks de legalidade Commander.
- App: `applyOptimizationWithIds()` refaz busca por nome e filtra additions fora da identidade antes do `PUT`.
- O deck salvo ainda passa pelo `POST /decks/:id/validate`.

### 4. Referencias cEDH/Commander competitivas nao vazaram para bracket casual

- `resolveCommanderOptimizeMetaScope(...)` so ativa `competitive_commander` para `deckFormat=commander` com `bracket>=3`.
- O artifact `auntie_ool_cursewretch.json` prova uso competitivo no caso certo (`competitive_model_stage_used=true`).
- Nao achei indicio de aplicacao dessas referencias em `bracket 1-2`.

### 5. Telemetria e logs ficaram uteis o bastante para auditoria real

- `OptimizeStageTelemetry` registra `snapshot()` e loga cada etapa com `[OPTIMIZE_TIMING_STAGE]`.
- O backend de auditoria iniciou com Sentry ativo.
- Nao houve crash novo nem ruido de exception mascarando o resultado do optimize.

### 6. O cache esta coerente, mas a documentacao estava atrasada

- O codigo atual salva `ai_optimize_cache` com `NOW() + INTERVAL '6 hours'`.
- Parte da documentacao operacional ainda descrevia `24h`.
- Este commit corrige o material atualizado para refletir o TTL real de `6h`.

## Ajustes nao bloqueantes

1. **Dry-run ainda depende de API valida.** `run_commander_only_optimization_validation.dart --dry-run` continua exigindo `GET /health`. Nao e bug funcional do optimize, mas significa que o modo dry-run nao e offline.
2. **Nao houve prova live de `cache.hit=true` nesta rodada.** O caminho esta correto no codigo, mas faltou um passo dedicado de repetir a mesma requisicao para registrar hit real no runtime auditado.
3. **Latencia de `POST /ai/archetypes` ainda e perceptivel.** No rerun live ficou em `8495ms`; nao bloqueia, mas merece tuning separado se a meta UX for sub-5s.

## Proximos ajustes recomendados

1. Adicionar um passo de runtime que repita o mesmo `POST /ai/optimize` para gravar `cache.hit=true` como evidencia live.
2. Considerar um `--offline-plan-only` ou `--skip-health-check` no runner commander-only para dry-run puramente estrutural.
3. Continuar monitorando `request.deck_context` e `complete.fill_remainder`, que seguem como maiores consumidores de tempo.

## Follow-up 2026-04-27

### Ajustes implementados

- `run_commander_only_optimization_validation.dart --dry-run` passou a gravar, por padrao, em `test/artifacts/commander_only_optimization_validation/latest_dry_run_summary.json` e `doc/RELATORIO_COMMANDER_ONLY_OPTIMIZATION_DRY_RUN_2026-04-27.md`.
- A prova `apply` versionada em `latest_summary.json` e `RELATORIO_COMMANDER_ONLY_OPTIMIZATION_VALIDATION_2026-04-21.md` foi preservada para nao ser sobrescrita por dry-run.
- Foi adicionado `--skip-health-check` para dry-run estrutural/offline sem depender de `GET /health` ou probe de `/auth/login`.
- Foi adicionado `--prove-cache-hit` para `--apply`, repetindo o mesmo `/ai/optimize` antes do apply e registrando `cache.hit=true` no artifact quando o backend vivo confirmar o cache.
- A primeira prova live de cache expôs um bug real: `complete_async` lia cache, mas nao salvava o resultado no `ai_optimize_cache`.
- O job async de complete passou a persistir o payload final com `cache.hit=false`; a segunda chamada agora retorna `cache.hit=true`.

### Comandos validados

```bash
cd server && dart analyze bin/run_commander_only_optimization_validation.dart test/commander_only_runtime_validation_config_test.dart
cd server && dart test test/commander_only_runtime_validation_config_test.dart
cd server && dart run bin/run_commander_only_optimization_validation.dart --dry-run --skip-health-check
cd server && TEST_API_BASE_URL=http://127.0.0.1:8082 VALIDATION_LIMIT=1 VALIDATION_ARTIFACT_DIR=test/artifacts/commander_only_optimization_cache_probe VALIDATION_SUMMARY_JSON_PATH=test/artifacts/commander_only_optimization_cache_probe/latest_summary.json VALIDATION_SUMMARY_MD_PATH=doc/RELATORIO_COMMANDER_ONLY_CACHE_HIT_PROBE_2026-04-27.md dart run bin/run_commander_only_optimization_validation.dart --apply --prove-cache-hit
```

### Evidencia live de cache

- `server/test/artifacts/commander_only_optimization_cache_probe/latest_summary.json`
- `server/doc/RELATORIO_COMMANDER_ONLY_CACHE_HIT_PROBE_2026-04-27.md`
- Resultado: `passed=1`, `failed=0`, `cache_probe.hit=true`, `cache_probe.cache_key=v6:9d8303a9`.
