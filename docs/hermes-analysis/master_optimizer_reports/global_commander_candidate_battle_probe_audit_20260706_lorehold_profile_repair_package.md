# Global Commander Candidate Battle Probe Audit

- generated_at: `2026-07-06T07:46:08.494123+00:00`
- status: `battle_probe_blocks_promotion`
- deck_id: `612`
- commander: `Lorehold, the Historian`
- promotion_allowed: `false`
- larger_battle_gate_required: `true`

## Battle Metrics

- base_wr: `0.0`
- candidate_wr: `100.0`
- win_rate_delta: `100.0`
- same_sample_shape: `true`

## Deck Diff

- added_cards: `['Bant Panorama', 'Birgi, God of Storytelling // Harnfel, Horn of Bounty', 'Brokers Hideout', 'Call Forth the Tempest', "Pyromancer's Goggles"]`
- cut_cards: `["Artist's Talent", "Brass's Bounty", "Jeska's Will", 'Starfall Invocation', 'Storm-Kiln Artist']`

## Replay Evidence

- replay_dir: `docs/hermes-analysis/master_optimizer_reports/global_commander_candidate_battle_probe_runner_20260706_lorehold_profile_repair_package_replay`
- stale_lorehold_mentions: `0`
- added_cards_exercised_in_events: `['Call Forth the Tempest']`
- added_cards_seen_without_exercise: `['Bant Panorama', 'Birgi, God of Storytelling // Harnfel, Horn of Bounty', 'Brokers Hideout', "Pyromancer's Goggles"]`
- added_cards_decision_only: `[]`
- added_cards_unobserved: `[]`
- added_cards_unexercised_in_events: `['Bant Panorama', 'Birgi, God of Storytelling // Harnfel, Horn of Bounty', 'Brokers Hideout', "Pyromancer's Goggles"]`

## Blockers

- `added_cards_not_exercised_in_replay_events`

## Policy

- battle_sample: The 1-game equal-sample probe/gate is diagnostic only and cannot promote a deck by itself.
- card_exposure: Added cards must be drawn/cast/used in replay events before card-level swap evidence is trusted.
- promotion: Promotion remains closed until larger equal battle gate and replay trace pass.
