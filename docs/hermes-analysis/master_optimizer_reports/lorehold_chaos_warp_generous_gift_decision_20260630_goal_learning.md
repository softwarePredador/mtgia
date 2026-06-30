# Lorehold Chaos Warp / Generous Gift Decision - 2026-06-30

## Scope

- Baseline: protected deck `607`.
- Candidate package: `chaos_warp_same_lane_benchmark_cut_generous_gift`.
- Added card: `Chaos Warp`.
- Cut card: `Generous Gift`.
- Lane: `interaction_removal_benchmark`.
- PostgreSQL writes: `false`.
- Source DB mutated: `false`.

## Why This Was Tested

The current safe-cut replanner found no automatic gate-ready swaps from deck
`607`, but the manual exposure review identified `Generous Gift` as a measured
spot-removal cut candidate that required same-lane benchmarking. `Chaos Warp`
was selected because it is an active-rule spot-removal card already present in
Lorehold variants and does not require cutting protected miracle, ramp, or
pressure-window anchors.

This was a removal-lane comparison, not a generic "strong card" test.

## Evidence

Smoke gate:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_chaos_warp_generous_gift_gate_20260630_goal_learning_smoke_20260630_205058.md`
- Opponents: `8` real opponent decks.
- Games: `3` per opponent, `24` total per side.
- Baseline `607`: `11W/12L/1S`, `45.83%`.
- Candidate: `14W/10L/0S`, `58.33%`.
- Delta: `+12.50 pp`.
- Candidate card-use proof: `Chaos Warp` recorded `31` use events, was accessed
  in `10/24` games, used in `9/24` games, and those used games ended
  `8W/1L/0S`.
- Baseline cut-card proof: `Generous Gift` recorded `9` use events and was
  accessed in `4/24` games.

Confirmation seed matrix:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_chaos_warp_generous_gift_seed_matrix_20260630_goal_learning_confirm_20260630_205527.md`
- Seeds: `20260630`, `123`, `999`.
- Games: `72` total per side.
- Baseline `607`: `27W/44L`.
- Candidate: `30W/42L`.
- Aggregate delta: `+3.64 pp`.
- Average seed delta: `+4.17 pp`.
- Seed `999` regressed: candidate `10/24` versus `607` `11/24`.
- Critical matchup: Winota fell from baseline `4W/5L` to candidate `3W/6L`.

## Decision

Reject this exact swap.

The card was genuinely exercised, and the aggregate signal is positive, but
Lorehold promotion requires preserving fast-pressure matchups. The candidate
worsened the Winota critical matchup, so `Generous Gift` remains protected in
the current `607` shell unless a future same-lane interaction package can keep
or improve the Winota record while also beating the protected baseline.

## Next Action

Do not rerun `+Chaos Warp / -Generous Gift` as a promotion candidate without a
new hypothesis that specifically repairs fast-pressure performance. The next
deck-learning work should move to an unsupported same-lane model, currently the
`discard_ramp_value` lane around `Monument to Endurance`, or produce a new
cut-safe package that protects Winota, miracle cadence, and the `607` anchor
set from the start.
