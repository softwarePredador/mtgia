# ManaLoom Premium Visual QA Gate

## Veredito automatico

`NOT_A_VISUAL_PASS`.

Este relatorio valida sinais objetivos de drift visual, mas nao substitui prova viva no iPhone Simulator. Proporcao de cards, poluicao visual, seam de imagem, legibilidade real e fidelidade ao mockup exigem revisar screenshots.

## Metadata

- Gerado em UTC: `2026-06-04T17:28:25.480923+00:00`
- Branch: `master`
- SHA: `f7324381`
- Config: `server/config/premium_visual_qa_surfaces.json`
- Arquivos auditados: `49`
- Life Counter incluido: `True`

## Fontes de verdade

- `docs/MANALOOM_VISUAL_EXECUTION_BASE_2026-04-19.md`
- `docs/qa/manaloom_layout_uniformity_audit_iphone15_2026-05-22.md`
- `app/doc/UI_TEST_SURFACE_MAP.md`

## Regras premium aplicadas

- Obsidian/slate surfaces; no loose bright/default Material surfaces.
- Brass is the primary action color; Frost is support/informational only.
- Cards use the same family as Meus Decks: dark surface, soft radius, restrained border/shadow, clear hierarchy.
- Display typography is reserved for brand/headers/deck identity; dense utility UI uses the app UI font.
- Buttons, tabs, chips, sheets and bottom navigation must use AppTheme tokens and consistent active/disabled states.
- No screen gets a visual pass from static analysis alone; iPhone Simulator screenshots are required for app-facing changes.

## Sumario de sinais

`signals=304 P1=0 P2=304`

### Por regra

- `material_color_direct`: 144 (mostrando 60)
- `radius_literal`: 78 (mostrando 60)
- `hardcoded_color_literal`: 71 (mostrando 60)
- `border_without_theme_token`: 50
- `possible_small_touch_or_visual_target`: 29
- `text_style_without_theme_token`: 22
- `container_decoration_without_theme_token`: 15
- `font_size_literal`: 6
- `button_style_direct_color`: 2

## Matriz por tela

| Surface | Capturas obrigatorias | Sinais | Foco de revisao |
| --- | --- | ---: | --- |
| Splash/Login/Cadastro | `00_splash`, `01_login`, `02_register_filled` | 3 | logo nova; splash/login coerentes; CTA brass; campos sem Material default; contraste em labels e placeholders |
| Home | `03_home` | 6 | hero art sem seam/transparencia indevida; card hero proporcional; quick actions consistentes; recent decks com cards da familia Meus Decks |
| Meus Decks | `04_decks` | 14 | baseline visual; grid/cards ricos; badges legiveis; filtros/tabs ativos; FAB/menus alinhados |
| Detalhes do Deck | `04b_deck_details` | 14 | tabs coerentes; cards de metricas; legibilidade de analise; CTA otimizar/adicionar; graficos sem ruido visual |
| Criar/Gerar/Importar Deck | `04a_create_deck_dialog`, `04c_deck_import`, `05_generate`, `06_generate_preview` | 5 | forms premium; hierarquia de preview; botoes primario/secundario; empty/error states; sem texto cru de backend |
| Busca/Detalhe/Adicionar Carta | `sets_search_01_cards_results`, `sets_search_02_card_detail`, `card_add_commander_choice_modal` | 9 | resultado identico ao mockup aprovado; modal comandante guiado; quantidade alinhada; texto de botoes; badges/sets legiveis |
| Colecao/Fichario/Marketplace | `08_collection`, `collection_01_binder`, `collection_02_marketplace`, `collection_04_sets_catalog`, `sets_search_04_set_detail` | 8 | menus nao deslocados; tabs e filtros alinhados; cards/empty states; editor modal; marketplace sem default colors |
| Trades/Mensagens/Notificacoes | `market_trade_05_trade_list`, `market_trade_08_trade_chat`, `messages_01_inbox`, `messages_02_conversation`, `market_trade_11_notifications` | 4 | status chips; linhas de conversa; unread badges; CTA/context menus; empty/loading/error states |
| Comunidade/Perfil | `07_community`, `09_profile`, `profile_community_02_user_profile`, `profile_community_05_community_deck_detail` | 14 | feed/cards; perfil proprio e publico; badges sociais; botoes seguir/editar; hierarquia de texto |
| Life Counter/Lotus | `life_counter_lotus`, `life_counter_card_search`, `life_counter_set_life`, `life_counter_player_appearance` | 227 | linguagem tabletop propria; contadores legiveis por jogador; overlays/settings; cores separaveis; touch targets em mesa |

## Comandos de prova viva obrigatoria

Substitua `<IPHONE_SIMULATOR_UDID>` pelo device atual de `flutter devices`. Para app-facing visual change, a captura deve passar e os screenshots devem ser revisados contra o checklist abaixo.

### non_life_counter

```bash
cd app && flutter test integration_test/app_full_non_life_counter_visual_capture_smoke_test.dart -d <IPHONE_SIMULATOR_UDID> --dart-define=API_BASE_URL=<API_BASE_URL> --dart-define=PUBLIC_API_BASE_URL=<PUBLIC_API_BASE_URL> --dart-define=DISABLE_FIREBASE_STARTUP=true --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true --reporter expanded --no-version-check
```

### life_counter

```bash
cd app && flutter test integration_test/life_counter_lotus_visual_capture_smoke_test.dart integration_test/life_counter_native_card_search_smoke_test.dart integration_test/life_counter_set_life_live_smoke_test.dart integration_test/life_counter_native_player_appearance_color_card_live_smoke_test.dart -d <IPHONE_SIMULATOR_UDID> --dart-define=API_BASE_URL=<API_BASE_URL> --dart-define=PUBLIC_API_BASE_URL=<PUBLIC_API_BASE_URL> --dart-define=DISABLE_FIREBASE_STARTUP=true --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true --reporter expanded --no-version-check
```

## Checklist de screenshot

- Proporcao: cards, hero, modais e listas ocupam area adequada sem sobras artificiais.
- Background: nao ha seam, transparencia indevida, bloco claro solto ou Material default.
- Cor: textos/botoes/tabs/chips seguem Obsidian/Brass/Frost; sem branco/preto/cinza Material indevido.
- Tipografia: headers usam display com intencao; formularios/listas usam UI font e escala AppTheme.
- Borda/raio: cards, inputs, sheets e modais usam a familia de Meus Decks.
- Hierarquia: CTA principal e claramente brass; secundarias ficam discretas.
- Densidade: tela nao fica poluida, nem vazia quando ha conteudo.
- Acessibilidade visual: contraste, tamanho de toque e truncamento sao legiveis no iPhone.

## Sinais detalhados

### P2

#### P2-001 radius_literal

- Surface: `auth`
- Evidencia: `app/lib/features/auth/widgets/auth_visual_shell.dart:130`
- Trecho: `borderRadius: BorderRadius.circular(30),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-002 radius_literal

- Surface: `auth`
- Evidencia: `app/lib/features/auth/widgets/auth_visual_shell.dart:143`
- Trecho: `borderRadius: BorderRadius.circular(26),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-003 radius_literal

