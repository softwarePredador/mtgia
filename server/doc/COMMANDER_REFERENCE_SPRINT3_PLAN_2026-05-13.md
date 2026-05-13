# Commander Reference Sprint 3 Plan - 2026-05-13

## Resultado de abertura

**PASS WITH RISKS.**

A decisao post-Sprint 2 e **GO condicionado** para planejamento e preparacao
offline em batches pequenos, mas continua **NO-GO** para promocao ampla,
aplicacao no banco, corpus novo ou guidance forte sem repetir os gates por
comandante.

Este plano e documental. Nenhum corpus foi criado, nenhum artifact de decklist foi
persistido, nenhuma mutacao de banco foi executada e nenhum endpoint app-facing,
scanner, camera ou OCR foi alterado.

## Referencias locais lidas

- `server/doc/COMMANDER_REFERENCE_POST_SPRINT2_DECISION_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT2_FINAL_2026-05-13.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_READINESS_SCORECARD_2026-05-13.md`
- `server/test/artifacts/commander_reference_readiness_2026-05-13/readiness_scorecard_summary.json`
- `server/doc/COMMANDER_REFERENCE_SPRINT2_TRACKER_2026-05-13.md`
- `server/doc/COMMANDER_REFERENCE_PROFILE_ANCHOR_30_PLAN_2026-05-12.md`
- `docs/CONTEXTO_PRODUTO_ATUAL.md`
- `server/manual-de-instrucao.md`

## Separacao de evidencias

### Fatos locais provados

- Sprint 2 fechou **PASS WITH RISKS**: Kinnan, Muldrotha, Yuriko, Winota e
  Atraxa foram promovidos com public proof 5/5 e scorecard final `score=100`.
- Korvold ficou bloqueado: `core_package_weak`,
  `public_runtime_gate_not_passed`, timeout fallback 2/5 e scorecard 90.
- O gate obrigatorio por comandante exige corpus publico/offline, dry-run,
  apply, idempotencia, public proof 5/5 e readiness final `PASS`, `score=100`,
  `status=ready_for_mini_batch`, `timeout fallback=0`.
- O comparativo publico e a prova de valor app autorizam apenas expansao
  controlada: `commander_name` preservou comandante e ativou
  profile/stats/corpus, mas diagnostics continuam opcionais.
- A lista Anchor 30 local ja priorizava varios alvos aqui usados:
  `Teysa Karlov`, `Sythis, Harvest's Hand`, `Urza, Lord High Artificer`,
  `Krenko, Mob Boss`, `Light-Paws, Emperor's Voice`,
  `Meren of Clan Nel Toth`, `Niv-Mizzet, Parun`, `Brago, King Eternal`,
  `Feather, the Redeemed` e `Jodah, the Unifier`.

### Achados web-derived

Nao houve live web research nesta tarefa porque o objetivo era abrir um plano
sem corpus e sem aplicar no banco. A disponibilidade de corpus abaixo e
classificada como **esperada**, nao provada, ate a etapa futura de coleta
offline/sanitizada com fontes Commander claras.

### Interpretacao operacional

Sprint 3 deve maximizar diversidade sem misturar cEDH com Commander casual. A
fila prioriza lacunas deixadas pelo Sprint 2: mono-color, guildas nao cobertas,
artifacts, enchantments, tokens/counters e cinco cores. Comandantes de combo,
stax ou high-power so podem virar guidance forte se a lane de poder ficar
explicita no corpus e no scorecard.

## Cobertura planejada

| Dimensao | Cobertura Sprint 3 |
| --- | --- |
| WUBRG agregado | W, U, B, R e G aparecem em multiplos lotes; ha mono-W, mono-U, mono-R, guildas, tricolor e cinco cores. |
| Typal | Krenko, Jodah. |
| Spellslinger | Niv-Mizzet, Feather. |
| Graveyard | Meren, Korvold retry. |
| Artifacts | Urza. |
| Enchantments | Light-Paws, Sythis. |
| Tokens | Krenko, Teysa, Ghave, Korvold retry. |
| Counters | Ghave, Jodah como apoio legends/+1/+1; Atraxa ja cobre counters no Sprint 2 promovido. |
| Control | Niv-Mizzet, Urza, Brago. |
| Combat | Krenko, Light-Paws, Feather, Jodah. |
| Combo | Niv-Mizzet, Urza, Korvold retry, Ghave, Jodah. |

## Lote 1 - primeira execucao recomendada

