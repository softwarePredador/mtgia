# Battle Human Replay Renderer Scope Audit - 2026-06-19T19:26:25Z

## Scope

This audit checks the current human replay text against the structured battle
artifacts. It does not change PostgreSQL, swaps, runtime code, automation, or
commits.

Primary source:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`

Per-seed sources:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/replay.txt`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/replay.events.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/replay.decision_trace.jsonl`

## Current Latest Result

- `timestamp_utc=2026-06-19T18:47:21Z`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `seeds_completed=16`
- `events=14679`
- `decisions=2265`
- `seeds_with_high_or_critical_action_findings=[]`
- `seeds_with_strategy_blockers=[]`

No current alert condition was found for high/critical action findings or
strategy blockers.

## Human Replay Completeness Boundary

The current human replay is useful as a readable projection, but it is not the
complete learning ledger.

Evidence:

- Total `replay.txt` lines across current seeds: `7826`.
- Total `replay.events.jsonl` rows across current seeds: `14679`.
- Total `replay.decision_trace.jsonl` rows across current seeds: `2265`.
- Text/event ratio: `0.533`.
- `decision_audit_human_replay_complete=not_evaluated_by_replay_decision_auditor`.
- `decision_audit_rules_interaction_trusted=not_evaluated_by_replay_decision_auditor`.

Operational reading: `replay.txt` can explain the battle to a human, but
learning, WR, confidence, legality, and blocker decisions must keep using the
structured JSONL artifacts plus the action, decision, forensic, event-contract,
coverage, and strategy gates.

## Placeholder Check

Current placeholder counts in `replay.txt`:

| Placeholder | Count | Reading |
| --- | ---: | --- |
| `event=?` | 0 | Previously fixed trigger renderer issue remains closed. |
| `stack=?` | 0 | Previously fixed trigger renderer issue remains closed. |
| `target=?` | 0 | No current target placeholder found by this scan. |
| `stack_object=?` | 0 | No current stack-object placeholder found by this scan. |
| `life=?->` | 11 | Active human-log gap for life-before on utility land activation. |
| `CMC=?` | 106 | Active human-log gap for cast events without `cmc`. |

## Life Field Gap

`utility_land_activated` appeared for:

- `Ancient Tomb`: `11`
- `Sunbaked Canyon`: `4`
- `Urza's Saga`: `1`
- `Hall of Heliod's Generosity`: `2`
- `Inventors' Fair`: `1`
- `War Room`: `2`

There are `13` `utility_land_activated` rows with `life_paid` but no
`life_before`.

Examples:

- `seed_63201734`, `replay.events.jsonl` line `192`: `Ancient Tomb`,
  `life_after=38`, `life_paid=2`, no `life_before`.
- `seed_63201734`, `replay.txt` line `129`: `ACTIVATE ... Ancient Tomb ...
  life=?->38 life_paid=2`.
- `seed_63201744`, `replay.events.jsonl` lines `899` and `1049`: `War Room`
  has `life_paid=2`, but no `life_before` or `life_after`; `replay.txt` prints
  only `life_paid=2`.

Required adjustment: utility-land activations that pay life should emit
`life_before` and `life_after` consistently, and the renderer should avoid a
silent partial note when only `life_paid` is available.

## CMC Field Gap

Current cast events with missing `cmc`:

| Event | Total | Missing `cmc` |
| --- | ---: | ---: |
| `spell_cast` | 418 | 0 |
| `creature_cast` | 86 | 0 |
| `commander_cast` | 28 | 28 |
| `miracle_cast` | 46 | 46 |
| `end_step_instant` | 32 | 32 |

Examples:

- `seed_63201734`, `replay.events.jsonl` line `36`: `commander_cast` for
  `Kraum, Ludevic's Opus`, no `cmc`.
- `seed_63201734`, `replay.txt` line `54`: `CAST COMMANDER ... (CMC=?)`.
- `seed_63201735`, `replay.events.jsonl` line `380`: `end_step_instant` for
  `Seething Song`, no `cmc`.
- `seed_63201736`, `replay.events.jsonl` line `608`: `miracle_cast` for
  `Valakut Awakening // Valakut Stoneforge`, no `cmc`.

Required adjustment: all cast-like event emitters should either carry `cmc` or
the renderer should label the field as intentionally unavailable. Because the
regular `spell_cast` and `creature_cast` paths already provide `cmc`, this
looks like a narrower emitter-path consistency gap.

## Current Conclusion

The flow is acceptable for the current mandatory gates because the latest run is
trusted, no high/critical action findings or strategy blockers are present, and
the older trigger placeholder gap is still closed.

The human battle log is not complete enough to be used alone for learning or
debugging exact rules interactions. The concrete remaining gaps are:

1. `utility_land_activated` life payment lineage is partial.
2. `commander_cast`, `miracle_cast`, and `end_step_instant` omit `cmc`.
3. `replay.txt` is a readable projection with fewer rows than
   `replay.events.jsonl`, not the full audit ledger.

These gaps should be tracked as documentation/observability issues unless a
future auditor proves they affect legality, strategy selection, or learning
weights.
