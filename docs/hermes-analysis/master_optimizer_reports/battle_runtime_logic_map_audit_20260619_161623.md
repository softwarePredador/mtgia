# Battle Runtime Logic Map Audit - 2026-06-19T16:16:23Z

## Scope

Static/runtime inventory for the current battle engine and its immediate tests.
This audit does not change PostgreSQL, swaps, product code, or automation code.

Files inspected:

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_strategy_auditor.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_research_review.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/replay_decision_auditor.py`
- battle test files under `docs/hermes-analysis/manaloom-knowledge/scripts/`
- latest automation artifact:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`

## Engine Shape

`battle_analyst_v9.py` current static shape:

- lines: `13900`
- classes: `8`
- top-level functions: `290`
- literal replay event types emitted: `94`
- `emit_decision_trace(...)` call sites: `34`

Classes:

| Class | Line | Methods | Role |
| --- | ---: | ---: | --- |
| `ReplacementRegistry` | 378 | 1 | Replacement/prevention pipeline. |
| `EngineMetrics` | 401 | 5 | Runtime health metrics. |
| `CastingContext` | 514 | 2 | Cast cost/timing/context lock. |
| `ContinuousEffect` | 689 | 1 | Continuous effect representation. |
| `ManaPool` | 2552 | 7 | Mana accounting/payment. |
| `Player` | 2580 | 18 | Player zones, mana, combat state, counters. |
| `StackItem` | 3110 | 1 | Stack object. |
| `Stack` | 3129 | 5 | Stack push/resolve/threat. |

High-signal function groups from top-level names:

| Group | Count | Examples |
| --- | ---: | --- |
| cast | 15 | `begin_cast_context`, `commit_cast_payment`, `cast_spells_v8`, `cast_flashback_spell_from_graveyard`, `try_lorehold_miracle_cast` |
| land | 23 | `choose_land_for_resource_cost`, `activate_utility_lands`, `trigger_landfall`, `put_lands_from_library` |
| combat | 10 | `combat_phase_v8`, `combat_damage_steps`, `combat_instant_removal_window` |
| trigger | 11 | `resolve_or_enqueue_trigger`, `flush_triggers_in_apnap`, `trigger_spell_cast_engines` |
| target | 12 | `is_legal_target`, `targeting_decision`, `removal_target_candidates` |
| rule | 11 | `_select_primary_runtime_rule`, `_annotated_battle_rule_effect`, `_build_composite_battle_rule_effect` |
| effect | 16 | `get_card_effect`, `apply_effect_immediate`, `resolve_composite_resolution_effect` |
| mulligan | 7 | `mulligan_evaluation`, `mulligan_decision`, `_emit_mulligan_decision_trace` |
| decision | 10 | `emit_decision_trace`, `decision_card_option`, `targeting_decision` |

## Replay Event Surface

The engine currently emits `94` literal replay event names. This is much broader
than the action critic and forensic subsets already documented in the event
contract audit.

Representative emitted families:

- casting/cost: `cast_announced`, `cast_illegal`, `cost_paid`,
  `additional_cost_paid`, `additional_cost_failed`, `spell_cast`,
  `spell_resolved`, `spell_countered`;
- turn/priority: `turn_start`, `priority_pass`, `turn_end`;
- combat: `combat_step`, `multi_defender_attack`, `combat_result`, `combat`;
- triggers: `trigger_put_on_stack`, `trigger_resolved`,
  `utility_land_triggered`, `saga_chapter_progressed`,
  `saga_chapter_resolved`;
- abilities: `activated_ability`, `activated_ability_skipped`,
  `utility_artifact_activated`, `utility_land_activated`,
  `loyalty_ability_activated`;
- zones/replacements: `replacement_applied`, `token_ceased_to_exist`,
  `warp_exiled_end_step`, `warp_recast_from_exile`;
- effects: `board_wipe_resolved`, `wheel_resolved`, `tutor_resolved`,
  `recursion_resolved`, `damage_resolved`, `topdeck_manipulation_activated`.

Current risk remains the same as the event contract audit: event emission is
rich, but validation classification is not centrally declared per event type.

## Decision Trace Surface

`battle_analyst_v9.py` has `34` `emit_decision_trace(...)` call sites. Literal
decision kinds emitted by static extraction:

- `mulligan_decision`
- `pass_no_action`
- `response`
- `utility_land_activation`
- `utility_artifact_activation`
- `activated_sacrifice_damage`
- `attack_trigger_artifact_tutor`
- `lorehold_upkeep_rummage`
- `cast_spell`
- `saga_chapter_resolution`
- `combat_attack`
- `wheel`
- `board_wipe`
- `worldfire_reset`
- `tutor`

Latest seed `786135854` decision types:

| Decision type | Count |
| --- | ---: |
| `pass_no_action` | 69 |
| `cast_spell` | 35 |
| `combat_attack` | 24 |
| `mulligan_decision` | 8 |
| `utility_artifact_activation` | 8 |
| `lorehold_upkeep_rummage` | 4 |
| `saga_chapter_resolution` | 1 |
| `wheel` | 1 |
| `tutor` | 1 |
| `response` | 1 |

Latest seed had `152` decision rows and `0` rows missing `score_components`.

Open traceability gap: there is no generated matrix that says, for every emitted
decision type, which auditor validates it, what fields are required, and whether
current latest artifacts exercised it.

## Effect/Template Surface

Static effect literals referenced by the engine: `57`.

Forensic `SUPPORTED_EFFECTS`: `52`.

Latest effect coverage snapshot:

- `effect_coverage_unknowns`: `33`
- `effect_totals.unknown`: `41`
- `heuristic_effects`: `120`
- `runtime_safe_rule_names`: `1702`
- `active_or_review_rule_names`: `3159`
- `review_only_rule_names`: `1457`
- `review_only_rule_instances`: `34`

Effect totals seen in latest coverage include real implemented families such as
`counter=99`, `ramp_permanent=129`, `tutor=82`, `ramp_ritual=55`,
`draw_engine=39`, `remove_permanent=33`, and `land=377`, but still include
`unknown=41`.

Operational reading: many action/effect templates exist, and core tests pass,
but the project still lacks a single effect/template contract mapping:

- `effect_json.effect`;
- runtime handler/function;
- emitted replay event(s);
- action critic behavior;
- forensic support;
- focused test fixture;
- current latest coverage count.

Without that map, "all card action templates are created" is not currently
provable.

## Test Surface Observed

Runtime suites with direct battle coverage found by static scan include:

- `battle_card_specific_tests.py`: `62` tests, broad card/effect mechanics.
- `battle_stack_casting_tests.py`: `17` tests, stack/priority/casting/payment.
- `battle_turn_flow_tests.py`: `24` tests, turn flow, mulligan, extra turns.
- `battle_combat_tests.py`: `14` tests, combat/blocking/damage.
- `battle_event_trigger_tests.py`: `5` tests, APNAP/triggers/event ordering.
- `battle_zone_transition_tests.py`: `19` tests, zones, tutors, wheels, tokens.
- `battle_replacement_tests.py`: `7` tests, prevention/replacement.
- `battle_targeting_tests.py`: `7` tests, protection/hexproof/ward/targets.
- `battle_rules_2026_tests.py`: `6` tests, modern mechanics.

Validation commands run in this audit, all exit code `0`:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_turn_flow_tests.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_event_trigger_tests.py`

This is strong evidence for many mechanics, but it is still suite-based and not
a proof that every effect/template in the live corpus has a handler and fixture.

## Findings

### Runtime effect/template manifest missing

The engine has a broad effect surface (`57` effect literals), forensic supports
`52`, and latest coverage still has `unknown=41` effect totals and `33`
`unknown_effect` flags. The current tests prove many mechanics, but not a
complete effect-by-effect template contract.

Required next validation: generate or maintain a manifest where every
`effect_json.effect` maps to handler, event, critic/forensic support, focused
fixture, and latest coverage count.

### Decision trace taxonomy manifest missing

The engine emits at least `15` decision kinds across `34` call sites, while
latest seed exercised `10` kinds. The latest trace has complete
`score_components`, but there is no summary that proves every emitted decision
kind has a required-field contract and an owning auditor.

Required next validation: a decision taxonomy matrix with emitted kinds,
required fields, latest count, and auditor coverage.

## Register Updates Needed

- Add a P1/P2 finding for missing effect/template contract.
- Add a P2 finding for missing decision trace taxonomy/auditor ownership matrix.
