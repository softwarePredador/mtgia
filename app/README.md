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
- `edit cards` e card pools permanecem embutidos no runtime Lotus como parte suportada do produto final, sem migracao visual para Flutter nesta fase
- `turn tracker`, `game timer` e `table state` agora tambem registram `live_patch_eligible` e `apply_strategy`, deixando explicito na observabilidade quando o apply fechou por runtime live ou por `reload`
- `day/night` agora tambem registra `live_patch_eligible` e `apply_strategy`, alinhando sua trilha de apply/fallback ao mesmo contrato observavel
- `dice`, `commander damage`, `player appearance`, `player counter`, `player state` e `set life` continuam `reload-only`, e agora tambem anotam isso explicitamente na observabilidade de apply com `live_patch_eligible: false` e `apply_strategy: reload_fallback`
- `settings` continua `reload-only` por seguranca do bundle Lotus, e agora tambem anota isso explicitamente na observabilidade de apply com `live_patch_eligible: false` e `apply_strategy: reload_fallback`
- `history` e `card search` continuam Lotus-first visuais, e as sheets internas agora anotam explicitamente `surface_strategy: native_fallback`; `history export` tambem anota `transfer_strategy: clipboard_export`
- `history import` agora tambem anota `transfer_strategy: clipboard_import`, `apply_strategy: canonical_store_sync` e `reload_required: false`, deixando explicito que a troca real acontece no estado canonico sem rebootar o bundle
- `settings`, `day/night`, `turn tracker`, `game timer`, `dice` e `table state` agora tambem anotam `surface_strategy: native_fallback` na abertura da sheet interna, deixando explicito que essas superfices utilitarias continuam suporte nativo ao fluxo Lotus-first
- `commander damage`, `player appearance`, `player counter`, `player state` e `set life` agora tambem anotam `surface_strategy: native_fallback` na abertura da sheet interna, deixando explicito que o runtime de jogador continua suporte nativo ao fluxo Lotus-first
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
- `game timer` agora ja evita `reload` no caso seguro `active -> active`, usando patch incremental do runtime Lotus, mas so quando o alvo `.game-timer` esta presente no DOM real
- `turn tracker` agora tambem evita `reload` nos casos seguros de avancar turnos para frente, fazer rewind curto limitado e mudar o starting player por rewind curto em `Turn 1`, com tracker ja ativo, dirigindo o proprio runtime do Lotus, mas so quando o alvo `.turn-time-tracker` esta presente no DOM real
- `table state` agora tambem evita `reload` no recorte seguro de `monarch/initiative`, reaplicando ou limpando moedas, ownership visual e estado da `menu-button` direto no DOM do Lotus; `storm` continua em fallback
- `day/night` continua live no Lotus, mas agora so fecha sem fallback quando o `.day-night-switcher` confirma a troca; se nao confirmar, o host recarrega o bundle
- `game modes` embutidos agora tambem so registram sucesso quando o seletor de abertura, o follow-up de `edit cards` ou o seletor de fechamento existe no DOM real do Lotus; o passo de card pool saiu do `setTimeout` fire-and-forget e passou a ser confirmado em chamada separada, com `native_game_modes_action_failed` e `action_delivered` evitando telemetria ambigua
- `turn tracker`, `game timer` e `table state` agora tambem anotam `apply_strategy` (`live_runtime` vs `reload_fallback`) e `live_patch_eligible` nos eventos de apply
- `day/night` agora tambem anota `apply_strategy` (`live_runtime` vs `reload_fallback`) e `live_patch_eligible` no evento de apply
- `dice`, `commander damage`, `player appearance`, `player counter`, `player state` e `set life` agora tambem anotam `apply_strategy: reload_fallback` e `live_patch_eligible: false`, deixando explicito no log que ainda dependem de rehydrate completo
- `settings` agora tambem anota `apply_strategy: reload_fallback` e `live_patch_eligible: false`, deixando explicito no log que esse dominio continua dependente de rehydrate completo
- `history` e `card search` agora tambem anotam `surface_strategy: native_fallback` nos eventos da sheet interna, deixando explicito no log que esses atalhos sao suporte nativo e nao takeover visual principal
- `history import` agora tambem anota `transfer_strategy: clipboard_import`, `apply_strategy: canonical_store_sync` e `reload_required: false`, deixando explicito no log que esse fluxo faz sync canonico sem apply live no Lotus
- `settings`, `day/night`, `turn tracker`, `game timer`, `dice` e `table state` agora tambem anotam `surface_strategy: native_fallback` nos eventos de open/dismiss da sheet interna, padronizando a leitura de suporte tecnico Lotus-first
- `commander damage`, `player appearance`, `player counter`, `player state` e `set life` agora tambem anotam `surface_strategy: native_fallback` nos eventos de open/dismiss da sheet interna, padronizando a leitura de suporte tecnico Lotus-first no runtime de jogador
- suite de fallback interno para `player appearance`: `test/features/home/lotus_life_counter_internal_player_appearance_test.dart`
- suite de fallback interno para `commander damage` e `player counter`: `test/features/home/lotus_life_counter_internal_player_values_test.dart`
- suite de fallback interno para `player state` e `set life`: `test/features/home/lotus_life_counter_internal_player_state_test.dart`
- suite de fallback interno para `table state` e outcomes simples de `autoKill`: `test/features/home/lotus_life_counter_internal_state_outcomes_test.dart`
- suite dedicada de normalizacao canonica do host: `test/features/home/lotus_life_counter_host_normalization_test.dart`
- revisao formal do papel das native sheets: `app/doc/LIFE_COUNTER_NATIVE_SHEETS_REVIEW_2026-04-02.md`

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
