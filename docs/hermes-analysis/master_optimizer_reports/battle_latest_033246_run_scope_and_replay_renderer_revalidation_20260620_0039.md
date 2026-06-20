# Battle Latest 033246 Run Scope and Replay Renderer Revalidation

Timestamp: 2026-06-20 00:39 -03.

Scope: close `BV-081` and revalidate the temporary `BV-089` damage-cause
regression observed in run `20260620_032709`. No PostgreSQL write, deck swap,
commit, or push was performed.

## Code Changes

- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
  now publishes `run_profile`, `run_scope`, `invocation_kind`,
  `seeds_source`, `start_seed_source`, and `run_scope_contract`.
- `SEEDS=1` maps to `run_scope=focused_seed` and
  `run_profile=focused_single_seed`.
- `SEEDS=16` maps to `run_scope=recurring_full` and
  `run_profile=recurring_16_seed`.
- `battle_replay_v10_3.py` now renders `damage_resolved.cause` from
  `cause -> effect -> reason -> source -> card -> ?`.
- `test_battle_replay_v10_3_renderer.py` now covers `Lightning Bolt` damage
  with no explicit `cause`, `effect`, or `reason`.

## Validation Evidence

- `bash -n /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
  - PASS.
- Dry-run `--seeds 1 --start-seed 63219981`
  - log includes `run_profile=focused_single_seed run_scope=focused_seed invocation_kind=manual_cli`.
- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py`
  - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py`
  - PASS, 9 tests.
- Re-render of `20260620_032709`
  - `original_cause_unknown=1`, `rerendered_cause_unknown=0`.

## Focused Run

Artifact: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_033208/summary.json`

- `run_scope=focused_seed`
- `run_profile=focused_single_seed`
- `invocation_kind=manual_cli`
- `seeds_requested=1`
- `seeds_completed=1`
- `start_seed=63219981`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- human replay placeholder counters all `0`

## Recurring Run

Artifact: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_033246/summary.json`

- `run_scope=recurring_full`
- `run_profile=recurring_16_seed`
- `invocation_kind=default_or_scheduled`
- `seeds_requested=16`
- `seeds_completed=16`
- `start_seed=63210332`
- `battle_replay_final_status=blocked`
- `mandatory_gate_divergences=["forensic_audit=blocked"]`
- `test_results_total=16`
- `test_results_status_counts={"pass":16}`
- `human_replay_resolve_ability_kind_unknown_lines=0`
- `human_replay_damage_cause_unknown_lines=0`
- `human_replay_unknown_lines=0`
- `human_replay_placeholder_lines=0`
- `human_replay_placeholder_samples=[]`

Direct scan of the 16 `seed_*/replay.txt` files from `033246` found
`kind_unknown=0`, `cause_unknown=0`, `UNKNOWN=0`, and `PLACEHOLDER=0`.

## Result

`BV-081` is closed: focused and recurring summaries are distinguishable by
artifact-level fields, and recurring readiness can require
`run_scope=recurring_full`.

`BV-089` remains closed after revalidation: the `Lightning Bolt` `cause=?`
regression from `032709` is fixed by renderer fallback and absent from the
official recurring run `033246`.
