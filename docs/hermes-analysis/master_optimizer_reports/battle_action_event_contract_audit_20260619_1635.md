# Battle Action Event Contract Audit - 2026-06-19T16:35Z

## Scope

Artifact-only validation slice for replay event taxonomy, `battle_action_critic`
coverage, renderer coverage, and forensic card-event coverage. This audit does
not change PostgreSQL, swaps, product code, or automation code.

Inputs:

- Latest summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- Latest run:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_163044`
- Latest events:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_163044/seed_786135854/replay.events.jsonl`
- Default action critic:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_163044/seed_786135854/action_critic.json`
- Generated contract artifact:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/action_event_contract_1635/action_event_contract.json`
- Re-run with `--include-technical`:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/action_event_contract_1635/action_critic_include_technical.json`
- Re-run forensic:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/action_event_contract_1635/forensic_audit.json`

## Current Latest Snapshot

Latest `summary.json` at `2026-06-19T16:30:44Z`:

- `events`: `1073`
- `decisions`: `152`
- `action_findings`: `0`
- `action_verdict_counts`: `{"ok": 475}`
- `strategy_findings`: `0`
- `decision_audit_turn_findings`: `0`
- `decision_audit_decision_findings`: `0`
- `forensic_rule_findings`: `0`
- `forensic_turn_findings`: `0`
- high/critical/action, strategy blocker, replay-decision high/critical, and
  forensic high/critical seed lists: empty.

Validation commands run:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py --include-technical ...` - PASS, `0` findings.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py --events ... --report ...` - PASS, `0` blocker findings in current summary.

## Event Surface

Static extraction from `battle_analyst_v9.py`:

- `emit_replay_event(...)` call sites: `143`
- static engine event types: `94`

Latest seed:

- total events: `1073`
- observed event types: `40`

Top observed event types:

| Event | Count |
| --- | ---: |
| `priority_pass` | 375 |
| `combat_step` | 155 |
| `cast_announced` | 82 |
| `cast_illegal` | 47 |
| `turn_start` | 42 |
| `mana_refreshed` | 42 |
| `combat_result` | 39 |
| `cost_paid` | 35 |
| `turn_end` | 29 |
| `land_played` | 26 |
| `spell_cast` | 26 |
| `spell_resolved` | 25 |
| `combat` | 24 |
| `trigger_put_on_stack` | 19 |
| `trigger_resolved` | 19 |
| `activated_ability_skipped` | 18 |
| `multi_defender_attack` | 13 |
| `lorehold_upkeep_rummage_skipped` | 10 |
| `topdeck_manipulation_activated` | 8 |
| `creature_cast` | 8 |

## Action Critic Coverage

`battle_action_critic.py` currently defines:

- `ACTION_EVENTS`: `24`
- `TECHNICAL_EVENTS`: `4`
- `CARD_ACTION_EVENTS`: `8`
- `DECISION_ACTION_EVENTS`: `7`

Default action critic result:

- `total_actions`: `475`
- `verdict_counts`: `{"ok": 475}`
- `findings`: `0`

The default critic covers `475/1073` latest events. The remaining events are
either explicitly technical or outside the default action set.

Re-run with `--include-technical`:

- `total_actions`: `1073`
- `verdict_counts`: `{"ok": 1073}`
- `findings`: `0`

Operational caveat: `--include-technical` includes every event kind, even those
without type-specific checks. Therefore `ok=1073` is a ledger/pass-through
result, not proof that all `1073` events have specialized action validation.

## Observed Events Outside Default Sets

Observed events outside `ACTION_EVENTS + TECHNICAL_EVENTS`: `52` events across
`14` types.

| Event | Count |
| --- | ---: |
| `activated_ability_skipped` | 18 |
| `lorehold_upkeep_rummage_skipped` | 10 |
| `topdeck_manipulation_activated` | 8 |
| `lorehold_upkeep_rummage` | 4 |
| `damage_resolved` | 2 |
| `saga_chapter_progressed` | 2 |
| `additional_cost_paid` | 1 |
| `copy_creature_token_created` | 1 |
| `equipment_attached` | 1 |
| `extra_turn_scheduled` | 1 |
| `saga_chapter_resolved` | 1 |
| `saga_sacrificed_by_sba` | 1 |
| `treasure_created` | 1 |
| `wheel_resolved` | 1 |

These events may be valid and intentionally informational, but the current
summary does not distinguish `action_audited`, `technical`, `renderer_only`,
`forensic_card_event`, `strategy_signal`, and `ignored_with_reason`.

## Renderer And Forensic Coverage

Observed event types with no specific renderer branch/dynamic match: `17` types.
This does not necessarily mean the raw event is lost, but it means the human
`replay.txt` is not guaranteed to have a purpose-built line for the type.

High-count examples without specific renderer coverage:

- `priority_pass`: `375`
- `combat_step`: `155`
- `activated_ability_skipped`: `18`
- `multi_defender_attack`: `13`
- `lorehold_upkeep_rummage_skipped`: `10`
- `lorehold_upkeep_rummage`: `4`

Forensic card-event coverage:

- `CARD_EVENT_KINDS`: `9`
- latest forensic card events: `111`
- latest card-event lineage: `card_id_present=63`, `card_id_missing=48`,
  `semantic_hash_present=63`, `semantic_hash_missing=48`,
  `rule_logical_key_present=109`, `rule_logical_key_missing=2`.

Forensic remains useful for card effects, but it covers a small subset of the
`1073` event stream and still has lineage gaps for `card_id` and
`semantic_hash`.

## Operational Reading

The latest replay has no high/critical action finding, and the action critic
tests are green. That is good evidence for the current default action rules.

It is not evidence that every event emitted by the battle engine has an explicit
consumer contract. The current risk is denominator ambiguity:

- `action_verdict_counts={"ok":475}` covers default action events, not all
  `1073` events.
- `--include-technical` can produce `ok=1073`, but that includes pass-through
  event types with no specific checks.
- `52` observed events are outside the default action/technical sets.
- The human replay renderer and forensic auditor cover useful subsets, not the
  full event surface.

## Required Follow-Up

- Add an event contract manifest or generated audit with one row per event type:
  emitted by engine, observed count, renderer status, action critic status,
  forensic status, decision/strategy status, and explicit ignore reason.
- Add summary counters:
  `event_types_total`, `event_types_action_audited`,
  `event_types_technical`, `event_types_renderer_only`,
  `event_types_forensic_only`, `event_types_unclassified`, and
  `events_unclassified`.
- Treat `--include-technical` as a ledger mode unless each included event type
  has a declared classification.
- Continue tracking forensic lineage (`card_id`, `semantic_hash`,
  `rule_logical_key`) separately from absence of forensic findings.

