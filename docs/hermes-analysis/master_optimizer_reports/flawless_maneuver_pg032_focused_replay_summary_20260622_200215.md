# Flawless Maneuver PG032 Focused Event Proof

Generated: 2026-06-22 20:10 UTC

Artifacts:

- Events: `docs/hermes-analysis/master_optimizer_reports/flawless_maneuver_pg032_focused_events_20260622_200215.jsonl`

Rule evidence:

- logical_rule_key: `battle_rule_v1:73622071c1ad89267708f914a0729bf2`
- oracle_hash: `fa955216fa827bf75c5b79dcbdb4b97e`
- active effect: `indestructible`
- battle_model_scope: `flawless_maneuver_control_commander_free_creatures_indestructible_until_eot_v1`

Scenario:

- Lorehold controlled `Lorehold, the Historian` as commander and had zero available mana.
- Opponent had `Blasphemous Act` on the stack as a damage wipe.
- `Flawless Maneuver` was cast as a response with `alternative_cost={0}` and `alternative_cost_kind=control_commander`.
- `protection_resolved` granted indestructible to the two creatures Lorehold controlled.
- `Blasphemous Act` resolved; Lorehold's commander and protected creature survived, and the opponent creature was removed.

Caveat:

- This proof covers the oracle protection mode under a board-wipe response. It does not claim broader Magic rules equivalence beyond creatures you control gaining indestructible until end of turn.
