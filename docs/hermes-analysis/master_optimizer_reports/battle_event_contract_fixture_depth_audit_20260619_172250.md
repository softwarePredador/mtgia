# Battle Event Contract Fixture Depth Audit - 2026-06-19 17:22Z

## Scope

This report audits the residual depth of the recurring event contract gate after
`event_contract_static` became a passing gate. It does not reopen the minimum
event-contract issue; it records which static event paths still need forced
fixtures before they can be considered deeply replay-tested.

Source artifacts:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_172250/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_172250/event_contract_static.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/event_contract_fixture_depth_172250/event_contract_fixture_depth.json`

## Current Gate Result

| Metric | Value |
| --- | ---: |
| `event_contract_static.status` | `event_contract_static_ready` |
| `mandatory_gate_statuses.event_contract_static.status` | `pass` |
| `events_observed_total` | `1073` |
| `observed_event_types_total` | `40` |
| `static_event_types_total` | `94` |
| `all_event_types_total` | `97` |
| `observed_unclassified_total` | `0` |
| `static_unclassified_total` | `0` |
| `observed_missing_required_fields` | `0` |

Alert paths checked through `summary.json`:

- `seeds_with_high_or_critical_action_findings=[]`
- `seeds_with_strategy_blockers=[]`
- `seeds_with_high_or_critical_decision_audit_findings=[]`
- `seeds_with_high_or_critical_forensic_findings=[]`

## Residual Fixture Gap

The contract gate now proves classification, expected consumer, and minimum
fields for static and observed event types. It does not prove that every rare
branch has been forced through a replay fixture.

| Fixture status | Event types |
| --- | ---: |
| `observed_in_latest` | `40` |
| `static_contract_waiver_until_forced_fixture` | `57` |

Waived-until-fixture by class:

| Class | Event types |
| --- | ---: |
| `strategy_signal` | `36` |
| `renderer_only` | `9` |
| `technical` | `4` |
| `ignored_with_reason` | `4` |
| `action_audited` | `2` |
| `forensic_card_event` | `2` |

Waived-until-fixture by expected consumer:

| Consumer | Event types |
| --- | ---: |
| `decision_strategy_or_replay_context` | `36` |
| `battle_replay_v10_3.py` | `9` |
| `structured_replay_ledger` | `4` |
| `skip_guardrail_or_state_cleanup` | `4` |
| `battle_action_critic.py` | `2` |
| `battle_forensic_audit.py` | `2` |

## Priority Fixture Candidates

These are the first branches to force because they are audited actions,
forensic-card events, or strategic rule interactions:

| Event | Class | Consumer | Minimum fields |
| --- | --- | --- | --- |
| `additional_cost_failed` | `action_audited` | `battle_action_critic.py` | `event, turn` |
| `spell_countered` | `action_audited` | `battle_action_critic.py` | `event, turn` |
| `instant_removal` | `forensic_card_event` | `battle_forensic_audit.py` | `event, turn` |
| `multi_target_resolution` | `forensic_card_event` | `battle_forensic_audit.py` | `event, turn` |
| `adventure_cast` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `adventure_creature_cast_from_exile` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `board_wipe_resolved` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `composite_rule_resolved` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `extra_turn_taken` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `flashback_cast` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `removal_countered_by_ward` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `utility_artifact_activated` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `utility_land_activated` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `ward_countered` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `warp_cast` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `worldfire_resolved` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |

## Interpretation

`BV-034` can remain closed because the contract gate now classifies all static
event types and validates minimum fields for observed events. The remaining gap
is fixture depth: rare event emitters are covered by a static waiver until a
forced replay makes the branch observable.

Closure for this residual gap requires reducing
`static_contract_waiver_until_forced_fixture` to `0`, or replacing every
remaining waiver with an explicit accepted reason that says why no forced replay
is needed.