- Surface: `auth`
- Evidencia: `app/lib/features/auth/widgets/auth_visual_shell.dart:207`
- Trecho: `borderRadius: BorderRadius.circular(26),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-004 possible_small_touch_or_visual_target

- Surface: `card_search`
- Evidencia: `app/lib/features/cards/screens/card_search_screen.dart:768`
- Trecho: `width: 38,`
- Impacto: Alvo ou elemento visual menor que 48 pode ficar dificil de tocar ou parecer desalinhado.
- Sugestao: Validar screenshot/touch target; elevar para bug se o alvo real ficar abaixo de 48x48.

#### P2-005 possible_small_touch_or_visual_target

- Surface: `card_search`
- Evidencia: `app/lib/features/cards/screens/card_search_screen.dart:769`
- Trecho: `height: 38,`
- Impacto: Alvo ou elemento visual menor que 48 pode ficar dificil de tocar ou parecer desalinhado.
- Sugestao: Validar screenshot/touch target; elevar para bug se o alvo real ficar abaixo de 48x48.

#### P2-006 possible_small_touch_or_visual_target

- Surface: `card_search`
- Evidencia: `app/lib/features/cards/screens/card_search_screen.dart:1236`
- Trecho: `width: 30,`
- Impacto: Alvo ou elemento visual menor que 48 pode ficar dificil de tocar ou parecer desalinhado.
- Sugestao: Validar screenshot/touch target; elevar para bug se o alvo real ficar abaixo de 48x48.

#### P2-007 possible_small_touch_or_visual_target

- Surface: `card_search`
- Evidencia: `app/lib/features/cards/screens/card_search_screen.dart:1237`
- Trecho: `height: 30,`
- Impacto: Alvo ou elemento visual menor que 48 pode ficar dificil de tocar ou parecer desalinhado.
- Sugestao: Validar screenshot/touch target; elevar para bug se o alvo real ficar abaixo de 48x48.

#### P2-008 radius_literal

- Surface: `card_search`
- Evidencia: `app/lib/features/cards/screens/card_search_screen.dart:267`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-009 radius_literal

- Surface: `card_search`
- Evidencia: `app/lib/features/cards/screens/card_search_screen.dart:329`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-010 radius_literal

- Surface: `card_search`
- Evidencia: `app/lib/features/cards/screens/card_search_screen.dart:580`
- Trecho: `borderRadius: BorderRadius.circular(99),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-011 text_style_without_theme_token

- Surface: `card_search`
- Evidencia: `app/lib/features/decks/widgets/deck_card_edit_dialog.dart:99`
- Trecho: `style: TextStyle(color: theme.colorScheme.error),`
- Impacto: TextStyle isolado facilita drift de tipografia, peso e cor.
- Sugestao: Preferir Theme.of(context).textTheme + copyWith usando AppTheme quando necessario.

#### P2-012 text_style_without_theme_token

- Surface: `card_search`
- Evidencia: `app/lib/features/decks/widgets/deck_card_edit_dialog.dart:199`
- Trecho: `style: TextStyle(color: theme.colorScheme.error),`
- Impacto: TextStyle isolado facilita drift de tipografia, peso e cor.
- Sugestao: Preferir Theme.of(context).textTheme + copyWith usando AppTheme quando necessario.

#### P2-013 border_without_theme_token

- Surface: `collection_binder_market`
- Evidencia: `app/lib/features/binder/screens/binder_screen.dart:452`
- Trecho: `border: Border.all(color: accent.withValues(alpha: 0.22)),`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-014 border_without_theme_token

- Surface: `collection_binder_market`
- Evidencia: `app/lib/features/binder/screens/binder_screen.dart:1010`
- Trecho: `border: Border.all(color: color.withValues(alpha: 0.22)),`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-015 border_without_theme_token

- Surface: `collection_binder_market`
- Evidencia: `app/lib/features/binder/screens/marketplace_screen.dart:714`
- Trecho: `border: Border.all(color: color.withValues(alpha: 0.25)),`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-016 possible_small_touch_or_visual_target

- Surface: `collection_binder_market`
- Evidencia: `app/lib/features/binder/screens/binder_screen.dart:1491`
- Trecho: `side: const BorderSide(color: AppTheme.outlineMuted, width: 0.5),`
- Impacto: Alvo ou elemento visual menor que 48 pode ficar dificil de tocar ou parecer desalinhado.
- Sugestao: Validar screenshot/touch target; elevar para bug se o alvo real ficar abaixo de 48x48.

#### P2-017 possible_small_touch_or_visual_target

- Surface: `collection_binder_market`
- Evidencia: `app/lib/features/binder/widgets/binder_item_editor.dart:1009`
- Trecho: `width: 36,`
- Impacto: Alvo ou elemento visual menor que 48 pode ficar dificil de tocar ou parecer desalinhado.
- Sugestao: Validar screenshot/touch target; elevar para bug se o alvo real ficar abaixo de 48x48.

#### P2-018 possible_small_touch_or_visual_target

- Surface: `collection_binder_market`
- Evidencia: `app/lib/features/binder/widgets/binder_item_editor.dart:1010`
- Trecho: `height: 36,`
- Impacto: Alvo ou elemento visual menor que 48 pode ficar dificil de tocar ou parecer desalinhado.
- Sugestao: Validar screenshot/touch target; elevar para bug se o alvo real ficar abaixo de 48x48.

#### P2-019 radius_literal

- Surface: `collection_binder_market`
- Evidencia: `app/lib/features/binder/widgets/binder_item_editor.dart:513`
- Trecho: `borderRadius: BorderRadius.circular(3),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-020 radius_literal

- Surface: `collection_binder_market`
- Evidencia: `app/lib/features/collection/screens/set_cards_screen.dart:391`
- Trecho: `borderRadius: BorderRadius.circular(8),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-021 border_without_theme_token

- Surface: `community_profile`
- Evidencia: `app/lib/features/community/screens/community_screen.dart:1073`
- Trecho: `border: Border.all(color: accent.withValues(alpha: 0.26)),`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-022 border_without_theme_token

- Surface: `community_profile`
- Evidencia: `app/lib/features/community/screens/community_screen.dart:1533`
- Trecho: `? Border.all(`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-023 border_without_theme_token

- Surface: `community_profile`
- Evidencia: `app/lib/features/community/screens/community_screen.dart:1665`
- Trecho: `border: Border.all(`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-024 possible_small_touch_or_visual_target

- Surface: `community_profile`
- Evidencia: `app/lib/features/community/screens/community_deck_detail_screen.dart:93`
- Trecho: `width: 20,`
- Impacto: Alvo ou elemento visual menor que 48 pode ficar dificil de tocar ou parecer desalinhado.
- Sugestao: Validar screenshot/touch target; elevar para bug se o alvo real ficar abaixo de 48x48.

#### P2-025 possible_small_touch_or_visual_target

- Surface: `community_profile`
- Evidencia: `app/lib/features/community/screens/community_deck_detail_screen.dart:94`
- Trecho: `height: 20,`
- Impacto: Alvo ou elemento visual menor que 48 pode ficar dificil de tocar ou parecer desalinhado.
- Sugestao: Validar screenshot/touch target; elevar para bug se o alvo real ficar abaixo de 48x48.

#### P2-026 possible_small_touch_or_visual_target

