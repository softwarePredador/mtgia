# Lorehold Safe-Cut Replanner

- generated_at: `2026-07-04T21:21:31Z`
- postgres_writes: `False`
- source_db_mutated: `False`
- ledger: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_learning_evidence_ledger_20260628_v6.json`
- source_group_count: `2`
- cut_pool_count: `94`
- manifest_ready_count: `0`
- manifest_package_count: `0`
- blocked_reason_counts: `{"cut_is_early_mana_floor_support": 28, "cut_is_miracle_core_big_spell": 50, "cut_is_protection_shell": 28, "cut_not_flex_decision": 168, "incompatible_lane": 143, "missing_cut_safety_row": 154, "never_cut_lane": 58, "prior_rejected_cut": 74, "prior_rejected_signature": 4, "protected_cut": 44, "same_as_blocked_source_cut": 2}`

## Interpretation

- No follow-up package should be gated from this report.
- Every alternate cut was blocked by cut-safety, structural role, lane compatibility, or prior rejected evidence.
- Next action is to expand the cut-safety evidence or run a manual cut review before spending battle-gate time.

## Manifest Ready Packages

- None.

## Top Blocked Followups

| Package | Source | Cut | Blockers |
| --- | --- | --- | --- |
| past_in_flames_recast_safe_cut_ancient_tomb | `past_in_flames_recast` | `Ancient Tomb` | `cut_not_flex_decision, incompatible_lane, missing_cut_safety_row, never_cut_lane` |
| past_in_flames_recast_safe_cut_approach_of_the_second_sun | `past_in_flames_recast` | `Approach of the Second Sun` | `cut_is_miracle_core_big_spell, cut_not_flex_decision, incompatible_lane, missing_cut_safety_row` |
| past_in_flames_recast_safe_cut_arcane_signet | `past_in_flames_recast` | `Arcane Signet` | `cut_is_early_mana_floor_support, prior_rejected_cut` |
| past_in_flames_recast_safe_cut_arid_mesa | `past_in_flames_recast` | `Arid Mesa` | `cut_not_flex_decision, incompatible_lane, missing_cut_safety_row, never_cut_lane` |
| past_in_flames_recast_safe_cut_artists_talent | `past_in_flames_recast` | `Artist's Talent` | `cut_not_flex_decision, missing_cut_safety_row, prior_rejected_cut` |
| past_in_flames_recast_safe_cut_avatars_wrath | `past_in_flames_recast` | `Avatar's Wrath` | `cut_is_miracle_core_big_spell, cut_is_protection_shell, cut_not_flex_decision, incompatible_lane, missing_cut_safety_row, prior_rejected_cut` |
| past_in_flames_recast_safe_cut_battlefield_forge | `past_in_flames_recast` | `Battlefield Forge` | `cut_not_flex_decision, incompatible_lane, missing_cut_safety_row, never_cut_lane` |
| past_in_flames_recast_safe_cut_benders_waterskin | `past_in_flames_recast` | `Bender's Waterskin` | `cut_is_early_mana_floor_support, cut_not_flex_decision, prior_rejected_cut, protected_cut, same_as_blocked_source_cut` |
| past_in_flames_recast_safe_cut_big_score | `past_in_flames_recast` | `Big Score` | `cut_is_miracle_core_big_spell, cut_not_flex_decision, missing_cut_safety_row, prior_rejected_cut` |
| past_in_flames_recast_safe_cut_blasphemous_act | `past_in_flames_recast` | `Blasphemous Act` | `cut_is_early_mana_floor_support, cut_is_miracle_core_big_spell, cut_not_flex_decision, missing_cut_safety_row` |
| past_in_flames_recast_safe_cut_bloodstained_mire | `past_in_flames_recast` | `Bloodstained Mire` | `cut_not_flex_decision, incompatible_lane, missing_cut_safety_row, never_cut_lane` |
| past_in_flames_recast_safe_cut_boros_signet | `past_in_flames_recast` | `Boros Signet` | `cut_is_early_mana_floor_support, prior_rejected_cut` |
| past_in_flames_recast_safe_cut_call_forth_the_tempest | `past_in_flames_recast` | `Call Forth the Tempest` | `cut_is_miracle_core_big_spell, cut_not_flex_decision, incompatible_lane, missing_cut_safety_row` |
| past_in_flames_recast_safe_cut_command_beacon | `past_in_flames_recast` | `Command Beacon` | `cut_not_flex_decision, incompatible_lane, missing_cut_safety_row, never_cut_lane` |
| past_in_flames_recast_safe_cut_command_tower | `past_in_flames_recast` | `Command Tower` | `cut_not_flex_decision, incompatible_lane, missing_cut_safety_row, never_cut_lane` |
| past_in_flames_recast_safe_cut_creative_technique | `past_in_flames_recast` | `Creative Technique` | `cut_is_miracle_core_big_spell, incompatible_lane, prior_rejected_cut, protected_cut` |
| past_in_flames_recast_safe_cut_dawns_truce | `past_in_flames_recast` | `Dawn's Truce` | `cut_is_protection_shell, cut_not_flex_decision, prior_rejected_cut, protected_cut` |
| past_in_flames_recast_safe_cut_deflecting_swat | `past_in_flames_recast` | `Deflecting Swat` | `cut_is_protection_shell, cut_not_flex_decision, incompatible_lane, missing_cut_safety_row` |
| past_in_flames_recast_safe_cut_eiganjo,_seat_of_the_empire | `past_in_flames_recast` | `Eiganjo, Seat of the Empire` | `cut_not_flex_decision, incompatible_lane, missing_cut_safety_row, never_cut_lane` |
| past_in_flames_recast_safe_cut_elegant_parlor | `past_in_flames_recast` | `Elegant Parlor` | `cut_not_flex_decision, incompatible_lane, missing_cut_safety_row, never_cut_lane` |
