# Relatorio Aggressive Candidate Quality v2 - Etapa 1

Data: 2026-05-05

## Resultado

**PASS.** Foi criada uma base de dados aditiva, idempotente e DB-backed para melhorar candidatos do `optimize` aggressive sem inserir novas cartas e sem alterar `cards`, `card_legalities`, `cards.color_identity` ou regras de bracket/legalidade.

## Escopo entregue

- Novo helper testavel: `server/lib/ai/candidate_quality_data_support.dart`.
- Novo comando operacional: `server/bin/candidate_quality_data_foundation.dart`.
- Novo teste: `server/test/candidate_quality_data_support_test.dart`.
- Novas tabelas aditivas:
  - `card_function_tags`
  - `card_role_scores`
  - `commander_card_synergy`
  - `optimize_rejection_penalties`
- Nova view aditiva:
  - `optimize_candidate_quality_summary`
- Indices para lookup por tag/role/commander/penalidade.

## Guardrails

- O comando default e `--dry-run`; sem `--apply` nao executa escrita.
- O apply usa `INSERT ... ON CONFLICT DO UPDATE` e chaves primarias naturais para evitar duplicidade.
- A selecao canonica de printings usa desempate deterministico por `c.id`.
- A poda remove apenas linhas obsoletas das fontes geradas por este comando:
  - `deterministic_heuristic_v1`
  - `meta_decks_cooccurrence_v1`
  - `quality_gate_history_v1`
- Tags e scores nao sobrescrevem legalidade, identidade de cor, bracket ou dados source-of-truth.
- O SQL de sample pools mantem filtros de Commander legality e `color_identity <@ commander_identity`.
- Nao houve IA offline nem chamada externa em request path.

## Comandos executados

```bash
cd server && dart analyze lib/ai/candidate_quality_data_support.dart bin/candidate_quality_data_foundation.dart test/candidate_quality_data_support_test.dart
cd server && dart test test/candidate_quality_data_support_test.dart
cd server && dart run bin/candidate_quality_data_foundation.dart --dry-run --artifact-dir=test/artifacts/aggressive_candidate_quality_v2_2026-05-05
cd server && dart run bin/candidate_quality_data_foundation.dart --apply --artifact-dir=test/artifacts/aggressive_candidate_quality_v2_2026-05-05
cd server && dart run bin/candidate_quality_data_foundation.dart --apply --artifact-dir=test/artifacts/aggressive_candidate_quality_v2_2026-05-05/idempotence
cd server && dart run bin/candidate_quality_data_foundation.dart --dry-run --artifact-dir=test/artifacts/aggressive_candidate_quality_v2_2026-05-05/post_fix_dry_run
cd server && dart run bin/candidate_quality_data_foundation.dart --apply --artifact-dir=test/artifacts/aggressive_candidate_quality_v2_2026-05-05/post_fix_apply
cd server && dart run bin/candidate_quality_data_foundation.dart --apply --artifact-dir=test/artifacts/aggressive_candidate_quality_v2_2026-05-05/final_idempotence
cd server && dart run bin/mtg_data_integrity.dart --artifact-dir=test/artifacts/mtg_data_integrity_2026-05-05_acqv2
cd server && dart analyze bin lib routes test
cd server && dart test test/sets_route_test.dart test/cards_route_test.dart test/candidate_quality_data_support_test.dart
```

## Cobertura medida

Fonte: `server/test/artifacts/aggressive_candidate_quality_v2_2026-05-05/final_idempotence/summary_apply.json`.

| Metrica | Valor |
|---|---:|
| `cards` no banco | 33774 |
| cards canonicas escaneadas | 33312 |
| cards com tags deterministicas | 20002 |
| cobertura de tags | 60.04% |
| `card_function_tags` final | 33011 |
| `card_role_scores` final | 30988 |
| `commander_card_synergy` final | 5000 |
| `optimize_rejection_penalties` final | 358 |
| `card_meta_insights` disponiveis | 33274 |
| `meta_decks` disponiveis | 650 |
| `optimization_analysis_logs` disponiveis | 534 |

## Tags funcionais

| Tag | Linhas |
|---|---:|
| sacrifice | 5610 |
| graveyard | 4723 |
| removal | 4700 |
| token | 3912 |
| draw | 3619 |
| ramp | 3092 |
| mana_fixing | 1606 |
| protection | 1234 |
| recursion | 1209 |
| board_wipe | 834 |
| aristocrats | 702 |
| tutor | 633 |
| counterspell | 439 |
| wincon | 402 |
| stax | 149 |
| combo_piece | 147 |

## Role scores, bracket e budget

- Role score rows: 30988.
- Bracket scopes:
  - `any`: 27209
  - `bracket_2_4`: 3637
  - `bracket_3_4`: 142
- Budget tier atual: `unknown` para 30988 rows porque os campos de preco canonicos analisados estavam sem valor confiavel para essa etapa. Isso foi mantido explicito, sem inferencia artificial.