- Surface: `community_profile`
- Evidencia: `app/lib/features/profile/profile_screen.dart:292`
- Trecho: `width: 2,`
- Impacto: Alvo ou elemento visual menor que 48 pode ficar dificil de tocar ou parecer desalinhado.
- Sugestao: Validar screenshot/touch target; elevar para bug se o alvo real ficar abaixo de 48x48.

#### P2-027 possible_small_touch_or_visual_target

- Surface: `community_profile`
- Evidencia: `app/lib/features/social/screens/user_profile_screen.dart:464`
- Trecho: `side: const BorderSide(color: AppTheme.outlineMuted, width: 0.5),`
- Impacto: Alvo ou elemento visual menor que 48 pode ficar dificil de tocar ou parecer desalinhado.
- Sugestao: Validar screenshot/touch target; elevar para bug se o alvo real ficar abaixo de 48x48.

#### P2-028 possible_small_touch_or_visual_target

- Surface: `community_profile`
- Evidencia: `app/lib/features/social/screens/user_profile_screen.dart:1205`
- Trecho: `side: const BorderSide(color: AppTheme.outlineMuted, width: 0.5),`
- Impacto: Alvo ou elemento visual menor que 48 pode ficar dificil de tocar ou parecer desalinhado.
- Sugestao: Validar screenshot/touch target; elevar para bug se o alvo real ficar abaixo de 48x48.

#### P2-029 radius_literal

- Surface: `community_profile`
- Evidencia: `app/lib/features/community/screens/community_screen.dart:210`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-030 radius_literal

- Surface: `community_profile`
- Evidencia: `app/lib/features/community/screens/community_screen.dart:216`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-031 radius_literal

- Surface: `community_profile`
- Evidencia: `app/lib/features/community/screens/community_screen.dart:222`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-032 radius_literal

- Surface: `community_profile`
- Evidencia: `app/lib/features/community/screens/community_screen.dart:629`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-033 radius_literal

- Surface: `community_profile`
- Evidencia: `app/lib/features/community/screens/community_screen.dart:635`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-034 radius_literal

- Surface: `community_profile`
- Evidencia: `app/lib/features/community/screens/community_screen.dart:641`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-035 border_without_theme_token

- Surface: `deck_create_generate_import`
- Evidencia: `app/lib/features/decks/screens/deck_generate_screen.dart:846`
- Trecho: `border: Border.all(color: theme.colorScheme.outline),`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-036 border_without_theme_token

- Surface: `deck_create_generate_import`
- Evidencia: `app/lib/features/decks/screens/deck_generate_screen.dart:917`
- Trecho: `border: Border.all(color: theme.colorScheme.outline),`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-037 border_without_theme_token

- Surface: `deck_create_generate_import`
- Evidencia: `app/lib/features/decks/screens/deck_generate_screen.dart:950`
- Trecho: `border: Border.all(color: theme.colorScheme.outline),`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-038 border_without_theme_token

- Surface: `deck_create_generate_import`
- Evidencia: `app/lib/features/decks/widgets/deck_optimize_sheet_widgets.dart:35`
- Trecho: `border: Border.all(color: accent.withValues(alpha: 0.24), width: 0.8),`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-039 possible_small_touch_or_visual_target

- Surface: `deck_create_generate_import`
- Evidencia: `app/lib/features/decks/widgets/deck_optimize_sheet_widgets.dart:101`
- Trecho: `side: BorderSide(color: accent.withValues(alpha: 0.22), width: 0.8),`
- Impacto: Alvo ou elemento visual menor que 48 pode ficar dificil de tocar ou parecer desalinhado.
- Sugestao: Validar screenshot/touch target; elevar para bug se o alvo real ficar abaixo de 48x48.

#### P2-040 border_without_theme_token

- Surface: `deck_details`
- Evidencia: `app/lib/features/decks/screens/deck_details_screen.dart:420`
- Trecho: `border: Border.all(`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-041 border_without_theme_token

- Surface: `deck_details`
- Evidencia: `app/lib/features/decks/screens/deck_details_screen.dart:896`
- Trecho: `border: borderColor != null ? Border.all(color: borderColor) : null,`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-042 border_without_theme_token

- Surface: `deck_details`
- Evidencia: `app/lib/features/decks/widgets/deck_analysis_tab.dart:574`
- Trecho: `border: Border.all(color: accent.withValues(alpha: 0.42)),`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-043 border_without_theme_token

- Surface: `deck_details`
- Evidencia: `app/lib/features/decks/widgets/deck_analysis_tab.dart:1099`
- Trecho: `border: Border.all(`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-044 border_without_theme_token

- Surface: `deck_details`
- Evidencia: `app/lib/features/decks/widgets/deck_analysis_tab.dart:1509`
- Trecho: `border: Border.all(color: accent.withValues(alpha: 0.18), width: 0.7),`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-045 border_without_theme_token

- Surface: `deck_details`
- Evidencia: `app/lib/features/decks/widgets/deck_analysis_tab.dart:1594`
- Trecho: `border: Border.all(color: color.withValues(alpha: 0.18), width: 0.7),`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-046 border_without_theme_token

- Surface: `deck_details`
- Evidencia: `app/lib/features/decks/widgets/deck_details_aux_widgets.dart:65`
- Trecho: `border: Border.all(`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-047 border_without_theme_token

- Surface: `deck_details`
- Evidencia: `app/lib/features/decks/widgets/deck_details_overview_tab.dart:654`
- Trecho: `border: Border.all(color: accent.withValues(alpha: 0.22)),`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-048 border_without_theme_token

- Surface: `deck_details`
- Evidencia: `app/lib/features/decks/widgets/deck_details_overview_tab.dart:879`
- Trecho: `border: Border.all(color: accent.withValues(alpha: 0.28), width: 0.9),`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-049 border_without_theme_token

- Surface: `deck_details`
- Evidencia: `app/lib/features/decks/widgets/deck_details_overview_tab.dart:1017`
- Trecho: `border: Border.all(color: issue.accent.withValues(alpha: 0.22)),`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-050 border_without_theme_token

- Surface: `deck_details`
- Evidencia: `app/lib/features/decks/widgets/deck_details_overview_tab.dart:1111`
- Trecho: `border: Border.all(color: color.withValues(alpha: 0.24)),`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-051 border_without_theme_token

- Surface: `deck_details`
- Evidencia: `app/lib/features/decks/widgets/deck_details_overview_tab.dart:1377`
- Trecho: `border: Border.all(`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-052 possible_small_touch_or_visual_target

- Surface: `deck_details`
- Evidencia: `app/lib/features/decks/widgets/deck_details_overview_tab.dart:1205`
- Trecho: `height: 1.35,`
- Impacto: Alvo ou elemento visual menor que 48 pode ficar dificil de tocar ou parecer desalinhado.
- Sugestao: Validar screenshot/touch target; elevar para bug se o alvo real ficar abaixo de 48x48.

#### P2-053 radius_literal

- Surface: `deck_details`
- Evidencia: `app/lib/features/decks/screens/deck_details_screen.dart:742`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-054 border_without_theme_token

- Surface: `decks`
- Evidencia: `app/lib/features/decks/widgets/deck_ui_components.dart:87`
- Trecho: `border: Border.all(color: accent.withValues(alpha: 0.2), width: 0.8),`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-055 border_without_theme_token

