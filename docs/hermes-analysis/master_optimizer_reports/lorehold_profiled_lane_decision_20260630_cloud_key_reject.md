# Lorehold Profiled Lane Decision - 2026-06-30

- Scope: protected baseline deck `607`, profiled same-lane cut surface, Lorehold variants `608-616`, natural battle gate against `8` real opponents x `3` games.
- Source DB mutated: `false`.
- PostgreSQL writes: `false`.
- Deck change: `none`.

## External/Contract Context

The Commander contract remains the source of operating logic: do not replace a protected baseline card unless the new card competes in the same lane and ties or beats deck `607` with card-use evidence. External Commander sources are evidence lanes only; they do not promote a card without local legality, runtime, strategy, and battle proof.

Reference URLs kept in scope for this lane:

- `https://edhrec.com/commanders/lorehold-the-historian`
- `https://edhrec.com/articles/how-to-build-a-commander-deck`
- `https://commanderspellbook.com/`

## Removal Lane Result

Report:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_benchmark_generator_20260630_removal_lane_audit.md`

Result:

- Requested cut role: `spot_removal`.
- Profiled removal cuts evaluated: `2`.
- Candidate pool: `270`.
- Pair evaluations: `540`.
- Preflight-ready pairs: `0`.
- Selected packages: `0`.

Interpretation:

- Interaction/removal is not ready for another natural gate from this profiled surface.
- `Chaos Warp` over `Stroke of Midnight` is blocked by prior exact reject.
- `Olórin's Searing Light`, `Razorgrass Ambush // Razorgrass Field`, `Lightning Bolt`, `Wear // Tear`, `Abrade`, and similar cards do not match the `Stroke of Midnight` permanent-removal scope.
- Prior positive-looking Olórin evidence remains interaction/removal learning only, not a hand-filter promotion and not a same-scope `Stroke` replacement.

## All-Lane Preflight Result

Report:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_benchmark_generator_20260630_all_lanes_preflight.md`

Result:

- Profiled cuts evaluated: `4`.
- Candidate pool: `270`.
- Pair evaluations: `1080`.
- Preflight-ready pairs before gate: `1`.
- Selected package: `+Cloud Key; -Bender's Waterskin`.

This was valid to test only because it is a same-function ramp/cost-reduction benchmark and the protected-cut registry allowed a same-function challenge.

## Natural Gate Result

Gate report:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_cloud_key_waterskin_gate_20260630_all_lanes_20260630_082705.md`

Result:

| Package | Baseline 607 | Candidate | Delta | Decision |
| --- | ---: | ---: | ---: | --- |
| `+Cloud Key; -Bender's Waterskin` | `11W/12L/1S` | `9W/15L/0S` | `-8.33pp` | `reject_or_rework` |

Card-use proof:

- `Cloud Key`: `15` recorded use events, accessed in `6` games, used-game record `4W/1L/0S`.
- `Bender's Waterskin`: `8` recorded use events, accessed in `5` games, used-game record `1W/3L/0S`.

The rejection is therefore not an invisible-card sampling artifact. The card was exercised and still lost the natural gate.

Strategic regression:

- `miracle_cast`: `48 -> 38` (`-10`).
- `lorehold_cost_paid`: `254 -> 231` (`-23`).
- `lorehold_spell_cast`: `240 -> 229` (`-11`).
- `lorehold_upkeep_rummage`: `95 -> 49` (`-46`).
- `topdeck_manipulation_activated`: `32 -> 50` (`+18`), but this did not convert into wins.
- Fast pressure: Winota fell from `2W/1L` to `0W/3L`.

Decision:

- Keep `Bender's Waterskin` protected in deck `607`.
- Do not rerun exact `+Cloud Key; -Bender's Waterskin` unless a materially different package hypothesis changes the cut lane.

## Post-Rejection Queue

Report:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_benchmark_generator_20260630_post_cloud_key_reject.md`

Result:

- Pair evaluations: `1080`.
- Preflight-ready pairs: `0`.
- Selected packages: `0`.
- Recommended next action: `no_profiled_cut_benchmark_package_ready`.

Next product step:

- Leave this profiled cut surface.
- Move to a different lane with a new hypothesis, preferably pressure/protection or a fresh source-backed package that does not cut protected miracle/ramp anchors.
