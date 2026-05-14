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
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_AB_CONSOLIDATION_2026-05-14.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_C_CORPUS_PREP_2026-05-14.md`
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
| 9 | `Purphoros, God of the Forge` | C | Mono-red token payoff/burn sem repetir Goblin typal de Krenko | DONE | DONE, PASS | DONE | DONE | BLOCKED 5/5 legal sem profile/stats/corpus | BLOCKED score 25 `blocked` | false |
| 10 | `Brago, King Eternal` | C | Azorius blink/ETB value/control sem stax duro como default | DONE | DONE, PASS | DONE | DONE | PASS | PASS score 100 `ready_for_mini_batch` | true |
| 11 | `Veyran, Voice of Duality` | C | Izzet magecraft/spell-copy/prowess sem repetir Niv draw-damage control | DONE | DONE, PASS | DONE | DONE | BLOCKED 5/5 legal sem profile/stats/corpus | BLOCKED score 25 `blocked` | false |
| 12 | `Balan, Wandering Knight` | C | Mono-white Equipment Voltron sem repetir Light-Paws aura tutor | DONE | DONE, PASS | DONE | DONE | BLOCKED 5/5 legal sem profile/stats/corpus | BLOCKED score 25 `blocked` | false |

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

## Consolidacao Lotes A+B e decisao Lote C - 2026-05-14

Relatorio:
`server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_AB_CONSOLIDATION_2026-05-14.md`.

Resultado consolidado: **PASS_WITH_RISKS**.

- Promovidos A+B: Krenko, Light-Paws, Niv-Mizzet, Teysa, Meren, Korvold, Sythis
  e Urza, todos com corpus/apply/idempotencia PASS, public proof 5/5,
  `score=100`, `ready_for_mini_batch`, invalid/off-identity 0 e timeout fallback
  0/5.
- App runtime real: PASS_WITH_RISKS no Android fisico `SM A135M` para Krenko,
  Teysa, Urza e Meren, cobrindo register/login, Generate Commander com
  `commander_name`, preview, save, Deck Details e `/decks/:id/validate`.
- Riscos: workaround de rede celular no Android por timeout Wi-Fi, iPhone 15
  Simulator ainda nao provado por `MLImage.framework`/scanner, `429` em prova
  publica de lote exige backoff, e `GET /decks/:id.commander_name` agregado nao
  foi fonte de verdade no Lote B.
- API map: consultado e mantido sem alteracao porque nao houve drift de rota,
  payload, response shape, diagnostics app-facing, async job, data source ou
  consumidor mobile.
- Lote C recomendado: `Purphoros, God of the Forge`, `Brago, King Eternal`,
  `Veyran, Voice of Duality` e `Balan, Wandering Knight`, priorizando lacunas
  red tokens sem Goblin typal, Azorius blink/control, Izzet magecraft e
  mono-white Equipment sem repetir diretamente Krenko, Niv ou Light-Paws.

## Lote C corpus prep/dry-run - 2026-05-14

Artifacts:
`server/test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/<safe_commander>/corpus.json`
e
`server/test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/<safe_commander>/dry_run/`.

Relatorio:
`server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_C_CORPUS_PREP_2026-05-14.md`.

| Commander | Decks | Dry-run | DB mutations | Commander/main | unresolved | off_color | singleton |
| --- | ---: | --- | --- | --- | ---: | ---: | --- |
| `Purphoros, God of the Forge` | 5 | PASS | false | 1/99 em 5/5 | 0 | 0 | `{}` em 5/5 |
| `Brago, King Eternal` | 4 | PASS | false | 1/99 em 4/4 | 0 | 0 | `{}` em 4/4 |
| `Veyran, Voice of Duality` | 4 | PASS | false | 1/99 em 4/4 | 0 | 0 | `{}` em 4/4 |
| `Balan, Wandering Knight` | 4 | PASS | false | 1/99 em 4/4 | 0 | 0 | `{}` em 4/4 |

Na etapa de corpus prep, `--apply` nao foi executado por escopo e o Lote C ficou
sem idempotencia, public proof, readiness final ou promocao. O resultado e
**PASS_WITH_RISKS** porque Veyran precisou excluir fontes EDHREC high-signal
default/spellslinger/spell-copy/storm por unresolved local de cartas recentes,
embora o corpus final aceito esteja estruturalmente limpo.

## Lote C apply + readiness pos-corpus - 2026-05-14

Artifacts novos:
`server/test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/<safe_commander>/dry_run_pre_apply/`,
`apply/`, `apply_idempotency/` e
`server/test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/readiness_after_corpus/`.

Relatorio atualizado:
`server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_C_CORPUS_PREP_2026-05-14.md`.

| Commander | Dry-run pre-apply | Apply | Idempotency | Readiness sem runtime summary |
| --- | --- | --- | --- | --- |
| `Purphoros, God of the Forge` | PASS 5/5, unresolved=0, off_color=0, 1/99, singleton `{}` | PASS 5/5 | PASS 5/5 | 25, `blocked`, blockers profile/card_stats/deterministic |
| `Brago, King Eternal` | PASS 4/4, unresolved=0, off_color=0, 1/99, singleton `{}` | PASS 4/4 | PASS 4/4 | 98, `profile_ready_needs_proof`, warning `public_runtime_proof_missing` |
| `Veyran, Voice of Duality` | PASS 4/4, unresolved=0, off_color=0, 1/99, singleton `{}` | PASS 4/4 | PASS 4/4 | 25, `blocked`, blockers profile/card_stats/deterministic |
| `Balan, Wandering Knight` | PASS 4/4, unresolved=0, off_color=0, 1/99, singleton `{}` | PASS 4/4 | PASS 4/4 | 25, `blocked`, blockers profile/card_stats/deterministic |

Contagens DB-backed pos-apply: Purphoros 5/5, Brago 4/4, Veyran 4/4 e Balan
4/4 linhas aceitas totais por comandante, todas com unresolved/off-color 0,
`commander_quantity=1`, `main_quantity=99` e singleton limpo. Pre-change para o
Lote C era 0 linhas por comandante. Nenhum comandante do Lote C foi promovido.

## Lote C public proof + decisao - 2026-05-14

Relatorio:
`server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_C_PUBLIC_PROOF_2026-05-14.md`.

Artifacts novos:
`server/test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/<safe_commander>/public_proof/summary.json`
e
`server/test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/<safe_commander>/readiness_public/readiness_scorecard_summary.json`.

| Commander | Public proof | Runtime gates | p50/p95 | Readiness publico | Promoted |
| --- | --- | --- | --- | --- | --- |
| `Purphoros, God of the Forge` | BLOCKED | HTTP 200, validation, commander e main 99 em 5/5; profile/stats/corpus 0/5; invalid=0, off_identity=0, timeout=0 | 794ms / 12590ms | score 25, `blocked`, blockers profile/card_stats/deterministic | false |
| `Brago, King Eternal` | PASS | HTTP 200, validation, commander, main 99, profile/stats/corpus em 5/5; invalid=0, off_identity=0, timeout=0 | 864ms / 942ms | score 100, `ready_for_mini_batch` | true |
| `Veyran, Voice of Duality` | BLOCKED | HTTP 200, validation, commander e main 99 em 5/5; profile/stats/corpus 0/5; invalid=0, off_identity=0, timeout=0 | 794ms / 11112ms | score 25, `blocked`, blockers profile/card_stats/deterministic | false |
| `Balan, Wandering Knight` | BLOCKED | HTTP 200, validation, commander e main 99 em 5/5; profile/stats/corpus 0/5; invalid=0, off_identity=0, timeout=0 | 826ms / 15568ms | score 25, `blocked`, blockers profile/card_stats/deterministic | false |

Decisao: apenas Brago foi promovido para mini-batch controlado. O Lote C como
conjunto fica **BLOCKED** ate aplicar/corrigir Commander Reference Profile,
Card Stats e fallback deterministico para Purphoros, Veyran e Balan e repetir a
prova publica.

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
