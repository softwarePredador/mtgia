# Battle latest removal target choice recheck - 2026-06-19T23:20:22Z

Scope: read-only validation. No code was changed for this report, PostgreSQL was
not touched, and no deck swaps were applied.

## Sources

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_63202308/replay.events.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_63202308/replay.decision_trace.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_63202308/replay.txt`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_63202308/replay_decision_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_63202308/forensic_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_63202310/forensic_audit.json`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- `docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md`
- `docs/hermes-analysis/manaloom-knowledge/scripts/replay_decision_auditor.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`

## Current aggregate gate

Latest official run:

- `timestamp_utc=2026-06-19T23:08:29Z`
- `battle_replay_final_status=review_required`
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`
- `mandatory_gate_divergences=["forensic_audit=review_required","replay_decision_audit=review_required"]`
- `action_critic.status=pass`, `findings=0`
- `strategy_audit.status=pass`, `findings=4`,
  `review_required_findings=0`, `low_confidence_findings=4`
- `forensic_audit.status=review_required`, `rule_findings=2`,
  `turn_findings=1`
- `replay_decision_audit.status=review_required`,
  `decision_findings=0`, `turn_findings=1`
- high/critical action findings: `[]`
- high/critical replay-decision findings: `[]`
- high/critical forensic findings: `[]`

No high/critical action finding or strategy blocker was present in this summary.
The run is still not trusted because the aggregate final status is
`review_required`.

## Validated target-choice finding

The current target-choice issue is seed `63202308`, turn `10`, player
`Lorehold`, card `Rise of the Eldrazi`.

The official structured event is:

```json
{
  "event": "removal_resolved",
  "turn": 10,
  "player": "Lorehold",
  "card": "Rise of the Eldrazi",
  "target": "Fiend Artisan",
  "target_player": "Tayam, Luminous Enigma #116 (real)",
  "available_targets": 3,
  "target_effect": "creature",
  "target_power": 1,
  "target_toughness": 1,
  "target_score": null,
  "target_options": null,
  "targeting_pipeline": "targeting_formal_minimal",
  "component_index": 0,
  "destination": "graveyard",
  "phase": null,
  "priority_window": null
}
```

The replay-decision auditor records:

- `turn_findings=1`
- `decision_findings=0`
- finding: `Removal hit a low-power target while multiple targets were available.`
- severity: `low`

The forensic auditor records the same turn finding and no rule finding for
seed `63202308`.

The human replay text only renders:

```text
REMOVAL Lorehold: Rise of the Eldrazi removed Fiend Artisan from Tayam, Luminous Enigma #116 (real)
```

It does not render `available_targets=3`, the other legal candidates, a target
score, or a reason for selecting `Fiend Artisan`.

`replay.decision_trace.jsonl` has no entry for `Rise of the Eldrazi` or for the
removal target selection. Therefore the official artifact cannot prove whether
the selected target was strategically correct or just under-documented.

## Auditor/code cross-check

`replay_decision_auditor.py` intentionally allows a removal target to avoid this
finding when `target_options` and `target_score` prove no better target was
available. In the latest artifact, both fields are absent on the flagged event,
so the auditor cannot distinguish a weak target from missing provenance.

The current dirty worktree of `battle_analyst_v9.py` contains local changes that
add `target_priority(...)`, `target_option_replay_entry(...)`,
`target_selection_replay_fields(...)`, and inject
`**target_selection_replay_fields(...)` into removal event emission paths.

That local diff is not evidence that the latest artifact is fixed:

- artifact event mtime:
  `2026-06-19T20:08:47-0300 .../latest/seed_63202308/replay.events.jsonl`
- artifact summary mtime:
  `2026-06-19T20:11:08-0300 .../latest/summary.json`
- dirty worktree file mtime:
  `2026-06-19T20:16:43-0300 docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`

The worktree change is later than the official artifact and must be validated by
a new official run before closing the gate.

## Related forensic issue

The same latest run also has seed `63202310` forensic rule findings for
`Into the Flood Maw`: runtime effect `remove_creature` differs from registry
effect `remove_permanent` on both `spell_cast` and `spell_resolved`, severity
`low`. This is the other half of `mandatory_gate_divergences` and remains part
of `BV-079`.

## Task for "Ajustar battle"

1. Make the official wrapper emit and persist `target_score` and
   `target_options` for every `removal_resolved` event with
   `available_targets > 1`, including composite-resolution removals such as
   `Rise of the Eldrazi`.
2. Emit a decision-trace row for target selection, or otherwise include a stable
   `target_choice_reason` field that the replay-decision auditor can consume.
3. Update `replay.txt` so human logs show at least selected target, target score,
   available target count, and reason/options summary when multiple legal targets
   exist.
4. Rerun the official battle-strategy audit and validate the new
   `/latest/summary.json`. Do not close `BV-079` from a dirty local diff alone.
5. If the selected target was actually the best target, the new artifact should
   give the auditor enough data to waive/skip the finding. If the selected target
   was not best, adjust target priority/card classification and keep the gate in
   review until behavior is corrected.

## Superseded by newer latest

After this report was written, newer official runs moved `latest` to
`20260619_232324`. The current run has
`battle_replay_final_status=trusted_for_strategy_learning` and
`mandatory_gate_divergences=[]`. In that run, the previous target-choice finding
does not reproduce, and the only multi-target `removal_resolved` event publishes
both `target_score` and `target_options`.

This report remains historical evidence for run `20260619_230829`; do not use it
as the current latest status without also reading
`battle_latest_232324_gate_recheck_20260619_202744.md`.
