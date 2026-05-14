# Commander Reference Sprint 3 Lote B Corpus Apply - 2026-05-14

## Verdict

**PASS_WITH_RISKS** para apply controlado, idempotencia e readiness scorecard
pos-corpus sem runtime summary.

Os quatro corpora do Lote B que haviam passado no dry-run foram rerodados em
`dry_run_pre_apply/`, aplicados em `apply/` e reaplicados em
`apply_idempotency/`. Todos mantiveram `accepted_deck_count == deck_count`,
`unresolved=0`, `off_color=0`, `commander_quantity=1`, `main_quantity=99` e
`singleton_violations={}`. O scorecard pos-apply ficou em
**PASS_WITH_RISKS** porque, por escopo, nao foi fornecido runtime summary/public
proof nesta rodada; todos os comandantes ficaram com score 98,
`profile_ready_needs_proof`, sem blockers e com warning unico
`public_runtime_proof_missing`.

## Escopo e seguranca

- Incluido: sync de `master`, releitura do contexto obrigatorio, dry-run
  pre-apply, `--apply`, `--apply` de idempotencia, contagens DB-backed,
  readiness scorecard sem runtime summary, documentacao e validacoes focadas.
- Fora do escopo: public proof 5/5, promocao, runtime app, endpoint
  app-facing, scanner, camera e OCR.
- Nao foram persistidos ou documentados secrets, tokens, JWT, Sentry DSN,
  `DATABASE_URL`, `OPENAI_API_KEY`, credenciais QA, prompts completos ou payload
  sensivel.
- O apply foi idempotente via upsert nas tabelas
  `commander_reference_decks`, `commander_reference_deck_cards` e
  `commander_reference_deck_analysis`; a reaplicacao substitui as linhas do
  mesmo `source_deck_key` e nao cria novas cartas em `cards`.

## Fontes web originais consultadas

As fontes incluidas continuam sendo paginas publicas EDHREC Average Deck
coletadas previamente para artifact offline. Elas provam contexto Commander por
rotulo externo `Average Deck for ...`, `total_card_count=100`, commander no slot
de comando e main deck com 99 cartas no payload publico usado para montar os
corpora offline.

| Commander | Fontes incluidas |
| --- | --- |
| `Meren of Clan Nel Toth` | `https://edhrec.com/average-decks/meren-of-clan-nel-toth`; `https://edhrec.com/average-decks/meren-of-clan-nel-toth/aristocrats`; `https://edhrec.com/average-decks/meren-of-clan-nel-toth/budget` |
| `Korvold, Fae-Cursed King` | `https://edhrec.com/average-decks/korvold-fae-cursed-king`; `https://edhrec.com/average-decks/korvold-fae-cursed-king/treasure`; `https://edhrec.com/average-decks/korvold-fae-cursed-king/sacrifice`; `https://edhrec.com/average-decks/korvold-fae-cursed-king/aristocrats` |
| `Sythis, Harvest's Hand` | `https://edhrec.com/average-decks/sythis-harvests-hand`; `https://edhrec.com/average-decks/sythis-harvests-hand/enchantress`; `https://edhrec.com/average-decks/sythis-harvests-hand/auras`; `https://edhrec.com/average-decks/sythis-harvests-hand/lifegain`; `https://edhrec.com/average-decks/sythis-harvests-hand/budget` |
| `Urza, Lord High Artificer` | `https://edhrec.com/average-decks/urza-lord-high-artificer`; `https://edhrec.com/average-decks/urza-lord-high-artificer/artifacts`; `https://edhrec.com/average-decks/urza-lord-high-artificer/control`; `https://edhrec.com/average-decks/urza-lord-high-artificer/combo`; `https://edhrec.com/average-decks/urza-lord-high-artificer/budget` |

Fontes sondadas e deixadas fora do artifact final permanecem excluidas:

| Commander | Fonte | Motivo |
| --- | --- | --- |
| `Meren of Clan Nel Toth` | `/graveyard` | Dry-run rejeitou por `unresolved_cards`: `Cauldron of Essence`. |
| `Meren of Clan Nel Toth` | `/sacrifice` | Dry-run rejeitou por `unresolved_cards`: `Cauldron of Essence`. |
| `Meren of Clan Nel Toth` | `/self-mill` | Dry-run rejeitou por `unresolved_cards`: `Grave Researcher`. |

## Comandos executados

Executados a partir de `server/`, sem expor valores de variaveis sensiveis:

```bash
dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/<safe_commander>/corpus.json \
  --dry-run \
  --artifact-dir=test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/<safe_commander>/dry_run_pre_apply

dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/<safe_commander>/corpus.json \
  --apply \
  --artifact-dir=test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/<safe_commander>/apply

dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/<safe_commander>/corpus.json \
  --apply \
  --artifact-dir=test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/<safe_commander>/apply_idempotency

dart run bin/commander_reference_readiness_scorecard.dart \
  --commanders="Meren of Clan Nel Toth;Korvold, Fae-Cursed King;Sythis, Harvest's Hand;Urza, Lord High Artificer" \
  --artifact-dir=test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/readiness_after_corpus
```

Contagens pre/post foram feitas com consulta DB-backed usando `psql
"$DATABASE_URL"` sem imprimir o valor da conexao.

## Contagens DB-backed

Pre-change:

| Commander | Deck rows | Accepted rows | unresolved_total | off_color_total |
| --- | ---: | ---: | ---: | ---: |
| `Meren of Clan Nel Toth` | 0 | 0 | 0 | 0 |
| `Korvold, Fae-Cursed King` | 4 | 4 | 0 | 0 |
| `Sythis, Harvest's Hand` | 0 | 0 | 0 | 0 |
| `Urza, Lord High Artificer` | 0 | 0 | 0 | 0 |

Post-change:

| Commander | Deck rows | Accepted rows | unresolved_total | off_color_total | commander_qty_ok | main_qty_ok | singleton_violation_rows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `Meren of Clan Nel Toth` | 3 | 3 | 0 | 0 | 3 | 3 | 0 |
| `Korvold, Fae-Cursed King` | 8 | 8 | 0 | 0 | 8 | 8 | 0 |
| `Sythis, Harvest's Hand` | 5 | 5 | 0 | 0 | 5 | 5 | 0 |
| `Urza, Lord High Artificer` | 5 | 5 | 0 | 0 | 5 | 5 | 0 |

Observacao: Korvold ja tinha 4 linhas historicas antes deste apply; o Lote B
validado nesta rodada aplicou e reaplicou 4/4 decks aceitos nos artifacts
abaixo.

## Resultado por comandante

| Commander | Decks Lote B | Dry-run pre-apply | Apply | Idempotency | Gate estrutural |
| --- | ---: | --- | --- | --- | --- |
| `Meren of Clan Nel Toth` | 3 | PASS 3/3, db_mutations=false | PASS 3/3 | PASS 3/3 | unresolved=0, off_color=0, 1/99, singleton `{}` |
| `Korvold, Fae-Cursed King` | 4 | PASS 4/4, db_mutations=false | PASS 4/4 | PASS 4/4 | unresolved=0, off_color=0, 1/99, singleton `{}` |
| `Sythis, Harvest's Hand` | 5 | PASS 5/5, db_mutations=false | PASS 5/5 | PASS 5/5 | unresolved=0, off_color=0, 1/99, singleton `{}` |
| `Urza, Lord High Artificer` | 5 | PASS 5/5, db_mutations=false | PASS 5/5 | PASS 5/5 | unresolved=0, off_color=0, 1/99, singleton `{}` |

Artifacts novos:

- `server/test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/<safe_commander>/dry_run_pre_apply/`
- `server/test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/<safe_commander>/apply/`
- `server/test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/<safe_commander>/apply_idempotency/`
- `server/test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/readiness_after_corpus/readiness_scorecard_summary.json`

