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

## Operational observability validation

Os comandos abaixo passaram no `emulator-5554` como prova operacional de instrumentacao, fora da bateria funcional do life counter:

- `flutter test integration_test/mobile_sentry_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`

## Android smoke battery

Os comandos abaixo passaram no `emulator-5554`:

- `flutter test integration_test/life_counter_webview_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_reopen_snapshot_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_lotus_visual_overlays_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_lotus_settings_visual_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_lotus_card_search_visual_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_card_search_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_clock_visual_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_clock_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_history_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_settings_ui_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_day_night_reopen_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_settings_reopen_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_player_appearance_reopen_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_player_state_reopen_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_life_totals_reopen_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_regular_counters_reopen_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_turn_tracker_reopen_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_turn_tracker_live_next_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_turn_tracker_live_previous_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_turn_tracker_live_previous_two_steps_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_dice_d20_live_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_dice_high_roll_live_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_dice_first_player_live_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_dice_coin_live_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_table_state_reopen_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_table_state_ownership_live_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_table_state_clear_ownership_live_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_table_state_storm_live_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_commander_damage_reopen_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_commander_cast_reopen_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_extra_counters_reopen_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_game_timer_reopen_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_game_timer_reset_live_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_game_timer_resume_live_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_game_timer_start_live_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_game_timer_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_game_timer_paused_reopen_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_game_timer_paused_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_table_state_roundtrip_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_commander_cast_roundtrip_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_commander_damage_roundtrip_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_extra_counters_roundtrip_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_player_state_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_player_state_option_card_partner_live_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_player_state_option_card_hidden_counter_live_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_player_state_option_card_hidden_commander_damage_live_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_player_state_option_card_appearance_background_live_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_player_state_option_card_appearance_dismiss_live_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_player_counter_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_player_counter_visible_cards_live_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_commander_damage_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_commander_damage_hidden_live_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_commander_damage_visible_cards_live_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_player_appearance_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_player_appearance_dismiss_live_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_player_appearance_background_live_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_player_appearance_color_card_live_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_player_appearance_color_card_dismiss_live_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_player_appearance_profile_image_fallback_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_player_appearance_profiles_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_player_state_appearance_hub_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_player_state_appearance_image_present_fallback_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_player_state_appearance_dismiss_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_player_state_appearance_background_live_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_player_counter_hub_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_player_state_d20_hub_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_player_state_commander_damage_hub_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_player_state_set_life_hub_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_player_state_set_life_autokill_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_set_life_live_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_player_state_hidden_counter_live_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_player_state_hidden_counter_visible_cards_live_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_player_state_hidden_commander_damage_live_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_player_state_hidden_commander_damage_visible_cards_live_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_player_state_partner_commander_live_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_player_state_partner_commander_visible_cards_live_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_game_modes_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_game_modes_card_pool_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_native_game_modes_settings_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_two_players_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_three_players_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_four_players_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_five_players_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`
- `flutter test integration_test/life_counter_six_players_smoke_test.dart -d emulator-5554 --reporter expanded --no-version-check`

## Notes from final validation

