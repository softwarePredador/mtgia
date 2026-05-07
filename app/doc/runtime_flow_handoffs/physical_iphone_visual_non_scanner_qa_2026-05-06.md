# Physical iPhone Visual Non-Scanner QA - 2026-05-06

## Verdict

`PASS WITH RISKS`

The non-scanner visual/runtime battery ran on the physical iPhone `Rafa`
(`00008130-001C152922BA001C`) against the public backend
`https://evolution-cartinhas.8ktevp.easypanel.host`. Scanner, camera, OCR and
MLKit scanner flows were explicitly ignored and not opened.

## Runtime environment

- Date/time: `2026-05-07T08:42-03:00` to `2026-05-07T09:45-03:00`
- Repository: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia`
- Branch: `master`
- Local SHA before QA: `1c89bb0`
- Backend URL used by the app:
  `https://evolution-cartinhas.8ktevp.easypanel.host`
- Backend `/health`: `200`, `environment=production`,
  `git_sha=1c89bb0e467fd422d84fa696e57a7f73d07618d3`
- Device: `Rafa`, Flutter/CoreDevice id `00008130-001C152922BA001C`,
  iOS `26.5 23F5043k`, `iPhone 15 Pro (iPhone16,1)`
- Connection: physical iPhone via wireless CoreDevice/local network

## Device discovery

`flutter devices --no-version-check` reported:

```text
Rafa (wireless) (mobile) • 00008130-001C152922BA001C • ios • iOS 26.5 23F5043k
iPhone 15 (mobile)      • F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF • ios • iOS 17.4 simulator
macOS (desktop)         • macos • darwin-arm64
Chrome (web)            • chrome • web-javascript
```

`xcrun devicectl device info details --device 00008130-001C152922BA001C`
reported `marketingName=iPhone 15 Pro`, `productType=iPhone16,1`,
`developerModeStatus=enabled`, `transportType=localNetwork`.

## Evidence folder

`app/doc/runtime_flow_proofs_2026-05-06_physical_iphone_non_scanner_visual/`

Screenshots captured by the passing physical `flutter drive` visual harness:

- `app_full_screenshots/01_login.png`
- `app_full_screenshots/02_register_filled.png`
- `app_full_screenshots/03_home.png`
- `app_full_screenshots/04_decks.png`
- `app_full_screenshots/04a_create_deck_dialog.png`
- `app_full_screenshots/04b_deck_details.png`
- `app_full_screenshots/05_generate.png`
- `app_full_screenshots/06_generate_preview_not_proven.png`
- `app_full_screenshots/07_community.png`
- `app_full_screenshots/08_collection.png`
- `app_full_screenshots/09_profile.png`

## Exact commands

Primary visual capture:

```bash
cd app
MANALOOM_SCREENSHOT_DIR="$PWD/doc/runtime_flow_proofs_2026-05-06_physical_iphone_non_scanner_visual/app_full_screenshots" \
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_full_non_life_counter_visual_capture_smoke_test.dart \
  -d 00008130-001C152922BA001C \
  --publish-port \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --no-version-check
```

Focused physical passes:

```bash
cd app
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/sets_catalog_runtime_test.dart -d 00008130-001C152922BA001C --publish-port --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --dart-define=DISABLE_FIREBASE_STARTUP=true --no-version-check
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/sets_search_catalog_runtime_test.dart -d 00008130-001C152922BA001C --publish-port --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --dart-define=DISABLE_FIREBASE_STARTUP=true --no-version-check
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/collection_entrypoints_runtime_test.dart -d 00008130-001C152922BA001C --publish-port --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --dart-define=DISABLE_FIREBASE_STARTUP=true --no-version-check
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/binder_marketplace_trade_runtime_test.dart -d 00008130-001C152922BA001C --publish-port --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --dart-define=DISABLE_FIREBASE_STARTUP=true --no-version-check
```

Local non-scanner visual/golden validation:

