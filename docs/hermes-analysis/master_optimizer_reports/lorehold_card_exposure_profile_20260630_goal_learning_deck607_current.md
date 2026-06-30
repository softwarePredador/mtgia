# Lorehold Card Exposure Profile - 2026-06-28

- Generated at: `2026-06-30T20:47:31Z`
- Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Evidence paths scanned: `281`
- JSON files scanned: `207`
- JSONL files scanned: `74`
- Parse errors: `0`

## Card Profiles

| Card | Unique Exposure | Role | Decision | Signals | Top Events/Metrics |
| --- | ---: | --- | --- | --- | --- |
| Ancient Tomb | 39 | `tutor_access` | `review_required` | ramp_engine, tutor_access, tutor_target | activated_ability=19, activated_ability_skipped=1, land_played=15, tutor_resolved=2, utility_land_activated=2 |
| Approach of the Second Sun | 140 | `runtime_ready_unexposed` | `review_required` | miracle_hit, paid_cast_exposure | approach_cast_tracked=2, approach_first_resolution=1, cast_announced=1, cost_paid=66, miracle_cast=3, cost_paid:Approach of the Second Sun=82, discard_to_top:Approach of the Second Sun=55, lorehold_rummage_to_top:Approach of the Second Sun=55, miracle:Approach of the Second Sun=49 |
| Arcane Signet | 176 | `ramp_engine` | `review_required` | paid_cast_exposure, ramp_engine | cost_paid=112, spell_cast=2, cost_paid:Arcane Signet=223 |
| Arid Mesa | 13 | `runtime_ready_unexposed` | `review_required` | none | land_played=13 |
| Artist's Talent | 463 | `draw_filter_value` | `review_required` | discard_payoff, draw_filter_value, paid_cast_exposure | cost_paid=3, trigger_resolved=256, trigger_skipped=171, cost_paid:Artist's Talent=118 |
| Avatar's Wrath | 112 | `runtime_ready_unexposed` | `review_required` | discard_or_rummage_context, miracle_hit, paid_cast_exposure | airbend_other_creatures_resolved=34, cost_paid=22, replacement_applied=16, turn_end=2, cost_paid:Avatar's Wrath=10, discard_to_top:Avatar's Wrath=16, lorehold_rummage_to_top:Avatar's Wrath=88, miracle:Avatar's Wrath=35 |
| Battlefield Forge | 15 | `ramp_engine` | `review_required` | ramp_engine | land_played=15 |
| Bender's Waterskin | 266 | `ramp_engine` | `review_required` | paid_cast_exposure, ramp_engine | cost_paid=216, cost_paid:Bender's Waterskin=181 |
| Big Score | 38 | `discard_ramp_value` | `review_required` | discard_or_rummage_context, discard_payoff, miracle_hit, paid_cast_exposure, ramp_engine | additional_cost_paid=3, cost_paid=24, turn_end=4, cost_paid:Big Score=19, miracle:Big Score=1 |
| Blasphemous Act | 295 | `board_wipe_pressure_reset` | `review_required` | discard_or_rummage_context, miracle_hit, pressure_reset_board_wipe | board_wipe_resolved=2, cost_paid=6, damage_wipe_resolved=11, miracle_cast=3, permanent_moved_from_battlefield=10, discard_to_top:Blasphemous Act=32, lorehold_rummage_to_top:Blasphemous Act=26, miracle:Blasphemous Act=6, spell_rummage_to_top:Blasphemous Act=5, static_cost_reduction_on:Blasphemous Act=921 |
| Bloodstained Mire | 31 | `runtime_ready_unexposed` | `review_required` | none | land_played=31 |
| Boros Signet | 54 | `ramp_engine` | `review_required` | paid_cast_exposure, ramp_engine | cost_paid=14, cost_paid:Boros Signet=180 |
| Call Forth the Tempest | 8 | `ramp_engine` | `review_required` | discard_or_rummage_context, ramp_engine | cost_paid=2, turn_end=2, discard_to_top:Call Forth the Tempest=22, lorehold_rummage_to_top:Call Forth the Tempest=22 |
| Command Beacon | 18 | `runtime_ready_unexposed` | `review_required` | none | land_played=18 |
| Command Tower | 93 | `tutor_access` | `review_required` | tutor_access, tutor_target | activated_ability=6, land_played=86, tutor_resolved=1 |
| Creative Technique | 38 | `runtime_ready_unexposed` | `review_required` | discard_or_rummage_context, paid_cast_exposure | cost_paid=24, demonstrate_resolved=1, top_nonland_free_cast=2, top_nonland_free_cast_resolved=1, turn_end=6, cost_paid:Creative Technique=4, discard_to_top:Creative Technique=3, lorehold_rummage_to_top:Creative Technique=3 |
| Dawn's Truce | 17 | `runtime_ready_unexposed` | `review_required` | protection_window | protection_resolved=1, discard_to_top:Dawn's Truce=21, lorehold_rummage_to_top:Dawn's Truce=43 |
| Deflecting Swat | 116 | `spot_removal` | `review_required` | spot_removal | cast_announced=4, cost_paid=4, miracle_cast=2, priority_pass=16, redirect_removal_resolved=2, discard_to_top:Deflecting Swat=437, lorehold_rummage_to_top:Deflecting Swat=383, spell_rummage_to_top:Deflecting Swat=2 |
| Eiganjo, Seat of the Empire | 96 | `runtime_ready_unexposed` | `review_required` | none | land_played=96 |
| Elegant Parlor | 8 | `runtime_ready_unexposed` | `review_required` | none | land_played=8 |
| Emeria's Call // Emeria, Shattered Skyclave | 86 | `token_protection_rebuild` | `not_safe_as_blind_cut` | board_development_tokens, discard_or_rummage_context, miracle_hit, protection_window | cost_paid=4, protection_resolved=38, tokens_created=38, turn_end=2, discard_to_top:Emeria's Call // Emeria, Shattered Skyclave=11, lorehold_rummage_to_top:Emeria's Call // Emeria, Shattered Skyclave=11, miracle:Emeria's Call // Emeria, Shattered Skyclave=6 |
| Esper Sentinel | 456 | `draw_filter_value` | `review_required` | draw_filter_value, paid_cast_exposure, tutor_target | cast_announced=5, cost_paid=5, pg073_rule_snapshot=1, pg073_rule_summary=1, priority_pass=31, cost_paid:Esper Sentinel=238 |
| Everything Comes to Dust | 34 | `board_wipe_pressure_reset` | `review_required` | discard_or_rummage_context, miracle_hit, pressure_reset_board_wipe | board_wipe_resolved=27, cost_paid=2, turn_end=2, discard_to_top:Everything Comes to Dust=13, lorehold_rummage_to_top:Everything Comes to Dust=10, miracle:Everything Comes to Dust=3 |
| Exotic Orchard | 14 | `runtime_ready_unexposed` | `review_required` | none | land_played=14 |
| Farewell | 179 | `board_wipe_pressure_reset` | `review_required` | discard_or_rummage_context, miracle_hit, pressure_reset_board_wipe | permanent_moved_from_battlefield=8, replacement_applied=133, turn_end=2, discard_to_top:Farewell=84, lorehold_rummage_to_top:Farewell=84, miracle:Farewell=3 |
| Fated Clash | 261 | `board_wipe_pressure_reset` | `review_required` | discard_or_rummage_context, miracle_hit, pressure_reset_board_wipe, protection_window | board_wipe_resolved=123, cost_paid=6, permanent_moved_from_battlefield=49, replacement_applied=6, spell_resolved=74, miracle:Fated Clash=2 |
| Fellwar Stone | 69 | `ramp_engine` | `review_required` | paid_cast_exposure, ramp_engine | spell_resolved=1, cost_paid:Fellwar Stone=448 |
| Flawless Maneuver | 16 | `runtime_ready_unexposed` | `review_required` | protection_window | protection_resolved=10, spell_cast=1, spell_resolved=1, discard_to_top:Flawless Maneuver=27, lorehold_rummage_to_top:Flawless Maneuver=3 |
| Flooded Strand | 18 | `runtime_ready_unexposed` | `review_required` | none | land_played=18 |
| Furygale Flocking | 128 | `runtime_ready_unexposed` | `review_required` | board_development_tokens, miracle_hit, paid_cast_exposure | spell_resolved=1, tokens_created=1, cost_paid:Furygale Flocking=1, discard_to_top:Furygale Flocking=4, lorehold_rummage_to_top:Furygale Flocking=4, miracle:Furygale Flocking=2, static_cost_reduction_on:Furygale Flocking=1194 |
| Generous Gift | 42 | `spot_removal` | `review_required` | miracle_hit, paid_cast_exposure, spot_removal | compensation_tokens_created=1, cost_paid=8, removal_resolved=1, spell_resolved=1, cost_paid:Generous Gift=118, miracle:Generous Gift=4 |
| Giver of Runes | 60 | `runtime_ready_unexposed` | `review_required` | paid_cast_exposure | activated_ability=2, cast_announced=3, cost_paid=3, creature_cast=3, spell_resolved=1, cost_paid:Giver of Runes=138 |
| Glittering Massif | 75 | `ramp_engine` | `review_required` | discard_or_rummage_context, ramp_engine | land_played=73, turn_end=2 |
| Hexing Squelcher | 82 | `runtime_ready_unexposed` | `review_required` | paid_cast_exposure | cost_paid=6, creature_cast=1, creature_to_battlefield=2, replacement_applied=6, spell_resolved=2, cost_paid:Hexing Squelcher=285 |
| High Noon | 66 | `runtime_ready_unexposed` | `review_required` | paid_cast_exposure | spell_resolved=2, cost_paid:High Noon=215 |
| Hit the Mother Lode | 11 | `draw_filter_value` | `review_required` | discard_or_rummage_context, draw_filter_value, miracle_hit, paid_cast_exposure, ramp_engine | cost_paid=4, turn_end=3, cost_paid:Hit the Mother Lode=1, miracle:Hit the Mother Lode=9 |
| Improvisation Capstone | 59 | `draw_filter_value` | `review_required` | draw_filter_value, miracle_hit, paid_cast_exposure | cost_paid=49, cost_paid:Improvisation Capstone=16, miracle:Improvisation Capstone=1 |
| Insurrection | 23 | `runtime_ready_unexposed` | `review_required` | miracle_hit | cost_paid=18, spell_resolved=2, steal_all_creatures_resolved=2, miracle:Insurrection=3 |
| Jeska's Will | 40 | `runtime_ready_unexposed` | `review_required` | miracle_hit, paid_cast_exposure | jeskas_will_resolved=2, spell_cast=2, spell_resolved=2, cost_paid:Jeska's Will=70, discard_to_top:Jeska's Will=4, lorehold_rummage_to_top:Jeska's Will=4, miracle:Jeska's Will=3 |
| Land Tax | 2641 | `tutor_access` | `review_required` | paid_cast_exposure, tutor_access | cost_paid=460, land_tax_trigger_resolved=462, land_tax_trigger_skipped=1663, spell_cast=1, spell_resolved=2, cost_paid:Land Tax=182 |
| Library of Leng | 713 | `runtime_ready_unexposed` | `review_required` | discard_payoff, paid_cast_exposure | cost_paid=618, runtime_rule_loaded=1, saga_chapter_resolved=57, cost_paid:Library of Leng=176 |
| Lightning Greaves | 80 | `runtime_ready_unexposed` | `review_required` | paid_cast_exposure | cast_announced=3, cost_paid=3, equipment_attached=1, equipment_unattached=4, priority_pass=12, cost_paid:Lightning Greaves=199 |
| Lorehold, the Historian | 4627 | `runtime_ready_unexposed` | `review_required` | paid_cast_exposure | cast_announced=13, cast_illegal=8, commander_cast=8, cost_paid=2583, equipment_attached=1, cost_paid:Lorehold, the Historian=2561, static_cost_reduction_on:Lorehold, the Historian=338 |
| Marsh Flats | 29 | `runtime_ready_unexposed` | `review_required` | none | land_played=29 |
| Mizzix's Mastery | 95 | `runtime_ready_unexposed` | `review_required` | discard_or_rummage_context, paid_cast_exposure | cast_announced=3, cost_paid=38, miracle_cast=1, mizzix_mastery_copy_cast=2, mizzix_mastery_resolved=2, cost_paid:Mizzix's Mastery=37 |
| Molecule Man | 79 | `runtime_ready_unexposed` | `review_required` | discard_or_rummage_context, paid_cast_exposure | cost_paid=77, turn_end=1, cost_paid:Molecule Man=3 |
| Monument to Endurance | 56 | `discard_ramp_value` | `review_required` | discard_payoff, paid_cast_exposure, ramp_engine | discard_modal_trigger_resolved=7, cost_paid:Monument to Endurance=128 |
| Mother of Runes | 75 | `runtime_ready_unexposed` | `review_required` | paid_cast_exposure | cast_announced=3, cost_paid=3, creature_cast=5, replacement_applied=12, spell_resolved=1, cost_paid:Mother of Runes=242 |
| Mountain // Mountain | 331 | `runtime_ready_unexposed` | `review_required` | discard_or_rummage_context | land_played=49, land_tax_trigger_resolved=279, turn_end=3 |
| Path to Exile | 145 | `spot_removal` | `review_required` | miracle_hit, paid_cast_exposure, spot_removal | cast_announced=2, cost_paid=30, focused_final_state=1, miracle_cast=3, priority_pass=15, cost_paid:Path to Exile=113, miracle:Path to Exile=6 |
| Pearl Medallion | 128 | `runtime_ready_unexposed` | `review_required` | paid_cast_exposure | cost_paid:Pearl Medallion=134, static_cost_reduction_saved:Pearl Medallion=602, static_cost_reduction_source_cast:Pearl Medallion=602 |
| Pinnacle Monk // Mystic Peak | 8 | `recursion_engine` | `review_required` | graveyard_recursion, paid_cast_exposure | cost_paid=5, etb_recursion_resolved=1, spell_resolved=1, cost_paid:Pinnacle Monk // Mystic Peak=3 |
| Plains // Plains | 209 | `runtime_ready_unexposed` | `review_required` | discard_or_rummage_context | land_played=76, land_tax_trigger_resolved=129, turn_end=4 |
| Plaza of Heroes | 17 | `ramp_engine` | `review_required` | discard_or_rummage_context, ramp_engine | land_played=14, turn_end=3 |
| Prismari Pianist | 65 | `runtime_ready_unexposed` | `review_required` | board_development_tokens, paid_cast_exposure | replacement_applied=6, spell_resolved=1, trigger_resolved=33, cost_paid:Prismari Pianist=85 |
| Prismatic Vista | 14 | `runtime_ready_unexposed` | `review_required` | none | land_played=14 |
| Promise of Loyalty | 53 | `board_wipe_pressure_reset` | `review_required` | discard_or_rummage_context, miracle_hit, paid_cast_exposure, pressure_reset_board_wipe | board_wipe_resolved=14, cost_paid=14, permanent_moved_from_battlefield=13, turn_end=5, cost_paid:Promise of Loyalty=6, discard_to_top:Promise of Loyalty=3, lorehold_rummage_to_top:Promise of Loyalty=3, miracle:Promise of Loyalty=3 |
| Radiant Summit | 7 | `ramp_engine` | `review_required` | discard_or_rummage_context, ramp_engine | land_played=6, turn_end=1 |
| Redirect Lightning | 9 | `spot_removal` | `review_required` | spot_removal | redirect_removal_resolved=1, discard_to_top:Redirect Lightning=40, lorehold_rummage_to_top:Redirect Lightning=40 |
| Reforge the Soul | 23 | `draw_filter_value` | `review_required` | discard_or_rummage_context, discard_payoff, draw_filter_value | cost_paid=7, spell_resolved=2, turn_end=2, wheel_resolved=4, discard_to_top:Reforge the Soul=21, lorehold_rummage_to_top:Reforge the Soul=45 |
| Reliquary Tower | 31 | `runtime_ready_unexposed` | `review_required` | discard_or_rummage_context | land_played=29, turn_end=2 |
| Rise of the Eldrazi | 54 | `spot_removal` | `review_required` | spot_removal, tutor_target | composite_rule_component_resolved=3, composite_rule_resolved=3, cost_paid=3, miracle_cast=6, priority_pass=9, discard_to_top:Rise of the Eldrazi=37, lorehold_rummage_to_top:Rise of the Eldrazi=31, spell_rummage_to_top:Rise of the Eldrazi=5 |
| Ruby Medallion | 179 | `runtime_ready_unexposed` | `review_required` | discard_or_rummage_context, paid_cast_exposure | cost_paid=25, focused_state_assertion=1, spell_resolved=1, turn_end=2, cost_paid:Ruby Medallion=184, static_cost_reduction_saved:Ruby Medallion=728, static_cost_reduction_source_cast:Ruby Medallion=728 |
| Sacred Foundry | 46 | `runtime_ready_unexposed` | `review_required` | none | land_played=46 |
| Scalding Tarn | 38 | `runtime_ready_unexposed` | `review_required` | discard_or_rummage_context | land_played=37, turn_end=1 |
| Scroll Rack | 2345 | `runtime_ready_unexposed` | `review_required` | paid_cast_exposure | activated_ability_skipped=8, cast_announced=1, cost_paid=566, priority_pass=4, runtime_rule_loaded=1, cost_paid:Scroll Rack=176, topdeck:Scroll Rack=1654 |
| Sensei's Divining Top | 2972 | `runtime_ready_unexposed` | `review_required` | paid_cast_exposure | cost_paid=949, saga_chapter_resolved=269, topdeck_manipulation_activated=1508, cost_paid:Sensei's Divining Top=961, topdeck:Sensei's Divining Top=2065 |
| Smothering Tithe | 854 | `ramp_engine` | `review_required` | discard_or_rummage_context, paid_cast_exposure, ramp_engine | cost_paid=65, trigger_resolved=734, turn_end=2, cost_paid:Smothering Tithe=142 |
| Sol Ring | 217 | `ramp_engine` | `review_required` | paid_cast_exposure, ramp_engine | cast_announced=2, cost_paid=128, etb_removal_resolved=2, removal_resolved=3, saga_chapter_resolved=16, cost_paid:Sol Ring=194 |
| Spectator Seating | 9 | `runtime_ready_unexposed` | `review_required` | none | land_played=9 |
| Starfall Invocation | 359 | `board_wipe_pressure_reset` | `review_required` | miracle_hit, paid_cast_exposure, pressure_reset_board_wipe | board_wipe_resolved=86, cost_paid=2, permanent_moved_from_battlefield=86, replacement_applied=181, cost_paid:Starfall Invocation=2, discard_to_top:Starfall Invocation=7, lorehold_rummage_to_top:Starfall Invocation=7, miracle:Starfall Invocation=3 |
| Storm Herd | 25 | `runtime_ready_unexposed` | `review_required` | board_development_tokens, miracle_hit | cost_paid=14, spell_cast=1, spell_resolved=3, tokens_created=2, discard_to_top:Storm Herd=28, lorehold_rummage_to_top:Storm Herd=28, miracle:Storm Herd=1 |
| Stroke of Midnight | 40 | `spot_removal` | `review_required` | miracle_hit, paid_cast_exposure, spot_removal | compensation_tokens_created=1, cost_paid=10, removal_resolved=1, replacement_applied=18, spell_resolved=1, cost_paid:Stroke of Midnight=15, miracle:Stroke of Midnight=6 |
| Sunbaked Canyon | 30 | `runtime_ready_unexposed` | `review_required` | none | activated_ability_skipped=8, land_played=20, utility_land_activated=2 |
| Sunbillow Verge | 32 | `runtime_ready_unexposed` | `review_required` | none | land_played=32 |
| Surge to Victory | 228 | `runtime_ready_unexposed` | `review_required` | discard_or_rummage_context, miracle_hit | cost_paid=7, spell_copied=3, trigger_resolved=191, turn_end=1, miracle:Surge to Victory=51 |
| Swiftfoot Boots | 66 | `runtime_ready_unexposed` | `review_required` | paid_cast_exposure | equipment_attached=1, spell_resolved=1, cost_paid:Swiftfoot Boots=233 |
| Swords to Plowshares | 234 | `spot_removal` | `review_required` | miracle_hit, paid_cast_exposure, spot_removal | cost_paid=66, removal_resolved=1, replacement_applied=135, spell_resolved=1, cost_paid:Swords to Plowshares=64, miracle:Swords to Plowshares=4 |
| Talisman of Conviction | 57 | `runtime_ready_unexposed` | `review_required` | paid_cast_exposure | cost_paid:Talisman of Conviction=211 |
| Teferi's Protection | 24 | `runtime_ready_unexposed` | `review_required` | none | phase_out_resolved=9, replacement_applied=1, self_exiled_on_resolution=1, spell_resolved=1, discard_to_top:Teferi's Protection=32, lorehold_rummage_to_top:Teferi's Protection=32 |
| Tempt with Bunnies | 31 | `draw_filter_value` | `review_required` | board_development_tokens, draw_filter_value, paid_cast_exposure | composite_rule_component_resolved=1, composite_rule_resolved=1, spell_resolved=1, cost_paid:Tempt with Bunnies=64 |
| The Mind Stone | 1869 | `ramp_engine` | `review_required` | paid_cast_exposure, ramp_engine | cost_paid=631, trigger_resolved=916, trigger_skipped=30, utility_artifact_activated=252, cost_paid:The Mind Stone=162 |
| The Scarlet Witch | 352 | `runtime_ready_unexposed` | `review_required` | paid_cast_exposure | cost_paid=304, cost_paid:The Scarlet Witch=88, static_cost_reduction_saved:The Scarlet Witch=288, static_cost_reduction_source_cast:The Scarlet Witch=16 |
| Thor, God of Thunder | 120 | `runtime_ready_unexposed` | `review_required` | paid_cast_exposure | replacement_applied=12, trigger_resolved=60, cost_paid:Thor, God of Thunder=2, spell_cast:Thor, God of Thunder=2, thor_noncreature_damage:Thor, God of Thunder=34, thor_noncreature_damage_amount:Thor, God of Thunder=643 |
| Tibalt's Trickery | 8 | `runtime_ready_unexposed` | `review_required` | none | discard_to_top:Tibalt's Trickery=46, lorehold_rummage_to_top:Tibalt's Trickery=7 |
| Tragic Arrogance | 79 | `board_wipe_pressure_reset` | `review_required` | discard_or_rummage_context, miracle_hit, pressure_reset_board_wipe | board_wipe_resolved=31, cost_paid=6, permanent_moved_from_battlefield=31, turn_end=3, discard_to_top:Tragic Arrogance=15, lorehold_rummage_to_top:Tragic Arrogance=15, miracle:Tragic Arrogance=3 |
| Turbulent Steppe | 8 | `ramp_engine` | `review_required` | ramp_engine | land_played=8 |
| Unexpected Windfall | 33 | `discard_ramp_value` | `review_required` | discard_payoff, miracle_hit, paid_cast_exposure, ramp_engine | additional_cost_paid=5, cost_paid=10, runtime_rule_loaded=1, spell_cast=1, spell_resolved=4, cost_paid:Unexpected Windfall=6, miracle:Unexpected Windfall=6 |
| Urza's Saga | 2174 | `runtime_ready_unexposed` | `review_required` | discard_or_rummage_context | land_played=22, saga_chapter_progressed=1082, saga_chapter_resolved=530, saga_sacrificed_by_sba=537, turn_end=3 |
| Victory Chimes | 266 | `ramp_engine` | `review_required` | paid_cast_exposure, ramp_engine | cost_paid=236, cost_paid:Victory Chimes=126 |
| War Room | 13 | `runtime_ready_unexposed` | `review_required` | none | land_played=13 |
| Winds of Abandon | 45 | `spot_removal` | `review_required` | paid_cast_exposure, spot_removal | cost_paid=10, removal_resolved=2, replacement_applied=16, spell_resolved=2, cost_paid:Winds of Abandon=46 |
| Windswept Heath | 11 | `runtime_ready_unexposed` | `review_required` | none | land_played=11 |
| Wooded Foothills | 44 | `runtime_ready_unexposed` | `review_required` | discard_or_rummage_context | land_played=42, turn_end=2 |

