# Life Counter - Next Sprints - 2026-03-30

## Snapshot

Estado final desta frente do contador:

- baseline visual e de gameplay da mesa continua Lotus-faithful
- diretriz oficial: o `WebView` do Lotus e a camada visual oficial da mesa
- ManaLoom fica com backend, persistencia, snapshot bridge, normalizacao e regras de mesa
- sem pedido explicito, mudanca visual nova deve preservar o Lotus 1:1
- decisao fechada: o `WebView` nao entra em roadmap de remocao enquanto a prioridade for manter ou superar o padrao visual atual do Lotus
- customizacao visual futura deve priorizar alteracoes no proprio `WebView`, nao reimplementacao do board em Flutter puro

## O que ficou fechado

- host Flutter e shell policy ManaLoom-owned
- sessao canonica, settings canonicas e fronteiras de persistencia ManaLoom-owned
- fluxo visual principal devolvido ao Lotus para:
  - `settings`
  - `history`
  - `card search`
  - `dice`
  - `turn tracker`
  - `game timer / clock`
  - `table state`
  - `day / night`
  - `player state`
  - `set life`
  - `player counters`
  - `commander damage`
  - `player appearance`
- `Planechase`, `Archenemy` e `Bounty` definidos como fluxos Lotus-first visuais no produto final
- `edit cards` e card pools permanecem embutidos no Lotus por decisao explicita
- revisao formal das native sheets concluida
- primeira poda controlada concluida:
  - `life_counter_native_quick_actions_sheet.dart`

## Validacao consolidada

Fonte de verdade da validacao final:

- `app/doc/LIFE_COUNTER_FINAL_VALIDATION_2026-04-02.md`

Cobertura final relevante:

- bootstrap e reopen do contador vivo
- reload/rebootstrap com snapshot canonico
- player counts:
  - 2
  - 5
  - 6
- overlays visuais Lotus-first:
  - menu radial
  - history
  - card search
- runtime de jogador no Android real:
  - `player state`
  - `player counters`
  - `commander damage`
  - `player state -> set life -> autoKill`
- round-trip real de:
  - `storm`
  - `monarch`
  - `initiative`
  - `commander damage`
  - `commander cast`
  - `extra counters`
- `Game Modes` no Android real:
  - abertura da shell interna de suporte
  - `settings`
  - card pool ativo

## O que continua Lotus-owned

- runtime central da mesa
- overlays internos de gameplay
- commander damage runtime visual
- `Planechase`, `Archenemy` e `Bounty` como experiencias visuais/gameplay

Observacao:

- esses pontos permanecem Lotus-owned por decisao explicita de fidelidade visual
- isso nao e debito obrigatorio de migracao nesta fase

## Sprint 1 - Closed

Fechado.

## Sprint 2 - Closed

Fechado.

## Sprint 3 - Closed

Fechado.

## Sprint 4 - Commander Damage And Player Runtime

Status: closed under Lotus-first architecture

Fechado com:

- runtime de jogador Lotus-first visualmente e ManaLoom-backed por tras
- pipeline canonico consolidado para sessao, tracker, ownership e `autoKill`
- smokes Android finais fechados para runtime de jogador e round-trips criticos

## Sprint 5 - Game Modes And Endgame

Status: closed under Lotus-first architecture

Fechado com:

- `Planechase`, `Archenemy` e `Bounty` suportados como fluxos Lotus-first visuais
- ManaLoom por tras em observabilidade, handoff tecnico e persistencia quando necessario
- `Game Modes` fechados como parte do produto final sem ambiguidade

## Documentos principais

- `app/doc/LIFE_COUNTER_WEBVIEW_EXECUTION_PLAN_2026-04-02.md`
- `app/doc/LIFE_COUNTER_NATIVE_SHEETS_REVIEW_2026-04-02.md`
- `app/doc/LIFE_COUNTER_FINAL_VALIDATION_2026-04-02.md`

## Trabalho futuro opcional

Nenhum sprint adicional e obrigatorio para considerar o life counter encerrado nesta arquitetura.

Se houver novo briefing, o trabalho futuro mais provavel e:

1. hardening adicional do backend invisivel em pontos especificos
2. poda controlada de fallback interno quando houver cobertura equivalente
3. customizacao visual no proprio Lotus, sem reimplementar a mesa em Flutter puro

## Notes

- a prioridade continua sendo preservar a mesa visualmente igual ao Lotus
- o `WebView` permanece como renderer visual oficial
- toda evolucao visual futura deve priorizar o proprio Lotus
