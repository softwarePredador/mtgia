# ManaLoom Android Design Audit — SM A135M — 2026-05-07

## Resultado final

**PASS WITH RISKS** para a auditoria visual/UX mobile no Android físico
**SM A135M** (`R58T300SREH`) contra o backend público
`https://evolution-cartinhas.8ktevp.easypanel.host`.

Scanner, câmera, OCR e MLKit ficaram **100% ignorados**.

## Device, backend e autenticação

| Item | Resultado |
| --- | --- |
| Branch | `master`, sincronizada com `origin/master` por fast-forward |
| Device | `SM A135M`, Android 14/API 34, id `R58T300SREH` |
| Backend | `https://evolution-cartinhas.8ktevp.easypanel.host` |
| Health | `healthy`, produção, `git_sha=0a6c73aad9d235a48ca2fe84ca657a432ea0ef20` |
| Auth QA | conta descartável criada/autenticada pelo app; segredo/token/senha não documentados |
| Scanner/camera/OCR | ignorado/deferred |

## Comandos executados

| Comando | Resultado |
| --- | --- |
| `git status --short --branch && git fetch origin master && git checkout master && git pull --ff-only origin master && git status --short` | PASS, branch atualizado |
| `adb devices -l` | PASS, `R58T300SREH device ... model:SM_A135M` |
| `flutter devices --no-version-check` | PASS, `SM A135M (mobile) • R58T300SREH • android-arm • Android 14 (API 34)` |
| `curl -sS https://evolution-cartinhas.8ktevp.easypanel.host/health` | PASS, `healthy` |
| `flutter test integration_test/app_full_non_life_counter_visual_capture_smoke_test.dart -d R58T300SREH ...` | PASS, `01:02 +1`; screenshots in-run para login/register/home/decks/deck detail/generate/community/collection/profile |
| `flutter test integration_test/binder_marketplace_trade_runtime_test.dart -d R58T300SREH ...` | PASS, `01:18 +2`; binder/marketplace/trades/trade detail/messages/notifications |
| `flutter test integration_test/sets_search_catalog_runtime_test.dart -d R58T300SREH ...` | PASS no rerun, `00:23 +1`; Search/Cards, Coleções e Card/Set data path |
| `flutter test integration_test/life_counter_native_game_modes_smoke_test.dart -d R58T300SREH ...` | PASS, `00:19 +1`; Life Counter/Lotus shell |
| `flutter test integration_test/deck_runtime_m2006_test.dart -d R58T300SREH ...` | BLOCKED nesta rodada fresca por encerramento prematuro do harness antes do fluxo; evidência histórica do mesmo dia permanece PASS WITH RISKS |
| `flutter analyze lib test --no-version-check` | PASS, sem issues |
| `flutter test test/features/cards test/features/collection test/features/home --no-version-check` | PASS |
| `flutter analyze lib test integration_test --no-version-check` | PASS final, sem issues |
| `flutter test test --no-version-check --reporter expanded` | PASS final, `550` testes |
| `flutter test integration_test/sets_search_catalog_runtime_test.dart -d R58T300SREH ...` apos patch | BLOCKED pelo runner (`did not complete`), mas requests `/cards` e `/sets` retornaram 200; screenshot ADB salvo |
| `flutter test integration_test/life_counter_native_player_state_smoke_test.dart -d R58T300SREH --reporter expanded --no-version-check` apos patch | PASS, `00:36 +2`; screenshot ADB salvo |

Observação operacional: uma tentativa paralela de rodar dois `flutter test`
Android ao mesmo tempo causou falha Gradle transitória em
`:app:createDebugApkListingFileRedirect`; o rerun sequencial do harness de
Sets/Search passou.

## Provas e screenshots

Prova histórica/runtime do mesmo device e data:

- `app/doc/runtime_flow_handoffs/android_sm_a135m_non_scanner_qa_2026-05-07.md`
- `app/doc/runtime_flow_proofs_2026-05-07_android_sm_a135m_non_scanner/`

Prova fresca desta rodada:

- O harness visual emitiu `CAPTURE_TAKEN` e `SCREENSHOT_BEGIN/END` para:
  `01_login`, `02_register_filled`, `03_home`, `04_decks`,
  `04a_create_deck_dialog`, `04b_deck_details`, `05_generate`,
  `06_generate_preview_not_proven`, `07_community`, `08_collection`,
  `09_profile`.
