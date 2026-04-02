# Life Counter - Snapshot Canonical Matrix - 2026-04-02

## Objective

Inventariar as chaves relevantes do snapshot do Lotus e classificar cada uma como:

- `canonical source`
- `derived for Lotus`
- `legacy compatibility`
- `still Lotus-dependent`

Este documento existe para apoiar a `Wave 1` do fechamento de ownership do contador.

Documento relacionado:

- `app/doc/LIFE_COUNTER_CORE_OWNERSHIP_CLOSURE_PLAN_2026-04-02.md`

## Checkpoint after implementation

Estado registrado depois da rodada de `2026-04-02`:

- a matrix desta fase ja foi usada para abrir ownership canonico de `history`
- `LifeCounterHistoryState` e `LifeCounterHistoryStore` passam a ser o owner real do dominio
- `gameHistory`, `allGamesHistory`, `currentGameMeta` e `gameCounter` continuam existindo como payload de compatibilidade para o renderer Lotus
- o bootstrap agora tambem aceita patch incremental via `receivePatch`, mas isso ainda vale so para dominios com runtime seguro
- o `turn tracker` agora tambem tem recortes de sync incremental pelo proprio runtime do Lotus, sem depender de patch cego de storage

## Reading rule

As chaves abaixo sao lidas e escritas dentro do contexto do `localStorage` do Lotus ou da ponte de bootstrap associada ao bundle embutido.

Quando uma chave estiver marcada como:

- `canonical source`: o valor de verdade ja deve vir do ManaLoom
- `derived for Lotus`: o valor pode existir no snapshot, mas ja deve ser reconstruivel do contrato canonico
- `legacy compatibility`: ainda existe para compatibilidade com o runtime atual, mas nao deveria ser a fonte primaria
- `still Lotus-dependent`: o projeto ainda depende da semantica do Lotus para essa area

## Matrix

| Key | Domain | Current producer | Canonical owner | Classification | Notes |
| --- | --- | --- | --- | --- | --- |
| `players` | estado principal dos jogadores | Lotus runtime e host ManaLoom | `LifeCounterSession` | `derived for Lotus` | Deve ser reconstruivel da sessao canonica. Hoje ainda e alterado diretamente pelo runtime Lotus em fluxos visuais principais. |
| `playerCount` | configuracao basica da mesa | Lotus runtime e host ManaLoom | `LifeCounterSession.playerCount` | `derived for Lotus` | Ja e reconstrutivel do contrato canonico. |
| `startingLife2P` | configuracao basica da mesa | Lotus runtime e host ManaLoom | `LifeCounterSession.startingLifeTwoPlayer` | `derived for Lotus` | Ja e reconstrutivel do contrato canonico. |
| `startingLifeMP` | configuracao basica da mesa | Lotus runtime e host ManaLoom | `LifeCounterSession.startingLifeMultiPlayer` | `derived for Lotus` | Ja e reconstrutivel do contrato canonico. |
| `layoutType` | layout/rotacao interna do Lotus | Lotus runtime e host ManaLoom | nenhum contrato proprio; derivado por adapter | `still Lotus-dependent` | O app consegue reler e reaproveitar, mas ainda depende da semantica de layout do Lotus para serializacao do tracker. |
| `turnTracker` | tracker e turn timer embutido | Lotus runtime e host ManaLoom | `LifeCounterSession` + `LifeCounterTurnTrackerEngine` | `derived for Lotus` | Ja existe saneamento canonico antes da serializacao para o Lotus. |
| `gameSettings` | configuracoes visuais e de runtime | Lotus runtime e host ManaLoom | `LifeCounterSettings` | `canonical source` | O contrato tipado ja existe e o snapshot pode ser reconstruido a partir dele. |
| `gameTimerState` | timer principal | Lotus runtime e host ManaLoom | `LifeCounterGameTimerState` | `canonical source` | O contrato tipado ja existe e o adapter reconstrui a chave do Lotus. |
| `__manaloom_player_special_states` | estados especiais do jogador | host ManaLoom | `LifeCounterSession.playerSpecialStates` | `canonical source` | Chave de suporte nossa, nao uma dependencia original do Lotus. |
| `__manaloom_player_appearances` | aparencia e nickname | host ManaLoom | `LifeCounterSession.playerAppearances` | `canonical source` | Chave de suporte nossa, reconstruivel da sessao canonica. |
| `__manaloom_table_state` | storm, monarch, initiative, rolls e first player auxiliar | host ManaLoom | campos de mesa em `LifeCounterSession` | `canonical source` | Chave suplementar nossa para preservar estado que o Lotus nao expressa bem sozinho. |
| `__manaloom_day_night_mode` | preferencia day/night | host ManaLoom | `LifeCounterDayNightState` | `canonical source` | Hoje ja vive em store propria e e reaplicado ao bundle. |
| `gameHistory` | historico da partida atual | host ManaLoom e renderer Lotus | `LifeCounterHistoryState` | `derived for Lotus` | O valor vivo agora sai do contrato canonico e e serializado para o formato legado so por compatibilidade visual. |
| `allGamesHistory` | historico arquivado | host ManaLoom e renderer Lotus | `LifeCounterHistoryState` | `derived for Lotus` | O historico arquivado agora e reconstruido do store canonico antes de voltar ao Lotus. |
| `currentGameMeta` | metadata da partida atual | host ManaLoom e bootstrap adapter | `LifeCounterHistoryState` | `derived for Lotus` | Agora fica persistido no contrato canonico de `history` e volta ao Lotus so como payload de compatibilidade visual. |
| `gameCounter` | contador de partidas | host ManaLoom e bootstrap adapter | `LifeCounterHistoryState` | `derived for Lotus` | Agora fica persistido no contrato canonico de `history` em vez de depender de valor implicito do bootstrap. |
| `turnTrackerHintOverlay_v1` | hint de onboarding do Lotus | shell policy | nenhum | `legacy compatibility` | Nao e parte do core do jogo; so controla supressao de hint. |
| `countersOnPlayerCardHintOverlay_v1` | hint de onboarding do Lotus | shell policy | nenhum | `legacy compatibility` | Nao e parte do core do jogo; so controla supressao de hint. |

