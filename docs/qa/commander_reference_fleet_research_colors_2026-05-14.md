# Commander Reference Fleet Research - Colors and Themes - 2026-05-14

## Resultado

**Completo para pesquisa documental.** Nenhum codigo foi alterado e nenhuma
mutacao de banco foi aplicada.

Este relatorio prioriza 20 novos candidatos para Commander Reference cobrindo
lacunas de cores e temas ainda fracas depois dos Sprints 1/2/3. A proposta nao
promove nenhum comandante automaticamente: cada candidato precisa repetir o gate
ja usado nos lotes anteriores antes de virar guidance forte.

## Fontes locais lidas

- `server/doc/RELATORIO_COMMANDER_REFERENCE_READINESS_SCORECARD_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_READINESS_MINI_BATCH_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_MINI_BATCH_COVERAGE_2026-05-13.md`
- `server/doc/COMMANDER_REFERENCE_SPRINT2_TRACKER_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT2_FINAL_2026-05-13.md`
- `server/doc/COMMANDER_REFERENCE_SPRINT3_TRACKER_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_AB_CONSOLIDATION_2026-05-14.md`

## Fatos locais comprovados

### Lista local de 20 promovidos

| Origem | Promovidos |
| --- | --- |
| Mini-batch inicial / Sprint 1 operacional | `Lorehold, the Historian`, `Prosper, Tome-Bound`, `Aesi, Tyrant of Gyre Strait`, `Edgar Markov`, `Dina, Essence Brewer`, `Zimone, Infinite Analyst` |
| Sprint 2 | `Kinnan, Bonder Prodigy`, `Muldrotha, the Gravetide`, `Yuriko, the Tiger's Shadow`, `Winota, Joiner of Forces`, `Atraxa, Praetors' Voice` |
| Sprint 3 Lotes A+B | `Krenko, Mob Boss`, `Light-Paws, Emperor's Voice`, `Niv-Mizzet, Parun`, `Teysa Karlov`, `Meren of Clan Nel Toth`, `Korvold, Fae-Cursed King`, `Sythis, Harvest's Hand`, `Urza, Lord High Artificer` |
| Sprint 3 Lote C | `Brago, King Eternal` |

### Gaps locais que justificam pesquisa

- Mono-black e mono-green ainda nao aparecem como comandantes promovidos.
- Mono-red e mono-white existem, mas estao estreitos: Krenko e Light-Paws cobrem
  goblins/tokens e auras, enquanto Purphoros e Balan ficaram bloqueados no Lote C.
- Azorius tem Brago promovido, mas ainda precisa separar blink de control/artifacts.
- Gruul nao tem comandante promovido.
- Selesnya tem Sythis, mas ainda esta concentrado em enchantress.
- Dimir tem Yuriko, mas falta Dimir control/graveyard fora de ninjas.
- Orzhov tem Teysa, mas ainda falta aristocrats/tokens alternativo e control/drain.
- Artifacts, lands, equipment, blink, control e combo precisam de lanes claras para
  nao contaminar decks casuais com pacotes high-power/cEDH.

## Fontes web consultadas

| Fonte | Uso nesta pesquisa | Evidencia obtida |
| --- | --- | --- |
| Scryfall API `cards/named` | Validar identidade de cor, tipo lendario e `legalities.commander` | Todos os 20 candidatos abaixo retornaram `commander=legal` como cartas lendarias validas para Commander. |
| EDHREC commander pages | Provar contexto Commander publico por comandante | Todas as 20 paginas de comandante retornaram HTTP 200. |
| cEDH Decklist Database | Verificar quais candidatos tambem aparecem em contexto cEDH | Pagina publica retornou HTTP 200 e continha mencoes a `Yawgmoth`, `Selvala`, `Magda`, `Shorikai`, `Sisay`, `Gitrog`, alem de sinais fracos para `Rhys` e `Scarab`. |
| Archidekt search | Fonte provavel complementar de corpus publico Commander | Search publico retornou HTTP 200, mas decks individuais nao foram validados neste passe. |
| Moxfield advanced search | Checagem de disponibilidade | Retornou HTTP 403 neste ambiente; nao foi usado como evidencia. |

Separacao obrigatoria: Scryfall prova legalidade e identidade de cor; EDHREC
prova contexto Commander publico; cEDH Decklist Database prova apenas presenca em
contexto competitivo para os nomes encontrados. Nenhuma decklist completa foi
copiada, persistida ou usada como verdade de produto.

## Candidatos priorizados

