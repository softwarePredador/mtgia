# Battle Event Contract Fixture Depth Current Audit - 2026-06-19T18:46Z

## Scope

Read-only audit of the current recurring battle `latest` artifact to refresh
`BV-047`. This report checks event-contract fixture depth only. It does not
change PostgreSQL, does not apply swaps, does not change runtime code, and does
not commit anything.

Source artifacts:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/event_contract_static.json`
- Real latest directory:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_183529/`

## Current Gate Result

| Metric | Value |
| --- | ---: |
| `timestamp_utc` | `2026-06-19T18:35:29Z` |
| `battle_replay_final_status` | `trusted_for_strategy_learning` |
| `battle_replay_final_status_reason` | `all_mandatory_gates_pass` |
| `mandatory_gate_divergences` | `[]` |
| `event_contract_static.status` | `pass` |
| `event_contract_static.status_detail` | `event_contract_static_ready` |
| `events_observed_total` | `14679` |
| `observed_event_types_total` | `53` |
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

There is no current user-alert condition under the configured rule.

## Fixture Depth Delta

The event contract itself is ready. The remaining issue is fixture depth for
static event emitters that did not appear in the latest 16-seed run.

| Fixture status | Previous 17:22Z | Current 18:46Z | Delta |
| --- | ---: | ---: | ---: |
| `observed_in_latest` | `40` | `53` | `+13` |
| `static_contract_waiver_until_forced_fixture` | `57` | `44` | `-13` |

Current waived-until-fixture by class:

| Class | Event types |
| --- | ---: |
| `strategy_signal` | `27` |
| `renderer_only` | `7` |
| `technical` | `4` |
| `ignored_with_reason` | `4` |
| `forensic_card_event` | `2` |

Current waived-until-fixture by expected consumer:

| Consumer | Event types |
| --- | ---: |
| `decision_strategy_or_replay_context` | `27` |
| `battle_replay_v10_3.py` | `7` |
| `structured_replay_ledger` | `4` |
| `skip_guardrail_or_state_cleanup` | `4` |
| `battle_forensic_audit.py` | `2` |

Notable progress from the old priority list:

- Now observed in latest:
  `additional_cost_failed`, `spell_countered`, `board_wipe_resolved`,
  `composite_rule_resolved`, `utility_land_activated`.
- Still not observed in latest:
  `instant_removal`, `multi_target_resolution`, `adventure_cast`,
  `adventure_creature_cast_from_exile`, `extra_turn_taken`, `flashback_cast`,
  `removal_countered_by_ward`, `utility_artifact_activated`,
  `ward_countered`, `warp_cast`, `worldfire_resolved`.

## Remaining Priority Fixture Candidates

These event types are still static-only in the current latest and matter to
strategy context or forensic validation.

| Event | Class | Consumer | Minimum fields |
| --- | --- | --- | --- |
| `activated_ability` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `adventure_cast` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `adventure_creature_cast_from_exile` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `battle_back_face_cast` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `cannot_lose_turn_resolved` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `cantrip_mana_filter_artifact_resolved` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `extra_combat_scheduled` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `extra_combat_taken` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `extra_turn_scheduled` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `extra_turn_taken` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `flashback_cast` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `game_lost` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `game_win_prevented` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `instant_removal` | `forensic_card_event` | `battle_forensic_audit.py` | `event, turn` |
| `land_recursion_creature_resolved` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `land_recursion_resolved` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `life_artifact_resolved` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `loot_resolved` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `loyalty_ability_activated` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `multi_target_resolution` | `forensic_card_event` | `battle_forensic_audit.py` | `event, turn` |
| `phase_creatures_resolved` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `protection_resolved` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `removal_countered_by_ward` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `station_activated` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `utility_artifact_activated` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `ward_countered` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `warp_cast` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `warp_recast_from_exile` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |
| `worldfire_resolved` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` |

## Interpretation

`BV-047` remains open, but its evidence must be refreshed from `57` to `44`
static waivers. The latest recurring battle is trusted for strategy learning
under the mandatory gates, and there are no high/critical action findings or
strategy blockers. That is different from saying every rare event branch has a
forced replay fixture.

Closure requires one of these outcomes:

- `static_contract_waiver_until_forced_fixture=0`; or
- every remaining waiver has an explicit accepted reason that no forced replay
  is needed; or
- a dedicated fixture-depth gate records the residual rare branches as accepted
  with owner, consumer, and test evidence.
