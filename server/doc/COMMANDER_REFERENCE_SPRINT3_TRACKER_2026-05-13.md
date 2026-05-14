# Commander Reference Sprint 3 Tracker - 2026-05-13

## Objetivo

Acompanhar a execucao controlada do Sprint 3 Commander Reference em lotes
pequenos, sem promocao automatica e sem guidance forte antes de repetir todos os
gates por comandante.

Este tracker nao altera runtime, app mobile, endpoints app-facing, scanner,
camera ou OCR.

## Referencias

- `server/doc/COMMANDER_REFERENCE_SPRINT3_PLAN_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_A_CORPUS_PREP_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_A_PUBLIC_PROOF_2026-05-13.md`
- `app/doc/runtime_flow_handoffs/commander_reference_sprint3_lot_a_app_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_A_FINAL_2026-05-13.md`
- `server/bin/commander_reference_deck_corpus.dart`

## Status por comandante

| Prioridade | Commander | Lote | Cobertura esperada | corpus_prepared | dry_run | apply | idempotency | public_proof | readiness_scorecard | promoted |
| ---: | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `Krenko, Mob Boss` | A | Mono-red goblin typal/go-wide tokens/haste | DONE | DONE | DONE | DONE | PASS | PASS score 100 `ready_for_mini_batch` | true |
| 2 | `Light-Paws, Emperor's Voice` | A | Mono-white auras/Voltron/protection | DONE | DONE | DONE | DONE | PASS | PASS score 100 `ready_for_mini_batch` | true |
| 3 | `Niv-Mizzet, Parun` | A | Izzet spellslinger/draw-damage/control-combo lanes | DONE | DONE | DONE | DONE | PASS | PASS score 100 `ready_for_mini_batch` | true |
| 4 | `Teysa Karlov` | A | Orzhov aristocrats/tokens/death triggers | DONE | DONE | DONE | DONE | PASS | PASS score 100 `ready_for_mini_batch` | true |
| 5 | `Meren of Clan Nel Toth` | B | Golgari graveyard recursion/sacrifice value | DONE | DONE, PASS | DONE | DONE | PASS | PASS score 100 `ready_for_mini_batch` | true |
| 6 | `Korvold, Fae-Cursed King` retry | B | Jund sacrifice/treasure/value-combo | DONE | DONE, PASS | DONE | DONE | PASS | PASS score 100 `ready_for_mini_batch` | true |
| 7 | `Sythis, Harvest's Hand` | B | Selesnya enchantress value | DONE | DONE, PASS | DONE | DONE | PASS | PASS score 100 `ready_for_mini_batch` | true |
| 8 | `Urza, Lord High Artificer` | B | Mono-blue artifacts/control/combo with explicit power lane | DONE | DONE, PASS | DONE | DONE | PASS | PASS score 100 `ready_for_mini_batch` | true |
| 9 | `Brago, King Eternal` | C | Azorius blink/ETB value/control | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | false |
| 10 | `Feather, the Redeemed` | C | Boros spellslinger-Voltron/protection combat | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | false |
| 11 | `Jodah, the Unifier` | C | Five-color legendary typal/value-combat | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | false |
| 12 | `Ghave, Guru of Spores` | C | Abzan tokens/+1/+1 counters/aristocrats-combo | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | false |

## Lote A corpus prep - 2026-05-13

Artifacts:
`server/test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/<safe_commander>/corpus.json`
e
`server/test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/<safe_commander>/dry_run/`.

| Commander | Decks | Dry-run | DB mutations | Commander/main | unresolved | off_color | singleton |
| --- | ---: | --- | --- | --- | ---: | ---: | --- |
| `Krenko, Mob Boss` | 4 | PASS | false | 1/99 em 4/4 | 0 | 0 | `{}` em 4/4 |
| `Light-Paws, Emperor's Voice` | 4 | PASS | false | 1/99 em 4/4 | 0 | 0 | `{}` em 4/4 |
| `Niv-Mizzet, Parun` | 5 | PASS | false | 1/99 em 5/5 | 0 | 0 | `{}` em 5/5 |
| `Teysa Karlov` | 5 | PASS | false | 1/99 em 5/5 | 0 | 0 | `{}` em 5/5 |

## Historico de promocao

Lote A saiu de **corpus_prepared/dry_run only** para apply controlado em
2026-05-13. `--apply` e idempotencia passaram para todos os quatro comandantes,
mas public proof permanece `NOT_RUN` e o readiness scorecard pos-apply ficou
`PASS_WITH_RISKS` por `public_runtime_proof_missing`; portanto nenhum comandante
do Sprint 3 esta promovido ou autorizado como guidance forte.

Atualizacao posterior em 2026-05-13: a prova publica 5/5 de `/ai/generate`
passou para os quatro comandantes aplicados do Lote A no backend publico
`ac8318386d33f2b31425989fbe5dd3500ca56213`. Os scorecards com
`--runtime-summary` retornaram `score=100`, `ready_for_mini_batch`,
`warnings=[]` e `blockers=[]`; portanto Krenko, Light-Paws, Niv-Mizzet e Teysa
foram promovidos para mini-batch controlado.

