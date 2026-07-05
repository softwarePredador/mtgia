# Lorehold Hypothesis Queue From Value Model

- generated_at: `2026-07-05T00:07:40Z`
- status: `lorehold_hypothesis_queue_ready_no_natural_gate`
- postgres_writes: `false`
- source_db_mutated: `false`
- deck_607_mutated: `false`
- protected_baseline: `deck_607`
- hypothesis_count: `40`
- natural_gate_ready_count: `0`
- gate_ready_now_count_from_preflight: `0`
- promotion_allowed: `false`
- allow_new_natural_gate_now: `false`

## Queue Summary

- status_counts: `{"blocked_prior_reject": 9, "needs_safe_cut_model": 31}`
- lane_counts: `{"combo_finishers": 6, "interaction_pressure": 4, "mana_base_review": 7, "protection_window": 5, "spell_chain_conversion": 9, "topdeck_miracle_setup": 5, "tutors_access": 3, "unclassified_variant_watchlist": 4}`
- preflight_status: `no_current_candidate_passes_miracle_access_first_preflight`
- trace_status: `lorehold_miracle_trace_failure_learning_ready`

## Next Learning Actions

### mana_base_safe_cut_model_v1
- purpose: Compare Plateau, Clifftop Retreat, Rugged Prairie, Sundown Pass, Boseiju, Cavern, and Boros Garrison by source quality, ETB/timing risk, and protected utility-land displacement.
- promotion_boundary: No battle gate until the land cut keeps 34 lands, color access, topdeck anchors, and fast-pressure utility intact.

### topdeck_forced_access_diagnostic_v1
- purpose: Exercise Penance, Galvanoth, Valakut Awakening, Wheel of Fortune, and Dragon's Rage Channeler to learn whether they increase first-draw/miracle access without suppressing 607 anchors.
- promotion_boundary: Forced access can teach card value, but natural-gate eligibility still requires non-regressed anchor access floors.

### spell_chain_conversion_trace_v2
- purpose: Study Apex of Power, Brass's Bounty, Dance with Calamity, Goldspan Dragon, and Invoke Calamity as conversion cards only after miracle/topdeck trace improves.
- promotion_boundary: Do not expand pressure or mana packages without positive miracle-cast and topdeck-activation traces.

### protection_window_pressure_diagnostic_v1
- purpose: Test Silence, Boros Charm, Grand Abolisher, Perch Protection, and Deflecting Palm as pressure-window hypotheses with explicit Winota-floor checks.
- promotion_boundary: A card that improves generic protection still fails if it regresses fast-pressure matchup or protected miracle cadence.

## Hypotheses

