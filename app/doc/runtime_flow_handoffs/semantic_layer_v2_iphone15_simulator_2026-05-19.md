# Semantic Layer v2 iPhone 15 Simulator Runtime - 2026-05-19

## Status

`PASS_WITH_RISKS`

## Ambiente

- App runtime: iPhone 15 Simulator `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`.
- Backend: `https://evolution-cartinhas.8ktevp.easypanel.host`.
- Backend SHA: `36a356eeba9e787f8eeb9648f93c718bea40af95`.
- Harness: `app/integration_test/deck_functional_tags_runtime_test.dart`.

## Resultado

`00:09 +1: All tests passed!`

## Cobertura provada

- `/health` confirmou o SHA publico correto.
- Resolveu 7 cartas da fixture por `/cards`.
- Criou deck Commander pequeno para prova de analise.
- `GET /decks/:id/analysis` retornou `200`.
- `functional_tags.semantic_schema_version=semantic_layer_v2_2026_05_18`.
- `sample_details.ramp` retornou explicabilidade por carta/tag.
- UI de Deck Analysis renderizou a secao de funcoes.
- UI exibiu amostra `Sol Ring`.
- UI exibiu texto amigavel `Conta como ramp`.

Resumo sanitizado:

- `persisted_rows=6`;
- `persisted_copies=6`;
- `heuristic_rows=1`;
- `heuristic_copies=1`;
- `counts.ramp=2`;
- `counts.draw=1`;
- `counts.removal=2`;
- `ramp_sample_detail_count=2`;
- `has_explainability_reason=true`.

## Evidencias

- `app/doc/runtime_flow_proofs_2026-05-19_semantic_layer_v2/summary.json`
- `server/test/artifacts/semantic_layer_v2_public_runtime_2026-05-19/route_smoke_summary.json`

## Riscos restantes

- Prova em simulador iOS, nao em build assinado em device fisico.
- Warning conhecido de plugins iOS arm64 apareceu, mas nao bloqueou a execucao.
- `/ai/optimize` e `/ai/generate` foram provados como aceite async/smoke; a
  qualidade de jobs completos continua como gate separado antes de transformar
  v2 em gate duro.