## Package Implications

- `austere_command_over_emeria`: `manual_tradeoff_only` - Emeria has measured token/protection exposure, so Austere must prove board-reset value beats rebuild/protection loss.

## Samples

### Ancient Tomb

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_42.jsonl` path `line:184` turn `10` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_923.jsonl` path `line:12` turn `1` effect `land` metric ``
- `tutor_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seed42/battle_forensic_seed_42.jsonl` path `line:449` turn `6` effect `` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seed42/battle_forensic_seed_42.jsonl` path `line:529` turn `7` effect `land` metric ``
- `utility_land_activated` from `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seed42/battle_forensic_seed_42.jsonl` path `line:530` turn `7` effect `` metric ``
- `tutor_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seeds42_44/battle_forensic_seed_42.jsonl` path `line:449` turn `6` effect `` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seeds42_44/battle_forensic_seed_42.jsonl` path `line:529` turn `7` effect `land` metric ``
- `utility_land_activated` from `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seeds42_44/battle_forensic_seed_42.jsonl` path `line:530` turn `7` effect `` metric ``

### Approach of the Second Sun

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `cast_announced` from `docs/hermes-analysis/master_optimizer_reports/approach_second_sun_pg046_focused_events_20260622_235039.jsonl` path `line:1` turn `46` effect `approach` metric ``
- `approach_cast_tracked` from `docs/hermes-analysis/master_optimizer_reports/approach_second_sun_pg046_focused_events_20260622_235039.jsonl` path `line:2` turn `46` effect `` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/approach_second_sun_pg046_focused_events_20260622_235039.jsonl` path `line:3` turn `46` effect `approach` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/approach_second_sun_pg046_focused_events_20260622_235039.jsonl` path `line:7` turn `46` effect `approach` metric ``
- `pg046_focused_replay_summary` from `docs/hermes-analysis/master_optimizer_reports/approach_second_sun_pg046_focused_events_20260622_235039.jsonl` path `line:9` turn `` effect `` metric ``
- `priority_pass` from `docs/hermes-analysis/master_optimizer_reports/deck6_l6_silence_lock_pg054_focused_events_20260623_013520.jsonl` path `line:3.events[2]` turn `3` effect `` metric ``
- `priority_pass` from `docs/hermes-analysis/master_optimizer_reports/deck6_l6_silence_lock_pg054_focused_events_20260623_013520.jsonl` path `line:3.events[3]` turn `3` effect `` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_l6_silence_lock_pg054_focused_events_20260623_013520.jsonl` path `line:3.events[4]` turn `3` effect `approach` metric ``

### Arcane Signet

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_42.jsonl` path `line:169` turn `9` effect `ramp_permanent` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_42.jsonl` path `line:174` turn `9` effect `ramp_permanent` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[10]` turn `` effect `` metric `cost_paid:Arcane Signet`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[10]` turn `` effect `` metric `cost_paid:Arcane Signet`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[10]` turn `` effect `` metric `cost_paid:Arcane Signet`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_silence_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[10]` turn `` effect `` metric `cost_paid:Arcane Signet`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_austere_emeria_tradeoff_gate_20260627_v1_20260627_232955.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[10]` turn `` effect `` metric `cost_paid:Arcane Signet`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[1].telemetry.top_cards[7]` turn `` effect `` metric `cost_paid:Arcane Signet`

### Arid Mesa

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_923.jsonl` path `line:128` turn `7` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Kenrith, the Returned King #113 (real):0[28]` turn `8` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Winota, Joiner of Forces #39 (real):0[17]` turn `20` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[17]` turn `20` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Kenrith, the Returned King #113 (real):0[28]` turn `8` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Winota, Joiner of Forces #39 (real):0[17]` turn `20` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_post_squee_package_gate_20260627_v1_seed42_hash0_isolated_timeout.json` path `packages[1].gate_summary.candidate.telemetry.squee_game_traces.synergy_faithless_looting_squee_enabler:Vivi Ornitier #99 (real):0[28]` turn `17` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_post_squee_package_gate_20260627_v1_seed42_hash0_isolated_timeout.json` path `packages[2].gate_summary.candidate.telemetry.squee_game_traces.synergy_galvanoth_topdeck_freecast:Sisay, Weatherlight Captain #61 (real):2[46]` turn `12` effect `land` metric ``

### Artist's Talent

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_607_608_pg080_pg081_focused_events_20260623_082229.jsonl` path `line:4` turn `4` effect `rummage` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[9]` turn `` effect `` metric `cost_paid:Artist's Talent`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[5]` turn `` effect `` metric `cost_paid:Artist's Talent`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[2].gate_summary.candidate.telemetry.top_cards[11]` turn `` effect `` metric `cost_paid:Artist's Talent`
- `trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Etali, Primal Conqueror #67 (real):1[40]` turn `8` effect `rummage` metric ``
- `trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Etali, Primal Conqueror #67 (real):1[77]` turn `14` effect `rummage` metric ``
- `trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Etali, Primal Conqueror #67 (real):1[79]` turn `14` effect `rummage` metric ``
- `trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Thrasios, Triton Hero #77 (real):0[52]` turn `10` effect `rummage` metric ``

### Avatar's Wrath

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[8]` turn `` effect `` metric `cost_paid:Avatar's Wrath`
- `airbend_other_creatures_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Tannuk, Memorial Ensign #40 (real):1[36]` turn `14` effect `` metric ``
- `airbend_other_creatures_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Winota, Joiner of Forces #39 (real):0[34]` turn `24` effect `` metric ``
- `airbend_other_creatures_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Winota, Joiner of Forces #39 (real):0[34]` turn `24` effect `` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_creative_technique_seed20260630_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_enlightened_tutor_creative_technique_v1:Thrasios, Triton Hero #101 (real):1[30]` turn `6` effect `airbend_other_creatures` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_creative_technique_seed20260630_real8_games3_partial.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_enlightened_tutor_creative_technique_v1:Thrasios, Triton Hero #101 (real):1[30]` turn `6` effect `airbend_other_creatures` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed123_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kefka, Court Mage #112 (real):2[42]` turn `7` effect `airbend_other_creatures` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed123_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Thrasios, Triton Hero #101 (real):0[60]` turn `8` effect `airbend_other_creatures` metric ``

### Battlefield Forge

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/deck6_l1b_nonfetch_land_mana_pg051_focused_events_20260623_012230.jsonl` path `line:13` turn `1` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Umbris, Fear Manifest #114 (real):1[68]` turn `17` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Vivi Ornitier #99 (real):2[12]` turn `4` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_trace_samples[12]` turn `4` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Winota, Joiner of Forces #39 (real):0[27]` turn `22` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Winota, Joiner of Forces #39 (real):0[27]` turn `22` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brainstone_topdeck_miracle_cut_squelcher:Sisay, Weatherlight Captain #61 (real):2[4]` turn `4` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1.json` path `packages[1].gate_summary.candidate.telemetry.squee_game_traces.synergy_ghostly_prison_pressure_cut_squelcher:Sisay, Weatherlight Captain #61 (real):1[6]` turn `6` effect `land` metric ``

