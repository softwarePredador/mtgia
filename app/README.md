# App Flutter — ManaLoom

Aplicativo Flutter do ManaLoom.

## Papel do app hoje

O app deve preservar a jornada principal do produto:

1. onboarding com contexto correto
2. gerar ou importar deck
3. abrir details
4. otimizar ou reconstruir
5. aplicar e validar

## Fonte de verdade

Antes de mudar fluxo, prioridade ou UX do app, consultar:

1. [../docs/CONTEXTO_PRODUTO_ATUAL.md](../docs/CONTEXTO_PRODUTO_ATUAL.md)
2. [../docs/README.md](../docs/README.md)
3. [test/README.md](test/README.md)

Os documentos em `app/doc/` continuam úteis como apoio, mas hoje são complementares ao contexto operacional do repositório.

Documento complementar importante para a frente do contador:

- `app/doc/LIFE_COUNTER_LOTUS_MIGRATION_PLAN_2026-03-29.md`
- `app/doc/LIFE_COUNTER_LOTUS_HOST_SMOKE_CHECKLIST_2026-03-29.md`
- `app/doc/LIFE_COUNTER_LOTUS_BRANDING_AUDIT_2026-03-29.md`
- `app/doc/LIFE_COUNTER_LOTUS_SHELL_POLICY_2026-03-29.md`
- `app/doc/LIFE_COUNTER_LOTUS_SHELL_OWNED_AFFORDANCES_2026-03-29.md`
- `app/doc/LIFE_COUNTER_LOTUS_STATIC_SHELL_REPLACEMENT_2026-03-29.md`
- `app/doc/LIFE_COUNTER_LOTUS_GAMEPLAY_COPY_AUDIT_2026-03-29.md`
- `app/doc/LIFE_COUNTER_SPRINT_2026-03-30.md`
- `app/doc/LIFE_COUNTER_NEXT_SPRINTS_2026-03-30.md`
- `app/doc/LIFE_COUNTER_CORE_OWNERSHIP_CLOSURE_PLAN_2026-04-02.md`
- `app/doc/LIFE_COUNTER_SNAPSHOT_CANONICAL_MATRIX_2026-04-02.md`
- `app/doc/LIFE_COUNTER_WEBVIEW_EXECUTION_PLAN_2026-04-02.md`
- `app/doc/LIFE_COUNTER_NATIVE_SHEETS_REVIEW_2026-04-02.md`
- `app/doc/LIFE_COUNTER_NATIVE_FALLBACK_AUDIT_2026-04-03.md`
- `app/doc/LIFE_COUNTER_OWNERSHIP_BRIDGE_STATUS_2026-04-03.md`
- `app/doc/LIFE_COUNTER_FINAL_VALIDATION_2026-04-02.md`

Estado vivo do contador hoje:

- diretriz atual: o `WebView` do Lotus e a camada visual oficial da mesa; ManaLoom fica com backend, persistencia, normalizacao e customizacao futura por cima do proprio Lotus
- mudanca visual sem pedido explicito deve preservar o Lotus 1:1
- decisao arquitetural fechada: o `WebView` nao sera removido como meta ativa enquanto a prioridade for manter ou superar a qualidade visual do Lotus
- customizacao futura deve priorizar edicao do proprio Lotus no `WebView` (`css`, `js`, assets e injecao controlada pelo host), nao reimplementacao do board em Flutter puro
- runtime source-of-truth: `app/assets/lotus/`
- implementacao oficial: `app/lib/features/home/lotus_life_counter_screen.dart`
- rota viva: `app/lib/features/home/life_counter_route.dart`
- contrato proprio de sessao/persistencia: `app/lib/features/home/life_counter/`
- engine canonica inicial da mesa: `app/lib/features/home/life_counter/life_counter_tabletop_engine.dart`
- catalogo proprio de settings por secao/campo: `app/lib/features/home/life_counter/life_counter_settings_catalog.dart`
- surfaces nativas ainda existentes em codigo: `app/lib/features/home/life_counter/life_counter_native_settings_sheet.dart`, `app/lib/features/home/life_counter/life_counter_native_history_sheet.dart`, `app/lib/features/home/life_counter/life_counter_native_card_search_sheet.dart`, `app/lib/features/home/life_counter/life_counter_native_turn_tracker_sheet.dart`, `app/lib/features/home/life_counter/life_counter_native_game_timer_sheet.dart`, `app/lib/features/home/life_counter/life_counter_native_dice_sheet.dart`, `app/lib/features/home/life_counter/life_counter_native_table_state_sheet.dart` e `app/lib/features/home/life_counter/life_counter_native_day_night_sheet.dart`
- fluxo visual principal ja devolvido ao Lotus para:
  - `settings`
  - `history`
  - `card search`
