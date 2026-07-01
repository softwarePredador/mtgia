# ManaLoom Premium Visual QA Gate

## Veredito automatico

`NOT_A_VISUAL_PASS`.

Este relatorio valida sinais objetivos de drift visual, mas nao substitui prova viva no iPhone Simulator. Proporcao de cards, poluicao visual, seam de imagem, legibilidade real e fidelidade ao mockup exigem revisar screenshots.

## Metadata

- Gerado em UTC: `2026-07-01T12:05:13.564672+00:00`
- Branch: `codex/session-agent-xmage-mapper-20260630`
- SHA: `5325e6580`
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

`signals=0 P1=0 P2=0`

### Por regra

- Nenhum sinal objetivo de drift visual encontrado nas surfaces configuradas.

## Matriz por tela

| Surface | Capturas obrigatorias | Sinais | Foco de revisao |
| --- | --- | ---: | --- |
| Splash/Login/Cadastro | `00_splash`, `01_login`, `02_register_filled` | 0 | logo nova; splash/login coerentes; CTA brass; campos sem Material default; contraste em labels e placeholders |
| Home | `03_home` | 0 | hero art sem seam/transparencia indevida; card hero proporcional; quick actions consistentes; recent decks com cards da familia Meus Decks |
| Meus Decks | `04_decks` | 0 | baseline visual; grid/cards ricos; badges legiveis; filtros/tabs ativos; FAB/menus alinhados |
| Detalhes do Deck | `04b_deck_details`, `04_saved_deck_details` | 0 | tabs coerentes; cards de metricas; legibilidade de analise; CTA otimizar/adicionar; graficos sem ruido visual |
| Criar/Gerar/Importar Deck | `04a_create_deck_dialog`, `04c_deck_import`, `05_generate`, `06_generate_preview`, `01_no_commander_no_learned_button`, `02_commander_learned_button_visible`, `03_hermes_preview` | 0 | forms premium; hierarquia de preview; botoes primario/secundario; empty/error states; sem texto cru de backend |
| Busca/Detalhe/Adicionar Carta | `sets_search_01_cards_results`, `sets_search_02_card_detail`, `card_add_commander_choice_modal` | 0 | resultado identico ao mockup aprovado; modal comandante guiado; quantidade alinhada; texto de botoes; badges/sets legiveis |
| Colecao/Fichario/Marketplace | `08_collection`, `collection_01_binder`, `collection_02_marketplace`, `collection_04_sets_catalog`, `sets_search_04_set_detail` | 0 | menus nao deslocados; tabs e filtros alinhados; cards/empty states; editor modal; marketplace sem default colors |
| Trades/Mensagens/Notificacoes | `market_trade_05_trade_list`, `market_trade_08_trade_chat`, `messages_01_inbox`, `messages_02_conversation`, `market_trade_11_notifications` | 0 | status chips; linhas de conversa; unread badges; CTA/context menus; empty/loading/error states |
| Comunidade/Perfil | `07_community`, `09_profile`, `profile_community_02_user_profile`, `profile_community_05_community_deck_detail` | 0 | feed/cards; perfil proprio e publico; badges sociais; botoes seguir/editar; hierarquia de texto |
| Life Counter/Lotus | `commander_damage_overlay`, `turn_tracker_hint_overlay`, `life_counter_card_search_sheet`, `life_counter_set_life_sheet_35`, `life_counter_player_appearance_presets` | 0 | linguagem tabletop propria; contadores legiveis por jogador; overlays/settings; cores separaveis; touch targets em mesa |

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

### commander_learned_deck

```bash
cd app && flutter test integration_test/commander_learned_deck_runtime_test.dart -d <IPHONE_SIMULATOR_UDID> --dart-define=API_BASE_URL=<API_BASE_URL> --dart-define=PUBLIC_API_BASE_URL=<PUBLIC_API_BASE_URL> --dart-define=DISABLE_FIREBASE_STARTUP=true --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true --reporter expanded --no-version-check
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

Nenhum sinal objetivo encontrado.
VISUAL_PREMIUM_QA_RESULT: signals=0 P1=0 P2=0 visual_pass=false
