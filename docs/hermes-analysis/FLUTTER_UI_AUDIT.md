# Flutter UI/UX Audit

## Metadata

- Gerado em UTC: `2026-06-04T15:07:16.609031+00:00`
- Branch: `codex/hermes-analysis-docs`
- SHA: `2b289baa`
- Escopo: `app/lib/features/**/*.dart`, `app/lib/core/**/*.dart`
- Arquivos Dart analisados: `152`
- Metodo: varredura estatica deterministica por padroes de UI/UX

## Sumario

`findings=323 P0=0 P1=83 P2=240`

### Contagem por regra

- `material_color_direct`: 204 (mostrando 80)
- `hardcoded_color`: 128 (mostrando 80)
- `interactive_without_semantics_hint`: 79
- `possible_small_touch_target`: 52
- `icon_button_missing_tooltip`: 25
- `mock_or_hardcoded_data`: 3
- `image_network_missing_state`: 2
- `placeholder_or_mock_copy`: 1
- `network_image_no_cache_abstraction`: 1

## Findings

### P1

#### P1-001 icon_button_missing_tooltip

- Evidencia: `app/lib/features/auth/screens/login_screen.dart:193`
- Trecho: `suffixIcon: IconButton(`
- Impacto: Botao apenas com icone sem tooltip reduz compreensao e acessibilidade.
- Sugestao: Adicionar tooltip claro; quando necessario, semanticLabel no Icon.

#### P1-002 icon_button_missing_tooltip

- Evidencia: `app/lib/features/auth/screens/register_screen.dart:90`
- Trecho: `leading: IconButton(`
- Impacto: Botao apenas com icone sem tooltip reduz compreensao e acessibilidade.
- Sugestao: Adicionar tooltip claro; quando necessario, semanticLabel no Icon.

#### P1-003 icon_button_missing_tooltip

- Evidencia: `app/lib/features/auth/screens/register_screen.dart:238`
- Trecho: `suffixIcon: IconButton(`
- Impacto: Botao apenas com icone sem tooltip reduz compreensao e acessibilidade.
- Sugestao: Adicionar tooltip claro; quando necessario, semanticLabel no Icon.

#### P1-004 icon_button_missing_tooltip

- Evidencia: `app/lib/features/auth/screens/register_screen.dart:279`
- Trecho: `suffixIcon: IconButton(`
- Impacto: Botao apenas com icone sem tooltip reduz compreensao e acessibilidade.
- Sugestao: Adicionar tooltip claro; quando necessario, semanticLabel no Icon.

#### P1-005 icon_button_missing_tooltip

- Evidencia: `app/lib/features/binder/screens/binder_screen.dart:1051`
- Trecho: `const _ActionIconButton({`
- Impacto: Botao apenas com icone sem tooltip reduz compreensao e acessibilidade.
- Sugestao: Adicionar tooltip claro; quando necessario, semanticLabel no Icon.

#### P1-006 icon_button_missing_tooltip

- Evidencia: `app/lib/features/binder/screens/binder_screen.dart:1147`
- Trecho: `suffixIcon: IconButton(`
- Impacto: Botao apenas com icone sem tooltip reduz compreensao e acessibilidade.
- Sugestao: Adicionar tooltip claro; quando necessario, semanticLabel no Icon.

#### P1-007 icon_button_missing_tooltip

- Evidencia: `app/lib/features/binder/screens/marketplace_screen.dart:99`
- Trecho: `suffixIcon: IconButton(`
- Impacto: Botao apenas com icone sem tooltip reduz compreensao e acessibilidade.
- Sugestao: Adicionar tooltip claro; quando necessario, semanticLabel no Icon.

#### P1-008 icon_button_missing_tooltip

- Evidencia: `app/lib/features/cards/screens/card_detail_screen.dart:37`
- Trecho: `leading: IconButton(`
- Impacto: Botao apenas com icone sem tooltip reduz compreensao e acessibilidade.
- Sugestao: Adicionar tooltip claro; quando necessario, semanticLabel no Icon.

#### P1-009 icon_button_missing_tooltip

- Evidencia: `app/lib/features/cards/screens/card_search_screen.dart:294`
- Trecho: `: IconButton(`
- Impacto: Botao apenas com icone sem tooltip reduz compreensao e acessibilidade.
- Sugestao: Adicionar tooltip claro; quando necessario, semanticLabel no Icon.

#### P1-010 icon_button_missing_tooltip

- Evidencia: `app/lib/features/community/screens/community_screen.dart:180`
- Trecho: `suffixIcon: IconButton(`
- Impacto: Botao apenas com icone sem tooltip reduz compreensao e acessibilidade.
- Sugestao: Adicionar tooltip claro; quando necessario, semanticLabel no Icon.

#### P1-011 icon_button_missing_tooltip

- Evidencia: `app/lib/features/community/screens/community_screen.dart:586`
- Trecho: `suffixIcon: IconButton(`
- Impacto: Botao apenas com icone sem tooltip reduz compreensao e acessibilidade.
- Sugestao: Adicionar tooltip claro; quando necessario, semanticLabel no Icon.

#### P1-012 icon_button_missing_tooltip

- Evidencia: `app/lib/features/decks/screens/deck_generate_screen.dart:355`
- Trecho: `leading: IconButton(`
- Impacto: Botao apenas com icone sem tooltip reduz compreensao e acessibilidade.
- Sugestao: Adicionar tooltip claro; quando necessario, semanticLabel no Icon.

#### P1-013 icon_button_missing_tooltip

- Evidencia: `app/lib/features/decks/screens/deck_import_screen.dart:403`
- Trecho: `leading: IconButton(`
- Impacto: Botao apenas com icone sem tooltip reduz compreensao e acessibilidade.
- Sugestao: Adicionar tooltip claro; quando necessario, semanticLabel no Icon.

#### P1-014 icon_button_missing_tooltip

