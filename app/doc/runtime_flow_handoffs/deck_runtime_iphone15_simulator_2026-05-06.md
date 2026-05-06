# Runtime Flow Handoff — iPhone 15 Simulator — 2026-05-06

## Lotus visual polish proof — 2026-05-06 12:58-13:07 -0300

**PASS** for Lotus visual polish on the primary iPhone 15 Simulator after fixing the visual probe false negative. The app/runtime surface was real Flutter + embedded Lotus WebView on iOS Simulator; backend was **not started** because this Life Counter/Lotus harness uses local stores and bundled WebView assets only.

Concrete simulator target:

```text
iPhone 15 (mobile) • F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF • ios • com.apple.CoreSimulator.SimRuntime.iOS-17-4 (simulator)
```

`xcrun simctl list devices available | grep -E "iPhone 15|Booted"` summary:

```text
iPhone 15 Pro (F3C5B123-673F-4ACC-84B2-489957CB81C8) (Shutdown)
iPhone 15 Pro Max (DABB9D79-2FDB-4585-94DB-E31F1288EE74) (Shutdown)
iPhone 15 (F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF) (Booted)
iPhone 15 Plus (6A3E5508-0190-48AC-B6D1-E4BA8A94FFD9) (Shutdown)
```

Backend:

- URL used by app: **none**.
- Health result: **not applicable** for this harness.
- Backend process cleanup: **not applicable**; no backend was started.

Exact runtime command:

```bash
cd app
flutter test integration_test/life_counter_lotus_visual_runtime_proof_test.dart \
  -d "iPhone 15" \
  --reporter expanded \
  --no-version-check
```

Final result: **PASS** (`00:27 +1`). Sanitized probe evidence:

```json
{"firstLifeText":"40","rawFirstLifeText":"","lifeDigitCount":2,"lifeContentFits":true,"horizontalOverflow":false,"webViewErrorText":false}
{"firstStoredLife":41,"firstLifeText":"41","rawFirstLifeText":"","snapshotLength":845}
{"firstStoredLife":40,"firstLifeText":"40","rawFirstLifeText":"","snapshotLength":845}
{"playerCardCount":4,"firstStoredLife":41,"visibleLifeText":"41","rawVisibleLifeText":"","webViewErrorText":false}
```

Visual inspection:

- Initial table: four players visible, all life totals visually rendered as `40`, no horizontal overflow, no WebView error.
- After `+1`: first player visually rendered as `41`; other players remain visible and readable; contrast remains acceptable on all four quadrants.
- `+1/-1` controls: store changed to `41`, then back to `40`, then persisted `41` before reopen.
- Reopen/persistence: reopened table had four players and first player persisted at `41`.
- No crash, stuck modal, raw 4xx/5xx, timeout copy, secrets, JWT, `DATABASE_URL`, `SENTRY_DSN`, or payload-sensitive output.

Investigation result:

- The previous `firstLifeText=""` and `lifeContentFits=false` were **false negatives in the harness**, not a visual bug.
- Lotus renders life totals as CSS sprite digits (`.font.char-4`, `.font.char-0`) rather than text nodes, so `textContent` is expected to be empty.
- The old fit check measured an individual sprite digit's `scrollWidth/clientWidth`, which is not a reliable "whole life total fits in the life box" assertion.
- The harness now posts `debug_*` probe messages so the app does not treat probe messages as blocked external shell actions, avoiding the artificial snackbar in screenshots.
- The harness decodes visible life totals from `.font.char-*` classes and checks every rendered digit stays inside the `.player-life-count` container.

Evidence artifacts:

| Artifact | Purpose |
| --- | --- |
| `app/doc/runtime_flow_proofs_2026-05-06_lotus_visual_polish_iphone15/life_counter_lotus_runtime_initial_after_probe_fix.png` | Initial four-player visual proof (`40`). |
| `app/doc/runtime_flow_proofs_2026-05-06_lotus_visual_polish_iphone15/life_counter_lotus_runtime_after_plus_after_probe_fix.png` | After `+1` visual proof (`41`). |
| `app/doc/runtime_flow_proofs_2026-05-06_lotus_visual_polish_iphone15/life_counter_lotus_visual_runtime_proof_test_iphone15_after_probe_fix_sanitized.log` | Sanitized runtime markers only; raw base64 screenshot log was not kept. |

Focused validation:

