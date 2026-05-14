# Commander Reference Sprint 3 Lote C Corpus Prep - 2026-05-14

## Verdict

**PASS_WITH_RISKS** para corpus prep, apply controlado, idempotencia e
readiness scorecard pos-corpus sem runtime summary.

Foram preparados corpora offline para `Purphoros, God of the Forge`,
`Brago, King Eternal`, `Veyran, Voice of Duality` e
`Balan, Wandering Knight` em
`server/test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/<safe_commander>/corpus.json`.
Todos os dry-runs finais e o novo dry-run pre-apply passaram com
`db_mutations=false`, `commander_quantity=1`, `main_quantity=99`,
`unresolved=0`, `off_color=0` e singleton limpo. O apply foi executado em
`apply/` e repetido em `apply_idempotency/`, com todos os corpora aceitos.

O resultado nao e PASS pleno porque `Veyran, Voice of Duality` precisou excluir
as fontes EDHREC mais fortes de default/spellslinger/spell-copy/storm por
cartas recentes nao resolvidas localmente, e porque o readiness pos-corpus sem
runtime summary ficou bloqueado para Balan, Purphoros e Veyran por falta de
profile/card_stats/deterministic reference proof ja aplicados. Brago ficou
`profile_ready_needs_proof` apenas por ausencia de public runtime proof.

## Escopo e seguranca

- Incluido: sync de `master`, releitura do contexto obrigatorio, corpus JSON
  offline existente, dry-run DB-backed pre-apply, `--apply`, idempotencia,
  readiness scorecard sem runtime summary, documentacao e validacoes focadas.
- Fora do escopo: public proof, runtime app, endpoint app-facing, scanner,
  camera e OCR.
- Nao foram persistidos ou documentados secrets, tokens, JWT, Sentry DSN,
  `DATABASE_URL`, `OPENAI_API_KEY`, credenciais QA, prompts completos ou payload
  sensivel.
- Os artifacts offline nao criam dependencia runtime em EDHREC, scraping ou API
  nao oficial.

## Fontes web consultadas

As fontes incluidas sao paginas publicas EDHREC Average Deck. Elas provam
contexto Commander por rotulo externo `Average Deck for ...`,
`total_card_count=100`, comandante no slot de comando e main deck com 99 cartas
no payload publico usado para montar os artifacts offline.

| Commander | Fontes incluidas |
| --- | --- |
| `Purphoros, God of the Forge` | `https://edhrec.com/average-decks/purphoros-god-of-the-forge`; `https://edhrec.com/average-decks/purphoros-god-of-the-forge/tokens`; `https://edhrec.com/average-decks/purphoros-god-of-the-forge/burn`; `https://edhrec.com/average-decks/purphoros-god-of-the-forge/budget`; `https://edhrec.com/average-decks/purphoros-god-of-the-forge/aggro` |
| `Brago, King Eternal` | `https://edhrec.com/average-decks/brago-king-eternal`; `https://edhrec.com/average-decks/brago-king-eternal/blink`; `https://edhrec.com/average-decks/brago-king-eternal/control`; `https://edhrec.com/average-decks/brago-king-eternal/budget` |
| `Veyran, Voice of Duality` | `https://edhrec.com/average-decks/veyran-voice-of-duality/budget`; `https://edhrec.com/average-decks/veyran-voice-of-duality/voltron`; `https://edhrec.com/average-decks/veyran-voice-of-duality/midrange`; `https://edhrec.com/average-decks/veyran-voice-of-duality/treasure` |
| `Balan, Wandering Knight` | `https://edhrec.com/average-decks/balan-wandering-knight`; `https://edhrec.com/average-decks/balan-wandering-knight/equipment`; `https://edhrec.com/average-decks/balan-wandering-knight/voltron`; `https://edhrec.com/average-decks/balan-wandering-knight/budget` |

Fontes sondadas e deixadas fora do artifact final:

| Commander | Fonte | Motivo |
| --- | --- | --- |
| `Purphoros, God of the Forge` | `/goblins` | Excluida para nao repetir diretamente Krenko/Goblin typal. |
| `Purphoros, God of the Forge` | `/treasure`, `/combo` | Baixo volume e risco de lane menos representativa para token-burn casual. |
| `Brago, King Eternal` | `/stax`, `/combo`, `/artifacts` | Excluidas para nao transformar blink/ETB value em stax/combo/artifacts como default. |
| `Veyran, Voice of Duality` | default, `/spellslinger`, `/spell-copy`, `/storm`, `/cantrips`, `/prowess` | Dry-run rejeitou por unresolved local: `Resonating Lute`, `Flashback` ou ambos. |
| `Balan, Wandering Knight` | `/cats`, `/auras`, `/lifegain`, `/artifacts` | Excluidas por baixo volume, overlap com Light-Paws/Auras ou diluicao do shell Equipment Voltron. |

## Fatos locais/database comprovados

Comando executado para cada comandante:

```bash
cd server
dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/<safe_commander>/corpus.json \
  --dry-run \
  --artifact-dir=test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/<safe_commander>/dry_run
```

Resultado consolidado:

| Commander | Decks | Status | db_mutations | Commander/main | unresolved | off_color | singleton_violations | Artifact |
| --- | ---: | --- | --- | --- | ---: | ---: | --- | --- |
| `Purphoros, God of the Forge` | 5 | PASS | false | 1/99 em 5/5 | 0 | 0 | `{}` em 5/5 | `server/test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/purphoros_god_of_the_forge/dry_run/purphoros_god_of_the_forge_dry_run_summary.json` |
| `Brago, King Eternal` | 4 | PASS | false | 1/99 em 4/4 | 0 | 0 | `{}` em 4/4 | `server/test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/brago_king_eternal/dry_run/brago_king_eternal_dry_run_summary.json` |
| `Veyran, Voice of Duality` | 4 | PASS | false | 1/99 em 4/4 | 0 | 0 | `{}` em 4/4 | `server/test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/veyran_voice_of_duality/dry_run/veyran_voice_of_duality_dry_run_summary.json` |
| `Balan, Wandering Knight` | 4 | PASS | false | 1/99 em 4/4 | 0 | 0 | `{}` em 4/4 | `server/test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/balan_wandering_knight/dry_run/balan_wandering_knight_dry_run_summary.json` |

O dry-run tambem provou que nenhum deck foi rejeitado e que `--apply` nao foi
executado. Nao houve public proof, readiness scorecard ou promocao.

## Achados derivados da web

| Commander | Padrao publico observado |
| --- | --- |
| `Purphoros, God of the Forge` | Mono-red token-burn: o comandante converte criacao repetida de criaturas em dano inevitavel, com token makers, payoffs de ETB/dano em massa, haste/rituais e poucos slots de interacao. |
| `Brago, King Eternal` | Azorius blink/ETB value: criaturas e permanentes com ETB, flicker de baixo custo, mana rocks que resetam, draw/value incremental e controle leve sustentam loops de valor. |
| `Veyran, Voice of Duality` | Izzet magecraft/spellslinger: cantrips, copiar spell, triggers duplicados, treasures/rituais e payoffs de dano/pump aparecem, mas as fontes finais aceitas localmente estao mais laterais do que as paginas high-signal rejeitadas. |
| `Balan, Wandering Knight` | Mono-white Equipment Voltron: equipamentos de custo/equip alto ficam melhores com o comandante, que move equipamentos em velocidade instantanea; protecao, evasion, double strike e draw branco sustentam o plano. |

## Interpretacao estrategica

Purphoros quer reduzir a janela de resposta da mesa: muitos tokens pequenos viram
dano global sem precisar atacar. A malicia e combinar geradores de multiplos
corpos com payoffs redundantes de ETB/dano e rituais que escalam com criaturas,
sem virar apenas Goblins/Krenko 2.

