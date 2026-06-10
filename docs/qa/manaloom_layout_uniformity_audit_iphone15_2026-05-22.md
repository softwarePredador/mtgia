# ManaLoom Layout Uniformity Audit - iPhone Simulator - 2026-05-22

## Veredito

`PASS_WITH_RISKS` para o shell mobile non-scanner.

As telas do fluxo principal que foram migradas para o sistema visual de
`Meus Decks` estao uniformes na prova viva iOS desta rodada: fundo Obsidian,
superficies azul-noturno, bordas Brass/Frost discretas, titulos serifados,
texto secundario frio, CTAs brass, bottom navigation e hierarquia de modais.

Este veredito nao diz que toda tela ficou pixel-identica ao mockup do designer.
Ele diz que as telas do produto usam a mesma linguagem visual e nao ficaram com
familias antigas destoando entre si no fluxo non-scanner provado.

## Criterios

O baseline de comparacao foi a tela `Meus Decks` atual:

1. background escuro com atmosfera controlada, sem bloco claro solto;
2. cards com raio, borda, sombra e spacing compatíveis com o shell;
3. display typography serifada para headers e copy secundaria coerente;
4. brass para acao primaria e destaque ativo;
5. Frost/blue apenas como suporte informacional;
6. modais com decisao guiada, CTA principal e cancelamento secundario;
7. tabs, app bars e bottom navigation sem drift evidente por feature.

## Evidencia usada

- Rotas declaradas em `app/lib/main.dart`.
- Screens e entrypoints em `app/lib/features/**`.
- Surface keys documentadas em `app/doc/UI_TEST_SURFACE_MAP.md`.
- Varredura estatica de tokens visuais em `app/lib/features/**` e
  `app/lib/core/widgets/**`, excluindo scanner/camera/OCR e Life Counter/Lotus.
- Proof folder:
  `app/doc/runtime_flow_proofs_2026-05-22_meus_decks_visual_system_iphone15/`.
- Handoff runtime:
  `app/doc/runtime_flow_handoffs/meus_decks_visual_system_iphone15_2026-05-22.md`.
- Capturas vivas iOS dos harnesses:
  - `app_full_non_life_counter_visual_capture_smoke_test.dart`;
  - `sets_search_catalog_runtime_test.dart`;
- `card_add_commander_choice_runtime_test.dart`;
- `collection_entrypoints_runtime_test.dart`;
- `binder_marketplace_trade_runtime_test.dart`;
- `profile_community_runtime_test.dart`.
- Rerun final apos auditoria de tokens:
  `/tmp/manaloom_layout_uniformity_token_audit_20260522.log`,
  resultado `00:51 +1: All tests passed!`.
- Contact sheet do rerun final:
  `app/doc/runtime_flow_proofs_2026-05-22_meus_decks_visual_system_iphone15/contact_sheet_app_full_token_audit.jpg`.

## Auditoria de tokens visuais

Comando base executado:

```bash
rg -n "Color\(0x|Colors\." app/lib/features app/lib/core/widgets \
  -g '*.dart' \
  -g '!**/scanner/**' \
  -g '!**/life_counter/**' \
  -g '!**/lotus/**' \
  -g '!**/life_counter_screen.dart' \
  -g '!**/lotus_life_counter_screen.dart'
```

Correcoes aplicadas nesta rodada:

- Home: sombras, overlay do hero/card e texto escuro de CTA passaram a usar
  `AppTheme.backgroundAbyss`, `AppTheme.surfaceSlate`, `AppTheme.textPrimary`
  e `AppTheme.brass400`.
- Auth/Splash: overlays antigos em `Color(0x...)` foram trocados por tokens
  derivados de `AppTheme.backgroundAbyss` e `AppTheme.transparent`.
- Imports, fichario, trades, comunidade, notificacoes, colecao, perfil,
  sample hand e progress badges: `Colors.white`, `Colors.black` e
  `Colors.transparent` foram substituidos por tokens do sistema quando eram
  puramente visuais.
- Golden da Home foi atualizado apos a troca intencional de tokens e o teste
  foi estabilizado com pre-cache do banner.

Resultado da varredura apos correcoes:

- Nenhum uso residual de `Color(0x...)` ou `Colors.*` em telas non-scanner
  auditadas.
- O unico match restante e falso positivo por nome de variavel
  `identityColors` em `card_detail_screen.dart`.
- Excecoes fora desta varredura: tokens internos de `AppTheme`, scanner,
  camera/OCR, Life Counter/Lotus e logica de contraste dinamico onde aplicavel.

## Validacoes finais

- `flutter analyze lib test --no-version-check`: PASS.
- `flutter test test --no-version-check --reporter compact`: PASS,
  `01:52 +590: All tests passed!`.
- `flutter test test/features/home/home_screen_test.dart
  test/features/decks/screens/deck_import_screen_test.dart --no-version-check
  --reporter compact`: PASS, `00:05 +6: All tests passed!`.
- `app_full_non_life_counter_visual_capture_smoke_test.dart` no iPhone
  Simulator: PASS, `00:51 +1: All tests passed!`.
- `git diff --check`: PASS.
- Scan simples de secrets em linhas alteradas: sem hits.

## Matriz de telas

