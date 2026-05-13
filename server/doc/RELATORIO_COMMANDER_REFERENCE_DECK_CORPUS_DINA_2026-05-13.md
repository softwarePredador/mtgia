# Commander Reference Deck Corpus - Dina, Essence Brewer - 2026-05-13

## Verdict

**PASS WITH RISKS.**

O corpus offline de `Dina, Essence Brewer` foi montado a partir de 5 paginas
publicas EDHREC Average Deck e validado em `--dry-run` sem mutacao no banco.
O artifact final e uma projecao local-resolvivel: as paginas EDHREC originais
continham cartas novas de Secrets of Strixhaven que o banco local ainda nao
resolve; esses slots foram substituidos por staples Golgari de sacrificio/value
ja resolviveis localmente para permitir que o corpus passe nos gates do runner.

## Scope

Scanner, camera, OCR, app mobile, rotas app-facing, `/ai/optimize`, prova
publica de `/ai/generate` e `--apply` ficaram fora do escopo. O trabalho cobriu
somente corpus offline, dry-run DB-backed e documentacao.

## Fontes consultadas

Fontes publicas Commander, coletadas uma vez em baixo volume para analise
offline:

- `https://edhrec.com/average-decks/dina-essence-brewer`
- `https://edhrec.com/average-decks/dina-essence-brewer/sacrifice`
- `https://edhrec.com/average-decks/dina-essence-brewer/aristocrats`
- `https://edhrec.com/average-decks/dina-essence-brewer/budget`
- `https://edhrec.com/average-decks/dina-essence-brewer/tokens`
- `https://edhrec.com/commanders/dina-essence-brewer` como contexto publico
  adicional de Commander.

Artifact:
`server/test/artifacts/commander_reference_deck_corpus_dina_2026-05-13/dina_edhrec_average_corpus.json`

## Criterios de inclusao

- fonte publica explicitamente rotulada como EDHREC Average Deck para
  `Dina, Essence Brewer`;
- commander em zona de comando com quantidade `1`;
- main deck com quantidade total `99`;
- deck total com quantidade `100`;
- identidade Golgari/BG sem cartas fora de cor;
- sem violacao singleton fora de terrenos basicos;
- uso somente offline: o runtime nao faz scraping nem depende de API nao
  oficial.

## Fatos locais comprovados

Dry-run executado:

```bash
cd server
dart run bin/commander_reference_deck_corpus.dart \
  --corpus-json=test/artifacts/commander_reference_deck_corpus_dina_2026-05-13/dina_edhrec_average_corpus.json \
  --dry-run \
  --artifact-dir=test/artifacts/commander_reference_deck_corpus_dina_2026-05-13/dry_run
```

Resultado:

| Metric | Value |
| --- | ---: |
| status | `PASS` |
| mode | `dry_run` |
| db_mutations | `false` |
| deck_count | 5 |
| accepted_deck_count | 5 |
| rejected_deck_count | 0 |
| commander_quantity | 1 em 5/5 |
| main_quantity | 99 em 5/5 |
| unresolved_count | 0 em 5/5 |
| off_color_count | 0 em 5/5 |
| singleton_violations | `{}` em 5/5 |

O comandante resolveu localmente como `Dina, Essence Brewer`, preservando a
identidade BG esperada.

Artifact:
`server/test/artifacts/commander_reference_deck_corpus_dina_2026-05-13/dry_run/dina_essence_brewer_dry_run_summary.json`

## Unresolved e correcao local-resolvivel

A primeira validacao rejeitou 5/5 decks apenas por `unresolved_cards`. Nao houve
off-color nem singleton violation. As cartas ausentes no banco local em
2026-05-13 foram:

| Unresolved source card |
| --- |
| `Cauldron of Essence` |
| `Defiling Daemogoth` |
| `Dina's Guidance` |
| `Eccentric Pestfinder` |
| `Feral Appetite` |
| `Immoral Bargain` |
| `Merchant of Venom` |
| `Moseo, Vein's New Dean` |
| `Ominous Harvest` |
| `Pest Rescuer` |
| `Professor Dellian Fel` |
| `Ribtruss Roaster` |
| `Stensian Sanguinist` |
| `Teacher's Pest` |
| `Titan's Grave` |
| `Turbulent Fen` |
| `Witherbloom Charm` |

