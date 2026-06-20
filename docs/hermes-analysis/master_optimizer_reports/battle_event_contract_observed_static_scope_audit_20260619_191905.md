# Battle Event Contract Observed/Static Scope Audit - 2026-06-19T19:19Z

## Scope

This audit checks the current `event_contract_static` gate and the difference
between:

- event types emitted as static string literals in `battle_analyst_v9.py`;
- event types observed in the latest replay JSONL;
- event types that are observed and classified, but not found as static
  `emit_replay_event(...)` string literals.

No code, PostgreSQL data, swaps, or commits were changed.

## Sources

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/event_contract_static.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/event_contract_static.md`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_event_contract_static_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_event_contract_static_audit.py`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- `docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md`

## Current Latest State

- `timestamp_utc`: `2026-06-19T18:47:21Z`
- `battle_replay_final_status`: `trusted_for_strategy_learning`
- `mandatory_gate_divergences`: `[]`
- `event_contract_static_status`: `event_contract_static_ready`
- `event_contract_static_events_observed_total`: `14679`
- `event_contract_static_observed_event_types_total`: `53`
- `event_contract_static_static_event_types_total`: `94`
- `event_contract_static_all_event_types_total`: `97`
- `event_contract_static_observed_unclassified_total`: `0`
- `event_contract_static_static_unclassified_total`: `0`
- `event_contract_static_observed_missing_required_fields`: `0`
- `event_contract_static_waiver_until_forced_fixture`: `0`
- `event_contract_static_fixture_unaccepted_types`: `[]`

## Observed Not Static Literal

Current `observed_not_static_literal`:

| Event | Observed count | Class | Consumer | Minimum fields | Reading |
| --- | ---: | --- | --- | --- | --- |
| `player_eliminated` | `48` | `action_audited` | `battle_action_critic.py` | `event, turn` | Observed and classified, but not discovered as a static literal by AST extraction. |
| `replacement_applied` | `11` | `action_audited` | `battle_action_critic.py` | `event, turn` | Observed and classified, but not discovered as a static literal by AST extraction. |
| `saga_sacrificed_by_sba` | `2` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | Observed and classified, but not discovered as a static literal by AST extraction. |

These are not unclassified events and do not fail the current gate. They remain
important because they prove the static literal extractor is not equivalent to
the full observed event surface.

## Fixture/Waiver Depth

The current fixture depth is clean:

- `fixture_or_waiver_counts`:
  `{"observed_in_latest": 53, "static_contract_accepted_waiver": 44}`
- `static_fixture_accepted_waiver_total`: `44`
- `static_contract_waiver_until_forced_fixture`: `0`
- `static_fixture_unaccepted_types`: `[]`

Accepted static-only waiver reasons:

| Reason | Count |
| --- | ---: |
| `accepted_strategy_context_signal_static_contract` | `27` |
| `accepted_renderer_only_event_no_guardrail_consumer` | `7` |
| `accepted_explicitly_ignored_event_contract` | `4` |
| `accepted_technical_ledger_event_no_forced_replay_required` | `4` |
| `accepted_forensic_card_event_static_contract_until_observed` | `2` |

## Contract Reading

The current event contract gate is working:

- observed event types are classified;
- static event types are classified;
- observed events have required minimum fields;
- unobserved static event types have accepted fixture/waiver ownership;
- no static event currently needs forced fixture work.

The key limitation is semantic:

`event_contract_static_ready` does not mean every observed event type was found
as a static literal in the engine AST. It means every observed/static type is
classified and has the required contract status.

## Finding

No new open battle finding is required in this pass. The register already kept
`player_eliminated`, `replacement_applied`, and `saga_sacrificed_by_sba` visible
as observed-but-not-static-literal types, and the current latest artifact still
surfaces them explicitly.

The operational rule remains:

When using `event_contract_static_ready`, always report
`observed_not_static_literal`, `observed_unclassified_total`,
`static_unclassified_total`, `observed_missing_required_fields`, and
`static_contract_waiver_until_forced_fixture` together.

## Recommended Follow-up

- Do not treat `static_event_types_total=94` as the full runtime event surface
  by itself; include the `all_event_types_total=97` denominator.
- Keep `observed_not_static_literal` visible in handoffs and docs until the
  dynamic/indirect emit paths are explicitly documented or folded into static
  extraction.
- Continue failing the gate only for unclassified event types, missing required
  fields, or unaccepted fixture-depth gaps.