- Evidencia: `app/lib/features/decks/widgets/deck_card.dart:234`
- Trecho: `IconButton(`
- Impacto: Botao apenas com icone sem tooltip reduz compreensao e acessibilidade.
- Sugestao: Adicionar tooltip claro; quando necessario, semanticLabel no Icon.

#### P1-015 icon_button_missing_tooltip

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_card_search_sheet.dart:171`
- Trecho: `: IconButton(`
- Impacto: Botao apenas com icone sem tooltip reduz compreensao e acessibilidade.
- Sugestao: Adicionar tooltip claro; quando necessario, semanticLabel no Icon.

#### P1-016 icon_button_missing_tooltip

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_commander_damage_sheet.dart:466`
- Trecho: `IconButton(`
- Impacto: Botao apenas com icone sem tooltip reduz compreensao e acessibilidade.
- Sugestao: Adicionar tooltip claro; quando necessario, semanticLabel no Icon.

#### P1-017 icon_button_missing_tooltip

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_commander_damage_sheet.dart:485`
- Trecho: `IconButton(`
- Impacto: Botao apenas com icone sem tooltip reduz compreensao e acessibilidade.
- Sugestao: Adicionar tooltip claro; quando necessario, semanticLabel no Icon.

#### P1-018 icon_button_missing_tooltip

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_game_modes_sheet.dart:627`
- Trecho: `IconButton(`
- Impacto: Botao apenas com icone sem tooltip reduz compreensao e acessibilidade.
- Sugestao: Adicionar tooltip claro; quando necessario, semanticLabel no Icon.

#### P1-019 icon_button_missing_tooltip

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_player_counter_sheet.dart:432`
- Trecho: `IconButton(`
- Impacto: Botao apenas com icone sem tooltip reduz compreensao e acessibilidade.
- Sugestao: Adicionar tooltip claro; quando necessario, semanticLabel no Icon.

#### P1-020 icon_button_missing_tooltip

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_player_counter_sheet.dart:457`
- Trecho: `IconButton(`
- Impacto: Botao apenas com icone sem tooltip reduz compreensao e acessibilidade.
- Sugestao: Adicionar tooltip claro; quando necessario, semanticLabel no Icon.

#### P1-021 icon_button_missing_tooltip

- Evidencia: `app/lib/features/home/life_counter_screen.dart:2267`
- Trecho: `: IconButton(`
- Impacto: Botao apenas com icone sem tooltip reduz compreensao e acessibilidade.
- Sugestao: Adicionar tooltip claro; quando necessario, semanticLabel no Icon.

#### P1-022 icon_button_missing_tooltip

- Evidencia: `app/lib/features/messages/screens/chat_screen.dart:226`
- Trecho: `return IconButton(`
- Impacto: Botao apenas com icone sem tooltip reduz compreensao e acessibilidade.
- Sugestao: Adicionar tooltip claro; quando necessario, semanticLabel no Icon.

#### P1-023 icon_button_missing_tooltip

- Evidencia: `app/lib/features/scanner/widgets/scanned_card_preview.dart:700`
- Trecho: `suffixIcon: IconButton(`
- Impacto: Botao apenas com icone sem tooltip reduz compreensao e acessibilidade.
- Sugestao: Adicionar tooltip claro; quando necessario, semanticLabel no Icon.

#### P1-024 icon_button_missing_tooltip

- Evidencia: `app/lib/features/social/screens/user_search_screen.dart:61`
- Trecho: `suffixIcon: IconButton(`
- Impacto: Botao apenas com icone sem tooltip reduz compreensao e acessibilidade.
- Sugestao: Adicionar tooltip claro; quando necessario, semanticLabel no Icon.

#### P1-025 icon_button_missing_tooltip

- Evidencia: `app/lib/features/trades/screens/trade_detail_screen.dart:1104`
- Trecho: `IconButton(`
- Impacto: Botao apenas com icone sem tooltip reduz compreensao e acessibilidade.
- Sugestao: Adicionar tooltip claro; quando necessario, semanticLabel no Icon.

#### P1-026 image_network_missing_state

- Evidencia: `app/lib/core/widgets/cached_card_image.dart:88`
- Trecho: `return Image.network(`
- Impacto: Imagem remota sem estado de loading/erro gera tela quebrada ou salto visual em rede lenta.
- Sugestao: Adicionar fallback visual, loadingBuilder/frameBuilder e errorBuilder.

#### P1-027 image_network_missing_state

- Evidencia: `app/lib/features/home/home_screen.dart:682`
- Trecho: `return Image.network(`
- Impacto: Imagem remota sem estado de loading/erro gera tela quebrada ou salto visual em rede lenta.
- Sugestao: Adicionar fallback visual, loadingBuilder/frameBuilder e errorBuilder.

#### P1-028 mock_or_hardcoded_data

- Evidencia: `app/lib/features/decks/screens/deck_generate_screen.dart:650`
- Trecho: `final isMock = _generatedDeck!['is_mock'] == true;`
- Impacto: Dados mock/hardcoded no fluxo de UI podem divergir do backend real.
- Sugestao: Trocar por provider/API real ou isolar em fixture de teste/dev.

#### P1-029 mock_or_hardcoded_data

- Evidencia: `app/lib/features/decks/screens/deck_generate_screen.dart:727`
- Trecho: `if (isMock || warnings is Map) ...[`
- Impacto: Dados mock/hardcoded no fluxo de UI podem divergir do backend real.
- Sugestao: Trocar por provider/API real ou isolar em fixture de teste/dev.

#### P1-030 mock_or_hardcoded_data

- Evidencia: `app/lib/features/decks/screens/deck_generate_screen.dart:747`
- Trecho: `if (isMock)`
- Impacto: Dados mock/hardcoded no fluxo de UI podem divergir do backend real.
- Sugestao: Trocar por provider/API real ou isolar em fixture de teste/dev.

#### P1-031 placeholder_or_mock_copy

- Evidencia: `app/lib/features/decks/screens/deck_import_screen.dart:580`
- Trecho: `'Exemplo',`
- Impacto: Copy placeholder ou mock pode vazar para producao e reduzir confianca.
- Sugestao: Substituir por copy final ou condicionar a ambiente de desenvolvimento.

#### P1-032 possible_small_touch_target

- Evidencia: `app/lib/features/auth/screens/login_screen.dart:270`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-033 possible_small_touch_target

- Evidencia: `app/lib/features/auth/screens/register_screen.dart:357`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-034 possible_small_touch_target

- Evidencia: `app/lib/features/binder/screens/binder_screen.dart:1481`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-035 possible_small_touch_target

- Evidencia: `app/lib/features/binder/screens/marketplace_screen.dart:497`
- Trecho: `GestureDetector(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-036 possible_small_touch_target

- Evidencia: `app/lib/features/binder/widgets/binder_item_editor.dart:618`
- Trecho: `child: GestureDetector(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-037 possible_small_touch_target

- Evidencia: `app/lib/features/binder/widgets/binder_item_editor.dart:665`
- Trecho: `child: GestureDetector(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-038 possible_small_touch_target

- Evidencia: `app/lib/features/binder/widgets/binder_item_editor.dart:998`
- Trecho: `return InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-039 possible_small_touch_target

- Evidencia: `app/lib/features/cards/screens/card_search_screen.dart:317`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-040 possible_small_touch_target

- Evidencia: `app/lib/features/cards/screens/card_search_screen.dart:616`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-041 possible_small_touch_target

- Evidencia: `app/lib/features/cards/screens/card_search_screen.dart:1156`
- Trecho: `return InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-042 possible_small_touch_target

- Evidencia: `app/lib/features/community/screens/community_deck_detail_screen.dart:205`
- Trecho: `child: GestureDetector(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-043 possible_small_touch_target

- Evidencia: `app/lib/features/community/screens/community_screen.dart:747`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-044 possible_small_touch_target

- Evidencia: `app/lib/features/community/screens/community_screen.dart:961`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-045 possible_small_touch_target

- Evidencia: `app/lib/features/community/screens/community_screen.dart:1105`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-046 possible_small_touch_target

- Evidencia: `app/lib/features/decks/screens/deck_list_screen.dart:487`
- Trecho: `InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-047 possible_small_touch_target

- Evidencia: `app/lib/features/decks/screens/deck_list_screen.dart:957`
- Trecho: `return InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-048 possible_small_touch_target

- Evidencia: `app/lib/features/decks/widgets/deck_details_overview_tab.dart:448`
- Trecho: `(card) => InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-049 possible_small_touch_target

- Evidencia: `app/lib/features/decks/widgets/deck_details_overview_tab.dart:1179`
- Trecho: `InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-050 possible_small_touch_target

- Evidencia: `app/lib/features/decks/widgets/deck_details_overview_tab.dart:1359`
- Trecho: `InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-051 possible_small_touch_target

- Evidencia: `app/lib/features/decks/widgets/deck_optimize_sheet_widgets.dart:103`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-052 possible_small_touch_target

- Evidencia: `app/lib/features/decks/widgets/deck_optimize_sheet_widgets.dart:1134`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-053 possible_small_touch_target

- Evidencia: `app/lib/features/decks/widgets/deck_progress_indicator.dart:129`
- Trecho: `return InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-054 possible_small_touch_target

- Evidencia: `app/lib/features/home/home_screen.dart:434`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-055 possible_small_touch_target

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_card_search_sheet.dart:340`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-056 possible_small_touch_target

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_player_appearance_sheet.dart:908`
- Trecho: `return InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-057 possible_small_touch_target

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1773`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-058 possible_small_touch_target

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1999`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-059 possible_small_touch_target

- Evidencia: `app/lib/features/home/life_counter_screen.dart:2396`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-060 possible_small_touch_target

- Evidencia: `app/lib/features/home/life_counter_screen.dart:2438`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-061 possible_small_touch_target

- Evidencia: `app/lib/features/home/life_counter_screen.dart:2598`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-062 possible_small_touch_target

- Evidencia: `app/lib/features/home/life_counter_screen.dart:3399`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-063 possible_small_touch_target

- Evidencia: `app/lib/features/home/life_counter_screen.dart:3601`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-064 possible_small_touch_target

- Evidencia: `app/lib/features/home/life_counter_screen.dart:4765`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-065 possible_small_touch_target

- Evidencia: `app/lib/features/home/life_counter_screen.dart:4969`
- Trecho: `child: GestureDetector(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-066 possible_small_touch_target

- Evidencia: `app/lib/features/home/life_counter_screen.dart:5446`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-067 possible_small_touch_target

- Evidencia: `app/lib/features/home/life_counter_screen.dart:6130`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-068 possible_small_touch_target

- Evidencia: `app/lib/features/home/life_counter_screen.dart:6302`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-069 possible_small_touch_target

- Evidencia: `app/lib/features/notifications/screens/notification_screen.dart:176`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-070 possible_small_touch_target

- Evidencia: `app/lib/features/profile/profile_screen.dart:254`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-071 possible_small_touch_target

- Evidencia: `app/lib/features/scanner/screens/card_scanner_screen.dart:663`
- Trecho: `GestureDetector(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-072 possible_small_touch_target

- Evidencia: `app/lib/features/scanner/widgets/scanned_card_preview.dart:243`
- Trecho: `GestureDetector(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-073 possible_small_touch_target

- Evidencia: `app/lib/features/scanner/widgets/scanned_card_preview.dart:401`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-074 possible_small_touch_target

- Evidencia: `app/lib/features/scanner/widgets/scanned_card_preview.dart:416`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-075 possible_small_touch_target

- Evidencia: `app/lib/features/scanner/widgets/scanned_card_preview.dart:550`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-076 possible_small_touch_target

- Evidencia: `app/lib/features/social/screens/user_profile_screen.dart:390`
- Trecho: `return GestureDetector(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-077 possible_small_touch_target

- Evidencia: `app/lib/features/social/screens/user_profile_screen.dart:463`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-078 possible_small_touch_target

- Evidencia: `app/lib/features/social/screens/user_profile_screen.dart:1215`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-079 possible_small_touch_target

- Evidencia: `app/lib/features/social/screens/user_search_screen.dart:197`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-080 possible_small_touch_target

- Evidencia: `app/lib/features/trades/screens/create_trade_screen.dart:772`
- Trecho: `return GestureDetector(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-081 possible_small_touch_target

- Evidencia: `app/lib/features/trades/screens/create_trade_screen.dart:989`
- Trecho: `InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-082 possible_small_touch_target

- Evidencia: `app/lib/features/trades/screens/create_trade_screen.dart:1012`
- Trecho: `InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

#### P1-083 possible_small_touch_target

- Evidencia: `app/lib/features/trades/screens/trade_inbox_screen.dart:291`
- Trecho: `child: InkWell(`
- Impacto: Area tocavel possivelmente menor que 48x48 prejudica usabilidade mobile.
- Sugestao: Garantir minimo de 48x48 para alvos de toque.

### P2

#### P2-001 hardcoded_color

- Evidencia: `app/lib/core/theme/app_theme.dart:26`
- Trecho: `static const Color transparent = Color(0x00000000);`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-002 hardcoded_color

- Evidencia: `app/lib/core/theme/app_theme.dart:30`
- Trecho: `static const Color backgroundAbyss = Color(0xFF0F1115); // obsidian-950`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-003 hardcoded_color

- Evidencia: `app/lib/core/theme/app_theme.dart:31`
- Trecho: `static const Color surfaceSlate = Color(0xFF171A21); // obsidian-900`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-004 hardcoded_color

- Evidencia: `app/lib/core/theme/app_theme.dart:32`
- Trecho: `static const Color surfaceElevated = Color(0xFF232735); // slate-800`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-005 hardcoded_color

- Evidencia: `app/lib/core/theme/app_theme.dart:35`
- Trecho: `static const Color brass500 = Color(0xFFC58B2A);`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-006 hardcoded_color

- Evidencia: `app/lib/core/theme/app_theme.dart:36`
- Trecho: `static const Color brass400 = Color(0xFFE0A93B);`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-007 hardcoded_color

- Evidencia: `app/lib/core/theme/app_theme.dart:37`
- Trecho: `static const Color brass700 = Color(0xFF8E641B);`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-008 hardcoded_color

- Evidencia: `app/lib/core/theme/app_theme.dart:39`
- Trecho: `static const Color frost400 = Color(0xFF6FA8DC);`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-009 hardcoded_color

- Evidencia: `app/lib/core/theme/app_theme.dart:40`
- Trecho: `static const Color frost600 = Color(0xFF3E5F8A);`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-010 hardcoded_color

- Evidencia: `app/lib/core/theme/app_theme.dart:49`
- Trecho: `static const Color textPrimary = Color(0xFFF3EFE3); // ivory-100`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-011 hardcoded_color

- Evidencia: `app/lib/core/theme/app_theme.dart:50`
- Trecho: `static const Color textSecondary = Color(0xFFB8C0CC); // mist-300`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-012 hardcoded_color

- Evidencia: `app/lib/core/theme/app_theme.dart:51`
- Trecho: `static const Color textHint = Color(0xFF8A93A3); // mist-500 (hints/placeholders)`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-013 hardcoded_color

- Evidencia: `app/lib/core/theme/app_theme.dart:52`
- Trecho: `static const Color outlineMuted = Color(0xFF2B3142); // slate-700`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-014 hardcoded_color

- Evidencia: `app/lib/core/theme/app_theme.dart:61`
- Trecho: `static const Color success = Color(0xFF4FAF7A);`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-015 hardcoded_color

- Evidencia: `app/lib/core/theme/app_theme.dart:62`
- Trecho: `static const Color warning = Color(0xFFD28B2C);`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-016 hardcoded_color

- Evidencia: `app/lib/core/theme/app_theme.dart:63`
- Trecho: `static const Color error = Color(0xFFC65A46);`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-017 hardcoded_color

- Evidencia: `app/lib/core/theme/app_theme.dart:118`
- Trecho: `static const Color manaW = Color(0xFFF0F2C0);`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-018 hardcoded_color

- Evidencia: `app/lib/core/theme/app_theme.dart:119`
- Trecho: `static const Color manaU = Color(0xFFB3CEEA);`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-019 hardcoded_color

- Evidencia: `app/lib/core/theme/app_theme.dart:120`
- Trecho: `static const Color manaB = Color(0xFFA69F9D); // Visível em gráficos`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-020 hardcoded_color

- Evidencia: `app/lib/core/theme/app_theme.dart:121`
- Trecho: `static const Color manaR = Color(0xFFEB9F82);`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-021 hardcoded_color

- Evidencia: `app/lib/core/theme/app_theme.dart:122`
- Trecho: `static const Color manaG = Color(0xFFC4D3CA);`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-022 hardcoded_color

- Evidencia: `app/lib/core/theme/app_theme.dart:123`
- Trecho: `static const Color manaC = Color(0xFFB8C0CC);`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-023 hardcoded_color

- Evidencia: `app/lib/core/theme/app_theme.dart:187`
- Trecho: `return const Color(0xFF3D3000);`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-024 hardcoded_color

- Evidencia: `app/lib/core/theme/app_theme.dart:189`
- Trecho: `return const Color(0xFF0A2340);`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-025 hardcoded_color

- Evidencia: `app/lib/core/theme/app_theme.dart:191`
- Trecho: `return const Color(0xFF1A1A1A);`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-026 hardcoded_color

- Evidencia: `app/lib/core/theme/app_theme.dart:193`
- Trecho: `return const Color(0xFF3D1005);`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-027 hardcoded_color

- Evidencia: `app/lib/core/theme/app_theme.dart:195`
- Trecho: `return const Color(0xFF0C2E1A);`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-028 hardcoded_color

- Evidencia: `app/lib/core/theme/app_theme.dart:197`
- Trecho: `return const Color(0xFF2A2A2A);`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-029 hardcoded_color

- Evidencia: `app/lib/core/theme/app_theme.dart:208`
- Trecho: `return const Color(0xFFC0C0C0);`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-030 hardcoded_color

- Evidencia: `app/lib/core/theme/app_theme.dart:210`
- Trecho: `return const Color(0xFFFFD700);`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-031 hardcoded_color

- Evidencia: `app/lib/features/auth/screens/splash_screen.dart:84`
- Trecho: `Color(0x22000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-032 hardcoded_color

- Evidencia: `app/lib/features/auth/screens/splash_screen.dart:85`
- Trecho: `Color(0x00000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-033 hardcoded_color

- Evidencia: `app/lib/features/auth/screens/splash_screen.dart:86`
- Trecho: `Color(0x99070A0F),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-034 hardcoded_color

- Evidencia: `app/lib/features/home/home_screen.dart:280`
- Trecho: `foregroundColor: const Color(0xFF120D05),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-035 hardcoded_color

- Evidencia: `app/lib/features/home/home_screen.dart:576`
- Trecho: `Color(0x10000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-036 hardcoded_color

- Evidencia: `app/lib/features/home/home_screen.dart:577`
- Trecho: `Color(0x11000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-037 hardcoded_color

- Evidencia: `app/lib/features/home/home_screen.dart:578`
- Trecho: `Color(0xEE11151D),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-038 hardcoded_color

- Evidencia: `app/lib/features/home/home_screen.dart:725`
- Trecho: `color: Color(0x55F3EFE3),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-039 hardcoded_color

- Evidencia: `app/lib/features/home/home_screen.dart:807`
- Trecho: `color: Color(0x44E0A93B),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-040 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_card_search_sheet.dart:82`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-041 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_commander_damage_sheet.dart:101`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-042 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_day_night_sheet.dart:52`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-043 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_dice_sheet.dart:83`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-044 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_game_modes_sheet.dart:113`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-045 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_game_timer_sheet.dart:73`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-046 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_history_sheet.dart:51`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-047 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_player_appearance_sheet.dart:445`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-048 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_player_appearance_sheet.dart:926`
- Trecho: `color: Color(0x33000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-049 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_player_counter_sheet.dart:174`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-050 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_player_state_sheet.dart:229`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-051 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart:128`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-052 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart:398`
- Trecho: `? const Color(0xFFFF7A9C)`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-053 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart:403`
- Trecho: `? const Color(0x66FF2C77)`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-054 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart:436`
- Trecho: `? const Color(0x33FF2C77)`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-055 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart:439`
- Trecho: `destructive ? const Color(0xFFFF5E9A) : AppTheme.textPrimary,`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-056 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart:445`
- Trecho: `? const Color(0x66FF2C77)`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-057 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_settings_sheet.dart:78`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-058 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_table_state_sheet.dart:85`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-059 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_turn_tracker_sheet.dart:80`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-060 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:108`
- Trecho: `Color(0xFFFFB51E),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-061 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:109`
- Trecho: `Color(0xFFFF0A5B),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-062 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:110`
- Trecho: `Color(0xFFCF7AEF),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-063 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:111`
- Trecho: `Color(0xFF4B57FF),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-064 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:112`
- Trecho: `Color(0xFF44E063),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-065 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:113`
- Trecho: `Color(0xFF40B9FF),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-066 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:912`
- Trecho: `color: Color(0xA6000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-067 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1335`
- Trecho: `color: Color(0xFF44E063),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-068 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1342`
- Trecho: `color: Color(0xFFFFE277),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-069 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1349`
- Trecho: `color: Color(0xFF40B9FF),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-070 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1356`
- Trecho: `color: Color(0xFFB9B4FF),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-071 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1552`
- Trecho: `color: const Color(0xFF9CE9FF).withValues(`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-072 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1580`
- Trecho: `color: const Color(0xFFFFE69A).withValues(`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-073 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1610`
- Trecho: `color: const Color(0xFF0D1117),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-074 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1646`
- Trecho: `Color(0xFF04070E),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-075 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1647`
- Trecho: `Color(0xFF121A2B),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-076 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1658`
- Trecho: `Color(0xFFEAFDFF),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-077 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1659`
- Trecho: `Color(0xFFB9D7FF),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-078 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1673`
- Trecho: `Color(0xFFFDF4FF),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-079 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1674`
- Trecho: `Color(0xFFD7EDFF),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-080 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1689`
- Trecho: `..color = const Color(0xFFE5FCFF).withValues(alpha: 0.56 + (0.2 * progress))`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-081 interactive_without_semantics_hint

- Evidencia: `app/lib/features/auth/screens/login_screen.dart:270`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-082 interactive_without_semantics_hint

- Evidencia: `app/lib/features/auth/screens/register_screen.dart:357`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-083 interactive_without_semantics_hint

- Evidencia: `app/lib/features/binder/screens/binder_screen.dart:1481`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-084 interactive_without_semantics_hint

- Evidencia: `app/lib/features/binder/screens/marketplace_screen.dart:497`
- Trecho: `GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-085 interactive_without_semantics_hint

- Evidencia: `app/lib/features/binder/widgets/binder_item_editor.dart:467`
- Trecho: `return GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-086 interactive_without_semantics_hint

- Evidencia: `app/lib/features/binder/widgets/binder_item_editor.dart:618`
- Trecho: `child: GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-087 interactive_without_semantics_hint

- Evidencia: `app/lib/features/binder/widgets/binder_item_editor.dart:665`
- Trecho: `child: GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-088 interactive_without_semantics_hint

- Evidencia: `app/lib/features/binder/widgets/binder_item_editor.dart:998`
- Trecho: `return InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-089 interactive_without_semantics_hint

- Evidencia: `app/lib/features/cards/screens/card_detail_screen.dart:76`
- Trecho: `return GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-090 interactive_without_semantics_hint

- Evidencia: `app/lib/features/cards/screens/card_detail_screen.dart:136`
- Trecho: `(_) => GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-091 interactive_without_semantics_hint

- Evidencia: `app/lib/features/cards/screens/card_search_screen.dart:317`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-092 interactive_without_semantics_hint

- Evidencia: `app/lib/features/cards/screens/card_search_screen.dart:616`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-093 interactive_without_semantics_hint

- Evidencia: `app/lib/features/cards/screens/card_search_screen.dart:1156`
- Trecho: `return InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-094 interactive_without_semantics_hint

- Evidencia: `app/lib/features/cards/screens/card_search_screen.dart:1263`
- Trecho: `return InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-095 interactive_without_semantics_hint

- Evidencia: `app/lib/features/community/screens/community_deck_detail_screen.dart:205`
- Trecho: `child: GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-096 interactive_without_semantics_hint

- Evidencia: `app/lib/features/community/screens/community_screen.dart:747`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-097 interactive_without_semantics_hint

- Evidencia: `app/lib/features/community/screens/community_screen.dart:788`
- Trecho: `child: GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-098 interactive_without_semantics_hint

- Evidencia: `app/lib/features/community/screens/community_screen.dart:961`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-099 interactive_without_semantics_hint

- Evidencia: `app/lib/features/community/screens/community_screen.dart:1105`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-100 interactive_without_semantics_hint

- Evidencia: `app/lib/features/community/screens/community_screen.dart:1450`
- Trecho: `InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-101 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/screens/deck_details_screen.dart:716`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-102 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/screens/deck_list_screen.dart:487`
- Trecho: `InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-103 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/screens/deck_list_screen.dart:957`
- Trecho: `return InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-104 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/screens/deck_list_screen.dart:1009`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-105 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/screens/deck_list_screen.dart:1346`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-106 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/screens/deck_list_screen.dart:1446`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-107 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/widgets/deck_card.dart:85`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-108 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/widgets/deck_details_overview_tab.dart:448`
- Trecho: `(card) => InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-109 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/widgets/deck_details_overview_tab.dart:1179`
- Trecho: `InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-110 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/widgets/deck_details_overview_tab.dart:1202`
- Trecho: `InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-111 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/widgets/deck_details_overview_tab.dart:1359`
- Trecho: `InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-112 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/widgets/deck_optimize_sheet_widgets.dart:103`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-113 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/widgets/deck_optimize_sheet_widgets.dart:1134`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-114 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/widgets/deck_progress_indicator.dart:129`
- Trecho: `return InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-115 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/widgets/deck_progress_indicator.dart:277`
- Trecho: `return InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-116 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/widgets/deck_ui_components.dart:164`
- Trecho: `return InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-117 interactive_without_semantics_hint

- Evidencia: `app/lib/features/home/home_screen.dart:434`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-118 interactive_without_semantics_hint

- Evidencia: `app/lib/features/home/home_screen.dart:546`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-119 interactive_without_semantics_hint

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_card_search_sheet.dart:304`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-120 interactive_without_semantics_hint

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_card_search_sheet.dart:340`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-121 interactive_without_semantics_hint

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_player_appearance_sheet.dart:908`
- Trecho: `return InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-122 interactive_without_semantics_hint

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1500`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-123 interactive_without_semantics_hint

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1531`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-124 interactive_without_semantics_hint

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1773`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-125 interactive_without_semantics_hint

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1934`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-126 interactive_without_semantics_hint

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1999`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-127 interactive_without_semantics_hint

- Evidencia: `app/lib/features/home/life_counter_screen.dart:2396`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-128 interactive_without_semantics_hint

- Evidencia: `app/lib/features/home/life_counter_screen.dart:2438`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-129 interactive_without_semantics_hint

- Evidencia: `app/lib/features/home/life_counter_screen.dart:2598`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-130 interactive_without_semantics_hint

- Evidencia: `app/lib/features/home/life_counter_screen.dart:3172`
- Trecho: `InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-131 interactive_without_semantics_hint

- Evidencia: `app/lib/features/home/life_counter_screen.dart:3387`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-132 interactive_without_semantics_hint

- Evidencia: `app/lib/features/home/life_counter_screen.dart:3399`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-133 interactive_without_semantics_hint

- Evidencia: `app/lib/features/home/life_counter_screen.dart:3601`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-134 interactive_without_semantics_hint

- Evidencia: `app/lib/features/home/life_counter_screen.dart:4765`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-135 interactive_without_semantics_hint

- Evidencia: `app/lib/features/home/life_counter_screen.dart:4969`
- Trecho: `child: GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-136 interactive_without_semantics_hint

- Evidencia: `app/lib/features/home/life_counter_screen.dart:5121`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-137 interactive_without_semantics_hint

- Evidencia: `app/lib/features/home/life_counter_screen.dart:5221`
- Trecho: `child: GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-138 interactive_without_semantics_hint

- Evidencia: `app/lib/features/home/life_counter_screen.dart:5446`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-139 interactive_without_semantics_hint

- Evidencia: `app/lib/features/home/life_counter_screen.dart:6130`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-140 interactive_without_semantics_hint

- Evidencia: `app/lib/features/home/life_counter_screen.dart:6302`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-141 interactive_without_semantics_hint

- Evidencia: `app/lib/features/notifications/screens/notification_screen.dart:176`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-142 interactive_without_semantics_hint

- Evidencia: `app/lib/features/profile/profile_screen.dart:254`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-143 interactive_without_semantics_hint

- Evidencia: `app/lib/features/scanner/screens/card_scanner_screen.dart:663`
- Trecho: `GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-144 interactive_without_semantics_hint

- Evidencia: `app/lib/features/scanner/widgets/scanned_card_preview.dart:92`
- Trecho: `return GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-145 interactive_without_semantics_hint

- Evidencia: `app/lib/features/scanner/widgets/scanned_card_preview.dart:243`
- Trecho: `GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-146 interactive_without_semantics_hint

- Evidencia: `app/lib/features/scanner/widgets/scanned_card_preview.dart:302`
- Trecho: `GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-147 interactive_without_semantics_hint

- Evidencia: `app/lib/features/scanner/widgets/scanned_card_preview.dart:401`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-148 interactive_without_semantics_hint

- Evidencia: `app/lib/features/scanner/widgets/scanned_card_preview.dart:416`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-149 interactive_without_semantics_hint

- Evidencia: `app/lib/features/scanner/widgets/scanned_card_preview.dart:550`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-150 interactive_without_semantics_hint

- Evidencia: `app/lib/features/social/screens/user_profile_screen.dart:390`
- Trecho: `return GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-151 interactive_without_semantics_hint

- Evidencia: `app/lib/features/social/screens/user_profile_screen.dart:463`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-152 interactive_without_semantics_hint

- Evidencia: `app/lib/features/social/screens/user_profile_screen.dart:1215`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-153 interactive_without_semantics_hint

- Evidencia: `app/lib/features/social/screens/user_search_screen.dart:197`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-154 interactive_without_semantics_hint

- Evidencia: `app/lib/features/trades/screens/create_trade_screen.dart:772`
- Trecho: `return GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-155 interactive_without_semantics_hint

- Evidencia: `app/lib/features/trades/screens/create_trade_screen.dart:959`
- Trecho: `InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-156 interactive_without_semantics_hint

- Evidencia: `app/lib/features/trades/screens/create_trade_screen.dart:989`
- Trecho: `InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-157 interactive_without_semantics_hint

- Evidencia: `app/lib/features/trades/screens/create_trade_screen.dart:1012`
- Trecho: `InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-158 interactive_without_semantics_hint

- Evidencia: `app/lib/features/trades/screens/create_trade_screen.dart:1086`
- Trecho: `return GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-159 interactive_without_semantics_hint

- Evidencia: `app/lib/features/trades/screens/trade_inbox_screen.dart:291`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-160 material_color_direct

- Evidencia: `app/lib/features/binder/screens/binder_screen.dart:58`
- Trecho: `dividerColor: Colors.transparent,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-161 material_color_direct

- Evidencia: `app/lib/features/binder/widgets/binder_item_editor.dart:523`
- Trecho: `? Colors.white`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-162 material_color_direct

- Evidencia: `app/lib/features/binder/widgets/binder_item_editor.dart:958`
- Trecho: `foregroundColor: Colors.white,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-163 material_color_direct

- Evidencia: `app/lib/features/binder/widgets/binder_item_editor.dart:971`
- Trecho: `color: Colors.white,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-164 material_color_direct

- Evidencia: `app/lib/features/cards/screens/card_detail_screen.dart:139`
- Trecho: `backgroundColor: Colors.transparent,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-165 material_color_direct

- Evidencia: `app/lib/features/collection/screens/collection_screen.dart:70`
- Trecho: `dividerColor: Colors.transparent,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-166 material_color_direct

- Evidencia: `app/lib/features/community/screens/community_deck_detail_screen.dart:295`
- Trecho: `color: Colors.white,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-167 material_color_direct

- Evidencia: `app/lib/features/community/screens/community_deck_detail_screen.dart:304`
- Trecho: `foregroundColor: Colors.white,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-168 material_color_direct

- Evidencia: `app/lib/features/community/screens/community_screen.dart:67`
- Trecho: `dividerColor: Colors.transparent,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-169 material_color_direct

- Evidencia: `app/lib/features/decks/screens/deck_import_screen.dart:716`
- Trecho: `foregroundColor: Colors.white,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-170 material_color_direct

- Evidencia: `app/lib/features/decks/screens/deck_import_screen.dart:728`
- Trecho: `color: Colors.white,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-171 material_color_direct

- Evidencia: `app/lib/features/decks/widgets/deck_progress_indicator.dart:206`
- Trecho: `color: Colors.white,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-172 material_color_direct

- Evidencia: `app/lib/features/decks/widgets/sample_hand_widget.dart:241`
- Trecho: `foregroundColor: Colors.white,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-173 material_color_direct

- Evidencia: `app/lib/features/decks/widgets/sample_hand_widget.dart:422`
- Trecho: `foregroundColor: Colors.white,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-174 material_color_direct

- Evidencia: `app/lib/features/home/home_screen.dart:211`
- Trecho: `color: Colors.black.withValues(alpha: 0.28),`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-175 material_color_direct

- Evidencia: `app/lib/features/home/home_screen.dart:449`
- Trecho: `color: Colors.black.withValues(alpha: 0.14),`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-176 material_color_direct

- Evidencia: `app/lib/features/home/home_screen.dart:558`
- Trecho: `color: Colors.black.withValues(alpha: 0.18),`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-177 material_color_direct

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_card_search_sheet.dart:18`
- Trecho: `backgroundColor: Colors.transparent,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-178 material_color_direct

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_card_search_sheet.dart:303`
- Trecho: `color: Colors.transparent,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-179 material_color_direct

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_card_search_sheet.dart:339`
- Trecho: `color: Colors.transparent,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-180 material_color_direct

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_commander_damage_sheet.dart:15`
- Trecho: `backgroundColor: Colors.transparent,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-181 material_color_direct

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_day_night_sheet.dart:13`
- Trecho: `backgroundColor: Colors.transparent,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-182 material_color_direct

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_dice_sheet.dart:18`
- Trecho: `backgroundColor: Colors.transparent,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-183 material_color_direct

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_game_modes_sheet.dart:79`
- Trecho: `backgroundColor: Colors.transparent,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-184 material_color_direct

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_game_modes_sheet.dart:597`
- Trecho: `backgroundColor: Colors.transparent,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-185 material_color_direct

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_game_timer_sheet.dart:15`
- Trecho: `backgroundColor: Colors.transparent,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-186 material_color_direct

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_history_sheet.dart:15`
- Trecho: `backgroundColor: Colors.transparent,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-187 material_color_direct

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_player_appearance_sheet.dart:40`
- Trecho: `backgroundColor: Colors.transparent,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-188 material_color_direct

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_player_appearance_sheet.dart:818`
- Trecho: `color.computeLuminance() > 0.55 ? Colors.black : Colors.white;`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-189 material_color_direct

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_player_appearance_sheet.dart:906`
- Trecho: `color.computeLuminance() > 0.55 ? Colors.black : Colors.white;`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-190 material_color_direct

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_player_counter_sheet.dart:16`
- Trecho: `backgroundColor: Colors.transparent,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-191 material_color_direct

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_player_state_sheet.dart:22`
- Trecho: `backgroundColor: Colors.transparent,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-192 material_color_direct

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart:15`
- Trecho: `backgroundColor: Colors.transparent,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-193 material_color_direct

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart:183`
- Trecho: `color: Colors.white.withValues(alpha: 0.28),`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-194 material_color_direct

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart:201`
- Trecho: `color: Colors.white,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-195 material_color_direct

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_settings_sheet.dart:14`
- Trecho: `backgroundColor: Colors.transparent,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-196 material_color_direct

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_table_state_sheet.dart:14`
- Trecho: `backgroundColor: Colors.transparent,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-197 material_color_direct

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_turn_tracker_sheet.dart:15`
- Trecho: `backgroundColor: Colors.transparent,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-198 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:550`
- Trecho: `barrierColor: Colors.black.withValues(alpha: 0.72),`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-199 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:884`
- Trecho: `backgroundColor: Colors.black,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-200 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:893`
- Trecho: `color: Colors.black,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-201 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1446`
- Trecho: `color: Colors.white.withValues(alpha: 0.76),`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-202 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1499`
- Trecho: `color: Colors.transparent,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-203 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1530`
- Trecho: `color: Colors.transparent,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-204 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1569`
- Trecho: `color: Colors.white.withValues(alpha: isExpanded ? 0.32 : 0.2),`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-205 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1574`
- Trecho: `color: Colors.black.withValues(alpha: 0.24),`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-206 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1603`
- Trecho: `color: Colors.white.withValues(alpha: isExpanded ? 0.3 : 0.2),`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-207 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1614`
- Trecho: `color: Colors.white.withValues(alpha: 0.36),`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-208 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1681`
- Trecho: `..color = Colors.black.withValues(alpha: 0.1)`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-209 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1713`
- Trecho: `Colors.white.withValues(alpha: 0.18),`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-210 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1714`
- Trecho: `Colors.transparent,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-211 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1737`
- Trecho: `..color = Colors.white.withValues(alpha: 0.28 + (0.12 * progress))`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-212 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1767`
- Trecho: `final topTint = Color.lerp(color, Colors.white, 0.2) ?? color;`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-213 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1768`
- Trecho: `final bottomTint = Color.lerp(color, Colors.black, 0.12) ?? color;`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-214 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1790`
- Trecho: `color: Colors.black.withValues(alpha: 0.2 * visualOpacity),`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-215 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1795`
- Trecho: `color: Colors.white.withValues(alpha: 0.1 * visualOpacity),`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-216 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1810`
- Trecho: `color: Colors.black.withValues(alpha: 0.9 * visualOpacity),`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-217 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1880`
- Trecho: `color: Colors.transparent,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-218 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1901`
- Trecho: `color: Colors.white.withValues(alpha: 0.98),`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-219 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1912`
- Trecho: `color: Colors.white.withValues(alpha: 0.66),`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-220 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1933`
- Trecho: `color: Colors.transparent,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-221 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1946`
- Trecho: `color: Colors.white,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-222 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1972`
- Trecho: `color: Colors.white.withValues(alpha: 0.86),`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-223 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1998`
- Trecho: `color: Colors.transparent,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-224 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:2006`
- Trecho: `color: selected ? const Color(0xFFFF2C77) : Colors.transparent,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-225 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:2012`
- Trecho: `: Colors.white.withValues(alpha: 0.9),`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-226 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:2033`
- Trecho: `final tileColor = playerCount >= 4 ? Colors.black : Colors.white;`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-227 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:2036`
- Trecho: `? Colors.black.withValues(alpha: 0.82)`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-228 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:2037`
- Trecho: `: Colors.white.withValues(alpha: 0.9);`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-229 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:2147`
- Trecho: `color: Colors.white.withValues(alpha: 0.9),`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-230 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:2160`
- Trecho: `color: Colors.white.withValues(alpha: 0.72),`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-231 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:2182`
- Trecho: `color: Colors.white.withValues(alpha: 0.86),`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-232 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:2249`
- Trecho: `color: Colors.white.withValues(alpha: 0.96),`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-233 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:2256`
- Trecho: `color: Colors.white.withValues(alpha: 0.34),`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-234 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:2262`
- Trecho: `color: Colors.white.withValues(alpha: 0.82),`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-235 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:2278`
- Trecho: `color: Colors.white.withValues(alpha: 0.82),`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-236 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:2282`
- Trecho: `fillColor: Colors.black.withValues(alpha: 0.28),`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-237 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:2286`
- Trecho: `color: Colors.white,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-238 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:2293`
- Trecho: `color: Colors.white.withValues(alpha: 0.94),`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-239 material_color_direct

- Evidencia: `app/lib/features/home/life_counter_screen.dart:2395`
- Trecho: `color: Colors.transparent,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-240 network_image_no_cache_abstraction

- Evidencia: `app/lib/features/home/home_screen.dart:682`
- Trecho: `return Image.network(`
- Impacto: Listas com imagens remotas podem recarregar sem cache dedicado e piorar scroll/percepcao de performance.
- Sugestao: Avaliar componente centralizado com cache, placeholder e tratamento de erro.

## Incertezas / medir depois

- Contraste real depende de renderizacao e tema ativo; validar com screenshot ou teste visual.
- Overflow e truncamento dependem de device, escala de fonte e dados reais; validar em telas pequenas com textScaleFactor alto.
- Estados empty/error/loading contextuais exigem revisar providers/API por fluxo, alem desta varredura estatica.

## Git status no momento da auditoria

```text
## codex/hermes-analysis-docs...origin/codex/hermes-analysis-docs
?? docs/hermes-analysis/FLUTTER_UI_AUDIT.md
```

UI_AUDIT_RESULT: findings=323 P0=0 P1=83 P2=240
