# Lorehold Discard Ramp Value / Monument Decision - 2026-06-30

Status: `all_current_same_lane_replacements_rejected_keep_monument`.

Scope:

- protected baseline: deck `607`;
- package lane: `discard_ramp_value_benchmark`;
- tested cut: `Monument to Endurance`;
- tested additions: `Cool but Rude`, `Currency Converter`,
  `Glint-Horn Buccaneer`, `Magmakin Artillerist`, and `Surly Badgersaur`;
- gate: natural equal package gate, no forced access, `8` real opponents,
  `3` games per opponent, opponent seed `20260629`, simulation seed
  `20260630`.

Why this lane exists:

- `Monument to Endurance` is not generic ramp. In the current Lorehold shell it
  is a discard-trigger value/ramp payoff tied to hand filtering, treasure, and
  opponent life-loss pressure.
- The profiled-cut generator now supports this role as
  `discard_ramp_value`, and can target a specific cut through `--cut-card`
  using the full manual-review expansion instead of only the top automatic
  candidates.

Package results:

| Package | Add | Cut | Baseline | Candidate | Winota baseline | Winota candidate | Card-use evidence | Decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `cool_but_rude_same_lane_benchmark_cut_monument_to_endurance` | `Cool but Rude` | `Monument to Endurance` | `11W/12L/1S` | `9W/15L/0S` | `2W/1L/0S` | `0W/3L/0S` | `Cool but Rude` used `20` times, accessed in `4` games | `reject_or_rework` |
| `currency_converter_same_lane_benchmark_cut_monument_to_endurance` | `Currency Converter` | `Monument to Endurance` | `11W/12L/1S` | `11W/13L/0S` | `2W/1L/0S` | `1W/2L/0S` | `Currency Converter` used `41` times, accessed in `8` games | `reject_regresses_critical_matchup` |
| `glint_horn_buccaneer_same_lane_benchmark_cut_monument_to_endurance` | `Glint-Horn Buccaneer` | `Monument to Endurance` | `11W/12L/1S` | `10W/14L/0S` | `2W/1L/0S` | `0W/3L/0S` | `Glint-Horn Buccaneer` used `13` times, accessed in `7` games | `reject_regresses_critical_matchup` |
| `magmakin_artillerist_same_lane_benchmark_cut_monument_to_endurance` | `Magmakin Artillerist` | `Monument to Endurance` | `11W/12L/1S` | `7W/17L/0S` | `2W/1L/0S` | `1W/2L/0S` | `Magmakin Artillerist` used `16` times, accessed in `11` games | `reject_regresses_critical_matchup` |
| `surly_badgersaur_same_lane_benchmark_cut_monument_to_endurance` | `Surly Badgersaur` | `Monument to Endurance` | `11W/12L/1S` | `10W/14L/0S` | `2W/1L/0S` | `0W/3L/0S` | `Surly Badgersaur` used `6` times, accessed in `7` games | `reject_regresses_critical_matchup` |

Decision:

- Keep `Monument to Endurance` in protected deck `607`.
- Do not promote `+Cool but Rude; -Monument to Endurance`.
- Do not promote `+Currency Converter; -Monument to Endurance`.
- Do not promote `+Glint-Horn Buccaneer; -Monument to Endurance`.
- Do not promote `+Magmakin Artillerist; -Monument to Endurance`.
- Do not promote `+Surly Badgersaur; -Monument to Endurance`.
- `Currency Converter` and the other tested discard-payoff creatures remain
  coherent Lorehold cards, but `Monument to Endurance` is not the safe cut for
  them in the current shell. All tested replacements either lost total wins,
  regressed Winota, or both.

Tooling changes made for this decision:

- `lorehold_profiled_cut_benchmark_generator.py` now supports the
  `discard_ramp_value` role and `--cut-card`.
- `lorehold_synergy_package_gate.py` now rejects a package as
  `reject_regresses_critical_matchup` when a critical matchup, currently
  Winota-style fast pressure, drops versus `607`.
- `lorehold_synergy_seed_matrix.py` now carries critical matchup records into
  aggregate confirmation decisions.

Evidence artifacts:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_benchmark_generator_20260630_goal_learning_discard_ramp_value_monument.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_benchmark_generator_20260630_goal_learning_discard_ramp_value_monument_remaining.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_discard_ramp_value_monument_gate_20260630_goal_learning_smoke_20260630_210849.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_currency_converter_monument_gate_20260630_goal_learning_critical_guard_20260630_212135.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_discard_ramp_value_monument_remaining_gate_20260630_goal_learning_smoke_20260630_213021.md`

Next coherent work:

- Do not keep testing one-for-one replacements over `Monument to Endurance`
  from the current discard-ramp-value candidate pool. The current pool has
  been exhausted and failed the protected baseline.
- If `Currency Converter` is revisited, test it as an addition paired with a
  safer cut from the same strategic risk budget, not as a direct replacement
  for `Monument to Endurance`.