Para nao aplicar backfill nem mutar o banco nesta etapa, o JSON final foi
marcado como `edhrec_average_deck_local_resolvable_projection` e cada slot
unresolved recebeu substituto Golgari on-theme ja resolvivel localmente. O
proprio artifact registra `local_resolution_replacements` por deck.

| Deck key | Replacements |
| --- | ---: |
| `edhrec_dina_default_average` | 16 |
| `edhrec_dina_sacrifice_average` | 16 |
| `edhrec_dina_aristocrats_average` | 16 |
| `edhrec_dina_budget_average` | 15 |
| `edhrec_dina_tokens_average` | 16 |

## Achados derivados da web

As paginas EDHREC Average Deck provam contexto Commander por fonte, titulo e
formato de lista media para `Dina, Essence Brewer`. As cinco variantes apontam
para o mesmo nucleo estrategico:

- sacrificio repetivel e fodder/recursion para ativar a compra de Dina em
  multiplos turnos;
- payoffs aristocrats/drain como plano secundario, sem presumir que cada
  sacrificio compra carta;
- criaturas e permanentes que geram valor ao morrer ou ao criar corpos extras;
- pacote BG de ramp, remocao e recursao para manter o motor funcionando;
- lane budget/tokens como variacoes casuais, nao como prova cEDH.

## Interpretacao estrategica

Dina quer transformar sacrificios bem temporizados em vantagem de cartas e usar
o corpo/vida/counters como recompensa incremental. A "malicia" nao e montar um
loop de sacrificio infinito generico; e distribuir os sacrificios entre turnos e
turnos de oponentes para extrair o gatilho uma vez por turno, enquanto fodder,
recursao e drain mantem pressao. A carta `Dina, Soul Steeper` aparece como
suporte nas medias, mas isso nao prova que a comandante deve ser tratada como o
antigo plano lifegain-drain-only.

Padroes uteis para absorver em `optimize`/`generate` numa etapa futura:

- preservar pacote de sac outlets e fodder recorrente: `Viscera Seer`,
  `Carrion Feeder`, `Woe Strider`, `Reassembling Skeleton`, `Bloodghast` e
  `Jadar, Ghoulcaller of Nephalia`;
- priorizar payoffs compactos de morte/drain: `Blood Artist`,
  `Zulaport Cutthroat`, `Bastion of Remembrance` e `Dina, Soul Steeper` como
  suporte, nao como comandante;
- manter recursao/value BG: `Eternal Witness`, `Victimize`,
  `Moldervine Reclamation`, `Deadly Brew` e `Meren of Clan Nel Toth`;
- separar lane budget/tokens de lane average/aristocrats para nao forcar cartas
  premium ou plano errado em pedidos casuais.

Padroes arriscados ou nao transferiveis:

- nao colapsar `Dina, Essence Brewer` em `Dina, Soul Steeper` ou em pacote
  lifegain-drain antigo;
- nao tratar paginas Average Deck como cEDH;
- nao promover guidance forte ate corrigir/backfillar as cartas novas ausentes
  ou aceitar explicitamente a projecao local-resolvivel;
- nao copiar decklists em runtime; usar apenas sinais agregados de roles,
  recorrencia e pacotes.

## Proximo passo minimo

1. Rodar scorecard read-only para `Dina, Essence Brewer` usando o corpus aceito
   somente depois de decidir se a projecao local-resolvivel e aceitavel para
   `--apply`.
2. Opcionalmente auditar backfill oficial das cartas unresolved via Scryfall
   antes de qualquer `--apply`, se o objetivo for persistir listas EDHREC mais
   fieis.
3. Manter prova publica 5/5 de `/ai/generate` fora desta etapa; ela so deve
   acontecer apos corpus aplicado e scorecard sem `corpus_missing`.
