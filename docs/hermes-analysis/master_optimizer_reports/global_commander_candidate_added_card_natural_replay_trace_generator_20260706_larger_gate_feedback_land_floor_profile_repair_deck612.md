# Global Commander Candidate Added Card Natural Replay Trace Generator

- generated_at: `2026-07-06T12:36:07.456074+00:00`
- status: `candidate_added_card_natural_replay_all_exercised_ready_for_larger_gate`
- commander: `Lorehold, the Historian`
- deck_id: `612`
- focus_card_count: `7`
- focus_cards: `Ash Barrens, Bant Panorama, Battlefield Forge, Brokers Hideout, Cabaretti Courtyard, Demolition Field, Evolving Wilds`
- seed_count: `10`
- generated_replay_count: `10`
- exercised_added_cards: `['Ash Barrens', 'Bant Panorama', 'Battlefield Forge', 'Brokers Hideout', 'Cabaretti Courtyard', 'Demolition Field', 'Evolving Wilds']`
- unexercised_added_cards: `[]`
- forced_access_used: `false`
- larger_battle_gate_allowed_next: `true`
- promotion_allowed: `false`
- next_gate: `run_larger_equal_battle_gate`

## Review Rows

| Card | Status | Exercise | Exposure | Decisions | Next Gate |
| --- | --- | ---: | ---: | ---: | --- |
| `Ash Barrens` | `natural_added_card_exercised` | 3 | 407 | 3 | `include_in_larger_equal_gate_candidate_package` |
| `Bant Panorama` | `natural_added_card_exercised` | 1 | 407 | 0 | `include_in_larger_equal_gate_candidate_package` |
| `Battlefield Forge` | `natural_added_card_exercised` | 1 | 407 | 1 | `include_in_larger_equal_gate_candidate_package` |
| `Brokers Hideout` | `natural_added_card_exercised` | 2 | 407 | 4 | `include_in_larger_equal_gate_candidate_package` |
| `Cabaretti Courtyard` | `natural_added_card_exercised` | 3 | 407 | 2 | `include_in_larger_equal_gate_candidate_package` |
| `Demolition Field` | `natural_added_card_exercised` | 3 | 407 | 3 | `include_in_larger_equal_gate_candidate_package` |
| `Evolving Wilds` | `natural_added_card_exercised` | 5 | 407 | 3 | `include_in_larger_equal_gate_candidate_package` |

## Larger Gate Blockers

- none

## Policy

- natural_replay_boundary: This report collects natural replay evidence only; it does not run the larger battle gate.
- larger_gate_boundary: A larger equal battle gate may run only after blocker adds are naturally exercised or the package is revised.
- promotion_boundary: No deck mutation or promotion is opened by this report.
