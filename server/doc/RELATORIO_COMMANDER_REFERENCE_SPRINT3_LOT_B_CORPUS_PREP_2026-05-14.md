# Commander Reference Sprint 3 Lote B Corpus Prep - 2026-05-14

## Verdict

**PASS_WITH_RISKS** para corpus prep e dry-run offline. Nenhum corpus foi aplicado
no banco: todos os dry-runs foram executados com `db_mutations=false` e
`--apply` ficou **APPLY_NOT_RUN** por escopo.

O resultado tem riscos porque `Meren of Clan Nel Toth` precisou excluir fontes
EDHREC com cartas ainda nao resolvidas no DB local, `Korvold, Fae-Cursed King`
carrega historico de Sprint 2 com `core_package_weak`, e `Urza, Lord High
Artificer` tem vies publico de high-power/combo.

## Escopo e seguranca

- Incluido: leitura do fechamento Lote A, selecao do Lote B, coleta web publica
  de baixo volume, corpus JSON offline, dry-run DB-backed e documentacao.
- Precondicao de sync atendida: `master` local/origin e `/health.git_sha`
  publico apontavam para `f4ec0d3c056d811f033d061cfaf0afefa82d30fb`.
- Fora do escopo: `--apply`, idempotencia, public proof, promocao, runtime app,
  endpoint app-facing, scanner, camera e OCR.
- Nao foram persistidos secrets, tokens, JWT, Sentry DSN, `DATABASE_URL`,
  `OPENAI_API_KEY`, credenciais QA, prompts completos ou payload sensivel.

## Fontes web consultadas

As fontes incluidas sao paginas publicas EDHREC Average Deck. Elas provam contexto
Commander por rotulo externo `Average Deck for ...`, `total_card_count=100`,
commander no slot de comando e main deck com 99 cartas no payload publico usado
uma unica vez para montar artifact offline.

| Commander | Fontes incluidas |
| --- | --- |
| `Meren of Clan Nel Toth` | `https://edhrec.com/average-decks/meren-of-clan-nel-toth`; `https://edhrec.com/average-decks/meren-of-clan-nel-toth/aristocrats`; `https://edhrec.com/average-decks/meren-of-clan-nel-toth/budget` |
| `Korvold, Fae-Cursed King` | `https://edhrec.com/average-decks/korvold-fae-cursed-king`; `https://edhrec.com/average-decks/korvold-fae-cursed-king/treasure`; `https://edhrec.com/average-decks/korvold-fae-cursed-king/sacrifice`; `https://edhrec.com/average-decks/korvold-fae-cursed-king/aristocrats` |
| `Sythis, Harvest's Hand` | `https://edhrec.com/average-decks/sythis-harvests-hand`; `https://edhrec.com/average-decks/sythis-harvests-hand/enchantress`; `https://edhrec.com/average-decks/sythis-harvests-hand/auras`; `https://edhrec.com/average-decks/sythis-harvests-hand/lifegain`; `https://edhrec.com/average-decks/sythis-harvests-hand/budget` |
| `Urza, Lord High Artificer` | `https://edhrec.com/average-decks/urza-lord-high-artificer`; `https://edhrec.com/average-decks/urza-lord-high-artificer/artifacts`; `https://edhrec.com/average-decks/urza-lord-high-artificer/control`; `https://edhrec.com/average-decks/urza-lord-high-artificer/combo`; `https://edhrec.com/average-decks/urza-lord-high-artificer/budget` |

Fontes sondadas e deixadas fora do artifact final:

| Commander | Fonte | Motivo |
| --- | --- | --- |
| `Meren of Clan Nel Toth` | `/graveyard` | Dry-run rejeitou por `unresolved_cards`: `Cauldron of Essence`. |
| `Meren of Clan Nel Toth` | `/sacrifice` | Dry-run rejeitou por `unresolved_cards`: `Cauldron of Essence`. |
| `Meren of Clan Nel Toth` | `/self-mill` | Dry-run rejeitou por `unresolved_cards`: `Grave Researcher`. |

## Fatos locais comprovados

Comando usado para cada comandante, a partir de `server/`:

```bash
dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/<safe_commander>/corpus.json \
  --dry-run \
  --artifact-dir=test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/<safe_commander>/dry_run
```

Resultado consolidado:

| Commander | Decks | Dry-run | DB mutations | Commander/main | unresolved | off_color | singleton_violations | Artifact |
| --- | ---: | --- | --- | --- | ---: | ---: | --- | --- |
| `Meren of Clan Nel Toth` | 3 | PASS | false | 1/99 em 3/3 | 0 | 0 | `{}` em 3/3 | `server/test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/meren_of_clan_nel_toth/dry_run/meren_of_clan_nel_toth_dry_run_summary.json` |
| `Korvold, Fae-Cursed King` | 4 | PASS | false | 1/99 em 4/4 | 0 | 0 | `{}` em 4/4 | `server/test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/korvold_fae_cursed_king/dry_run/korvold_fae_cursed_king_dry_run_summary.json` |
| `Sythis, Harvest's Hand` | 5 | PASS | false | 1/99 em 5/5 | 0 | 0 | `{}` em 5/5 | `server/test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/sythis_harvest_s_hand/dry_run/sythis_harvest_s_hand_dry_run_summary.json` |
| `Urza, Lord High Artificer` | 5 | PASS | false | 1/99 em 5/5 | 0 | 0 | `{}` em 5/5 | `server/test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/urza_lord_high_artificer/dry_run/urza_lord_high_artificer_dry_run_summary.json` |

