# Battle Latest Blockers And Effect Residual Audit - 2026-06-19 17:34Z

## Scope

This report records the current local battle validation state for the recurring
ManaLoom audit latest pointer. It is documentation-only: no PostgreSQL changes,
no swaps, no code changes and no commit.

Primary source:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`

Resolved run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_173448/`

Supporting sources:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_173448/effect_coverage.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/latest_blockers_effect_residual_173448/latest_blockers_effect_residual.json`

## Latest Status

| Field | Value |
| --- | --- |
| `timestamp_utc` | `2026-06-19T17:34:48Z` |
| `battle_replay_final_status` | `blocked` |
| `mandatory_gate_divergences` | `action_critic=blocked`, `effect_coverage=review_required`, `forensic_audit=blocked`, `strategy_audit=review_required` |
| `action_findings` | `1` |
| `strategy_findings` | `3` |
| `decision_audit_decision_findings` | `0` |
| `effect_coverage_unknowns` | `0` |
| `heuristic_effects` | `120` |
| high/critical action seeds | `63201749` |
| strategy blocker seeds | none |
| high/critical forensic seeds | `63201736`, `63201744` |

Alert: this run must not be treated as learning-safe. The latest official
summary is blocked by one high action finding and two high forensic findings.

## High Findings

| Gate | Seed | Turn | Evidence | Gap | Required adjustment |
| --- | --- | ---: | --- | --- | --- |
| action critic | `63201749` | 5 | `action-000109`, event `replacement_applied`, label `prevention:life_total_cant_change` | `replacement_without_zone_or_object_metadata`: the replacement event lacks affected object, zone transition and applied replacement list. | Every `replacement_applied` must emit affected object, from/to zones and applied replacement names. |
| forensic audit | `63201736` | 2 | `spell_resolved`, card `Veil of Summer`, effect `draw_cards`, player `Rograkh, Son of Rohgahh #62 (real)` | Event depended on heuristic source `functional_tags_json`. | Move this card/effect path into verified or active `card_battle_rules`, or mark it with an explicit audit-only waiver. |
| forensic audit | `63201744` | 1 | `spell_resolved`, card `Veil of Summer`, effect `draw_cards`, player `Etali, Primal Conqueror #105 (real)` | Event depended on heuristic source `functional_tags_json`. | Move this card/effect path into verified or active `card_battle_rules`, or mark it with an explicit audit-only waiver. |

## Strategy Review

The strategy gate is not blocked, but remains review-required.

| Seed | Decision | Finding | Required handling |
| --- | --- | --- | --- |
| `63201739` | `decision-000005` | `forced_keep_after_bad_mulligan`: negative keep score and no early game plan. | Track separately; do not use the resulting win rate as high-confidence deck quality. |
| `63201740` | `decision-000009` | `forced_keep_after_bad_mulligan`: negative keep score and no early game plan. | Track separately; do not use the resulting win rate as high-confidence deck quality. |
| `63201741` | `decision-000015` | `forced_keep_after_bad_mulligan`: negative keep score and no early game plan. | Track separately; do not use the resulting win rate as high-confidence deck quality. |

## Effect Coverage Residual

`unknown_cards=[]` and `effect_coverage_unknowns=0`, but the coverage gate is
still `review_required`. The remaining risk is residual quality of the rules,
not only missing template names.

Snapshot:

- `opponents_loaded=12`
- `total_card_instances=1288`
- `unique_cards=556`
- `runtime_safe_rule_names=1702`
- `needs_review_rule_names=1457`
- `source_totals`: `battle_rule_curated=724`, `type_land=377`,
  `effect_map=100`, `battle_rule_needs_review_generated=34`,
  `focused_template_ready=33`, `tag=20`
- `review_status_counts`: `active=27`, `needs_review=1457`,
  `verified=1675`

Residual flags:

| Flag | Card rows | Instances | Main source/effect/deck signal |
| --- | ---: | ---: | --- |
| `heuristic_effect` | 92 | 120 | Mostly `effect_map`/`tag`; main effect `creature`; highest deck signal `Magda=24`, `Yorion=16`, `Kinnan=13`. |
| `trigger_not_explicit` | 63 | 147 | Mostly curated rules, but trigger handling remains implicit; highest deck signal `Sisay=19`, `Akiri=16`, `Kenrith=15`, `Lumra=15`. |
| `cast_permission_not_explicit` | 35 | 89 | Mostly curated rules plus some focused templates; highest deck signal `Gwen=12`, `Kraum=10`, `Etali=9`. |
| `temporary_effect_not_explicit` | 38 | 65 | Mostly curated rules; highest deck signal `Magda=9`, `Etali=7`, `Lorehold=7`. |
| `land_utility_ability_not_modeled` | 21 | 48 | All from `type_land`; highest deck signal `Lumra=11`, `Kinnan=6`, `Kenrith=5`. |
| `needs_review_rule` | 29 | 34 | Generated review-only rules; highest deck signal `Lumra=9`, `Yorion=8`. |
| `oracle_target_removal_mismatch` | 10 | 20 | Includes `Pyroblast`, `Red Elemental Blast`, `Mizzix's Mastery`, `Soul-Guide Lantern`. |
| `oracle_silence_mismatch` | 4 | 15 | Includes `Permission Denied`, `Drannith Magistrate`, `Ranger-Captain of Eos`, `Silence`. |
| `copy_effect_mismatch` | 1 | 1 | `Mirrorpool`. |

Top deck residuals:

| Deck | Risk flag instances | Flagged card rows | Main pressure |
| --- | ---: | ---: | --- |
| `Lumra, Bellow of the Woods #49 (real)` | 52 | 40 | `trigger_not_explicit=15`, `land_utility_ability_not_modeled=11`, `needs_review_rule=9`, `heuristic_effect=9` |
| `Magda, Brazen Outlaw #71 (real)` | 51 | 41 | `heuristic_effect=24`, `temporary_effect_not_explicit=9`, `trigger_not_explicit=8` |
| `Akiri, Line-Slinger #30 (real)` | 44 | 35 | `trigger_not_explicit=16`, `cast_permission_not_explicit=8`, `heuristic_effect=8` |
| `Ishai, Ojutai Dragonspeaker #28 (real)` | 44 | 36 | `trigger_not_explicit=13`, `heuristic_effect=10`, `cast_permission_not_explicit=8` |
| `Kinnan, Bonder Prodigy #37 (real)` | 44 | 38 | `heuristic_effect=13`, `trigger_not_explicit=11`, `land_utility_ability_not_modeled=6` |
| `Gwen Stacy #65 (real)` | 43 | 33 | `cast_permission_not_explicit=12`, `trigger_not_explicit=12`, `temporary_effect_not_explicit=6` |
| `Sisay, Weatherlight Captain #31 (real)` | 41 | 35 | `trigger_not_explicit=19`, `cast_permission_not_explicit=8` |
| `Kenrith, the Returned King #113 (real)` | 40 | 32 | `trigger_not_explicit=15`, `cast_permission_not_explicit=5`, `land_utility_ability_not_modeled=5` |

## Required Evaluation Points

1. `replacement_applied` needs a stricter event contract: affected object,
   origin zone, destination zone, replacement source, replacement rule name and
   prevented/replaced value.
2. Heuristic forensic sources such as `functional_tags_json` must be prevented
   from producing high-confidence battle learning unless they are promoted to
   verified/active battle rules or explicitly waived.
3. `effect_coverage_unknowns=0` is not enough. The gate must keep residual
   flags visible until triggers, cast permission, temporary effects, utility
   lands and `needs_review` rules have fixtures, handlers or accepted waivers.
4. Strategy findings from forced bad mulligans must be excluded from
   high-confidence win-rate conclusions.
5. Focused template readiness still needs dispatch/evidence proof from
   `evaluate_draft(...)`; predicate match alone is not executable evidence.

## Register Updates

Open findings added or refreshed in
`docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md`:

- `BV-011`: coverage remains open despite `effect_coverage_unknowns=0`.
- `BV-039`: effect/template contract remains open because residual flags and
  dispatch gaps still exist.
- `BV-049`: high action finding for `replacement_applied` metadata.
- `BV-050`: high forensic finding for heuristic `Veil of Summer` event source.
- `BV-051`: strategy confidence issue for forced bad mulligan keeps.
