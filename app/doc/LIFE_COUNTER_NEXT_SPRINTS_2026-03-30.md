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
- validacao automatizada atual cobre:
  - bootstrap/reopen do contador vivo
  - reboot dedicado do snapshot persistido do contador vivo
  - player counts 2, 5 e 6
  - sinais visuais de settings no WebView
  - history/card search nativos no caminho vivo
  - engine e sheet nativa do turn tracker
  - tracker runtime apos reload do bundle

O que ainda continua Lotus-owned:

- runtime central da mesa
- overlays internos de gameplay
- commander damage runtime
- game timer runtime real
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

## Sprint 3 - Timer And Clock Ownership

Status: next

Objetivo:

- assumir `game timer` e `clock` como superficie/controlador nosso, ainda sem redesenhar a mesa

Escopo:

- mapear o contrato real do Lotus para timer/clock
  - `gameSettings.gameTimer`
  - `gameSettings.gameTimerMainScreen`
  - `gameSettings.showClockOnMainScreen`
  - `turnTracker.turnTimer`
- `gameTimerState.startTime / isPaused / pausedTime`
- decidir se:
  - so sincronizamos a configuracao e runtime no bundle
  - ou tomamos posse do timer surface com overlay Flutter
- validar:
  - start/pause/resume
  - persistencia apos reload
  - `showClockOnMainScreen`
  - `gameTimerMainScreen`

Done when:

- timer e clock tem contrato nosso claro
- runtime real passa em smoke de configuracao e continuidade
- nao ha regressao visual na mesa

Progress so far:

- o host ja espelha e reidrata `gameTimerState` via contrato canonico proprio
- o snapshot de UI ja diferencia:
  - game timer real
  - game timer pausado
  - clock
  - clock acoplado ao game timer

## Sprint 4 - Commander Damage And Player Runtime

Objetivo:

- preparar a saida do Lotus nas partes de jogador mais sensiveis, sem ainda remover a mesa

Escopo:

- mapear com mais fidelidade:
  - commander damage por fonte
  - partner commander
  - counters clicaveis
  - estados especiais de jogador
- aumentar o contrato canonico so no que o runtime realmente usa
- decidir a primeira subfatia viavel para migracao nativa:
  - commander damage shell
  - counters shell
  - overlays auxiliares

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

1. Sprint 3 - Timer And Clock Ownership
2. Sprint 4 - Commander Damage And Player Runtime
3. Sprint 5 - Game Modes And Endgame

## Notes

- a prioridade continua sendo preservar a mesa visualmente igual ao Lotus
- toda substituicao deve acontecer por casca/contrato primeiro, layout depois
- se algum slice exigir mudar a mesa para continuar, isso deve subir como risco explicito antes de implementar
