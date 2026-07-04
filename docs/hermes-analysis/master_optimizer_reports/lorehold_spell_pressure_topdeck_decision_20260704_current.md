# Lorehold Spell Pressure Topdeck Decision

- generated_at: `2026-07-04T22:49:23Z`
- status: `spell_pressure_smoke_positive_but_not_confirmable`
- postgres_writes: `false`
- source_db_mutated: `false`
- deck_607_mutated: `false`
- baseline_rank: `1`
- candidate_rank: `2`
- aggregate_delta_wins: `1`
- candidate_record: `{"games": 4, "losses": 3, "stalls": 0, "win_rate": 25.0, "wins": 1}`
- baseline_record: `{"games": 4, "losses": 4, "stalls": 0, "win_rate": 0.0, "wins": 0}`
- observed_pressure_cards: `["Young Pyromancer"]`
- failure_modes: `["head_to_head_lost_to_607", "miracle_topdeck_or_lorehold_floor_regressed", "no_fast_pressure_lift", "no_seed_safe_cut_fallback", "package_density_not_clean", "pressure_pair_underexercised", "structural_rank_below_607"]`
- promotion_allowed: `false`
- confirmation_allowed: `false`

## Battle Detail

- candidate_games_by_opponent: `{"Fixed Lorehold deck 607": "loss", "Sisay, Weatherlight Captain #61 (real)": "win", "Vivi Ornitier #99 (real)": "loss", "Winota, Joiner of Forces #39 (real)": "loss"}`
- baseline_games_by_opponent: `{"Fixed Lorehold deck 607": "loss", "Sisay, Weatherlight Captain #61 (real)": "loss", "Vivi Ornitier #99 (real)": "loss", "Winota, Joiner of Forces #39 (real)": "loss"}`
- strategic_floor_deltas: `{"lorehold_spell_cast": 0, "lorehold_upkeep_rummage": -1, "miracle_cast": -1, "topdeck_manipulation_activated": 0}`
- pressure_card_event_counts: `{"cost_paid:Young Pyromancer": 1, "spell_cast:Young Pyromancer": 1, "spell_resolved:Young Pyromancer": 1}`

## External Learning

- GameTyrant Lorehold deck tech: https://gametyrant.com/news/how-to-build-a-lorehold-the-historian-commander-deck-deck-tech
- EDHREC optimized spellslinger page: https://edhrec.com/commanders/lorehold-the-historian/optimized/spellslinger
- Draftsim Lorehold guide: https://draftsim.com/lorehold-the-historian-edh-deck/

## Decision

- keep_607_as_protected_baseline: `true`
- promotion_allowed: `false`
- confirmation_allowed: `false`
- reason: The new full-shell pressure deck produced a small smoke aggregate lift, but it ranked below 607 structurally, lost the head-to-head mirror, regressed key miracle/topdeck/Lorehold floor metrics, and naturally exercised only part of the pressure pair.
- next_actions:
  - do_not_promote_or_confirm_this_exact_shell_yet
  - mine_the_sisay_win_trace_for_whether_young_pyromancer_mattered
  - repair_pressure_card_exposure_before_any_confirm8x3_gate
  - keep_607_protected_until_equal_gate_and_card_use_proof
