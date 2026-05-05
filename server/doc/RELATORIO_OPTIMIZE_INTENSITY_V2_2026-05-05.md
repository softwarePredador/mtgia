# Relatorio Optimize Intensity v2 — 2026-05-05

## Resultado

**PASS.** Sprint 1 backend/API implementado para `/ai/optimize` com contrato `intensity`, escopo real de sugestoes por intensidade, cache separado por intensidade, `rebuild_guided` explicito e quality gate preservado.

## Commits inspecionados

| Ref | Commit | Nota |
|---|---|---|
| `HEAD` antes da alteracao | `487d2b2657246bff18e77e0219b06a0918c805e2` | `Prepare agents for optimize intensity sprint` |

## Contrato implementado

| Campo | Status |
|---|---|
| Request `intensity` | Opcional; aceita `light`, `focused`, `aggressive`, `rebuild`; valor ausente resolve para `focused` com `source=omitted_default`; valor invalido retorna 400. |
| Response `intensity` | String selecionada em respostas sync, async accepted, cache hit, complete final e rebuild-guided. |
| Response `optimize_intensity` | Objeto com `selected`, `requested`, `source`, `target_swaps.min/max`, `quality_gate.can_reduce_scope`, `candidate_swaps`, `returned_swaps` e campos de reducao quando aplicavel. |
| Cache | `ai_optimize_cache` agora usa chave `v7` incluindo intensidade para evitar reaproveitar uma resposta de outro escopo. |
| Rebuild | `intensity=rebuild` retorna `mode=rebuild_guided`, `outcome_code=rebuild_guided`, `next_action.endpoint=/ai/rebuild` e nao aplica mudancas automaticamente. |
| Needs repair | Deck estruturalmente invalido retorna `mode=rebuild_guided`, `outcome_code=rebuild_guided`, mantendo `quality_error.code=OPTIMIZE_NEEDS_REPAIR` para diagnostico. |

## Mapeamento de intensidade

| Intensidade | Alvo produto | Escopo backend |
|---|---:|---|
| `light` | 3-5 swaps seguros | `swapLimit=5` no shortlist deterministico; gates podem reduzir/rejeitar. |
| `focused` | 6-10 swaps seguros | `swapLimit=10`; default para request sem `intensity`. |
| `aggressive` | 10-20 swaps seguros | `swapLimit=20`; pode expor mais candidatos quando existem candidatos seguros, sem relaxar gates. |
| `rebuild` | Reconstrucao guiada | Retorna proxima acao `/ai/rebuild` com explicacao e payload sugerido. |

## Matriz de path/outcome

| Cenario | Path selecionado | Evidencia |
|---|---|---|
| Request sem `intensity` | `focused` por compatibilidade | `optimize_runtime_support_test.dart`: `source=omitted_default`, alvo 6-10. |
| `light` | Optimize deterministico/AI limitado a menor escopo | Teste compara `swapLimit=5`; retorno pode ser menor por gate. |
| `focused` | Optimize default balanceado | Live complete retornou `intensity=focused`; cache key `v7`. |
| `aggressive` | Mais candidatos seguros que `light` quando existem | `optimize_learning_pipeline_test.dart`: aggressive retorna mais candidatos que light no mesmo deck. |
| `rebuild` | `rebuild_guided` explicito | Endpoint monta `next_action` para `/ai/rebuild`, sem aplicar. |
| Deck `needs_repair` | `rebuild_guided` + 422 diagnostico | Live Talrand 99 Wastes: `mode=rebuild_guided`, `quality_error.code=OPTIMIZE_NEEDS_REPAIR`. |
| Complete async | Job `202` + polling | Live `ai_optimize_flow_test.dart` completou jobs e retornou `stage_telemetry`. |
| Cache hit | Mesmo contrato com `intensity` | Cache key inclui intensidade; cache hit reanexa `intensity`, `optimize_intensity`, `timings`, `stage_telemetry`. |

## Timing summary

