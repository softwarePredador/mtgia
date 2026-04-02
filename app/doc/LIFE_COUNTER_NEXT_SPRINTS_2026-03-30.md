# Life Counter - Next Sprints - 2026-03-30

## Snapshot

Estado atual do contador:

- baseline visual e de gameplay da mesa continua Lotus-faithful
- diretriz atual: o `WebView` do Lotus e a camada visual oficial da mesa; ManaLoom continua dona de backend, persistencia, normalizacao e customizacao futura por cima do proprio Lotus
- sem pedido explicito, mudanca visual nova deve preservar o Lotus 1:1
- host Flutter e shell policy ja sao ManaLoom-owned
- sessao canonica, settings canonicas e fronteiras de persistencia ja sao nossas
- fluxo visual ja devolvido ao Lotus para:
  - settings
  - history
  - card search
- fluxo visual tambem devolvido ao Lotus para:
  - player state
  - set life
  - player counters
  - commander damage
  - player appearance
- pacote prioritario de reversao visual ja aplicado para:
  - dice
  - turn tracker
  - game timer / clock
  - table state
  - day / night
- validacao automatizada atual cobre:
  - bootstrap/reopen do contador vivo
  - reboot dedicado do snapshot persistido do contador vivo
  - player counts 2, 5 e 6
  - sinais visuais de settings no WebView
  - history/card search nativos no caminho vivo
  - engine e sheet nativa do turn tracker
  - tracker runtime apos reload do bundle
  - game timer pausado via bootstrap canonico
  - game timer ativo com continuidade apos reload
  - game timer shell no caminho vivo
  - clock-only surface abrindo a shell nativa do timer
  - round-trip real de commander damage com partner commander
  - round-trip real de storm, monarch e initiative
  - round-trip real de commander tax separado em `tax-1` e `tax-2`
  - round-trip real de custom counters por jogador

O que ainda continua Lotus-owned:

- runtime central da mesa
- overlays internos de gameplay
- commander damage runtime
- Planechase, Archenemy e Bounty

## Next Actions

Ordem de execucao a partir do estado atual:

1. fechar o baseline visual Lotus-first
2. alinhar os testes com a diretriz real do produto
3. fortalecer o backend invisivel por tras do `WebView`
4. revisar sheets nativas e fluxos internos que nao sao mais visuais
5. fechar a decisao explicita de `Game Modes`

Documento operacional principal desta fase:

- `app/doc/LIFE_COUNTER_WEBVIEW_EXECUTION_PLAN_2026-04-02.md`

Proximo passo imediato:

- alinhar a suite de testes com a diretriz Lotus-first, separando visual Lotus de fallback interno

## Sprint 1 - Closed

Objetivo fechado:

- assumir as primeiras superficies substituiveis sem mexer no layout da mesa

Entregas fechadas:

- settings nativa
- history nativa
- import/export proprio de history
- card search nativa
- validacoes reais de UI/settings/player counts
- turn tracker engine e shell nativa

Pendencia que nasceu no fechamento:

- o runtime real do Lotus ainda normaliza o `turnTracker` no reboot, mesmo depois de aplicarmos o estado canonico

## Sprint 2 - Closed

Objetivo fechado:

- fechar a lacuna entre a shell nativa do turn tracker e o comportamento real do runtime embutido

Entregas fechadas:

- o runtime do Lotus agora so e carregado depois do bootstrap do snapshot
- reload do bundle preserva o tracker no caminho vivo
- reabertura via snapshot persistido ficou validada em smoke dedicado
- o drift observado no `currentPlayerIndex` foi reduzido a normalizacao esperada do proximo jogador vivo

Nota de fechamento:

- o bundle ainda continua dono do runtime visual do tracker na mesa
- o proximo ganho real deixa de ser tracker e passa a ser `game timer` e `clock`

## Sprint 3 - Closed

Objetivo fechado:

- assumir `game timer` e `clock` como superficie/controlador nosso, ainda sem redesenhar a mesa

Entregas fechadas:

- contrato canonico proprio de `gameTimerState`
- adapter entre `gameTimerState` e snapshot vivo do Lotus
- engine propria de `start/pause/resume/reset`
- sheet nativa do `game timer`
- shell do `clock` apontando para a mesma superficie ManaLoom
- snapshot de UI capaz de distinguir:
  - game timer real
  - game timer pausado
  - clock
  - clock acoplado ao game timer
- smokes reais cobrindo:
  - configuracao visual do timer/clock
  - timer pausado
  - timer ativo com continuidade apos reload
  - abertura do timer shell no caminho vivo
  - abertura do clock-only surface no caminho vivo

Nota de fechamento:

- a mesa continua visualmente Lotus-faithful
- o runtime visual interno do timer ainda e o do bundle, mas a superficie e o contrato agora ja estao sob posse ManaLoom

## Sprint 4 - Commander Damage And Player Runtime

