# Battle Documentation Router Current Audit - 2026-06-19T18:50Z

## Scope

Read-only audit of battle documentation routing after the latest recurring
wrapper reached `trusted_for_strategy_learning` and the event fixture-depth
gap was converted into accepted static waivers. This report checks whether
current docs route readers to the live register and latest summary before they
make readiness claims.

No PostgreSQL changes, swaps, code edits, automation edits, or commits were
made.

## Runtime Source Checked

Primary source:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`

Latest status at inspection:

| Metric | Value |
| --- | --- |
| `timestamp_utc` | `2026-06-19T18:47:21Z` |
| `run_dir` | `20260619_184721` |
| `seeds_completed` | `16` |
| `events` | `14679` |
| `decisions` | `2265` |
| `battle_replay_final_status` | `trusted_for_strategy_learning` |
| `battle_replay_final_status_reason` | `all_mandatory_gates_pass` |
| `mandatory_gate_divergences` | `[]` |
| `seeds_with_high_or_critical_action_findings` | `[]` |
| `seeds_with_strategy_blockers` | `[]` |
| `event_contract_static_waiver_until_forced_fixture` | `0` |
| `event_contract_static_fixture_unaccepted_types` | `[]` |

There is no current high/critical action finding or strategy-blocker alert
condition.

## Documentation Routing Evidence

### `BATTLE_SYSTEM_LOGIC.md`

The file now correctly warns that it is architecture context, not proof of
readiness, and points readers to:

- `BATTLE_VALIDATION_REGISTER_2026-06-19.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `BATTLE_REPLAY_GATE_MATRIX.md`

However, the same top warning still embeds a stale status:

- Lines `7-8`: `2026-06-19T16:42:53Z` with
  `battle_replay_final_status=review_required`.

Current latest is `trusted_for_strategy_learning`, so the embedded snapshot is
now stale even though the routing instruction is correct.

### `BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md`

The index has the right precedence rule:

- register prevails on divergence, omission, or a new unlisted artifact.
- `BATTLE_REPLAY_GATE_MATRIX.md` is listed and tied to latest `20260619_183529`.

The current-source table is intentionally non-exhaustive, but it omits late
reports that are now important for the live battle-validation narrative:

| Late artifact | Listed in status index |
| --- | --- |
| `battle_event_contract_fixture_depth_current_audit_20260619_184651.md` | no |
| latest official run `20260619_184721` summary/event-contract artifacts | no |
| `battle_latest_trusted_focused_lineage_audit_20260619_1838.md` | no |
| `battle_strategy_gate_semantics_audit_20260619_1830.md` | no |
| `battle_strategy_confidence_consumer_audit_20260619_182529.md` | no |
| `battle_latest_181408_delta_audit_20260619_1816.md` | no |
| `battle_latest_strategy_forensic_gate_audit_20260619_1812.md` | no |
| `battle_focused_template_builder_contract_audit_20260619_180140.md` | no |
| `battle_runtime_surface_outside_recurring_audit_20260619_175415.md` | no |
| `battle_latest_focused_dispatch_forensic_audit_20260619_174452.md` | no |
| `battle_latest_blockers_effect_residual_audit_20260619_173448.md` | no |
| `battle_focused_template_dispatch_gap_audit_20260619_173213.md` | no |
| `battle_template_dispatch_gap_audit_20260619_172842.md` | no |
| `battle_event_contract_fixture_depth_audit_20260619_172250.md` | no |

This is not a runtime failure because the index explicitly says the register
prevailed. It is still a documentation-routing risk.

### `LOREHOLD_DECK6_STRATEGY_COHERENCE_AUDIT_2026-06-19.md`

This file contains historical sections that mention earlier `review_required`
and `blocked` states. Later sections correctly record the current official run:

- latest completed run `20260619_183529`;
- `battle_replay_final_status=trusted_for_strategy_learning`;
- `battle_replay_final_status_reason=all_mandatory_gates_pass`;
- focused dispatch and forensic lineage passing.

Operational reading: it is safe as a chronological audit, but it is not a
compact current-status document. Readers must use the register and latest
summary before taking its older sections as current.

## Finding

### Documentation router has stale embedded status and incomplete late-artifact list

The live register and gate matrix are now the right sources for current battle
status. The broader documentation set still has two routing weaknesses:

- the top of `BATTLE_SYSTEM_LOGIC.md` embeds a stale `review_required` snapshot;
- the status index omits multiple late 17:00-18:46 validation reports that
  explain how the latest reached trusted status and how `BV-047` was closed by
  accepted static fixture-depth waivers.

Risk: a future Codex pass can follow a current-looking architecture or index
page, stop at an old `review_required` or miss the late reports, and reopen
closed issues or under-report the remaining fixture-depth gap.

This should remain a documentation/process finding, not a battle-engine blocker.

## Suggested Follow-Up

- In `BATTLE_SYSTEM_LOGIC.md`, avoid embedding a point-in-time final status near
  the top, or update it whenever the latest trusted/review status changes.
- In `BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md`, either list the late
  validation reports above or make the index explicitly secondary to a
  generated/latest report list.
- Keep `BATTLE_VALIDATION_REGISTER_2026-06-19.md` as the single live source for
  open/closed findings.
