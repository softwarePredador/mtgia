# Life Counter - Final Validation - 2026-04-02

## Objective

Registrar a validacao final do life counter na arquitetura oficial definida para o produto:

- `WebView` do Lotus como renderer visual oficial
- ManaLoom como backend invisivel de sessao, persistencia, snapshot bridge, normalizacao e regras de mesa
- `Planechase`, `Archenemy` e `Bounty` incluidos no produto final como fluxos Lotus-first visuais
- sem roadmap ativo de remocao do `WebView`

## Scope validated

### Baseline visual Lotus-first

- menu radial
- `settings`
- `history`
- `card search`
- mesa principal em tela cheia
- overlays principais permanecendo Lotus-first

### Backend invisivel ManaLoom

- bootstrap canonico
- reload e reopen por snapshot
- normalizacao de `turnTracker`
- saneamento de ownership de mesa
- `autoKill`
- `commander damage`
- `dice / high roll / roll 1st`
- round-trip de `storm`, `monarch`, `initiative`

### Runtime de jogador

- `player state`
- `set life`
- `player counters`
- `commander damage`
- `player appearance`

### Game Modes

- abertura da shell interna de suporte
- `settings`
- `edit cards`
- card pool ativo
- fronteira de suporte Lotus-first documentada

## Local validation battery

Os comandos abaixo passaram:

- `flutter analyze --no-version-check`
- `flutter test test/features/home --no-version-check`

## Android smoke battery

Os comandos abaixo passaram no `emulator-5554`:

- `flutter test integration_test/life_counter_webview_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_reopen_snapshot_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_lotus_visual_overlays_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_lotus_settings_visual_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_lotus_card_search_visual_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_day_night_reopen_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_settings_reopen_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_player_appearance_reopen_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_player_state_reopen_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_life_totals_reopen_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_regular_counters_reopen_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_table_state_reopen_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_commander_damage_reopen_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_commander_cast_reopen_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_extra_counters_reopen_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_game_timer_reopen_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_table_state_roundtrip_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_commander_cast_roundtrip_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_commander_damage_roundtrip_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_extra_counters_roundtrip_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_player_state_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_player_counter_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_commander_damage_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_player_state_set_life_autokill_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_game_modes_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_game_modes_card_pool_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_game_modes_settings_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_two_players_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_five_players_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_six_players_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`

## Notes from final validation

- `life_counter_webview_smoke_test.dart` foi alinhado com a regra canonica atual do tracker: quando o `startingPlayerIndex` do snapshot aponta para jogador fora da mesa, o bootstrap canonico reescreve `firstPlayerIndex` para o primeiro jogador ativo.
- `life_counter_native_player_state_smoke_test.dart` foi endurecido para limpar o store explicitamente e acionar `Decked Out` pelo botao dedicado da sheet, evitando heranca de estado entre cenarios.
- os smokes de `Game Modes` passaram a esperar o modal explicitamente antes das assercoes, reduzindo sensibilidade ao tempo de animacao do overlay.
- `day / night` tambem ficou coberto no caminho vivo de reopen: a preferencia canonica ManaLoom volta a prevalecer mesmo quando o snapshot Lotus e propositalmente regravado com valor stale antes da reabertura.
- `settings` tambem ficou coberto no mesmo padrao de reopen: `gameSettings` canonico volta a prevalecer no bootstrap mesmo quando o snapshot Lotus salvo traz flags stale.
- `player appearance` tambem ficou coberto no mesmo padrao: `players` e `__manaloom_player_appearances` canonicos voltam a prevalecer sobre um snapshot Lotus stale no bootstrap e no reopen.
- `player special state` tambem ficou coberto no mesmo padrao: `players.alive` e `__manaloom_player_special_states` canonicos voltam a prevalecer sobre um snapshot Lotus stale no bootstrap e no reopen.
- `life totals` tambem ficaram cobertos no mesmo padrao: `players[].life` canonicos voltam a prevalecer no bootstrap e no reopen mesmo quando o snapshot Lotus salvo traz vidas stale.
- `poison`, `energy` e `experience` tambem ficaram cobertos no mesmo padrao: os counters regulares canonicos voltam a prevalecer no bootstrap e no reopen mesmo quando o snapshot Lotus salvo traz valores stale zerados.
- `table state` tambem ficou coberto no mesmo padrao: `__manaloom_table_state` canonico volta a prevalecer no bootstrap e no reopen mesmo quando o snapshot Lotus salvo traz `storm`, `monarch` e `initiative` stale.
- `commander damage` tambem ficou coberto no mesmo padrao: `players[].commanderDamage` canonico volta a prevalecer no bootstrap e no reopen mesmo quando o snapshot Lotus salvo traz dano stale zerado.
- `commander casts` tambem ficou coberto no mesmo padrao: `players[].partnerCommander` e `players[].counters.tax-*` canonicos voltam a prevalecer no bootstrap e no reopen mesmo quando o snapshot Lotus salvo traz tax stale zerado.
- `extra counters` tambem ficou coberto no mesmo padrao: `players[].counters` canonicos voltam a prevalecer no bootstrap e no reopen mesmo quando o snapshot Lotus salvo traz counters customizados stale ou vazios.
- o smoke de `6 players` precisou de reinicio do daemon `adb` durante a rodada; o rerun passou sem mudanca de produto.

## Final done definition

Dentro da arquitetura Lotus-first oficial, o life counter fica considerado fechado quando:

- a UI principal permanece Lotus-first
- nenhum clique principal abre UI Flutter por acidente
- a sessao canonica e o snapshot Lotus permanecem coerentes em bootstrap, reload e reopen
- runtime de jogador e estado auxiliar de mesa passam pela camada canonicamente normalizada do ManaLoom
- `Planechase`, `Archenemy` e `Bounty` ficam suportados como fluxos Lotus-first com backend ManaLoom por tras

## Explicitly out of scope

Nao faz parte deste encerramento:

- remover o `WebView`
- reimplementar a mesa em Flutter puro
- redesenhar o Lotus
- migrar visualmente `Planechase`, `Archenemy` ou `Bounty` para Flutter

## Operational conclusion

O life counter fica encerrado nesta frente como:

- visual oficial: Lotus no `WebView`
- backend oficial: ManaLoom
- evolucao visual futura: preferencialmente no proprio Lotus (`css`, `js`, assets e host injection)