- PNGs locais persistidos em
  `app/doc/runtime_flow_proofs_2026-05-07_sm_a135m_design/`:
  `01_login.png`, `02_register_filled.png`,
  `sets_search_catalog_after_ux_polish.png` e
  `life_counter_native_player_state_after_ux_polish.png`.
- Logs frescos:
  `app_full_non_life_counter_visual_capture_smoke_test.log`,
  `sets_search_catalog_runtime_test_after_ux_polish.log` e
  `life_counter_native_player_state_after_ux_polish.log`.

## Matriz de telas/módulos

| Tela/módulo | Status | Evidência |
| --- | --- | --- |
| Login/Register | PASS | captura in-run e PNGs locais `01_login.png`, `02_register_filled.png`; registro 201 |
| Home | PASS | captura in-run `03_home`; sem crash/erro bruto |
| Search/Cards | PASS WITH RISKS | `sets_search_catalog_runtime_test`, `/cards?name=Black+Lotus` 200; PNG ADB `sets_search_catalog_after_ux_polish.png`; runner fresco encerrou antes do fim |
| Card Detail | PASS WITH RISKS | path de cards provado por Search/Sets; captura dedicada não persistida |
| Sets/Coleções | PASS WITH RISKS | `sets_search_catalog_runtime_test`, `/sets` 200 e prova historica `/cards?set=ECC` 200; PNG ADB `sets_search_catalog_after_ux_polish.png` |
| Decks | PASS | captura in-run `04_decks`; criação de deck 200 |
| Deck Detail | PASS | captura in-run `04b_deck_details`; `/decks/:id` 200 |
| Generate | PASS WITH RISKS | captura `05_generate`; backend aceitou async 202; preview síncrono não provado |
| Optimize | PASS WITH RISKS | prova histórica do mesmo dia PASS em `Focado`; harness fresco bloqueou antes do fluxo |
| Validate | PASS WITH RISKS | prova histórica do mesmo dia PASS; harness fresco bloqueou antes do fluxo |
| Binder/Fichário | PASS | `binder_marketplace_trade_runtime_test`; CRUD binder 201/200/204 |
| Binder dashboard | PASS | runtime histórico do mesmo dia e binder stats 200 nesta rodada |
| Marketplace | PASS | marketplace 200 e trade lifecycle PASS |
| Trades | PASS | trade lifecycle PASS |
| Trade Detail | PASS | `/trades/:id` 200 em múltiplos estados |
| Messages/Conversations | PASS | conversa direta, mensagem e read receipt PASS |
| Notifications | PASS | list/read/read-all PASS |
| Profile | PASS | captura in-run `09_profile`, `/users/me` 200 |
| Community | PASS | captura in-run `07_community`, `/community/decks` 200 |
| Life Counter/Lotus | PASS WITH RISKS | shell native/WebView PASS; PNG ADB `life_counter_native_player_state_after_ux_polish.png`; captura nativa via `takeScreenshot` segue risco histórico |
| Scanner/camera/OCR | IGNORED | fora do escopo |

## Findings classificados

| ID | Prioridade | Finding | Status |
| --- | --- | --- | --- |
| UX-A135M-001 | P2 | Ícone de IA (`auto_awesome_mosaic`) era usado para Coleções, ação não-IA, criando ruído semântico. | Corrigido para `Icons.grid_view_rounded` em Search e Collection. |
| UX-A135M-002 | P2 | Tabs da Collection pressionavam largura em tela mid-size Android; risco de truncar/densificar Marketplace/Trades/Coleções. | Corrigido com `isScrollable: true` e padding de label. |
| UX-A135M-003 | P2 | CTAs `Apply` em sheets do Life Counter/Lotus ainda usavam alias legado `manaViolet` e foreground branco em botão primário. | Corrigido para `AppTheme.brass500` + `AppTheme.backgroundAbyss`. |
| UX-A135M-004 | P2 | CTA `Gerar com IA` no onboarding usava cor primária de ação em vez de Frost Blue, reduzindo semântica de IA. | Corrigido para `AppTheme.frost400` com foreground Obsidian. |
| UX-A135M-005 | P3 | Alguns blocos tocados tinham formatação/linhas longas que dificultavam manutenção visual segura. | Formatado sem mudar regra de negócio. |
| UX-A135M-006 | P3 | Generate async aceitou job, mas preview visual não apareceu dentro da janela do harness amplo. | Mantido como risco; não é patch visual seguro nesta rodada. |
| UX-A135M-007 | P2 | Harness fresco de deck optimize/validate encerrou antes do fluxo no SM A135M. | Runtime histórico do mesmo dia cobre; precisa rerun dedicado. |