| Tela/surface | Rota ou entrada | Evidencia viva | Veredito |
| --- | --- | --- | --- |
| Splash | `/` | captura `00_splash` do smoke amplo | Branded transition; consistente com arte e logo, nao e comparada como tela de trabalho. |
| Login | `/login` | `auth_refresh_01_login` | Uniforme com splash/Home apos migracao para logo e shell visual atual. |
| Cadastro | `/register` | `auth_refresh_02_register_filled` | Uniforme com auth/splash. |
| Home | `/home` | `auth_refresh_03_home`, `app_full_03_home` | Uniforme; usa hero proprio sem quebrar tokens de `Meus Decks`. |
| Onboarding core flow | `/onboarding/core-flow` | `app_full_03a_onboarding_core_flow` | Uniforme. |
| Meus Decks | `/decks` | `app_full_04_decks`, `auth_refresh_04_decks` | Baseline visual. |
| Criar deck modal | acao de `/decks` | `app_full_04a_create_deck_dialog` | Uniforme. |
| Detalhes do deck | `/decks/:id` | `app_full_04b_deck_details` | Uniforme. |
| Gerador de deck | `/decks/generate` | `app_full_05_generate` | Uniforme para formulario e loading. |
| Preview de generate | resultado de `/decks/generate` | `app_full_06_generate_preview_not_proven` | Layout base nao quebrou, mas preview positivo nao ficou provado no smoke amplo. |
| Importar deck | `/decks/import` | captura `04c_deck_import` do smoke amplo | Uniforme para a tela full-screen de importacao. |
| Busca de cartas | `/decks/:id/search` ou modo fichario | `sets_search_01_cards_results` | Uniforme e alinhada ao redesign de resultados. |
| Detalhe da carta | navegacao a partir da busca | `sets_search_02_card_detail` | Uniforme. |
| Modal adicionar carta/comandante | acao da busca | `card_add_commander_choice_modal` | Uniforme; decisao de comandante usa modal premium atual. |
| Colecao hub | `/collection` | `app_full_08_collection` | Uniforme. |
| Fichario | aba de `/collection` / `BinderScreen` | `collection_01_binder`, `market_trade_01_binder_have` | Uniforme. |
| Editor de item do fichario | sheet/modal do fichario | `market_trade_00_binder_editor_add`, `market_trade_00b_binder_editor_edit` | Uniforme. |
| Marketplace do fichario | aba de `/collection` / `MarketplaceScreen` | `collection_02_marketplace`, `market_trade_02_marketplace_result` | Uniforme. |
| Trade inbox | `/trades` e aba Collection | `market_trade_05_trade_list`; captura isolada `collection_03_trade_inbox` | Uniforme quando autenticado; captura isolada Collection registrou estado auth vazio. |
| Criar proposta | `/trades/create/:receiverId` | `market_trade_03_create_trade`, `market_trade_04_create_trade_review` | Uniforme. |
| Detalhes do trade | `/trades/:tradeId` | `market_trade_06` ate `market_trade_10` | Uniforme durante ciclo de status. |
| Trade chat | detalhes do trade | `market_trade_08_trade_chat` | Uniforme. |
| Catalogo de colecoes | `/collection/sets` | `collection_04_sets_catalog`, `sets_search_03_collections_results` | Uniforme. |
| Cartas da colecao | `/collection/sets/:code` | `sets_search_04_set_detail` | Uniforme. |
| Ultima colecao | `/collection/latest-set` | `LatestSetCollectionScreen` retorna `SetCardsScreen(loadLatest: true)` | Mesma surface de Cartas da colecao; sem layout distinto a validar. |
| Market geral | `/market` | `collection_05_market_screen` | Uniforme no estado capturado; a rodada registrou loading/movers e nao revisao pixel de todos estados. |
| Comunidade | `/community` | `app_full_07_community`, `profile_community_04_community_explore` | Uniforme. |
| Deck publico | detalhe da comunidade | `profile_community_05_community_deck_detail` | Uniforme. |
| Perfil de usuario | `/community/user/:userId` | `profile_community_02_user_profile` | Uniforme. |
| Busca de usuarios | `/community/search-users` | `profile_community_03_user_search`, `profile_community_07_community_users` | Uniforme. |
| Following/community feed | aba da comunidade | `profile_community_06_community_following` | Uniforme. |
| Perfil proprio | `/profile` | `app_full_09_profile`, `profile_community_01_profile` | Uniforme. |
| Mensagens | `/messages` | `messages_01_inbox` | Uniforme. |
| Chat direto | `/messages/:conversationId` | `messages_02_conversation` | Uniforme. |
| Notificacoes | `/notifications` | `market_trade_11_notifications` | Uniforme. |

## Superficies fora do veredito uniforme

| Surface | Motivo |
| --- | --- |
| Scanner / Camera / OCR | `CardScannerScreen` depende de camera, permission flow e overlay de reconhecimento. A rodada atual e explicitamente non-scanner e nao executou prova visual real desse screen. |
| Life Counter / Lotus | A rota de contador usa uma linguagem tabletop propria, com shell/sheets e runtime/goldens dedicados. Ela deve ser validada por sua suite visual especifica, nao forcada a copiar `Meus Decks`. |

## Desvios e proximos ajustes

1. Se o objetivo mudar de uniformidade para fidelidade pixel a pixel ao mockup,
   abrir rodada por tela com screenshot comparativo e aceite do designer.
2. Reabrir scanner apenas com gate de camera/permissao/OCR em device ou fluxo
   controlado que capture o screen real.
3. Manter Life Counter/Lotus como trilha visual separada e repetir sua prova
   viva quando houver alteracao no skin tabletop.
4. Se Market geral ganhar estados ricos alem de loading/movers, capturar estado
   preenchido e erro amigavel na proxima rodada visual.
