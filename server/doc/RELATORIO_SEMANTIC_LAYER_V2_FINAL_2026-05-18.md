# Semantic Layer v2 Final - 2026-05-18

## Resultado final

PASS_WITH_RISKS.

## Consolidado

- Schema/data v2 aditivo criado com compatibilidade do envelope v1.
- Backfill dry-run e apply sanitizados executados com 72.295% de cobertura.
- Apply controlado gravou `24172` linhas em `card_semantic_tags_v2` e
  `52797` tags funcionais derivadas da v2, sem regressões agregadas.
- Optimize/generate integrados em shadow mode para evitar regressao por tags
  contextuais ainda heuristicas.
- Deck Analysis exibe explicabilidade por carta/tag com fallback legado.
- Testes/analyzers focados passaram.
- Deploy publico provado em `36a356eeba9e787f8eeb9648f93c718bea40af95`.
- Smoke publico validou `/analysis`, `/ai-analysis`, `/ai/optimize` e
  `/ai/generate`.
- Runtime iPhone 15 Simulator validou `semantic_schema_version`,
  `sample_details`, explicabilidade e UI.

## Prova publica 2026-05-19

Artifacts:

- `server/test/artifacts/semantic_layer_v2_public_runtime_2026-05-19/route_smoke_summary.json`
- `app/doc/runtime_flow_proofs_2026-05-19_semantic_layer_v2/summary.json`
- `app/doc/runtime_flow_handoffs/semantic_layer_v2_iphone15_simulator_2026-05-19.md`

Resumo:

- `/health.git_sha=36a356eeba9e787f8eeb9648f93c718bea40af95`.
- `/decks/:id/analysis=200`.
- `/decks/:id/ai-analysis=200`.
- `/ai/optimize=202`.
- `/ai/generate=202`.
- `functional_tags.semantic_schema_version=semantic_layer_v2_2026_05_18`.
- `persisted_rows=6`, `heuristic_rows=1` na fixture runtime.
- `ramp_sample_detail_count=2`.
- `has_explainability_reason=true`.
- UI exibiu `Sol Ring` e texto amigavel `Conta como ramp`.

## Proximos passos objetivos

1. Corrigir/investigar o executor async de optimize: a prova de qualidade em
   2026-05-19 retornou `Optimize async recebeu resposta invalida do executor interno`.
2. Criar corpus pequeno de decks completos que produzam swaps validos, nao
   apenas `rebuild_guided`.
3. Curar falsos positivos `blink_like_removal` e `expensive_ramp_review`.
4. Promover v2 de shadow para gate somente apos taxa de falsos positivos aceitavel.

## Quality gate 2026-05-19

Relatorio:

- `server/doc/RELATORIO_SEMANTIC_LAYER_V2_QUALITY_GATE_2026-05-19.md`

Resumo:

- `generate`: `2/2` jobs async completos, `2/2` validos,
  `semantic_layer_v2=true`.
- `optimize`: `2/2` jobs async chegaram em `failed`; sync forcado respondeu
  com `rebuild_guided` seguro, mas sem swaps.
- Decisao: manter v2 em `shadow mode`; ainda nao promover para gate duro.