```bash
cd app
flutter analyze lib/features/binder/screens/binder_screen.dart integration_test/binder_dashboard_runtime_test.dart test_driver/integration_test.dart integration_test/app_full_non_life_counter_visual_capture_smoke_test.dart --no-version-check
flutter test test/core/observability/app_observability_test.dart test/features/home/lotus_visual_skin_test.dart test/features/home/life_counter_clone_proof_test.dart --no-version-check
```

## Results matrix

| Scope | Result | Evidence |
| --- | --- | --- |
| Backend public health | `PASS` | `logs/environment_and_health.log` |
| App boot/login/register/home visual | `PASS` | `app_full_screenshots/01_login.png` to `03_home.png` |
| Decks and deck detail visual | `PASS` | `04_decks.png`, `04a_create_deck_dialog.png`, `04b_deck_details.png` |
| Generate screen visual | `PASS` | `05_generate.png` |
| Generate preview | `NOT PROVEN` | Public backend did not produce the synchronous preview expected by the broad visual harness; the UI stayed friendly and captured `06_generate_preview_not_proven.png`. |
| Search/Cards and card detail | `PASS` | `physical_sets_search_catalog_runtime_test_drive.log` |
| Sets/Colecoes and set detail | `PASS` | `physical_sets_catalog_runtime_test_drive.log`, `physical_sets_search_catalog_runtime_test_drive.log` |
| Collection entry points | `PASS` | `physical_collection_entrypoints_runtime_test_drive.log` |
| Binder dashboard | `PASS WITH FIX / RETRY RISK` | Initial run exposed a real RenderFlex overflow; fixed in `binder_screen.dart`. Clean physical rerun was blocked by Flutter Driver extension discovery, but focused UI/golden validation passed and marketplace/trade flow passed after the fix. |
| Marketplace, trades, messages, notifications | `PASS` | `physical_binder_marketplace_trade_runtime_test_after_fix_drive.log` |
| Community and profile visual | `PASS` | `07_community.png`, `09_profile.png` |
| Profile/community deep social navigation | `NOT PROVEN` | Physical reruns hit wireless VM Service/Xcode discovery instability and one product-copy mismatch looking for `Deck Publico`. |
| Life Counter/Lotus | `PASS LOCAL / PHYSICAL NOT PROVEN` | Non-scanner golden/skin tests passed; physical Lotus run hit VM Service resume instability. |
| Scanner/camera/OCR/MLKit scanner | `IGNORED` | Out of scope by request; no scanner route was opened. |

## Visual issue fixed

The physical Binder dashboard lifecycle surfaced:

```text
A RenderFlex overflowed by 38 pixels on the bottom.
```

Safe UI fix:

- `BinderTabContent` now unfocuses the keyboard before applying filters, so the
  set-code filter submit does not leave the keyboard compressing the dashboard.
- The empty Binder CTA row now uses a centered `Wrap`, preventing narrow-screen
  horizontal pressure between "Buscar carta" and "Escanear".

No scanner behavior was changed.

## Risks and blockers

- Physical iOS `flutter drive` over wireless CoreDevice is unstable on this
  device/runtime. Observed failures included VM Service not discovered, Flutter
  Driver extension taking too long, and Xcode debug launch timeouts. These were
  runner/tooling failures, not app crashes.
- `Deck generate -> optimize preview/apply/validate` was not fully re-proven on
  the physical device in this round. The visual harness reached Generate, but
  the public backend did not return the expected synchronous preview in the
  broad visual test.
- The physical dashboard fix needs a stable wired rerun for stronger evidence;
  the original overflow was fixed and no equivalent overflow remained in local
  non-scanner visual tests.

## Smallest next actions

1. Re-run the same physical commands with USB/wired connection to remove the
   wireless VM Service variable.
2. Add a dedicated physical deck optimize harness that seeds a known complete
   deck through API and opens its detail screen directly before optimize.
3. Update the profile/community deep-link expectation to assert the actual
   public deck detail title/name instead of hard-coding fallback copy.
