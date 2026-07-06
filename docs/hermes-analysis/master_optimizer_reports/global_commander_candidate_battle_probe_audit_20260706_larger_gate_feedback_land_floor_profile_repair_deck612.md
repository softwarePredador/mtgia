# Global Commander Candidate Battle Probe Audit

- generated_at: `2026-07-06T12:35:20.432295+00:00`
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

- added_cards: `['Ash Barrens', 'Bant Panorama', 'Battlefield Forge', 'Brokers Hideout', 'Cabaretti Courtyard', 'Demolition Field', 'Escape Tunnel', 'Evolving Wilds', 'Sunbaked Canyon']`
- cut_cards: `['Agate Instigator', 'Ancient Gold Dragon', "Artist's Talent", "Brass's Bounty", "Jeska's Will", 'Longshot, Rebel Bowman', 'Starfall Invocation', 'Storm-Kiln Artist', "Warleader's Call"]`

## Replay Evidence

- replay_dir: `docs/hermes-analysis/master_optimizer_reports/global_commander_candidate_battle_probe_runner_20260706_larger_gate_feedback_land_floor_profile_repair_deck612_replay`
- stale_lorehold_mentions: `0`
- added_cards_exercised_in_events: `['Escape Tunnel', 'Sunbaked Canyon']`
- added_cards_seen_without_exercise: `['Ash Barrens', 'Bant Panorama', 'Battlefield Forge', 'Brokers Hideout', 'Cabaretti Courtyard', 'Demolition Field', 'Evolving Wilds']`
- added_cards_decision_only: `[]`
- added_cards_unobserved: `[]`
- added_cards_unexercised_in_events: `['Ash Barrens', 'Bant Panorama', 'Battlefield Forge', 'Brokers Hideout', 'Cabaretti Courtyard', 'Demolition Field', 'Evolving Wilds']`

## Blockers

- `added_cards_not_exercised_in_replay_events`

## Policy

- battle_sample: The 1-game equal-sample probe/gate is diagnostic only and cannot promote a deck by itself.
- card_exposure: Added cards must be drawn/cast/used in replay events before card-level swap evidence is trusted.
- promotion: Promotion remains closed until larger equal battle gate and replay trace pass.