| Priority | Status | Lanes | Card | Next Test |
| --- | --- | --- | --- | --- |
| `P1_safe_cut_model` | `needs_safe_cut_model` | `mana_base_review` | `Plateau` | `build_safe_cut_mana_source_model_before_any_battle_gate` |
| `P1_safe_cut_model` | `needs_safe_cut_model` | `mana_base_review` | `Clifftop Retreat` | `build_safe_cut_mana_source_model_before_any_battle_gate` |
| `P1_safe_cut_model` | `needs_safe_cut_model` | `mana_base_review` | `Boseiju, Who Shelters All` | `build_safe_cut_mana_source_model_before_any_battle_gate` |
| `P1_safe_cut_model` | `needs_safe_cut_model` | `mana_base_review` | `Rugged Prairie` | `build_safe_cut_mana_source_model_before_any_battle_gate` |
| `P1_safe_cut_model` | `needs_safe_cut_model` | `mana_base_review` | `Sundown Pass` | `build_safe_cut_mana_source_model_before_any_battle_gate` |
| `P1_forced_access_diagnostic` | `needs_safe_cut_model` | `spell_chain_conversion` | `Apex of Power` | `forced_access_diagnostic_only_until_miracle_access_floors_pass` |
| `P1_forced_access_diagnostic` | `needs_safe_cut_model` | `combo_finishers, spell_chain_conversion` | `Brass's Bounty` | `forced_access_diagnostic_only_until_miracle_access_floors_pass` |
| `P1_forced_access_diagnostic` | `needs_safe_cut_model` | `combo_finishers, protection_window` | `Perch Protection` | `forced_access_pressure_window_diagnostic_only_until_winota_floor_passes` |
| `P1_forced_access_diagnostic` | `needs_safe_cut_model` | `protection_window` | `Boros Charm` | `forced_access_pressure_window_diagnostic_only_until_winota_floor_passes` |
| `P1_forced_access_diagnostic` | `needs_safe_cut_model` | `protection_window` | `Silence` | `forced_access_pressure_window_diagnostic_only_until_winota_floor_passes` |
| `P1_forced_access_diagnostic` | `needs_safe_cut_model` | `topdeck_miracle_setup` | `Galvanoth` | `forced_access_diagnostic_only_until_miracle_access_floors_pass` |
| `P1_forced_access_diagnostic` | `needs_safe_cut_model` | `topdeck_miracle_setup` | `Penance` | `forced_access_diagnostic_only_until_miracle_access_floors_pass` |
| `P1_forced_access_diagnostic` | `needs_safe_cut_model` | `topdeck_miracle_setup` | `Valakut Awakening // Valakut Stoneforge` | `forced_access_diagnostic_only_until_miracle_access_floors_pass` |
| `P1_forced_access_diagnostic` | `needs_safe_cut_model` | `topdeck_miracle_setup` | `Wheel of Fortune` | `forced_access_diagnostic_only_until_miracle_access_floors_pass` |
| `P1_forced_access_diagnostic` | `needs_safe_cut_model` | `interaction_pressure, protection_window` | `Deflecting Palm` | `forced_access_pressure_window_diagnostic_only_until_winota_floor_passes` |
| `P1_forced_access_diagnostic` | `needs_safe_cut_model` | `topdeck_miracle_setup` | `Dragon's Rage Channeler` | `forced_access_diagnostic_only_until_miracle_access_floors_pass` |
| `P1_forced_access_diagnostic` | `needs_safe_cut_model` | `protection_window` | `Grand Abolisher` | `forced_access_pressure_window_diagnostic_only_until_winota_floor_passes` |
| `P2_forced_access_diagnostic` | `needs_safe_cut_model` | `interaction_pressure` | `Austere Command` | `safe_cut_model_required_before_natural_gate` |
| `P2_forced_access_diagnostic` | `needs_safe_cut_model` | `spell_chain_conversion` | `Dance with Calamity` | `forced_access_diagnostic_only_until_miracle_access_floors_pass` |
| `P2_forced_access_diagnostic` | `needs_safe_cut_model` | `spell_chain_conversion` | `Goldspan Dragon` | `forced_access_diagnostic_only_until_miracle_access_floors_pass` |
| `P2_forced_access_diagnostic` | `needs_safe_cut_model` | `spell_chain_conversion` | `Invoke Calamity` | `forced_access_diagnostic_only_until_miracle_access_floors_pass` |
| `P2_forced_access_diagnostic` | `needs_safe_cut_model` | `combo_finishers` | `Longshot, Rebel Bowman` | `safe_cut_model_required_before_natural_gate` |
| `P2_forced_access_diagnostic` | `needs_safe_cut_model` | `unclassified_variant_watchlist` | `Olórin's Searing Light` | `safe_cut_model_required_before_natural_gate` |
| `P2_forced_access_diagnostic` | `needs_safe_cut_model` | `unclassified_variant_watchlist` | `Restoration Seminar` | `safe_cut_model_required_before_natural_gate` |
| `P2_forced_access_diagnostic` | `needs_safe_cut_model` | `unclassified_variant_watchlist` | `Volcanic Vision` | `safe_cut_model_required_before_natural_gate` |
| `P2_forced_access_diagnostic` | `needs_safe_cut_model` | `mana_base_review` | `Boros Garrison` | `build_safe_cut_mana_source_model_before_any_battle_gate` |
| `P2_forced_access_diagnostic` | `needs_safe_cut_model` | `mana_base_review` | `Cavern of Souls` | `build_safe_cut_mana_source_model_before_any_battle_gate` |
| `P2_forced_access_diagnostic` | `needs_safe_cut_model` | `interaction_pressure` | `Chaos Warp` | `safe_cut_model_required_before_natural_gate` |
| `P2_forced_access_diagnostic` | `needs_safe_cut_model` | `combo_finishers` | `Dualcaster Mage` | `safe_cut_model_required_before_natural_gate` |
| `P2_forced_access_diagnostic` | `needs_safe_cut_model` | `tutors_access` | `Goblin Engineer` | `safe_cut_model_required_before_natural_gate` |
| `P2_forced_access_diagnostic` | `needs_safe_cut_model` | `combo_finishers` | `Goliath Daydreamer` | `safe_cut_model_required_before_natural_gate` |
| `P3_learning_only` | `blocked_prior_reject` | `tutors_access` | `Enlightened Tutor` | `do_not_retest_without_new_cut_or_new_trace_hypothesis` |
| `P3_learning_only` | `blocked_prior_reject` | `tutors_access` | `Gamble` | `do_not_retest_without_new_cut_or_new_trace_hypothesis` |
| `P3_learning_only` | `blocked_prior_reject` | `spell_chain_conversion` | `Storm-Kiln Artist` | `do_not_retest_without_new_cut_or_new_trace_hypothesis` |
| `P3_learning_only` | `blocked_prior_reject` | `spell_chain_conversion` | `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `do_not_retest_without_new_cut_or_new_trace_hypothesis` |
| `P3_learning_only` | `blocked_prior_reject` | `spell_chain_conversion` | `Mana Vault` | `do_not_retest_without_new_cut_or_new_trace_hypothesis` |
| `P3_learning_only` | `blocked_prior_reject` | `unclassified_variant_watchlist` | `The One Ring` | `do_not_retest_without_new_cut_or_new_trace_hypothesis` |
| `P3_learning_only` | `blocked_prior_reject` | `spell_chain_conversion` | `Cloud Key` | `do_not_retest_without_new_cut_or_new_trace_hypothesis` |
| `P3_learning_only` | `blocked_prior_reject` | `interaction_pressure` | `Electro, Assaulting Battery` | `do_not_retest_without_new_cut_or_new_trace_hypothesis` |
| `P3_learning_only` | `blocked_prior_reject` | `combo_finishers` | `Possibility Storm` | `do_not_retest_without_new_cut_or_new_trace_hypothesis` |

## Queue Policy

- natural_gate: closed until miracle_access_first_shell_v1 floors pass before battle
- prior_rejects: blocked unless a materially new cut model or trace hypothesis is declared
- safe_cuts: required before any candidate can be called a real challenger
- forced_access: allowed only as learning diagnostic; it cannot promote a deck by itself
- lands: review only through a mana-source model that preserves 34 lands and protected utility anchors

## External Research Refresh

- Wizards Commander format: https://magic.wizards.com/en/formats/commander
  - Commander legality remains the first gate: 99-card main deck plus commander, singleton, color identity, multiplayer context, and power-bracket framing.
- Official Commander rules: https://mtgcommander.net/index.php/rules/
  - The deck shape, singleton rule, and color identity restrictions are hard constraints before strategy scoring.
- Scryfall Lorehold Oracle: https://scryfall.com/card/sos/201/lorehold-the-historian
  - Lorehold's strategic center is discounted miracle for instants/sorceries plus opponent-upkeep rummage, so topdeck control and first-draw timing are not optional lanes.
- EDHREC Lorehold optimized topdeck decks: https://edhrec.com/decks/lorehold-the-historian/optimized/topdeck
  - Current public signal tags Lorehold as Topdeck, Spellslinger, Combo, and Discard; these are evidence lanes, not automatic card swaps over protected 607 anchors.
- EDHREC Lorehold combos: https://edhrec.com/combos/lorehold-the-historian
  - Approach/Scroll Rack, Mizzix's Mastery, and Top/Birgi-style combo references support package hypotheses, but combo existence is not deck-balance or battle-gate proof.
- Card Kingdom Lorehold synergy review: https://blog.cardkingdom.com/10-crazy-synergy-cards-for-lorehold-the-historian-secrets-of-strixhaven/
  - Library of Leng, Penance, Sensei's Divining Top, Scroll Rack, Land Tax, Victory Chimes, and Bender's Waterskin are externally coherent with the miracle setup plan; internal gates still decide final cuts.

## Decision

- current_best_baseline: `deck_607`
- natural_gate_ready_now: `false`
- promotion_allowed: `false`
- reason: The value model has useful hypotheses, but the latest preflight has zero gate-ready candidates. No card from the watchlist currently has both safe-cut proof and miracle-access floor proof.
- next_action: `run safe-cut model and forced-access diagnostics as learning steps before any natural battle gate`