## Lote A apply + readiness pos-corpus - 2026-05-13

Artifacts novos:
`server/test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/<safe_commander>/dry_run_pre_apply/`,
`apply/`, `apply_idempotency/` e
`server/test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/readiness_after_corpus/`.

| Commander | Dry-run pre-apply | Apply | Idempotency | Readiness sem runtime summary |
| --- | --- | --- | --- | --- |
| `Krenko, Mob Boss` | PASS 4/4, unresolved=0, off_color=0, 1/99, singleton `{}` | PASS 4/4 | PASS 4/4 | 98, `profile_ready_needs_proof`, warning `public_runtime_proof_missing` |
| `Light-Paws, Emperor's Voice` | PASS 4/4, unresolved=0, off_color=0, 1/99, singleton `{}` | PASS 4/4 | PASS 4/4 | 98, `profile_ready_needs_proof`, warning `public_runtime_proof_missing` |
| `Niv-Mizzet, Parun` | PASS 5/5, unresolved=0, off_color=0, 1/99, singleton `{}` | PASS 5/5 | PASS 5/5 | 98, `profile_ready_needs_proof`, warning `public_runtime_proof_missing` |
| `Teysa Karlov` | PASS 5/5, unresolved=0, off_color=0, 1/99, singleton `{}` | PASS 5/5 | PASS 5/5 | 98, `profile_ready_needs_proof`, warning `public_runtime_proof_missing` |

## Lote A public proof + promocao - 2026-05-13

Artifacts novos:
`server/test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/<safe_commander>/public_proof/summary.json`
e
`server/test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/<safe_commander>/readiness_public/readiness_scorecard_summary.json`.

| Commander | Public proof | Runtime gates | p50/p95 | Readiness publico | Promoted |
| --- | --- | --- | --- | --- | --- |
| `Krenko, Mob Boss` | PASS 5/5 | HTTP 200, validation, commander, main 99, profile/stats/corpus; invalid=0, off_identity=0, timeout=0 | 888ms / 1233ms | score 100, `ready_for_mini_batch` | true |
| `Light-Paws, Emperor's Voice` | PASS 5/5 | HTTP 200, validation, commander, main 99, profile/stats/corpus; invalid=0, off_identity=0, timeout=0 | 873ms / 952ms | score 100, `ready_for_mini_batch` | true |
| `Niv-Mizzet, Parun` | PASS 5/5 | HTTP 200, validation, commander, main 99, profile/stats/corpus; invalid=0, off_identity=0, timeout=0 | 857ms / 981ms | score 100, `ready_for_mini_batch` | true |
| `Teysa Karlov` | PASS 5/5 | HTTP 200, validation, commander, main 99, profile/stats/corpus; invalid=0, off_identity=0, timeout=0 | 856ms / 908ms | score 100, `ready_for_mini_batch` | true |

## Lote B corpus prep/dry-run - 2026-05-14

Artifacts:
`server/test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/<safe_commander>/corpus.json`
e
`server/test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/<safe_commander>/dry_run/`.

Relatorios:
`server/doc/COMMANDER_REFERENCE_SPRINT3_LOT_B_PLAN_2026-05-14.md` e
`server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_B_CORPUS_PREP_2026-05-14.md`.

| Commander | Decks | Dry-run | DB mutations | Commander/main | unresolved | off_color | singleton |
| --- | ---: | --- | --- | --- | ---: | ---: | --- |
| `Meren of Clan Nel Toth` | 3 | PASS | false | 1/99 em 3/3 | 0 | 0 | `{}` em 3/3 |
| `Korvold, Fae-Cursed King` | 4 | PASS | false | 1/99 em 4/4 | 0 | 0 | `{}` em 4/4 |
| `Sythis, Harvest's Hand` | 5 | PASS | false | 1/99 em 5/5 | 0 | 0 | `{}` em 5/5 |
| `Urza, Lord High Artificer` | 5 | PASS | false | 1/99 em 5/5 | 0 | 0 | `{}` em 5/5 |

Na etapa de corpus prep, `--apply` nao foi executado por escopo e o Lote B ficou
sem idempotencia, public proof, readiness final ou promocao. O resultado daquela
etapa foi **PASS_WITH_RISKS** por Meren ter fontes especificas excluidas por
unresolved local, Korvold carregar historico de core package fraco e Urza exigir
lane high-power/combo explicita.

## Lote B apply + readiness pos-corpus - 2026-05-14

Artifacts novos:
`server/test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/<safe_commander>/dry_run_pre_apply/`,
`apply/`, `apply_idempotency/` e
`server/test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/readiness_after_corpus/`.

Relatorio atualizado:
`server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_B_CORPUS_PREP_2026-05-14.md`.