- pacote prioritario de reversao visual ja aplicado para:
  - `dice`
  - `turn tracker`
  - `game timer / clock`
  - `table state`
  - `day / night`
- shell nativa atual de game modes: `app/lib/features/home/life_counter/life_counter_native_game_modes_sheet.dart`
- `Planechase`, `Archenemy` e `Bounty` agora seguem Lotus como fluxo visual principal
- a shell nativa de `game modes` continua existindo em codigo apenas como apoio de backend, observabilidade e fluxos internos
- decisao final de `Game Modes`: `Planechase`, `Archenemy` e `Bounty` entram no produto final como fluxos Lotus-first visuais, com ManaLoom sustentando handoff tecnico, observabilidade e persistencia quando necessario
- os handoffs embutidos de `game modes` agora so contam como entregues quando o seletor alvo existe no DOM real do Lotus, inclusive no segundo passo de `edit cards`; seletor ausente vira falha observavel, e o dismiss da shell passa a carregar `action_delivered`
- `game modes` agora tambem expõe `core_scope: excluded_from_canonical_core` em open, dismiss e falha de entrega, deixando explicito no proprio runtime observavel que esse dominio fica fora do fechamento do core canonico desta fase
- a shell de `game modes` agora tambem expõe `surface_strategy: native_fallback` em open, dismiss e falha de entrega, alinhando essa superficie Lotus-first ao mesmo contrato observavel das outras sheets internas
- `edit cards` e card pools permanecem embutidos no runtime Lotus como parte suportada do produto final, sem migracao visual para Flutter nesta fase
- `turn tracker`, `game timer` e `table state` agora tambem registram `live_patch_eligible` e `apply_strategy`, deixando explicito na observabilidade quando o apply fechou por runtime live ou por `reload`
- `day/night` agora tambem registra `live_patch_eligible` e `apply_strategy`, alinhando sua trilha de apply/fallback ao mesmo contrato observavel
- `dice` agora tambem tem um recorte sem `reload` por `canonical_store_sync` quando a shell so altera resultado canonico de rolagem; com `turn tracker` ativo, isso continua limitado aos casos em que `first player` e a estrutura do tracker permanecem intactos
- `player state` agora tambem tem um recorte sem `reload` por `canonical_store_sync` quando a sheet so altera dados canonicos de rolagem, reaproveitando o mesmo criterio conservador de `dice`
- `player state` agora tambem herda `canonical_store_sync` sem `reload` quando o efeito final do hub fica limitado a `player counter` oculto ou `commander damage` oculto, reaproveitando os mesmos gates de settings desses dominios
- `player state` agora tambem herda `canonical_store_sync` sem `reload` quando o efeito final do hub fica limitado a `partner commander` oculto, desde que counters continuem fora do player card e a mutacao nao escape desse contrato
- os recortes ocultos de `commander damage`, `player counter` e `partner commander` agora tambem respeitam os flags especificos de visibilidade do Lotus: `showCommanderDamageCounters` para dano de comandante e `showRegularCounters` para counters regulares, mesmo quando `showCountersOnPlayerCard` continua ligado
- o hub de `player state` agora tambem tem cobertura dedicada para esses mesmos subcasos, garantindo que a heranca de `canonical_store_sync` continua coerente quando o player card segue ativo mas o counter especifico permanece escondido
- em `partner commander`, esse recorte agora tambem volta para `reload_fallback` quando existe `backgroundImagePartner` no payload do jogador, porque esse asset ainda pode alterar a superficie visual do Lotus
- quando `player state` nasce de takeover do option-card do Lotus, o host agora tambem reseta a superficie do board apos apply sem `reload`, e a observabilidade passa a expor `surface_reset_strategy`, evitando deixar o overlay visual stale mesmo quando a mutacao fechou por `canonical_store_sync` ou `live_runtime`
- quando `player state` nasce de takeover do option-card do Lotus e a sheet e fechada sem apply, o evento de dismiss agora tambem expõe `surface_reset_required` e `surface_reset_strategy`, deixando explicito o reset do bundle usado so para limpar a superficie takeover
- `player state` agora tambem tem um recorte sem `reload` por `live_runtime` quando o efeito final do hub fica limitado a um `set life` curto em um unico jogador, reaproveitando os controles reais do Lotus
- `player appearance` agora tambem tem um recorte sem `reload` por `live_runtime` quando a mutacao fica limitada ao background solido de um unico jogador; nickname e imagens continuam em `reload_fallback`
- `player state` agora tambem herda `live_runtime` quando o efeito final do hub fica limitado a esse mesmo recorte seguro de `player appearance` com background solido de um unico jogador
- `commander damage` agora tambem tem um recorte sem `reload` por `canonical_store_sync` quando o settings ja garante que esse dano fica invisivel na mesa e sem efeito colateral de vida ou auto-kill
- `player counter` agora tambem tem um recorte sem `reload` por `canonical_store_sync` quando o settings ja garante que counters ficam invisiveis na mesa e `poison` nao pode acionar `autoKill`
- o atalho direto de `set life` agora tambem tem um recorte sem `reload` por `live_runtime` quando a mudanca fica limitada a um delta medio de vida no jogador alvo e o runtime real do Lotus confirma os controles da mesa
- `settings` continua `reload-only` por seguranca do bundle Lotus, e agora tambem anota isso explicitamente na observabilidade de apply com `live_patch_eligible: false` e `apply_strategy: reload_fallback`
- os applies de `settings`, `day/night`, `turn tracker`, `game timer`, `player appearance` e `table state` agora tambem expõem `reload_required`, alinhando toda a trilha observavel de apply ao mesmo contrato usado no restante do contador
- `history` e `card search` continuam Lotus-first visuais, e as sheets internas agora anotam explicitamente `surface_strategy: native_fallback`; `history export` tambem anota `transfer_strategy: clipboard_export`
- `history import` agora tambem anota `transfer_strategy: clipboard_import`, `apply_strategy: canonical_store_sync` e `reload_required: false`, deixando explicito que a troca real acontece no estado canonico sem rebootar o bundle
- a telemetria da shell de `history` agora tambem expõe `history_domain_present`, evitando colapsar `currentGameMeta/gameCounter` em simples ausencia de eventos quando o dominio continua presente
- `history transfer` agora tambem carrega `currentGameMeta` e `gameCounter`, evitando perder `meta-only history` ao exportar/importar por clipboard
- `history transfer` agora tambem carrega `archivedGameCount`, evitando achatar historico importado para `0/1` jogos arquivados no round-trip por clipboard
- a deteccao de `history_domain_present` agora tambem parte do proprio dominio `LifeCounterHistoryState`, evitando drift entre host, shell e snapshot matrix
- `settings`, `day/night`, `turn tracker`, `game timer`, `dice` e `table state` agora tambem anotam `surface_strategy: native_fallback` na abertura da sheet interna, deixando explicito que essas superfices utilitarias continuam suporte nativo ao fluxo Lotus-first
- `commander damage`, `player appearance`, `player counter`, `player state` e `set life` agora tambem anotam `surface_strategy: native_fallback` na abertura da sheet interna, deixando explicito que o runtime de jogador continua suporte nativo ao fluxo Lotus-first
- os fluxos `open-native-*` agora tambem expõem `fallback_classification`, separando `ownership_bridge`, `support_utility` e `excluded_core_support` sem depender de leitura implícita por tipo de sheet
- a propria entrada da shell agora tambem registra `native_fallback_surface_requested` para cada `open-native-*`, com tipo, source e classificacao, fechando a auditoria do fallback antes mesmo da sheet abrir
- esse evento de borda agora tambem expõe `domain_key` e `review_status`, transformando a revisao dos fallbacks internos numa regra viva da shell em vez de uma leitura espalhada pelo codigo
- os defaults de `source` para cada `open-native-*` agora tambem saem do mesmo inventario da shell, evitando drift entre a auditoria de borda e a abertura real da sheet
- esse mesmo inventario agora tambem deixa explicito quando a shell usou `used_default_source`, separando chamadas que vieram com `source` real do Lotus das que dependeram do fallback interno do host
- a borda da shell agora tambem expõe `native_fallback_surface_rejected`, evitando que `open-native-*` desconhecido ou payload invalido morra em silencio
- a borda da shell agora tambem rejeita explicitamente superfices nativas de jogador sem `targetPlayerIndex`, evitando que a sheet abra com alvo implicito e esconda erro de payload do Lotus
- `player appearance export/import` agora tambem anotam `surface_strategy: native_fallback` e `transfer_strategy: clipboard_export/clipboard_import`, deixando explicito quando o fluxo auxiliar usa clipboard
- `player appearance profile save/delete` agora tambem anotam `surface_strategy: native_fallback` e `persistence_strategy: owned_profile_store`, deixando explicito quando o fluxo auxiliar usa a store propria de perfis do ManaLoom
- `player appearance profile select` agora tambem anota `surface_strategy: native_fallback` e `persistence_strategy: owned_profile_store`, deixando explicito quando a sheet apenas carrega um preset salvo no draft local
- quando `player appearance` nasce de takeover da superficie de background do Lotus e a sheet e fechada sem apply, a observabilidade agora tambem expõe `surface_reset_required` e `surface_reset_strategy`, deixando explicito o reset do bundle usado so para limpar a superficie takeover
- o host agora tambem tem cobertura unitaria para o fallback `canonical -> bootstrap Lotus` sem snapshot persistido, incluindo `day/night`, `session`, `settings`, `timer`, `history`, `history-only` e `day/night-only`
- o host agora tambem espelha `day/night` do `persist_snapshot` Lotus para a store canonica, e limpa estado stale quando `__manaloom_day_night_mode` some do snapshot
- o mirror canonico do host agora tambem limpa `session` e `settings` stale quando o snapshot Lotus deixa de trazer `players` ou `gameSettings`, evitando reopen com estado antigo reidratado do nosso lado
- o mirror canonico do host agora tambem preserva `history` meta-only (`currentGameMeta` / `gameCounter`) quando o snapshot Lotus traz o dominio sem entradas, evitando perder esse estado canonico logo no primeiro espelhamento
- o round-trip de `history` meta-only agora tambem tem cobertura direta na store canonica e no fallback `history-only -> bootstrap Lotus`, provando que `currentGameMeta/gameCounter` sobrevivem mesmo sem eventos
- o fallback canônico do host agora tambem tem prova direta para `session + history` meta-only, garantindo que uma mesa canônica ativa não sobrescreve `currentGameMeta/gameCounter` com os defaults do bootstrap
- a deduplicacao de observabilidade do `persist_snapshot` no host agora tambem considera `session` e `history`, evitando que uma carga parcial anterior esconda o primeiro mirror canonico desses dominios na mesma carga do Lotus
- o merge de bootstrap do host agora tambem poda chaves stale de `session`, `settings`, `game timer`, `day/night` e `history` quando o fallback canonico daquele dominio nao existe mais, evitando que um snapshot Lotus salvo ressuscite estado antigo no reopen
- o host agora tambem tem prova direta de reopen com snapshot Lotus salvo parcial e stale, garantindo que o merge do bootstrap preserva flags auxiliares fora do core, mas reidrata `session`, `settings`, `game timer`, `day/night` e `history` a partir do estado canonico
- o host agora tambem tem prova direta do round-trip `persist_snapshot Lotus -> stores canonicas -> fallback bootstrap`, garantindo que um snapshot valido consegue ser espelhado e reaberto sem depender do `localStorage` original
- validacao final de produto registrada em `app/doc/LIFE_COUNTER_FINAL_VALIDATION_2026-04-02.md`
- definicao operacional de encerramento atual:
  - visual oficial: Lotus no `WebView`
  - backend oficial: ManaLoom
  - nenhuma remocao ativa do `WebView`