## Per-domain reading

### Strongly canonical today

Dominios que ja podem ser tratados como nossos:

- settings
- game timer
- special states
- player appearances
- table state suplementar
- day/night
- grande parte da sessao principal dos jogadores
- grande parte do tracker

Arquivos centrais:

- `life_counter_session.dart`
- `life_counter_settings.dart`
- `life_counter_game_timer_state.dart`
- `lotus_life_counter_session_adapter.dart`
- `lotus_life_counter_settings_adapter.dart`
- `lotus_life_counter_game_timer_adapter.dart`

### Canonical but still mirrored through Lotus-shaped payloads

Dominios que ja tem dono canonico, mas ainda sao empacotados no formato do Lotus:

- `players`
- `playerCount`
- `startingLife2P`
- `startingLifeMP`
- `turnTracker`

Leitura:

- a verdade ja esta bem encaminhada para nosso lado
- ainda falta reduzir dependencia de serializacao Lotus-shaped para aplicacao em runtime

### Still open for ownership closure

Dominios que ainda bloqueiam a frase `core 100% nosso` sem ressalva:

- `currentGameMeta`
- `layoutType`

Leitura:

- `history` ja saiu desta lista como owner canonico
- `currentGameMeta/gameCounter` agora ja vivem no contrato canonico de `history`
- `layoutType` ainda depende da semantica do bundle Lotus

## Current write paths

Hoje os writes importantes acontecem em tres familias:

### 1. Bootstrap and mirror

- `flutter_bootstrap.js` pede `request_bootstrap` e persiste `persist_snapshot`
- `lotus_host_controller.dart` salva snapshot bruto e deriva contratos canonicos

Leitura:

- o host ja participa do ciclo de verdade
- mas ainda aceita Lotus como escritor inicial em varios casos

### 2. Canonical native apply paths

Em `lotus_life_counter_screen.dart`, varios fluxos nativos:

- salvam store canonica
- regeneram chaves do snapshot
- recarregam o bundle Lotus

Leitura:

- isso prova ownership parcial forte
- isso ainda nao e o estado final de renderer puro

Complemento desta rodada:

- `history` agora passa primeiro pelo store canonico antes de qualquer serializacao Lotus
- `game timer` ja tem um caso seguro de patch incremental sem `reload`
- `turn tracker` ja tem casos seguros de sync incremental sem `reload`, desde que a mutacao seja apenas avancar turnos para frente ou voltar um unico passo mantendo a mesma configuracao estrutural

### 3. Runtime Lotus-first visual paths

A policy atual evita sequestrar o visual principal do Lotus.

Leitura:

- boa decisao de produto para preservar UX
- ao mesmo tempo, isso significa que o Lotus ainda e escritor de estado em parte do caminho vivo

## Closure criteria for this matrix

Esta matrix fica considerada suficiente para a `Wave 1` quando:

1. cada chave relevante do snapshot tem classificacao clara
2. os dominios ainda abertos ficam explicitamente nomeados
3. o time consegue olhar para uma mutacao do contador e responder:
   - de onde vem a verdade
   - para onde ela e persistida
   - o que ainda e apenas compatibilidade do Lotus

## Immediate next recommendation

Com esta matriz pronta, a proxima task mais correta e:

1. continuar o mapeamento conservador de dominios com `safe live patch`
2. ampliar o `turn tracker` apenas se houver mais caminhos seguros pelo proprio runtime Lotus, sem patch cego de memoria interna
3. manter `currentGameMeta/gameCounter` sincronizados com qualquer evolucao futura do contrato de `history`
