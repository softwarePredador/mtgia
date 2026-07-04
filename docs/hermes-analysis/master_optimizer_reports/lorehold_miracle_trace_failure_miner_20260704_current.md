# Lorehold Miracle Trace Failure Miner

- generated_at: `2026-07-04T23:49:39Z`
- status: `lorehold_miracle_trace_failure_learning_ready`
- postgres_writes: `false`
- source_db_mutated: `false`
- deck_607_mutated: `false`
- candidate_count: `2`
- promotion_allowed: `false`
- keep_607_as_protected_baseline: `true`
- next_shell_contract: `miracle_access_first_shell`
- blocking_failure_flags: `["head_to_head_not_won", "miracle_trace_missing", "topdeck_activation_missing", "topdeck_anchor_access_regressed", "pressure_causality_unproven", "pressure_conversion_unproven", "fast_pressure_slice_not_protected"]`

## Candidate Gate Summary

| Candidate | Record | vs 607 | Miracle | Topdeck | Anchor Access Delta | Flags | Decision |
| --- | ---: | ---: | ---: | ---: | ---: | --- | --- |
| challenger_lorehold_spell_pressure_mana_conversion_deoverfill_v1 | `1W/3L/0S` | `0W/1L/0S` | `8` | `4` | `-2` | `["head_to_head_not_won", "pressure_causality_unproven", "pressure_conversion_unproven", "topdeck_activation_regressed", "topdeck_anchor_access_regressed"]` | `do_not_promote_pressure_unproven` |
| challenger_lorehold_spell_volume_access_depressure_v1 | `0W/4L/0S` | `0W/1L/0S` | `0` | `0` | `-4` | `["fast_pressure_slice_not_protected", "head_to_head_not_won", "mana_event_without_conversion_to_wins", "miracle_trace_missing", "miracle_volume_regressed", "pressure_causality_unproven", "topdeck_activation_missing", "topdeck_activation_regressed", "topdeck_anchor_access_regressed"]` | `reject_current_depressure_shell` |

## External Learning Applied

- Wizards Commander format: https://magic.wizards.com/en/formats/commander
  - Color identity and singleton legality are entry gates only; colorless cards can be legal, but legality does not prove deck value.
- EDHREC Lorehold commander page: https://edhrec.com/commanders/lorehold-the-historian
  - The current public Lorehold surface is tagged around Topdeck, Spellslinger, Discard, and Burn; high-synergy cards include Library of Leng, Storm Herd, Sensei's Divining Top, Approach of the Second Sun, and Scroll Rack.
- EDHREC Miracles Every Turn article: https://edhrec.com/articles/miracles-every-turn-with-lorehold-the-historian-in-commander
  - Lorehold's upkeep rummage creates first-draw miracle windows on opponents' turns; top-library tools and Library of Leng are core engine cards, not replaceable generic utility.
- EDHREC Boros Miracles budget article: https://edhrec.com/articles/lorehold-the-historian-boros-miracles-on-a-budget
  - The deck wants a high instant/sorcery density and spell-lands so the first draw each turn is not a dud for miracle.

## Staple Accessibility Snapshot

- Mana Vault: commander `legal`, color_identity `[]`, edhrec_rank `145`, source https://scryfall.com/card/2x2/308/mana-vault
  - Externally legal and powerful. In the current ManaLoom corpus it is also internally available and runtime-modeled, so the 607 blocker is safe-cut plus equal battle proof, not color identity.
- The One Ring: commander `legal`, color_identity `[]`, edhrec_rank `90`, source https://scryfall.com/card/ltr/246/the-one-ring
  - Externally legal and colorless. In the current ManaLoom corpus it is also internally available and runtime-modeled, but a generic protection/draw staple is not automatically better than a Lorehold miracle/topdeck anchor.

## Internal Accessibility Snapshot

- source_db: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Mana Vault: oracle_cache `true`, runtime_rule `true`, in_607 `false`, in_615 `true`, blocker `not_in_protected_607_and_prior_cut_battle_evidence_rejected`
  - rule_statuses: `["active/auto"]`
  - known_deck_ids: `[6, 31, 54, 58, 62, 74, 83, 84, 104, 105, 606, 612, 613, 615, 619, 621]`
- The One Ring: oracle_cache `true`, runtime_rule `true`, in_607 `false`, in_615 `true`, blocker `not_in_protected_607_and_prior_cut_battle_evidence_rejected`
  - rule_statuses: `["verified/auto"]`
  - known_deck_ids: `[6, 84, 608, 613, 615, 619, 620, 621]`

## Learned Priority Order

1. legal_identity_and_card_availability
2. commander_intent_and_topdeck_miracle_density
3. natural_access_to_topdeck_anchors
4. trace_proof_that_miracle_window_executes
5. pressure_or_mana_conversion_after_engine_floor_is_preserved
6. same_seed_battle_gate_ties_or_beats_607

## Decision

- treat_mana_vault_and_the_one_ring_as_external_legal_staples_but_internal_unproven
- predeclare_anchor_access_floors_for_land_tax_scroll_rack_top_library_mind_stone_urzas_saga
- require_nonzero_miracle_cast_and_topdeck_activation_before_confirm_gate
- reject_any_candidate_that_loses_head_to_head_to_fixed_607_even_if_structural_matrix_ranks_high