Status: in progress

Objetivo:

- preparar a saida do Lotus nas partes de jogador mais sensiveis, sem ainda remover a mesa

Escopo:

- mapear com mais fidelidade:
  - commander damage por fonte
  - partner commander
  - commander tax por parceiro
  - counters clicaveis
  - table state auxiliar de gameplay
  - estados especiais de jogador
- aumentar o contrato canonico so no que o runtime realmente usa
- decidir a primeira subfatia viavel para migracao nativa:
  - commander damage shell
  - counters shell
  - overlays auxiliares

Progresso fechado ate agora:

- split real de `commander1/commander2` preservado no contrato canonico
- `storm`, `monarch` e `initiative` preservados por chave auxiliar nossa no snapshot vivo
- `commander tax` preservado com detalhe proprio de `commander_one_casts` e `commander_two_casts`
- counters arbitrarios do Lotus preservados em `player_extra_counters`
- shells nativas de runtime de jogador ja assumidas:
  - `commander damage`
  - `player appearance`
  - `player counters`
  - `player state`
  - `set life`
- shell nativa adicional assumida no runtime vivo:
  - `table state`
- o `menu-button` voltou ao overlay radial original do Lotus
- `settings`, `history` e `card search` tambem voltaram ao visual original do Lotus
- a shell nativa de `game modes` continua existindo em codigo, mas o objetivo agora e preservar o overlay visual do Lotus como fluxo principal
- os botoes de `settings` dentro dos overlays ativos de `Planechase`, `Archenemy` e `Bounty` agora tambem retornam primeiro para a shell ManaLoom
- shell nativa adicional assumida no runtime vivo:
  - `dice / high roll / coin / roll 1st`
- `player state` agora funciona como hub para:
  - `set life`
  - `player counters`
  - `commander damage`
  - `player appearance`
  - `player D20`
- a shell nativa de `table state` agora controla:
  - `storm`
  - `monarch`
  - `initiative`
- `set life`, `player counters`, `player state` e `table state` agora compartilham uma engine canonica inicial da mesa
- `commander damage` agora tambem compartilha essa engine canonica inicial da mesa para leitura e escrita do split por comandante
- o resumo letal e a deteccao de fonte letal de `commander damage` agora tambem passam pela engine canonica da mesa, em vez de ficarem espalhados na shell
- `set life` agora tambem cobre ajustes rapidos de dano/cura pela mesma engine canonica, aproximando a saida do runtime implicito do Lotus
- `autoKill` agora tambem passa pela engine canonica e ja e aplicado nos fluxos nativos de `set life`, `player counters` e `commander damage`
- `player state` agora tambem aciona transicoes canonicas de jogador como `knock out`, `decked out`, `left table` e `revive`
- a engine canonica agora tambem concentra sinais criticos de counters para feedback nativo de `poison` e `commander tax`
- a engine canonica agora tambem concentra o status atual do jogador, incluindo letalidade por vida, poison e commander damage, alem de estados especiais
- o hub nativo de `player counters` agora tambem reflete esse status canonico do jogador, reduzindo mais feedback implicito do Lotus
- a shell nativa de `set life` agora tambem reflete esse status canonico do jogador em tempo real, antes do apply
- a shell nativa de `commander damage` agora tambem reflete esse status canonico do alvo em tempo real, antes do apply
- o status canonico do jogador agora tambem vive em uma estrutura unica da `LifeCounterTabletopEngine`, reduzindo mais duplicacao entre `set life`, `player counters`, `player state` e `commander damage`
- a `LifeCounterTabletopEngine` agora tambem expõe um `player board summary` unico para as shells nativas, reunindo status, sinais criticos e resumo letal de commander damage
- `Player State` agora tambem passa por `autoKill` quando hubs aninhados devolvem uma sessao letal, preservando estados especiais manuais
- o estado de `day / night` agora fica em store propria e eh reaplicado no bundle via `__manaloom_day_night_mode`
- os hints legados de `turn tracker` e `counters on card` agora sao suprimidos e marcados como concluidos pela shell policy
- `player appearance` agora tambem tem transporte proprio de import/export via clipboard
- perfis salvos de aparencia agora ficam em store propria ManaLoom
- `__manaloom_table_state` agora preserva tambem:
  - `lastPlayerRolls`
  - `lastHighRolls`
  - `firstPlayerIndex` auxiliar