- Surface: `decks`
- Evidencia: `app/lib/features/decks/widgets/deck_ui_components.dart:138`
- Trecho: `border: Border.all(color: color.withValues(alpha: 0.28), width: 0.7),`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-056 border_without_theme_token

- Surface: `decks`
- Evidencia: `app/lib/features/decks/widgets/deck_ui_components.dart:294`
- Trecho: `border: Border.all(`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-057 possible_small_touch_or_visual_target

- Surface: `decks`
- Evidencia: `app/lib/features/decks/widgets/deck_card.dart:79`
- Trecho: `border: Border.all(color: AppTheme.outlineMuted, width: 0.5),`
- Impacto: Alvo ou elemento visual menor que 48 pode ficar dificil de tocar ou parecer desalinhado.
- Sugestao: Validar screenshot/touch target; elevar para bug se o alvo real ficar abaixo de 48x48.

#### P2-058 radius_literal

- Surface: `decks`
- Evidencia: `app/lib/features/decks/screens/deck_list_screen.dart:440`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-059 radius_literal

- Surface: `decks`
- Evidencia: `app/lib/features/decks/screens/deck_list_screen.dart:488`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-060 radius_literal

- Surface: `decks`
- Evidencia: `app/lib/features/decks/screens/deck_list_screen.dart:958`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-061 radius_literal

- Surface: `decks`
- Evidencia: `app/lib/features/decks/screens/deck_list_screen.dart:964`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-062 radius_literal

- Surface: `decks`
- Evidencia: `app/lib/features/decks/screens/deck_list_screen.dart:1240`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-063 radius_literal

- Surface: `decks`
- Evidencia: `app/lib/features/decks/screens/deck_list_screen.dart:1273`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-064 radius_literal

