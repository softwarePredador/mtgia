# Lorehold Access Density Control Decision - 2026-06-30

- generated_at: `2026-06-30`
- postgres_writes: `false`
- source_db_mutated: `false`
- protected_baseline: `deck_607`
- candidate: `challenger_lorehold_access_density_control_v1`

## Decision

- Do not promote `challenger_lorehold_access_density_control_v1`.
- Do not spend a confirmation gate on this exact from-scratch shell.
- Keep `607` protected.
- Treat `Enlightened Tutor` and `Gamble` as runtime-valid but still cut-sensitive: the current evidence does not justify cutting a protected engine slot or adding an overfilled access shell.

## Evidence

Builder report:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_access_density_control_v1.json`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_access_density_control_v1_access_density_control.json`

Strategy matrix:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_access_density_control_v1_access_density_control_matrix.json`
- Candidate was legal and structurally coherent enough to smoke-test, but overfilled `topdeck_miracle_setup`, `hand_filter`, `spell_chain_conversion`, and `graveyard_recursion`.

Natural smoke gate:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_access_density_control_v1_access_density_control_fixed607_gate.json`
- `deck_607`: `1/4`
- `challenger_lorehold_access_density_control_v1`: `0/4`
- Natural tutor exposure was insufficient: no `Enlightened Tutor` or `Gamble` card-event counts were observed for the challenger.

Forced tutor access gate:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_access_density_control_v1_access_density_control_forced_tutors_pipe_opening_gate.json`
- Forced mode: `opening_hand`
- Focus cards: `Enlightened Tutor|Gamble`
- `deck_607`: `1/4`
- `challenger_lorehold_access_density_control_v1`: `0/4`
- Candidate tutor evidence:
  - `Enlightened Tutor`: accessed `4/4`, opening hand `4/4`, cost-paid `3`, spell-cast `3`, resolved `4`
  - `Gamble`: accessed `4/4`, opening hand `4/4`, cost-paid `3`, spell-cast `3`, resolved `2`

## Interpretation

The current blocker is not simply "add more access." When access was forced, the
shell still failed to convert. The likely issue is package density and timing:
the candidate overfilled topdeck/filter/spell-chain/recursion lanes and did not
preserve enough conversion efficiency under pressure.

## Next Action

Continue from the corrected queue:

1. Do not rerun this exact access-density shell.
2. Build a smaller same-lane/access package only if a cut model identifies a non-protected slot.
3. Prefer learning from existing `607` traces and narrow same-lane packages over adding multiple tutors plus recursion/filter density at once.