## Achados derivados da web

| Commander | Padrao publico observado |
| --- | --- |
| `Meren of Clan Nel Toth` | Recursion BG com criaturas utilitarias, sac outlets, self-mill/tutors e engines de valor; as fontes mais especificas de graveyard/sacrifice ainda dependem de cartas recentes ausentes localmente. |
| `Korvold, Fae-Cursed King` | Sacrifice/treasure Jund com ramp alto, tokens/treasures como material de compra e payoffs aristocrats; o retry trocou `budget` por `aristocrats` para reforcar o core package. |
| `Sythis, Harvest's Hand` | Enchantress GW com draw/value ao conjurar encantamentos, protecao, remocoes enchantment-based, auras como suporte e payoffs de mesa, nao como Voltron puro. |
| `Urza, Lord High Artificer` | Mono-blue artifacts com rocks, cost reducers, interaction, tutors e lanes explicitas de control/combo; budget foi mantido como contrapeso casual. |

## Interpretacao estrategica

Meren quer converter criaturas pequenas em recurso recorrente. A malicia do deck e
usar sacrifice/self-mill para transformar o cemiterio em mao adicional, sem virar
apenas Golgari goodstuff nem repetir Muldrotha.

Korvold premia sacrificar qualquer permanente, especialmente treasures e tokens,
para crescer, comprar cartas e fechar com drain/combo/value. O corpus e util para
absorver pacotes de sacrifice/treasure, mas o historico local exige proof futuro
de core package forte e timeout fallback zero.

Sythis recompensa encantamentos baratos que compram cartas e estabilizam mesa. A
linha correta para ManaLoom e enchantress value; Light-Paws ja cobre aura-Voltron,
entao auras aqui devem ser suporte, nao o plano default.

Urza transforma artifacts em mana e vantagem, com incentivo natural para combo e
control. Esse padrao e relevante, mas nao deve ser aplicado a casual Commander sem
bracket/lane explicito.

## Padroes uteis para absorver futuramente

- Meren: sac outlets, criaturas utilitarias, recursion, self-mill controlado e
  tutors como pacote BG de toolbox.
- Korvold: treasure makers, sacrifice outlets, token fodder, aristocrats/drain e
  ramp Jund como pacote coerente.
- Sythis: enchantress draw, enchantment ramp/cost reduction, protection,
  enchantment-based interaction e wincons de encantamento.
- Urza: artifact ramp, cost reducers, artifact card advantage, counters/removal
  azuis e combos apenas em lane marcada.

## Padroes arriscados ou nao transferiveis

- Nao usar as fontes Meren excluidas sem backfill/resolucao DB para
  `Cauldron of Essence` e `Grave Researcher`.
- Nao promover Korvold sem provar que o retry resolveu `core_package_weak` e
  timeout fallback.
- Nao transformar Sythis em clone de Light-Paws Voltron.
- Nao transformar Urza casual em shell cEDH/stax/combo duro por popularidade
  publica.
- Nao copiar decklists para prompt/runtime; estes artifacts so devem alimentar
  sinais agregados apos futuro apply controlado.

## Recomendacao por comandante

| Commander | Recomendacao |
| --- | --- |
| `Meren of Clan Nel Toth` | **PASS_WITH_RISKS**: corpus minimo 3/3 aceito; antes de apply futuro, decidir se aceita lote reduzido ou faz backfill seguro das cartas ausentes. |
| `Korvold, Fae-Cursed King` | **PASS_WITH_RISKS**: dry-run 4/4 passou e corpus ficou mais focado, mas o historico Sprint 2 exige public proof e scorecard rigorosos antes de promocao. |
| `Sythis, Harvest's Hand` | **PASS** para corpus/dry-run; proximo gate deve verificar que enchantress value nao virou Voltron/goodstuff. |
| `Urza, Lord High Artificer` | **PASS_WITH_RISKS**: dry-run 5/5 passou; manter combo/control como lane explicita e bloquear stax/cEDH como default casual. |

## Menores proximas acoes tecnicas

1. Rodar revisao dos packages/top cards dos summaries antes de qualquer apply.
2. Se o Lote B avancar, rerodar dry-run pre-apply e aplicar somente corpora ainda
   PASS, em tarefa separada.
3. Executar apply idempotente, public proof sanitizado 5/5 e readiness scorecard
   com runtime summary antes de promocao.
4. Manter `APPLY_NOT_RUN` ate haver autorizacao explicita para mutar banco.

## Decisao

Resultado final: **PASS_WITH_RISKS**.

Lote B esta preparado para revisao tecnica offline. Nao houve apply no banco e
nenhum comandante esta promovido.
