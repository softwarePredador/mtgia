# ManaLoom strict visual revalidation - 2026-06-05

## Verdict

`PASS_WITH_RISKS` for the live iPhone Simulator visual proof captured on 2026-06-05.

The runtime checks passed and the extracted screenshots were manually inspected for the regression class reported by QA: wrapped/cut button text, hidden numeric values, misaligned tabs/menus, and unreadable modal controls.

This is not a full static visual pass. `server/bin/premium_visual_audit.py` still reports P2 visual drift signals, so the static audit remains a backlog/gate companion rather than a release pass by itself.

## Environment

- Device: iPhone 15 Pro Max Simulator `DABB9D79-2FDB-4585-94DB-E31F1288EE74`
- Backend: `https://evolution-cartinhas.8ktevp.easypanel.host`
- Source SHA during static audit: `4af68ade`
- Extracted proof folder, ignored by Git: `app/doc/runtime_flow_proofs_2026-06-05_strict_visual_revalidation_iphone15/`

## Commands run

```bash
python3 server/bin/premium_visual_audit.py --include-life-counter --output docs/qa/manaloom_premium_visual_audit_latest.md
```

Result: `signals=303 P1=0 P2=303 visual_pass=false`.

```bash
cd app
flutter test integration_test/app_full_non_life_counter_visual_capture_smoke_test.dart \
  -d DABB9D79-2FDB-4585-94DB-E31F1288EE74 \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded \
  --no-version-check
```

Result: `00:49 +1: All tests passed!`

```bash
cd app
flutter test \
  integration_test/life_counter_lotus_visual_capture_smoke_test.dart \
  integration_test/life_counter_native_card_search_smoke_test.dart \
  integration_test/life_counter_set_life_live_smoke_test.dart \
  integration_test/life_counter_native_player_appearance_color_card_live_smoke_test.dart \
  -d DABB9D79-2FDB-4585-94DB-E31F1288EE74 \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded \
  --no-version-check
```

Result: `03:10 +5: All tests passed!`

```bash
cd app
flutter test integration_test/commander_learned_deck_runtime_test.dart \
  -d DABB9D79-2FDB-4585-94DB-E31F1288EE74 \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded \
  --no-version-check
```

Result: `00:24 +1: All tests passed!`

## Captures produced

Runtime screenshots extracted from logs:

- Non-Life Counter: 14 screenshots
- Life Counter: 5 screenshots
- Commander learned deck: 4 screenshots
- Contact sheets: `contact_sheet_non_life_counter.jpg`, `contact_sheet_life_counter.jpg`, `contact_sheet_commander_learned.jpg`

Key captured screens:

- `00_splash`
- `01_login`
- `02_register_filled`
- `03_home`
- `04_decks`
- `04a_create_deck_dialog`
- `04b_deck_details`
- `04c_deck_import`
- `05_generate`
- `06_generate_preview_not_proven`
- `07_community`
- `08_collection`
- `09_profile`
- `commander_damage_overlay`
- `turn_tracker_hint_overlay`
- `life_counter_card_search_sheet`
- `life_counter_set_life_sheet_35`
- `life_counter_player_appearance_presets`
- `01_no_commander_no_learned_button`
- `02_commander_learned_button_visible`
- `03_hermes_preview`
- `04_saved_deck_details`

## Manual visual checks

Passed in inspected screenshots:

- `commander_damage_overlay`: `RETURN TO GAME` is not wrapped, not clipped, and is horizontally aligned with `GOT IT!`.
- `life_counter_set_life_sheet_35`: value `35` is fully visible, centered, and not hidden by the sheet header or scroll area.
- `life_counter_set_life_sheet_35`: keypad digits and `DEL` are horizontal and legible.
- `life_counter_set_life_sheet_35`: `Cancel` and `Set Life` are visible and not hidden by the bottom edge.
- `life_counter_card_search_sheet`: search field, quick suggestions, and close action are legible in the sheet.
- `life_counter_player_appearance_presets`: color presets, `Use`, `Cancel`, and `Apply` are visible.
- `08_collection`: top menus/tabs are aligned across the screen and no longer appear shifted to the right.
- `03_home`, `04_decks`, `04b_deck_details`, `07_community`, `09_profile`: captured surfaces retain the dark/brass/blue premium visual family.
- Commander learned flow: button appears only after commander input, preview shows Hermes origin/score/legalidade/confidence, saved deck reports 100 total, 99 main, 1 commander, and no blocked premium Mox cards.