Brago premia permanentes que ja geram valor entrando no campo e ficam melhores
quando piscados todo turno. O corpus deve ensinar blink/control de valor, nao
stax duro como default, porque stax muda a experiencia casual e exige lane de
poder explicita.

Veyran duplica triggers de magecraft/prowess e incentiva sequencias de spells
baratas. A leitura web confirma a direcao spellslinger, mas o artifact final
precisa ser tratado como incompleto em qualidade de fonte porque as paginas
default/spellslinger/spell-copy/storm nao passaram no resolvedor local.

Balan e Voltron de equipamentos, nao auras. O incentivo e montar uma pilha de
equipamentos que alterna entre protecao, evasion, dano explosivo e resiliencia,
com suporte suficiente de compra/tutor para nao depender de uma unica mao
inicial.

## Padroes uteis para absorver futuramente

- Purphoros: token makers, haste/rituais, Impact Tremors-like redundancy,
  sac/damage outlets e sweepers assimetricos como pacote token-burn.
- Brago: ETB draw/removal/bounce, flicker barato, mana rocks resetaveis,
  recursion leve e controle Azorius como pacote blink value.
- Veyran: cantrips, copy effects, magecraft/prowess payoffs, rituais/treasures e
  counters leves, mas somente depois de reforcar o corpus high-signal.
- Balan: equipamentos core, protecao/evasion, double strike, tutors white e draw
  por equipamentos/combat damage como pacote Equipment Voltron.

## Padroes arriscados ou nao transferiveis

1. Nao importar Purphoros `/goblins` como padrao, para evitar repetir Krenko e
   distorcer token-burn para Goblin typal.
2. Nao transformar Brago casual em stax/combo default; stax precisa de lane
   explicita e criterio de usuario.
3. Nao promover Veyran com o corpus atual sem resolver a lacuna das paginas
   default/spellslinger/spell-copy/storm.
4. Nao misturar Balan com Light-Paws/Auras; equipamentos sao a identidade
   funcional deste lote.
5. Nao copiar decklists EDHREC em runtime; usar somente sinais agregados apos
   etapa futura de apply, idempotencia, public proof e scorecard.

## Recomendacao por comandante

| Commander | Recomendacao |
| --- | --- |
| `Purphoros, God of the Forge` | **GO condicionado** para dry-run pre-apply futuro; corpus forte para token-burn sem Goblin typal. |
| `Brago, King Eternal` | **GO condicionado** para dry-run pre-apply futuro; manter blink/ETB value e bloquear stax/combo default. |
| `Veyran, Voice of Duality` | **PASS_WITH_RISKS**; antes de apply, preferir backfill/resolucao local de `Resonating Lute`/`Flashback` ou nova fonte publica que recupere spellslinger/spell-copy/storm. |
| `Balan, Wandering Knight` | **GO condicionado** para dry-run pre-apply futuro; corpus coerente de Equipment Voltron sem aura shell. |

## Apply controlado + readiness pos-corpus - 2026-05-14

Comandos principais executados:

```bash
cd server
dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/<safe_commander>/corpus.json \
  --dry-run \
  --artifact-dir=test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/<safe_commander>/dry_run_pre_apply

dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/<safe_commander>/corpus.json \
  --apply \
  --artifact-dir=test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/<safe_commander>/apply

dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/<safe_commander>/corpus.json \
  --apply \
  --artifact-dir=test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/<safe_commander>/apply_idempotency

dart run bin/commander_reference_readiness_scorecard.dart \
  --commanders="Purphoros, God of the Forge;Brago, King Eternal;Veyran, Voice of Duality;Balan, Wandering Knight" \
  --artifact-dir=test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/readiness_after_corpus
```

Pre-change DB counts para os quatro comandantes eram `0` linhas em
`commander_reference_decks`. Post-apply/idempotencia DB-backed:

| Commander | DB deck rows | accepted | unresolved_total | off_color_total | clean 1/99 rows |
| --- | ---: | ---: | ---: | ---: | ---: |
| `Balan, Wandering Knight` | 4 | 4 | 0 | 0 | 4 |
| `Brago, King Eternal` | 4 | 4 | 0 | 0 | 4 |
| `Purphoros, God of the Forge` | 5 | 5 | 0 | 0 | 5 |
| `Veyran, Voice of Duality` | 4 | 4 | 0 | 0 | 4 |

Resultados por fase:

| Commander | Dry-run pre-apply | Apply | Idempotency |
| --- | --- | --- | --- |
| `Balan, Wandering Knight` | PASS 4/4, unresolved=0, off_color=0, 1/99, singleton `{}` | PASS 4/4 | PASS 4/4 |
| `Brago, King Eternal` | PASS 4/4, unresolved=0, off_color=0, 1/99, singleton `{}` | PASS 4/4 | PASS 4/4 |
| `Purphoros, God of the Forge` | PASS 5/5, unresolved=0, off_color=0, 1/99, singleton `{}` | PASS 5/5 | PASS 5/5 |
| `Veyran, Voice of Duality` | PASS 4/4, unresolved=0, off_color=0, 1/99, singleton `{}` | PASS 4/4 | PASS 4/4 |

`--apply` e idempotencia sao upserts por `source_deck_key`, com substituicao
controlada das cartas do mesmo source deck e resumo agregado por comandante.
Rollback pratico: rerodar um corpus anterior validado para os mesmos
`source_deck_key` ou remover explicitamente essas keys se for necessario
desfazer o lote; a operacao aplicada nesta rodada e idempotente.

Readiness scorecard sem runtime summary:

| Commander | Score | Status | Expansion ready | Warnings | Blockers |
| --- | ---: | --- | --- | --- | --- |
| `Balan, Wandering Knight` | 25 | `blocked` | false | `public_runtime_proof_missing` | `commander_card_not_resolved`, `profile_missing_or_below_confidence`, `card_stats_missing`, `deterministic_reference_deck_invalid`, `deterministic_main_quantity_not_99` |
| `Brago, King Eternal` | 98 | `profile_ready_needs_proof` | false | `public_runtime_proof_missing` | nenhum |
| `Purphoros, God of the Forge` | 25 | `blocked` | false | `public_runtime_proof_missing` | `commander_card_not_resolved`, `profile_missing_or_below_confidence`, `card_stats_missing`, `deterministic_reference_deck_invalid`, `deterministic_main_quantity_not_99` |
| `Veyran, Voice of Duality` | 25 | `blocked` | false | `public_runtime_proof_missing` | `commander_card_not_resolved`, `profile_missing_or_below_confidence`, `card_stats_missing`, `deterministic_reference_deck_invalid`, `deterministic_main_quantity_not_99` |

Nao houve ajuste de runner ou codigo nesta etapa.

## Proximas acoes tecnicas minimas

1. Aplicar ou preparar profiles/card_stats para Balan, Purphoros e Veyran antes
   de qualquer public proof/promocao.
2. Revisar manualmente os packages extraidos dos dry-runs, principalmente Veyran.
3. Resolver/backfill cartas locais que bloquearam fontes Veyran high-signal ou
   substituir por fonte publica equivalente antes de public proof/promocao.
4. Executar public proof 5/5 e readiness scorecard com
   runtime summary; bloquear promocao com `score<100`, warning relevante,
   timeout fallback, invalid/off-identity, unresolved/off-color ou core package
   fraco.

## Decisao

Resultado final: **PASS_WITH_RISKS**.

Lote C esta preparado em artifacts offline, provado por dry-run DB-backed,
aplicado com idempotencia e registrado no readiness scorecard pos-corpus. Nao ha
promocao: Brago ainda precisa public proof, e Balan/Purphoros/Veyran precisam de
profiles/card_stats/deterministic proof antes de runtime.
