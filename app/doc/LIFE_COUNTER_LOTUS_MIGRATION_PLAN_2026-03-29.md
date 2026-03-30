# Life Counter Lotus Migration Plan - 2026-03-29

## Objective

Turn the validated Lotus copy into a ManaLoom-owned life counter without losing the current `1:1` behavior, layout, gestures, or game flow.

This plan assumes:

- the current Lotus embed is the official baseline
- parity with the original app has already been validated
- future customization must happen in controlled phases

## Current baseline

### Source of truth today

- route: `app/lib/main.dart`
- host screen: `app/lib/features/home/lotus_life_counter_screen.dart`
- Flutter bundle copy: `app/assets/lotus/`
- route constant: `app/lib/features/home/life_counter_route.dart`
- local Android asset mirror: `app/android/app/src/main/assets/lotus/`
  - stale local artifact only
  - not an active runtime contract
- legacy Flutter implementation kept only as fallback/reference:
  - `app/lib/features/home/life_counter_screen.dart`

### Validated state

- `143/144` files from the original Lotus `base.apk` match byte-for-byte
- the only intentional delta is `index.html`, where `cordova.js` is replaced by `flutter_bootstrap.js`
- bridges validated in runtime:
  - `cordova`
  - `AppReview`
  - `clipboard`
  - `insomnia`
- stable board screenshots are effectively equivalent to the original Lotus render

## Architecture target

The migration should move from this:

`Flutter host -> WebView -> Lotus bundle`

To this:

`Flutter host -> ManaLoom counter modules`

But not in one rewrite.

The safe end-state is:

1. `Host layer`
   - route
   - lifecycle
   - fullscreen behavior
   - platform bridges
   - analytics and logging

2. `Compatibility layer`
   - the embedded Lotus bundle
   - parity screenshots
   - bridge shims
   - feature flags for fallback

3. `Owned feature slices`
   - settings
   - timers
   - history
   - card search integration
   - player card interactions
   - game modes

4. `Final native screen`
   - all critical gameplay owned by ManaLoom
   - Lotus bundle removable without regressions

## Non-negotiable rules

- Do not modify the Lotus bundle unless the change is strictly required for hosting, bridging, or verified product customization.
- Prefer changing the Flutter host first, not the copied Lotus internals.
- Any native replacement must keep a parity checklist against the current Lotus baseline.
- Never replace multiple gameplay surfaces at once.
- Keep the current embedded Lotus path runnable until the native replacement for that slice is fully validated.

## Migration phases

### Phase 0 - Freeze the baseline

Status:

- completed technically
- needs to be treated as a product baseline from now on

Goal:

- stop treating the counter as an experiment
- lock the current Lotus embed as the official reference implementation

Work:

- keep `/life-counter` pointing to `LotusLifeCounterScreen`
- treat `life_counter_screen.dart` as legacy
- keep `app/assets/lotus/` as the only runtime source of truth
- do not treat `android/app/src/main/assets/lotus/` as an active runtime requirement
- preserve emulator screenshots and parity evidence for regression checking

Exit criteria:

- team agrees that Lotus embed is the live baseline for the counter
- no active navigation path depends on the old Flutter counter

### Phase 1 - Harden the host shell

Goal:

- make the embed stable, testable, and easier to evolve without touching the Lotus bundle

Work:

- extract WebView-specific logic into a small host layer:
  - `lotus_host_controller`
  - `lotus_js_bridges`
  - `lotus_runtime_flags`
- centralize bridge names and responsibilities
- add structured logs for:
  - page boot
  - bridge health
  - load failures
  - external navigation attempts
- add a repeatable smoke-test checklist for emulator validation
- add a script or documented command set for reinstall + launch + screenshot capture

Exit criteria:

- the host can be debugged without reading minified Lotus code
- bridge regressions are detectable quickly
- cold start, resume, and reload behavior are predictable

### Phase 2 - Own the shell around Lotus

Goal:

- make the counter feel like part of ManaLoom even while Lotus still powers gameplay

Work:

- align route ownership and entry points in the app
- replace Lotus-specific external messaging where appropriate:
  - app name references
  - external support links
  - promo copy that does not belong in ManaLoom
- decide which links should:
  - stay external
  - open in app
  - be removed
- add analytics around:
  - open counter
  - leave counter
  - use menu/settings/history/search

Exit criteria:

- the counter is clearly a ManaLoom surface
- branding mismatches are removed from the product shell
- no critical product flow depends on Lotus-owned external destinations

### Phase 3 - Replace integrations before replacing gameplay

Goal:

- own the edges first, not the core gameplay logic

Work:

- own persistence boundaries
- own clipboard/export/import boundaries
- own review/share/open-link behaviors
- define a stable storage contract for:
  - game state
  - settings
  - player customizations
- decide whether Lotus local storage remains temporary compatibility storage or becomes migrated data

Exit criteria:

- platform/native integrations are ManaLoom-owned
- we can change app-level behavior without patching Lotus internals

### Phase 4 - Replace feature slices one at a time

Goal:

- progressively move gameplay from Lotus bundle to native Flutter modules without losing parity

Recommended order:

1. settings and non-gameplay overlays
2. timers and turn tracker
3. history and import/export
4. card search integration
5. player counters and player options
6. commander damage interactions
7. game modes:
   - Planechase
   - Archenemy
   - Bounty

For each slice:

- create a parity checklist against the Lotus behavior
- implement the native slice behind a feature flag
- validate against screenshots and gesture flows
- keep Lotus fallback alive until the slice is stable

Exit criteria:

- each slice can be enabled independently
- regressions are isolated to one slice at a time

### Phase 5 - Compose the native ManaLoom counter

Goal:

- merge the replaced slices into a single owned counter architecture

Work:

- define native state model for the whole game
- define shared services:
  - session persistence
  - player model
  - counters model
  - game modes model
  - history model
- create modular UI surfaces matching the Lotus interaction model
- keep gesture behavior identical until an explicit redesign phase starts

Exit criteria:

- the native screen can reproduce the current Lotus core flow end-to-end
- the embed is no longer required for primary gameplay

### Phase 6 - Retire the embedded Lotus bundle

Goal:

- remove the compatibility layer only when it is no longer needed

Work:

- delete WebView route
- delete Lotus bundle assets
- delete temporary bridges and compatibility flags
- keep final parity screenshots and migration notes archived

Exit criteria:

- native counter is production-ready
- removal of Lotus assets does not remove any supported feature

## Immediate execution order

### Now

- treat the embedded Lotus as the official baseline
- keep parity evidence and smoke steps documented
- stop investing in the old Flutter counter implementation

### Next

- Phase 1: harden the host shell
- Phase 2: own the shell around Lotus

### After that

- start Phase 3 and Phase 4 with small, isolated slices

## Recommended first owned slices

If the goal is to reduce risk while keeping fidelity, the first slices should be:

1. settings shell
   - low gameplay risk
   - high product ownership value

2. timers and turn tracker
   - contained logic
   - highly visible
   - easier to parity-test than all player interactions at once

3. history and import/export
   - strong product value
   - lets ManaLoom own data boundaries early

Avoid as the first native slice:

- full player card rewrite
- commander damage interaction rewrite
- all game modes in one sprint

## Definition of done for the migration

The migration is only done when all of the following are true:

- no critical counter feature depends on the embedded Lotus bundle
- the native ManaLoom counter reproduces the current Lotus baseline behavior
- gesture behavior is preserved or intentionally redesigned
- platform integrations are owned by ManaLoom
- the old `life_counter_screen.dart` and the Lotus embed can be removed safely

## Practical next task

The next engineering task should be:

### `LC-HOST-01 - Extract and harden the Lotus host shell`

Scope:

- refactor `lotus_life_counter_screen.dart`
- isolate JS bridges
- isolate runtime flags
- document smoke validation
- keep behavior unchanged

Why this comes first:

- it improves maintainability immediately
- it reduces future risk
- it does not disturb the validated `1:1` counter behavior