## Patches aplicados

- `app/lib/features/cards/screens/card_search_screen.dart`
  - troca de ícone de Coleções para `grid_view_rounded`.
- `app/lib/features/collection/screens/collection_screen.dart`
  - ícone de Coleções sem semântica de IA;
  - tabs roláveis com padding horizontal mais confortável.
- `app/lib/features/home/life_counter/*_sheet.dart`
  - CTAs primários `Apply` migrados para Brass + foreground Obsidian.
- `app/lib/features/home/lotus/lotus_host_overlays.dart`
  - botão de retry em Brass + foreground Obsidian.
- `app/lib/features/home/onboarding_core_flow_screen.dart`
  - CTA `Gerar com IA` em Frost Blue;
  - badges de passo em Brass + foreground Obsidian.

Nenhuma alteração backend/API/DB/AI/scanner/secrets foi feita.

## Itens não verificados

- PNG dedicado por tela para Home/Decks/Deck Detail/Generate/Community/
  Collection/Profile não ficou persistido individualmente nesta rodada; há
  eventos in-run e cobertura historica do mesmo dia/device.
- Optimize/Validate fresco no harness `deck_runtime_m2006_test.dart` ficou
  bloqueado antes do fluxo, apesar de cobertura histórica PASS WITH RISKS do
  mesmo dia/device.
- Auditoria visual manual pixel-level ficou parcial, limitada aos PNGs locais de
  Login/Register, Sets/Search e Life Counter.

## Veredito

**PASS WITH RISKS**.

O app autenticou de forma real, abriu telas centrais no SM A135M, preservou a
identidade Obsidian/Brass/Frost Blue e recebeu patches visuais seguros de
semântica de ícone, tab density e contraste de CTA. Os riscos restantes são
cobertura PNG dedicada ainda parcial e rerun dedicado de Optimize/Validate.

---

## Second Pass — Home readability + expanded runtime captures — 2026-05-07

### Resultado final da segunda rodada

**PASS WITH RISKS** para a segunda passada visual/UX no Android físico
**SM A135M** (`R58T300SREH`) contra o backend público
`https://evolution-cartinhas.8ktevp.easypanel.host`.

O status permanece com risco apenas porque o caminho `Optimize -> Agressivo`
depende do backend público retornar preview positivo; a UI de falha amigável foi
provada. Os PNGs da segunda passada foram materializados no diretório solicitado.
Scanner/câmera/OCR/MLKit continuaram 100% ignorados.

### Device, backend e autenticação

| Item | Resultado |
| --- | --- |
| Branch | `master`, sincronizada com `origin/master` por fast-forward; havia alterações locais em andamento antes desta segunda passada |
| Device | `SM-A135M`, Android `14`, API `34`, id `R58T300SREH` |
| Backend | `https://evolution-cartinhas.8ktevp.easypanel.host` |
| Health | `healthy`, produção, `version=1.0.0`, `git_sha=797d69f4409ba39ba7674d77a7993ddad9bf8239` |
| Auth QA | contas QA descartáveis criadas/autenticadas pelos harnesses; senha/token/JWT/headers não documentados |
| Scanner/camera/OCR | ignorado/deferred |

### Comandos executados na segunda passada

