# Sensei's Divining Top PG039 focused replay

Generated: 2026-06-22T21:53:06-03:00

## Scenario

- Lorehold has already cast `Approach of the Second Sun` once.
- `Sensei's Divining Top` is on battlefield with three lands and `Lorehold, the Historian`.
- Library top before activation: `Small Creature`, then `Approach of the Second Sun`, then `Mountain`.
- The opponent upkeep rummage window is processed with deterministic RNG seed `123`.

## Rule proof

- `rule_logical_key`: `battle_rule_v1:70c8478871f352b46cee1af296117951`
- `rule_oracle_hash`: `f2c5ac0f52963cd710470adc25cc6d7c`
- `battle_model_scope`: `senseis_top_reorder_draw_lorehold_first_draw_miracle_v1`
- Executor: `{1}` top-three reorder for Lorehold first-draw planning.
- Caveat: the generic activated draw mode is `annotation_only`; PG039 only executes draw-put-self-on-top in the Lorehold first-draw miracle window.

## Event proof

- `topdeck_manipulation_activated` seq 2: Top reordered `Small Creature` into `Approach of the Second Sun` and emitted PG039 key/hash.
- `lorehold_upkeep_rummage` seq 3: discarded `Nine Mana Spell` and drew `Approach of the Second Sun`.
- `miracle_cast` seq 4: cast `Approach of the Second Sun` from the Lorehold opponent-upkeep rummage source.
- `game_won` seq 8: Lorehold won by `approach`.

## Decision proof

- Decision id: `decision-000001`.
- Outcome: `topdeck_reordered_for_first_draw`.
- Chosen card: `Approach of the Second Sun`.
- Risk flags: `upkeep_mana_spend, topdeck_reorder`.

## Artifacts

- Events JSONL: `docs/hermes-analysis/master_optimizer_reports/senseis_top_pg039_focused_events_20260622_215306.jsonl`
- Decision trace JSONL: `docs/hermes-analysis/master_optimizer_reports/senseis_top_pg039_focused_decision_trace_20260622_215306.jsonl`
