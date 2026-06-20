# Battle Documentation Freshness Audit - 2026-06-19T16:42Z

## Scope

Artifact-only validation slice for battle documentation freshness and source
routing. This audit checks whether current battle docs point readers to the live
validation register and whether the status index includes the latest validation
artifacts.

No PostgreSQL changes, swaps, commits, product-code edits, or automation edits
were made.

## Inputs

- Live register:
  `docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md`
- Documentation status index:
  `docs/hermes-analysis/BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md`
- Broad logic document:
  `docs/hermes-analysis/BATTLE_SYSTEM_LOGIC.md`
- Current task matrix:
  `docs/hermes-analysis/BATTLE_GENERATOR_LOREHOLD_TASK_MATRIX_2026-06-17.md`
- Current gate matrix:
  `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- Current decision taxonomy:
  `docs/hermes-analysis/BATTLE_DECISION_TRACE_TAXONOMY.md`
- Latest recurring result:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`

## Latest Runtime Status Checked

Latest `summary.json` at inspection time:

- `timestamp_utc`: `2026-06-19T16:39:24Z`
- `run_dir`:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_163924`
- `start_seed`: `786135854`
- `events`: `1073`
- `decisions`: `152`
- `action_findings`: `0`
- `action_verdict_counts`: `{"ok": 475}`
- `strategy_findings`: `0`
- `decision_audit_turn_findings`: `0`
- `decision_audit_decision_findings`: `0`
- `forensic_rule_findings`: `0`
- `forensic_turn_findings`: `0`
- `battle_replay_final_status`: `review_required`
- `mandatory_gate_divergences`: `["effect_coverage=review_required"]`
- `effect_coverage_unknowns`: `33`
- `heuristic_effects`: `120`
- high/critical/action, strategy blocker, replay-decision high/critical, and
  forensic high/critical seed lists: empty.

Operational reading: there is no high/critical notification condition in the
latest run, but the aggregate replay status is not trusted; it is
`review_required` due to effect coverage.

## Documentation Routing Evidence

The documentation index correctly identifies the live register as the primary
source, but its `Current Sources` table was created before multiple later
artifacts.

Current source routing checks:

| Document | Exists | In status index | Points to register | Observation |
| --- | --- | --- | --- | --- |
| `BATTLE_VALIDATION_REGISTER_2026-06-19.md` | yes | yes | yes | Correct live source. |
| `BATTLE_SYSTEM_LOGIC.md` | yes | yes | no | Self-describes as canonical and last-updated `2026-06-18`; direct readers can miss later gates and register findings. |
| `BATTLE_GENERATOR_LOREHOLD_TASK_MATRIX_2026-06-17.md` | yes | yes | no | Current task backlog, but direct readers do not get a mandatory link to the live register. |
| `BATTLE_DECISION_TRACE_TAXONOMY.md` | yes | no | no | Current taxonomy as of `2026-06-19T16:30:44Z`, but omitted from the status index. |
| `BATTLE_REPLAY_GATE_MATRIX.md` | yes | no | no | Current final-status gate matrix, but omitted from the status index. |
| `LOREHOLD_DECK6_STRATEGY_COHERENCE_AUDIT_2026-06-19.md` | yes | yes | no | Current learned-deck source/coherence audit, but direct readers do not get the live register context. |
| `master_optimizer_reports/battle_action_event_contract_audit_20260619_1635.md` | yes | no | no | Current event/action critic denominator audit, omitted from the status index. |
| `master_optimizer_reports/battle_decision_trace_taxonomy_audit_20260619_1627.md` | yes | no | no | Current decision trace taxonomy evidence, omitted from the status index. |
| `master_optimizer_reports/battle_template_contract_crosscheck_20260619_162233.md` | yes | no | no | Current focused-evidence/template crosscheck, omitted from the status index. |
| `master_optimizer_reports/battle_runtime_surface_manifest_20260619_1700.md` | yes | no | no | Current runtime-surface manifest, omitted from the status index. |
| `master_optimizer_reports/battle_effect_coverage_audit_20260619_1638_runtime_status.md` | yes | no | no | Current runtime-status coverage snapshot, omitted from the status index. |
| `master_optimizer_reports/battle_forensic_audit_20260619_163318.md` | yes | no | no | Current forensic audit report, omitted from the status index. |

## Findings

### Documentation index is stale relative to the live register

`BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md` is useful and should remain
the routing document, but it does not list the current decision taxonomy, replay
gate matrix, action-event contract audit, template crosscheck, runtime surface
manifest, latest runtime-status coverage snapshot, or latest forensic report.

Impact: a future battle-validation pass can follow the index and miss artifacts
that are already referenced by the live register. This can reopen already
classified questions or overstate confidence.

### Broad canonical logic doc lacks a live-register guard

`BATTLE_SYSTEM_LOGIC.md` starts as the canonical complete documentation for
simulation, optimization, and validation, and it still states last update
`2026-06-18`. It does not point to `BATTLE_VALIDATION_REGISTER_2026-06-19.md`,
the replay gate matrix, or the latest aggregate status.

Impact: the document is valuable architecture context, but using it directly as
current proof can bypass later findings such as:

- `battle_replay_final_status=review_required`;
- effect coverage unknowns and heuristic effects;
- decision types with only generic coverage;
- action critic denominator ambiguity;
- current event/action contract gaps.

## Required Follow-Up

- Update the documentation index after every new battle validation artifact, or
  make the live register the only required "current source" and mark the index
  as a secondary router.
- Add a top-of-file warning or pointer in `BATTLE_SYSTEM_LOGIC.md` that current
  readiness must be checked in the live register and latest `summary.json`.
- Treat `BATTLE_SYSTEM_LOGIC.md` as architecture/background unless the current
  claim being used is revalidated against the live register and latest
  recurring summary.
- Add a register checklist item: any current battle doc used as evidence must
  either point to the register or be explicitly rechecked against the latest
  recurring audit.