- shells nativas atuais de runtime de jogador: `app/lib/features/home/life_counter/life_counter_native_commander_damage_sheet.dart`, `app/lib/features/home/life_counter/life_counter_native_player_appearance_sheet.dart`, `app/lib/features/home/life_counter/life_counter_native_player_counter_sheet.dart`, `app/lib/features/home/life_counter/life_counter_native_player_state_sheet.dart` e `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart`
- reboot do tracker e reabertura do snapshot persistido ja validados em `integration_test/life_counter_reopen_snapshot_smoke_test.dart`
- contrato canonico inicial do game timer: `app/lib/features/home/life_counter/life_counter_game_timer_state*.dart`
- engine propria do game timer: `app/lib/features/home/life_counter/life_counter_game_timer_engine.dart`
- contrato proprio de import/export de history: `app/lib/features/home/life_counter/life_counter_history_transfer.dart`
- store canonica de `history`: `app/lib/features/home/life_counter/life_counter_history_store.dart`
- `currentGameMeta` e `gameCounter` agora tambem ficam no contrato canonico de `history`, nao so no payload legado do Lotus
- snapshot proprio do `localStorage` do Lotus: `app/lib/features/home/lotus/lotus_storage_snapshot*.dart`
- adapter do snapshot vivo para sessao canonica: `app/lib/features/home/lotus/lotus_life_counter_session_adapter.dart`
- adapter do `gameSettings` vivo para configuracao canonica: `app/lib/features/home/lotus/lotus_life_counter_settings_adapter.dart`
- adapter do `gameTimerState` vivo para contrato canonico: `app/lib/features/home/lotus/lotus_life_counter_game_timer_adapter.dart`
- o contrato canonico de sessao agora preserva:
  - split real de commander damage
  - split real de commander tax
  - storm/monarch/initiative
  - custom counters por jogador