| Prova | Tempo observado |
|---|---:|
| Live `ai_optimize_flow_test.dart --tags live` | `02:46`, `+10 ~1` |
| Complete async source deck no live | `total_ms=9648`; maiores stages: `complete.fill_remainder=3408ms`, `complete.ai_suggestion_loop=1771ms`, `complete.build_final_response=1114ms`, `complete.prepare_commander_seed=556ms`. |
| Needs repair Talrand live | `total_ms=2959`; maiores stages: `request.deck_context=1778ms`, `deck_context.theme_profile=634ms`, `request.cache_lookup=577ms`, `request.user_preferences=574ms`, `deck_context.cards_query=569ms`. |

## Qualidade, legalidade e seguranca

- Color identity: preservada por `shouldKeepCommanderFillerCandidate`/filtros de identity; teste novo rejeita carta branca em comandante mono-U.
- Legalidade Commander: consultas continuam filtrando `card_legalities` e `DeckRulesService` segue validando rebuild/complete.
- Bracket: `applyBracketPolicyToAdditions` segue bloqueando power spikes; teste novo bloqueia `Mana Crypt` quando o budget de fast mana bracket 1 ja foi consumido.
- Commander preservation: filtros existentes impedem remover comandante; testes de pipeline continuam passando.
- Quality gate: `filterUnsafeOptimizeSwapsByCardData` segue podendo reduzir escopo; teste novo reduz 12 swaps agressivos inseguros para zero, sem false success.
- Metadata app-consumivel: detalhes agora incluem `reason`, `role`/`function`, `priority`, `risk`, `impact_estimate` quando possivel.
- Sentry/logging: excecoes do route handler seguem em `captureRouteException` com tag `route=ai_optimize`; timings por stage sao logados por `OptimizeStageTelemetry`.

## Comandos executados

| Comando | Resultado |
|---|---|
| `cd server && dart analyze lib/ai/optimize_runtime_support.dart lib/ai/optimize_request_support.dart routes/ai/optimize/index.dart test/optimize_runtime_support_test.dart test/optimize_learning_pipeline_test.dart test/optimization_quality_gate_test.dart` | PASS |
| `cd server && dart test test/optimize_runtime_support_test.dart test/optimize_learning_pipeline_test.dart test/optimization_quality_gate_test.dart test/optimize_complete_support_test.dart test/optimization_pipeline_integration_test.dart` | PASS, `+62` |
| `cd server && dart analyze lib routes test` | PASS |
| `cd server && dart test test/optimization_quality_gate_test.dart test/optimization_pipeline_integration_test.dart test/optimize_complete_support_test.dart test/external_commander_meta_promotion_support_test.dart && RUN_INTEGRATION_TESTS=0 dart test test/ai_optimize_flow_test.dart -r expanded` | PASS; live suite skipped offline by env |
| `PORT=8082 dart run .dart_frog/server.dart` + `curl http://127.0.0.1:8082/health` | PASS; backend healthy |
| `cd server && TEST_API_BASE_URL=http://127.0.0.1:8082 dart test test/ai_optimize_flow_test.dart --tags live -r expanded` | PASS, `+10 ~1`, `02:46` |
| `PORT=8080 dart run .dart_frog/server.dart` + `cd server && dart run bin/run_commander_only_optimization_validation.dart --dry-run` | PASS; 19 candidatos planejados, escrita bloqueada por default |

## App/backend contract findings

- App antigo pode continuar omitindo `intensity`; backend seleciona `focused` e retorna campos novos de forma aditiva.
- App novo deve enviar `intensity` explicitamente quando o usuario escolher intensidade.
- App deve tratar `mode=rebuild_guided` como outcome normal, exibir `message`/`next_action.explanation` e acionar `/ai/rebuild` apenas por escolha do usuario.
- App preview/apply pode continuar usando `additions_detailed`/`removals_detailed`; o backend mantem listas balanceadas em optimize e recomendações enriquecidas.

## Blockers

Nenhum blocker backend remanescente para Sprint 1.

## Menores proximos fixes

1. Atualizar app para enviar `intensity` no bottom sheet de optimize e mostrar `optimize_intensity.returned_swaps`.
2. Adicionar teste app-side para `mode=rebuild_guided` como outcome normal de optimize.
3. Medir em runtime mobile se `aggressive` aumenta preview de swaps sem queda de aplicabilidade.