| Pri | Commander | Cores | Tema principal | Por que agrega | Fontes provaveis de corpus | Risco de unresolved | Prioridade operacional |
| ---: | --- | --- | --- | --- | --- | --- | --- |
| 1 | `Yawgmoth, Thran Physician` | B | Mono-black aristocrats, sacrifice, proliferate, combo | Fecha mono-black com engine tecnica diferente de Teysa/Dina; bom para ensinar sac outlets, undying, card draw pago por vida e finalizacao combo sem virar default casual. | Scryfall legal; EDHREC commander page; cEDH DDB citado para lane competitiva; Archidekt como apoio. | Baixo-medio: comandante antigo, mas pacotes combo podem incluir cartas caras/fast mana que precisam lane separada. | Alta: primeiro mono-black recomendado. |
| 2 | `Selvala, Heart of the Wilds` | G | Mono-green big mana, creatures, combo | Fecha mono-green com ramp explosivo e draw baseado em poder; separa casual creature-ramp de cEDH combo. | Scryfall legal; EDHREC commander page; cEDH DDB citado; Archidekt como apoio. | Baixo: base de cartas ampla e antiga; risco maior e power-lane, nao resolucao. | Alta: primeiro mono-green recomendado. |
| 3 | `Shorikai, Genesis Engine` | UW | Azorius artifacts, vehicles, control, combo | Complementa Brago sem repetir blink; cobre artifacts/control em UW e testa comandante artefato/veiculo. | Scryfall legal; EDHREC commander page; cEDH DDB citado; Archidekt como apoio. | Medio: vehicles e pacotes Kamigawa/Neon Dynasty podem exigir checagem local. | Alta: melhor ponte Azorius control/artifacts. |
| 4 | `Magda, Brazen Outlaw` | R | Mono-red treasures, artifacts, Dwarf typal, combo | Substitui Purphoros como caminho mono-red nao promovido, cobrindo artifacts/treasure/combo e typal sem repetir Krenko. | Scryfall legal; EDHREC commander page; cEDH DDB citado; Archidekt como apoio. | Medio: corpus cEDH usa tutors/combos especificos; separar casual dwarf-treasure de combo. | Alta: mono-red alternativo com grande valor estrategico. |
| 5 | `Sram, Senior Edificer` | W | Mono-white equipment/auras, Voltron, card draw | Cobre equipment depois do bloqueio de Balan e testa white card-advantage por permanentes baratos. | Scryfall legal; EDHREC commander page; Archidekt como apoio. | Baixo: shell antigo e cards comuns; monitorar se corpus virar aura demais. | Alta: melhor substituto inicial para equipment mono-white. |
| 6 | `The Gitrog Monster` | BG | Lands, graveyard, dredge/value, combo | Fecha lands+graveyard combo com identidade clara; ensina que lands podem ser engine, nao so mana base. | Scryfall legal; EDHREC commander page; cEDH DDB citado; Archidekt como apoio. | Medio: loops competitivos e cartas de dredge exigem lane e validacao singleton. | Alta: cobre lands de forma mais profunda que Aesi. |
| 7 | `Mizzix of the Izmagnus` | UR | Izzet spellslinger, cost reduction, storm/combo | Alternativa a Veyran bloqueado e a Niv promovido; cobre spellslinger por reducao de custo, nao draw-damage. | Scryfall legal; EDHREC commander page; Archidekt como apoio. | Baixo-medio: shell antigo; risco e misturar storm high-power em bracket casual. | Alta: priorizar se Veyran continuar bloqueado. |
| 8 | `Rhys the Redeemed` | GW | Selesnya tokens, go-wide, populate/doubling | Cobre tokens Selesnya sem depender de Sythis enchantress; excelente para densidade de token makers e payoffs. | Scryfall legal; EDHREC commander page; cEDH DDB contem mencoes fracas a Rhys; Archidekt como apoio. | Baixo: shell antigo; checar cartas recentes de token/doubling. | Alta-media: fecha tokens GW. |
| 9 | `The Scarab God` | UB | Dimir control, Zombies, graveyard reanimation | Complementa Yuriko com Dimir control/graveyard/typal; bom para ensinar inevitabilidade e reuso de cemiterio alheio. | Scryfall legal; EDHREC commander page; cEDH DDB tem mencoes fracas; Archidekt como apoio. | Baixo: comandante estabelecido; risco e typal zombie virar generico. | Alta-media: melhor Dimir nao-ninja. |
| 10 | `Elenda, the Dusk Rose` | BW | Orzhov tokens, aristocrats, sacrifice | Complementa Teysa com comandante que cresce e converte morte em tokens; reforca aristocrats sem depender de dobrar triggers. | Scryfall legal; EDHREC commander page; Archidekt como apoio. | Baixo-medio: versoes recentes podem puxar novos vampires/tokens. | Alta-media: Orzhov alternativo seguro. |
| 11 | `Yorion, Sky Nomad` | UW | Azorius blink, ETB value, control | Reforca blink sem repetir Brago e permite separar blink fair de stax duro; util para validar shell UW de ETB/control. | Scryfall legal; EDHREC commander page; Archidekt como apoio. | Medio: Yorion como commander e menos canonicamente popular que Brago; exigir corpus Commander claro. | Media-alta: blink redundante de seguranca. |
| 12 | `Azusa, Lost but Seeking` | G | Mono-green lands, extra land drops, ramp | Cobre mono-green lands de forma simples e casual-friendly; diferencia lands de combo Gitrog. | Scryfall legal; EDHREC commander page; Archidekt como apoio. | Baixo: staples antigos; risco de goodstuff sem payoffs de landfall. | Media-alta: mono-green casual/base. |
| 13 | `Zada, Hedron Grinder` | R | Mono-red spellslinger, cantrips, tokens | Cobre spellslinger vermelho e go-wide por copias de spell; alternativa budget/fun a Niv/Mizzix. | Scryfall legal; EDHREC commander page; Archidekt como apoio. | Baixo: shell antigo; monitorar duplicacao de pumps e token enablers. | Media: bom para diversidade de red. |
| 14 | `Tuvasa the Sunlit` | GUW | Bant enchantress, auras, Voltron/value | Expande enchantress alem de Sythis e testa splash azul para protecao/card selection sem colapsar com auras mono-white. | Scryfall legal; EDHREC commander page; Archidekt como apoio. | Baixo-medio: muitos enchantress staples resolviveis; risco de copiar Sythis com splash. | Media: usar para robustez enchantress. |
| 15 | `Xenagos, God of Revels` | GR | Gruul big creatures, haste, Voltron/stompy | Fecha Gruul com jogo casual de criaturas grandes, combat math e explosao de dano sem depender de combo. | Scryfall legal; EDHREC commander page; Archidekt como apoio. | Baixo: shell antigo; risco de ficar apenas Gruul goodstuff. | Media: primeiro Gruul casual recomendado. |
| 16 | `Captain Sisay` | GW | Selesnya legends toolbox, combo/control | Da uma lane toolbox para Selesnya, com risco competitivo explicito; diferente de tokens e enchantress. | Scryfall legal; EDHREC commander page; cEDH DDB citado como `Sisay`; Archidekt como apoio. | Medio-alto: pacotes competitivos e legends especificas podem gerar unresolved/off-theme. | Media: so com lanes casual/cEDH separadas. |
| 17 | `Liesa, Shroud of Dusk` | BW | Orzhov control, lifedrain, tax/punisher | Cobre control/drain Orzhov sem repetir aristocrats; util para ManaLoom entender pillowfort/tax leve. | Scryfall legal; EDHREC commander page; Archidekt como apoio. | Baixo-medio: Commander Legends e staples amplos; risco de stax desagradavel como default. | Media-baixa: apos Elenda. |
| 18 | `Giada, Font of Hope` | W | Mono-white Angel typal, counters, ramp | Reforca mono-white com typal creature deck, diferente de auras/equipment. | Scryfall legal; EDHREC commander page; Archidekt como apoio. | Medio: Angels recentes e reprints podem variar; checar cards SNC/LCI/FDN. | Media-baixa: bom para typal white. |
| 19 | `Tovolar, Dire Overlord` | GR | Gruul Werewolf typal, combat, card draw | Fecha typal Gruul e testa DFC/transform no corpus, uma classe importante de resolucao. | Scryfall legal; EDHREC commander page; Archidekt como apoio. | Medio-alto: DFCs e cards recentes podem aumentar unresolved/local casing. | Media-baixa: bom teste tecnico, nao primeiro lote. |
| 20 | `K'rrik, Son of Yawgmoth` | B | Mono-black lifepay, storm/combo, devotion | Segundo mono-black para lane high-power/cEDH; excelente para ensinar que vida e recurso, mas arriscado para casual. | Scryfall legal; EDHREC commander page; Archidekt como apoio; cEDH contexto nao provado neste passe. | Medio: pacote competitivo sensivel; risco principal e power mismatch. | Baixa-controlada: nao promover sem bracket/lane explicito. |