### Bender's Waterskin

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[1]` turn `` effect `` metric `cost_paid:Bender's Waterskin`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_austere_emeria_tradeoff_gate_20260627_v1_20260627_232955.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[5]` turn `` effect `` metric `cost_paid:Bender's Waterskin`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_electro_waterskin_gate_20260630_fixed_20260630_042339_electro_assaulting_battery_same_lane_benchmark_cut_bender_s_waterskin.json` path `results[0].telemetry.focus_card_game_traces.deck_607:K-9, Mark I #34 (real):1[19]` turn `4` effect `ramp_permanent` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_electro_waterskin_gate_20260630_fixed_20260630_042339_electro_assaulting_battery_same_lane_benchmark_cut_bender_s_waterskin.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kraum, Ludevic's Opus #81 (real):2[43]` turn `8` effect `ramp_permanent` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_electro_waterskin_gate_20260630_fixed_20260630_042339_electro_assaulting_battery_same_lane_benchmark_cut_bender_s_waterskin.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Thrasios, Triton Hero #76 (real):1[21]` turn `4` effect `ramp_permanent` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_electro_waterskin_gate_20260630_fixed_20260630_042339_electro_assaulting_battery_same_lane_benchmark_cut_bender_s_waterskin.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Thrasios, Triton Hero #76 (real):2[57]` turn `9` effect `ramp_permanent` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_creative_technique_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:K-9, Mark I #34 (real):1[19]` turn `4` effect `ramp_permanent` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_creative_technique_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kraum, Ludevic's Opus #81 (real):2[43]` turn `8` effect `ramp_permanent` metric ``

### Big Score

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_creative_technique_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kraum, Ludevic's Opus #81 (real):1[79]` turn `13` effect `treasure_maker` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_creative_technique_seed20260630_real8_games3_partial.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kraum, Ludevic's Opus #81 (real):1[79]` turn `13` effect `treasure_maker` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed123_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_enlightened_tutor_insurrection_v1:Kefka, Court Mage #112 (real):1[91]` turn `13` effect `treasure_maker` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed123_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_enlightened_tutor_insurrection_v1:Kraum, Ludevic's Opus #81 (real):2[47]` turn `8` effect `treasure_maker` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed123_real8_games3_partial.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_enlightened_tutor_insurrection_v1:Kefka, Court Mage #112 (real):1[91]` turn `13` effect `treasure_maker` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed123_real8_games3_partial.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_enlightened_tutor_insurrection_v1:Kraum, Ludevic's Opus #81 (real):2[47]` turn `8` effect `treasure_maker` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kraum, Ludevic's Opus #81 (real):1[79]` turn `13` effect `treasure_maker` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed20260630_real8_games3_partial.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kraum, Ludevic's Opus #81 (real):1[79]` turn `13` effect `treasure_maker` metric ``

### Blasphemous Act

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/blasphemous_act_pg029_focused_events_20260622_192517.jsonl` path `line:1` turn `5` effect `damage_wipe` metric ``
- `damage_wipe_resolved` from `docs/hermes-analysis/master_optimizer_reports/blasphemous_act_pg029_focused_events_20260622_192517.jsonl` path `line:2` turn `5` effect `` metric ``
- `priority_pass` from `docs/hermes-analysis/master_optimizer_reports/flawless_maneuver_pg032_focused_events_20260622_200215.jsonl` path `line:4` turn `3` effect `` metric ``
- `priority_pass` from `docs/hermes-analysis/master_optimizer_reports/flawless_maneuver_pg032_focused_events_20260622_200215.jsonl` path `line:5` turn `3` effect `` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/flawless_maneuver_pg032_focused_events_20260622_200215.jsonl` path `line:6` turn `3` effect `damage_wipe` metric ``
- `damage_wipe_resolved` from `docs/hermes-analysis/master_optimizer_reports/flawless_maneuver_pg032_focused_events_20260622_200215.jsonl` path `line:7` turn `3` effect `` metric ``
- `miracle_cast` from `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seed42/battle_forensic_seed_42.jsonl` path `line:918` turn `14` effect `board_wipe` metric ``
- `priority_pass` from `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seed42/battle_forensic_seed_42.jsonl` path `line:919` turn `14` effect `` metric ``

### Bloodstained Mire

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_42.jsonl` path `line:19` turn `1` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_42.jsonl` path `line:25` turn `2` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_923.jsonl` path `line:177` turn `9` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[2].gate_summary.candidate.telemetry.squee_game_traces.synergy_reprieve_cut_avatar_wrath:Winota, Joiner of Forces #39 (real):0[22]` turn `7` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seed42/battle_forensic_seed_42.jsonl` path `line:75` turn `2` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seeds42_44/battle_forensic_seed_42.jsonl` path `line:75` turn `2` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Umbris, Fear Manifest #114 (real):1[11]` turn `5` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed42_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Winota, Joiner of Forces #39 (real):0[58]` turn `17` effect `land` metric ``

### Boros Signet

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_silence_fixed.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[3]` turn `` effect `` metric `cost_paid:Boros Signet`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v5_exposure_smoke_20260627_213725.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[11]` turn `` effect `` metric `cost_paid:Boros Signet`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed123_real8_games3.json` path `results[1].telemetry.top_cards[5]` turn `` effect `` metric `cost_paid:Boros Signet`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed123_real8_games3_partial.json` path `results[1].telemetry.top_cards[5]` turn `` effect `` metric `cost_paid:Boros Signet`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed999_real8_games3.json` path `results[0].telemetry.top_cards[11]` turn `` effect `` metric `cost_paid:Boros Signet`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed999_real8_games3_partial.json` path `results[0].telemetry.top_cards[11]` turn `` effect `` metric `cost_paid:Boros Signet`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed42_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[6]` turn `` effect `` metric `cost_paid:Boros Signet`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_fixed607_v2_spellchain_big_sorcery_fixed607_gate.json` path `results[1].telemetry.top_cards[4]` turn `` effect `` metric `cost_paid:Boros Signet`

### Call Forth the Tempest

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `discard_to_top` from `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_vault_method_repair_gate_20260630_seed123_real8_games3.json` path `results[1].telemetry.top_cards[10]` turn `` effect `` metric `discard_to_top:Call Forth the Tempest`
- `lorehold_rummage_to_top` from `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_vault_method_repair_gate_20260630_seed123_real8_games3.json` path `results[1].telemetry.top_cards[9]` turn `` effect `` metric `lorehold_rummage_to_top:Call Forth the Tempest`
- `discard_to_top` from `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_vault_method_repair_gate_20260630_seed123_real8_games3_partial.json` path `results[1].telemetry.top_cards[10]` turn `` effect `` metric `discard_to_top:Call Forth the Tempest`
- `lorehold_rummage_to_top` from `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_vault_method_repair_gate_20260630_seed123_real8_games3_partial.json` path `results[1].telemetry.top_cards[9]` turn `` effect `` metric `lorehold_rummage_to_top:Call Forth the Tempest`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_promotion_gate_607_614_615_20260629_seed20260625_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Tannuk, Memorial Ensign #40 (real):2[59]` turn `10` effect `damage_wipe` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_promotion_gate_607_614_615_20260629_seed42_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.deck_614:Kenrith, the Returned King #113 (real):1[104]` turn `11` effect `damage_wipe` metric ``
- `turn_end` from `docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_access_conversion_gate_20260627_seed7_v1_tutor_access_v1.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_gamble_approach_access_cut_creative:Sisay, Weatherlight Captain #61 (real):2[1]` turn `1` effect `` metric ``
- `turn_end` from `docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_access_conversion_gate_20260627_seed7_v1_tutor_access_v1.json` path `packages[0].gate_summary.candidate.telemetry.squee_trace_samples[1]` turn `1` effect `` metric ``

### Command Beacon

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v5_exposure_smoke_20260627_213725.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Kenrith, the Returned King #113 (real):0[13]` turn `15` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v5_exposure_smoke_20260627_213725.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[13]` turn `15` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed20260625_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_core_challenge_dance_over_storm:Winota, Joiner of Forces #39 (real):0[16]` turn `17` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_lapse_approach_gate_20260627_v1_fixed.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_lapse_approach_topdeck_cut_tibalts_trickery:Vivi Ornitier #99 (real):0[13]` turn `6` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_lapse_approach_gate_20260627_v1_fixed.json` path `packages[0].gate_summary.candidate.telemetry.squee_trace_samples[13]` turn `6` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed20260625_v1_library_pressure_v1.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brainstone_topdeck_miracle_cut_squelcher:Winota, Joiner of Forces #39 (real):0[63]` turn `21` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_gate_20260627_v1_real.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_plateau_timing_upgrade_cut_radiant_summit:Vivi Ornitier #99 (real):0[15]` turn `6` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_gate_20260627_v1_real.json` path `packages[0].gate_summary.candidate.telemetry.squee_trace_samples[15]` turn `6` effect `land` metric ``

### Command Tower

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_923.jsonl` path `line:60` turn `4` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):0[10]` turn `14` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[10]` turn `14` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):0[10]` turn `14` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[10]` turn `14` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):0[10]` turn `14` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[10]` turn `14` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[2].gate_summary.candidate.telemetry.squee_game_traces.synergy_reprieve_cut_avatar_wrath:Winota, Joiner of Forces #39 (real):0[8]` turn `4` effect `land` metric ``

### Creative Technique

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed123_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:K-9, Mark I #34 (real):0[84]` turn `10` effect `exile_top_nonland_free_cast` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed123_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kraum, Ludevic's Opus #81 (real):2[55]` turn `8` effect `exile_top_nonland_free_cast` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed123_real8_games3_partial.json` path `results[0].telemetry.focus_card_game_traces.deck_607:K-9, Mark I #34 (real):0[84]` turn `10` effect `exile_top_nonland_free_cast` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed123_real8_games3_partial.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kraum, Ludevic's Opus #81 (real):2[55]` turn `8` effect `exile_top_nonland_free_cast` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed20260630_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_enlightened_tutor_insurrection_v1:Kinnan, Bonder Prodigy #72 (real):2[92]` turn `14` effect `exile_top_nonland_free_cast` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed20260630_real8_games3_partial.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_enlightened_tutor_insurrection_v1:Kinnan, Bonder Prodigy #72 (real):2[92]` turn `14` effect `exile_top_nonland_free_cast` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed999_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:K-9, Mark I #34 (real):1[117]` turn `18` effect `exile_top_nonland_free_cast` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed999_real8_games3_partial.json` path `results[0].telemetry.focus_card_game_traces.deck_607:K-9, Mark I #34 (real):1[117]` turn `18` effect `exile_top_nonland_free_cast` metric ``

### Dawn's Truce

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `lorehold_rummage_to_top` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[1].telemetry.top_cards[11]` turn `` effect `` metric `lorehold_rummage_to_top:Dawn's Truce`
- `lorehold_rummage_to_top` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3_partial.json` path `results[1].telemetry.top_cards[11]` turn `` effect `` metric `lorehold_rummage_to_top:Dawn's Truce`
- `protection_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Tannuk, Memorial Ensign #40 (real):1[31]` turn `13` effect `` metric ``
- `discard_to_top` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_leng_telemetry_gate_20260627_seed20260625_squee_v1.json` path `results[0].telemetry.top_cards[10]` turn `` effect `` metric `discard_to_top:Dawn's Truce`
- `lorehold_rummage_to_top` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_leng_telemetry_gate_20260627_seed20260625_squee_v1.json` path `results[0].telemetry.top_cards[9]` turn `` effect `` metric `lorehold_rummage_to_top:Dawn's Truce`
- `discard_to_top` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed20260625_v1_library_pressure_v1.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[10]` turn `` effect `` metric `discard_to_top:Dawn's Truce`
- `lorehold_rummage_to_top` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed20260625_v1_library_pressure_v1.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[9]` turn `` effect `` metric `lorehold_rummage_to_top:Dawn's Truce`
- `discard_to_top` from `docs/hermes-analysis/master_optimizer_reports/lorehold_life_floor_conversion_gate_20260627_seed20260625_v1_life_floor_v1.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[10]` turn `` effect `` metric `discard_to_top:Dawn's Truce`

### Deflecting Swat

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/deflecting_swat_pg031_focused_events_20260622_195126.jsonl` path `line:1` turn `3` effect `redirect_removal` metric ``
- `redirect_removal_resolved` from `docs/hermes-analysis/master_optimizer_reports/deflecting_swat_pg031_focused_events_20260622_195126.jsonl` path `line:2` turn `3` effect `` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_42.jsonl` path `line:64` turn `4` effect `redirect_removal` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_42.jsonl` path `line:65` turn `4` effect `redirect_removal` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_42.jsonl` path `line:78` turn `4` effect `redirect_removal` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_42.jsonl` path `line:79` turn `4` effect `redirect_removal` metric ``
- `miracle_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_923.jsonl` path `line:230` turn `12` effect `redirect_removal` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_923.jsonl` path `line:231` turn `12` effect `redirect_removal` metric ``

### Eiganjo, Seat of the Empire

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):0[16]` turn `15` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[16]` turn `15` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):0[16]` turn `15` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[16]` turn `15` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):0[16]` turn `15` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[16]` turn `15` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_silence_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):0[16]` turn `15` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_silence_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[16]` turn `15` effect `land` metric ``

### Elegant Parlor

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Tannuk, Memorial Ensign #40 (real):1[49]` turn `17` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed20260625_v1_library_pressure_v1.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brainstone_topdeck_miracle_cut_squelcher:Winota, Joiner of Forces #39 (real):1[26]` turn `21` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed7_v1_library_pressure_v1.json` path `packages[2].gate_summary.candidate.telemetry.squee_game_traces.synergy_one_ring_protection_draw_cut_squelcher:Vivi Ornitier #99 (real):1[11]` turn `5` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed7_v1_library_pressure_v1.json` path `packages[2].gate_summary.candidate.telemetry.squee_trace_samples[11]` turn `5` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_gate_20260627_v1_real.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_plateau_timing_upgrade_cut_radiant_summit:Vivi Ornitier #99 (real):1[19]` turn `7` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed20260624_v1.json` path `results[2].telemetry.squee_game_traces.candidate_607_squee_hashseed0_isolated_cached_timeout_v3:Vivi Ornitier #99 (real):1[57]` turn `19` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_topfreecast_conversion_gate_20260627_seed42_v2_topfreecast_v2.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_galvanoth_topdeck_freecast_cut_thor:Vivi Ornitier #99 (real):2[64]` turn `17` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_access_conversion_gate_20260627_seed42_v2_gamble_tutor_access_v2.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_gamble_access_cut_thor:Vivi Ornitier #99 (real):2[64]` turn `17` effect `land` metric ``

### Emeria's Call // Emeria, Shattered Skyclave

- Decision: `not_safe_as_blind_cut`; next: test_austere_only_as_explicit_wipe_over_rebuild_tradeoff
- `protection_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[2].gate_summary.candidate.telemetry.squee_game_traces.synergy_reprieve_cut_avatar_wrath:Sisay, Weatherlight Captain #61 (real):0[8]` turn `8` effect `` metric ``
- `tokens_created` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[2].gate_summary.candidate.telemetry.squee_game_traces.synergy_reprieve_cut_avatar_wrath:Sisay, Weatherlight Captain #61 (real):0[9]` turn `8` effect `token_maker` metric ``
- `protection_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[2].gate_summary.candidate.telemetry.squee_trace_samples[8]` turn `8` effect `` metric ``
- `tokens_created` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[2].gate_summary.candidate.telemetry.squee_trace_samples[9]` turn `8` effect `token_maker` metric ``
- `turn_end` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Winota, Joiner of Forces #39 (real):0[1]` turn `4` effect `` metric ``
- `protection_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Aang, at the Crossroads #106 (real):1[15]` turn `13` effect `` metric ``
- `tokens_created` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Aang, at the Crossroads #106 (real):1[16]` turn `13` effect `token_maker` metric ``
- `protection_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Sisay, Weatherlight Captain #61 (real):0[22]` turn `8` effect `` metric ``

### Esper Sentinel

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg073_l4_card_flow_focused_events_20260623_051141.jsonl` path `line:2` turn `4` effect `draw_cards` metric ``
- `pg073_rule_snapshot` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg073_l4_l6_card_flow_focused_events_20260623_052954.jsonl` path `line:1` turn `` effect `draw_engine` metric ``
- `trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg073_l4_l6_card_flow_focused_events_20260623_052954.jsonl` path `line:2` turn `4` effect `draw_cards` metric ``
- `trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg073_l4_l6_card_flow_focused_events_20260623_052954.jsonl` path `line:3` turn `5` effect `draw_cards` metric ``
- `pg073_rule_summary` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg073_l4_l6_card_flow_focused_events_20260623_052954.jsonl` path `line:4` turn `` effect `` metric ``
- `tutor_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg076_support_passive_annotation_focused_events_20260623_054358.jsonl` path `line:6` turn `6` effect `` metric ``
- `tutor_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_recruiter_guard_pg064_focused_events_20260623_025848.jsonl` path `line:3` turn `3` effect `` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[4]` turn `` effect `` metric `cost_paid:Esper Sentinel`

