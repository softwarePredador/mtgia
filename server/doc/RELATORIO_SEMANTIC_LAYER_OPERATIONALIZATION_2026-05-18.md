# Semantic Layer Operationalization - 2026-05-18

## Veredito

`PASS_WITH_RISKS`

A camada semantica saiu de uso puramente heuristico em runtime para uso
operacional com dados persistidos em `card_function_tags` e fallback
deterministico quando nao houver tag persistida confiavel.

## Mudancas aplicadas

- `summarizeFunctionalTagsForDeck` agora prioriza `functional_tags` persistido
  por carta quando presente e com confidence suficiente.
- Se nao houver tag persistida confiavel, o fluxo preserva o fallback
  heuristico anterior via `inferFunctionalCardTags`.
- `functional_tags.source` agora informa `persisted_rows`,
  `persisted_copies`, `heuristic_rows` e `heuristic_copies`.
- `GET /decks/:id/analysis` e `POST /decks/:id/ai-analysis` agora carregam
  `card_function_tags` por `card_id` e entregam esses sinais para o sumario.
- O foundation runner foi executado em dry-run e apply para popular/atualizar
  tags, role scores, sinergias e penalidades geradas.

## Foundation dry-run

Artifact:

- `server/test/artifacts/semantic_layer_operational_foundation_2026-05-18_dry_run/summary_dry_run.json`

Resumo sanitizado:

- `db_mutations=false`
- `cards_scanned=33324`
- `cards_with_function_tags=23434`
- `function_tag_rows_planned=59712`
- `role_score_rows_planned=45425`
- `commander_synergy_rows_planned=5000`
- `rejection_penalty_rows_planned=371`
- `function_tag_coverage_pct=70.322`

## Foundation apply

Artifact:

- `server/test/artifacts/semantic_layer_operational_foundation_2026-05-18_apply/summary_apply.json`

Resumo sanitizado:

- `db_mutations=true`
- `upserted_function_tags=59712`
- `upserted_role_scores=45425`
- `upserted_commander_synergies=5000`
- `upserted_rejection_penalties=371`
- `pruned_stale_function_tags=294`
- `pruned_stale_role_scores=1134`

## Validacoes

- `dart analyze lib/ai/functional_card_tags.dart lib/ai/candidate_quality_data_support.dart 'routes/decks/[id]/analysis/index.dart' 'routes/decks/[id]/ai-analysis/index.dart' test/functional_card_tags_test.dart test/candidate_quality_data_support_test.dart`: PASS.
- `dart test test/functional_card_tags_test.dart test/candidate_quality_data_support_test.dart -r expanded`: PASS.
- Servidor local `PORT=8082` com backend real: `GET /health`: PASS.
- `dart test test/deck_analysis_contract_test.dart -r expanded`: PASS, `3/3`.

## Prova publica app/runtime

Artifact:

- `app/doc/runtime_flow_proofs_2026-05-18_deck_functional_tags_persisted_source/summary.json`

Resumo sanitizado no backend publico `04ec676f42f452acbbca3f96a2ee1852015d7974`:

- iPhone 15 Simulator `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`: PASS.
- `GET /decks/:id/analysis`: `200`.
- `functional_tags.schema_version=functional_card_tags_v1_2026_05_18`.
- `functional_tags.source.priority=persisted_then_heuristic`.
- `persisted_rows=5`, `persisted_copies=5`.
- `heuristic_rows=2`, `heuristic_copies=2`.
- Contagens principais: `ramp=2`, `draw=1`, `removal=2`.
- Cobertura da fixture: `card_rows=7`, `tagged_rows=6`.
- UI renderizou a secao de funcoes e exibiu amostra de ramp.

## Riscos restantes

- A classificacao continua deterministica/heuristica; a persistencia melhora
  estabilidade e auditabilidade, mas nao substitui revisao humana para casos
  ambiguos.
- O deploy publico foi provado para leitura persistida na rota de analysis e
  na UI de Deck Analysis, mas a prova e uma fixture pequena e nao substitui
  auditoria semantica massiva.
- Previews brutos do runner foram descartados do versionamento; ficam
  versionados apenas summaries e `tag_counts.csv` para evitar excesso de
  nomes/listas em artefatos.

## Proximo passo recomendado

Medir impacto no `optimize aggressive` e no `generate` usando esses sinais:

- comparar antes/depois de contagem funcional em decks reais sanitizados;
- verificar se `functional_tags.source.persisted_rows` cresce nos decks
  testados;
- registrar falsos positivos/negativos reportados por usuarios com nome da
  carta e tag esperada.