## Cobertura exigida

| Lacuna/tema pedido | Candidatos que cobrem |
| --- | --- |
| Mono-black | Yawgmoth, K'rrik |
| Mono-green | Selvala, Azusa |
| Mono-red | Magda, Zada |
| Mono-white | Sram, Giada |
| Azorius | Shorikai, Yorion |
| Gruul | Xenagos, Tovolar |
| Selesnya | Rhys, Captain Sisay |
| Dimir | The Scarab God |
| Orzhov | Elenda, Liesa |
| Artifacts | Shorikai, Magda, Sram |
| Enchantress | Tuvasa |
| Graveyard | Yawgmoth, The Gitrog Monster, The Scarab God |
| Spellslinger | Mizzix, Zada |
| Tokens | Rhys, Elenda, Zada |
| Lands | The Gitrog Monster, Azusa |
| Equipment | Sram |
| Blink | Yorion |
| Control | Shorikai, The Scarab God, Liesa |
| Combo | Selvala, Magda, Gitrog, Mizzix, K'rrik |
| Typal | Giada, Tovolar, Magda, The Scarab God |

## Interpretacao e malicia estrategica

- `Yawgmoth`, `Selvala`, `Magda`, `Gitrog`, `Captain Sisay`, `Shorikai` e `K'rrik`
  exigem separacao forte entre casual, high-power e cEDH. A existencia de sinal
  cEDH nao deve virar padrao de produto para Commander casual.
