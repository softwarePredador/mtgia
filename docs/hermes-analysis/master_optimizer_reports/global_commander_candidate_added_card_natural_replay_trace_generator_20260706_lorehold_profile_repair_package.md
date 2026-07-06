# Global Commander Candidate Added Card Natural Replay Trace Generator

- generated_at: `2026-07-06T09:50:05.557556+00:00`
- status: `candidate_added_card_natural_replay_all_exercised_ready_for_larger_gate`
- commander: `Lorehold, the Historian`
- deck_id: `612`
- focus_card_count: `4`
- focus_cards: `Bant Panorama, Birgi, God of Storytelling // Harnfel, Horn of Bounty, Brokers Hideout, Pyromancer's Goggles`
- seed_count: `5`
- generated_replay_count: `5`
- exercised_added_cards: `['Bant Panorama', 'Birgi, God of Storytelling // Harnfel, Horn of Bounty', 'Brokers Hideout', "Pyromancer's Goggles"]`
- unexercised_added_cards: `[]`
- forced_access_used: `false`
- larger_battle_gate_allowed_next: `true`
- promotion_allowed: `false`
- next_gate: `run_larger_equal_battle_gate`

## Review Rows

| Card | Status | Exercise | Exposure | Decisions | Next Gate |
| --- | --- | ---: | ---: | ---: | --- |
| `Bant Panorama` | `natural_added_card_exercised` | 1 | 185 | 0 | `include_in_larger_equal_gate_candidate_package` |
| `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `natural_added_card_exercised` | 4 | 185 | 12 | `include_in_larger_equal_gate_candidate_package` |
| `Brokers Hideout` | `natural_added_card_exercised` | 1 | 185 | 1 | `include_in_larger_equal_gate_candidate_package` |
| `Pyromancer's Goggles` | `natural_added_card_exercised` | 4 | 185 | 31 | `include_in_larger_equal_gate_candidate_package` |

## Larger Gate Blockers

- none

## Policy

- natural_replay_boundary: This report collects natural replay evidence only; it does not run the larger battle gate.
- larger_gate_boundary: A larger equal battle gate may run only after blocker adds are naturally exercised or the package is revised.
- promotion_boundary: No deck mutation or promotion is opened by this report.
