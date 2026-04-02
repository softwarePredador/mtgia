# Life Counter - WebView Execution Plan - 2026-04-02

## Objective

Travamos a diretriz do contador assim:

- o `WebView` do Lotus e a camada visual oficial da mesa
- ManaLoom fica com backend, persistencia, snapshot bridge, normalizacao e regras de mesa
- sem pedido explicito, nenhuma task nova deve mudar o visual do Lotus

Em termos praticos:

- o usuario deve enxergar Lotus
- o estado critico deve ser nosso
- o host Flutter deve agir como uma camada invisivel

## Immediate Goal

Fechar o baseline `Lotus visual + backend ManaLoom` sem abrir uma frente nova de redesign.

O que significa fechar esse baseline:

- menu radial do Lotus preservado
- overlays principais do Lotus preservados
- stores e engines ManaLoom continuam espelhando e normalizando o estado
- reload e reopen continuam estaveis
- testes automatizados refletem que o fluxo visual principal e Lotus-first

## Rules

### Always do

- preservar o visual do Lotus como padrao
- usar o host Flutter para observar, normalizar e persistir
- concentrar regra em:
  - `LifeCounterTabletopEngine`
  - `LifeCounterTurnTrackerEngine`
  - `LifeCounterDiceEngine`
  - adapters de snapshot e settings
- validar cada pacote com:
  - `flutter analyze`
  - testes de host/policy relevantes
  - smoke Android quando o fluxo for visual no `WebView`
- commitar e subir ao final de cada task fechada

### Never do without explicit approval

- criar ou recolocar sheet Flutter como fluxo visual principal
- redesenhar menu, overlay ou affordance que ja exista no Lotus
- planejar remocao do `WebView` como meta imediata
- tratar Flutter como substituto visual da mesa

### Allowed exceptions

- fallback interno de debug
- smoke helpers para JS/DOM
- suporte interno temporario para diagnostico de fluxo vivo

Essas excecoes nao devem virar fluxo principal.

## Execution Order

### Step 1 - Finish the Lotus-first visual baseline

#### What must be true

- `menu-button` abre o menu radial do Lotus
- `settings`, `history` e `card search` abrem overlays do Lotus
- `dice`, `turn tracker`, `game timer / clock`, `table state` e `day / night` continuam Lotus-first
- superfícies de jogador continuam Lotus-first

#### What still needs work

- manter a validacao automatizada de `card search` no Android real junto do baseline Lotus-first
- revisar se existe qualquer takeover visual restante em `lotus_shell_policy.dart`
- revisar testes de host que ainda assumem `open-native-*` como caminho principal

#### Acceptance

- smoke Android cobrindo pelo menos:
  - menu Lotus
  - history Lotus
  - card search Lotus ou justificativa tecnica documentada
- nenhum clique principal do menu deve abrir UI Flutter sem pedido explicito

### Step 2 - Align tests with the real product direction

#### Objective

Parar de misturar teste de fluxo visual principal com teste de fallback interno.

#### What to do

- separar testes de:
  - visual Lotus-first
  - backend invisivel ManaLoom
  - fallback/debug interno
- manter `lotus_life_counter_screen_test.dart` focado em:
  - persistencia
  - normalizacao
  - saneamento de sessao
  - fluxo interno do host
- manter integration tests focados em:
  - caminho visual real no `WebView`

#### Acceptance

- fica claro no nome e no conteudo de cada teste se ele valida:
  - UI Lotus
  - backend ManaLoom
  - fallback interno

### Step 3 - Strengthen the invisible backend

#### Objective

Continuar puxando comportamento critico para o nosso lado sem mexer no visual.

#### Priority areas

1. `turnTracker`
2. `table ownership`
3. `dice / high roll / roll 1st`
4. `autoKill`
5. `commander damage`
6. `snapshot reload / reopen`

#### What to do

- manter o pipeline unico:
  - snapshot vivo
  - derivacao canonica
  - normalizacao por engine
  - persistencia canonica
  - reidratacao do Lotus quando necessario
- remover calculos de regra duplicados espalhados em UI Flutter

#### Acceptance

- nenhum bug novo de drift entre sessao canonica e snapshot
- cada nova regra entra primeiro na engine, nao na UI

### Step 4 - Review native sheets and internal-only flows

#### Objective

Decidir o que ainda deve existir apenas como suporte interno e o que ja pode ser podado.

#### Candidate files to review

- `life_counter_native_settings_sheet.dart`
- `life_counter_native_history_sheet.dart`
- `life_counter_native_card_search_sheet.dart`
- `life_counter_native_turn_tracker_sheet.dart`
- `life_counter_native_game_timer_sheet.dart`
- `life_counter_native_dice_sheet.dart`
- `life_counter_native_table_state_sheet.dart`
- `life_counter_native_day_night_sheet.dart`
- sheets de runtime de jogador

#### Rule

Nao remover por impulso.

Primeiro classificar cada uma como:

- principal
- fallback interno
- debug only
- pronta para poda

#### Acceptance

- cada sheet listada acima tem dono e status claro

### Step 5 - Decide the boundary of Game Modes

#### Objective

Fechar de forma explicita o destino de:

- `Planechase`
- `Archenemy`
- `Bounty`

#### Decision options

1. permanecem Lotus-owned visual e funcionalmente
2. permanecem Lotus-first visualmente, com ManaLoom por tras
3. entram em backlog de migracao nativa

#### Current recommendation

- manter Lotus-first visualmente
- manter ManaLoom como observabilidade, handoff tecnico e estado
- evitar migracao visual enquanto a mesa principal continuar Lotus

#### Acceptance

- documentacao com decisao explicita
- sem ambiguidade sobre `edit cards` e card pools

## Next Concrete Tasks

### Task A - Closed

Smoke confiavel de `card search` no Android real.

#### Closed with

- `integration_test/life_counter_lotus_card_search_visual_smoke_test.dart`
- abertura do `Card Search` original do Lotus
- confirmacao explicita de que nao caiu na overlay Flutter nativa

### Task B

Refatorar a suite de testes para separar:

- fluxo Lotus-first
- backend invisivel
- fallback interno

#### Done when

- `lotus_life_counter_screen_test.dart` fica menos misturado com fluxo visual principal

### Task C

Atualizar docs principais para refletir a diretriz definitiva.

#### Files

- `README.md`
- `doc/LIFE_COUNTER_NEXT_SPRINTS_2026-03-30.md`
- este plano

#### Done when

- um novo colaborador entende em poucos minutos:
  - o que pode mexer
  - o que nao pode mexer
  - a ordem correta das proximas tasks

## Validation Checklist Per Task

Ao fechar qualquer task desta frente:

1. rodar `flutter analyze`
2. rodar os testes locais relevantes
3. rodar smoke Android se tocar fluxo visual do `WebView`
4. revisar `git status`
5. commitar com mensagem clara
6. subir para `origin/master`

## Commit Policy

Regra operacional vigente:

- task fechada => commit imediato
- commit feito => push imediato
- nao acumular varias tasks fechadas no worktree

## Current Recommendation

O proximo passo mais certo e:

1. fechar o smoke de `card search` Lotus-first
2. separar os testes de visual principal e fallback interno
3. continuar fortalecendo o backend invisivel sem mexer no visual
