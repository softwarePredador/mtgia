# Battle Latest 031128 Human Replay Renderer BV-089 Closure

Generated at: `2026-06-20T00:16:00-03:00`

## Scope

This report closes only `BV-089`, the human replay renderer placeholder
provenance issue. It does not claim global battle readiness: the same official
run is currently blocked by other gates.

## Reproduction

Source run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_025107`

Observed before the fix:

- `100` lines matching `RESOLVE ABILITY ... kind=?`
- `0` lines matching `DAMAGE ... cause=?`
- Matching JSONL `trigger_resolved` rows already carried `trigger` and often
  `trigger_spell`, for example Birgi with `trigger=spell_cast` and
  `trigger_spell=Jeska's Will`.

## Treatment

Changed:

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`

The renderer now resolves `trigger_resolved` kind using:

1. `activation_kind`
2. `trigger_kind`
3. `trigger`
4. `trigger_event`
5. `event_type`
6. `?`

When `trigger_spell` exists, the human replay line includes it as
`trigger_spell=<card>`.

The recurring wrapper now publishes human replay placeholder counters in
`summary.json` and `summary.md`:

- `human_replay_resolve_ability_kind_unknown_lines`
- `human_replay_damage_cause_unknown_lines`
- `human_replay_unknown_lines`
- `human_replay_placeholder_lines`
- `human_replay_placeholder_samples`

## Validation

Focused checks:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py` - PASS
- Re-render of the `20260620_025107` JSONL files with the patched renderer:
  `events_rendered=15048`, `original_kind_unknown=100`,
  `rerendered_kind_unknown=0`, `rerendered_cause_unknown=0`.
- `bash -n /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh` - PASS

Official run after wrapper publication:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_031128/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_031128/summary.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_031128/test_results.jsonl`

Official run values:

- `seeds_requested=16`
- `seeds_completed=16`
- `start_seed=63210311`
- `human_replay_resolve_ability_kind_unknown_lines=0`
- `human_replay_damage_cause_unknown_lines=0`
- `human_replay_unknown_lines=0`
- `human_replay_placeholder_lines=0`
- `human_replay_placeholder_samples=[]`
- Direct scan of all `seed_*/replay.txt`: `kind_unknown=0`,
  `cause_unknown=0`, `UNKNOWN=0`, `PLACEHOLDER=0`
- `test_results_total=16`
- `test_results_status_counts={"pass":16}`
- `test_battle_replay_v10_3_renderer`: PASS, `exit_code=0`,
  `log_lines=8`

Current aggregate caveat:

- `battle_replay_final_status=blocked`
- `mandatory_gate_divergences=["forensic_audit=blocked","strategy_audit=review_required"]`
- Current blockers are outside `BV-089` and remain in the register.

## Result

`BV-089` has closure evidence: the human replay no longer renders the current
placeholder classes, the renderer has a regression test for trigger fallback,
and the official summary now publishes placeholder counters.