```bash
cd app
dart format integration_test/life_counter_lotus_visual_runtime_proof_test.dart
flutter analyze integration_test/life_counter_lotus_visual_runtime_proof_test.dart test/features/home/lotus_visual_skin_test.dart test/features/home/lotus_life_counter_screen_test.dart test/features/home/lotus_life_counter_internal_shell_test.dart --no-version-check
flutter test test/features/home/lotus_visual_skin_test.dart test/features/home/lotus_life_counter_screen_test.dart test/features/home/lotus_life_counter_internal_shell_test.dart --no-version-check
flutter test test/features/decks/screens/deck_runtime_widget_flow_test.dart --no-version-check
flutter test test/features/decks/screens/deck_details_screen_smoke_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart --no-version-check
```

Results: analyze **PASS**, focused Lotus tests **PASS** (`+21`), deck runtime widget **PASS**, focused deck validation suite **PASS** (`+81`).

Blockers: none. Smallest next action: keep the sprite-aware Lotus visual probe as the release/runtime guard for future polish changes.

## Fresh optimize apply proof — 2026-05-06 12:19-13:05 -0300

**PASS** for the missing fresh runtime proof: the iPhone 15 Simulator applied freshly approved `/ai/optimize` swaps from the live local backend without relying on historical evidence.

The backend was started on `http://127.0.0.1:8082`, `/health` returned healthy, and the focused API probe found an actionable Talrand Commander optimize response: `intensity=focused`, `mode=optimize`, `outcome=optimized`, `swaps=7`, `elapsed_ms=33122`, `timings` present, `stage_telemetry=true`. The probe then applied a partial selection (`deselected=1`, `applied=6`) through the deck update contract and strict validate returned `200`; final deck total stayed `100` and `Talrand, Sky Summoner` remained commander.

The live iPhone 15 run used the same complete healthy Commander fixture and forced the saved strategy to `control` so the UI consumed the safe, approved path instead of the known `Spellslinger` quality-rejected branch. Command:

```bash
cd app && flutter test integration_test/deck_runtime_m2006_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=RUNTIME_OPTIMIZE_INTENSITY_LABEL=Focado \
  --dart-define=RUNTIME_OPTIMIZE_REQUIRE_APPLY=true \
  --dart-define=RUNTIME_OPTIMIZE_FORCE_ARCHETYPE=control \
  --reporter expanded \
  --no-version-check
```

Result: **PASS** (`01:31 +1`). Runtime evidence: `POST /ai/optimize -> 200 (30945ms)`, screenshots/hooks `09_preview`, `09b_preview_partial_selection`, and `10_complete_validated`. The harness unchecked one suggestion before applying, applied only selected swaps, validated final state, preserved commander, and did not show crash, overflow, raw timeout, raw 4xx/5xx, raw payload, stuck modal, JWT, secrets, `SENTRY_DSN`, `DATABASE_URL`, or full prompt.

Harness change: `app/integration_test/deck_runtime_m2006_test.dart` now accepts dart-defines for runtime optimize intensity, required-apply mode, and forced saved archetype. Defaults remain backward-compatible (`Agressivo`, no forced apply), so the existing aggressive diagnostics proof still works, while this targeted run can fail fast if live optimize returns `rebuild_guided` or safe no-op.

Backend cleanup: backend PID `80392` was stopped with `kill 80392`; `lsof -nP -iTCP:8082 -sTCP:LISTEN` returned no listener.

## Final verdict

**PASS WITH RISKS** for final iPhone release QA after optimize upgrades.

The requested release-consolidation runtime was executed on the primary iPhone 15 Simulator against the live local backend on `http://127.0.0.1:8082`. Search/Sets, async deck generation/save/detail, aggressive optimize safe no-op diagnostics, binder dashboard, marketplace/trades/messages/notifications, and Lotus life counter harnesses completed without crash, Flutter overflow failure, stuck modal, raw timeout, raw 4xx/5xx copy, raw payload, JWT, secrets, `SENTRY_DSN`, `DATABASE_URL`, or full prompt exposure in the user-facing UI.

Residual risk: the live backend returned safe no-op/rebuild-guided branches for deck optimize in this consolidation run, so **runtime apply with fresh live suggestions was NOT PROVEN in this specific run**. Historical iPhone 15 evidence from 2026-05-05 remains the proof for selectable preview/partial apply when the backend returns approved swaps. The widget deck suite still proves preview selection and apply mechanics locally.

Scanner/camera/OCR/physical scanner: **DEFERRED / NOT PROVEN** by scope.

## Date/time

- Requested datetime: `2026-05-06T10:55:12.028-03:00`
- Execution window: `2026-05-06T10:55-03:00` through `2026-05-06T11:29-03:00`
- Final local timestamp: `2026-05-06T11:29:27-0300`

## Git and branch synchronization

