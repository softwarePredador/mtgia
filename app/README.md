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

Estado vivo do contador hoje:

- runtime source-of-truth: `app/assets/lotus/`
- implementacao oficial: `app/lib/features/home/lotus_life_counter_screen.dart`
- rota viva: `app/lib/features/home/life_counter_route.dart`
- contrato proprio de sessao/persistencia: `app/lib/features/home/life_counter/`
- engine canonica inicial da mesa: `app/lib/features/home/life_counter/life_counter_tabletop_engine.dart`
- catalogo proprio de settings por secao/campo: `app/lib/features/home/life_counter/life_counter_settings_catalog.dart`
- shells nativas atuais do contador: `app/lib/features/home/life_counter/life_counter_native_settings_sheet.dart`, `app/lib/features/home/life_counter/life_counter_native_history_sheet.dart` e `app/lib/features/home/life_counter/life_counter_native_card_search_sheet.dart`
- shell nativa atual do turn tracker: `app/lib/features/home/life_counter/life_counter_native_turn_tracker_sheet.dart`
- shell nativa atual de timer/clock: `app/lib/features/home/life_counter/life_counter_native_game_timer_sheet.dart`
- shell nativa atual de dice/high roll: `app/lib/features/home/life_counter/life_counter_native_dice_sheet.dart`
- shell nativa atual de table state: `app/lib/features/home/life_counter/life_counter_native_table_state_sheet.dart`
- shell nativa atual de day/night: `app/lib/features/home/life_counter/life_counter_native_day_night_sheet.dart`
- shell nativa atual de game modes: `app/lib/features/home/life_counter/life_counter_native_game_modes_sheet.dart`
- entradas diretas de `Planechase`, `Archenemy` e `Bounty` agora tambem passam pela shell ManaLoom antes de voltar ao runtime embutido
- a shell de `game modes` agora tambem owns a ajuda contextual nativa de `Planechase`, `Archenemy` e `Bounty`
- os botoes de `settings` dentro dos overlays ativos de `Planechase`, `Archenemy` e `Bounty` agora tambem voltam para a shell ManaLoom
- as entradas de `edit cards` de `Planechase`, `Archenemy` e `Bounty` agora tambem passam pela shell ManaLoom antes do handoff para o editor embutido correspondente
- a shell de `game modes` agora tambem reconhece quando o editor embutido de card pool ja esta aberto e oferece retorno/fechamento explicito dessa superficie
- a shell de `game modes` agora tambem assume o limite de 2 modos ativos do Lotus e bloqueia a abertura de um terceiro modo antes do warning legado
- shells nativas atuais de runtime de jogador: `app/lib/features/home/life_counter/life_counter_native_commander_damage_sheet.dart`, `app/lib/features/home/life_counter/life_counter_native_player_appearance_sheet.dart`, `app/lib/features/home/life_counter/life_counter_native_player_counter_sheet.dart`, `app/lib/features/home/life_counter/life_counter_native_player_state_sheet.dart` e `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart`
- reboot do tracker e reabertura do snapshot persistido ja validados em `integration_test/life_counter_reopen_snapshot_smoke_test.dart`
- contrato canonico inicial do game timer: `app/lib/features/home/life_counter/life_counter_game_timer_state*.dart`
- engine propria do game timer: `app/lib/features/home/life_counter/life_counter_game_timer_engine.dart`
- contrato proprio de import/export de history: `app/lib/features/home/life_counter/life_counter_history_transfer.dart`
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
- takeover atual do runtime de jogador:
  - `option-card` do Lotus abre a shell nativa de estado do jogador
  - `killed-overlay` funciona como atalho real para a shell nativa de estado do jogador
  - `color-card` e a entrada de background do Lotus abrem a shell nativa de aparencia do jogador
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
- `monarch-btn` e `initiative-btn` do Lotus agora podem abrir a shell nativa de `Table State`
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
- o `day-night-switcher` do Lotus agora pode abrir a shell nativa de `Day / Night`
- o hub rapido ManaLoom agora tambem oferece `Day / Night`
- o hub rapido ManaLoom agora tambem oferece `Game Modes` como shell propria de status e navegacao
- o estado de `day/night` agora fica em store propria e eh reaplicado no bundle via `__manaloom_day_night_mode`
- os hints legados de `turn tracker` e `counters on card` agora sao marcados como concluídos e suprimidos pela shell policy
- `dice-btn` do Lotus agora abre a shell nativa de `dice/high roll/coin/roll 1st`
- `menu-button` do Lotus agora pode abrir um hub rapido ManaLoom para `settings`, `history`, `card search`, `turn tracker`, `game timer`, `dice`, `table state` e `day/night`
- o toque no total de vida do jogador pode abrir a shell nativa de `Set Life`
- smoke novo preparado para o caminho vivo `Player State -> Set Life`: `integration_test/life_counter_native_player_state_set_life_hub_smoke_test.dart`

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
