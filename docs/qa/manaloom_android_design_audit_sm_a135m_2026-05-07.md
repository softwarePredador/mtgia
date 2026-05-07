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
