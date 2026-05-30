# Mapa de Testes de Layout e Validação Visual — ManaLoom

> Data: 2026-05-30
> Objetivo: Listagem completa de todos os testes que validam layout, overflow, responsividade, golden comparison, e DOM probes visuais.

## Índice
1. [Overflow Tests](#1-overflow-tests)
2. [Golden Comparison](#2-golden-comparison)
3. [Responsive Multi-Viewport](#3-responsive-multi-viewport)
4. [Layout Key Presence](#4-layout-key-presence)
5. [WebView DOM Probes](#5-webview-dom-probes)
6. [Visual Screenshot Capture](#6-visual-screenshot-capture)
7. [Doc de Referência](#7-doc-de-referencia)
8. [Gaps Conhecidos](#8-gaps-conhecidos)

---

## 1. Overflow Tests

Renderiza widget em viewport estreita e verifica se não estoura (`takesException() isNull`).

| Teste | Widget | Viewports | Text Scaler |
|---|---|---|---|
| `deck_card_overflow_test.dart` | `DeckCard` | 280, 320, 360, 375, 411 | 1.0 |
| `create_trade_screen_overflow_test.dart` | `CreateTradeScreen` | 320 | 1.3 |
| `marketplace_screen_overflow_test.dart` | `MarketplaceTabContent` | 320, 390 | 1.25 |
| `deck_diagnostic_panel_test.dart` | `DeckDiagnosticPanel` | 280 | 1.0 |
| `sample_hand_widget_test.dart` | `SampleHandWidget` | default | 1.0 |
| `app_state_panel_test.dart` | `AppStatePanel` | 280 | 1.0 |
| `home_screen_test.dart` | `HomeScreen` | 390x844 | 1.0 |

**Total: 7 arquivos cobrindo 5 viewports (280, 320, 360, 375, 390, 411)**

---

## 2. Golden Comparison

Compara screenshot do widget com baseline PNG versionada (`matchesGoldenFile`).

| Teste | Goldens | Viewport | Tolerância |
|---|---|---|---|
| `home_screen_test.dart` | `home_hero_sma135m.png` | 390x844 | padrão |
| `life_counter_clone_proof_test.dart` | 5 goldens: normal 4p, hub open, settings, set life, high roll | 590x1280 | 0.06%–0.35% |

**Total: 6 goldens em 2 arquivos**

---

## 3. Responsive Multi-Viewport

Testa o mesmo widget em múltiplas larguras.

| Widget | Viewports Testados |
|---|---|
| `DeckCard` | 280, 320, 360, 375, 411 (10 testes) |
| `MarketplaceTabContent` | 320, 390 (2 testes) |
| `HomeScreen` | 390x844 (1 viewport) |

**Total: 13 testes em 3 arquivos, 6 viewports distintos**

---

## 4. Layout Key Presence

Usa `find.byKey` para validar que elementos estruturais renderizam.

| Tela | Arquivo | Keys |
|---|---|---|
| Life Counter (legacy) | `life_counter_screen_test.dart` | `life-counter-control-hub`, `life-counter-hub-toggle`, `life-counter-hub-settings`, `life-counter-rail-dice`, `life-counter-dice-overlay`, `life-counter-quick-minus-*`, `life-counter-quick-plus-*`, `life-counter-player-high-roll-event-*` +20 outros |
| Life Counter Clone Proof | `life_counter_clone_proof_test.dart` | `life-counter-clone-current-frame`, `life-counter-life-core-*`, `life-counter-bottom-rail`, `life-counter-settings-overlay`, `life-counter-set-life-overlay` |
| Home | `home_screen_test.dart` | `home-hero-frame` |
| Optimize Dialogs | `deck_optimize_dialogs_test.dart` | `optimize-preview-dialog`, `optimize-preview-apply-button`, `optimize-intensity-*`, `optimize-suggestion-remove-*`, `optimize-suggestion-add-*` |
| Marketplace | `marketplace_screen_overflow_test.dart` | `marketplace-list-loading`, `marketplace-list-error`, `marketplace-list-empty` |
| Sample Hand | `sample_hand_widget_test.dart` | `sample-hand-draw`, `sample-hand-mulligan` |
| Diagnostic Panel | `deck_diagnostic_panel_test.dart` | `deck-diagnostic-panel`, `deck-diagnostic-summary-badge`, `deck-diagnostic-metric-*`, `deck-diagnostic-insight-*` |
| 12+ native sheet tests | `life_counter_native_*_sheet_test.dart` | `life-counter-native-*` |

---

## 5. WebView DOM Probes

Valida layout do WebView Lotus Life Counter via JavaScript bridge (dimensões, overflow px, fontes, geometria).

| Teste | O que valida |
|---|---|
| `life_counter_webview_smoke_test.dart` | `viewportWidth > 300`, `viewportHeight > 600`, `horizontalOverflowPx <= 1.5`, `verticalOverflowPx <= 1.5`, `firstPlayerCardWidth > 150`, `firstPlayerLifeBoxWidth > 60`, `gameTimerFontSize inInclusiveRange(24,40)`, `turnTrackerFontSize inInclusiveRange(18,28)`, `skinApplied == true` |
| `life_counter_lotus_visual_runtime_proof_test.dart` | `lifeContentFits == true`, `horizontalOverflow == false`, `lifeFontSize > 12`, `lifeRectWidth > 40`, `lifeRectHeight > 40`, `playerLifeCount == 4` |
| `life_counter_clock_visual_smoke_test.dart` | `clockCount`, `clockWithGameTimerCount`, font families (Manrope, Fraunces), font sizes |
| `lotus_ui_snapshot_test.dart` | Model parsing: `viewport_width`, `viewport_height`, `horizontal_overflow_px`, `vertical_overflow_px`, `first_player_card_width`, `first_player_life_box_width`, font sizes |

**Total: 4 arquivos com 30+ assertions de geometria**

---

## 6. Visual Screenshot Capture

Captura screenshots em device/simulador para evidência visual (não é validação automatizada, é registro).

| Teste | O que captura |
|---|---|
| `life_counter_lotus_visual_runtime_proof_test.dart` | Lotus life counter (initial + after plus button) |
| `life_counter_lotus_visual_capture_smoke_test.dart` | Lotus commander damage proof overlay |
| `life_counter_lotus_visual_overlays_smoke_test.dart` | Lotus overlays (D20, coin, high roll, first player, set life, commander damage, card search, dice, appearance) |
| `life_counter_lotus_settings_visual_smoke_test.dart` | Lotus settings overlay |
| `life_counter_lotus_card_search_visual_smoke_test.dart` | Lotus card search overlay |
| `app_full_non_life_counter_visual_capture_smoke_test.dart` | App completo (splash, login, home, decks, generate, community, collection, profile) |

**Total: 6 arquivos, ~20 screenshots por execução**

---

## 7. Doc de Referência

| Doc | Conteúdo |
|---|---|
| `app/test/README.md` | Suite structure, overflows cobertos, golden tolerances |
| `app/doc/UI_TEST_SURFACE_MAP.md` | Contrato de keys estáveis por tela, checkpoints de screenshot, surface ownership |
| `app/doc/APP_AUDIT_2026-04-29.md` | Auditoria visual histórica — fixes de overflow, runtime proofs |

---

## 8. Gaps Conhecidos

| Gap | Impacto |
|---|---|
| **DeckCard é o único widget com teste responsivo multi-viewport** | Outros widgets podem quebrar em telas estreitas sem detecção |
| **Nenhum golden test para telas funcionais atuais** | Regressão visual passa despercebida |
| **Integration tests só usam 390x844** | Sem cobertura de tablet ou landscape |
| **Nenhum teste de posição/alinhamento/padding** | Layout é validado só por "não estourou" |
| **Life Counter Flutter shell sem teste de overflow** | Só o WebView interno é validado |
| **community_screen (1729 linhas) sem teste de widget unitário** | Maior tela sem cobertura de layout |
| **trade_detail_screen (1479 linhas) sem teste de layout dedicado** | Só o CreateTrade tem overflow test |
| **binder_screen (1628 linhas) sem teste de widget dedicado** | Marketplace tem, mas binder principal não |
| **chat_screen sem teste de widget** | 3 falhas pré-existentes no flutter test |
