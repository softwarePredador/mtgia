# Commander Reference Sprint 2 Corpus Prep - 2026-05-13

## Verdict

**PASS.**

Foram preparados corpora offline para `Kinnan, Bonder Prodigy`,
`Korvold, Fae-Cursed King`, `Muldrotha, the Gravetide`,
`Yuriko, the Tiger's Shadow`, `Winota, Joiner of Forces` e
`Atraxa, Praetors' Voice` em
`server/test/artifacts/commander_reference_sprint2_2026-05-13/<safe_commander>/corpus.json`.

Nenhum corpus foi aplicado no banco. O unico gate executado foi `--dry-run`,
com `db_mutations=false` para todos os comandantes.

## Scope

Scanner, camera, OCR, app mobile, rotas app-facing, public proof,
readiness scorecard, `--apply`, idempotencia e promocao ficaram fora do escopo.
O trabalho cobriu apenas pesquisa publica de baixo volume, montagem offline do
JSON, dry-run DB-backed e documentacao.

## Fontes web consultadas

As fontes abaixo sao paginas publicas EDHREC Average Deck. Elas provam contexto
Commander por rotulo explicito da pagina, comandante no slot de comando e
`total_card_count=100` no payload publico usado para montar o artifact offline.

| Commander | Fontes incluidas |
| --- | --- |
| `Kinnan, Bonder Prodigy` | `https://edhrec.com/average-decks/kinnan-bonder-prodigy`; `https://edhrec.com/average-decks/kinnan-bonder-prodigy/budget`; `https://edhrec.com/average-decks/kinnan-bonder-prodigy/cedh`; `https://edhrec.com/average-decks/kinnan-bonder-prodigy/combo` |
| `Korvold, Fae-Cursed King` | `https://edhrec.com/average-decks/korvold-fae-cursed-king`; `https://edhrec.com/average-decks/korvold-fae-cursed-king/treasure`; `https://edhrec.com/average-decks/korvold-fae-cursed-king/sacrifice`; `https://edhrec.com/average-decks/korvold-fae-cursed-king/budget` |
| `Muldrotha, the Gravetide` | `https://edhrec.com/average-decks/muldrotha-the-gravetide`; `https://edhrec.com/average-decks/muldrotha-the-gravetide/graveyard`; `https://edhrec.com/average-decks/muldrotha-the-gravetide/self-mill`; `https://edhrec.com/average-decks/muldrotha-the-gravetide/budget` |
| `Yuriko, the Tiger's Shadow` | `https://edhrec.com/average-decks/yuriko-the-tigers-shadow`; `https://edhrec.com/average-decks/yuriko-the-tigers-shadow/ninjas`; `https://edhrec.com/average-decks/yuriko-the-tigers-shadow/topdeck`; `https://edhrec.com/average-decks/yuriko-the-tigers-shadow/budget` |
| `Winota, Joiner of Forces` | `https://edhrec.com/average-decks/winota-joiner-of-forces`; `https://edhrec.com/average-decks/winota-joiner-of-forces/humans`; `https://edhrec.com/average-decks/winota-joiner-of-forces/hatebears`; `https://edhrec.com/average-decks/winota-joiner-of-forces/budget` |
| `Atraxa, Praetors' Voice` | `https://edhrec.com/average-decks/atraxa-praetors-voice`; `https://edhrec.com/average-decks/atraxa-praetors-voice/plus-1-plus-1-counters`; `https://edhrec.com/average-decks/atraxa-praetors-voice/planeswalkers`; `https://edhrec.com/average-decks/atraxa-praetors-voice/infect`; `https://edhrec.com/average-decks/atraxa-praetors-voice/budget` |

Paginas sondadas e deixadas fora do artifact final por redundancia ou para
manter o volume baixo: Kinnan `artifacts` e `big-mana`; Korvold
`aristocrats`, `lands` e `cedh`; Muldrotha `reanimator`, `lands` e `combo`;
Yuriko `extra-turns` e `cedh`; Winota `stax`, `cedh` e `aggro`; Atraxa
`proliferate` e `poison` (404).

## Fatos locais comprovados

Comando executado para cada comandante:

```bash
cd server
dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_sprint2_2026-05-13/<safe_commander>/corpus.json \
  --dry-run \
  --artifact-dir=test/artifacts/commander_reference_sprint2_2026-05-13/<safe_commander>/dry_run
```

Resultado consolidado:

| Commander | Decks | Status | db_mutations | commander_quantity | main_quantity | unresolved | off_color | singleton_violations | Artifact |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `Kinnan, Bonder Prodigy` | 4 | `PASS` | `false` | 1 em 4/4 | 99 em 4/4 | 0 em 4/4 | 0 em 4/4 | `{}` em 4/4 | `server/test/artifacts/commander_reference_sprint2_2026-05-13/kinnan_bonder_prodigy/dry_run/kinnan_bonder_prodigy_dry_run_summary.json` |
| `Korvold, Fae-Cursed King` | 4 | `PASS` | `false` | 1 em 4/4 | 99 em 4/4 | 0 em 4/4 | 0 em 4/4 | `{}` em 4/4 | `server/test/artifacts/commander_reference_sprint2_2026-05-13/korvold_fae_cursed_king/dry_run/korvold_fae_cursed_king_dry_run_summary.json` |
| `Muldrotha, the Gravetide` | 4 | `PASS` | `false` | 1 em 4/4 | 99 em 4/4 | 0 em 4/4 | 0 em 4/4 | `{}` em 4/4 | `server/test/artifacts/commander_reference_sprint2_2026-05-13/muldrotha_the_gravetide/dry_run/muldrotha_the_gravetide_dry_run_summary.json` |
| `Yuriko, the Tiger's Shadow` | 4 | `PASS` | `false` | 1 em 4/4 | 99 em 4/4 | 0 em 4/4 | 0 em 4/4 | `{}` em 4/4 | `server/test/artifacts/commander_reference_sprint2_2026-05-13/yuriko_the_tigers_shadow/dry_run/yuriko_the_tiger_s_shadow_dry_run_summary.json` |
| `Winota, Joiner of Forces` | 4 | `PASS` | `false` | 1 em 4/4 | 99 em 4/4 | 0 em 4/4 | 0 em 4/4 | `{}` em 4/4 | `server/test/artifacts/commander_reference_sprint2_2026-05-13/winota_joiner_of_forces/dry_run/winota_joiner_of_forces_dry_run_summary.json` |
| `Atraxa, Praetors' Voice` | 5 | `PASS` | `false` | 1 em 5/5 | 99 em 5/5 | 0 em 5/5 | 0 em 5/5 | `{}` em 5/5 | `server/test/artifacts/commander_reference_sprint2_2026-05-13/atraxa_praetors_voice/dry_run/atraxa_praetors_voice_dry_run_summary.json` |

