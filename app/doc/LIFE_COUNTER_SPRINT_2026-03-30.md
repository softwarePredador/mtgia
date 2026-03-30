# Life Counter Sprint - 2026-03-30

## Goal

Move the live life counter one slice closer to being ManaLoom-owned without changing the current Lotus-faithful tabletop layout.

This sprint stays out of the central board rendering. The priority is to take ownership of the first replaceable product surfaces: `settings`, then `history`, then `search`.

## Current state

Already validated on the live path:

- embedded Lotus remains the official tabletop baseline
- Flutter host owns boot, loading, error, retry, shell policy, and observability
- canonical session and canonical settings exist outside Lotus storage
- canonical bootstrap back into Lotus works
- runtime settings visual signals are validated for:
  - `setLifeByTappingNumber`
  - `verticalTapAreas`
  - `cleanLook`
  - counters on card
  - commander damage counters
  - clock and game timer surfaces
- player-count bootstrap coverage is validated in isolated runtime tests for:
  - 2 players
  - 5 players
  - 6 players

Now ManaLoom-owned in the live experience:

- settings UI surface
- history surface
- card search surface

Still Lotus-owned in the live experience:

- history import/export behavior
- tabletop gameplay runtime itself

## Main risks

- changing the board or gestures before we own settings/history/search would spend risk in the wrong place
- multi-scenario integration tests are flaky when the same WebView process is reused across scenarios
- some Lotus runtime pointers, especially around turn-tracker bootstrap in 6-player layouts, can normalize during live boot and should be treated carefully in parity tests

## Sprint scope

### LC-SPRINT-01 - Settings contract ownership

Deliverables:

- make the ManaLoom settings model easier to drive from native UI
- define a typed catalog of sections and setting fields
- ensure settings can be rendered by section without depending on Lotus naming

Done when:

- settings have a `copyWith`
- a typed settings catalog exists
- tests prove the catalog covers every supported field exactly once

### LC-SPRINT-02 - Native settings shell groundwork

Deliverables:

- define the section order and product copy for the future native settings sheet
- keep the current live board untouched
- prepare Flutter-owned settings UI to target the canonical settings store, not Lotus internals

Done when:

- section/grouping is no longer implicit in the old legacy screen or minified Lotus runtime
- host and future UI can share the same settings catalog

### LC-SPRINT-03 - Runtime validation hardening

Deliverables:

- keep player-count smokes isolated by runtime
- avoid sharing multiple player-count scenarios in one WebView process
- preserve the settings UI smoke for visible runtime changes

Done when:

- isolated smokes exist for 2, 5 and 6 players
- settings UI smoke still passes on the live WebView path

## Out of scope

- replacing the main tabletop board
- replacing commander damage UI
- replacing card search in this same sprint
- removing the Lotus bundle

## Recommended next sequence after this sprint

1. Move history import/export into ManaLoom-owned contracts.
2. Harden runtime validation for native search interactions beyond the open-shell smoke.
3. Keep the central Lotus tabletop untouched until settings/history/search are all owned end-to-end.