### Everything Comes to Dust

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `board_wipe_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):1[13]` turn `14` effect `` metric ``
- `board_wipe_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[13]` turn `14` effect `` metric ``
- `board_wipe_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Tannuk, Memorial Ensign #40 (real):1[43]` turn `15` effect `` metric ``
- `board_wipe_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Umbris, Fear Manifest #114 (real):1[57]` turn `14` effect `` metric ``
- `board_wipe_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Umbris, Fear Manifest #114 (real):1[74]` turn `18` effect `` metric ``
- `board_wipe_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Umbris, Fear Manifest #114 (real):1[76]` turn `18` effect `` metric ``
- `board_wipe_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v5_exposure_smoke_20260627_213725.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Kenrith, the Returned King #113 (real):0[5]` turn `13` effect `` metric ``
- `board_wipe_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v5_exposure_smoke_20260627_213725.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[5]` turn `13` effect `` metric ``

### Exotic Orchard

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_42.jsonl` path `line:15` turn `1` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Rograkh, Son of Rohgahh #62 (real):1[27]` turn `11` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Rograkh, Son of Rohgahh #62 (real):1[13]` turn `10` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Rograkh, Son of Rohgahh #62 (real):1[13]` turn `9` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed7_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_core_challenge_dance_over_storm:Winota, Joiner of Forces #39 (real):0[21]` turn `11` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brainstone_topdeck_miracle_cut_squelcher:Sisay, Weatherlight Captain #61 (real):1[9]` turn `9` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_gate_20260627_v1_real.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_plateau_timing_upgrade_cut_radiant_summit:Vivi Ornitier #99 (real):1[53]` turn `15` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_post_squee_package_gate_20260627_v1_seed42_hash0_isolated_timeout.json` path `packages[1].gate_summary.candidate.telemetry.squee_game_traces.synergy_faithless_looting_squee_enabler:Vivi Ornitier #99 (real):0[46]` turn `21` effect `land` metric ``

### Farewell

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `replacement_applied` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Etali, Primal Conqueror #67 (real):0[71]` turn `10` effect `` metric ``
- `replacement_applied` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kinnan, Bonder Prodigy #57 (real):0[74]` turn `10` effect `` metric ``
- `replacement_applied` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_boros_charm_tibalts_trickery_v1:Kinnan, Bonder Prodigy #84 (real):0[98]` turn `13` effect `` metric ``
- `replacement_applied` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_boros_charm_tibalts_trickery_v1:Lumra, Bellow of the Woods #49 (real):2[25]` turn `4` effect `` metric ``
- `replacement_applied` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_boros_charm_tibalts_trickery_v1:Thrasios, Triton Hero #77 (real):1[38]` turn `8` effect `` metric ``
- `replacement_applied` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3_partial.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Etali, Primal Conqueror #67 (real):0[71]` turn `10` effect `` metric ``
- `replacement_applied` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3_partial.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kinnan, Bonder Prodigy #57 (real):0[74]` turn `10` effect `` metric ``
- `replacement_applied` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3_partial.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_boros_charm_tibalts_trickery_v1:Kinnan, Bonder Prodigy #84 (real):0[98]` turn `13` effect `` metric ``

### Fated Clash

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):0[8]` turn `14` effect `fated_clash_protect_then_destroy` metric ``
- `board_wipe_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):0[9]` turn `14` effect `` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[8]` turn `14` effect `fated_clash_protect_then_destroy` metric ``
- `board_wipe_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[9]` turn `14` effect `` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):0[8]` turn `14` effect `fated_clash_protect_then_destroy` metric ``
- `board_wipe_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):0[9]` turn `14` effect `` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[8]` turn `14` effect `fated_clash_protect_then_destroy` metric ``
- `board_wipe_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[9]` turn `14` effect `` metric ``

### Fellwar Stone

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg070_l2_hash_only_runtime_focused_events_20260623_011859.jsonl` path `line:3` turn `7` effect `ramp_permanent` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[1].gate_summary.candidate.telemetry.top_cards[8]` turn `` effect `` metric `cost_paid:Fellwar Stone`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_chaos_warp_stroke_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.top_cards[8]` turn `` effect `` metric `cost_paid:Fellwar Stone`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_cloud_key_waterskin_gate_20260630_all_lanes_20260630_082705.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[8]` turn `` effect `` metric `cost_paid:Fellwar Stone`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_deflecting_palm_redirect_lightning_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.top_cards[8]` turn `` effect `` metric `cost_paid:Fellwar Stone`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_electro_waterskin_gate_20260630_fixed_20260630_042339.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[8]` turn `` effect `` metric `cost_paid:Fellwar Stone`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_electro_waterskin_gate_20260630_fixed_20260630_042339_electro_assaulting_battery_same_lane_benchmark_cut_bender_s_waterskin.json` path `results[0].telemetry.top_cards[8]` turn `` effect `` metric `cost_paid:Fellwar Stone`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_creative_technique_seed20260630_real8_games3.json` path `results[0].telemetry.top_cards[8]` turn `` effect `` metric `cost_paid:Fellwar Stone`

### Flawless Maneuver

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/flawless_maneuver_pg032_focused_events_20260622_200215.jsonl` path `line:1` turn `3` effect `indestructible` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/flawless_maneuver_pg032_focused_events_20260622_200215.jsonl` path `line:2` turn `3` effect `indestructible` metric ``
- `protection_resolved` from `docs/hermes-analysis/master_optimizer_reports/flawless_maneuver_pg032_focused_events_20260622_200215.jsonl` path `line:3` turn `3` effect `` metric ``
- `protection_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Umbris, Fear Manifest #114 (real):1[45]` turn `12` effect `` metric ``
- `protection_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Vivi Ornitier #99 (real):2[26]` turn `7` effect `` metric ``
- `protection_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed20260625_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_core_challenge_dance_over_storm:Sisay, Weatherlight Captain #61 (real):1[24]` turn `16` effect `` metric ``
- `protection_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_life_floor_conversion_gate_20260627_seed20260625_v1_life_floor_v1.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_angel_grace_life_floor_cut_dawn:Sisay, Weatherlight Captain #61 (real):0[14]` turn `19` effect `` metric ``
- `discard_to_top` from `docs/hermes-analysis/master_optimizer_reports/lorehold_one_ring_gate_20260630_creative_technique_seed20260630_real8_games3.json` path `results[1].telemetry.top_cards[6]` turn `` effect `` metric `discard_to_top:Flawless Maneuver`

### Flooded Strand

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_42.jsonl` path `line:137` turn `7` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_923.jsonl` path `line:28` turn `2` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Tannuk, Memorial Ensign #40 (real):1[45]` turn `16` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Kenrith, the Returned King #113 (real):0[9]` turn `4` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Kenrith, the Returned King #113 (real):0[9]` turn `4` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed7_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_core_challenge_dance_over_storm:Winota, Joiner of Forces #39 (real):0[34]` turn `14` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed20260625_v1_library_pressure_v1.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brainstone_topdeck_miracle_cut_squelcher:Winota, Joiner of Forces #39 (real):0[7]` turn `7` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed20260625_v1_library_pressure_v1.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brainstone_topdeck_miracle_cut_squelcher:Winota, Joiner of Forces #39 (real):2[8]` turn `16` effect `land` metric ``

### Furygale Flocking

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg091_token_maker_family_focused_events_20260623_093259.jsonl` path `line:2` turn `9` effect `token_maker` metric ``
- `tokens_created` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg091_token_maker_family_focused_events_20260623_093259.jsonl` path `line:3` turn `9` effect `token_maker` metric ``
- `static_cost_reduction_saved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[1].telemetry.top_cards[10]` turn `` effect `` metric `static_cost_reduction_saved:Furygale Flocking`
- `static_cost_reduction_on` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[1].telemetry.top_cards[9]` turn `` effect `` metric `static_cost_reduction_on:Furygale Flocking`
- `static_cost_reduction_saved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3_partial.json` path `results[1].telemetry.top_cards[10]` turn `` effect `` metric `static_cost_reduction_saved:Furygale Flocking`
- `static_cost_reduction_on` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3_partial.json` path `results[1].telemetry.top_cards[9]` turn `` effect `` metric `static_cost_reduction_on:Furygale Flocking`
- `static_cost_reduction_on` from `docs/hermes-analysis/master_optimizer_reports/lorehold_chaos_warp_stroke_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.top_cards[2]` turn `` effect `` metric `static_cost_reduction_on:Furygale Flocking`
- `static_cost_reduction_saved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_chaos_warp_stroke_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.top_cards[3]` turn `` effect `` metric `static_cost_reduction_saved:Furygale Flocking`

### Generous Gift

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg089_l6_removal_compensation_focused_events_20260623_062000.jsonl` path `line:2` turn `5` effect `remove_permanent` metric ``
- `removal_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg089_l6_removal_compensation_focused_events_20260623_062000.jsonl` path `line:3` turn `5` effect `` metric ``
- `compensation_tokens_created` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg089_l6_removal_compensation_focused_events_20260623_062000.jsonl` path `line:4` turn `5` effect `` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed20260630_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_enlightened_tutor_insurrection_v1:Kraum, Ludevic's Opus #81 (real):2[97]` turn `18` effect `remove_permanent` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed20260630_real8_games3_partial.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_enlightened_tutor_insurrection_v1:Kraum, Ludevic's Opus #81 (real):2[97]` turn `18` effect `remove_permanent` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed42_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[8]` turn `` effect `` metric `cost_paid:Generous Gift`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_access_density_control_v1_access_density_control_forced_tutors_pipe_opening_gate.json` path `results[1].telemetry.focus_card_game_traces.challenger_lorehold_access_density_control_v1:Winota, Joiner of Forces #39 (real):0[26]` turn `4` effect `remove_permanent` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_access_density_control_v1_access_density_control_forced_tutors_pipe_opening_gate_partial.json` path `results[1].telemetry.focus_card_game_traces.challenger_lorehold_access_density_control_v1:Winota, Joiner of Forces #39 (real):0[26]` turn `4` effect `remove_permanent` metric ``

### Giver of Runes

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg076_support_passive_annotation_focused_events_20260623_054358.jsonl` path `line:2` turn `6` effect `creature` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[7]` turn `` effect `` metric `cost_paid:Giver of Runes`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[9]` turn `` effect `` metric `cost_paid:Giver of Runes`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_austere_emeria_tradeoff_gate_20260627_v1_20260627_232955.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[9]` turn `` effect `` metric `cost_paid:Giver of Runes`
- `cast_announced` from `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seed42/battle_forensic_seed_42.jsonl` path `line:798` turn `12` effect `creature` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seed42/battle_forensic_seed_42.jsonl` path `line:799` turn `12` effect `creature` metric ``
- `creature_cast` from `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seed42/battle_forensic_seed_42.jsonl` path `line:800` turn `12` effect `creature` metric ``
- `cast_announced` from `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seeds42_44/battle_forensic_seed_42.jsonl` path `line:798` turn `12` effect `creature` metric ``

### Glittering Massif

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):0[18]` turn `16` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[18]` turn `16` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):0[18]` turn `16` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[18]` turn `16` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):0[18]` turn `16` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[18]` turn `16` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_silence_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):0[18]` turn `16` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_silence_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[18]` turn `16` effect `land` metric ``

### Hexing Squelcher

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg087_remaining_semantic_focused_events_20260623_085349.jsonl` path `line:2` turn `8` effect `creature` metric ``
- `creature_to_battlefield` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg087_remaining_semantic_focused_events_20260623_085349.jsonl` path `line:3` turn `8` effect `` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg088_remaining_semantic_focused_events_20260623_090018.jsonl` path `line:5` turn `4` effect `creature` metric ``
- `creature_to_battlefield` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg088_remaining_semantic_focused_events_20260623_090018.jsonl` path `line:6` turn `4` effect `` metric ``
- `creature_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_42.jsonl` path `line:59` turn `3` effect `creature` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[1].gate_summary.candidate.telemetry.top_cards[11]` turn `` effect `` metric `cost_paid:Hexing Squelcher`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_austere_emeria_tradeoff_gate_20260627_v1_20260627_232955.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[4]` turn `` effect `` metric `cost_paid:Hexing Squelcher`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[5]` turn `` effect `` metric `cost_paid:Hexing Squelcher`

### High Noon

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/high_noon_pg096_focused_events_20260623_112650.jsonl` path `line:2` turn `4` effect `passive` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[7]` turn `` effect `` metric `cost_paid:High Noon`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[7]` turn `` effect `` metric `cost_paid:High Noon`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[7]` turn `` effect `` metric `cost_paid:High Noon`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_silence_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[7]` turn `` effect `` metric `cost_paid:High Noon`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_austere_emeria_tradeoff_gate_20260627_v1_20260627_232955.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[7]` turn `` effect `` metric `cost_paid:High Noon`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_equal_battle_gate_20260629_artifact_contract_smoke_v1.json` path `results[0].telemetry.top_cards[10]` turn `` effect `` metric `cost_paid:High Noon`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_exposure_by_game_gate_20260628_v1_20260628_101737.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[10]` turn `` effect `` metric `cost_paid:High Noon`

### Hit the Mother Lode

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `turn_end` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed42_hash0_isolated_timeout_storm_challenge.json` path `packages[1].gate_summary.candidate.telemetry.squee_game_traces.synergy_core_challenge_aetherflux_over_storm:Sisay, Weatherlight Captain #61 (real):1[1]` turn `4` effect `` metric ``
- `turn_end` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed42_hash0_isolated_timeout_storm_challenge.json` path `packages[1].gate_summary.candidate.telemetry.squee_trace_samples[1]` turn `4` effect `` metric ``
- `miracle` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed7_v1_library_pressure_v1.json` path `packages[1].gate_summary.candidate.telemetry.top_cards[4]` turn `` effect `` metric `miracle:Hit the Mother Lode`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_vault_gate_20260628_v1_20260628_092000.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[11]` turn `` effect `` metric `cost_paid:Hit the Mother Lode`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_one_ring_gate_20260630_creative_technique_seed20260630_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_one_ring_creative_technique_v1:Winota, Joiner of Forces #73 (real):1[120]` turn `19` effect `composite_resolution` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_one_ring_gate_20260630_creative_technique_seed20260630_real8_games3_partial.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_one_ring_creative_technique_v1:Winota, Joiner of Forces #73 (real):1[120]` turn `19` effect `composite_resolution` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_one_ring_gate_20260630_redirect_lightning_seed20260630_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_one_ring_redirect_lightning_v1:Rograkh, Son of Rohgahh #95 (real):1[152]` turn `18` effect `composite_resolution` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_one_ring_gate_20260630_redirect_lightning_seed20260630_real8_games3_partial.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_one_ring_redirect_lightning_v1:Rograkh, Son of Rohgahh #95 (real):1[152]` turn `18` effect `composite_resolution` metric ``

