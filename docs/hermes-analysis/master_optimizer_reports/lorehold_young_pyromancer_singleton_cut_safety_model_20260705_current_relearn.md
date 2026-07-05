# Lorehold Young Pyromancer Singleton Cut-Safety Model

- Generated at: `2026-07-05T03:47:34Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Status: `young_pyromancer_singleton_no_cut_keep_607`
- Target card: `Young Pyromancer`
- Package status: `blocked_no_cut_or_hypothesis_capacity`
- Evaluated cut slots: `94`
- Eligible cuts: `0`
- Pressure-lane evidence gaps: `0`
- Pressure-lane hard blocked: `1`
- Seed-safe cut count: `0`
- Reviewable evidence gaps: `0`
- Natural battle gate allowed: `false`
- Promotion allowed: `false`
- Recommended next action: `mine_pressure_lane_cut_evidence_or_non_deck_forced_diagnostic`

## Target Card

- Role: `low_curve_token_pressure_payoff`
- CMC: `2.0`
- Type line: `Creature — Human Shaman`
- Commander legality: `legal`
- Preflight: `pass`
- Verified auto battle rules: `1`
- Already in 607: `false`
- Package blockers: `["insufficient_diagnostic_cut_capacity", "insufficient_hypothesis_natural_gate_capacity", "insufficient_seed_safe_cut_capacity", "missing_current_hypothesis_queue", "no_card_level_natural_gate_ready"]`

## Top Cut-Safety Rows

| Card | Lane | Young Pyromancer Cut Status | Exposure | Events | Action |
| --- | --- | --- | ---: | ---: | --- |
| Hexing Squelcher | `contextual` | `blocked_pressure_lane_hard_anchor` | 93 | 17 | do_not_cut_until_new_evidence_removes_anchor_blocker |
| Call Forth the Tempest | `spell_velocity` | `blocked_hard_anchor_or_prior_reject` | 8 | 4 | do_not_use_as_young_pyromancer_cut_under_current_contract |
| Pinnacle Monk // Mystic Peak | `removal` | `blocked_hard_anchor_or_prior_reject` | 8 | 7 | do_not_use_as_young_pyromancer_cut_under_current_contract |
| Redirect Lightning | `protection` | `blocked_hard_anchor_or_prior_reject` | 9 | 1 | do_not_use_as_young_pyromancer_cut_under_current_contract |
| Hit the Mother Lode | `early_mana` | `blocked_hard_anchor_or_prior_reject` | 11 | 7 | do_not_use_as_young_pyromancer_cut_under_current_contract |
| Flawless Maneuver | `protection` | `blocked_hard_anchor_or_prior_reject` | 16 | 12 | do_not_use_as_young_pyromancer_cut_under_current_contract |
| Tibalt's Trickery | `protection` | `blocked_hard_anchor_or_prior_reject` | 17 | 0 | do_not_use_as_young_pyromancer_cut_under_current_contract |
| Dawn's Truce | `hand_filter` | `blocked_hard_anchor_or_prior_reject` | 17 | 1 | do_not_use_as_young_pyromancer_cut_under_current_contract |
| Reforge the Soul | `draw` | `blocked_hard_anchor_or_prior_reject` | 23 | 15 | do_not_use_as_young_pyromancer_cut_under_current_contract |
| Insurrection | `wincon` | `blocked_hard_anchor_or_prior_reject` | 23 | 22 | do_not_use_as_young_pyromancer_cut_under_current_contract |
| Teferi's Protection | `protection` | `blocked_hard_anchor_or_prior_reject` | 24 | 12 | do_not_use_as_young_pyromancer_cut_under_current_contract |
| Storm Herd | `big_spell_value` | `blocked_hard_anchor_or_prior_reject` | 25 | 20 | do_not_use_as_young_pyromancer_cut_under_current_contract |
| Tempt with Bunnies | `wincon` | `blocked_hard_anchor_or_prior_reject` | 31 | 3 | do_not_use_as_young_pyromancer_cut_under_current_contract |
| Unexpected Windfall | `early_mana` | `blocked_hard_anchor_or_prior_reject` | 33 | 25 | do_not_use_as_young_pyromancer_cut_under_current_contract |
| Everything Comes to Dust | `spell_velocity` | `blocked_hard_anchor_or_prior_reject` | 34 | 31 | do_not_use_as_young_pyromancer_cut_under_current_contract |
| Big Score | `early_mana` | `blocked_hard_anchor_or_prior_reject` | 40 | 33 | do_not_use_as_young_pyromancer_cut_under_current_contract |
| Stroke of Midnight | `removal` | `blocked_hard_anchor_or_prior_reject` | 43 | 32 | do_not_use_as_young_pyromancer_cut_under_current_contract |
| Jeska's Will | `early_mana` | `blocked_hard_anchor_or_prior_reject` | 44 | 6 | do_not_use_as_young_pyromancer_cut_under_current_contract |
| Generous Gift | `removal` | `blocked_hard_anchor_or_prior_reject` | 52 | 19 | do_not_use_as_young_pyromancer_cut_under_current_contract |
| Promise of Loyalty | `protection` | `blocked_hard_anchor_or_prior_reject` | 53 | 46 | do_not_use_as_young_pyromancer_cut_under_current_contract |
| Creative Technique | `big_spell_value` | `blocked_hard_anchor_or_prior_reject` | 58 | 54 | do_not_use_as_young_pyromancer_cut_under_current_contract |
| Winds of Abandon | `removal` | `blocked_hard_anchor_or_prior_reject` | 59 | 32 | do_not_use_as_young_pyromancer_cut_under_current_contract |
| Improvisation Capstone | `draw` | `blocked_hard_anchor_or_prior_reject` | 59 | 49 | do_not_use_as_young_pyromancer_cut_under_current_contract |
| Rise of the Eldrazi | `removal` | `blocked_hard_anchor_or_prior_reject` | 60 | 48 | do_not_use_as_young_pyromancer_cut_under_current_contract |

## External Support

- `EDHREC Lorehold core spellslinger`: https://edhrec.com/commanders/lorehold-the-historian/core/spellslinger - preserve_lorehold_core_axes_before_young_pyromancer_gate
- `GameTyrant Lorehold deck tech`: https://gametyrant.com/news/how-to-build-a-lorehold-the-historian-commander-deck-deck-tech - young_pyromancer_requires_pressure_body_cut_or_package_proof
- `Draftsim spellslinger commander overview`: https://draftsim.com/best-spellslinger-commanders/ - token_pressure_is_a_branch_not_automatic_lorehold_truth

## Decision

- Keep 607 protected: `true`
- Natural battle gate allowed: `false`
- Promotion allowed: `false`
- Reason: Young Pyromancer passes local identity/runtime preflight, but current 607 cut evidence has no eligible pressure-compatible cut and the card is still missing a natural-gate hypothesis row.
- Next actions:
  - do_not_mutate_or_replace_deck_607
  - do_not_run_natural_battle_without_one_named_pressure_safe_cut
  - mine pressure-window losses for low-use non-anchor pressure slots
  - use forced diagnostics only for learning, not promotion
