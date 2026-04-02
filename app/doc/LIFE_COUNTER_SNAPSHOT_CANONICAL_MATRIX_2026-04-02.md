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
- os caminhos de runtime sem `reload` agora tambem confirmam presenca real do alvo no DOM do Lotus antes de reportar sucesso ao host
- `table state` agora tambem tem um recorte sem `reload` para `storm`, `monarch` e `initiative`; `storm` fecha so por patch no payload canonico, e `monarch/initiative` continuam com sync visual no DOM do Lotus
- `day/night` agora tambem confirma o `.day-night-switcher` antes de assumir sucesso no sync live; se o alvo nao responder, o host volta para fallback
- os handoffs embutidos de `Game Modes` agora tambem confirmam que o seletor primario, o follow-up de `edit cards` e os seletores de fechamento existem antes de reportar sucesso; seletor ausente deixa de parecer entrega bem-sucedida, e o dismiss da shell passa a carregar o status real de entrega
- `turn tracker`, `game timer` e `table state` agora tambem expõem na observabilidade se o apply fechou em `live_runtime` ou `reload_fallback`, evitando leitura ambigua dos recortes sem `reload`
- `day/night` agora tambem expõe `live_patch_eligible` e `apply_strategy`, alinhando sua leitura operacional aos outros recortes com apply live
- `dice` agora tambem expõe `apply_strategy: canonical_store_sync` e `reload_required: false` no recorte em que a shell so altera resultado canonico; com `turn tracker` ativo, isso segue restrito a mudancas que nao tocam `first player` nem o estado estrutural do tracker
- `player state` agora tambem expõe `apply_strategy: canonical_store_sync` e `reload_required: false` no recorte em que a sheet so altera dados canonicos de rolagem, reaproveitando o mesmo criterio conservador de `dice`
- `player state` agora tambem expõe `apply_strategy: canonical_store_sync` e `reload_required: false` nos recortes em que o efeito final do hub fica limitado a `player counter` oculto ou `commander damage` oculto, reaproveitando os mesmos gates de settings ja aceitos nesses dominios fora do hub
- `player state` agora tambem expõe `apply_strategy: canonical_store_sync` e `reload_required: false` no recorte em que o efeito final do hub fica limitado a `partner commander` oculto, desde que counters continuem fora do player card e a mutacao nao escape desse contrato
- os recortes ocultos desses dominios agora tambem seguem a visibilidade real configurada pelo Lotus: `commander damage` continua elegivel quando `showCommanderDamageCounters` fica desligado mesmo com `showCountersOnPlayerCard` ligado, e `player counter/partner commander` continuam elegiveis quando `showRegularCounters` fica desligado
- o hub de `player state` agora tambem tem cobertura dedicada para esses dois subcasos, provando que a heranca de `canonical_store_sync` segue coerente com as sheets diretas mesmo no estado intermediario de card ativo com counter escondido
- em `partner commander`, esse recorte agora tambem fica bloqueado quando o jogador carrega `backgroundImagePartner`, porque esse asset ainda representa reflexo visual real no Lotus
- quando o fluxo de `player state` parte de `player_option_card_presented`, o host agora tambem reseta a superficie do Lotus apos apply sem `reload`, e a observabilidade passa a expor `surface_reset_strategy`, evitando deixar takeover stale mesmo quando o estado foi aplicado de forma canonicamente segura
- quando o fluxo de `player state` parte de `player_option_card_presented` e a sheet e fechada sem apply, o evento de dismiss agora tambem expõe `surface_reset_required` e `surface_reset_strategy`, deixando explicito que o host reabre o bundle apenas para limpar a superficie takeover
- `player state` agora tambem expõe `apply_strategy: live_runtime` e `reload_required: false` no recorte em que o efeito final do hub fica limitado a um `set life` curto em um unico jogador, reaproveitando os controles reais da mesa Lotus em vez de rebootar o bundle
- `commander damage` agora tambem expõe `apply_strategy: canonical_store_sync` e `reload_required: false` no recorte em que o settings ja garante ausencia de reflexo visual na mesa, mantendo `reload` nos cenarios em que esse dominio ainda afeta vida, estado letal ou counters visiveis
- `player counter` agora tambem expõe `apply_strategy: canonical_store_sync` e `reload_required: false` no recorte em que o settings ja garante ausencia de reflexo visual na mesa, mantendo `reload` quando counters ainda aparecem no player card ou quando `poison` pode acionar `autoKill`
- o atalho direto de `set life` agora tambem expõe `apply_strategy: live_runtime` e `reload_required: false` no recorte em que a mudanca fica limitada a um delta medio de vida no jogador alvo e o runtime do Lotus confirma os controles da mesa; fora desse recorte, o dominio continua em `reload_fallback`
- `settings` agora tambem expõe `live_patch_eligible: false` e `apply_strategy: reload_fallback`, deixando visivel no log que esse dominio continua fora do live sync por seguranca
- `history` e `card search` agora tambem expõem `surface_strategy: native_fallback` quando a shell interna assume o fluxo, separando esses eventos dos dominios que realmente aplicam estado no runtime
- `history import` agora tambem expõe `transfer_strategy: clipboard_import`, `apply_strategy: canonical_store_sync` e `reload_required: false`, separando a sincronizacao canonica de `history` dos eventos que sao apenas sheet fallback
- `settings`, `day/night`, `turn tracker`, `game timer`, `dice` e `table state` agora tambem expõem `surface_strategy: native_fallback` quando a sheet interna assume o fluxo, padronizando a leitura das superfices utilitarias Lotus-first
- `commander damage`, `player appearance`, `player counter`, `player state` e `set life` agora tambem expõem `surface_strategy: native_fallback` quando a sheet interna assume o fluxo, padronizando a leitura do runtime de jogador Lotus-first
- `player appearance export/import` agora tambem expõem `transfer_strategy: clipboard_export/clipboard_import`, separando os eventos de clipboard dos eventos de apply do runtime de jogador
- `player appearance profile save/delete` agora tambem expõem `persistence_strategy: owned_profile_store`, separando a store propria de perfis ManaLoom-owned dos eventos de apply e clipboard
- `player appearance profile select` agora tambem expõe `persistence_strategy: owned_profile_store`, separando o uso de preset salvo no draft da sheet dos eventos de apply do runtime de jogador
- o fallback bootstrap do host agora tambem tem cobertura unitaria direta para `day/night`, `session/settings/timer/history`, `history-only` e `day/night-only`, provando que o payload Lotus pode ser reconstruido a partir das stores canonicas sem snapshot persistido
- o host agora tambem espelha `__manaloom_day_night_mode` do `persist_snapshot` para a `LifeCounterDayNightStateStore`, e limpa store stale quando a chave some do snapshot Lotus
- o mirror canonico do host agora tambem limpa `LifeCounterSessionStore` e `LifeCounterSettingsStore` quando o snapshot Lotus nao traz mais `players` ou `gameSettings`, evitando reopen com estado stale reidratado do nosso lado
- o mirror canonico do host agora tambem preserva `history` meta-only (`currentGameMeta` / `gameCounter`) quando o snapshot Lotus traz o dominio sem entradas, evitando limpar cedo demais uma parte que ja e canonica
- o round-trip de `history` meta-only agora tambem tem cobertura direta na store canonica e no fallback `history-only`, provando que `currentGameMeta/gameCounter` seguem reidrataveis mesmo sem `gameHistory`
- o fallback canônico agora tambem cobre explicitamente `session + history` meta-only, provando que o payload de `history` canonico continua prevalecendo sobre o bootstrap default da sessao
- `game modes` agora tambem expõem `core_scope: excluded_from_canonical_core` em open, dismiss e falha de entrega, deixando explicito que esse dominio continua fora da matriz de ownership canonico desta fase
- a shell de `history` agora tambem expõe `history_domain_present`, deixando explicito quando `currentGameMeta/gameCounter` existem mesmo sem `gameHistory` ou `allGamesHistory` com entradas
- a deduplicacao de observabilidade do `persist_snapshot` agora tambem considera `session` e `history`, evitando que uma carga parcial anterior esconda o primeiro mirror canonico desses dominios na mesma carga do Lotus
- `history` e `card search` agora tambem expõem `surface_strategy: native_fallback` quando a sheet interna e acionada; `history export` marca `transfer_strategy: clipboard_export`

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
- `game timer` ja tem um caso seguro de patch incremental sem `reload`, desde que o alvo `.game-timer` exista e responda
- `turn tracker` ja tem casos seguros de sync incremental sem `reload`, desde que a mutacao seja apenas avancar turnos para frente, fazer rewind curto limitado, ou mudar o starting player por rewind curto em `Turn 1`, mantendo a mesma configuracao estrutural e com o alvo `.turn-time-tracker` presente
- `table state` ja tem um caso seguro de sync incremental sem `reload` para `storm`, `monarch` e `initiative`; `storm` fecha por patch no payload canonico, e `monarch/initiative` continuam exigindo `.player-card` presentes e `menu-button` sincronizada para o ajuste visual no DOM do Lotus
- `day/night` continua sendo aplicado live, mas agora so fecha sem `reload` quando o `.day-night-switcher` confirma a troca
- `day/night` agora tambem e reespelhado do `persist_snapshot` Lotus para a store canonica, o que mantem o fallback `canonical -> bootstrap` coerente mesmo depois de interacoes visuais que partem do bundle
- `session` e `settings` agora tambem sao limpas do lado canonico quando o snapshot Lotus nao traz mais `players` ou `gameSettings`, evitando que o fallback `canonical -> bootstrap` ressuscite estado stale apos reset ou snapshot parcial
- `game modes` embutidos agora tambem so registram sucesso quando o seletor de abertura, o follow-up de `edit cards` ou o seletor de fechamento existe no DOM real do Lotus; o passo de card pool agora e confirmado em chamada separada, sem `setTimeout` fire-and-forget, e a telemetria de dismiss passa a indicar `action_delivered`
- `turn tracker`, `game timer` e `table state` agora tambem registram `live_patch_eligible` e `apply_strategy`, separando visualmente no log quando o estado foi aplicado live e quando caiu em `reload`
- `day/night` agora tambem registra `live_patch_eligible` e `apply_strategy`, deixando explicito quando a troca foi aplicada live e quando o host precisou recarregar o bundle
- `dice` agora tambem tem um recorte sem `reload` por `canonical_store_sync` quando a shell so altera `last rolls`, `first player` e `last event`; com `turn tracker` ativo, isso fica limitado ao subcaso em que `first player` nao muda e o tracker permanece estruturalmente igual
- `player state` agora tambem tem um recorte sem `reload` por `canonical_store_sync` quando a sheet so altera `last rolls`, `first player` quando permitido e `last event`, reaproveitando o mesmo filtro conservador de `dice`
- `commander damage` agora tambem tem um recorte sem `reload` por `canonical_store_sync` quando a shell so altera dano canonico oculto para a mesa pelo settings atual, sem mudanca de vida, sem auto-kill e sem counters visiveis no player card
- `player counter` agora tambem tem um recorte sem `reload` por `canonical_store_sync` quando a shell so altera counters canonicos ocultos para a mesa pelo settings atual, sem risco de `poison` abrir `autoKill`
- `player state` agora tambem tem um recorte sem `reload` por `canonical_store_sync` quando a shell so altera `partner commander` oculto para a mesa pelo settings atual, sem counters visiveis no player card e sem mudanca estrutural misturada
- esses recortes ocultos agora tambem respeitam os flags especificos de visibilidade do Lotus, em vez de depender apenas do toggle global `showCountersOnPlayerCard`
- no caso especifico de `partner commander`, o host agora tambem expõe fallback quando `backgroundImagePartner` esta presente, em vez de tratar esse caminho como hidden sync seguro
- no caso especifico de `player state` vindo de option-card takeover, a observabilidade agora tambem expõe `surface_reset_required`, porque o reset visual do Lotus passa a ser obrigatorio mesmo quando o apply nao exigiu `reload_fallback`
- a suite de `player values` agora tambem prova os limites desses recortes, garantindo fallback para `reload` assim que `commander damage` volta a afetar vida ou assim que `player counter` volta a ficar visivel no player card
- `commander damage` e `player counter` agora tambem expõem `sync_blockers`, deixando explicito no log qual condicao bloqueou `canonical_store_sync` nos recortes ocultos
- `dice` e `player state` agora tambem expõem `sync_blockers`, deixando explicito no log qual condicao bloqueou `canonical_store_sync` nos recortes baseados em rolagem ou no recorte oculto de `partner commander`
- `turn tracker` e `game timer` agora tambem expõem `sync_blockers`, deixando explicito no log qual condicao bloqueou `live_runtime` nos recortes seguros de runtime (`tracker/timer` inativo, mudanca estrutural do tracker ou posicao fora dos caminhos suportados)
- `day/night` e `table state` agora tambem expõem `sync_blockers`, deixando explicito no log qual `reason` do runtime Lotus bloqueou o apply live (`switcher_missing`, `player_cards_missing` e equivalentes), em vez de esconder isso sob fallback generico
- `settings` e `player appearance` continuam expondo `sync_blockers` arquiteturais conhecidos; em `set life`, os blockers agora tambem distinguem delta acima do limite live, jogador previamente inativo, vida letal sem `autoKill` e mudanca fora do contrato do jogador alvo
- os applies de `settings`, `day/night`, `turn tracker`, `game timer`, `player appearance` e `table state` agora tambem expõem `reload_required`, padronizando a leitura de fallback e sync bem-sucedido no mesmo contrato observavel dos outros dominios
- `settings` continua em `reload`, e agora isso tambem fica explicito na observabilidade de apply, alinhando o dominio com o mesmo contrato de leitura operacional
- `history` e `card search` seguem sem apply de runtime nessa shell interna; a observabilidade agora deixa explicito quando o fluxo foi apenas `native_fallback`
- `history import` continua sem apply de runtime no Lotus, mas agora o log deixa explicito quando houve sync canonico real no ManaLoom sem `reload`
- nas utility sheets, a observabilidade agora tambem deixa explicito quando a interacao ficou restrita ao suporte nativo interno, sem implicar takeover visual do Lotus
- nas sheets de runtime de jogador, a observabilidade agora tambem deixa explicito quando a interacao ficou restrita ao suporte nativo interno, sem implicar takeover visual do Lotus
- em `game modes`, a observabilidade agora tambem deixa explicito quando a interacao ficou restrita ao suporte nativo interno, com `surface_strategy: native_fallback` em open, dismiss e falha de entrega
- em `player appearance`, a observabilidade agora tambem deixa explicito quando a interacao auxiliar ficou restrita a transporte por clipboard
- em `player appearance`, a observabilidade agora tambem deixa explicito quando a interacao auxiliar ficou restrita a persistencia propria de perfis ManaLoom-owned
- em `player appearance`, a observabilidade agora tambem deixa explicito quando a interacao auxiliar ficou restrita a carregar um preset salvo no draft da sheet, sem apply real na mesa
- quando `player appearance` parte de takeover da superficie de background do Lotus e a sheet e fechada sem apply, a observabilidade agora tambem expõe `surface_reset_required` e `surface_reset_strategy`, deixando explicito que o host reabre o bundle apenas para limpar a superficie takeover
- o caminho `canonical -> bootstrap Lotus` agora tambem fica provado sem snapshot persistido, incluindo `day/night`, reduzindo a dependencia implicita de `localStorage` preexistente como requisito de reabertura
- o merge de bootstrap do host agora tambem poda chaves stale de dominios canonicos ausentes antes de reaplicar o payload no Lotus, evitando que `session/settings/timer/day-night/history` antigos ressuscitem a partir de um snapshot salvo quando o fallback canonico daquele dominio ja foi limpo
- `history` e `card search` continuam como suporte interno Lotus-first, e agora isso tambem fica explicito na observabilidade das sheets nativas

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
2. ampliar o `turn tracker` apenas se houver mais caminhos seguros pelo proprio runtime Lotus, sem patch cego de memoria interna nem esperas longas demais
3. manter `currentGameMeta/gameCounter` sincronizados com qualquer evolucao futura do contrato de `history`