### Improvisation Capstone

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_hidden_retreat_synergy_gate_20260628_v2_20260628_071000.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[2]` turn `` effect `` metric `cost_paid:Improvisation Capstone`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1.json` path `packages[2].gate_summary.candidate.telemetry.top_cards[10]` turn `` effect `` metric `cost_paid:Improvisation Capstone`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_one_ring_gate_20260630_creative_technique_seed123_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Thrasios, Triton Hero #101 (real):1[55]` turn `8` effect `exile_value` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_one_ring_gate_20260630_creative_technique_seed123_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_one_ring_creative_technique_v1:Kinnan, Bonder Prodigy #72 (real):2[44]` turn `8` effect `exile_value` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_one_ring_gate_20260630_creative_technique_seed123_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_one_ring_creative_technique_v1:Thrasios, Triton Hero #101 (real):0[101]` turn `13` effect `exile_value` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_one_ring_gate_20260630_creative_technique_seed123_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_one_ring_creative_technique_v1:Winota, Joiner of Forces #73 (real):2[33]` turn `6` effect `exile_value` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_one_ring_gate_20260630_creative_technique_seed123_real8_games3_partial.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Thrasios, Triton Hero #101 (real):1[55]` turn `8` effect `exile_value` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_one_ring_gate_20260630_creative_technique_seed123_real8_games3_partial.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_one_ring_creative_technique_v1:Kinnan, Bonder Prodigy #72 (real):2[44]` turn `8` effect `exile_value` metric ``

### Insurrection

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg093_insurrection_focused_events_20260623_100709.jsonl` path `line:3` turn `6` effect `steal_all_creatures` metric ``
- `steal_all_creatures_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg093_insurrection_focused_events_20260623_100709.jsonl` path `line:4` turn `6` effect `` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg093_insurrection_focused_events_current_20260623_101800.jsonl` path `line:3` turn `6` effect `steal_all_creatures` metric ``
- `steal_all_creatures_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg093_insurrection_focused_events_current_20260623_101800.jsonl` path `line:4` turn `6` effect `` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_creative_technique_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:K-9, Mark I #34 (real):2[88]` turn `13` effect `steal_all_creatures` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_creative_technique_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kraum, Ludevic's Opus #81 (real):0[111]` turn `19` effect `steal_all_creatures` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_creative_technique_seed20260630_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_enlightened_tutor_creative_technique_v1:Thrasios, Triton Hero #101 (real):2[83]` turn `10` effect `steal_all_creatures` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_creative_technique_seed20260630_real8_games3_partial.json` path `results[0].telemetry.focus_card_game_traces.deck_607:K-9, Mark I #34 (real):2[88]` turn `13` effect `steal_all_creatures` metric ``

### Jeska's Will

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_l4_battle_support_focused_events_20260623_062422.jsonl` path `line:3` turn `5` effect `ramp_ritual` metric ``
- `jeskas_will_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_l4_battle_support_focused_events_20260623_062422.jsonl` path `line:4` turn `5` effect `` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_runtime_events_20260623_062156.jsonl` path `line:1` turn `5` effect `ramp_ritual` metric ``
- `jeskas_will_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_runtime_events_20260623_062156.jsonl` path `line:2` turn `5` effect `` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_923.jsonl` path `line:100` turn `6` effect `ramp_ritual` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_923.jsonl` path `line:36` turn `3` effect `ramp_ritual` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_equal_battle_gate_20260629_artifact_contract_smoke_v1.json` path `results[0].telemetry.top_cards[7]` turn `` effect `` metric `cost_paid:Jeska's Will`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed20260625_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[10]` turn `` effect `` metric `cost_paid:Jeska's Will`

### Land Tax

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_923.jsonl` path `line:171` turn `9` effect `tutor` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_923.jsonl` path `line:172` turn `9` effect `tutor` metric ``
- `tutor_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_923.jsonl` path `line:173` turn `9` effect `` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/land_tax_pg033_focused_events_20260622_201417.jsonl` path `line:1` turn `2` effect `land_tax` metric ``
- `land_tax_trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/land_tax_pg033_focused_events_20260622_201417.jsonl` path `line:2` turn `3` effect `` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[6]` turn `` effect `` metric `cost_paid:Land Tax`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[6]` turn `` effect `` metric `cost_paid:Land Tax`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[6]` turn `` effect `` metric `cost_paid:Land Tax`

### Library of Leng

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `runtime_rule_loaded` from `docs/hermes-analysis/master_optimizer_reports/deck6_606_pg082_hash_only_focused_events_20260623_083100.jsonl` path `line:1` turn `` effect `passive` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[5]` turn `` effect `` metric `cost_paid:Library of Leng`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Etali, Primal Conqueror #67 (real):0[11]` turn `2` effect `passive` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Etali, Primal Conqueror #67 (real):1[78]` turn `14` effect `passive` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kinnan, Bonder Prodigy #57 (real):0[4]` turn `1` effect `passive` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Lumra, Bellow of the Woods #49 (real):0[4]` turn `1` effect `passive` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Lumra, Bellow of the Woods #49 (real):1[37]` turn `7` effect `passive` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Thrasios, Triton Hero #77 (real):2[16]` turn `3` effect `passive` metric ``

### Lightning Greaves

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_42.jsonl` path `line:5` turn `1` effect `equipment_haste_shroud` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_42.jsonl` path `line:6` turn `1` effect `equipment_haste_shroud` metric ``
- `equipment_unattached` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_42.jsonl` path `line:7` turn `1` effect `` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/lightning_greaves_pg034_focused_events_20260622_202908.jsonl` path `line:1` turn `3` effect `equipment_haste_shroud` metric ``
- `equipment_attached` from `docs/hermes-analysis/master_optimizer_reports/lightning_greaves_pg034_focused_events_20260622_202908.jsonl` path `line:2` turn `3` effect `` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[8]` turn `` effect `` metric `cost_paid:Lightning Greaves`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[1].gate_summary.candidate.telemetry.top_cards[4]` turn `` effect `` metric `cost_paid:Lightning Greaves`
- `cast_announced` from `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seed42/battle_forensic_seed_42.jsonl` path `line:11` turn `1` effect `equipment_haste_shroud` metric ``

### Lorehold, the Historian

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `equipment_attached` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg078_l2_hash_scope_restore_focused_events_20260623_063535.jsonl` path `line:17` turn `4` effect `equipment_static_attachment` metric ``
- `commander_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_42.jsonl` path `line:47` turn `3` effect `commander` metric ``
- `commander_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_923.jsonl` path `line:170` turn `9` effect `commander` metric ``
- `commander_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_923.jsonl` path `line:54` turn `4` effect `commander` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[0]` turn `` effect `` metric `cost_paid:Lorehold, the Historian`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[0]` turn `` effect `` metric `cost_paid:Lorehold, the Historian`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[0]` turn `` effect `` metric `cost_paid:Lorehold, the Historian`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_silence_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[0]` turn `` effect `` metric `cost_paid:Lorehold, the Historian`

### Marsh Flats

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_923.jsonl` path `line:3` turn `1` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_923.jsonl` path `line:8` turn `1` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Umbris, Fear Manifest #114 (real):1[42]` turn `11` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed42_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Winota, Joiner of Forces #39 (real):0[15]` turn `8` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_leng_telemetry_gate_20260627_seed42_squee_v1.json` path `results[0].telemetry.squee_game_traces.deck_6:Winota, Joiner of Forces #39 (real):0[15]` turn `8` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed20260625_v1_library_pressure_v1.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brainstone_topdeck_miracle_cut_squelcher:Winota, Joiner of Forces #39 (real):0[31]` turn `12` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Winota, Joiner of Forces #39 (real):0[15]` turn `8` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brainstone_topdeck_miracle_cut_squelcher:Vivi Ornitier #99 (real):2[12]` turn `6` effect `land` metric ``

### Mizzix's Mastery

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `mizzix_mastery_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_l4_battle_support_focused_events_20260623_062422.jsonl` path `line:11` turn `6` effect `` metric ``
- `self_exiled_on_resolution` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_l4_battle_support_focused_events_20260623_062422.jsonl` path `line:12` turn `6` effect `` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_l4_battle_support_focused_events_20260623_062422.jsonl` path `line:6` turn `6` effect `overload_recursion` metric ``
- `mizzix_mastery_copy_cast` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_l4_battle_support_focused_events_20260623_062422.jsonl` path `line:7` turn `6` effect `` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_runtime_events_20260623_062156.jsonl` path `line:3` turn `6` effect `overload_recursion` metric ``
- `mizzix_mastery_copy_cast` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_runtime_events_20260623_062156.jsonl` path `line:4` turn `6` effect `` metric ``
- `mizzix_mastery_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_runtime_events_20260623_062156.jsonl` path `line:5` turn `6` effect `` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_42.jsonl` path `line:88` turn `5` effect `overload_recursion` metric ``

### Molecule Man

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_chaos_warp_stroke_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:K-9, Mark I #34 (real):2[51]` turn `7` effect `passive` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_chaos_warp_stroke_gate_20260630_seed20260630_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_chaos_warp_stroke_of_midnight_v1:K-9, Mark I #34 (real):2[64]` turn `12` effect `passive` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_deflecting_palm_redirect_lightning_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:K-9, Mark I #34 (real):2[51]` turn `7` effect `passive` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_deflecting_palm_redirect_lightning_gate_20260630_seed20260630_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_deflecting_palm_redirect_lightning_v1:Thrasios, Triton Hero #101 (real):1[103]` turn `16` effect `passive` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_electro_waterskin_gate_20260630_fixed_20260630_042339_electro_assaulting_battery_same_lane_benchmark_cut_bender_s_waterskin.json` path `results[0].telemetry.focus_card_game_traces.deck_607:K-9, Mark I #34 (real):2[51]` turn `7` effect `passive` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_creative_technique_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:K-9, Mark I #34 (real):2[51]` turn `7` effect `passive` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_creative_technique_seed20260630_real8_games3_partial.json` path `results[0].telemetry.focus_card_game_traces.deck_607:K-9, Mark I #34 (real):2[51]` turn `7` effect `passive` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:K-9, Mark I #34 (real):2[51]` turn `7` effect `passive` metric ``

### Monument to Endurance

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[6]` turn `` effect `` metric `cost_paid:Monument to Endurance`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[1].gate_summary.candidate.telemetry.top_cards[1]` turn `` effect `` metric `cost_paid:Monument to Endurance`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_silence_fixed.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[4]` turn `` effect `` metric `cost_paid:Monument to Endurance`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_austere_emeria_tradeoff_gate_20260627_v1_20260627_232955.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[3]` turn `` effect `` metric `cost_paid:Monument to Endurance`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[4]` turn `` effect `` metric `cost_paid:Monument to Endurance`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_equal_battle_gate_20260629_artifact_contract_smoke_v1.json` path `results[0].telemetry.top_cards[9]` turn `` effect `` metric `cost_paid:Monument to Endurance`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed20260625_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[4]` turn `` effect `` metric `cost_paid:Monument to Endurance`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed42_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[11]` turn `` effect `` metric `cost_paid:Monument to Endurance`

### Mother of Runes

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg076_support_passive_annotation_focused_events_20260623_054358.jsonl` path `line:3` turn `6` effect `creature` metric ``
- `creature_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_42.jsonl` path `line:178` turn `10` effect `creature` metric ``
- `creature_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_923.jsonl` path `line:209` turn `11` effect `creature` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[2].gate_summary.candidate.telemetry.top_cards[8]` turn `` effect `` metric `cost_paid:Mother of Runes`
- `cast_announced` from `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seed42/battle_forensic_seed_42.jsonl` path `line:567` turn `8` effect `creature` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seed42/battle_forensic_seed_42.jsonl` path `line:568` turn `8` effect `creature` metric ``
- `creature_cast` from `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seed42/battle_forensic_seed_42.jsonl` path `line:569` turn `8` effect `creature` metric ``
- `cast_announced` from `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seeds42_44/battle_forensic_seed_42.jsonl` path `line:567` turn `8` effect `creature` metric ``

### Mountain // Mountain

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `land_tax_trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kinnan, Bonder Prodigy #84 (real):1[46]` turn `8` effect `` metric ``
- `land_tax_trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Tivit, Seller of Secrets #108 (real):0[38]` turn `7` effect `` metric ``
- `land_tax_trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_boros_charm_tibalts_trickery_v1:Kinnan, Bonder Prodigy #57 (real):1[29]` turn `5` effect `` metric ``
- `land_tax_trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_boros_charm_tibalts_trickery_v1:Kinnan, Bonder Prodigy #57 (real):1[35]` turn `6` effect `` metric ``
- `land_tax_trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_boros_charm_tibalts_trickery_v1:Kinnan, Bonder Prodigy #84 (real):0[21]` turn `4` effect `` metric ``
- `land_tax_trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_boros_charm_tibalts_trickery_v1:Rograkh, Son of Rohgahh #119 (real):0[34]` turn `7` effect `` metric ``
- `land_tax_trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3_partial.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kinnan, Bonder Prodigy #84 (real):1[46]` turn `8` effect `` metric ``
- `land_tax_trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3_partial.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Tivit, Seller of Secrets #108 (real):0[38]` turn `7` effect `` metric ``

### Path to Exile

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `miracle_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_42.jsonl` path `line:145` turn `8` effect `remove_creature` metric ``
- `spell_countered` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_42.jsonl` path `line:146` turn `8` effect `` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[5]` turn `` effect `` metric `cost_paid:Path to Exile`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[5]` turn `` effect `` metric `cost_paid:Path to Exile`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[5]` turn `` effect `` metric `cost_paid:Path to Exile`
- `miracle` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[1].gate_summary.candidate.telemetry.top_cards[7]` turn `` effect `` metric `miracle:Path to Exile`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_silence_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[5]` turn `` effect `` metric `cost_paid:Path to Exile`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_austere_emeria_tradeoff_gate_20260627_v1_20260627_232955.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[5]` turn `` effect `` metric `cost_paid:Path to Exile`

### Pearl Medallion

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[11]` turn `` effect `` metric `cost_paid:Pearl Medallion`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[11]` turn `` effect `` metric `cost_paid:Pearl Medallion`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_silence_fixed.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[6]` turn `` effect `` metric `cost_paid:Pearl Medallion`
- `static_cost_reduction_saved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.top_cards[5]` turn `` effect `` metric `static_cost_reduction_saved:Pearl Medallion`
- `static_cost_reduction_source_cast` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.top_cards[6]` turn `` effect `` metric `static_cost_reduction_source_cast:Pearl Medallion`
- `static_cost_reduction_saved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3_partial.json` path `results[0].telemetry.top_cards[5]` turn `` effect `` metric `static_cost_reduction_saved:Pearl Medallion`
- `static_cost_reduction_source_cast` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3_partial.json` path `results[0].telemetry.top_cards[6]` turn `` effect `` metric `static_cost_reduction_source_cast:Pearl Medallion`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[11]` turn `` effect `` metric `cost_paid:Pearl Medallion`

### Pinnacle Monk // Mystic Peak

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_607_608_pg080_pg081_focused_events_20260623_082229.jsonl` path `line:5` turn `5` effect `creature` metric ``
- `etb_recursion_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_607_608_pg080_pg081_focused_events_20260623_082229.jsonl` path `line:6` turn `5` effect `` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_past_in_flames_pinnacle_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kraum, Ludevic's Opus #81 (real):1[85]` turn `14` effect `creature` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_past_in_flames_pinnacle_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Rograkh, Son of Rohgahh #95 (real):2[41]` turn `8` effect `creature` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_past_in_flames_pinnacle_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Thrasios, Triton Hero #101 (real):1[69]` turn `11` effect `creature` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_past_in_flames_pinnacle_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Thrasios, Triton Hero #76 (real):2[49]` turn `8` effect `creature` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_past_in_flames_pinnacle_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Winota, Joiner of Forces #73 (real):1[77]` turn `11` effect `creature` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed20260625_v1.json` path `results[1].telemetry.top_cards[10]` turn `` effect `` metric `cost_paid:Pinnacle Monk // Mystic Peak`

