# Lorehold Spell Pressure Overfill Repair

- generated_at: `2026-07-04T23:19:56Z`
- status: `overfill_repair_plan_ready`
- postgres_writes: `false`
- source_db_mutated: `false`
- deck_607_mutated: `false`
- candidate_key: `challenger_lorehold_spell_pressure_mana_conversion_v1`
- overfilled_packages: `{"hand_filter": {"actual": 19, "gap": 0, "maximum": 18, "minimum": 10, "overage": 1, "score": 9.444, "status": "overfilled", "weight": 10.0}, "spell_chain_conversion": {"actual": 47, "gap": 0, "maximum": 46, "minimum": 32, "overage": 1, "score": 12.717, "status": "overfilled", "weight": 13.0}, "topdeck_miracle_setup": {"actual": 15, "gap": 0, "maximum": 14, "minimum": 8, "overage": 1, "score": 12.071, "status": "overfilled", "weight": 13.0}}`
- trace_status: `pressure_trace_partial_presence_not_conversion_proof`
- wins_with_pressure_conversion_events: `0`
- top_cut_card: `Apex of Power`
- top_replacement_card: `Pearl Medallion`
- promotion_allowed: `false`
- confirmation_allowed: `false`

## Top Cut

- `Apex of Power`: `overfill_cut_candidate`
- overfilled_tags: `["hand_filter", "spell_chain_conversion", "topdeck_miracle_setup"]`
- blockers: `[]`
- after_cut_risks: `[]`

## Top Replacement

- `Pearl Medallion`: `replacement_candidate`
- roles: `["ramp"]`
- tags: `["early_plan"]`
- after_replacement_risks: `[]`

## Decision

- recommended_next_shell: `spell_pressure_mana_conversion_deoverfill`
- reason: Apex of Power is the lowest-risk current overfill cut: it contributes to topdeck, hand-filter, and spell-chain overfill, is not in protected 607, was not exercised in the smoke gate, and removing it repairs the package ranges. Pearl Medallion is the best 607-backed replacement because it preserves early mana without adding spell-chain/topdeck overfill.
- next_actions:
  - generate_deoverfill_shell_before_any_larger_gate
  - require_matrix_no_package_overfill_before_confirm_gate
  - require_storm_kiln_or_guttersnipe_conversion_events_before_learning_the_package

## External Learning

- EDHREC average optimized spellslinger: https://edhrec.com/average-decks/lorehold-the-historian/optimized/spellslinger
- EDHREC Boros Miracles budget article: https://edhrec.com/articles/lorehold-the-historian-boros-miracles-on-a-budget