## Readiness scorecard sem runtime summary

| Commander | Score | Status | Expansion ready | Blockers | Warnings |
| --- | ---: | --- | --- | --- | --- |
| `Meren of Clan Nel Toth` | 98 | `profile_ready_needs_proof` | false | `[]` | `public_runtime_proof_missing` |
| `Korvold, Fae-Cursed King` | 98 | `profile_ready_needs_proof` | false | `[]` | `public_runtime_proof_missing` |
| `Sythis, Harvest's Hand` | 98 | `profile_ready_needs_proof` | false | `[]` | `public_runtime_proof_missing` |
| `Urza, Lord High Artificer` | 98 | `profile_ready_needs_proof` | false | `[]` | `public_runtime_proof_missing` |

Resumo: `PASS_WITH_RISKS`, `commander_count=4`, `ready_count=0`.

## Achados derivados da web

| Commander | Padrao publico observado |
| --- | --- |
| `Meren of Clan Nel Toth` | Recursion BG com criaturas utilitarias, sac outlets, self-mill/tutors e engines de valor; as fontes mais especificas de graveyard/sacrifice ainda dependem de cartas recentes ausentes localmente. |
| `Korvold, Fae-Cursed King` | Sacrifice/treasure Jund com ramp alto, tokens/treasures como material de compra e payoffs aristocrats; o retry trocou `budget` por `aristocrats` para reforcar o core package. |
| `Sythis, Harvest's Hand` | Enchantress GW com draw/value ao conjurar encantamentos, protecao, remocoes enchantment-based, auras como suporte e payoffs de mesa, nao como Voltron puro. |
| `Urza, Lord High Artificer` | Mono-blue artifacts com rocks, cost reducers, interaction, tutors e lanes explicitas de control/combo; budget foi mantido como contrapeso casual. |

## Padroes uteis absorvidos

- Meren: sac outlets, criaturas utilitarias, recursion, self-mill controlado e
  tutors como pacote BG de toolbox.
- Korvold: treasure makers, sacrifice outlets, token fodder, aristocrats/drain e
  ramp Jund como pacote coerente.
- Sythis: enchantress draw, enchantment ramp/cost reduction, protection,
  enchantment-based interaction e wincons de encantamento.
- Urza: artifact ramp, cost reducers, artifact card advantage, counters/removal
  azuis e combos apenas em lane marcada.

## Riscos e gaps remanescentes

1. `public_runtime_proof_missing` bloqueia promocao dos quatro comandantes.
2. Korvold ainda carrega historico Sprint 2, embora o Lote B pos-apply nao tenha
   blockers nem `core_package_weak`.
3. Urza segue exigindo lane explicita de control/combo/high-power para nao
   contaminar Commander casual com cEDH/stax.
4. As fontes Meren excluidas continuam bloqueadas ate haver backfill/resolucao DB
   para `Cauldron of Essence` e `Grave Researcher`.
5. Nao houve public proof, app runtime, promocao ou alteracao de contrato
   app/backend nesta rodada.

## Rollback/idempotencia

O apply e idempotente por `source_deck_key`. Reaplicar o mesmo corpus atualiza as
linhas de deck/analysis e recria as linhas de cards do mesmo deck por chave
primaria, sem inserir cartas novas. Se fosse necessario desfazer apenas este
lote, o rollback operacional seguro seria remover os `source_deck_key` dos
artifacts Lote B nas tabelas `commander_reference_deck_cards` e
`commander_reference_decks`, seguido de remocao do aggregate correspondente em
`commander_reference_deck_analysis` apenas para os comandantes afetados; essa
acao nao foi executada.

## Decisao

Resultado final: **PASS_WITH_RISKS**.

Lote B esta aplicado e idempotente no banco, com readiness pos-corpus 98/100 para
os quatro comandantes, mas nenhum comandante esta promovido ate passar public
proof/runtime summary 5/5 sem fallback de timeout, invalid/off-identity ou
warning relevante.