- Branch target: `master`
- Initial branch: `master`
- Initial working tree before changes: clean.
- Safe sync:
  - `git fetch origin`
  - `git rev-list --left-right --count master...origin/master` returned `0 0`
  - `HEAD`: `e9163a5 (HEAD -> master, origin/master, origin/HEAD) Consolidate release status after optimize upgrades`
- No user changes were overwritten.

## Simulator proof

Concrete simulator id and runtime:

```text
iPhone 15 (mobile) • F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF • ios • com.apple.CoreSimulator.SimRuntime.iOS-17-4 (simulator)
```

`xcrun simctl list devices available | grep -E "iPhone 15|Booted"` summary:

```text
iPhone 15 Pro (F3C5B123-673F-4ACC-84B2-489957CB81C8) (Shutdown)
iPhone 15 Pro Max (DABB9D79-2FDB-4585-94DB-E31F1288EE74) (Shutdown)
iPhone 15 (F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF) (Booted)
iPhone 15 Plus (6A3E5508-0190-48AC-B6D1-E4BA8A94FFD9) (Shutdown)
```

`flutter devices` also detected macOS, Chrome, and one wireless physical iOS device, but the primary proof target was the iPhone 15 Simulator above. Wireless physical-device discovery warnings were ignored because they are out of scope for this run.

## Backend

- Backend URL used by app: `http://127.0.0.1:8082`
- Backend start command:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server && PORT=8082 dart run .dart_frog/server.dart
```

- Health command:

```bash
curl -sS http://127.0.0.1:8082/health
```

- Health result:

```json
{"status":"healthy","service":"mtgia-server","environment":"development","version":"1.0.0","checks":{"process":{"status":"healthy"}}}
```

- Backend stopped at end: **yes**.
- Stop proof: `lsof -nP -iTCP:8082 -sTCP:LISTEN` returned no listener after `kill 31941`.

## Evidence artifacts

- Requested proof folder created: `app/doc/runtime_flow_proofs_2026-05-06_iphone15_release_consolidation/`
- Screenshot capture hooks ran in the deck and Lotus harnesses (`CAPTURE_TAKEN ... bytes=...` in expanded output).
- No separate sanitized log or PNG files were materialized during this run; evidence was captured in command transcripts and summarized here without secrets or raw payloads.

## Commands executed and results

### Baseline

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
git status --short
git fetch origin
git status --short
flutter devices
xcrun simctl list devices available | grep -E "iPhone 15|Booted"
```

Result: **PASS**. Clean before changes; iPhone 15 Simulator booted with id `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`.

### Required app sanity

```bash
cd app && flutter analyze lib/features/decks lib/features/cards lib/features/collection lib/features/binder lib/features/trades test/features/decks --no-version-check && flutter test test/features/decks --no-version-check
```

Result: **PASS**.

- Analyze: no issues.
- Deck tests: `All tests passed`, `+153`.

### Search/Sets runtime

```bash
cd app && flutter test integration_test/sets_search_catalog_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check
```

Result: **PASS** (`00:18 +1`).

Coverage:

- Search Cards tab queried `Black Lotus`.
- Opened card detail through image tap.
- Search Collections tab queried `ECC`.
- Opened `Lorwyn Eclipsed Commander` set detail.
- Navigated back to set catalog.

### Deck Generate async -> save -> detail

```bash
cd app && flutter test integration_test/deck_generate_async_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check
```

First result: **FAIL**, then harness fixed and rerun.

- Failure cause: the live optimize branch returned neither approved suggestions nor the two legacy strings the harness waited for, causing a harness timeout after the deck was already generated, saved, and opened in details.
- Smallest fix implemented: `integration_test/deck_generate_async_runtime_test.dart` now accepts the live product states `Criar reconstrução guiada` and `Nenhuma melhoria segura encontrada` after opening optimize, instead of failing only because the backend chose a safe non-apply branch.

Final result after fix: **PASS** (`01:04 +1`).

Coverage:

- Registered new runtime account.
- Opened Decks.
- Opened Generate screen.
- Async generate showed initial feedback in `459ms`.
- Preview was shown before save.
- Saved generated Commander deck.
- Opened generated deck details through `/decks/<id>`.
- Optimize sheet opened.
- Live backend returned `rebuild_guided` product branch; harness captured `10_rebuild_guided_blocker`.

### Aggressive optimize runtime

```bash
cd app && flutter test integration_test/deck_runtime_m2006_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check
```

Result: **PASS** (`03:07 +1`).

Coverage:

- Registered new runtime account.
- Created deck through UI.
- Opened deck details.
- Imported a complete Talrand Commander list.
- Confirmed commander visibility.
- Opened Optimize.
- Selected `Agressivo`.
- Live backend returned safe no-op / quality rejected diagnostics.
- UI showed friendly diagnostics and did not expose raw technical strings.
- Harness asserted no `aggressive_candidate_quality` or `quality_gate_rejected` raw UI text.

Not proven in this run:

- Fresh live apply with suggestions, because no suggestions survived the backend quality gate in the aggressive run.
- Final validate after apply, because no apply was available in this no-op branch.

### Binder dashboard runtime

```bash
cd app && flutter test integration_test/binder_dashboard_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check
```

Result: **PASS** (`00:37 +1`).

Coverage:

- Registered/login via live backend.
- Opened collection/binder dashboard.
- Checked dashboard summary and wishlist.
- Searched and added `Sol Ring`.
- Edited binder item.
- Applied set filter.
- Deleted binder item.

### Marketplace / Trades / Messages / Notifications runtime

```bash
cd app && flutter test integration_test/binder_marketplace_trade_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check
```

Result: **PASS** (`01:45 +2`).

Coverage:

- Seller/buyer runtime accounts.
- Binder editor add/edit/delete.
- Marketplace listing/search.
- Create sale proposal.
- Trade detail lifecycle.
- Trade messages.
- Notifications list, mark read, mark all read.
- Direct messages conversation, send, read receipt.

### Life Counter / Lotus runtime

```bash
cd app && flutter test integration_test/life_counter_lotus_visual_runtime_proof_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check
```

Result: **PASS** (`00:28 +1`).

Coverage:

- Lotus life counter WebView runtime loaded.
- Four-player state available.
- Plus/minus changed persisted life value.
- Reopen restored state.
- No horizontal overflow and no WebView unavailable copy.

Observed risk:

- Probe reported `lifeContentFits=false` and empty visible life text, but the harness passed because stored state and no-overflow gates were satisfied. Keep this as a UI polish risk for Lotus visual fidelity, not a release blocker for this requested runtime.

### Required validation before commit

```bash
cd app && flutter test test/features/decks/screens/deck_runtime_widget_flow_test.dart --no-version-check
```

Result: **PASS** (`+1`).

```bash
cd app && flutter test test/features/decks/screens/deck_details_screen_smoke_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart --no-version-check
```

Result: **PASS** (`+81`).

Additional changed-harness check:

```bash
cd app && flutter analyze integration_test/deck_generate_async_runtime_test.dart --no-version-check
```

Result: **PASS**, no issues.

## What was real vs mocked

Real:

- iPhone 15 Simulator UI/runtime.
- Live local Dart Frog backend on port `8082`.
- App HTTP calls through `API_BASE_URL` / `PUBLIC_API_BASE_URL`.
- Auth/register/login, cards, sets, deck generate, deck save/detail, optimize, binder, marketplace, trades, messages, notifications endpoints.
- Lotus life counter widget/WebView harness on simulator.

Mocked/controlled:

- No scanner/camera/OCR runtime was executed.
- Some integration harnesses seed runtime data directly through backend HTTP before driving UI so the app can start from deterministic accounts/cards/binder/trade states.
- Widget validation suite uses mocked providers/API for local deck apply mechanics.

## Blockers and ownership

1. **Live apply with fresh optimize suggestions not proven in this consolidation run**
   - Owner: backend optimize quality/data + mobile runtime QA for rerun.
   - Detail: live aggressive optimize returned safe no-op diagnostics; async generated deck optimize returned `rebuild_guided`.
   - Smallest next action: run a known fixture/deck that produces approved swaps on `8082`, then rerun `deck_runtime_m2006_test.dart` or add a deterministic live seed for approved suggestions.

2. **Lotus visual probe reported content-fit risk**
   - Owner: app/home/Lotus UI.
   - Detail: stored life state was correct and no horizontal overflow occurred, but the probe saw empty visible life text / `lifeContentFits=false`.
   - Smallest next action: add one focused visual assertion/update for life text rendering in `life_counter_lotus_visual_runtime_proof_test.dart`.

3. **iOS simulator build warning for Apple Silicon iOS 26+ arm64 support**
   - Owner: app/iOS dependency maintenance.
   - Detail: Flutter emitted plugin target support warnings, but Xcode build completed and tests ran on iOS 17.4 iPhone 15.
   - Smallest next action: audit iOS plugin versions before adopting iOS 26+ simulator runtime as primary.

## Final status

- Final verdict: **PASS WITH RISKS**.
- Backend 8082 stopped: **yes**.
- Worktree after runtime, before docs commit: changed harness + docs only.
- Push/commit status: to be completed after this handoff update.
