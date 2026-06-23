# PG035 Lorehold, the Historian Focused Replay Summary

Generated at: 2026-06-22T20:45:49Z

## Scope

Focused deterministic proof for `Lorehold, the Historian` after PG035. This is a card-level replay/event proof, not a full 16-seed deck battle matrix and not evidence for a deck swap.

## Source Rule

- logical_rule_key: `battle_rule_v1:06d892f8ad75831f785aef6dcedc82b4`
- oracle_hash: `f1b6d4f38a533e56f0efb5a3f1547214`
- battle_model_scope: `lorehold_opponent_upkeep_miracle_v1`
- runtime model: opponent-upkeep discard-then-draw trigger plus first-draw miracle window for instants/sorceries in hand.

## Result

- triggered rummage count: `1`
- rummage event emitted: `True`
- rummage discarded: `Nine Mana Spell`
- rummage drew: `Reforge the Soul`
- event rule_logical_key: `battle_rule_v1:06d892f8ad75831f785aef6dcedc82b4`
- event rule_oracle_hash: `f1b6d4f38a533e56f0efb5a3f1547214`
- miracle event emitted after rummage draw: `False`

## Artifacts

- events: `docs/hermes-analysis/master_optimizer_reports/lorehold_historian_pg035_focused_events_20260622_204549.jsonl`
- decision trace: `docs/hermes-analysis/master_optimizer_reports/lorehold_historian_pg035_focused_decision_trace_20260622_204549.jsonl`
