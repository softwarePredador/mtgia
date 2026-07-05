# Lorehold Post-Mana-Base Learning Router

- generated_at: `2026-07-05T01:01:21Z`
- status: `post_mana_base_route_cut_safety_expansion_required`
- postgres_writes: `false`
- source_db_mutated: `false`
- deck_607_mutated: `false`
- current_best_baseline: `deck_607`
- promotion_allowed: `false`
- natural_battle_allowed_now: `false`
- mana_base_eligible_pair_count: `0`
- natural_gate_ready_count: `0`
- seed_safe_cut_ready_count: `0`
- promotable_external_shell_count: `0`
- recommended_next_route: `build_pressure_safe_cut_expansion_model`
- recommended_next_artifact: `lorehold_pressure_safe_cut_expansion_model`

## Routes

| Priority | Route | Allowed Now | Natural Battle | Reason |
| --- | --- | --- | --- | --- |
| `P0_blocked` | `close_simple_mana_base_swaps` | `false` | `false` | The current mana-base model-ready queue has no eligible pair left. |
| `P1_next` | `build_pressure_safe_cut_expansion_model` | `true` | `false` | External sources and internal traces both support pressure/treasure learning, but the current resolver has zero seed-safe cuts. The next valid work is to expand cut evidence, not to battle a new package. |
| `P2_research` | `storm_kiln_haze_combo_research` | `true` | `false` | Current external combo evidence makes Storm-Kiln plus Haze of Rage worth researching, but it must be treated as a package lane with runtime and cut checks, not as an automatic add. |
| `P2_research` | `full_shell_smoke_positive_followup` | `true` | `false` | Some from-scratch pressure shells produced smoke wins when 607 also failed, but the decision reports block promotion because structural rank, head-to-head, miracle floor, pressure exposure, or cut safety were insufficient. |
| `P0_blocked` | `natural_gate_any_watchlist_card` | `false` | `false` | No current hypothesis has both safe-cut proof and miracle-access floor proof. |

## External Evidence

- `edhrec_lorehold_optimized_discard_20260705`: Current EDHREC bracket-filtered Lorehold optimized discard page keeps the commander framed as spellslinger, topdeck, combo, and discard. Source: https://edhrec.com/commanders/lorehold-the-historian/optimized/discard
- `edhrec_lorehold_treasure_20260705`: The Treasure page surfaces Scroll Rack, Library of Leng, Storm-Kiln Artist, Smothering Tithe, Teferi's Protection, and Jeska's Will as relevant signals, which supports pressure/treasure research without making any one card automatic. Source: https://edhrec.com/commanders/lorehold-the-historian/treasure
- `edhrec_lorehold_budget_miracles_20260705`: The budget miracle article emphasizes high instant/sorcery density, spell-lands/MDFCs, topdeck setup, protection, and Storm-Kiln Artist. Source: https://edhrec.com/articles/lorehold-the-historian-boros-miracles-on-a-budget
- `coolstuffinc_lorehold_pressure_closure_20260705`: The article flags the need for topdeck manipulation, protection, and actual closing pressure; it treats token/combat and combo as alternate directions rather than generic upgrades. Source: https://www.coolstuffinc.com/a/stephenjohnson-04202026-lorehold-the-historian-commander
- `commander_spellbook_storm_kiln_haze_20260705`: Storm-Kiln Artist plus Haze of Rage is a red legal combo lane with infinite Treasure/storm/magecraft implications, but it is package research until runtime, cut, and battle evidence exist. Source: https://commanderspellbook.com/combo/3940-5195/

## Decision

- current_best_baseline: `deck_607`
- promotion_allowed: `false`
- reason: Current internal evidence has no gate-ready candidate after mana-base closure. External evidence supports pressure/treasure and combo-package research, but the active blocker is still cut safety and protected-anchor preservation.
- next_action: `build_pressure_safe_cut_expansion_model`
- blocked_actions: `["do_not_retest_exact_plateau_pairs", "do_not_run_natural_gate_without_safe_cut_and_miracle_access_preflight", "do_not_promote_full_shell_smoke_results", "do_not_cut_protected_607_anchors_for_global_staples"]`