## Achados derivados da web

Os sinais abaixo vem das fontes EDHREC Average Deck incluidas; eles ainda nao
sao regras de runtime porque nao houve `--apply` nem scorecard de promocao.

| Commander | Padrao publico observado |
| --- | --- |
| `Kinnan, Bonder Prodigy` | Simic ramp/combo com dorks e rocks que dobram mana, outlets de mana infinita e uma lane `cedh` explicitamente separada da lane budget/casual. |
| `Korvold, Fae-Cursed King` | Jund sacrifice/treasure value: sacrificar permanentes baratos gera compra, crescimento do comandante e conversao para aristocrats ou treasure burst. |
| `Muldrotha, the Gravetide` | Sultai graveyard recursion: self-mill, permanentes reutilizaveis e respostas que voltam do cemiterio em vez de Sultai goodstuff generico. |
| `Yuriko, the Tiger's Shadow` | Dimir ninjas/topdeck: evasivos baratos habilitam ninjutsu, topdeck manipulation aumenta dano de Yuriko e draw/value mantem pressao. |
| `Winota, Joiner of Forces` | Boros combat engine: nao-humanos pequenos disparam Winota para trapacear humanos impactantes; hatebears/stax aparece como lane de poder, nao default casual. |
| `Atraxa, Praetors' Voice` | WUBG proliferate umbrella com lanes divergentes: +1/+1 counters, planeswalkers, infect/poison e budget precisam ficar separados. |

## Interpretacao estrategica

Kinnan premia aceleracao barata e exige separacao de bracket: o incentivo
competitivo e montar mana infinita cedo, enquanto a lane casual deve preservar
ramp/value sem assumir fast-combo como padrao.

Korvold converte cada comida, treasure, fetch ou criatura descartavel em carta e
pressao de comandante. A malicia e transformar custo de sacrificio em recurso,
nao apenas empilhar payoffs aristocrats sem combustivel.

Muldrotha quer que o cemiterio seja uma segunda mao para permanentes. O pacote
util deve combinar self-mill, permanentes sacrificaveis, recursao e interacao
reciclavel; loops fortes devem ser tratados como power-lane separada.

Yuriko depende de tempo e manipulacao do topo. Cartas de custo alto na mao/topo
sao payoff de dano, mas o deck ainda precisa de evasivos baratos, ninjas e
interacao para conectar.

Winota e explosiva porque separa enablers nao-humanos de hits humanos. Misturar
tudo como Boros aggro generico perde a razao de existir do comandante.

Atraxa nao deve virar WUBG goodstuff. A mesma comandante suporta infect,
planeswalkers e counters; cada pedido de generate/optimize precisa escolher uma
lane antes de absorver pacotes.

## Padroes uteis para absorver futuramente

- Kinnan: dorks/rocks de mana, payoffs de mana grande, outlets e pacote cEDH
  marcado como lane propria.
- Korvold: treasures, fetch/sac fodder, draw-on-sac, recursion e payoffs
  aristocrats compactos.
- Muldrotha: self-mill, permanentes com ETB/sacrifice, recursion, interaction
  reutilizavel e land/value recursion.
- Yuriko: evasivos de baixo custo, ninjutsu density, topdeck manipulation,
  extra-turn/topdeck payoffs apenas quando a lane pedir.
- Winota: enablers nao-humanos baratos, hits humanos de alto impacto, protecao e
  hatebears separados de casual default.
- Atraxa: lanes explicitas para counters, superfriends e infect, com proliferate
  como cola mecanica e nao como lista unica.

## Padroes arriscados ou nao transferiveis

- Nao colapsar cEDH em Commander casual, especialmente Kinnan e Winota.
- Nao transformar Atraxa em um pacote unico; infect, superfriends e counters tem
  incentivos diferentes.
- Nao copiar decklists EDHREC em prompt/runtime; usar somente sinais agregados
  apos uma etapa futura de apply e scorecard.
- Nao assumir que popularidade publica e criterio de produto: budget, optimized,
  cEDH e theme pages precisam respeitar bracket/intencao do usuario.
- Nao promover guidance forte antes de `--apply`, idempotencia, public proof e
  readiness scorecard.

## Proximas acoes tecnicas minimas

1. Escolher um subconjunto pequeno para `--apply` controlado, com prioridade para
   Kinnan apenas se a lane cEDH continuar explicitamente isolada.
2. Rodar apply/idempotencia por comandante escolhido e registrar contagens
   DB-backed.
3. Executar public proof sanitizado 5x de `/ai/generate` e scorecard antes de
   qualquer promocao.
4. Se algum profile misturar lanes, ajustar o profile antes de ativar corpus como
   guidance forte.