### Plains // Plains

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[2].gate_summary.candidate.telemetry.squee_game_traces.synergy_reprieve_cut_avatar_wrath:Winota, Joiner of Forces #39 (real):0[12]` turn `5` effect `land` metric ``
- `land_tax_trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_boros_charm_tibalts_trickery_v1:Kinnan, Bonder Prodigy #57 (real):1[44]` turn `7` effect `` metric ``
- `land_tax_trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_boros_charm_tibalts_trickery_v1:Kinnan, Bonder Prodigy #84 (real):0[27]` turn `5` effect `` metric ``
- `land_tax_trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_boros_charm_tibalts_trickery_v1:Kinnan, Bonder Prodigy #84 (real):0[38]` turn `6` effect `` metric ``
- `land_tax_trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3_partial.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_boros_charm_tibalts_trickery_v1:Kinnan, Bonder Prodigy #57 (real):1[44]` turn `7` effect `` metric ``
- `land_tax_trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3_partial.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_boros_charm_tibalts_trickery_v1:Kinnan, Bonder Prodigy #84 (real):0[27]` turn `5` effect `` metric ``
- `land_tax_trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3_partial.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_boros_charm_tibalts_trickery_v1:Kinnan, Bonder Prodigy #84 (real):0[38]` turn `6` effect `` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Aang, at the Crossroads #106 (real):1[11]` turn `12` effect `land` metric ``

### Plaza of Heroes

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Kenrith, the Returned King #113 (real):0[43]` turn `11` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Kenrith, the Returned King #113 (real):0[43]` turn `11` effect `land` metric ``
- `turn_end` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed20260625_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_core_challenge_dance_over_storm:Vivi Ornitier #99 (real):2[5]` turn `19` effect `` metric ``
- `turn_end` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed20260625_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.candidate.telemetry.squee_trace_samples[5]` turn `19` effect `` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1.json` path `packages[1].gate_summary.candidate.telemetry.squee_game_traces.synergy_ghostly_prison_pressure_cut_squelcher:Vivi Ornitier #99 (real):0[18]` turn `16` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1.json` path `packages[1].gate_summary.candidate.telemetry.squee_trace_samples[18]` turn `16` effect `land` metric ``
- `turn_end` from `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_turbulent_gate_20260627_v1_real.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_plateau_timing_upgrade_cut_turbulent_steppe:Sisay, Weatherlight Captain #61 (real):0[15]` turn `5` effect `` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_post_squee_package_gate_20260627_v1_seed20260625_hash0_isolated_timeout.json` path `packages[1].gate_summary.candidate.telemetry.squee_game_traces.synergy_faithless_looting_squee_enabler:Vivi Ornitier #99 (real):2[15]` turn `23` effect `land` metric ``

### Prismari Pianist

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg091_token_maker_family_focused_events_20260623_093259.jsonl` path `line:6` turn `9` effect `token_maker` metric ``
- `trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg091_token_maker_family_focused_events_20260623_093259.jsonl` path `line:7` turn `9` effect `token_maker` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[1].gate_summary.candidate.telemetry.top_cards[5]` turn `` effect `` metric `cost_paid:Prismari Pianist`
- `trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_deflecting_palm_redirect_lightning_gate_20260630_seed20260630_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_deflecting_palm_redirect_lightning_v1:Winota, Joiner of Forces #73 (real):0[20]` turn `4` effect `token_maker` metric ``
- `trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_creative_technique_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Winota, Joiner of Forces #73 (real):0[40]` turn `6` effect `token_maker` metric ``
- `trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_creative_technique_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Winota, Joiner of Forces #73 (real):0[41]` turn `6` effect `token_maker` metric ``
- `trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_creative_technique_seed20260630_real8_games3_partial.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Winota, Joiner of Forces #73 (real):0[40]` turn `6` effect `token_maker` metric ``
- `trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_creative_technique_seed20260630_real8_games3_partial.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Winota, Joiner of Forces #73 (real):0[41]` turn `6` effect `token_maker` metric ``

### Prismatic Vista

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Rograkh, Son of Rohgahh #62 (real):1[22]` turn `10` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Tannuk, Memorial Ensign #40 (real):1[12]` turn `9` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Umbris, Fear Manifest #114 (real):1[36]` turn `9` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Winota, Joiner of Forces #39 (real):0[22]` turn `21` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Rograkh, Son of Rohgahh #62 (real):1[21]` turn `11` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Winota, Joiner of Forces #39 (real):0[22]` turn `21` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed7_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_core_challenge_dance_over_storm:Winota, Joiner of Forces #39 (real):0[45]` turn `16` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_life_floor_conversion_gate_20260627_seed20260625_v1_life_floor_v1.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_angel_grace_life_floor_cut_dawn:Sisay, Weatherlight Captain #61 (real):0[9]` turn `17` effect `land` metric ``

### Promise of Loyalty

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `permanent_moved_from_battlefield` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Rograkh, Son of Rohgahh #62 (real):1[13]` turn `7` effect `` metric ``
- `board_wipe_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Rograkh, Son of Rohgahh #62 (real):1[14]` turn `7` effect `` metric ``
- `permanent_moved_from_battlefield` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Tannuk, Memorial Ensign #40 (real):1[23]` turn `11` effect `` metric ``
- `board_wipe_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Tannuk, Memorial Ensign #40 (real):1[24]` turn `11` effect `` metric ``
- `permanent_moved_from_battlefield` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Vivi Ornitier #99 (real):2[17]` turn `5` effect `` metric ``
- `board_wipe_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Vivi Ornitier #99 (real):2[18]` turn `5` effect `` metric ``
- `permanent_moved_from_battlefield` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_trace_samples[17]` turn `5` effect `` metric ``
- `board_wipe_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_trace_samples[18]` turn `5` effect `` metric ``

### Radiant Summit

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brainstone_topdeck_miracle_cut_squelcher:Sisay, Weatherlight Captain #61 (real):2[14]` turn `6` effect `land` metric ``
- `turn_end` from `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_turbulent_gate_20260627_v1_real.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_plateau_timing_upgrade_cut_turbulent_steppe:Sisay, Weatherlight Captain #61 (real):0[10]` turn `4` effect `` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_post_squee_package_gate_20260627_v1_seed20260625_hash0_isolated_timeout.json` path `packages[2].gate_summary.candidate.telemetry.squee_game_traces.synergy_galvanoth_topdeck_freecast:Sisay, Weatherlight Captain #61 (real):1[18]` turn `27` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_post_squee_package_gate_20260627_v1_seed20260625_hash0_isolated_timeout.json` path `packages[2].gate_summary.candidate.telemetry.squee_game_traces.synergy_galvanoth_topdeck_freecast:Winota, Joiner of Forces #39 (real):1[10]` turn `9` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_topfreecast_conversion_gate_20260627_seed42_v1_topfreecast_v1.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_primal_amulet_spell_engine:Sisay, Weatherlight Captain #61 (real):2[21]` turn `10` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_topfreecast_conversion_gate_20260627_seed42_v2_topfreecast_v2.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_galvanoth_topdeck_freecast_cut_thor:Vivi Ornitier #99 (real):2[60]` turn `16` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_access_conversion_gate_20260627_seed42_v2_gamble_tutor_access_v2.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_gamble_access_cut_thor:Vivi Ornitier #99 (real):2[60]` turn `16` effect `land` metric ``

### Redirect Lightning

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `redirect_removal_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_607_608_pg080_pg081_focused_events_20260623_082229.jsonl` path `line:7` turn `4` effect `` metric ``
- `lorehold_rummage_to_top` from `docs/hermes-analysis/master_optimizer_reports/lorehold_exposure_by_game_gate_20260628_v1_20260628_101737.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[1]` turn `` effect `` metric `lorehold_rummage_to_top:Redirect Lightning`
- `discard_to_top` from `docs/hermes-analysis/master_optimizer_reports/lorehold_exposure_by_game_gate_20260628_v1_20260628_101737.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[2]` turn `` effect `` metric `discard_to_top:Redirect Lightning`
- `lorehold_rummage_to_top` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed20260625_v1_library_pressure_v1.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[5]` turn `` effect `` metric `lorehold_rummage_to_top:Redirect Lightning`
- `discard_to_top` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed20260625_v1_library_pressure_v1.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[6]` turn `` effect `` metric `discard_to_top:Redirect Lightning`
- `lorehold_rummage_to_top` from `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_vault_exposure_gate_20260628_v1_20260628_111500.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[1]` turn `` effect `` metric `lorehold_rummage_to_top:Redirect Lightning`
- `discard_to_top` from `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_vault_exposure_gate_20260628_v1_20260628_111500.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[2]` turn `` effect `` metric `discard_to_top:Redirect Lightning`
- `lorehold_rummage_to_top` from `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_vault_gate_after_ramp_runtime_fix_20260628_v1_20260628_102000.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[1]` turn `` effect `` metric `lorehold_rummage_to_top:Redirect Lightning`

### Reforge the Soul

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_high_battle_critical_focused_events_20260623_075434.jsonl` path `line:4` turn `5` effect `draw_cards` metric ``
- `wheel_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_high_battle_critical_focused_events_20260623_075434.jsonl` path `line:5` turn `5` effect `` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_runtime_semantics_focused_events_20260623_045814.jsonl` path `line:7` turn `5` effect `draw_cards` metric ``
- `wheel_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_runtime_semantics_focused_events_20260623_045814.jsonl` path `line:8` turn `5` effect `` metric ``
- `lorehold_rummage_to_top` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[2]` turn `` effect `` metric `lorehold_rummage_to_top:Reforge the Soul`
- `discard_to_top` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[3]` turn `` effect `` metric `discard_to_top:Reforge the Soul`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_creative_technique_seed20260630_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_enlightened_tutor_creative_technique_v1:Kraum, Ludevic's Opus #81 (real):1[73]` turn `12` effect `draw_cards` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_creative_technique_seed20260630_real8_games3_partial.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_enlightened_tutor_creative_technique_v1:Kraum, Ludevic's Opus #81 (real):1[73]` turn `12` effect `draw_cards` metric ``

### Reliquary Tower

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Winota, Joiner of Forces #39 (real):0[39]` turn `26` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Winota, Joiner of Forces #39 (real):0[39]` turn `26` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed42_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Winota, Joiner of Forces #39 (real):1[25]` turn `11` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed7_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_core_challenge_dance_over_storm:Winota, Joiner of Forces #39 (real):0[30]` turn `13` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_leng_telemetry_gate_20260627_seed42_squee_v1.json` path `results[0].telemetry.squee_game_traces.deck_6:Winota, Joiner of Forces #39 (real):1[25]` turn `11` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Winota, Joiner of Forces #39 (real):1[25]` turn `11` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1.json` path `packages[1].gate_summary.candidate.telemetry.squee_game_traces.synergy_ghostly_prison_pressure_cut_squelcher:Sisay, Weatherlight Captain #61 (real):1[24]` turn `11` effect `land` metric ``
- `turn_end` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1.json` path `packages[2].gate_summary.candidate.telemetry.squee_game_traces.synergy_one_ring_protection_draw_cut_squelcher:Sisay, Weatherlight Captain #61 (real):1[2]` turn `6` effect `` metric ``

### Rise of the Eldrazi

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `composite_rule_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_high_battle_critical_focused_events_20260623_075434.jsonl` path `line:11` turn `9` effect `` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_high_battle_critical_focused_events_20260623_075434.jsonl` path `line:6` turn `9` effect `composite_resolution` metric ``
- `removal_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_high_battle_critical_focused_events_20260623_075434.jsonl` path `line:7` turn `9` effect `` metric ``
- `composite_rule_component_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_high_battle_critical_focused_events_20260623_075434.jsonl` path `line:8` turn `9` effect `` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_runtime_semantics_focused_events_20260623_045814.jsonl` path `line:10` turn `9` effect `composite_resolution` metric ``
- `removal_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_runtime_semantics_focused_events_20260623_045814.jsonl` path `line:11` turn `9` effect `` metric ``
- `composite_rule_component_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_runtime_semantics_focused_events_20260623_045814.jsonl` path `line:12` turn `9` effect `` metric ``
- `composite_rule_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_runtime_semantics_focused_events_20260623_045814.jsonl` path `line:15` turn `9` effect `` metric ``

### Ruby Medallion

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg071_l3_fast_mana_runtime_focused_events_20260623_043623.jsonl` path `line:3` turn `3` effect `passive` metric ``
- `focused_state_assertion` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg071_l3_fast_mana_runtime_focused_events_20260623_043623.jsonl` path `line:4` turn `` effect `` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_silence_fixed.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[2]` turn `` effect `` metric `cost_paid:Ruby Medallion`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_austere_emeria_tradeoff_gate_20260627_v1_20260627_232955.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[10]` turn `` effect `` metric `cost_paid:Ruby Medallion`
- `static_cost_reduction_saved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.top_cards[2]` turn `` effect `` metric `static_cost_reduction_saved:Ruby Medallion`
- `static_cost_reduction_source_cast` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.top_cards[3]` turn `` effect `` metric `static_cost_reduction_source_cast:Ruby Medallion`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.top_cards[9]` turn `` effect `` metric `cost_paid:Ruby Medallion`
- `static_cost_reduction_saved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3_partial.json` path `results[0].telemetry.top_cards[2]` turn `` effect `` metric `static_cost_reduction_saved:Ruby Medallion`

### Sacred Foundry

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/deck6_l1b_nonfetch_land_mana_pg051_focused_events_20260623_012230.jsonl` path `line:14` turn `1` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Aang, at the Crossroads #106 (real):1[3]` turn `10` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed42_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Winota, Joiner of Forces #39 (real):0[74]` turn `21` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed42_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Winota, Joiner of Forces #39 (real):1[13]` turn `9` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_leng_telemetry_gate_20260627_seed42_squee_v1.json` path `results[0].telemetry.squee_game_traces.deck_6:Winota, Joiner of Forces #39 (real):0[74]` turn `21` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_leng_telemetry_gate_20260627_seed42_squee_v1.json` path `results[0].telemetry.squee_game_traces.deck_6:Winota, Joiner of Forces #39 (real):1[13]` turn `9` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Winota, Joiner of Forces #39 (real):0[74]` turn `21` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Winota, Joiner of Forces #39 (real):1[13]` turn `9` effect `land` metric ``

### Scalding Tarn

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_42.jsonl` path `line:63` turn `4` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_923.jsonl` path `line:237` turn `12` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seed42/battle_forensic_seed_42.jsonl` path `line:232` turn `4` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seeds42_44/battle_forensic_seed_42.jsonl` path `line:232` turn `4` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):1[12]` turn `14` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[12]` turn `14` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Kenrith, the Returned King #113 (real):0[13]` turn `5` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Kenrith, the Returned King #113 (real):0[13]` turn `5` effect `land` metric ``

