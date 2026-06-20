# Battle Effect Coverage Priority Audit - 2026-06-19 17:16Z

## Scope

This report prioritizes the current `effect_coverage=review_required` gate from
the recurring ManaLoom battle audit. It is evidence-only: no PostgreSQL changes,
no swaps, no product-code edits, and no commits.

Source artifacts:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_171605/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_171605/effect_coverage.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_171605/unknown_template_backlog.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/effect_coverage_priority_171605/effect_coverage_priority.json`

## Gate Snapshot

| Field | Value |
| --- | ---: |
| `battle_replay_final_status` | `review_required` |
| `mandatory_gate_divergences` | `["effect_coverage=review_required"]` |
| `action_findings` | `0` |
| `strategy_findings` | `0` |
| `decision_audit_decision_findings` | `0` |
| `effect_coverage_unknowns` | `33` |
| `heuristic_effects` | `120` |
| `needs_review_rule_names` | `1457` |
| `unknown_template_without_focused_template_match` | `29` |

Alert paths checked:

- `seeds_with_high_or_critical_action_findings`: `[]`
- `seeds_with_strategy_blockers`: `[]`
- `seeds_with_high_or_critical_decision_audit_findings`: `[]`
- `seeds_with_high_or_critical_forensic_findings`: `[]`

## Effect Coverage Snapshot

| Metric | Value |
| --- | ---: |
| `deck_id` | `6` |
| `opponents_loaded` | `12` |
| `total_card_instances` | `1288` |
| `unique_cards` | `556` |
| `runtime_safe_rule_names` | `1702` |
| `needs_review_rule_names` | `1457` |
| `review_status_counts.active` | `27` |
| `review_status_counts.verified` | `1675` |
| `review_status_counts.needs_review` | `1457` |

Source totals:

| Source | Count |
| --- | ---: |
| `battle_rule_curated` | `724` |
| `type_land` | `377` |
| `effect_map` | `100` |
| `battle_rule_needs_review_generated` | `34` |
| `unknown` | `33` |
| `tag` | `20` |

Risk flags:

| Flag | Count |
| --- | ---: |
| `trigger_not_explicit` | `147` |
| `heuristic_effect` | `120` |
| `cast_permission_not_explicit` | `89` |
| `temporary_effect_not_explicit` | `65` |
| `land_utility_ability_not_modeled` | `48` |
| `needs_review_rule` | `34` |
| `unknown_effect` | `33` |
| `oracle_target_removal_mismatch` | `20` |
| `oracle_silence_mismatch` | `15` |
| `copy_effect_mismatch` | `1` |

## Priority Findings

| Priority | Finding | Evidence | Required outcome |
| --- | --- | --- | --- |
| P1 | Unknown template backlog has triage, but no focused runtime support. | `29` unknown cards, `29` without focused template match, `29` with plan/waiver slot, `plan_status_counts={"template_required": 29}`. | Each current unknown card gets a focused template, executable fixture, or accepted waiver. |
| P1 | Generic/heuristic effects are still too broad for learning trust. | `heuristic_effect=120`; flagged sources include `effect_map=72`, `tag=20`; `creature` alone has `104` flagged rows. | Convert broad effect_map/tag/creature fallbacks into explicit rules/contracts or waivers. |
| P1 | Timing, permission, and trigger semantics are not explicit enough in the replay contract. | `trigger_not_explicit=147`, `cast_permission_not_explicit=89`, `temporary_effect_not_explicit=65`. | Decision/event trace records trigger source, cast permission window, temporary duration, target, and outcome. |
| P2 | `needs_review` generated rules exist inside the real deck corpus. | `needs_review_rule=34`, `needs_review_rule_names=1457`. | Keep review-only rules out of runtime learning or promote only after review and test evidence. |
| P2 | Land utility and oracle mismatch families need explicit fixtures or waivers. | `land_utility_ability_not_modeled=48`, `oracle_target_removal_mismatch=20`, `oracle_silence_mismatch=15`, `copy_effect_mismatch=1`. | Add narrow fixtures/waivers for land activated abilities, target semantics, silence semantics, and copy effects. |

## Deck Priority

| Deck | Flagged | Unknown | Heuristic | Trigger | Cast permission | Temporary | Land utility | Unknown cards |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `Magda, Brazen Outlaw #71 (real)` | `48` | `8` | `24` | `8` | `3` | `9` | `3` | `Ashnod's Transmogrant`, `Clown Car`, `God-Pharaoh's Statue`, `Liquimetal Coating`, `Mine Collapse`, `Stoke the Flames`, `Sudden Shock`, `Thorn of Amethyst` |
| `Yorion, Sky Nomad #38 (real)` | `40` | `8` | `16` | `2` | `4` | `1` | `0` | `Cryptic Coat`, `Cursed Windbreaker`, `Dissection Tools`, `Nevermore`, `Out of Time`, `Reality Acid`, `Scroll of Fate`, `Tragic Arrogance` |
| `Urza, Lord High Artificer #87 (real)` | `36` | `5` | `12` | `12` | `6` | `5` | `3` | `Banishing Knack`, `Codex Shredder`, `Copy Artifact`, `Power Artifact`, `Submerge` |
| `Ishai, Ojutai Dragonspeaker #28 (real)` | `37` | `2` | `10` | `13` | `8` | `4` | `2` | `Firestorm`, `Flash Photography` |
| `Akiri, Line-Slinger #30 (real)` | `36` | `2` | `8` | `16` | `8` | `5` | `4` | `Candelabra of Tawnos`, `Hidden Strings` |

## Unknown Template Families

The recurring backlog gate is now useful as a denominator: every current unknown
card has a reviewed family and an explicit owner/next fixture, but none has a
focused template match.

Largest reviewed families:

| Reviewed family | Cards |
| --- | ---: |
| `manifest_cloak_equipment` | `3` |
| `impulse_topdeck_or_library_zone` | `2` |
| `additional_cost_discard_multi_target_damage` | `1` |
| `alternative_cost_library_bounce` | `1` |
| `alternative_cost_sacrifice_mountain_damage` | `1` |
| `convoke_damage` | `1` |
| `copy_artifact_static_as_enters` | `1` |
| `copy_permanent_with_flash_or_flashback` | `1` |
| `copy_token_with_delayed_sacrifice` | `1` |
| `cost_reduction_static_aura` | `1` |
| `tap_untap_cipher_trigger` | `1` |
| `utility_artifact_untap_x_lands` | `1` |

High-value fixtures to add first because they cover common failure shapes:

- `Hidden Strings`: tap/untap plus cipher trigger.
- `Submerge`: alternative cost plus top-of-library bounce.
- `Stoke the Flames`: convoke payment plus damage.
- `Sudden Shock`: split second priority lock plus damage.
- `Tragic Arrogance`: per-player permanent type choice and sacrifice.
- `Cryptic Coat`: cloak/manifest equipment enter and attach.
- `God-Pharaoh's Statue`: static tax plus end-step life loss.
- `Candelabra of Tawnos`: X land untap activated ability.
- `Firestorm`: discard-X additional cost and multi-target damage.

## Closure Criteria

Do not treat this gate as clean until a later recurring run shows one of these:

- `effect_coverage_unknowns=0` for the target corpus; or
- every remaining unknown has an accepted waiver with reason and owner; and
- `unknown_template_without_focused_template_match=0`; and
- timing/trigger/cast-permission flags are either fixed or waived with an
  explicit event/decision trace contract; and
- `needs_review` rules are either promoted with test evidence or kept
  audit-only and blocked from learning.