| Prioridade | Commander | Cor | Tema | Motivo | Disponibilidade esperada de corpus | Risco de cartas novas/unresolved | Criterio de aceite |
| ---: | --- | --- | --- | --- | --- | --- | --- |
| 1 | `Krenko, Mob Boss` | R | Goblin typal, go-wide tokens, combat/aggro | Fecha lacuna mono-red e testa densidade de tokens/haste sem depender de multicolor. | Alta; comandante antigo, popular e com pacotes recorrentes de goblins, haste, sac outlets e payoff de go-wide. | Baixo; risco principal e pacote generico de goblins perder identidade Commander ou gerar curva/land count agressivo demais. | Corpus com 4+ fontes Commander claras, `unresolved=0`, `off_color=0`, main 99, pacote core forte de goblins/tokens/haste e public proof 5/5 sem timeout fallback. |
| 2 | `Light-Paws, Emperor's Voice` | W | Auras, Voltron, enchantments, combat | Fecha mono-white e separa Voltron/auras de white goodstuff ou enchantress generico. | Alta; deve haver sinais publicos abundantes de auras baratas, protecao, evasion e payoffs. | Medio; cartas de aura/protecao recentes podem faltar e a habilidade de tutor pode induzir pacotes repetitivos. | Corpus deve provar auras/protecao/evasion, singleton limpo, zero off-identity e deck gerado com plano Voltron reconhecivel sem virar white goodstuff. |
| 3 | `Niv-Mizzet, Parun` | UR | Spellslinger, draw-damage, control/combo | Cobre Izzet spellslinger e testa separacao entre casual, high-power e combo. | Alta; comandante historico com shells recorrentes de cantrips, wheels, counters e pingers. | Medio; risco maior e misturar shell cEDH/combo como default casual ou depender de wheels/pecas banidas/ausentes. | Corpus deve marcar lane de poder, preservar interacao/control, `timeout fallback=0`, sem cartas proibidas e sem tratar combo infinito como padrao casual. |
| 4 | `Teysa Karlov` | WB | Aristocrats, tokens, death triggers | Cobre Orzhov aristocrats sem colapsar com Dina BG, Edgar Mardu ou Korvold Jund. | Alta; padroes de death triggers, token makers, sac outlets e drain payoffs sao estaveis. | Baixo/medio; risco de nomes de tokens nao resolvidos em artefatos ou de pacote aristocrats ficar generico demais. | Corpus deve provar death triggers dobrados, sac outlets, token density e drain payoffs; scorecard final 100 e public proof 5/5. |

## Lote 2 - segunda execucao recomendada

| Prioridade | Commander | Cor | Tema | Motivo | Disponibilidade esperada de corpus | Risco de cartas novas/unresolved | Criterio de aceite |
| ---: | --- | --- | --- | --- | --- | --- | --- |
| 5 | `Meren of Clan Nel Toth` | BG | Graveyard recursion, sacrifice value, toolbox creatures | Cobre graveyard BG dedicado sem repetir Muldrotha BGU nem Korvold BRG. | Alta; comandante antigo com pacotes conhecidos de self-mill, sac outlets, criaturas utilitarias e recursion. | Baixo/medio; risco de overlap com Muldrotha e de loops high-power entrarem sem bracket explicito. | Corpus deve diferenciar recursion de permanentes BG, registrar lane casual/high-power e manter core package forte sem timeout fallback. |
| 6 | `Korvold, Fae-Cursed King` retry | BRG | Sacrifice, treasure, value/combo | Reabre apenas o bloqueado do Sprint 2 para corrigir core package e latencia. | Ja houve corpus local aceito 4/4, mas a qualidade runtime ficou insuficiente; nova disponibilidade e provavel, nao suficiente. | Alto; `core_package_weak` e timeout fallback 2/5 ja foram provados localmente. | So avanca se o novo corpus fortalecer sacrifice/treasure/value, readiness final chegar a `score=100`, public proof 5/5 e timeout fallback 0/5. |
| 7 | `Sythis, Harvest's Hand` | GW | Enchantress, enchantment value, auras support | Cobre enchantress GW e separa value engine de Light-Paws Voltron. | Alta; shell enchantress tem pacotes recorrentes de ramp, draw, protection e payoff. | Medio; pode colapsar com auras/Voltron ou depender de enchantments recentes nao sincronizados. | Corpus deve separar enchantress value de Voltron, provar engine de compra/ramp e zero unresolved/off-color. |
| 8 | `Urza, Lord High Artificer` | U | Artifacts, control, combo | Fecha artifacts mono-U e testa controle/combo sem contaminar decks casuais. | Alta, mas enviesada para high-power/cEDH; requer lane explicita. | Medio/alto; risco de stax/salt, pecas banidas, artifacts ausentes e cEDH virar default. | Corpus deve separar casual/high-power/cEDH, excluir pecas proibidas, preservar pacote artifact/control e passar public proof sem fallback. |

## Lote 3 - terceira execucao recomendada