### Scroll Rack

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `runtime_rule_loaded` from `docs/hermes-analysis/master_optimizer_reports/deck6_606_pg082_hash_only_focused_events_20260623_083100.jsonl` path `line:2` turn `` effect `topdeck_manipulation` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg070_l2_hash_only_runtime_focused_events_20260623_011859.jsonl` path `line:16` turn `7` effect `topdeck_manipulation` metric ``
- `topdeck_manipulation_activated` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_runtime_events_20260623_062156.jsonl` path `line:10` turn `6` effect `` metric ``
- `topdeck_manipulation_activated` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):0[0]` turn `12` effect `` metric ``
- `topdeck_manipulation_activated` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[0]` turn `12` effect `` metric ``
- `topdeck` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[1]` turn `` effect `` metric `topdeck:Scroll Rack`
- `topdeck_manipulation_activated` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):0[0]` turn `12` effect `` metric ``
- `topdeck_manipulation_activated` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[0]` turn `12` effect `` metric ``

### Sensei's Divining Top

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `topdeck` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[2]` turn `` effect `` metric `topdeck:Sensei's Divining Top`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[3]` turn `` effect `` metric `cost_paid:Sensei's Divining Top`
- `topdeck` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[2]` turn `` effect `` metric `topdeck:Sensei's Divining Top`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[3]` turn `` effect `` metric `cost_paid:Sensei's Divining Top`
- `topdeck` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[2]` turn `` effect `` metric `topdeck:Sensei's Divining Top`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[3]` turn `` effect `` metric `cost_paid:Sensei's Divining Top`
- `topdeck_manipulation_activated` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[2].gate_summary.candidate.telemetry.squee_game_traces.synergy_reprieve_cut_avatar_wrath:Sisay, Weatherlight Captain #61 (real):0[0]` turn `6` effect `` metric ``
- `topdeck_manipulation_activated` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[2].gate_summary.candidate.telemetry.squee_trace_samples[0]` turn `6` effect `` metric ``

### Smothering Tithe

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg066_birgi_smothering_focused_events_20260623_032200.jsonl` path `line:2` turn `6` effect `create_treasure` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[11]` turn `` effect `` metric `cost_paid:Smothering Tithe`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[11]` turn `` effect `` metric `cost_paid:Smothering Tithe`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[11]` turn `` effect `` metric `cost_paid:Smothering Tithe`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_silence_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[11]` turn `` effect `` metric `cost_paid:Smothering Tithe`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_austere_emeria_tradeoff_gate_20260627_v1_20260627_232955.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[11]` turn `` effect `` metric `cost_paid:Smothering Tithe`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[3]` turn `` effect `` metric `cost_paid:Smothering Tithe`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed20260625_hash0_isolated_timeout_storm_challenge.json` path `packages[1].gate_summary.candidate.telemetry.top_cards[3]` turn `` effect `` metric `cost_paid:Smothering Tithe`

### Sol Ring

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `removal_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg078_l2_hash_scope_restore_focused_events_20260623_063535.jsonl` path `line:12` turn `4` effect `` metric ``
- `removal_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_high_battle_critical_focused_events_20260623_075434.jsonl` path `line:17` turn `6` effect `` metric ``
- `etb_removal_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_high_battle_critical_focused_events_20260623_075434.jsonl` path `line:18` turn `6` effect `` metric ``
- `removal_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_runtime_semantics_focused_events_20260623_045814.jsonl` path `line:23` turn `6` effect `` metric ``
- `etb_removal_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_runtime_semantics_focused_events_20260623_045814.jsonl` path `line:24` turn `6` effect `` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_42.jsonl` path `line:4` turn `1` effect `ramp_permanent` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_42.jsonl` path `line:93` turn `5` effect `ramp_permanent` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[10]` turn `` effect `` metric `cost_paid:Sol Ring`

### Spectator Seating

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v5_exposure_smoke_20260627_213725.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Kenrith, the Returned King #113 (real):0[9]` turn `14` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v5_exposure_smoke_20260627_213725.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[9]` turn `14` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1.json` path `packages[1].gate_summary.candidate.telemetry.squee_game_traces.synergy_ghostly_prison_pressure_cut_squelcher:Winota, Joiner of Forces #39 (real):0[6]` turn `8` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_post_squee_package_gate_20260627_v1_seed20260625_hash0_isolated_timeout.json` path `packages[2].gate_summary.candidate.telemetry.squee_game_traces.synergy_galvanoth_topdeck_freecast:Winota, Joiner of Forces #39 (real):1[18]` turn `10` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_post_squee_package_gate_20260627_v1_seed42_hash0_isolated_timeout.json` path `packages[1].gate_summary.candidate.telemetry.squee_game_traces.synergy_faithless_looting_squee_enabler:Vivi Ornitier #99 (real):0[50]` turn `22` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_spellchain_conversion_gate_20260627_seed20260625_v1_spellchain_v1.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_birgi_seething_chain_cut_medallions:Sisay, Weatherlight Captain #61 (real):0[35]` turn `13` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_spellchain_conversion_gate_20260627_seed7_v1_spellchain_v1.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_birgi_seething_chain_cut_medallions:Sisay, Weatherlight Captain #61 (real):1[12]` turn `17` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_spellchain_conversion_gate_20260627_seed7_v1_spellchain_v1.json` path `packages[0].gate_summary.candidate.telemetry.squee_trace_samples[12]` turn `17` effect `land` metric ``

### Starfall Invocation

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `permanent_moved_from_battlefield` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):0[14]` turn `15` effect `` metric ``
- `board_wipe_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):0[15]` turn `15` effect `` metric ``
- `permanent_moved_from_battlefield` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[14]` turn `15` effect `` metric ``
- `board_wipe_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[15]` turn `15` effect `` metric ``
- `permanent_moved_from_battlefield` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):0[14]` turn `15` effect `` metric ``
- `board_wipe_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):0[15]` turn `15` effect `` metric ``
- `permanent_moved_from_battlefield` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[14]` turn `15` effect `` metric ``
- `board_wipe_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[15]` turn `15` effect `` metric ``

### Storm Herd

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_high_battle_critical_focused_events_20260623_075434.jsonl` path `line:14` turn `8` effect `token_maker` metric ``
- `tokens_created` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_high_battle_critical_focused_events_20260623_075434.jsonl` path `line:15` turn `8` effect `token_maker` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_runtime_semantics_focused_events_20260623_045814.jsonl` path `line:17` turn `8` effect `token_maker` metric ``
- `tokens_created` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_runtime_semantics_focused_events_20260623_045814.jsonl` path `line:18` turn `8` effect `token_maker` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_42.jsonl` path `line:124` turn `7` effect `token_maker` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_42.jsonl` path `line:125` turn `7` effect `token_maker` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed123_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kraum, Ludevic's Opus #81 (real):2[62]` turn `9` effect `token_maker` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed123_real8_games3_partial.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kraum, Ludevic's Opus #81 (real):2[62]` turn `9` effect `token_maker` metric ``

### Stroke of Midnight

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg089_l6_removal_compensation_focused_events_20260623_062000.jsonl` path `line:7` turn `5` effect `remove_permanent` metric ``
- `removal_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg089_l6_removal_compensation_focused_events_20260623_062000.jsonl` path `line:8` turn `5` effect `` metric ``
- `compensation_tokens_created` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg089_l6_removal_compensation_focused_events_20260623_062000.jsonl` path `line:9` turn `5` effect `` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_chaos_warp_stroke_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kraum, Ludevic's Opus #81 (real):0[19]` turn `4` effect `remove_permanent` metric ``
- `replacement_applied` from `docs/hermes-analysis/master_optimizer_reports/lorehold_chaos_warp_stroke_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kraum, Ludevic's Opus #81 (real):0[20]` turn `4` effect `` metric ``
- `replacement_applied` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed123_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_enlightened_tutor_insurrection_v1:Kinnan, Bonder Prodigy #72 (real):1[44]` turn `7` effect `` metric ``
- `replacement_applied` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed123_real8_games3_partial.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_enlightened_tutor_insurrection_v1:Kinnan, Bonder Prodigy #72 (real):1[44]` turn `7` effect `` metric ``
- `replacement_applied` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed999_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kraum, Ludevic's Opus #81 (real):2[58]` turn `8` effect `` metric ``

### Sunbaked Canyon

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_42.jsonl` path `line:3` turn `1` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_923.jsonl` path `line:53` turn `4` effect `land` metric ``
- `activated_ability_skipped` from `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seed42/battle_forensic_seed_42.jsonl` path `line:167` turn `3` effect `` metric ``
- `activated_ability_skipped` from `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seed42/battle_forensic_seed_42.jsonl` path `line:256` turn `4` effect `` metric ``
- `activated_ability_skipped` from `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seed42/battle_forensic_seed_42.jsonl` path `line:28` turn `1` effect `` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seed42/battle_forensic_seed_42.jsonl` path `line:3` turn `1` effect `land` metric ``
- `utility_land_activated` from `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seed42/battle_forensic_seed_42.jsonl` path `line:323` turn `5` effect `` metric ``
- `activated_ability_skipped` from `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seed42/battle_forensic_seed_42.jsonl` path `line:99` turn `2` effect `` metric ``

### Sunbillow Verge

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):1[3]` turn `11` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[3]` turn `11` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Kenrith, the Returned King #113 (real):0[23]` turn `7` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Kenrith, the Returned King #113 (real):0[23]` turn `7` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed20260625_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_core_challenge_dance_over_storm:Sisay, Weatherlight Captain #61 (real):1[9]` turn `12` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed20260625_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.candidate.telemetry.squee_trace_samples[19]` turn `12` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed42_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Winota, Joiner of Forces #39 (real):1[18]` turn `10` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed42_hash0_isolated_timeout_storm_challenge.json` path `packages[1].gate_summary.candidate.telemetry.squee_game_traces.synergy_core_challenge_aetherflux_over_storm:Sisay, Weatherlight Captain #61 (real):1[32]` turn `14` effect `land` metric ``

### Surge to Victory

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `miracle` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[8]` turn `` effect `` metric `miracle:Surge to Victory`
- `miracle` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[8]` turn `` effect `` metric `miracle:Surge to Victory`
- `miracle` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[8]` turn `` effect `` metric `miracle:Surge to Victory`
- `miracle` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_silence_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[8]` turn `` effect `` metric `miracle:Surge to Victory`
- `miracle` from `docs/hermes-analysis/master_optimizer_reports/lorehold_austere_emeria_tradeoff_gate_20260627_v1_20260627_232955.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[8]` turn `` effect `` metric `miracle:Surge to Victory`
- `trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Etali, Primal Conqueror #67 (real):1[59]` turn `11` effect `copy_spell` metric ``
- `trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Tivit, Seller of Secrets #108 (real):2[94]` turn `16` effect `copy_spell` metric ``
- `trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_boros_charm_tibalts_trickery_v1:Kinnan, Bonder Prodigy #57 (real):0[99]` turn `16` effect `copy_spell` metric ``

### Swiftfoot Boots

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg078_l2_hash_scope_restore_focused_events_20260623_063535.jsonl` path `line:16` turn `4` effect `equipment_static_attachment` metric ``
- `equipment_attached` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg078_l2_hash_scope_restore_focused_events_20260623_063535.jsonl` path `line:17` turn `4` effect `equipment_static_attachment` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[9]` turn `` effect `` metric `cost_paid:Swiftfoot Boots`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[9]` turn `` effect `` metric `cost_paid:Swiftfoot Boots`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[9]` turn `` effect `` metric `cost_paid:Swiftfoot Boots`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_silence_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[9]` turn `` effect `` metric `cost_paid:Swiftfoot Boots`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_austere_emeria_tradeoff_gate_20260627_v1_20260627_232955.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[9]` turn `` effect `` metric `cost_paid:Swiftfoot Boots`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_exposure_by_game_gate_20260628_v1_20260628_101737.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[9]` turn `` effect `` metric `cost_paid:Swiftfoot Boots`

### Swords to Plowshares

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `replacement_applied` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kinnan, Bonder Prodigy #57 (real):0[85]` turn `11` effect `` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_boros_charm_tibalts_trickery_v1:Lumra, Bellow of the Woods #49 (real):2[46]` turn `7` effect `remove_creature` metric ``
- `replacement_applied` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_boros_charm_tibalts_trickery_v1:Lumra, Bellow of the Woods #49 (real):2[47]` turn `7` effect `` metric ``
- `replacement_applied` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3_partial.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kinnan, Bonder Prodigy #57 (real):0[85]` turn `11` effect `` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3_partial.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_boros_charm_tibalts_trickery_v1:Lumra, Bellow of the Woods #49 (real):2[46]` turn `7` effect `remove_creature` metric ``
- `replacement_applied` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3_partial.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_boros_charm_tibalts_trickery_v1:Lumra, Bellow of the Woods #49 (real):2[47]` turn `7` effect `` metric ``
- `replacement_applied` from `docs/hermes-analysis/master_optimizer_reports/lorehold_chaos_warp_stroke_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kefka, Court Mage #112 (real):1[69]` turn `12` effect `` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_chaos_warp_stroke_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Winota, Joiner of Forces #73 (real):1[47]` turn `7` effect `remove_creature` metric ``

### Talisman of Conviction

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[4]` turn `` effect `` metric `cost_paid:Talisman of Conviction`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[4]` turn `` effect `` metric `cost_paid:Talisman of Conviction`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[4]` turn `` effect `` metric `cost_paid:Talisman of Conviction`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_silence_fixed.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[4]` turn `` effect `` metric `cost_paid:Talisman of Conviction`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_austere_emeria_tradeoff_gate_20260627_v1_20260627_232955.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[4]` turn `` effect `` metric `cost_paid:Talisman of Conviction`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[9]` turn `` effect `` metric `cost_paid:Talisman of Conviction`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_chaos_warp_stroke_gate_20260630_seed20260630_real8_games3.json` path `results[1].telemetry.top_cards[11]` turn `` effect `` metric `cost_paid:Talisman of Conviction`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed999_real8_games3.json` path `results[1].telemetry.top_cards[10]` turn `` effect `` metric `cost_paid:Talisman of Conviction`

### Teferi's Protection

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `phase_out_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[2].gate_summary.candidate.telemetry.squee_game_traces.synergy_reprieve_cut_avatar_wrath:Sisay, Weatherlight Captain #61 (real):0[12]` turn `8` effect `` metric ``
- `phase_out_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[2].gate_summary.candidate.telemetry.squee_trace_samples[12]` turn `8` effect `` metric ``
- `phase_out_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Umbris, Fear Manifest #114 (real):1[33]` turn `8` effect `` metric ``
- `phase_out_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed20260625_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_core_challenge_dance_over_storm:Sisay, Weatherlight Captain #61 (real):1[25]` turn `16` effect `` metric ``
- `lorehold_rummage_to_top` from `docs/hermes-analysis/master_optimizer_reports/lorehold_lapse_approach_gate_20260627_v1_fixed.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[5]` turn `` effect `` metric `lorehold_rummage_to_top:Teferi's Protection`
- `discard_to_top` from `docs/hermes-analysis/master_optimizer_reports/lorehold_lapse_approach_gate_20260627_v1_fixed.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[6]` turn `` effect `` metric `discard_to_top:Teferi's Protection`
- `phase_out_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brainstone_topdeck_miracle_cut_squelcher:Vivi Ornitier #99 (real):1[4]` turn `7` effect `` metric ``
- `phase_out_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1.json` path `packages[0].gate_summary.candidate.telemetry.squee_trace_samples[4]` turn `7` effect `` metric ``

### Tempt with Bunnies

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg091_token_maker_family_focused_events_20260623_093259.jsonl` path `line:11` turn `9` effect `composite_resolution` metric ``
- `composite_rule_component_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg091_token_maker_family_focused_events_20260623_093259.jsonl` path `line:12` turn `9` effect `` metric ``
- `composite_rule_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg091_token_maker_family_focused_events_20260623_093259.jsonl` path `line:14` turn `9` effect `` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[6]` turn `` effect `` metric `cost_paid:Tempt with Bunnies`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v5_exposure_smoke_20260627_213725.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[11]` turn `` effect `` metric `cost_paid:Tempt with Bunnies`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[7]` turn `` effect `` metric `cost_paid:Tempt with Bunnies`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_equal_battle_gate_20260629_artifact_contract_smoke_v1.json` path `results[0].telemetry.top_cards[11]` turn `` effect `` metric `cost_paid:Tempt with Bunnies`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed20260625_hash0_isolated_timeout_storm_challenge.json` path `packages[1].gate_summary.candidate.telemetry.top_cards[11]` turn `` effect `` metric `cost_paid:Tempt with Bunnies`

### The Mind Stone

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[2]` turn `` effect `` metric `cost_paid:The Mind Stone`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[2].gate_summary.candidate.telemetry.top_cards[10]` turn `` effect `` metric `cost_paid:The Mind Stone`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Etali, Primal Conqueror #67 (real):0[32]` turn `6` effect `ramp_permanent` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kinnan, Bonder Prodigy #84 (real):0[30]` turn `6` effect `ramp_permanent` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kinnan, Bonder Prodigy #84 (real):2[34]` turn `6` effect `ramp_permanent` metric ``
- `utility_artifact_activated` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kinnan, Bonder Prodigy #84 (real):2[51]` turn `8` effect `` metric ``
- `trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kinnan, Bonder Prodigy #84 (real):2[52]` turn `8` effect `harnessed_blink` metric ``
- `trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kinnan, Bonder Prodigy #84 (real):2[60]` turn `9` effect `harnessed_blink` metric ``