| Comando | Resultado |
| --- | --- |
| `git fetch origin && git checkout master && git pull --ff-only origin master && git status --short` | PASS; branch atualizada, com alterações locais de UX/teste já presentes |
| `adb devices` | PASS; `R58T300SREH device` |
| `adb -s R58T300SREH shell getprop ro.product.model` / `ro.build.version.release` / `ro.build.version.sdk` | PASS; `SM-A135M`, Android `14`, API `34` |
| `curl -sS https://evolution-cartinhas.8ktevp.easypanel.host/health` | PASS; `healthy`, `git_sha=797d69f4409ba39ba7674d77a7993ddad9bf8239` |
| `cd app && flutter analyze lib test integration_test --no-version-check` | PASS, sem issues |
| `cd app && flutter test test --no-version-check` | PASS, suíte unit/widget completa (`550+` testes) |
| `flutter test integration_test/app_full_non_life_counter_visual_capture_smoke_test.dart -d R58T300SREH ...` | PASS, `~01:02`, capturas de Login/Register/Home/Decks/Deck Detail/Generate/Community/Collection/Profile |
| `flutter test integration_test/sets_search_catalog_runtime_test.dart -d R58T300SREH ...` | PASS, `~00:27`, capturas Search/Cards, Card Detail, Coleções e Set Detail |
| `flutter test integration_test/binder_dashboard_runtime_test.dart -d R58T300SREH ...` | PASS, `~00:55`, capturas Binder dashboard, resultados, add/edit sheets |
| `flutter test integration_test/binder_marketplace_trade_runtime_test.dart -d R58T300SREH ...` | PASS, `~01:42`, capturas Binder/Marketplace/Trade list/detail/chat/notifications/messages |
| `flutter test integration_test/deck_runtime_m2006_test.dart -d R58T300SREH ...` | PASS, `~01:12`, capturas Deck flow, Optimize sheet e falha amigável de agressivo |
| `flutter test integration_test/deck_generate_async_runtime_test.dart -d R58T300SREH ...` | PASS, `~01:20`, capturas Generate async, preview, save, Deck Detail e rebuild guided blocker |
| `flutter test integration_test/life_counter_native_player_state_smoke_test.dart -d R58T300SREH --reporter expanded --no-version-check` | PASS, `~00:47`, capturas Lotus table e Player State overlays |
| `git diff --check` | PASS antes do commit da segunda passada |
| `cd app && flutter analyze lib test --no-version-check` | PASS antes do commit da segunda passada |

### Matriz de telas/módulos — segunda passada

| Tela/módulo | Status | Evidência de segunda passada |
| --- | --- | --- |
| Login/Register | PASS | `CAPTURE_TAKEN`: `01_login`, `02_register_filled`; registro/autenticação reais |
| Home | PASS | `CAPTURE_TAKEN`: `03_home`; patch aplicado para reduzir risco de truncamento no topo e cards |
| Search/Cards | PASS | `CAPTURE_TAKEN`: `sets_search_01_cards_results` |
| Card Detail | PASS | `CAPTURE_TAKEN`: `sets_search_02_card_detail` |
| Sets/Coleções | PASS | `CAPTURE_TAKEN`: `sets_search_03_collections_results` |
| Set Detail | PASS | `CAPTURE_TAKEN`: `sets_search_04_set_detail` |
| Decks | PASS | `CAPTURE_TAKEN`: `04_decks`, `04a_create_deck_dialog` |
| Deck Detail | PASS | `CAPTURE_TAKEN`: `04b_deck_details`, `08_deck_details` |
| Generate com IA | PASS WITH RISKS | `CAPTURE_TAKEN`: `05_generate`, `04_generate_screen`, `05_generate_async_progress`, `06_generate_preview`; primeira captura ampla ainda marcou `06_generate_preview_not_proven`, mas o harness async dedicado provou preview |
| Optimize sheet/preview/apply | PASS WITH RISKS | `CAPTURE_TAKEN`: `08_optimize_sheet`, `08c_optimize_sheet_agressivo`, `09_optimize_sheet`; fluxo focado/rebuild guided provado, agressivo continua com falha amigável quando o backend não entrega preview |
| Validate | PASS | `deck_runtime_m2006_test` PASS no fluxo create/import/optimize/apply/validate em device físico |
| Binder/Fichário | PASS | `CAPTURE_TAKEN`: `market_trade_01_binder_have`, `binder_01_dashboard` |
| Binder dashboard | PASS | `CAPTURE_TAKEN`: `binder_01_dashboard`, `binder_02_search_results`, `binder_03_add_item_sheet`, `binder_04_edit_item_sheet` |
| Marketplace | PASS | `CAPTURE_TAKEN`: `market_trade_02_marketplace_result` |
| Trades | PASS | `CAPTURE_TAKEN`: `market_trade_03_create_trade` a `market_trade_10_trade_detail_completed` |
| Trade Detail | PASS | Capturas pending/accepted/shipped/completed no mesmo harness |
| Messages/Conversations | PASS | `CAPTURE_TAKEN`: `messages_01_inbox`, `messages_02_conversation` |
| Notifications | PASS | `CAPTURE_TAKEN`: `market_trade_11_notifications` |
| Profile | PASS | `CAPTURE_TAKEN`: `09_profile` |
| Community | PASS | `CAPTURE_TAKEN`: `07_community` |
| Life Counter/Lotus | PASS | `CAPTURE_TAKEN`: `life_counter_01_lotus_table`, `life_counter_02_player_state`, `life_counter_03_player_state_killed_overlay` |
| Scanner/camera/OCR | IGNORED | fora de escopo |