- smokes reais atuais de runtime de jogador:
  - `integration_test/life_counter_commander_damage_roundtrip_smoke_test.dart`
  - `integration_test/life_counter_table_state_roundtrip_smoke_test.dart`
  - `integration_test/life_counter_commander_cast_roundtrip_smoke_test.dart`
  - `integration_test/life_counter_extra_counters_roundtrip_smoke_test.dart`
  - `integration_test/life_counter_native_commander_damage_smoke_test.dart`
  - `integration_test/life_counter_native_player_counter_smoke_test.dart`
  - `integration_test/life_counter_native_player_state_smoke_test.dart`
- o fluxo visual principal do runtime de jogador agora tambem deve permanecer Lotus-first:
  - `player state`
  - `set life`
  - `player counters`
  - `commander damage`
  - `player appearance`
- transporte proprio atual de aparencia do jogador:
  - `app/lib/features/home/life_counter/life_counter_player_appearance_transfer.dart`
  - export/import de perfil de aparencia via clipboard pela shell nativa
  - perfis salvos de aparencia em `app/lib/features/home/life_counter/life_counter_player_appearance_profile_store.dart`
- o espelho local em `app/android/app/src/main/assets/lotus/` nao e contrato ativo de runtime
- `Sprint 3` de `timer + clock` esta fechado
- `Sprint 4` esta em andamento, focado em `commander damage`, counters e runtime de jogador
- `Player State` agora funciona como hub ManaLoom para `counters`, `commander damage` e `player appearance`
- `Player State` agora tambem oferece `Roll D20` por jogador sem depender do menu auxiliar do Lotus
- `Player State` agora tambem oferece `Set Life` sem depender so do gesto original do Lotus
- `Player State` agora tambem aplica transicoes canonicas de jogador como `Knock Out`, `Decked Out`, `Left Table` e `Revive` pela engine da mesa
- `__manaloom_table_state` agora preserva tambem `lastPlayerRolls`, `lastHighRolls` e `firstPlayerIndex` auxiliar
- a shell nativa de `Table State` agora controla `storm`, `monarch` e `initiative` sem mexer no layout central da mesa
- `set life`, `player counters`, `player state` e `table state` agora compartilham uma engine canonica inicial da mesa, reduzindo regra espalhada entre shells
- `commander damage` agora tambem compartilha essa engine canonica inicial da mesa para leitura e escrita do split `commander1/commander2`
- o resumo letal e a deteccao de fonte letal de `commander damage` agora tambem saem da UI e passam pela engine canonica da mesa
- a shell nativa de `Set Life` agora tambem usa essa engine para ajustes rapidos de dano/cura sem depender do runtime implicito do Lotus
- `autoKill` agora tambem entra no fluxo nativo de `set life`, `player counters` e `commander damage`, reduzindo mais a dependencia do comportamento implicito do bundle
- a engine canonica da mesa agora tambem concentra sinais criticos de counters, como `poison lethal` e `critical commander tax`
- a engine canonica da mesa agora tambem concentra o status atual do jogador, incluindo letalidade por vida/poison/commander damage e estados especiais como `decked out` e `left table`
- o hub nativo de `player counters` agora tambem reflete esse status canonico do jogador, em vez de mostrar apenas o valor do counter selecionado
- a shell nativa de `set life` agora tambem reflete o status canonico do jogador em tempo real enquanto o valor eh editado
- a shell nativa de `commander damage` agora tambem reflete o status canonico do alvo em tempo real, antes do apply
- o status canonico do jogador agora tambem vive em uma estrutura unica da `LifeCounterTabletopEngine`, em vez de cada shell montar `label` e `description` por conta propria
- a engine canonica da mesa agora tambem expõe um `player board summary` unico, reunindo status, sinais criticos e resumo letal de commander damage para as shells nativas
- `Player State` agora tambem respeita `autoKill` quando `Set Life`, `Player Counter` ou `Commander Damage` voltam pelo hub, sem sobrescrever estados especiais manuais
- o host do contador vivo agora tambem consolida a aplicacao de sessoes nativas por um caminho unico de normalizacao e persistencia, reduzindo drift entre `set life`, `player counters`, `player state` e `commander damage`
- a `LifeCounterTabletopEngine` agora tambem concentra esse pipeline de normalizacao de board em um metodo unico, reduzindo dependencia da ordem de saneamento no host
- `turn tracker` e `table state` agora tambem usam a mesma nocao canonica de jogador ativo da `LifeCounterTabletopEngine`, em vez de checagens locais mais fracas
- a propria `LifeCounterTabletopEngine` agora tambem recusa `monarch` e `initiative` para jogadores fora da mesa, nao so a shell de `table state`
- `high roll` e `roll 1st` agora tambem respeitam apenas jogadores ativos, reduzindo mais um ponto de dependencia do comportamento implicito do Lotus
- a aplicacao de `dice` no host agora tambem passa pelo mesmo caminho central de normalizacao e persistencia usado pelas outras shells nativas
- o snapshot vivo agora tambem atualiza `turnTracker` pelo mesmo funil canonico de persistencia, evitando drift entre sessao ajustada e bundle recarregado
- o adapter do snapshot agora tambem serializa `turnTracker` usando a mesma nocao canonica de jogador ativo da engine da mesa
- a apresentacao de `special state` do jogador agora tambem sai da `LifeCounterNativePlayerStateSheet` e passa a ser definida pela `LifeCounterTabletopEngine`
- quando um jogador sai da mesa por estado letal, a engine canonica agora tambem saneia `monarch` e `initiative`, evitando ownership preso em jogador fora do jogo
- quando um jogador sai da mesa por estado letal, a camada canonica agora tambem realinha `currentTurnPlayerIndex` e `firstPlayerIndex`, evitando tracker preso em jogador fora do jogo
- quando nao sobra nenhum jogador ativo, o tracker canonico agora limpa os ponteiros em vez de manter referencia a jogador fora da mesa
- o `menu-button` voltou ao overlay radial original do Lotus
- `settings`, `history` e `card search` tambem voltaram ao visual original do Lotus
- `dice`, `turn tracker`, `game timer / clock`, `table state` e `day / night` tambem voltaram ao fluxo visual original do Lotus
- `player state`, `set life`, `player counters`, `commander damage` e `player appearance` tambem voltaram ao fluxo visual original do Lotus
- o estado de `day/night` agora fica em store propria e eh reaplicado no bundle via `__manaloom_day_night_mode`
- os hints legados de `turn tracker` e `counters on card` agora sao marcados como concluídos e suprimidos pela shell policy
- o toque no total de vida do jogador pode abrir a shell nativa de `Set Life`
- smoke novo preparado para o caminho vivo `Player State -> Set Life`: `integration_test/life_counter_native_player_state_set_life_hub_smoke_test.dart`
- plano operacional atual da frente Lotus-first: `app/doc/LIFE_COUNTER_WEBVIEW_EXECUTION_PLAN_2026-04-02.md`
- smoke Android Lotus-first de `menu + history`: `integration_test/life_counter_lotus_visual_overlays_smoke_test.dart`
- smoke Android Lotus-first de `card search`: `integration_test/life_counter_lotus_card_search_visual_smoke_test.dart`
- smoke Android de suporte interno para `Game Modes -> Settings`: `integration_test/life_counter_native_game_modes_settings_smoke_test.dart`
- suite de fallback interno do host/shell: `test/features/home/lotus_life_counter_internal_shell_test.dart`
- suite de fallback interno para `day night` e `game modes`: `test/features/home/lotus_life_counter_internal_actions_test.dart`
- suite de fallback interno para `turn tracker`, `game timer / clock` e `dice`: `test/features/home/lotus_life_counter_internal_runtime_test.dart`
- `game timer` agora ja evita `reload` nos casos seguros `active -> active` e `inactive -> active`, usando patch incremental do runtime Lotus, mas so quando o alvo `.game-timer` esta presente no DOM real
- `turn tracker` agora tambem evita `reload` nos casos seguros de avancar turnos para frente, fazer rewind curto limitado e mudar o starting player por rewind curto em `Turn 1`, com tracker ja ativo, dirigindo o proprio runtime do Lotus, mas so quando o alvo `.turn-time-tracker` esta presente no DOM real
- `table state` agora tambem evita `reload` para `storm`, `monarch` e `initiative`; `storm` fecha por patch no payload canonico, e `monarch/initiative` continuam reaplicando ou limpando moedas, ownership visual e estado da `menu-button` direto no DOM do Lotus
- `day/night` continua live no Lotus, mas agora so fecha sem fallback quando o `.day-night-switcher` confirma a troca; se nao confirmar, o host recarrega o bundle
- `game modes` embutidos agora tambem so registram sucesso quando o seletor de abertura, o follow-up de `edit cards` ou o seletor de fechamento existe no DOM real do Lotus; o passo de card pool saiu do `setTimeout` fire-and-forget e passou a ser confirmado em chamada separada, com `native_game_modes_action_failed` e `action_delivered` evitando telemetria ambigua
- `turn tracker`, `game timer` e `table state` agora tambem anotam `apply_strategy` (`live_runtime` vs `reload_fallback`) e `live_patch_eligible` nos eventos de apply
- `day/night` agora tambem anota `apply_strategy` (`live_runtime` vs `reload_fallback`) e `live_patch_eligible` no evento de apply
- `dice` agora tambem anota `apply_strategy: canonical_store_sync`, `reload_required: false` e `live_patch_eligible: false` no recorte em que so muda resultado canonico; com `turn tracker` ativo, isso continua restrito aos casos em que `first player` e a estrutura do tracker nao mudam
- `player state` agora tambem anota `apply_strategy: canonical_store_sync`, `reload_required: false` e `live_patch_eligible: false` no recorte em que a sheet so muda dados canonicos de rolagem
- `commander damage` agora tambem anota `apply_strategy: canonical_store_sync`, `reload_required: false` e `live_patch_eligible: false` no recorte em que o settings atual ja garante ausencia de reflexo visual na mesa
- `player counter` agora tambem anota `apply_strategy: canonical_store_sync`, `reload_required: false` e `live_patch_eligible: false` no recorte em que o settings atual ja garante ausencia de reflexo visual na mesa e `poison` nao pode acionar `autoKill`
- a suite de `player values` agora tambem prova explicitamente os limites desses recortes, garantindo `reload_fallback` quando `commander damage` volta a afetar vida ou quando `player counter` volta a ficar visivel na mesa
- `commander damage` e `player counter` agora tambem anotam `sync_blockers`, deixando explicito na observabilidade por que um recorte oculto caiu em `reload_fallback`
- `dice` e `player state` agora tambem anotam `sync_blockers`, deixando explicito na observabilidade por que um recorte baseado em rolagem caiu em `reload_fallback`
- no recorte oculto de `partner commander`, `player state` agora tambem anota `sync_blockers`, deixando explicito quando o fallback veio de counters ainda visiveis na mesa ou de mutacao misturada fora desse contrato
- `turn tracker` e `game timer` agora tambem anotam `sync_blockers`, deixando explicito na observabilidade por que um apply caiu em `reload_fallback` mesmo dentro da familia de live sync
- `day/night` e `table state` agora tambem anotam `sync_blockers` com o `reason` real devolvido pelo runtime do Lotus, deixando explicito quando o fallback veio de falha concreta de DOM/runtime e nao de bloqueio arquitetural previo
- `settings` e `player appearance` continuam anotando `sync_blockers` puramente arquiteturais; em `set life`, os blockers agora tambem deixam explicito quando o fallback veio de delta acima do limite live, jogador previamente inativo, vida letal sem `autoKill` ou mudanca fora do contrato do jogador alvo
- `settings` agora tambem anota `apply_strategy: reload_fallback` e `live_patch_eligible: false`, deixando explicito no log que esse dominio continua dependente de rehydrate completo
- `history` e `card search` agora tambem anotam `surface_strategy: native_fallback` nos eventos da sheet interna, deixando explicito no log que esses atalhos sao suporte nativo e nao takeover visual principal
- `history import` agora tambem anota `transfer_strategy: clipboard_import`, `apply_strategy: canonical_store_sync` e `reload_required: false`, deixando explicito no log que esse fluxo faz sync canonico sem apply live no Lotus
- `settings`, `day/night`, `turn tracker`, `game timer`, `dice` e `table state` agora tambem anotam `surface_strategy: native_fallback` nos eventos de open/dismiss da sheet interna, padronizando a leitura de suporte tecnico Lotus-first
- `commander damage`, `player appearance`, `player counter`, `player state` e `set life` agora tambem anotam `surface_strategy: native_fallback` nos eventos de open/dismiss da sheet interna, padronizando a leitura de suporte tecnico Lotus-first no runtime de jogador
- `player appearance export/import` agora tambem anotam `transfer_strategy: clipboard_export/clipboard_import`, separando os eventos auxiliares de clipboard dos eventos de apply do runtime de jogador
- `player appearance profile save/delete` agora tambem anotam `persistence_strategy: owned_profile_store`, separando a persistencia de perfis ManaLoom-owned dos eventos de apply do runtime de jogador
- `player appearance profile select` agora tambem anota `persistence_strategy: owned_profile_store`, separando o uso de preset salvo no draft da sheet dos eventos de apply do runtime de jogador
- o caminho `storage_bootstrap_restored_from_canonical` agora tambem tem prova unitaria dedicada em `test/features/home/lotus_host_controller_bootstrap_test.dart`, incluindo `day/night`
- suite de fallback interno para `player appearance`: `test/features/home/lotus_life_counter_internal_player_appearance_test.dart`
- suite de fallback interno para `commander damage` e `player counter`: `test/features/home/lotus_life_counter_internal_player_values_test.dart`
- suite de fallback interno para `player state` e `set life`: `test/features/home/lotus_life_counter_internal_player_state_test.dart`
- suite de fallback interno para `table state` e outcomes simples de `autoKill`: `test/features/home/lotus_life_counter_internal_state_outcomes_test.dart`
- suite dedicada de normalizacao canonica do host: `test/features/home/lotus_life_counter_host_normalization_test.dart`
- revisao formal do papel das native sheets: `app/doc/LIFE_COUNTER_NATIVE_SHEETS_REVIEW_2026-04-02.md`
- auditoria viva dos `open-native-*`: `app/doc/LIFE_COUNTER_NATIVE_FALLBACK_AUDIT_2026-04-03.md`
- status operacional dos dominios `ownership_bridge`: `app/doc/LIFE_COUNTER_OWNERSHIP_BRIDGE_STATUS_2026-04-03.md`

## Comandos

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Pastas principais

- `lib/features/decks/`
- `lib/features/home/`
- `lib/features/auth/`
- `lib/features/collection/`
- `lib/features/trades/`

## Observação

Neste momento, o app não deve puxar prioridade para longe do core de decks.  
Melhorias visuais e superfícies secundárias só entram quando protegem ou reforçam o fluxo principal.