- `life_counter_webview_smoke_test.dart` foi alinhado com a regra canonica atual do tracker: quando o `startingPlayerIndex` do snapshot aponta para jogador fora da mesa, o bootstrap canonico reescreve `firstPlayerIndex` para o primeiro jogador ativo.
- `life_counter_native_player_state_smoke_test.dart` foi endurecido para limpar o store explicitamente e acionar `Decked Out` pelo botao dedicado da sheet, evitando heranca de estado entre cenarios.
- os smokes de `Game Modes` passaram a esperar o modal explicitamente antes das assercoes, reduzindo sensibilidade ao tempo de animacao do overlay.
- `day / night` tambem ficou coberto no caminho vivo de reopen: a preferencia canonica ManaLoom volta a prevalecer mesmo quando o snapshot Lotus e propositalmente regravado com valor stale antes da reabertura.
- `settings` tambem ficou coberto no mesmo padrao de reopen: `gameSettings` canonico volta a prevalecer no bootstrap mesmo quando o snapshot Lotus salvo traz flags stale.
- o `clock` Lotus-first tambem ficou validado explicitamente no caminho vivo: com `showClockOnMainScreen=true` e `gameTimer=false`, o runtime mostra relogio sem subir timer visualmente.
- o recorte `clock-only -> native game timer sheet` tambem ficou validado no caminho vivo: com `showClockOnMainScreen=true` e `gameTimer=false`, tocar o relogio continua abrindo a sheet interna de timer sem quebrar a superficie Lotus-first.
- o atalho de `History` tambem ficou validado como `support_utility` no Android real: abrir a surface interna continua mostrando `lastTableEvent`, eventos do jogo atual e arquivo historico sem depender do overlay visual Lotus.
- o atalho de `Card Search` tambem ficou validado como `support_utility` no Android real: abrir a surface interna continua expondo busca e sugestoes base sem depender do overlay visual Lotus.
- os flags visuais principais de `settings` tambem ficaram validados explicitamente no caminho vivo: `setLifeByTapEnabled`, `verticalTapAreas`, `cleanLook`, counters visiveis, timer e clock realmente entram e saem do runtime Lotus conforme o bootstrap canonico.
- o atalho direto de `Set Life` tambem ficou validado no caminho vivo: abrir a sheet nativa a partir do total de vida, aplicar um delta curto e confirmar que a vida e o payload `players` do Lotus sao atualizados sem reboot completo do bundle, limpando o `lastTableEvent` canonico anterior; o probe JS confirma que esse recorte fecha em `live_runtime`.
- o hub de `Player State -> Manage Counters` tambem ficou validado no caminho vivo no recorte oculto: com counters escondidos no player card, aplicar `poison` pelo hub atualiza a sessao canonica e o payload `players` do Lotus sem reboot completo do bundle.
- o hub de `Player State -> Manage Counters` tambem ficou validado no recorte misto em que o player card continua visivel, mas os counters regulares ficam escondidos: aplicar `poison` pelo hub continua atualizando a sessao canonica e o payload `players` do Lotus sem reboot completo do bundle.
- o hub de `Player State -> Commander Damage` tambem ficou validado no caminho vivo no recorte oculto: com commander damage escondido no player card, aplicar dano pelo hub atualiza a sessao canonica e o payload `players` do Lotus sem reboot completo do bundle.
- o hub de `Player State -> Commander Damage` tambem ficou validado no recorte misto em que o player card continua visivel, mas os commander damage counters ficam escondidos: aplicar dano pelo hub continua atualizando a sessao canonica e o payload `players` do Lotus sem reboot completo do bundle.
- o toggle de `Partner commander` pelo `Player State` tambem ficou validado no caminho vivo no recorte oculto: com counters escondidos no player card, ativar o partner commander pelo hub atualiza a sessao canonica e o payload `players` do Lotus sem reboot completo do bundle.
- o toggle de `Partner commander` pelo `Player State` tambem ficou validado no recorte misto em que o player card continua visivel, mas os counters regulares ficam escondidos: ativar o partner commander pelo hub continua atualizando a sessao canonica e o payload `players` do Lotus sem reboot completo do bundle.
- o takeover de `Player State` vindo de `player_option_card_presented` tambem ficou validado no recorte seguro de `Partner commander`: aplicar a mudanca agora limpa a `option-card` diretamente no DOM e preserva a sessao canonica sem reboot completo do bundle.
- o takeover de `Player State` vindo de `player_option_card_presented` tambem ficou validado no recorte seguro de `Manage Counters` com counters ocultos: aplicar `poison` agora limpa a `option-card` diretamente no DOM e preserva a sessao canonica sem reboot completo do bundle.
- o takeover de `Player State` vindo de `player_option_card_presented` tambem ficou validado no recorte seguro de `Commander Damage` com counters ocultos: aplicar o dano agora limpa a `option-card` diretamente no DOM e preserva a sessao canonica sem reboot completo do bundle.
- o takeover de `Player State` vindo de `player_option_card_presented` tambem ficou validado no recorte seguro de `Appearance` com `background` solido: aplicar a cor agora limpa a `option-card` diretamente no DOM e preserva a sessao canonica sem reboot completo do bundle.
- o takeover de `Player State -> Appearance` vindo de `player_option_card_presented` tambem ficou validado no dismiss sem mudanca: cancelar `Player Appearance`, voltar ao `Player State` e aplicar sem alteracoes limpa a `option-card` diretamente no DOM e preserva a sessao canonica sem reboot completo do bundle.
- `player appearance` tambem ficou coberto no mesmo padrao: `players` e `__manaloom_player_appearances` canonicos voltam a prevalecer sobre um snapshot Lotus stale no bootstrap e no reopen.
- os `appearance profiles` do ManaLoom tambem ficaram validados no caminho vivo: aplicar um perfil salvo pelo fallback interno atualiza a sessao canonica e o runtime Lotus sem quebrar o fluxo visual principal.
- os `appearance profiles` com `backgroundImage` e `backgroundImagePartner` tambem ficaram validados no caminho vivo: aplicar um perfil salvo com referencias de imagem preserva a sessao canonica, e o probe JS confirma que esse recorte segue em `reload_fallback` quando o payload ainda carrega assets visuais do Lotus.
- o apply direto de `player appearance` tambem ficou validado no caminho vivo: editar nickname e preset pela shell interna atualiza a sessao canonica, e o probe JS confirma que este recorte segue em `reload_fallback` quando `nickname_changed` entra no payload.
- o dismiss sem mudanca de `player appearance` vindo da surface direta do player tambem ficou validado no caminho vivo: fechar a sheet agora limpa a `option-card` diretamente no DOM e preserva a sessao canonica sem reboot completo do bundle.
- o apply direto de `player appearance` tambem ficou validado no recorte seguro de `background` solido para um unico jogador: aplicar apenas o preset de cor preserva a sessao canonica e o payload Lotus sem alterar nickname, mantendo a `option-card` limpa no DOM e sem precisar reboot completo do bundle.
- o takeover de `player appearance` vindo do `color card` tambem ficou validado no recorte seguro de `background` solido para um unico jogador: aplicar apenas o preset de cor preserva a sessao canonica e o payload Lotus em `live_runtime`, mantendo a `option-card` limpa no DOM e sem reboot completo do bundle.
- o takeover de `player appearance` vindo do `color card` tambem ficou validado no dismiss sem mudanca: fechar a surface agora limpa a `option-card` diretamente no DOM e preserva a sessao canonica sem reboot completo do bundle.
- o hub de `Player State -> Appearance` tambem ficou validado no caminho vivo: abrir `Player Appearance` a partir do `Player State`, editar nickname e aplicar preserva a sessao canonica, e o probe JS confirma que este recorte segue classificado como `reload_fallback` por ainda mudar estrutura fora do patch incremental seguro do runtime Lotus.
- o hub de `Player State -> Appearance` tambem ficou validado no caminho vivo quando o jogador ja carrega `backgroundImage` e `backgroundImagePartner`: mesmo mudando apenas o `background` solido, a sessao canonica preserva as refs e o probe JS confirma que esse subfluxo segue em `reload_fallback` enquanto o payload ainda depende de assets visuais do Lotus.
- o hub de `Player State -> Appearance` tambem ficou validado no dismiss sem mudanca: abrir `Player Appearance` a partir do `Player State`, cancelar e voltar ao hub preserva a sessao canonica e mantem o runtime Lotus vivo sem reboot do bundle.
- o hub de `Player State -> Appearance` tambem ficou validado no recorte seguro de `background` solido para um unico jogador vindo de `player_state_surface_pressed`: aplicar apenas o preset de cor preserva a sessao canonica e o payload Lotus em `live_runtime`, mantendo o probe JS vivo e sem reboot completo do bundle.
- o fluxo direto de `Player Counter` tambem ficou validado no caminho vivo: aplicar `poison` pela shell direta preserva a sessao canonica, e o probe JS confirma que esse recorte segue em `reload_fallback` no cenario padrao quando `showCountersOnPlayerCard` e `autoKill` ainda estao habilitados.
- o fluxo direto de `Player Counter` tambem ficou validado no recorte misto em que o player card continua visivel, mas os counters regulares ficam escondidos: com `autoKill=false`, `showCountersOnPlayerCard=true` e `showRegularCounters=false`, aplicar `poison` pela shell direta preserva a sessao canonica e o runtime Lotus sem reboot completo do bundle.
- o fluxo direto de `Player Counter` tambem ficou validado no recorte oculto: com `autoKill=false` e `showCountersOnPlayerCard=false`, aplicar `poison` pela shell direta preserva a sessao canonica e mantem o runtime Lotus vivo sem reboot completo do bundle.
- o hub de `Player State -> Player Counter` tambem ficou validado no caminho vivo: abrir `Player Counter` a partir do `Player State`, criar um counter customizado e aplicar preserva a sessao canonica, e o probe JS confirma que este recorte segue classificado como `reload_fallback` quando `showCountersOnPlayerCard=true`.
- o hub de `Player State -> Roll D20` tambem ficou validado no caminho vivo: abrir `Roll D20` a partir do `Player State` atualiza a sessao canonica com `lastPlayerRolls` e `lastTableEvent`; o probe JS confirma que esse recorte fecha em `canonical_store_sync`, mas ainda exige `surface_reset_strategy: bundle_reload` para materializar evento/roll no runtime Lotus.
- o fluxo direto de `Commander Damage` tambem ficou validado no caminho vivo: aplicar dano preserva a sessao canonica, e o probe JS confirma que este recorte segue classificado como `reload_fallback` no cenario padrao com `autoKill` e `lifeLossOnCommanderDamage` habilitados.
- o fluxo direto de `Commander Damage` tambem ficou validado no recorte seguro com counters ocultos e sem reflexo em vida: com `autoKill=false`, `lifeLossOnCommanderDamage=false` e commander damage escondido no player card, aplicar dano pela shell direta preserva a sessao canonica e o payload `players` do Lotus sem reboot completo do bundle.
- o fluxo direto de `Commander Damage` tambem ficou validado no recorte misto em que o player card continua visivel, mas os commander damage counters ficam escondidos: com `autoKill=false`, `lifeLossOnCommanderDamage=false`, `showCountersOnPlayerCard=true` e `showCommanderDamageCounters=false`, aplicar dano pela shell direta preserva a sessao canonica e o runtime Lotus sem reboot completo do bundle.
- o hub direto de `Player State -> Commander Damage` tambem ficou validado no caminho vivo: abrir `Commander Damage` a partir do `Player State` e aplicar dano preserva a sessao canonica, e o probe JS confirma que este recorte segue classificado como `reload_fallback` no cenario padrao com `autoKill` e `lifeLossOnCommanderDamage` habilitados.
- o hub de `Player State -> Set Life` tambem ficou validado no caminho vivo: abrir `Set Life` a partir do `Player State`, aplicar um novo total e limpar `lastTableEvent` preserva a sessao canonica, e o probe JS confirma que este recorte segue classificado como `reload_fallback` quando o delta de vida excede o limite seguro de patch live.
- `player special state` tambem ficou coberto no mesmo padrao: `players.alive` e `__manaloom_player_special_states` canonicos voltam a prevalecer sobre um snapshot Lotus stale no bootstrap e no reopen.
- `life totals` tambem ficaram cobertos no mesmo padrao: `players[].life` canonicos voltam a prevalecer no bootstrap e no reopen mesmo quando o snapshot Lotus salvo traz vidas stale.
- `poison`, `energy` e `experience` tambem ficaram cobertos no mesmo padrao: os counters regulares canonicos voltam a prevalecer no bootstrap e no reopen mesmo quando o snapshot Lotus salvo traz valores stale zerados.
- `turnTracker` tambem ficou coberto no mesmo padrao: flags, ponteiros e turno atual canonicos voltam a prevalecer no bootstrap e no reopen mesmo quando o snapshot Lotus salvo traz tracker stale.
- o recorte de avancar `turn tracker` ativo tambem ficou validado no caminho vivo: abrir a sheet nativa, usar `Next` e aplicar atualiza a sessao canonica e o payload `turnTracker` do Lotus sem reboot completo do bundle.
- o recorte de voltar `turn tracker` ativo em um passo tambem ficou validado no caminho vivo: abrir a sheet nativa, usar `Previous` e aplicar atualiza a sessao canonica e o payload `turnTracker` do Lotus sem reboot completo do bundle.
- o recorte de voltar `turn tracker` ativo em dois passos tambem ficou validado no caminho vivo: abrir a sheet nativa, usar `Previous` duas vezes e aplicar mantem a sessao canonica e o payload `turnTracker` do Lotus sincronizados sem reboot completo do bundle.
- o recorte `D20` de `dice` tambem ficou validado no caminho vivo quando o tracker segue ativo e o `first player` nao muda: abrir a sheet nativa, usar `D20` e aplicar atualiza a sessao canonica e o espelho de `history.lastTableEvent` sem reboot completo do bundle, preservando o payload `turnTracker` do Lotus.
- o recorte `High Roll` de `dice` tambem ficou validado no caminho vivo: abrir a sheet nativa, usar `High Roll` e aplicar persiste `lastHighRolls`, `firstPlayerIndex` quando houver vencedor unico e o espelho de `history.lastTableEvent` sem reboot completo do bundle, mantendo `__manaloom_table_state` coerente com a sessao canonica.
- o recorte `Roll 1st` de `dice` tambem ficou validado no caminho vivo quando o tracker esta inativo: abrir a sheet nativa, usar `Roll 1st` e aplicar persiste `firstPlayerIndex` e o espelho de `history.lastTableEvent` sem reboot completo do bundle, mantendo `__manaloom_table_state` coerente com a sessao canonica.
- o recorte `Coin` de `dice` tambem ficou validado no caminho vivo: abrir a sheet nativa, usar `Coin` e aplicar atualiza apenas o `lastTableEvent` canonico e o espelho de `history.lastTableEvent` sem reboot completo do bundle, mantendo `__manaloom_table_state` estruturalmente coerente.
- o fallback de bootstrap do host tambem ficou provado sem depender de snapshot Lotus confiavel: a suite `lotus_host_controller_bootstrap_test.dart` cobre tanto o caso sem snapshot salvo quanto o caso de snapshot parcial e stale sendo corrigido pelos stores canonicos.
- o mecanismo de patch incremental do Lotus tambem ficou efetivamente validado no produto: os recortes `live_runtime` de `day/night`, `turn tracker`, `game timer` e `table state` passaram na bateria local e/ou nos smokes Android sem exigir reboot completo do bundle nesses casos seguros.
- o `game timer` tambem ficou validado no caminho vivo saindo de inativo para ativo: abrir a sheet a partir do `clock`, iniciar o timer e aplicar passa a reconstruir o estado canonico e a superficie Lotus sem precisar reboot completo do bundle nesse recorte seguro.
- o `game timer` tambem ficou validado no caminho vivo saindo de ativo para inativo: abrir a sheet com o timer correndo, usar `Reset` e aplicar remove o timer da superficie Lotus, limpa o `gameTimerState` persistido e evita reboot completo do bundle nesse recorte seguro.
- o `game timer` tambem ficou validado no caminho vivo saindo de ativo para pausado: abrir a sheet com o timer correndo, usar `Pause` e aplicar mantem store canonica, snapshot persistido e classe `.paused` coerentes no runtime Lotus sem reboot completo do bundle.
- o `game timer` tambem ficou validado no caminho vivo saindo de pausado para ativo: abrir a sheet com o timer pausado, usar `Resume` e aplicar remove a classe `.paused`, limpa `pausedTime` e mantem store canonica e snapshot persistido coerentes no runtime Lotus sem reboot completo do bundle.
- o timer pausado tambem ficou explicitamente validado no caminho vivo: quando o bootstrap canonico traz `isPaused=true`, o runtime Lotus reabre com o texto pausado correto e persiste o estado esperado.
- o timer pausado tambem ficou coberto em reopen: `startTime`, `pausedTime` e `isPaused=true` permanecem coerentes apos fechar e reabrir a tela.
- `table state` tambem ficou coberto no mesmo padrao: `__manaloom_table_state` canonico volta a prevalecer no bootstrap e no reopen mesmo quando o snapshot Lotus salvo traz `storm`, `monarch` e `initiative` stale.
- o recorte `monarch + initiative` de `table state` tambem ficou validado no caminho vivo: abrir a sheet nativa, atribuir os dois owners e aplicar atualiza a sessao canonica e `__manaloom_table_state` no runtime Lotus sem reboot completo do bundle.
- o recorte de limpeza de `monarch + initiative` tambem ficou validado no caminho vivo: abrir a sheet nativa com owners ativos, limpar ambos e aplicar zera a sessao canonica e `__manaloom_table_state` no runtime Lotus sem reboot completo do bundle.
- o recorte `storm-only` de `table state` tambem ficou validado no caminho vivo: abrir a sheet nativa, aumentar `Storm` e aplicar atualiza a sessao canonica e `__manaloom_table_state` no runtime Lotus sem tocar nos owners auxiliares da mesa.
- `commander damage` tambem ficou coberto no mesmo padrao: `players[].commanderDamage` canonico volta a prevalecer no bootstrap e no reopen mesmo quando o snapshot Lotus salvo traz dano stale zerado.
- `commander casts` tambem ficou coberto no mesmo padrao: `players[].partnerCommander` e `players[].counters.tax-*` canonicos voltam a prevalecer no bootstrap e no reopen mesmo quando o snapshot Lotus salvo traz tax stale zerado.
- `extra counters` tambem ficou coberto no mesmo padrao: `players[].counters` canonicos voltam a prevalecer no bootstrap e no reopen mesmo quando o snapshot Lotus salvo traz counters customizados stale ou vazios.
- o smoke de `6 players` precisou de reinicio do daemon `adb` durante a rodada; o rerun passou sem mudanca de produto.
- os player counts suportados agora ficam cobertos explicitamente na bateria Android em `2`, `3`, `4`, `5` e `6` jogadores, com bootstrap canonico no runtime Lotus.
- a verificacao operacional de `mobile_sentry_smoke_test.dart` tambem passou no Android real; ela foi mantida separada da bateria funcional do life counter por validar observabilidade do app, nao comportamento de mesa.

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
