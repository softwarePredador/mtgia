# Battle Unknown Effect Denominator Audit - 2026-06-19 19:52 UTC

## Scope

Readonly audit of the current action-template/effect coverage denominators. No
PostgreSQL changes, no swaps, no code edits and no commit.

## Primary artifact

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- Latest realpath:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_193733`
- `timestamp_utc=2026-06-19T19:37:33Z`
- `battle_replay_final_status=review_required`
- `mandatory_gate_divergences=["forensic_audit=review_required"]`
- `seeds_with_high_or_critical_action_findings=[]`
- `seeds_with_strategy_blockers=[]`

## Why this audit exists

The current latest can be read as if all unknown action templates are gone:

- `effect_coverage_unknowns=0`
- `unknown_template_backlog_cards=0`
- `unknown_template_backlog_status=focused_template_backlog_ready`
- `focused_template_dispatch_status=focused_template_dispatch_ready`

However, `effect_coverage.json` still contains:

- `effect_totals.unknown=41`

This is a denominator mismatch. `effect_coverage_unknowns` counts the
`unknown_effect` risk flag, which is emitted only when `source == "unknown"`.
`unknown_template_backlog` only iterates `coverage["unknown_cards"]`, also based
on `source == "unknown"`. A card can therefore have `effect == "unknown"` and
still be absent from the unknown backlog when its source is
`focused_template_ready` or `battle_rule_needs_review_generated`.

## Current counts

| Metric | Value |
| --- | ---: |
| `effect_coverage_unknowns` | 0 |
| `unknown_template_backlog_cards` | 0 |
| `coverage.unknown_cards` | 0 |
| `coverage.effect_totals.unknown` | 41 |
| Unique `focused_template_ready` cards with `effect=unknown` | 28 |
| Unique flagged cards with `effect=unknown` | 12 |
| Flagged `effect=unknown` from `battle_rule_needs_review_generated` | 5 |
| Flagged `effect=unknown` from `focused_template_ready` | 7 |

## Focused-template cards still carrying effect=unknown

`effect_coverage.json` reports `29` focused template cards. `28/29` still carry
`effect=unknown`; only `Banishing Knack` is represented as
`remove_permanent`.

Examples:

| Card | Focused template |
| --- | --- |
| `Flash Photography` | `supports_copy_permanent_flash_or_flashback_template` |
| `Heroes' Hangout` | `supports_impulse_topdeck_or_library_zone_template` |
| `Hidden Strings` | `supports_tap_untap_cipher_trigger_template` |
| `Kindle the Inner Flame` | `supports_copy_token_delayed_sacrifice_template` |
| `Liquimetal Coating` | `supports_type_change_continuous_effect_template` |
| `Submerge` | `supports_alternative_cost_library_bounce_template` |
| `Ashnod's Transmogrant` | `supports_counter_type_change_template` |
| `Candelabra of Tawnos` | `supports_utility_artifact_untap_x_lands_template` |
| `Copy Artifact` | `supports_copy_artifact_as_enters_template` |
| `Cryptic Coat` | `supports_manifest_cloak_equipment_template` |
| `Stoke the Flames` | `supports_convoke_damage_template` |
| `Sudden Shock` | `supports_split_second_damage_template` |
| `Tragic Arrogance` | `supports_modal_mass_sacrifice_selection_template` |

Operational reading: these cards have focused-template predicates and focused
evidence dispatch, but the coverage effect label is still `unknown`. They are
not `source=unknown`, so they do not appear in the unknown backlog.

## Needs-review generated cards with effect=unknown

The flagged non-focused examples are:

| Card | Source | Flags |
| --- | --- | --- |
| `Amulet of Vigor` | `battle_rule_needs_review_generated` | `needs_review_rule`, `trigger_not_explicit` |
| `Blood Moon` | `battle_rule_needs_review_generated` | `needs_review_rule` |
| `Exploration` | `battle_rule_needs_review_generated` | `needs_review_rule` |
| `Ghostly Flicker` | `battle_rule_needs_review_generated` | `needs_review_rule` |
| `Grasp of Fate` | `battle_rule_needs_review_generated` | `needs_review_rule` |

Operational reading: these are not in `unknown_template_backlog` either, because
their source is generated/needs-review rather than source unknown.

## Code path

Relevant implementation observations:

- `battle_effect_coverage_audit.py` increments `effect_totals[effect]` from
  `battle.get_card_effect(card).get("effect", "unknown")`.
- The same script adds the `unknown_effect` flag only when `source == "unknown"`.
- `coverage["unknown_cards"]` is built with `card["source"] == "unknown"`, not
  with `card["effect"] == "unknown"`.
- `battle_unknown_template_backlog_audit.py` iterates only
  `coverage["unknown_cards"]`.
- The wrapper summary maps `effect_coverage_unknowns` from
  `flag_totals.unknown_effect`, not from `effect_totals.unknown`.

Therefore the current `unknown_template_backlog_cards=0` proves there are no
source-unknown cards in that backlog. It does not prove there are zero
unknown-effect action families in coverage.

## Risk

A future agent or report can say "unknown backlog is zero" or "focused template
dispatch is ready" and accidentally imply that all card action effects are
fully modeled. The current artifact still has `41` card instances whose effect
label is `unknown`.

That weakens the exact answer to "all card action templates are created": the
focused backlog is ready, but the broader action-effect denominator still has
unknown effect labels and needs-review unknown effects.

## Recommended adjustments

1. Add explicit summary fields:
   - `effect_totals_unknown`
   - `focused_template_ready_unknown_effect_cards`
   - `needs_review_unknown_effect_cards`
2. Update unknown backlog wording so `unknown_cards=0` is not used as proof that
   `effect=unknown` is zero.
3. For focused-template-ready cards, either map the focused template to a stable
   effect family or report `effect=unknown` as an accepted but visible residual
   denominator.
4. For needs-review generated cards with `effect=unknown`, require promotion,
   focused evidence or waiver before treating them as complete action templates.
5. In handoffs, report `effect_coverage_unknowns` together with
   `effect_totals.unknown`.

## Closing criteria

This finding can be closed when either:

- `effect_totals.unknown=0`; or
- the summary/report separates source-unknown backlog from effect-unknown
  coverage, lists every `effect=unknown` card source, and marks each as focused
  ready, needs-review, waived or blocked with an owner.

The key invariant is that `unknown_template_backlog_cards=0` must no longer be
read as "there are no unknown effects in the battle corpus."

## Validation commands run

- Parsed:
  - `summary.json`
  - `effect_coverage.json`
  - `effect_coverage_residual.json`
  - `focused_template_dispatch.json`
  - `unknown_template_backlog.json`
- Static inspection of:
  - `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
  - `docs/hermes-analysis/manaloom-knowledge/scripts/battle_effect_coverage_audit.py`
  - `docs/hermes-analysis/manaloom-knowledge/scripts/battle_unknown_template_backlog_audit.py`