### The Scarlet Witch

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[1].gate_summary.candidate.telemetry.top_cards[9]` turn `` effect `` metric `cost_paid:The Scarlet Witch`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_silence_fixed.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[9]` turn `` effect `` metric `cost_paid:The Scarlet Witch`
- `static_cost_reduction_saved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.top_cards[7]` turn `` effect `` metric `static_cost_reduction_saved:The Scarlet Witch`
- `static_cost_reduction_saved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3_partial.json` path `results[0].telemetry.top_cards[7]` turn `` effect `` metric `static_cost_reduction_saved:The Scarlet Witch`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v5_exposure_smoke_20260627_213725.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[5]` turn `` effect `` metric `cost_paid:The Scarlet Witch`
- `static_cost_reduction_saved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_deflecting_palm_redirect_lightning_gate_20260630_seed20260630_real8_games3.json` path `results[1].telemetry.top_cards[7]` turn `` effect `` metric `static_cost_reduction_saved:The Scarlet Witch`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_creative_technique_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kefka, Court Mage #112 (real):0[51]` turn `8` effect `static_cost_reduction` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_creative_technique_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kraum, Ludevic's Opus #81 (real):1[78]` turn `13` effect `static_cost_reduction` metric ``

### Thor, God of Thunder

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_austere_emeria_tradeoff_gate_20260627_v1_20260627_232955.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[6]` turn `` effect `` metric `cost_paid:Thor, God of Thunder`
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/lorehold_austere_emeria_tradeoff_gate_20260627_v1_20260627_232955.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[7]` turn `` effect `` metric `spell_cast:Thor, God of Thunder`
- `thor_noncreature_damage_amount` from `docs/hermes-analysis/master_optimizer_reports/lorehold_chaos_warp_stroke_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.top_cards[11]` turn `` effect `` metric `thor_noncreature_damage_amount:Thor, God of Thunder`
- `trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_chaos_warp_stroke_gate_20260630_seed20260630_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_chaos_warp_stroke_of_midnight_v1:Winota, Joiner of Forces #73 (real):0[120]` turn `17` effect `damage_any_target` metric ``
- `thor_noncreature_damage_amount` from `docs/hermes-analysis/master_optimizer_reports/lorehold_cloud_key_waterskin_gate_20260630_all_lanes_20260630_082705.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[11]` turn `` effect `` metric `thor_noncreature_damage_amount:Thor, God of Thunder`
- `thor_noncreature_damage_amount` from `docs/hermes-analysis/master_optimizer_reports/lorehold_deflecting_palm_redirect_lightning_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.top_cards[11]` turn `` effect `` metric `thor_noncreature_damage_amount:Thor, God of Thunder`
- `trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_deflecting_palm_redirect_lightning_gate_20260630_seed20260630_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_deflecting_palm_redirect_lightning_v1:Winota, Joiner of Forces #73 (real):2[37]` turn `6` effect `damage_any_target` metric ``
- `thor_noncreature_damage_amount` from `docs/hermes-analysis/master_optimizer_reports/lorehold_electro_waterskin_gate_20260630_fixed_20260630_042339.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[11]` turn `` effect `` metric `thor_noncreature_damage_amount:Thor, God of Thunder`

### Tibalt's Trickery

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `lorehold_rummage_to_top` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[6]` turn `` effect `` metric `lorehold_rummage_to_top:Tibalt's Trickery`
- `discard_to_top` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[7]` turn `` effect `` metric `discard_to_top:Tibalt's Trickery`
- `lorehold_rummage_to_top` from `docs/hermes-analysis/master_optimizer_reports/lorehold_life_floor_conversion_gate_20260627_seed7_v1_life_floor_v1.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[6]` turn `` effect `` metric `lorehold_rummage_to_top:Tibalt's Trickery`
- `discard_to_top` from `docs/hermes-analysis/master_optimizer_reports/lorehold_life_floor_conversion_gate_20260627_seed7_v1_life_floor_v1.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[7]` turn `` effect `` metric `discard_to_top:Tibalt's Trickery`
- `discard_to_top` from `docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_benchmark_gate_20260630_after_forced_confirm_20260630_050720.json` path `packages[1].gate_summary.candidate.telemetry.top_cards[9]` turn `` effect `` metric `discard_to_top:Tibalt's Trickery`
- `discard_to_top` from `docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_benchmark_gate_20260630_after_forced_confirm_20260630_050720_planetarium_of_wan_shi_tong_same_lane_benchmark_cut_creative_technique.json` path `results[1].telemetry.top_cards[9]` turn `` effect `` metric `discard_to_top:Tibalt's Trickery`
- `discard_to_top` from `docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_benchmark_gate_20260630_after_forced_confirm_20260630_050720_planetarium_of_wan_shi_tong_same_lane_benchmark_cut_creative_technique_partial.json` path `results[1].telemetry.top_cards[9]` turn `` effect `` metric `discard_to_top:Tibalt's Trickery`
- `discard_to_top` from `docs/hermes-analysis/master_optimizer_reports/lorehold_promotion_gate_607_614_615_20260629_seed7_real8_games3.json` path `results[0].telemetry.top_cards[10]` turn `` effect `` metric `discard_to_top:Tibalt's Trickery`

### Tragic Arrogance

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `miracle` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_silence_fixed.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[7]` turn `` effect `` metric `miracle:Tragic Arrogance`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_creative_technique_seed20260630_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_enlightened_tutor_creative_technique_v1:Kraum, Ludevic's Opus #81 (real):1[84]` turn `13` effect `selective_nonland_sacrifice` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_creative_technique_seed20260630_real8_games3_partial.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_enlightened_tutor_creative_technique_v1:Kraum, Ludevic's Opus #81 (real):1[84]` turn `13` effect `selective_nonland_sacrifice` metric ``
- `turn_end` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed20260625_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_core_challenge_dance_over_storm:Vivi Ornitier #99 (real):2[5]` turn `19` effect `` metric ``
- `turn_end` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed20260625_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.candidate.telemetry.squee_trace_samples[5]` turn `19` effect `` metric ``
- `permanent_moved_from_battlefield` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed42_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Winota, Joiner of Forces #39 (real):1[6]` turn `7` effect `` metric ``
- `board_wipe_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed42_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Winota, Joiner of Forces #39 (real):1[7]` turn `7` effect `` metric ``
- `permanent_moved_from_battlefield` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed42_hash0_isolated_timeout_storm_challenge.json` path `packages[1].gate_summary.candidate.telemetry.squee_game_traces.synergy_core_challenge_aetherflux_over_storm:Sisay, Weatherlight Captain #61 (real):1[36]` turn `15` effect `` metric ``

### Turbulent Steppe

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Tannuk, Memorial Ensign #40 (real):1[22]` turn `11` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Aang, at the Crossroads #106 (real):0[9]` turn `4` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Aang, at the Crossroads #106 (real):0[9]` turn `4` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_gate_20260627_v1_real.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_plateau_timing_upgrade_cut_radiant_summit:Vivi Ornitier #99 (real):1[60]` turn `17` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_gate_20260627_v1_real.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_plateau_timing_upgrade_cut_radiant_summit:Winota, Joiner of Forces #39 (real):2[11]` turn `8` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_post_squee_package_gate_20260627_v1_seed42_hash0_isolated_timeout.json` path `packages[2].gate_summary.candidate.telemetry.squee_game_traces.synergy_galvanoth_topdeck_freecast:Sisay, Weatherlight Captain #61 (real):2[62]` turn `16` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_spellchain_conversion_gate_20260627_seed42_v1_spellchain_v1.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_birgi_seething_chain_cut_medallions:Winota, Joiner of Forces #39 (real):2[6]` turn `12` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed99_20260627_v1.json` path `results[2].telemetry.squee_game_traces.candidate_607_squee_hashseed0_isolated_cached_timeout_v3:Sisay, Weatherlight Captain #61 (real):0[17]` turn `13` effect `land` metric ``

### Unexpected Windfall

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `runtime_rule_loaded` from `docs/hermes-analysis/master_optimizer_reports/deck6_606_pg082_hash_only_focused_events_20260623_083100.jsonl` path `line:3` turn `` effect `treasure_maker` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_606_pg082_hash_only_focused_events_20260623_083100.jsonl` path `line:6` turn `4` effect `treasure_maker` metric ``
- `additional_cost_paid` from `docs/hermes-analysis/master_optimizer_reports/deck6_606_pg082_hash_only_focused_events_20260623_083100.jsonl` path `line:7` turn `4` effect `` metric ``
- `treasure_created` from `docs/hermes-analysis/master_optimizer_reports/deck6_606_pg082_hash_only_focused_events_20260623_083100.jsonl` path `line:8` turn `4` effect `` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg069_specific_runtime_cleanup_focused_events_20260623_011015.jsonl` path `line:6` turn `5` effect `treasure_maker` metric ``
- `additional_cost_paid` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg069_specific_runtime_cleanup_focused_events_20260623_011015.jsonl` path `line:7` turn `5` effect `` metric ``
- `treasure_created` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg069_specific_runtime_cleanup_focused_events_20260623_011015.jsonl` path `line:8` turn `5` effect `` metric ``
- `additional_cost_paid` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg070_l2_hash_only_runtime_focused_events_20260623_011859.jsonl` path `line:10` turn `7` effect `` metric ``

### Urza's Saga

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `saga_chapter_progressed` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Etali, Primal Conqueror #67 (real):0[35]` turn `6` effect `` metric ``
- `saga_chapter_progressed` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Etali, Primal Conqueror #67 (real):0[41]` turn `7` effect `` metric ``
- `saga_chapter_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Etali, Primal Conqueror #67 (real):0[42]` turn `7` effect `` metric ``
- `saga_sacrificed_by_sba` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Etali, Primal Conqueror #67 (real):0[43]` turn `7` effect `` metric ``
- `saga_chapter_progressed` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Etali, Primal Conqueror #67 (real):1[17]` turn `4` effect `` metric ``
- `saga_chapter_progressed` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Etali, Primal Conqueror #67 (real):1[23]` turn `5` effect `` metric ``
- `saga_chapter_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Etali, Primal Conqueror #67 (real):1[24]` turn `5` effect `` metric ``
- `saga_sacrificed_by_sba` from `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Etali, Primal Conqueror #67 (real):1[26]` turn `5` effect `` metric ``

### Victory Chimes

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v5_exposure_smoke_20260627_213725.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[9]` turn `` effect `` metric `cost_paid:Victory Chimes`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[11]` turn `` effect `` metric `cost_paid:Victory Chimes`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_creative_technique_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kefka, Court Mage #112 (real):1[51]` turn `9` effect `ramp_permanent` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_creative_technique_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kinnan, Bonder Prodigy #72 (real):0[32]` turn `6` effect `ramp_permanent` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_creative_technique_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kinnan, Bonder Prodigy #72 (real):1[26]` turn `5` effect `ramp_permanent` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_creative_technique_seed20260630_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Thrasios, Triton Hero #76 (real):2[126]` turn `20` effect `ramp_permanent` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_creative_technique_seed20260630_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_enlightened_tutor_creative_technique_v1:Kinnan, Bonder Prodigy #72 (real):2[55]` turn `8` effect `ramp_permanent` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_creative_technique_seed20260630_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_enlightened_tutor_creative_technique_v1:Kraum, Ludevic's Opus #81 (real):0[33]` turn `6` effect `ramp_permanent` metric ``

### War Room

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_923.jsonl` path `line:68` turn `4` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed20260625_v1_library_pressure_v1.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brainstone_topdeck_miracle_cut_squelcher:Sisay, Weatherlight Captain #61 (real):0[14]` turn `5` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed7_v1_library_pressure_v1.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brainstone_topdeck_miracle_cut_squelcher:Vivi Ornitier #99 (real):2[35]` turn `10` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed7_v1_library_pressure_v1.json` path `packages[2].gate_summary.candidate.telemetry.squee_game_traces.synergy_one_ring_protection_draw_cut_squelcher:Vivi Ornitier #99 (real):1[20]` turn `7` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_post_squee_package_gate_20260627_v1_seed42_hash0_isolated_timeout.json` path `packages[1].gate_summary.candidate.telemetry.squee_game_traces.synergy_faithless_looting_squee_enabler:Vivi Ornitier #99 (real):0[42]` turn `20` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_post_squee_package_gate_20260627_v1_seed42_hash0_isolated_timeout.json` path `packages[2].gate_summary.candidate.telemetry.squee_game_traces.synergy_galvanoth_topdeck_freecast:Vivi Ornitier #99 (real):1[16]` turn `13` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_post_squee_package_gate_20260627_v1_seed42_hash0_isolated_timeout.json` path `packages[2].gate_summary.candidate.telemetry.squee_trace_samples[16]` turn `13` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_spellchain_conversion_gate_20260627_seed20260625_v1_spellchain_v1.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_birgi_seething_chain_cut_medallions:Winota, Joiner of Forces #39 (real):1[6]` turn `23` effect `land` metric ``

### Winds of Abandon

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[10]` turn `` effect `` metric `cost_paid:Winds of Abandon`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_austere_emeria_tradeoff_gate_20260627_v1_20260627_232955.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[1]` turn `` effect `` metric `cost_paid:Winds of Abandon`
- `replacement_applied` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed123_real8_games3.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Thrasios, Triton Hero #101 (real):0[52]` turn `7` effect `` metric ``
- `replacement_applied` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed123_real8_games3_partial.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Thrasios, Triton Hero #101 (real):0[52]` turn `7` effect `` metric ``
- `replacement_applied` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed20260630_real8_games3.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_enlightened_tutor_insurrection_v1:Kraum, Ludevic's Opus #81 (real):1[66]` turn `10` effect `` metric ``
- `replacement_applied` from `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed20260630_real8_games3_partial.json` path `results[1].telemetry.focus_card_game_traces.candidate_607_enlightened_tutor_insurrection_v1:Kraum, Ludevic's Opus #81 (real):1[66]` turn `10` effect `` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed42_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[7]` turn `` effect `` metric `cost_paid:Winds of Abandon`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json` path `packages[4].gate_summary.candidate.telemetry.top_cards[2]` turn `` effect `` metric `cost_paid:Winds of Abandon`

### Windswept Heath

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seed42/battle_forensic_seed_42.jsonl` path `line:990` turn `16` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seeds42_44/battle_forensic_seed_42.jsonl` path `line:990` turn `16` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Sisay, Weatherlight Captain #61 (real):0[8]` turn `5` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Tannuk, Memorial Ensign #40 (real):1[17]` turn `10` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed7_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_core_challenge_dance_over_storm:Winota, Joiner of Forces #39 (real):0[16]` turn `10` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed20260625_v1_library_pressure_v1.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brainstone_topdeck_miracle_cut_squelcher:Winota, Joiner of Forces #39 (real):2[16]` turn `18` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_post_squee_package_gate_20260627_v1_seed20260625_hash0_isolated_timeout.json` path `packages[2].gate_summary.candidate.telemetry.squee_game_traces.synergy_galvanoth_topdeck_freecast:Winota, Joiner of Forces #39 (real):1[28]` turn `13` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_radiant_scrollwielder_gate_20260627_v1_fixed.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_radiant_scrollwielder_cut_scarlet_witch:Winota, Joiner of Forces #39 (real):0[5]` turn `10` effect `land` metric ``

### Wooded Foothills

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_923.jsonl` path `line:191` turn `10` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seed42/battle_forensic_seed_42.jsonl` path `line:822` turn `12` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seeds42_44/battle_forensic_seed_42.jsonl` path `line:822` turn `12` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Winota, Joiner of Forces #39 (real):0[5]` turn `17` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[5]` turn `17` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Winota, Joiner of Forces #39 (real):0[5]` turn `17` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed20260625_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_core_challenge_dance_over_storm:Sisay, Weatherlight Captain #61 (real):1[4]` turn `11` effect `land` metric ``
- `land_played` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed20260625_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_core_challenge_dance_over_storm:Winota, Joiner of Forces #39 (real):0[20]` turn `18` effect `land` metric ``
