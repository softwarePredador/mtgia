# Global Commander Mana Base Profile

- generated_at: `2026-07-05T19:56:29.072256+00:00`
- mutation_allowed: `false`
- postgres_writes: `false`
- source_db_mutated: `false`
- battle_or_optimization_performed: `false`
- profile_count: `9`
- status_counts: `{"mana_profile_ready_for_named_land_candidate_pool": 9}`
- top_next_action: `build_named_land_candidate_pool_from_mana_profiles`

## Profiles

| Deck | Commander | Colors | Status | Lands | Floor | Access | Recommendations |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `612` | `Lorehold, the Historian` | `WR` | `mana_profile_ready_for_named_land_candidate_pool` | 27/34 | 21 | W:15, R:17 | add_land_quantity_before_spell_slots, add_W_source_or_fetchable_access, add_R_source_or_fetchable_access, limit_colorless_utility_until_color_floor, review_fetchable_dual_or_basic_mix |
| `616` | `Lorehold, the Historian` | `WR` | `mana_profile_ready_for_named_land_candidate_pool` | 29/34 | 21 | W:16, R:19 | add_land_quantity_before_spell_slots, add_W_source_or_fetchable_access, add_R_source_or_fetchable_access, review_fetchable_dual_or_basic_mix |
| `609` | `Lorehold, the Historian` | `WR` | `mana_profile_ready_for_named_land_candidate_pool` | 30/34 | 21 | W:18, R:19 | add_land_quantity_before_spell_slots, add_W_source_or_fetchable_access, add_R_source_or_fetchable_access, prioritize_untapped_fixing_lands, limit_colorless_utility_until_color_floor, review_fetchable_dual_or_basic_mix |
| `610` | `Lorehold, the Historian` | `WR` | `mana_profile_ready_for_named_land_candidate_pool` | 30/34 | 21 | W:20, R:18 | add_land_quantity_before_spell_slots, add_W_source_or_fetchable_access, add_R_source_or_fetchable_access, limit_colorless_utility_until_color_floor |
| `608` | `Lorehold, the Historian` | `WR` | `mana_profile_ready_for_named_land_candidate_pool` | 31/34 | 21 | W:10, R:25 | add_land_quantity_before_spell_slots, add_W_source_or_fetchable_access, limit_colorless_utility_until_color_floor, review_fetchable_dual_or_basic_mix |
| `613` | `Lorehold, the Historian` | `WR` | `mana_profile_ready_for_named_land_candidate_pool` | 32/34 | 21 | W:18, R:19 | add_land_quantity_before_spell_slots, add_W_source_or_fetchable_access, add_R_source_or_fetchable_access, limit_colorless_utility_until_color_floor, review_fetchable_dual_or_basic_mix |
| `621` | `Y'shtola, Night's Blessed` | `WUB` | `mana_profile_ready_for_named_land_candidate_pool` | 32/34 | 15 | W:16, U:17, B:19 | add_land_quantity_before_spell_slots, review_fetchable_dual_or_basic_mix |
| `6` | `Lorehold, the Historian` | `WR` | `mana_profile_ready_for_named_land_candidate_pool` | 33/34 | 21 | W:23, R:23 | add_land_quantity_before_spell_slots, limit_colorless_utility_until_color_floor, review_fetchable_dual_or_basic_mix |
| `614` | `Lorehold, the Historian` | `WR` | `mana_profile_ready_for_named_land_candidate_pool` | 33/34 | 21 | W:24, R:19 | add_land_quantity_before_spell_slots, add_R_source_or_fetchable_access, review_fetchable_dual_or_basic_mix |

## Policy

- diagnostic_source_floor: Heuristic only: each commander color must have enough direct or fetchable access before named land candidates can be reviewed. This is not a promotion gate by itself.
- named_lands: This report does not name additions. Candidate lands require commander color identity, legality, current ownership/availability if applicable, same-lane cuts, and battle trace evidence.
