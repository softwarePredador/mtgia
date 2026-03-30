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
  - player counts 2, 5 e 6
  - sinais visuais de settings no WebView
  - history/card search nativos no caminho vivo
  - engine e sheet nativa do turn tracker

O que ainda continua Lotus-owned:

- runtime central da mesa
- overlays internos de gameplay
- commander damage runtime
- turn tracker runtime real apos reboot do bundle
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

## Sprint 2 - Tracker Runtime Ownership

Objetivo:

- fechar a lacuna entre a shell nativa do turn tracker e o comportamento real do runtime embutido

Escopo:

- descobrir quais chaves/flags o Lotus exige para manter o tracker ativo apos reload
- ajustar bootstrap/snapshot para preservar:
  - `isActive`
  - `ongoingGame`
  - `startingPlayerIndex`
  - `currentPlayerIndex`
  - `currentTurn`
  - `turnTimer`
- validar runtime real para:
  - abrir tracker nativo
  - aplicar start game
  - reabrir app
  - manter tracker ativo
- se necessario, introduzir espelho adicional nosso para hints/flags que o Lotus nao persiste sozinho

Done when:

- existe smoke de integracao verde para `turn tracker` no caminho vivo
- o tracker volta ativo apos reload
- o estado canonico e o snapshot vivo convergem sem drift no caso padrao de 4 jogadores

Risco principal:

- o Lotus pode depender de side effects de boot alem do objeto `turnTracker`

## Sprint 3 - Timer And Clock Ownership

Objetivo:

- assumir `game timer` e `clock` como superficie/controlador nosso, ainda sem redesenhar a mesa

Escopo:

- mapear o contrato real do Lotus para timer/clock
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

1. Sprint 2 - Tracker Runtime Ownership
2. Sprint 3 - Timer And Clock Ownership
3. Sprint 4 - Commander Damage And Player Runtime
4. Sprint 5 - Game Modes And Endgame

## Notes

- a prioridade continua sendo preservar a mesa visualmente igual ao Lotus
- toda substituicao deve acontecer por casca/contrato primeiro, layout depois
- se algum slice exigir mudar a mesa para continuar, isso deve subir como risco explicito antes de implementar
