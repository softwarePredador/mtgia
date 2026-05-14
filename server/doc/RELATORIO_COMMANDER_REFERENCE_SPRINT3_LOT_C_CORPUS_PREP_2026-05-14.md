# Commander Reference Sprint 3 Lote C Corpus Prep - 2026-05-14

## Verdict

**PASS_WITH_RISKS** para corpus prep/dry-run inicial, sem apply no banco.

Foram preparados corpora offline para `Purphoros, God of the Forge`,
`Brago, King Eternal`, `Veyran, Voice of Duality` e
`Balan, Wandering Knight` em
`server/test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/<safe_commander>/corpus.json`.
Todos os dry-runs finais passaram com `db_mutations=false`, `commander_quantity=1`,
`main_quantity=99`, `unresolved=0`, `off_color=0` e singleton limpo.

O resultado nao e PASS pleno porque `Veyran, Voice of Duality` precisou excluir
as fontes EDHREC mais fortes de default/spellslinger/spell-copy/storm por
cartas recentes nao resolvidas localmente. O corpus final de Veyran e valido para
dry-run, mas tem sinal estrategico mais fraco ate haver backfill/resolucao dessas
cartas ou fonte alternativa confiavel.

## Escopo e seguranca

- Incluido: sync de `master`, releitura do contexto obrigatorio, pesquisa publica
  de baixo volume, corpus JSON offline, dry-run DB-backed, documentacao e
  validacoes focadas.
- Fora do escopo: `--apply`, idempotencia, public proof, readiness scorecard,
  runtime app, endpoint app-facing, scanner, camera e OCR.
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

## Proximas acoes tecnicas minimas

1. Revisar manualmente os packages extraidos dos dry-runs, principalmente Veyran.
2. Resolver/backfill cartas locais que bloquearam fontes Veyran high-signal ou
   substituir por fonte publica equivalente antes de qualquer `--apply`.
3. Em tarefa futura, rodar novo dry-run pre-apply e so entao `--apply`
   controlado, seguido de idempotencia.
4. Depois de apply futuro, executar public proof 5/5 e readiness scorecard com
   runtime summary; bloquear promocao com `score<100`, warning relevante,
   timeout fallback, invalid/off-identity, unresolved/off-color ou core package
   fraco.

## Decisao

Resultado final: **PASS_WITH_RISKS**.

Lote C esta preparado em artifacts offline e provado por dry-run DB-backed sem
mutacao de banco. `--apply` ficou explicitamente **APPLY_NOT_RUN** por escopo.