| Prioridade | Commander | Cor | Tema | Motivo | Disponibilidade esperada de corpus | Risco de cartas novas/unresolved | Criterio de aceite |
| ---: | --- | --- | --- | --- | --- | --- | --- |
| 9 | `Brago, King Eternal` | WU | Blink, ETB value, control/stax-adjacent | Cobre Azorius control/blink e reaproveita pacotes ETB sem virar somente stax. | Alta; comandante antigo com sinais publicos estaveis de blink, rocks e ETB value. | Medio; risco de stax/salt e de artifacts utilitarios dominarem a identidade do deck. | Corpus deve distinguir blink value de stax duro, manter plano ETB claro e passar gates sem timeout fallback. |
| 10 | `Feather, the Redeemed` | RW | Spellslinger-Voltron, protection spells, combat | Cobre Boros spellslinger/protecao sem repetir Winota combat engine. | Alta; pacotes de pump, protection, heroic-like e cantrips sao recorrentes. | Baixo/medio; risco de overlap com Light-Paws Voltron e de truques recentes nao resolvidos. | Corpus deve provar loop de spells reutilizaveis, protecao e combate, com main 99, singleton limpo e comandante preservado 5/5. |
| 11 | `Jodah, the Unifier` | WUBRG | Legendary typal, five-color value/combat/combo | Fecha cinco cores e testa typal legends sem cair em goodstuff sem tema. | Alta; Anchor 30 local ja prioriza Jodah e o corpus de resolucao local ja cobre o nome como caso estavel de identidade. | Medio/alto; cinco cores aumenta risco de off-color, staples genericos e cartas recentes de legends. | Corpus deve provar legends-matter, evitar cinco cores generico, `off_color=0`, comandante fora das 99 e public proof 5/5. |
| 12 | `Ghave, Guru of Spores` | WBG | Tokens, +1/+1 counters, aristocrats/combo | Cobre counters/tokens Abzan e testa combo modular sem depender de Atraxa. | Media/alta; comandante antigo e popular, mas nao aparece no Anchor 30 local lido. | Medio/alto; muitas linhas de combo e pecas de counters/saprolings podem inflar complexidade ou cair em shell aristocrats generico. | Corpus deve provar tokens+counters como eixo primario, registrar lane casual/high-power, evitar combo como default casual e fechar scorecard 100. |

## Regras de execucao para quando o corpus for criado

1. Preparar no maximo um lote de 4 por vez.
2. Usar somente fontes publicas Commander claras e salvar apenas sinais agregados:
   roles, recorrencia, pacotes, contagens e summaries sanitizados.
3. Nao persistir decklists completas, prompts completos, credenciais, tokens ou
   nomes/valores de variaveis sensiveis.
4. Nao fazer scraping em runtime; a coleta deve ser offline e auditable.
5. Antes de qualquer apply: dry-run DB-backed com comandante resolvido,
   `commander_quantity=1`, `main_quantity=99`, `unresolved=0`, `off_color=0` e
   singleton limpo fora de terrenos basicos.
6. Depois de dry-run PASS: apply controlado, idempotencia, public proof sanitizado
   5/5 e readiness scorecard final.
7. Comandante com qualquer blocker, warning relevante, fallback de timeout,
   `score<100` ou `public_runtime_gate_not_passed` fica `BLOCKED` ou
   `PASS WITH RISKS`, sem guidance forte.

## Lote A - corpus prep executado em 2026-05-13

Tracker:
`server/doc/COMMANDER_REFERENCE_SPRINT3_TRACKER_2026-05-13.md`.

Relatorio:
`server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT3_LOT_A_CORPUS_PREP_2026-05-13.md`.

Artifacts:
`server/test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/<safe_commander>/corpus.json`
e
`server/test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/<safe_commander>/dry_run/`.

| Commander | corpus_prepared | dry_run | apply | idempotency | public_proof | readiness_scorecard | Promocao |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `Krenko, Mob Boss` | DONE | DONE, PASS | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | false |
| `Light-Paws, Emperor's Voice` | DONE | DONE, PASS | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | false |
| `Niv-Mizzet, Parun` | DONE | DONE, PASS | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | false |
| `Teysa Karlov` | DONE | DONE, PASS | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | false |

Todos os dry-runs do Lote A foram executados com `db_mutations=false`,
comandante resolvido, `commander_quantity=1`, `main_quantity=99`,
`unresolved=0`, `off_color=0` e `singleton_violations={}` em todos os decks.
Nenhum corpus foi aplicado no banco.

## Menores proximas acoes tecnicas

1. Se o Lote A for continuar, rodar `--apply` controlado apenas para corpora que
   continuarem PASS, seguido de idempotencia e contagens DB-backed.
2. Executar public proof sanitizado 5/5 e readiness scorecard final por
   comandante antes de qualquer promocao.
3. Manter Niv-Mizzet com lane combo/control explicita para nao contaminar casual
   Commander com default high-power.
4. Atualizar `server/doc/API_CONTRACTS_AND_DATA_MAP.md` apenas se houver mudanca
   real de rota, payload, response shape, diagnostics app-facing, async job ou
   consumer mobile.

## Decisao

**PASS WITH RISKS** para abrir Sprint 3 apenas como plano e futura execucao em
3 lotes de 4. **BLOCKED** para corpus, apply, promocao ou guidance forte neste
commit.
