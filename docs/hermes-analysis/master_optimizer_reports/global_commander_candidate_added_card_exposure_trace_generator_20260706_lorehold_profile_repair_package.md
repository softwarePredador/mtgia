# Global Commander Candidate Added Card Exposure Trace Generator

- generated_at: `2026-07-06T07:46:27.253398+00:00`
- status: `candidate_added_card_forced_exposure_all_exercised_diagnostic_only`
- commander: `Lorehold, the Historian`
- deck_id: `612`
- focus_card_count: `4`
- focus_cards: `Bant Panorama, Birgi, God of Storytelling // Harnfel, Horn of Bounty, Brokers Hideout, Pyromancer's Goggles`
- seed_count: `3`
- generated_replay_count: `3`
- forced_access_mode: `opening_hand`
- exercised_added_cards: `['Bant Panorama', 'Birgi, God of Storytelling // Harnfel, Horn of Bounty', 'Brokers Hideout', "Pyromancer's Goggles"]`
- unexercised_added_cards: `[]`
- natural_gate_satisfied_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `seek_natural_replay_confirmation_before_larger_equal_gate`

## Review Rows

| Card | Status | Forced Present | Exercise | Exposure | Decisions | Next Gate |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| `Bant Panorama` | `forced_added_card_exercised_diagnostic_only` | 3 | 3 | 128 | 0 | `seek_natural_replay_or_larger_equal_gate_after_forced_diagnostic` |
| `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `forced_added_card_exercised_diagnostic_only` | 3 | 21 | 128 | 24 | `seek_natural_replay_or_larger_equal_gate_after_forced_diagnostic` |
| `Brokers Hideout` | `forced_added_card_exercised_diagnostic_only` | 3 | 3 | 128 | 0 | `seek_natural_replay_or_larger_equal_gate_after_forced_diagnostic` |
| `Pyromancer's Goggles` | `forced_added_card_exercised_diagnostic_only` | 3 | 4 | 128 | 38 | `seek_natural_replay_or_larger_equal_gate_after_forced_diagnostic` |

## Blockers

- `forced_access_is_diagnostic_not_natural_gate`

## Policy

- forced_access_boundary: Forced access is diagnostic evidence only; it is not a natural battle gate.
- added_card_boundary: An added card must be exercised in target-deck events before its swap evidence is trusted.
- promotion_boundary: No candidate copy, deck mutation, battle gate, or promotion is opened by this report.
