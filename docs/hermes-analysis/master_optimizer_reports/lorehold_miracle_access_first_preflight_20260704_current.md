# Lorehold Miracle Access First Preflight

- generated_at: `2026-07-04T23:55:14Z`
- status: `no_current_candidate_passes_miracle_access_first_preflight`
- postgres_writes: `false`
- source_db_mutated: `false`
- deck_607_mutated: `false`
- preflight_contract: `miracle_access_first_shell_v1`
- candidate_count: `2`
- gate_ready_now_count: `0`
- promotion_allowed: `false`
- keep_607_as_protected_baseline: `true`

## Floors From Current 607 Evidence

- strategic_floors_from_607: `{"lorehold_cost_paid": 27, "lorehold_spell_cast": 22, "lorehold_upkeep_rummage": 5, "miracle_cast": 4, "topdeck_manipulation_activated": 5}`
- anchor_access_floors_from_607: `{"Land Tax": 1, "Library of Leng": 0, "Lorehold, the Historian": 3, "Scroll Rack": 1, "Sensei's Divining Top": 2, "The Mind Stone": 2, "Urza's Saga": 1}`

## Candidate Preflight

| Candidate | Status | Record | vs 607 | Blockers |
| --- | --- | ---: | ---: | --- |
| challenger_lorehold_spell_pressure_mana_conversion_deoverfill_v1 | `blocked_before_next_gate` | `1W/3L/0S` | `0W/1L/0S` | `["aggregate_topdeck_anchor_access_regressed", "head_to_head_vs_607_not_won_or_tied", "land_tax_access_below_607_floor", "lorehold_cost_paid_below_607_floor", "lorehold_spell_cast_below_607_floor", "pressure_card_use_not_observed", "pressure_causality_unproven", "pressure_conversion_not_proven", "senseis_divining_top_access_below_607_floor", "the_mind_stone_access_below_607_floor", "topdeck_manipulation_activated_below_607_floor"]` |
| challenger_lorehold_spell_volume_access_depressure_v1 | `blocked_before_next_gate` | `0W/4L/0S` | `0W/1L/0S` | `["aggregate_topdeck_anchor_access_regressed", "fast_pressure_slice_regressed", "head_to_head_vs_607_not_won_or_tied", "land_tax_access_below_607_floor", "lorehold_cost_paid_below_607_floor", "lorehold_spell_cast_below_607_floor", "lorehold_upkeep_rummage_below_607_floor", "miracle_cast_below_607_floor", "miracle_trace_missing", "pressure_card_use_not_observed", "pressure_causality_unproven", "scroll_rack_access_below_607_floor", "senseis_divining_top_access_below_607_floor", "the_mind_stone_access_below_607_floor", "topdeck_activation_missing", "topdeck_manipulation_activated_below_607_floor", "urzas_saga_access_below_607_floor"]` |

## Required Before Next Natural Gate

- declare the repaired failure mode before building the shell
- retain protected anchors or provide same-lane replacement proof before battle
- meet or exceed the current 607 miracle/topdeck strategic floors in the same seed window
- meet or exceed current 607 natural access to topdeck anchors
- show pressure or mana conversion only after the miracle/topdeck floor is preserved
- tie or beat fixed deck_607 head-to-head and avoid fast-pressure regression

## External Research Refresh

- Wizards Commander format: https://magic.wizards.com/en/formats/commander
  - Legality, singleton, and color identity are prerequisite gates only.
- EDHREC optimized Topdeck Lorehold page: https://edhrec.com/decks/lorehold-the-historian/optimized/topdeck
  - Current public Lorehold lists are tagged around Topdeck and Spellslinger, so the next shell must preserve that plan before adding pressure.
- EDHREC Miracles Every Turn with Lorehold: https://edhrec.com/articles/miracles-every-turn-with-lorehold-the-historian-in-commander
  - Lorehold's opponent-upkeep rummage creates first-draw miracle windows; top-library setup is the engine floor.
- EDHREC Boros Miracles on a Budget: https://edhrec.com/articles/lorehold-the-historian-boros-miracles-on-a-budget
  - Instant/sorcery density and non-dud first draws matter more than generic value-card insertion.

## Decision

- allow_new_natural_gate_now: `false`
- next_action: `design_new_shell_or_package_that_first_satisfies_miracle_access_floors`
