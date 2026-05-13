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
- `server/bin/commander_reference_deck_corpus.dart`

## Status por comandante

| Prioridade | Commander | Lote | Cobertura esperada | corpus_prepared | dry_run | apply | idempotency | public_proof | readiness_scorecard | promoted |
| ---: | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `Krenko, Mob Boss` | A | Mono-red goblin typal/go-wide tokens/haste | DONE | DONE | DONE | DONE | NOT_RUN | PASS_WITH_RISKS | false |
| 2 | `Light-Paws, Emperor's Voice` | A | Mono-white auras/Voltron/protection | DONE | DONE | DONE | DONE | NOT_RUN | PASS_WITH_RISKS | false |
| 3 | `Niv-Mizzet, Parun` | A | Izzet spellslinger/draw-damage/control-combo lanes | DONE | DONE | DONE | DONE | NOT_RUN | PASS_WITH_RISKS | false |
| 4 | `Teysa Karlov` | A | Orzhov aristocrats/tokens/death triggers | DONE | DONE | DONE | DONE | NOT_RUN | PASS_WITH_RISKS | false |
| 5 | `Meren of Clan Nel Toth` | B | Golgari graveyard recursion/sacrifice value | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | false |
| 6 | `Korvold, Fae-Cursed King` retry | B | Jund sacrifice/treasure/value-combo | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | false |
| 7 | `Sythis, Harvest's Hand` | B | Selesnya enchantress value | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | false |
| 8 | `Urza, Lord High Artificer` | B | Mono-blue artifacts/control/combo with explicit power lane | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | false |
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

## Bloqueio de promocao

Lote A saiu de **corpus_prepared/dry_run only** para apply controlado em
2026-05-13. `--apply` e idempotencia passaram para todos os quatro comandantes,
mas public proof permanece `NOT_RUN` e o readiness scorecard pos-apply ficou
`PASS_WITH_RISKS` por `public_runtime_proof_missing`; portanto nenhum comandante
do Sprint 3 esta promovido ou autorizado como guidance forte.

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