| Commander | Dry-run pre-apply | Apply | Idempotency | Readiness sem runtime summary |
| --- | --- | --- | --- | --- |
| `Meren of Clan Nel Toth` | PASS 3/3, unresolved=0, off_color=0, 1/99, singleton `{}` | PASS 3/3 | PASS 3/3 | 98, `profile_ready_needs_proof`, warning `public_runtime_proof_missing` |
| `Korvold, Fae-Cursed King` | PASS 4/4, unresolved=0, off_color=0, 1/99, singleton `{}` | PASS 4/4 | PASS 4/4 | 98, `profile_ready_needs_proof`, warning `public_runtime_proof_missing` |
| `Sythis, Harvest's Hand` | PASS 5/5, unresolved=0, off_color=0, 1/99, singleton `{}` | PASS 5/5 | PASS 5/5 | 98, `profile_ready_needs_proof`, warning `public_runtime_proof_missing` |
| `Urza, Lord High Artificer` | PASS 5/5, unresolved=0, off_color=0, 1/99, singleton `{}` | PASS 5/5 | PASS 5/5 | 98, `profile_ready_needs_proof`, warning `public_runtime_proof_missing` |

Contagens DB-backed pos-apply: Meren 3/3, Korvold 8/8, Sythis 5/5 e Urza 5/5
linhas aceitas totais por comandante, todas com unresolved/off-color 0,
`commander_quantity=1`, `main_quantity=99` e singleton limpo. Korvold ja tinha 4
linhas historicas antes deste apply; o corpus Lote B validado nesta rodada foi
4/4 nos artifacts.

Resultado: **PASS_WITH_RISKS** porque public proof/runtime summary nao foi
executado por escopo. Nenhum comandante do Lote B foi promovido.

## Lote B public proof + promocao - 2026-05-14

Relatorio:
`server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_B_PUBLIC_PROOF_2026-05-14.md`.

Artifacts novos:
`server/test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/<safe_commander>/public_proof/summary.json`
e
`server/test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/<safe_commander>/readiness_public/readiness_scorecard_summary.json`.

| Commander | Public proof | Runtime gates | p50/p95 | Readiness publico | Promoted |
| --- | --- | --- | --- | --- | --- |
| `Meren of Clan Nel Toth` | PASS 5/5 | HTTP 200, validation, commander, main 99, profile/stats/corpus; invalid=0, off_identity=0, timeout=0 | 854ms / 1238ms | score 100, `ready_for_mini_batch` | true |
| `Korvold, Fae-Cursed King` | PASS 5/5 | HTTP 200, validation, commander, main 99, profile/stats/corpus; invalid=0, off_identity=0, timeout=0 | 878ms / 942ms | score 100, `ready_for_mini_batch` | true |
| `Sythis, Harvest's Hand` | PASS 5/5 | HTTP 200, validation, commander, main 99, profile/stats/corpus; invalid=0, off_identity=0, timeout=0 | 651ms / 667ms | score 100, `ready_for_mini_batch` | true |
| `Urza, Lord High Artificer` | PASS 5/5 | HTTP 200, validation, commander, main 99, profile/stats/corpus; invalid=0, off_identity=0, timeout=0 | 652ms / 757ms | score 100, `ready_for_mini_batch` | true |

Observacao operacional: o primeiro disparo continuo encontrou rate limit publico
`429` apos dez chamadas; Sythis e Urza foram rerodados com backoff e os summaries
rate-limited ficaram preservados em `public_proof_rate_limited_attempt/`.

## Fechamento parcial Lote A - 2026-05-13

Relatorio final:
`server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_A_FINAL_2026-05-13.md`.

Resultado consolidado: **PASS_WITH_RISKS**.

- Backend/public proof: PASS. Krenko, Light-Paws, Niv-Mizzet e Teysa foram
  promovidos para mini-batch controlado com score 100,
  `ready_for_mini_batch`, timeout fallback 0/5, invalid/off-identity 0 e p95
  maximo 1233ms.
- App runtime: BLOCKED. O harness especifico Lote A foi criado, mas Android
  fisico travou antes da primeira interacao de UI e iPhone 15 Simulator ficou
  bloqueado pela dependencia nativa MLImage/Scanner. Deck Details/validate via app
  nao foi provado nesta rodada.
- API map: consultado e mantido sem alteracao porque nao houve mudanca de rota,
  payload, response shape, diagnostics app-facing, data source ou consumidor
  mobile.

Decisao para o Lote B: **GO condicionado** para corpus offline/backend,
dry-run, apply, idempotencia, public proof e readiness scorecard de
`Meren of Clan Nel Toth`, `Korvold, Fae-Cursed King` retry,
`Sythis, Harvest's Hand` e `Urza, Lord High Artificer`. Continua **NO-GO** para
declarar PASS completo de produto ou ampliar guidance sem ressalvas enquanto a
prova app runtime permanecer bloqueada.