- o toque no total de vida do jogador agora pode abrir a shell nativa de `set life`
- smokes reais adicionados:
  - `integration_test/life_counter_commander_damage_roundtrip_smoke_test.dart`
  - `integration_test/life_counter_table_state_roundtrip_smoke_test.dart`
  - `integration_test/life_counter_commander_cast_roundtrip_smoke_test.dart`
  - `integration_test/life_counter_extra_counters_roundtrip_smoke_test.dart`
  - `integration_test/life_counter_native_commander_damage_smoke_test.dart`
  - `integration_test/life_counter_native_player_appearance_smoke_test.dart`
  - `integration_test/life_counter_native_player_appearance_profiles_smoke_test.dart`
  - `integration_test/life_counter_native_player_counter_smoke_test.dart`
  - `integration_test/life_counter_native_player_state_smoke_test.dart`
  - `integration_test/life_counter_native_player_state_d20_hub_smoke_test.dart`
  - `integration_test/life_counter_native_player_state_set_life_hub_smoke_test.dart`

Done when:

- existe plano de fatiamento do runtime de jogador com ordem de migracao
- nao restam campos “soltos” sem dono entre sessao canonica e snapshot vivo

- overlays auxiliares mais leves da mesa tambem ja tem dono claro em superficies ManaLoom

## Sprint 5 - Game Modes And Endgame

Objetivo:

- tirar da frente o backlog de modos extras antes da troca final da mesa

Escopo:

- Planechase
- Archenemy
- Bounty
- revisar overlay/hints remanescentes ainda Lotus-only

Progresso inicial:

- shell nativa de `game modes` ainda existe em codigo como suporte de backend/handoff
- `Planechase`, `Archenemy` e `Bounty` agora seguem o Lotus como fluxo visual principal
- a shell nativa de `game modes` fica preservada como apoio tecnico de backend, observabilidade e fluxos internos
- diretriz atual desta frente: preservar o overlay visual do Lotus como fluxo principal e usar ManaLoom como camada invisivel de estado, observabilidade e handoff tecnico

Done when:

- os modos extras tem dono claro:
  - continuam no Lotus por decisao explicita
  - ou entram no backlog de migracao nativa com contrato definido

Pendencias reais apos a revalidacao:

  - o host do contador vivo agora tambem consolida a aplicacao de sessoes nativas por um caminho unico de normalizacao e persistencia, reduzindo drift entre `set life`, `player counters`, `player state` e `commander damage`
  - a `LifeCounterTabletopEngine` agora tambem concentra esse pipeline de normalizacao de board em um metodo unico, reduzindo dependencia da ordem de saneamento no host
  - `turn tracker` e `table state` agora tambem usam a mesma nocao canonica de jogador ativo da `LifeCounterTabletopEngine`, em vez de checagens locais mais fracas
  - a propria `LifeCounterTabletopEngine` agora tambem recusa `monarch` e `initiative` para jogadores fora da mesa, nao so a shell de `table state`
  - `high roll` e `roll 1st` agora tambem respeitam apenas jogadores ativos, reduzindo mais um ponto de dependencia do comportamento implicito do Lotus
  - a aplicacao de `dice` no host agora tambem passa pelo mesmo caminho central de normalizacao e persistencia usado pelas outras shells nativas
  - o snapshot vivo agora tambem atualiza `turnTracker` pelo mesmo funil canonico de persistencia, evitando drift entre sessao ajustada e bundle recarregado
  - o adapter do snapshot agora tambem serializa `turnTracker` usando a mesma nocao canonica de jogador ativo da engine da mesa
  - a apresentacao de `special state` do jogador agora tambem sai da shell e passa a ser definida pela `LifeCounterTabletopEngine`
- quando um jogador sai da mesa por estado letal, a engine canonica agora tambem saneia `monarch` e `initiative`, evitando ownership preso em jogador fora do jogo
  - quando um jogador sai da mesa por estado letal, a camada canonica agora tambem realinha `currentTurnPlayerIndex` e `firstPlayerIndex`, evitando tracker preso em jogador fora do jogo
  - quando nao sobra nenhum jogador ativo, o tracker canonico agora limpa os ponteiros em vez de manter referencia a jogador fora da mesa
  - revalidar em AVD limpo os smokes vivos mais novos que ainda sofrem com `INSTALL_FAILED_INSUFFICIENT_STORAGE`
- decidir se `edit cards` de `Planechase`, `Archenemy` e `Bounty` vao permanecer embutidos por decisao explicita ou se entram no backlog de migracao nativa
- fechar a decisao final sobre o runtime central da mesa antes de falar em remocao do `WebView`

## Exit Criteria Before Replacing The Tabletop

Antes de trocar o runtime central da mesa, precisamos ter:

- settings owned end-to-end
- history owned end-to-end
- card search owned end-to-end
- turn tracker runtime validado no caminho vivo
- timer/clock validados no caminho vivo
- contrato canonico estavel para jogador/counters/commander damage

## Recommended Order

1. Sprint 4 - Commander Damage And Player Runtime
2. Sprint 5 - Game Modes And Endgame

## Notes

- a prioridade continua sendo preservar a mesa visualmente igual ao Lotus
- toda substituicao deve acontecer por casca/contrato primeiro, layout depois
- se algum slice exigir mudar a mesa para continuar, isso deve subir como risco explicito antes de implementar
