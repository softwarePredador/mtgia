# Battle Decision Trace Current Scope Audit - 2026-06-19T19:05Z

## Scope

This audit checks the current recurring `decision_trace_taxonomy` output against
the canonical battle validation register and the older
`BATTLE_DECISION_TRACE_TAXONOMY.md` snapshot.

No code, PostgreSQL data, swaps, or commits were changed.

## Sources

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/decision_trace_taxonomy.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/decision_trace_taxonomy.md`
- `docs/hermes-analysis/BATTLE_DECISION_TRACE_TAXONOMY.md`
- `docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md`

## Current Latest State

- `timestamp_utc`: `2026-06-19T18:47:21Z`
- `battle_replay_final_status`: `trusted_for_strategy_learning`
- `mandatory_gate_divergences`: `[]`
- `seeds_completed`: `16`
- `events`: `14679`
- `decisions`: `2265`
- `seeds_with_high_or_critical_action_findings`: `[]`
- `seeds_with_strategy_blockers`: `[]`
- `decision_trace_taxonomy_status`: `decision_trace_taxonomy_ready`
- `decision_trace_kinds_total`: `15`
- `decision_trace_kinds_observed`: `12`
- `decision_trace_kinds_uncovered`: `3`
- `decision_trace_kinds_without_specific_contract`: `0`
- `decision_trace_observed_without_specific_contract`: `0`
- `decision_trace_contract_findings`: `0`
- `decision_trace_missing_required_fields`: `0`

## Observed Decision Types

The current latest run observed `12/15` static decision trace types:

| Decision type | Latest count | Specific status | Fixture/gate |
| --- | ---: | --- | --- |
| `pass_no_action` | `1094` | `specific` | `test_battle_decision_strategy_auditor.py` |
| `cast_spell` | `530` | `specific` | `test_battle_decision_strategy_auditor.py` |
| `combat_attack` | `237` | `specific_via_research` | `test_battle_decision_research_review.py` |
| `mulligan_decision` | `116` | `specific` | `test_battle_decision_strategy_auditor.py` |
| `lorehold_upkeep_rummage` | `109` | `accepted_field_contract_waiver` | `field_contract_required_before_observed_learning` |
| `utility_artifact_activation` | `93` | `accepted_field_contract_waiver` | `field_contract_required_before_observed_learning` |
| `tutor` | `47` | `specific` | `test_battle_decision_strategy_auditor.py` |
| `utility_land_activation` | `21` | `accepted_field_contract_waiver` | `field_contract_required_before_observed_learning` |
| `response` | `9` | `specific_via_research` | `test_battle_decision_research_review.py` |
| `wheel` | `6` | `specific` | `test_battle_decision_strategy_auditor.py` |
| `saga_chapter_resolution` | `2` | `accepted_field_contract_waiver` | `field_contract_required_before_observed_learning` |
| `board_wipe` | `1` | `specific` | `test_battle_decision_strategy_auditor.py` |

## Unobserved Static Types

The current latest run did not observe these `3/15` static types:

| Decision type | Latest count | Specific status | Fixture/gate | Reading |
| --- | ---: | --- | --- | --- |
| `activated_sacrifice_damage` | `0` | `accepted_field_contract_waiver` | `field_contract_required_before_observed_learning` | Contract owner exists, but this latest corpus did not exercise the branch. |
| `attack_trigger_artifact_tutor` | `0` | `accepted_field_contract_waiver` | `field_contract_required_before_observed_learning` | Contract owner exists, but this latest corpus did not exercise the branch. |
| `worldfire_reset` | `0` | `specific` | `test_battle_decision_strategy_auditor.py` | Strategy branch and fixture ownership exist, but the latest corpus did not exercise the branch. |

## Documentation Drift

`docs/hermes-analysis/BATTLE_DECISION_TRACE_TAXONOMY.md` is marked current as of
`2026-06-19T17:16:23Z` and points at run `20260619_171605`. Its summary says:

- `decision_trace_rows`: `152`
- `decision_trace_kinds_observed`: `10`
- `decision_trace_kinds_uncovered`: `5`

The current recurring latest artifact says:

- `decision_trace_rows`: `2265`
- `decision_trace_kinds_observed`: `12`
- `decision_trace_kinds_uncovered`: `3`

Operationally, the older doc is useful as a contract explanation, but it is no
longer a current status source unless it is updated or explicitly redirected to
the latest artifact/register.

## Finding

`decision_trace_taxonomy_ready` means every static or observed decision type has
an owner, a specific strategy/research branch, or an accepted field-contract
waiver. It does not mean every static branch was observed in the latest run.

The battle validation register should keep this distinction explicit so future
agents do not treat `taxonomy_ready` as complete exercise coverage for all
decision learning branches.

## Recommended Follow-up

- Keep `BATTLE_DECISION_TRACE_TAXONOMY.md` either generated from latest artifacts
  or clearly labeled as a historical contract explanation.
- When reporting decision trace readiness, always include:
  - `decision_trace_kinds_total`
  - `decision_trace_kinds_observed`
  - `decision_trace_kinds_uncovered`
  - `static_uncovered_types`
  - `accepted_waivers`
- Treat `activated_sacrifice_damage`, `attack_trigger_artifact_tutor`, and
  `worldfire_reset` as not exercised by the latest run until a corpus/fixture
  explicitly covers them.