- Surface: `decks`
- Evidencia: `app/lib/features/decks/widgets/deck_card.dart:294`
- Trecho: `borderRadius: BorderRadius.circular(2),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-065 text_style_without_theme_token

- Surface: `decks`
- Evidencia: `app/lib/features/decks/screens/deck_list_screen.dart:1215`
- Trecho: `style: TextStyle(color: Theme.of(context).colorScheme.error),`
- Impacto: TextStyle isolado facilita drift de tipografia, peso e cor.
- Sugestao: Preferir Theme.of(context).textTheme + copyWith usando AppTheme quando necessario.

#### P2-066 text_style_without_theme_token

- Surface: `decks`
- Evidencia: `app/lib/features/decks/screens/deck_list_screen.dart:1614`
- Trecho: `style: TextStyle(color: Theme.of(context).colorScheme.error),`
- Impacto: TextStyle isolado facilita drift de tipografia, peso e cor.
- Sugestao: Preferir Theme.of(context).textTheme + copyWith usando AppTheme quando necessario.

#### P2-067 text_style_without_theme_token

- Surface: `decks`
- Evidencia: `app/lib/features/decks/widgets/deck_card.dart:443`
- Trecho: `Text('Excluir', style: TextStyle(color: theme.colorScheme.error)),`
- Impacto: TextStyle isolado facilita drift de tipografia, peso e cor.
- Sugestao: Preferir Theme.of(context).textTheme + copyWith usando AppTheme quando necessario.

#### P2-068 border_without_theme_token

- Surface: `home`
- Evidencia: `app/lib/features/home/home_screen.dart:452`
- Trecho: `border: Border.all(`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-069 border_without_theme_token

- Surface: `home`
- Evidencia: `app/lib/features/home/home_screen.dart:959`
- Trecho: `border: Border.all(color: data.color.withValues(alpha: 0.16)),`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-070 possible_small_touch_or_visual_target

- Surface: `home`
- Evidencia: `app/lib/features/home/home_screen.dart:577`
- Trecho: `width: 28,`
- Impacto: Alvo ou elemento visual menor que 48 pode ficar dificil de tocar ou parecer desalinhado.
- Sugestao: Validar screenshot/touch target; elevar para bug se o alvo real ficar abaixo de 48x48.

#### P2-071 possible_small_touch_or_visual_target

- Surface: `home`
- Evidencia: `app/lib/features/home/home_screen.dart:578`
- Trecho: `height: 28,`
- Impacto: Alvo ou elemento visual menor que 48 pode ficar dificil de tocar ou parecer desalinhado.
- Sugestao: Validar screenshot/touch target; elevar para bug se o alvo real ficar abaixo de 48x48.

#### P2-072 radius_literal

- Surface: `home`
- Evidencia: `app/lib/features/home/home_screen.dart:316`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-073 radius_literal

- Surface: `home`
- Evidencia: `app/lib/features/home/home_screen.dart:632`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-074 border_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1578`
- Trecho: `border: Border.all(`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-075 border_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1611`
- Trecho: `border: Border.all(`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-076 border_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1802`
- Trecho: `border: Border.all(`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-077 border_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2038`
- Trecho: `border: Border.all(`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-078 border_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2494`
- Trecho: `border: Border.all(`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-079 border_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2583`
- Trecho: `border: Border.all(`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-080 border_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:3764`
- Trecho: `border: Border.all(`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-081 border_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:3902`
- Trecho: `border: Border.all(color: borderColor, width: 0.9),`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-082 border_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:4074`
- Trecho: `border: Border.all(`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-083 border_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:4212`
- Trecho: `border: Border.all(`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-084 border_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:4296`
- Trecho: `border: Border.all(`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-085 border_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:4441`
- Trecho: `border: Border.all(`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-086 border_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:4545`
- Trecho: `border: Border.all(`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-087 border_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:5038`
- Trecho: `border: Border.all(color: borderColor, width: 2),`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-088 border_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:5557`
- Trecho: `border: Border.all(`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-089 border_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:5582`
- Trecho: `border: Border.all(`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-090 border_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:5755`
- Trecho: `border: Border.all(`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-091 border_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:6582`
- Trecho: `border: Border.all(color: Colors.white, width: 2),`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-092 border_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:6625`
- Trecho: `border: Border.all(`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-093 border_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:6674`
- Trecho: `border: Border.all(`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-094 button_style_direct_color

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart:396`
- Trecho: `style: OutlinedButton.styleFrom(`
- Impacto: Botao do Life Counter com cor direta precisa de revisao de contraste e consistencia tabletop.
- Sugestao: Centralizar em paleta do Life Counter ou justificar com screenshot.

#### P2-095 button_style_direct_color

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart:445`
- Trecho: `style: FilledButton.styleFrom(`
- Impacto: Botao do Life Counter com cor direta precisa de revisao de contraste e consistencia tabletop.
- Sugestao: Centralizar em paleta do Life Counter ou justificar com screenshot.

#### P2-096 container_decoration_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1555`
- Trecho: `Container(`
- Impacto: Container decorado sem token e uma fonte comum de background/borda/sombra destoante.
- Sugestao: Migrar decoracao para componente/tokens ou revisar em screenshot.

#### P2-097 container_decoration_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1571`
- Trecho: `AnimatedContainer(`
- Impacto: Container decorado sem token e uma fonte comum de background/borda/sombra destoante.
- Sugestao: Migrar decoracao para componente/tokens ou revisar em screenshot.

#### P2-098 container_decoration_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1606`
- Trecho: `Container(`
- Impacto: Container decorado sem token e uma fonte comum de background/borda/sombra destoante.
- Sugestao: Migrar decoracao para componente/tokens ou revisar em screenshot.

#### P2-099 container_decoration_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2073`
- Trecho: `child: Container(`
- Impacto: Container decorado sem token e uma fonte comum de background/borda/sombra destoante.
- Sugestao: Migrar decoracao para componente/tokens ou revisar em screenshot.

#### P2-100 container_decoration_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2095`
- Trecho: `children: [tile(color: tileAlt), Expanded(child: Container())],`
- Impacto: Container decorado sem token e uma fonte comum de background/borda/sombra destoante.
- Sugestao: Migrar decoracao para componente/tokens ou revisar em screenshot.

#### P2-101 container_decoration_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2104`
- Trecho: `return Container(`
- Impacto: Container decorado sem token e uma fonte comum de background/borda/sombra destoante.
- Sugestao: Migrar decoracao para componente/tokens ou revisar em screenshot.

#### P2-102 container_decoration_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2501`
- Trecho: `Container(`
- Impacto: Container decorado sem token e uma fonte comum de background/borda/sombra destoante.
- Sugestao: Migrar decoracao para componente/tokens ou revisar em screenshot.

#### P2-103 container_decoration_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2577`
- Trecho: `return Container(`
- Impacto: Container decorado sem token e uma fonte comum de background/borda/sombra destoante.
- Sugestao: Migrar decoracao para componente/tokens ou revisar em screenshot.

#### P2-104 container_decoration_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:4276`
- Trecho: `child: Container(`
- Impacto: Container decorado sem token e uma fonte comum de background/borda/sombra destoante.
- Sugestao: Migrar decoracao para componente/tokens ou revisar em screenshot.

#### P2-105 container_decoration_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:4419`
- Trecho: `child: Container(`
- Impacto: Container decorado sem token e uma fonte comum de background/borda/sombra destoante.
- Sugestao: Migrar decoracao para componente/tokens ou revisar em screenshot.

#### P2-106 container_decoration_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:4539`
- Trecho: `child: Container(`
- Impacto: Container decorado sem token e uma fonte comum de background/borda/sombra destoante.
- Sugestao: Migrar decoracao para componente/tokens ou revisar em screenshot.

#### P2-107 container_decoration_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:5551`
- Trecho: `Container(`
- Impacto: Container decorado sem token e uma fonte comum de background/borda/sombra destoante.
- Sugestao: Migrar decoracao para componente/tokens ou revisar em screenshot.

#### P2-108 container_decoration_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:5572`
- Trecho: `Container(`
- Impacto: Container decorado sem token e uma fonte comum de background/borda/sombra destoante.
- Sugestao: Migrar decoracao para componente/tokens ou revisar em screenshot.

#### P2-109 container_decoration_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:6577`
- Trecho: `Container(`
- Impacto: Container decorado sem token e uma fonte comum de background/borda/sombra destoante.
- Sugestao: Migrar decoracao para componente/tokens ou revisar em screenshot.

#### P2-110 container_decoration_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:6668`
- Trecho: `Container(`
- Impacto: Container decorado sem token e uma fonte comum de background/borda/sombra destoante.
- Sugestao: Migrar decoracao para componente/tokens ou revisar em screenshot.

#### P2-111 font_size_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart:203`
- Trecho: `fontSize: 72,`
- Impacto: Tamanho de fonte literal pode quebrar escala tipografica entre telas.
- Sugestao: Trocar por AppTheme.fontMicro/fontXs/fontSm/fontMd/fontLg/fontXl/fontXxl/fontDisplay.

#### P2-112 font_size_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1826`
- Trecho: `fontSize: 13.4 * scaleFactor,`
- Impacto: Tamanho de fonte literal pode quebrar escala tipografica entre telas.
- Sugestao: Trocar por AppTheme.fontMicro/fontXs/fontSm/fontMd/fontLg/fontXl/fontXxl/fontDisplay.

#### P2-113 font_size_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1922`
- Trecho: `fontSize: 24,`
- Impacto: Tamanho de fonte literal pode quebrar escala tipografica entre telas.
- Sugestao: Trocar por AppTheme.fontMicro/fontXs/fontSm/fontMd/fontLg/fontXl/fontXxl/fontDisplay.

#### P2-114 font_size_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2192`
- Trecho: `fontSize: 22,`
- Impacto: Tamanho de fonte literal pode quebrar escala tipografica entre telas.
- Sugestao: Trocar por AppTheme.fontMicro/fontXs/fontSm/fontMd/fontLg/fontXl/fontXxl/fontDisplay.

#### P2-115 font_size_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:5273`
- Trecho: `fontSize: 72,`
- Impacto: Tamanho de fonte literal pode quebrar escala tipografica entre telas.
- Sugestao: Trocar por AppTheme.fontMicro/fontXs/fontSm/fontMd/fontLg/fontXl/fontXxl/fontDisplay.

#### P2-116 font_size_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:5608`
- Trecho: `fontSize: 76,`
- Impacto: Tamanho de fonte literal pode quebrar escala tipografica entre telas.
- Sugestao: Trocar por AppTheme.fontMicro/fontXs/fontSm/fontMd/fontLg/fontXl/fontXxl/fontDisplay.

#### P2-117 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_card_search_sheet.dart:82`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-118 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_dice_sheet.dart:83`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-119 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_player_appearance_sheet.dart:445`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-120 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_player_appearance_sheet.dart:933`
- Trecho: `color: Color(0x33000000),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-121 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_player_state_sheet.dart:229`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-122 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart:129`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-123 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart:399`
- Trecho: `? const Color(0xFFFF7A9C)`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-124 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart:404`
- Trecho: `? const Color(0x66FF2C77)`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-125 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart:448`
- Trecho: `? const Color(0x33FF2C77)`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-126 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart:451`
- Trecho: `destructive ? const Color(0xFFFF5E9A) : AppTheme.textPrimary,`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-127 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart:457`
- Trecho: `? const Color(0x66FF2C77)`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-128 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_settings_sheet.dart:78`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-129 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:108`
- Trecho: `Color(0xFFFFB51E),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-130 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:109`
- Trecho: `Color(0xFFFF0A5B),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-131 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:110`
- Trecho: `Color(0xFFCF7AEF),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-132 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:111`
- Trecho: `Color(0xFF4B57FF),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-133 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:112`
- Trecho: `Color(0xFF44E063),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-134 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:113`
- Trecho: `Color(0xFF40B9FF),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-135 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:906`
- Trecho: `decoration: BoxDecoration(color: Color(0xA6000000)),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-136 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1332`
- Trecho: `color: Color(0xFF44E063),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-137 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1339`
- Trecho: `color: Color(0xFFFFE277),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-138 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1346`
- Trecho: `color: Color(0xFF40B9FF),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-139 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1353`
- Trecho: `color: Color(0xFFB9B4FF),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-140 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1621`
- Trecho: `color: const Color(0xFF0D1117),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-141 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1658`
- Trecho: `colors: [Color(0xFF04070E), Color(0xFF121A2B)],`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-142 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1667`
- Trecho: `colors: [Color(0xFFEAFDFF), Color(0xFFB9D7FF)],`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-143 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1679`
- Trecho: `colors: [Color(0xFFFDF4FF), Color(0xFFD7EDFF)],`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-144 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1962`
- Trecho: `color: Color(0xFFFF2C77),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-145 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2036`
- Trecho: `color: selected ? const Color(0xFFFF2C77) : Colors.transparent,`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-146 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2041`
- Trecho: `? const Color(0xFFFF2C77)`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-147 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2332`
- Trecho: `color: Color(0xFF40B9FF),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-148 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2581`
- Trecho: `color: const Color(0xFFF7F4EC),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-149 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:3060`
- Trecho: `? const Color(0xFF4A3A12)`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-150 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:3062`
- Trecho: `? const Color(0xFF1D1D1D)`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-151 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:3064`
- Trecho: `? const Color(0xFF5B3A6C)`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-152 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:3066`
- Trecho: `? const Color(0xFF341217)`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-153 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:3068`
- Trecho: `? const Color(0xFF122A18)`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-154 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:3438`
- Trecho: `? const Color(0xFF2F2407)`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-155 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:3440`
- Trecho: `? const Color(0xFF121212)`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-156 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:3442`
- Trecho: `? const Color(0xFF1D1025)`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-157 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:3444`
- Trecho: `? const Color(0xFF2B090F)`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-158 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:3445`
- Trecho: `: const Color(0xFF0C2414),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-159 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:3448`
- Trecho: `? const Color(0xFFFFD36A)`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-160 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:3450`
- Trecho: `? const Color(0xFFEDEDED)`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-161 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:3452`
- Trecho: `? const Color(0xFFFF5AA9)`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-162 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:3454`
- Trecho: `? const Color(0xFFFF5B61)`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-163 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:3455`
- Trecho: `: const Color(0xFF6BFF8D),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-164 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:3834`
- Trecho: `accent: const Color(0xFF6BFF8D),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-165 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:3853`
- Trecho: `: const Color(0xFFFFB3A8),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-166 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:4178`
- Trecho: `Color(0xFFFF9CD1),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-167 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:4179`
- Trecho: `Color(0xFFFFF5A3),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-168 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:4180`
- Trecho: `Color(0xFFB7FFBE),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-169 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:4181`
- Trecho: `Color(0xFFB5C8FF),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-170 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:4188`
- Trecho: `colors: [Color(0xFFFFC55A), Color(0xFFFFE596), Color(0xFFFFB764)],`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-171 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:4485`
- Trecho: `Color(0xFFFF4C7D),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-172 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:4486`
- Trecho: `Color(0xFF4A5BFF),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-173 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:4487`
- Trecho: `Color(0xFFFFC552),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-174 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:4488`
- Trecho: `Color(0xFF5BDF79),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-175 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:4489`
- Trecho: `Color(0xFFFFFFFF),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-176 hardcoded_color_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:4809`
- Trecho: `accent: const Color(0xFF40B9FF),`
- Impacto: Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter.
- Sugestao: Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual.

#### P2-177 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_card_search_sheet.dart:18`
- Trecho: `backgroundColor: Colors.transparent,`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-178 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_card_search_sheet.dart:309`
- Trecho: `color: Colors.transparent,`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-179 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_card_search_sheet.dart:353`
- Trecho: `color: Colors.transparent,`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-180 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_dice_sheet.dart:18`
- Trecho: `backgroundColor: Colors.transparent,`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-181 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_player_appearance_sheet.dart:40`
- Trecho: `backgroundColor: Colors.transparent,`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-182 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_player_appearance_sheet.dart:818`
- Trecho: `color.computeLuminance() > 0.55 ? Colors.black : Colors.white;`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-183 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_player_appearance_sheet.dart:906`
- Trecho: `color.computeLuminance() > 0.55 ? Colors.black : Colors.white;`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-184 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_player_appearance_sheet.dart:926`
- Trecho: `color: selected ? AppTheme.textPrimary : Colors.transparent,`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-185 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_player_state_sheet.dart:22`
- Trecho: `backgroundColor: Colors.transparent,`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-186 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart:15`
- Trecho: `backgroundColor: Colors.transparent,`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-187 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart:184`
- Trecho: `color: Colors.white.withValues(alpha: 0.28),`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-188 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart:202`
- Trecho: `color: Colors.white,`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-189 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_settings_sheet.dart:14`
- Trecho: `backgroundColor: Colors.transparent,`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-190 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:551`
- Trecho: `barrierColor: Colors.black.withValues(alpha: 0.72),`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-191 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:879`
- Trecho: `backgroundColor: Colors.black,`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-192 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:888`
- Trecho: `color: Colors.black,`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-193 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1442`
- Trecho: `color: Colors.white.withValues(alpha: 0.76),`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-194 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1500`
- Trecho: `color: Colors.transparent,`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-195 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1540`
- Trecho: `color: Colors.transparent,`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-196 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1579`
- Trecho: `color: Colors.white.withValues(`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-197 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1586`
- Trecho: `color: Colors.black.withValues(alpha: 0.24),`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-198 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1612`
- Trecho: `color: Colors.white.withValues(`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-199 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1625`
- Trecho: `color: Colors.white.withValues(alpha: 0.36),`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-200 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1685`
- Trecho: `..color = Colors.black.withValues(alpha: 0.1)`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-201 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1720`
- Trecho: `colors: [Colors.white.withValues(alpha: 0.18), Colors.transparent],`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-202 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1744`
- Trecho: `..color = Colors.white.withValues(alpha: 0.28 + (0.12 * progress))`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-203 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1774`
- Trecho: `final topTint = Color.lerp(color, Colors.white, 0.2) ?? color;`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-204 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1775`
- Trecho: `final bottomTint = Color.lerp(color, Colors.black, 0.12) ?? color;`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-205 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1803`
- Trecho: `color: Colors.black.withValues(alpha: 0.2 * visualOpacity),`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-206 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1808`
- Trecho: `color: Colors.white.withValues(alpha: 0.1 * visualOpacity),`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-207 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1823`
- Trecho: `color: Colors.black.withValues(`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-208 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1897`
- Trecho: `color: Colors.transparent,`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-209 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1921`
- Trecho: `color: Colors.white.withValues(alpha: 0.98),`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-210 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1932`
- Trecho: `color: Colors.white.withValues(alpha: 0.66),`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-211 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1954`
- Trecho: `color: Colors.transparent,`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-212 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1967`
- Trecho: `color: Colors.white,`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-213 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1995`
- Trecho: `color: Colors.white.withValues(alpha: 0.86),`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-214 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2028`
- Trecho: `color: Colors.transparent,`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-215 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2036`
- Trecho: `color: selected ? const Color(0xFFFF2C77) : Colors.transparent,`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-216 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2042`
- Trecho: `: Colors.white.withValues(alpha: 0.9),`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-217 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2065`
- Trecho: `final tileColor = playerCount >= 4 ? Colors.black : Colors.white;`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-218 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2068`
- Trecho: `? Colors.black.withValues(alpha: 0.82)`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-219 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2069`
- Trecho: `: Colors.white.withValues(alpha: 0.9);`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-220 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2178`
- Trecho: `color: Colors.white.withValues(alpha: 0.9),`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-221 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2191`
- Trecho: `color: Colors.white.withValues(alpha: 0.72),`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-222 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2213`
- Trecho: `color: Colors.white.withValues(alpha: 0.86),`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-223 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2280`
- Trecho: `color: Colors.white.withValues(alpha: 0.96),`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-224 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2287`
- Trecho: `color: Colors.white.withValues(alpha: 0.34),`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-225 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2293`
- Trecho: `color: Colors.white.withValues(alpha: 0.82),`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-226 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2310`
- Trecho: `color: Colors.white.withValues(alpha: 0.82),`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-227 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2314`
- Trecho: `fillColor: Colors.black.withValues(alpha: 0.28),`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-228 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2318`
- Trecho: `color: Colors.white,`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-229 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2325`
- Trecho: `color: Colors.white.withValues(alpha: 0.94),`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-230 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2434`
- Trecho: `color: Colors.transparent,`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-231 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2441`
- Trecho: `color: Colors.black.withValues(alpha: 0.22),`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-232 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2444`
- Trecho: `color: Colors.white.withValues(alpha: 0.94),`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-233 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2451`
- Trecho: `color: Colors.white.withValues(alpha: 0.86),`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-234 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2481`
- Trecho: `color: Colors.transparent,`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-235 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2492`
- Trecho: `color: Colors.black.withValues(alpha: 0.24),`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-236 material_color_direct

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2495`
- Trecho: `color: Colors.white.withValues(alpha: 0.94),`
- Impacto: Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores.
- Sugestao: Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa.

#### P2-237 possible_small_touch_or_visual_target

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_card_search_sheet.dart:113`
- Trecho: `height: 1.35,`
- Impacto: Alvo ou elemento visual menor que 48 pode ficar dificil de tocar ou parecer desalinhado.
- Sugestao: Validar screenshot/touch target; elevar para bug se o alvo real ficar abaixo de 48x48.

#### P2-238 possible_small_touch_or_visual_target

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_dice_sheet.dart:114`
- Trecho: `height: 1.35,`
- Impacto: Alvo ou elemento visual menor que 48 pode ficar dificil de tocar ou parecer desalinhado.
- Sugestao: Validar screenshot/touch target; elevar para bug se o alvo real ficar abaixo de 48x48.

#### P2-239 possible_small_touch_or_visual_target

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_player_appearance_sheet.dart:476`
- Trecho: `height: 1.35,`
- Impacto: Alvo ou elemento visual menor que 48 pode ficar dificil de tocar ou parecer desalinhado.
- Sugestao: Validar screenshot/touch target; elevar para bug se o alvo real ficar abaixo de 48x48.

#### P2-240 possible_small_touch_or_visual_target

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_player_state_sheet.dart:260`
- Trecho: `height: 1.35,`
- Impacto: Alvo ou elemento visual menor que 48 pode ficar dificil de tocar ou parecer desalinhado.
- Sugestao: Validar screenshot/touch target; elevar para bug se o alvo real ficar abaixo de 48x48.

#### P2-241 possible_small_touch_or_visual_target

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart:160`
- Trecho: `height: 1.35,`
- Impacto: Alvo ou elemento visual menor que 48 pode ficar dificil de tocar ou parecer desalinhado.
- Sugestao: Validar screenshot/touch target; elevar para bug se o alvo real ficar abaixo de 48x48.

#### P2-242 possible_small_touch_or_visual_target

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_settings_sheet.dart:109`
- Trecho: `height: 1.35,`
- Impacto: Alvo ou elemento visual menor que 48 pode ficar dificil de tocar ou parecer desalinhado.
- Sugestao: Validar screenshot/touch target; elevar para bug se o alvo real ficar abaixo de 48x48.

#### P2-243 possible_small_touch_or_visual_target

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1791`
- Trecho: `height: 40 * scaleFactor,`
- Impacto: Alvo ou elemento visual menor que 48 pode ficar dificil de tocar ou parecer desalinhado.
- Sugestao: Validar screenshot/touch target; elevar para bug se o alvo real ficar abaixo de 48x48.

#### P2-244 possible_small_touch_or_visual_target

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:6440`
- Trecho: `width: 44,`
- Impacto: Alvo ou elemento visual menor que 48 pode ficar dificil de tocar ou parecer desalinhado.
- Sugestao: Validar screenshot/touch target; elevar para bug se o alvo real ficar abaixo de 48x48.

#### P2-245 possible_small_touch_or_visual_target

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:6441`
- Trecho: `height: 44,`
- Impacto: Alvo ou elemento visual menor que 48 pode ficar dificil de tocar ou parecer desalinhado.
- Sugestao: Validar screenshot/touch target; elevar para bug se o alvo real ficar abaixo de 48x48.

#### P2-246 possible_small_touch_or_visual_target

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:6620`
- Trecho: `width: 46,`
- Impacto: Alvo ou elemento visual menor que 48 pode ficar dificil de tocar ou parecer desalinhado.
- Sugestao: Validar screenshot/touch target; elevar para bug se o alvo real ficar abaixo de 48x48.

#### P2-247 possible_small_touch_or_visual_target

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:6621`
- Trecho: `height: 46,`
- Impacto: Alvo ou elemento visual menor que 48 pode ficar dificil de tocar ou parecer desalinhado.
- Sugestao: Validar screenshot/touch target; elevar para bug se o alvo real ficar abaixo de 48x48.

#### P2-248 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_card_search_sheet.dart:311`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-249 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_card_search_sheet.dart:317`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-250 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_card_search_sheet.dart:355`
- Trecho: `borderRadius: BorderRadius.circular(18),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-251 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_card_search_sheet.dart:365`
- Trecho: `borderRadius: BorderRadius.circular(16),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-252 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_card_search_sheet.dart:375`
- Trecho: `borderRadius: BorderRadius.circular(10),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-253 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_dice_sheet.dart:346`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-254 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_dice_sheet.dart:398`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-255 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart:453`
- Trecho: `borderRadius: BorderRadius.circular(20),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-256 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1502`
- Trecho: `borderRadius: BorderRadius.circular(radius),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-257 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1543`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-258 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1787`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-259 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1801`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-260 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1956`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-261 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2031`
- Trecho: `borderRadius: BorderRadius.circular(28),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-262 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2037`
- Trecho: `borderRadius: BorderRadius.circular(28),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-263 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2077`
- Trecho: `borderRadius: BorderRadius.circular(10),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-264 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2108`
- Trecho: `borderRadius: BorderRadius.circular(10),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-265 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2316`
- Trecho: `borderRadius: BorderRadius.circular(16),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-266 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2323`
- Trecho: `borderRadius: BorderRadius.circular(16),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-267 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2330`
- Trecho: `borderRadius: BorderRadius.circular(16),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-268 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2436`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-269 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2442`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-270 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2483`
- Trecho: `borderRadius: BorderRadius.circular(18),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-271 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2493`
- Trecho: `borderRadius: BorderRadius.circular(16),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-272 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2506`
- Trecho: `borderRadius: BorderRadius.circular(10),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-273 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2582`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-274 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2648`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-275 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2654`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-276 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:3236`
- Trecho: `borderRadius: BorderRadius.circular(20),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-277 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:3901`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-278 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:4005`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-279 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:4065`
- Trecho: `borderRadius: BorderRadius.circular(20),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-280 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:4210`
- Trecho: `borderRadius: BorderRadius.circular(20),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-281 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:4295`
- Trecho: `borderRadius: BorderRadius.circular(999),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-282 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:4438`
- Trecho: `borderRadius: BorderRadius.circular(`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-283 radius_literal

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:4544`
- Trecho: `borderRadius: BorderRadius.circular(4),`
- Impacto: Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.
- Sugestao: Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.

#### P2-284 text_style_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart:201`
- Trecho: `style: const TextStyle(`
- Impacto: TextStyle isolado facilita drift de tipografia, peso e cor.
- Sugestao: Preferir Theme.of(context).textTheme + copyWith usando AppTheme quando necessario.

#### P2-285 text_style_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1822`
- Trecho: `style: TextStyle(`
- Impacto: TextStyle isolado facilita drift de tipografia, peso e cor.
- Sugestao: Preferir Theme.of(context).textTheme + copyWith usando AppTheme quando necessario.

#### P2-286 text_style_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:1920`
- Trecho: `style: TextStyle(`
- Impacto: TextStyle isolado facilita drift de tipografia, peso e cor.
- Sugestao: Preferir Theme.of(context).textTheme + copyWith usando AppTheme quando necessario.

#### P2-287 text_style_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2190`
- Trecho: `style: TextStyle(`
- Impacto: TextStyle isolado facilita drift de tipografia, peso e cor.
- Sugestao: Preferir Theme.of(context).textTheme + copyWith usando AppTheme quando necessario.

#### P2-288 text_style_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2279`
- Trecho: `style: TextStyle(`
- Impacto: TextStyle isolado facilita drift de tipografia, peso e cor.
- Sugestao: Preferir Theme.of(context).textTheme + copyWith usando AppTheme quando necessario.

#### P2-289 text_style_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:2286`
- Trecho: `hintStyle: TextStyle(`
- Impacto: TextStyle isolado facilita drift de tipografia, peso e cor.
- Sugestao: Preferir Theme.of(context).textTheme + copyWith usando AppTheme quando necessario.

#### P2-290 text_style_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:3539`
- Trecho: `style: TextStyle(`
- Impacto: TextStyle isolado facilita drift de tipografia, peso e cor.
- Sugestao: Preferir Theme.of(context).textTheme + copyWith usando AppTheme quando necessario.

#### P2-291 text_style_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:3562`
- Trecho: `style: TextStyle(`
- Impacto: TextStyle isolado facilita drift de tipografia, peso e cor.
- Sugestao: Preferir Theme.of(context).textTheme + copyWith usando AppTheme quando necessario.

#### P2-292 text_style_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:3687`
- Trecho: `style: TextStyle(`
- Impacto: TextStyle isolado facilita drift de tipografia, peso e cor.
- Sugestao: Preferir Theme.of(context).textTheme + copyWith usando AppTheme quando necessario.

#### P2-293 text_style_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:4012`
- Trecho: `style: TextStyle(`
- Impacto: TextStyle isolado facilita drift de tipografia, peso e cor.
- Sugestao: Preferir Theme.of(context).textTheme + copyWith usando AppTheme quando necessario.

#### P2-294 text_style_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:4108`
- Trecho: `style: TextStyle(`
- Impacto: TextStyle isolado facilita drift de tipografia, peso e cor.
- Sugestao: Preferir Theme.of(context).textTheme + copyWith usando AppTheme quando necessario.

#### P2-295 text_style_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:4384`
- Trecho: `style: TextStyle(`
- Impacto: TextStyle isolado facilita drift de tipografia, peso e cor.
- Sugestao: Preferir Theme.of(context).textTheme + copyWith usando AppTheme quando necessario.

#### P2-296 text_style_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:5049`
- Trecho: `style: TextStyle(`
- Impacto: TextStyle isolado facilita drift de tipografia, peso e cor.
- Sugestao: Preferir Theme.of(context).textTheme + copyWith usando AppTheme quando necessario.

#### P2-297 text_style_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:5271`
- Trecho: `style: const TextStyle(`
- Impacto: TextStyle isolado facilita drift de tipografia, peso e cor.
- Sugestao: Preferir Theme.of(context).textTheme + copyWith usando AppTheme quando necessario.

#### P2-298 text_style_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:5426`
- Trecho: `style: TextStyle(`
- Impacto: TextStyle isolado facilita drift de tipografia, peso e cor.
- Sugestao: Preferir Theme.of(context).textTheme + copyWith usando AppTheme quando necessario.

#### P2-299 text_style_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:5606`
- Trecho: `style: const TextStyle(`
- Impacto: TextStyle isolado facilita drift de tipografia, peso e cor.
- Sugestao: Preferir Theme.of(context).textTheme + copyWith usando AppTheme quando necessario.

#### P2-300 text_style_without_theme_token

- Surface: `life_counter`
- Evidencia: `app/lib/features/home/life_counter_screen.dart:5772`
- Trecho: `style: TextStyle(`
- Impacto: TextStyle isolado facilita drift de tipografia, peso e cor.
- Sugestao: Preferir Theme.of(context).textTheme + copyWith usando AppTheme quando necessario.

#### P2-301 border_without_theme_token

- Surface: `trades_messages_notifications`
- Evidencia: `app/lib/features/trades/screens/trade_detail_screen.dart:160`
- Trecho: `border: Border.all(color: color.withValues(alpha: 0.3)),`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-302 border_without_theme_token

- Surface: `trades_messages_notifications`
- Evidencia: `app/lib/features/trades/screens/trade_detail_screen.dart:312`
- Trecho: `border: Border.all(color: color.withValues(alpha: 0.35)),`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-303 border_without_theme_token

- Surface: `trades_messages_notifications`
- Evidencia: `app/lib/features/trades/screens/trade_detail_screen.dart:600`
- Trecho: `border: Border.all(color: color.withValues(alpha: 0.25)),`
- Impacto: Borda sem token tende a variar cor/peso entre cards, filtros e modais.
- Sugestao: Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.

#### P2-304 possible_small_touch_or_visual_target

- Surface: `trades_messages_notifications`
- Evidencia: `app/lib/features/messages/screens/chat_screen.dart:259`
- Trecho: `width: 20,`
- Impacto: Alvo ou elemento visual menor que 48 pode ficar dificil de tocar ou parecer desalinhado.
- Sugestao: Validar screenshot/touch target; elevar para bug se o alvo real ficar abaixo de 48x48.

## Git status

```text
## master...origin/master
 M docs/README.md
 M server/bin/ui_audit_pipeline.py
 M server/manual-de-instrucao.md
?? docs/qa/MANALOOM_PREMIUM_VISUAL_QA_RUBRIC_2026-06-04.md
?? docs/qa/manaloom_premium_visual_audit_latest.md
?? server/bin/__pycache__/
?? server/bin/premium_visual_audit.py
?? server/bin/premium_visual_audit.sh
?? server/config/
```

VISUAL_PREMIUM_QA_RESULT: signals=304 P1=0 P2=304 visual_pass=false
