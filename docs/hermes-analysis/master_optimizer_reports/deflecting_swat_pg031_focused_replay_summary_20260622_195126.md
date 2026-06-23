# Deflecting Swat PG031 Focused Event Proof

Generated: 2026-06-22 19:51 UTC

Artifacts:

- Events: `docs/hermes-analysis/master_optimizer_reports/deflecting_swat_pg031_focused_events_20260622_195126.jsonl`

Rule evidence:

- logical_rule_key: `battle_rule_v1:bac48343654a53205d790a8268bd2631`
- oracle_hash: `a34c89817f87f32bedfb3d66a5bdc672`
- active effect: `redirect_removal`
- battle_model_scope: `deflecting_swat_control_commander_free_redirect_target_spell_or_ability_v1`

Scenario:

- Lorehold controlled `Lorehold, the Historian` as commander and had zero available mana.
- Opponent had a single-target creature removal spell on the stack targeting `Protected Creature`.
- `Deflecting Swat` was cast as a response with `alternative_cost={0}` and `alternative_cost_kind=control_commander`.
- `redirect_removal_resolved` changed the removal target from `Protected Creature` to `Opponent Threat`.
- The redirected removal resolved, preserving `Protected Creature` and removing `Opponent Threat`.

Caveat:

- PG031 stores the full oracle target class as `target_spell_or_ability`, but the current runtime proof covers `single_target_targeted_removal_spell`; activated/triggered ability target redirection remains `annotation_only` metadata.