- `Sram`, `Rhys`, `Azusa`, `Xenagos`, `Zada`, `Elenda` e `Giada` parecem melhores
  para ganho rapido de cobertura casual porque seus planos sao legiveis e menos
  dependentes de loops.
- `Yorion` e `Tuvasa` sao candidatos de redundancia tematica: ajudam a provar que
  o engine aprendeu blink/enchantress como padroes transferiveis, nao apenas
  Brago/Sythis como excecoes.
- `Tovolar` e uma boa prova tecnica de DFC/typal, mas deve esperar ate o lote ter
  margem para lidar com unresolved de cartas recentes ou dupla face.

## Padroes uteis para absorver em `optimize` e `generate`

- Separar tokens por incentivo: go-wide agressivo (`Rhys`, `Zada`) vs aristocrats
  (`Elenda`, `Yawgmoth`) vs typal board (`Giada`, `Tovolar`).
- Modelar lands como engine: extra land drops (`Azusa`), graveyard lands/combo
  (`Gitrog`) e landfall/value ja coberto por `Aesi`.
- Criar guardrails de equipment separados de auras: `Sram` deve priorizar
  equipamentos, protecao/evasao e draw por cast, nao virar Light-Paws 2.
- Criar lane de artifacts por cor: mono-blue `Urza` ja existe; `Shorikai` e
  `Magda` adicionam UW control/artifacts e R treasure/artifacts.
- Tratar spellslinger por subtipo de incentivo: draw-damage (`Niv`), cost
  reduction (`Mizzix`), copy-wide (`Zada`) e magecraft (`Veyran`, ainda bloqueado).
- Registrar explicitamente quando um core package e casual, high-power ou cEDH.

## Padroes arriscados ou nao transferiveis automaticamente

- Nao importar listas cEDH como default casual para `Yawgmoth`, `Selvala`, `Magda`,
  `Gitrog`, `Captain Sisay`, `Shorikai` ou `K'rrik`.
- Nao usar stax/tax duro como padrao para `Shorikai`, `Grand Arbiter`-like plans
  ou `Liesa`; se aparecer, deve ser lane opt-in.
- Nao tratar typal como simples filtro por creature type: `Giada`, `Tovolar`,
  `Magda` e `The Scarab God` precisam payoffs, curva e suporte especificos.
- Nao promover comandantes apenas porque EDHREC tem pagina HTTP 200; isso prova
  contexto Commander, nao qualidade de corpus local.
- Nao repetir erro do Lote C: corpus legal 5/5 sem profile/card stats/fallback
  deterministico nao basta para promocao.

## Menores proximas acoes tecnicas

1. Rodar apenas scorecard/read-only para os 8 primeiros candidatos, sem apply:
   `Yawgmoth`, `Selvala`, `Shorikai`, `Magda`, `Sram`, `Gitrog`, `Mizzix`, `Rhys`.
2. Para os candidatos que passarem resolucao inicial, preparar corpus offline de
   3 a 5 decks por comandante usando sinais agregados de EDHREC e, quando
   aplicavel, cEDH DDB apenas como label de lane competitiva.
3. Bloquear qualquer candidato com `unresolved > 0`, `off_color > 0`,
   `commander_quantity != 1`, `main_quantity != 99` ou singleton violations fora
   de terrenos basicos.
4. Aplicar no banco somente apos dry-run PASS, repetir idempotencia e depois
   public proof 5/5 sanitizado de `/ai/generate`.
5. Exigir scorecard final `score=100`, `ready_for_mini_batch`, blockers/warnings
   vazios, `profile/stats/corpus used`, invalid/off-identity 0 e timeout fallback
   0 antes de qualquer promocao.
