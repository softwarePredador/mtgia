# Lorehold Pressure Micro-Package Planner

- generated_at: `2026-07-04T22:30:27Z`
- status: `pressure_micro_package_no_gate_ready_keep_607`
- postgres_writes: `false`
- source_db_mutated: `false`
- deck_607_mutated: `false`
- seed_safe_cut_ready_count: `0`
- gate_ready_package_count: `0`
- promotion_allowed: `false`

## Micro Package Queue

| Package | Adds | Status | Trigger Count | Required Cuts |
| --- | --- | --- | ---: | ---: |
| pressure_natural_trigger_pair_guttersnipe_young_pyromancer | Guttersnipe, Young Pyromancer | `blocked_no_seed_safe_cut` | 13 | 2 |
| pressure_single_guttersnipe | Guttersnipe | `blocked_no_seed_safe_cut` | 7 | 1 |
| pressure_single_young_pyromancer | Young Pyromancer | `blocked_no_seed_safe_cut` | 6 | 1 |
| pressure_single_monastery_mentor_probe_only | Monastery Mentor | `blocked_no_seed_safe_cut` | 0 | 1 |

## Candidate Cards

| Card | Decision | Trigger Count | Events |
| --- | --- | ---: | ---: |
| Guttersnipe | `hypothesis_natural_trigger_signal_no_seed_safe_cut` | 7 | 9 |
| Young Pyromancer | `hypothesis_natural_trigger_signal_no_seed_safe_cut` | 6 | 10 |
| Monastery Mentor | `blocked_near_access_only_no_seed_safe_cut` | 0 | 0 |
| Storm-Kiln Artist | `hypothesis_natural_cast_signal_no_seed_safe_cut` | 0 | 2 |

## Cut Context

- seed_safe_cuts: `[]`
- same_lane_only_cut_cards: `["Bender's Waterskin", "Creative Technique"]`
- protected_anchor_cuts: `["Bender's Waterskin", "Creative Technique", "Molecule Man", "The Mind Stone", "The Scarlet Witch", "Victory Chimes"]`

## External Support

- GameTyrant Lorehold deck tech: https://gametyrant.com/news/how-to-build-a-lorehold-the-historian-commander-deck-deck-tech
- EDHREC Lorehold Commander page: https://edhrec.com/commanders/lorehold-the-historian
- EDHREC Boros Miracles budget article: https://edhrec.com/articles/lorehold-the-historian-boros-miracles-on-a-budget

## Decision

- keep_607_as_protected_baseline: `true`
- promotion_allowed: `false`
- reason: The natural trigger signal is real for Guttersnipe and Young Pyromancer, but the active 607 cut model still has zero seed-safe cuts. The next valid work is cut-safety expansion or a separate full-shell contract, not a natural battle gate.
- next_actions:
  - do_not_stage_or_battle_the_micro_package_until_seed_safe_cuts_exist
  - treat Guttersnipe and Young Pyromancer as the current smallest pressure hypothesis
  - preserve Bender's Waterskin and Creative Technique despite same-lane-only status
  - mine failed and winning 607 traces for a genuinely low-risk nonpressure cut slot
