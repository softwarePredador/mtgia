# Life Counter - Next Sprints - 2026-03-30

## Snapshot

Estado atual do contador:

- baseline visual e de gameplay da mesa continua Lotus-faithful
- host Flutter e shell policy ja sao ManaLoom-owned
- sessao canonica, settings canonicas e fronteiras de persistencia ja sao nossas
- shells nativas ja assumidas:
  - settings
  - history
  - card search
  - turn tracker shell
  - game timer shell
  - player appearance shell
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
- `menu-button` do Lotus agora pode abrir um hub rapido ManaLoom para:
  - `settings`
  - `history`
  - `card search`
  - `turn tracker`
  - `game timer`
  - `dice`
- shell nativa adicional assumida no runtime vivo:
  - `dice / high roll / coin / roll 1st`
- `player state` agora funciona como hub para:
  - `player counters`
  - `commander damage`
  - `player appearance`
  - `player D20`
- takeover do `option-card` do Lotus abre a shell nativa de estado do jogador
- `killed-overlay` funciona como atalho real para a shell nativa de estado do jogador
- takeover do `color-card` e da entrada de background do Lotus abre a shell nativa de aparencia do jogador
- `player appearance` agora tambem tem transporte proprio de import/export via clipboard
- perfis salvos de aparencia agora ficam em store propria ManaLoom
- `__manaloom_table_state` agora preserva tambem:
  - `lastPlayerRolls`
  - `lastHighRolls`
  - `firstPlayerIndex` auxiliar
- `dice-btn` do Lotus agora abre a shell nativa de `dice/high roll/coin/roll 1st`
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

Done when:

- existe plano de fatiamento do runtime de jogador com ordem de migracao
- nao restam campos “soltos” sem dono entre sessao canonica e snapshot vivo

## Sprint 5 - Game Modes And Endgame

Objetivo:

- tirar da frente o backlog de modos extras antes da troca final da mesa

Escopo:

- Planechase
- Archenemy
- Bounty
- revisar overlay/hints remanescentes ainda Lotus-only

Done when:

- os modos extras tem dono claro:
  - continuam no Lotus por decisao explicita
  - ou entram no backlog de migracao nativa com contrato definido

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