## Synergy e sample pools

`commander_card_synergy` foi derivada apenas de coocorrencia em `meta_decks` Commander/cEDH, com `evidence_count >= 2`, limite inicial de 5000 linhas e sem adicionar cartas.

Sample pools gerados em `sample_candidate_pools.json`:

| Shell / Commander | Identidade | Guardrails |
|---|---|---|
| Spider-Man 2099 | U/R | legal/restricted/null + subset de color identity |
| Kraum, Ludevic's Opus | U/R | legal/restricted/null + subset de color identity |
| Thrasios, Triton Hero | G/U | legal/restricted/null + subset de color identity |

Exemplos de candidatos filtrados: `Arcane Signet`, `Counterspell`, `Fierce Guardianship`, `Force of Negation`, `Birds of Paradise`, `Delighted Halfling`. O sample mostra `bracket_scope`, `legal_status` e `color_identity` para auditar que tags nao viram bypass.

## Penalidades de rejeicao

`optimize_rejection_penalties` recebeu 358 linhas agregadas a partir de `optimization_analysis_logs` falhos/reprovados. A tabela guarda apenas nomes de carta, commander/archetype agregados, contagem e penalidade; nao armazena prompt, JWT, user id, payload sensivel ou secrets.

## Dry-run/apply e idempotencia

Dry-run inicial:

- `db_mutations=false`.
- `card_function_tags`, `card_role_scores`, `commander_card_synergy`, `optimize_rejection_penalties` permaneceram em 0.

Apply final:

- `db_mutations=true`.
- `cards`, `card_meta_insights`, `meta_decks` e `optimization_analysis_logs` mantiveram os mesmos contadores antes/depois.
- Somente tabelas novas/aditivas receberam linhas.

Idempotencia final:

| Tabela | Pre | Post |
|---|---:|---:|
| card_function_tags | 33011 | 33011 |
| card_role_scores | 30988 | 30988 |
| commander_card_synergy | 5000 | 5000 |
| optimize_rejection_penalties | 358 | 358 |

Antes da correção deterministica, o dry-run `post_fix_dry_run` apontou stale rows geradas pela propria fonte: 6 tags, 3 role scores e 69 synergies. O apply `post_fix_apply` removeu somente essas linhas geradas, retornando aos contadores canonicos. O apply `final_idempotence` confirmou stale rows = 0.

## Auditoria MTG data integrity complementar

Fonte: `server/test/artifacts/mtg_data_integrity_2026-05-05_acqv2`.

| Item | Valor |
|---|---:|
| grupos duplicados `LOWER(sets.code)` | 82 |
| `cards.color_identity IS NULL` | 0 |
| candidatos de backfill deterministicos | 0 |
| unresolved color identity | 0 |

Esses contadores foram medidos em dry-run apenas. A etapa nao alterou sets nem color identity.

## Rollback / reversibilidade

Rollback seguro da etapa, se necessario:

```sql
DROP VIEW IF EXISTS optimize_candidate_quality_summary;
DROP TABLE IF EXISTS optimize_rejection_penalties;
DROP TABLE IF EXISTS commander_card_synergy;
DROP TABLE IF EXISTS card_role_scores;
DROP TABLE IF EXISTS card_function_tags;
```

Rollback parcial de dados gerados, preservando schema:

```sql
DELETE FROM card_function_tags WHERE source = 'deterministic_heuristic_v1';
DELETE FROM card_role_scores WHERE source = 'deterministic_heuristic_v1';
DELETE FROM commander_card_synergy WHERE source = 'meta_decks_cooccurrence_v1';
DELETE FROM optimize_rejection_penalties WHERE source = 'quality_gate_history_v1';
```

Nenhum rollback toca em `cards`, `card_legalities`, `sets`, `decks` ou dados de usuario.

## Validacao

- `dart analyze lib/ai/candidate_quality_data_support.dart bin/candidate_quality_data_foundation.dart test/candidate_quality_data_support_test.dart`: PASS.
- `dart test test/candidate_quality_data_support_test.dart`: PASS.
- `dart analyze bin lib routes test`: PASS.
- `dart test test/sets_route_test.dart test/cards_route_test.dart test/candidate_quality_data_support_test.dart`: PASS, 11 testes.
- Dry-run/apply/idempotencia DB-backed: PASS.

## Gaps e proximas etapas

- Consumo runtime pelo `/ai/optimize` ainda nao foi ligado nesta etapa; os dados estao prontos para etapa 2.
- Budget tier ficou `unknown` por falta de preco confiavel na selecao canonica atual.
- Tags sao heuristicas deterministicamente inferidas, nao revisadas manualmente; `source` e `confidence` permitem auditoria posterior.
- Duplicate set-code cleanup permanece fora desta etapa; contagem atual e 82 grupos.