## Remaining risks

- Static audit still reports `303` P2 drift signals. These are not runtime failures, but they prove the codebase still has hardcoded visual values and non-tokenized styling to continue reducing.
- `06_generate_preview_not_proven` remains a generic flow state label from the non-Life Counter smoke test. The dedicated Commander learned deck preview was proven separately in this run.
- Screenshots prove the captured states only. Long scrollable surfaces can still contain below-the-fold visual issues and should keep using targeted capture tests when changing those areas.

## Release interpretation

The reported visual regressions around Life Counter overlays and Set Life sheet are resolved in the live simulator proof. Do not treat this as permission to stop visual QA: for any app-facing layout change, run the static audit plus the relevant iPhone Simulator proof and manually inspect contact sheets before promotion.

## Follow-up: Commander learned deck UX polish

After reviewing the 2026-06-05 contact sheet, the Commander learned deck flow still showed visual pollution:

- the learned-deck button mixed action copy with internal dataset/score/status details;
- example prompts used repeated equal-weight filled blocks;
- the preview nested cards/chips for related metadata, making origin, score, legality and confidence compete with the primary deck review task.

Code updated:

- `app/lib/features/decks/screens/deck_generate_screen.dart`
- `app/test/features/decks/screens/deck_flow_entry_screens_test.dart`
- `app/integration_test/commander_learned_deck_runtime_test.dart`
- `app/integration_test/commander_learned_deck_availability_runtime_test.dart`

Visual changes:

- The learned-deck CTA now reads as one curated action card and no longer exposes `learned_deck`, score or raw status in the button area.
- The button helper uses product language: `curado pelo Hermes` and `legal para Commander`.
- Internal source/score/legalidade/confiança remain available in the preview only, where they serve auditability rather than first-action affordance.
- Example prompts now render as a lightweight suggestion list instead of repeated same-weight chips.
- The preview uses one main review panel, a left-accent learned-deck summary and a shortened main-deck sample instead of nested subcards and many chips.

Additional validation:

```bash
cd app
flutter analyze \
  lib/features/decks/screens/deck_generate_screen.dart \
  test/features/decks/screens/deck_flow_entry_screens_test.dart \
  integration_test/commander_learned_deck_runtime_test.dart \
  integration_test/commander_learned_deck_availability_runtime_test.dart \
  --no-version-check
```

Result: `No issues found!`

```bash
cd app
flutter test test/features/decks/screens/deck_flow_entry_screens_test.dart --no-version-check --reporter expanded
```

Result: `00:01 +4: All tests passed!`

```bash
cd app
flutter test integration_test/commander_learned_deck_runtime_test.dart \
  -d DABB9D79-2FDB-4585-94DB-E31F1288EE74 \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded \
  --no-version-check
```

Result: `00:25 +1: All tests passed!`

```bash
cd app
flutter test integration_test/commander_learned_deck_availability_runtime_test.dart \
  -d DABB9D79-2FDB-4585-94DB-E31F1288EE74 \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded \
  --no-version-check
```

Result: `00:19 +1: All tests passed!`

```bash
cd app
flutter test integration_test/app_full_non_life_counter_visual_capture_smoke_test.dart \
  -d DABB9D79-2FDB-4585-94DB-E31F1288EE74 \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded \
  --no-version-check
```

Result: `00:49 +1: All tests passed!`

Extracted proof folder, ignored by Git:

- `app/doc/runtime_flow_proofs_2026-06-05_commander_learned_polish_final_iphone15/`

Manual visual result:

- `02_commander_learned_button_visible`: button no longer displays raw `learned_deck`, score or `commander_legal`; the CTA reads as a single curated learned-deck action.
- `03_hermes_preview`: preview keeps audit details but with fewer visual containers and no chip cluster.
- `04_saved_deck_details`: save still creates Commander deck with 100 total, 99 main, 1 commander and no blocked premium Mox cards.

## Follow-up: Inter typography migration

The app UI font was migrated from Manrope to Inter while preserving Fraunces for brand/display hierarchy only.

Code updated:

- `app/pubspec.yaml`
- `app/assets/lotus/fonts/Inter.ttf`
- `app/lib/core/theme/app_theme.dart`
- `app/lib/features/home/lotus/lotus_visual_skin.dart`
- `app/lib/features/home/lotus/lotus_host_controller.dart`
- `app/lib/features/home/home_screen.dart`
- `app/test/features/home/home_screen_test.dart`
- `app/test/features/home/lotus_visual_skin_test.dart`
- `app/test/features/home/lotus_ui_snapshot_test.dart`
- `app/integration_test/life_counter_webview_smoke_test.dart`

Typography decisions:

- Inter is now the default UI font for body, labels, controls, chips, tabs, menus, snackbars, navigation and Lotus/WebView shell text.
- Fraunces remains restricted to display/header surfaces: `display*`, `headline*` and `titleLarge`.
- Dense utility surfaces use lower letter spacing and restrained weights to avoid Manrope-era over-bold UI after the Inter swap.
- Home header now reserves fixed space for right-side actions and scales the brand row down before it can overlap icons.

Validation:

```bash
cd app
flutter analyze --no-pub \
  lib/core/theme/app_theme.dart \
  lib/features/home/lotus/lotus_visual_skin.dart \
  lib/features/home/lotus/lotus_host_controller.dart \
  test/features/home/lotus_visual_skin_test.dart \
  test/features/home/home_screen_test.dart \
  test/features/home/lotus_ui_snapshot_test.dart \
  integration_test/life_counter_webview_smoke_test.dart \
  --no-version-check
```

Result: `No issues found!`

```bash
cd app
flutter test --no-pub test/features/home/lotus_visual_skin_test.dart --no-version-check --reporter expanded
flutter test --no-pub test/features/home/lotus_ui_snapshot_test.dart --no-version-check --reporter expanded
flutter test --no-pub test/features/home/home_screen_test.dart --no-version-check --reporter expanded
flutter test --no-pub test/features/decks/screens/deck_flow_entry_screens_test.dart --no-version-check --reporter expanded
```

Results: `+3`, `+2`, `+3`, `+4`; all passed.

```bash
cd app
flutter test --no-pub integration_test/app_full_non_life_counter_visual_capture_smoke_test.dart \
  -d DABB9D79-2FDB-4585-94DB-E31F1288EE74 \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded \
  --no-version-check
```

Result: `00:50 +1: All tests passed!`

```bash
cd app
flutter test --no-pub \
  integration_test/life_counter_webview_smoke_test.dart \
  integration_test/life_counter_lotus_visual_capture_smoke_test.dart \
  integration_test/life_counter_set_life_live_smoke_test.dart \
  -d DABB9D79-2FDB-4585-94DB-E31F1288EE74 \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded \
  --no-version-check
```

Result: `02:29 +5: All tests passed!`

```bash
cd app
flutter test --no-pub integration_test/commander_learned_deck_runtime_test.dart \
  -d DABB9D79-2FDB-4585-94DB-E31F1288EE74 \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded \
  --no-version-check
```

Result: `00:26 +1: All tests passed!`

Static audit:

```bash
python3 server/bin/premium_visual_audit.py --include-life-counter --output docs/qa/manaloom_premium_visual_audit_latest.md
```

Result: `signals=301 P1=0 P2=301 visual_pass=false`.

Extracted proof folder, ignored by Git:

- `app/doc/runtime_flow_proofs_2026-06-05_inter_typography_iphone15/`

Manual visual result:

- `03_home`: ManaLoom brand no longer overlaps message/notification icons after the responsive header adjustment.
- `commander_damage_overlay`: `RETURN TO GAME` and `GOT IT!` remain visible, aligned and not clipped with Inter.
- `life_counter_set_life_sheet_35`: value `35`, keypad numbers, `DEL`, `Cancel` and `Set Life` remain visible.
- `03_hermes_preview`: dense learned-deck text remains readable; long generated deck name is constrained inside the input row rather than overflowing the screen.
- `01_login`, `02_register_filled`, `04a_create_deck_dialog`, `04b_deck_details`, `05_generate`, `07_community`, `08_collection`, `09_profile`: captured surfaces retain the same dark/brass/frost visual family after the font swap.

Remaining risk:

- Static audit still has P2 tokenization/style drift signals. No P1 visual blocker was found, but future layout changes must continue using iPhone Simulator proof plus manual screenshot review.