### Findings da segunda passada

| ID | Prioridade | Finding | Status |
| --- | --- | --- | --- |
| UX-A135M-008 | P2 | Na Home em largura SM A135M, o wordmark `ManaLoom` no topo podia competir com ações de perfil/notificações e gerar overflow/truncamento em cenários de escala de fonte/localização. | Corrigido com `Flexible`, `maxLines: 1` e ellipsis preservando gradiente Brass. |
| UX-A135M-009 | P2 | Headers de seção e cards de intenção da Home dependiam de linhas horizontais densas; em telas estreitas, títulos/subtítulos longos podiam quebrar ritmo visual e pressionar o chevron. | Corrigido com header flexível e cards secundários empilhados, mantendo tap target e hierarquia. |
| UX-A135M-010 | P2 | A rodada anterior tinha evidência PNG dedicada parcial para Binder/Marketplace/Trades/Messages/Notifications/Sets/Card Detail/Life Counter. | Harnesses non-scanner receberam capturas visuais focadas nessas superfícies. |
| UX-A135M-011 | P3 | O helper de captura estava duplicado em alguns harnesses e dificultava expansão segura de provas visuais. | Adicionado helper compartilhado `visual_capture_helpers.dart` para capturas em runtime tests tocados. |

### Patches aplicados na segunda passada

- `app/lib/features/home/home_screen.dart`
  - wordmark flexível no AppBar custom;
  - `_SectionHeader` resiliente a largura estreita;
  - `_IntentCard` com helpers internos e layout empilhado para cards secundários,
    reduzindo pressão horizontal em SM A135M sem trocar tokens/identidade.
- `app/test/features/home/home_screen_test.dart`
  - teste widget em largura 390x844 para garantir que os cards de intenção da Home
    permaneçam renderizados sem exceção.
- `app/integration_test/visual_capture_helpers.dart`
  - helper compartilhado para capturas via `IntegrationTestWidgetsFlutterBinding`.
- `app/integration_test/sets_search_catalog_runtime_test.dart`
  - capturas de Cards, Card Detail, Coleções e Set Detail.
- `app/integration_test/binder_dashboard_runtime_test.dart`
  - capturas de dashboard, busca e sheets de add/edit.
- `app/integration_test/binder_marketplace_trade_runtime_test.dart`
  - capturas de Binder, Marketplace, Trade lifecycle, notificações e mensagens.
- `app/integration_test/life_counter_native_player_state_smoke_test.dart`
  - capturas Lotus table e Player State overlays.

Nenhuma alteração backend/API/DB/AI/modelo/scanner/secrets/env/signing/deployment
foi feita.

### Provas e paths

- Base histórica da primeira rodada:
  `app/doc/runtime_flow_proofs_2026-05-07_sm_a135m_design/`.
- Pasta solicitada para a segunda rodada:
  `app/doc/runtime_flow_proofs_2026-05-07_sm_a135m_design_second_pass/`.
- Capturas da segunda rodada foram provadas no stream dos harnesses pelos eventos
  `CAPTURE_TAKEN` listados na matriz acima e materializadas como PNGs individuais
  na pasta solicitada, incluindo logs brutos e `second_pass_contact_sheet.png`.

### Itens não verificados / riscos remanescentes

- Optimize `Agressivo` continua dependente do backend público entregar preview
  positivo; o app mostra falha amigável e o fluxo focado/rebuild guided passou.
- Auditoria pixel-level manual continua limitada pelas evidências persistidas
  existentes; a segunda passada aumentou cobertura automatizada de screenshots,
  mas não substitui revisão manual tela-a-tela de todos os PNGs salvos.

### Veredito da segunda passada

**PASS WITH RISKS**.

Os fluxos autenticados non-scanner centrais passaram no SM A135M real contra
backend público, a Home recebeu patch visual seguro para ergonomia/densidade em
tela estreita, e os harnesses agora capturam mais superfícies críticas com PNGs
persistidos no diretório de provas solicitado. O risco restante é funcional e
controlado: `Optimize -> Agressivo` depende de resposta positiva do backend
público para preview/apply completo, mantendo falha amigável quando indisponível.
