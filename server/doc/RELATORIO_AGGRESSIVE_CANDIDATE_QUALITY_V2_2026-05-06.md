# Relatorio Aggressive Candidate Quality v2 - 2026-05-06

## Resultado

**PASS.** O follow-up removeu com seguranca 1 row stale gerada em `card_role_scores`, sem upsert amplo e sem alterar `cards`, `sets`, `card_legalities`, legalidade Commander, identidade de cor, bracket ou contratos app-facing.

## Comandos executados

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia && git fetch origin master && git pull --ff-only origin master
cd server && dart run bin/candidate_quality_data_foundation.dart --dry-run --artifact-dir=test/artifacts/release_data_readiness_2026-05-06/follow_up_candidate_quality_dry_run
cd server && dart run bin/candidate_quality_data_foundation.dart --prune-stale-only --target=card_role_scores --max-prune=1 --artifact-dir=test/artifacts/release_data_readiness_2026-05-06/follow_up_candidate_quality_prune_only
cd server && dart run bin/candidate_quality_data_foundation.dart --dry-run --artifact-dir=test/artifacts/release_data_readiness_2026-05-06/follow_up_candidate_quality_post_prune_dry_run
cd server && dart run bin/candidate_quality_data_foundation.dart --prune-stale-only --target=card_role_scores --max-prune=1 --artifact-dir=test/artifacts/release_data_readiness_2026-05-06/follow_up_candidate_quality_prune_idempotence
cd server && dart analyze bin lib routes/cards routes/sets test
cd server && dart test test/sets_route_test.dart test/cards_route_test.dart test/candidate_quality_data_support_test.dart -r expanded
```

Linhas de conexao DB foram tratadas como configuracao operacional e nao sao reproduzidas. Nenhum `DATABASE_URL`, JWT, token, prompt ou payload sensivel foi documentado.

## Dry-run antes do prune

| Tabela | Stale rows |
|---|---:|
| `card_function_tags` | 0 |
| `card_role_scores` | 1 |
| `commander_card_synergy` | 0 |
| `optimize_rejection_penalties` | 0 |

O dry-run gerou `stale_generated_rows_preview.json/csv` com a chave exata da row stale. A linha estava em `card_role_scores`, `source='deterministic_heuristic_v1'`, role `ramp`, `format='commander'`, `subformat='any'`, `bracket_scope='any'`, `budget_tier='unknown'`. Esse dado e metadata advisory e nao participa como fonte de verdade de legalidade, identidade de cor ou bracket.

## Apply/prune

O cleanup usou o novo modo:

```bash
dart run bin/candidate_quality_data_foundation.dart --prune-stale-only --target=card_role_scores --max-prune=1
```

Guardrails do modo:

- exige `--target=card_role_scores`;
- nao executa `_ensureCandidateQualitySchema`;
- nao executa upsert de tags, role scores, synergies ou rejection penalties;
- reconsulta o conjunto stale dentro da transacao;
- aborta se as chaves divergirem do preview ou se exceder `--max-prune`;
- grava `stale_generated_rows_pruned.json/csv`.

## Contagens pre/post

| Objeto | Antes | Depois |
|---|---:|---:|
| `card_function_tags` | 33.011 | 33.011 |
| `card_role_scores` | 31.898 | 31.897 |
| `commander_card_synergy` | 7.179 | 7.179 |
| `optimize_rejection_penalties` | 358 | 358 |

Post-prune dry-run:

| Tabela | Stale rows |
|---|---:|
| `card_function_tags` | 0 |
| `card_role_scores` | 0 |
| `commander_card_synergy` | 0 |
| `optimize_rejection_penalties` | 0 |

## Code changes

- `server/bin/candidate_quality_data_foundation.dart`
  - adiciona artifacts `stale_generated_rows_preview.json/csv`;
  - adiciona `--prune-stale-only --target=card_role_scores --max-prune=N`;
  - adiciona transacao com guard de chaves para prune de `card_role_scores`;
  - adiciona artifacts `stale_generated_rows_pruned.json/csv`.

## DB changes

Foi removida 1 row obsoleta em `card_role_scores` com `source='deterministic_heuristic_v1'`. Nenhuma row source-of-truth foi alterada.

Rollback note: se for necessario restaurar exatamente a linha removida, usar `server/test/artifacts/release_data_readiness_2026-05-06/follow_up_candidate_quality_prune_only/stale_generated_rows_pruned.json` para reinserir a chave composta em `card_role_scores`. Restaurar nao e recomendado como rotina, porque a row nao aparece no plano deterministico atual.

## Validacao

| Comando | Resultado |
|---|---|
| `dart analyze bin lib routes/cards routes/sets test` | PASS |
| `dart test test/sets_route_test.dart test/cards_route_test.dart test/candidate_quality_data_support_test.dart -r expanded` | PASS, `+11` |
| Post dry-run candidate quality | PASS, stale generated rows = 0 |
| Prune-only idempotence | PASS, 0 rows removidas, `db_mutations=false` |

## Remaining unresolved

| Item | Status |
|---|---|
| Human reviewed tags | not proven |
| AI-generated tags | not used |
| Budget tier amplo | `unknown` ainda aparece em rows deterministic heuristic |
| Duplicate `sets.code` casing | tratado no relatorio MTG Data Integrity de 2026-05-06 |
