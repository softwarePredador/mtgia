# Lorehold Hand-Filter Expanded Decision - 2026-06-30

- Scope: protected baseline deck `607`, hand-filter/value candidates from the current miner, full deck-607 exposure profile, natural package gate with `8` real opponents and `3` games per opponent.
- Source DB mutated: `false`.
- PostgreSQL writes: `false`.
- Deck change: `none`.

## What Changed In The Tooling

- `lorehold_card_exposure_profiler.py` now supports `--deck-id`, so it can profile every card in protected deck `607` instead of only a manually listed candidate set.
- The profiler now records `active_effects` and `active_battle_model_scopes` and infers role from active rules when active rules exist. This fixed the Olórin false-positive where disabled generated `draw_cards` rows were mixed with the active `remove_creature` rule.
- `lorehold_hand_filter_cut_model.py` now searches the whole deck-607 non-core cut surface, but blocks cross-lane cuts, protected anchors, active-rule lane mismatches, miracle-core cuts without explicit override, and prior failed/inconclusive natural gates.

## Final Cut Model Result

Current report:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_cut_model_20260630_post_pg270_expanded607_search.md`

Summary:

- Original miner pairs evaluated: `25`.
- Expanded deck-607 pairs evaluated: `445`.
- Normal preflight-ready pairs: `0`.
- Expanded preflight-ready pairs: `0`.
- Expanded miracle-core override-required pairs after prior evidence: `0`.
- Prior rejected or blocked natural pairs: `4`.
- Recommended next action: `do_not_gate_hand_filter_without_new_cut_or_runtime_evidence`.

## Battle Evidence Produced

Gate report:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_expanded_package_gate_20260630_post_pg270_v2_20260630_080110.md`

Results:

| Package | Baseline 607 | Candidate | Decision | Card-Use Interpretation |
| --- | ---: | ---: | --- | --- |
| `+Valakut Awakening // Valakut Stoneforge; -Improvisation Capstone` | `11W/12L/1S` | `7W/17L/0S` | `reject_or_rework` | Candidate had `11` recorded use events; rejection is not invisible-card sampling. |
| `+Wheel of Fortune; -Improvisation Capstone` | `11W/12L/1S` | `9W/15L/0S` | `insufficient_card_outcome_sample` | Candidate had only `3` recorded use events and still lost the natural gate. Exact natural rerun is blocked until a different access hypothesis exists. |
| `+Olórin's Searing Light; -Improvisation Capstone` | `11W/12L/1S` | `12W/12L/0S` | `invalid_cross_lane_learning_only` | The active rule is `remove_creature` / edict, not hand-filter. This positive smoke result must not promote a hand-filter swap. |

## Decision

Do not change deck `607` from this hand-filter expanded pass.

The useful learning is tooling-level: the deckbuilder now stops repeating bad cross-lane cuts and stops trusting disabled generated rule effects when an active rule says the card belongs to another lane. Future Olórin work belongs in interaction/removal benchmarking, not hand-filter.
