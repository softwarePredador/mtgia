# Global Commander Battle Feedback Model

- generated_at: `2026-07-06T13:27:29.765730+00:00`
- status: `pass`
- battle_or_optimization_performed: `False`
- mutation_allowed: `False`
- promotion_allowed: `False`
- pair_count: `3`
- package_count: `3`
- blocked_pair_count: `0`
- blocked_package_count: `3`
- needs_exposure_pair_count: `3`
- needs_exercise_package_count: `0`
- ready_pair_count: `0`

## Pair Feedback

| Status | Commander | Deck | Add | Cut | Worst Delta | Best Delta | Observations | Recommendation |
| --- | --- | --- | --- | --- | ---: | ---: | ---: | --- |
| `pair_needs_exposure_replay_before_gate` | `Lorehold, the Historian` | `612` | `Ash Barrens, Bant Panorama, Battlefield Forge, Brokers Hideout, Cabaretti Courtyard, Demolition Field, Escape Tunnel, Evolving Wilds, Sunbaked Canyon` | `Agate Instigator, Ancient Gold Dragon, Artist's Talent, Brass's Bounty, Jeska's Will, Longshot, Rebel Bowman, Starfall Invocation, Storm-Kiln Artist, Warleader's Call` | 100.0 | 100.0 | 1 | `run_exposure_replay_or_focused_test_before_candidate_gate` |
| `pair_needs_exposure_replay_before_gate` | `Lorehold, the Historian` | `612` | `Bant Panorama, Birgi, God of Storytelling // Harnfel, Horn of Bounty, Brokers Hideout, Call Forth the Tempest, Pyromancer's Goggles` | `Artist's Talent, Brass's Bounty, Jeska's Will, Starfall Invocation, Storm-Kiln Artist` | 100.0 | 100.0 | 1 | `run_exposure_replay_or_focused_test_before_candidate_gate` |
| `pair_needs_exposure_replay_before_gate` | `Lorehold, the Historian` | `616` | `Bant Panorama, Boros Signet, Brokers Hideout` | `Boltwave, Guttersnipe, Worldfire` | 0.0 | 0.0 | 1 | `run_exposure_replay_or_focused_test_before_candidate_gate` |

## Package Feedback

| Status | Classification | Commander | Deck | Adds | Cuts | Protected Delta | Immediate Delta | Unexercised Adds | Recommendation |
| --- | --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `package_blocked_by_protected_baseline_gate` | `package_improved_weak_base_but_failed_protected_baseline` | `Lorehold, the Historian` | `612` | `Ash Barrens, Bant Panorama, Battlefield Forge, Birgi, God of Storytelling // Harnfel, Horn of Bounty, Brokers Hideout, Cabaretti Courtyard, Call Forth the Tempest, Demolition Field, Escape Tunnel, Evolving Wilds, Pyromancer's Goggles, Sunbaked Canyon` | `Agate Instigator, Ancient Gold Dragon, Artist's Talent, Birgi, God of Storytelling // Harnfel, Horn of Bounty, Brass's Bounty, Call Forth the Tempest, Jeska's Will, Longshot, Rebel Bowman, Pyromancer's Goggles, Starfall Invocation, Storm-Kiln Artist, Warleader's Call` | -6 | 1 | `-` | `block_package_until_new_source_lane_cut_or_strategy` |
| `package_blocked_by_protected_baseline_gate` | `package_improved_weak_base_but_failed_protected_baseline` | `Lorehold, the Historian` | `612` | `Bant Panorama, Birgi, God of Storytelling // Harnfel, Horn of Bounty, Brokers Hideout, Call Forth the Tempest, Pyromancer's Goggles` | `Artist's Talent, Brass's Bounty, Jeska's Will, Starfall Invocation, Storm-Kiln Artist` | -3 | 2 | `Call Forth the Tempest` | `block_package_until_new_source_lane_cut_or_strategy` |
| `package_blocked_by_protected_baseline_gate` | `package_improved_weak_base_but_failed_protected_baseline` | `Lorehold, the Historian` | `616` | `Arid Mesa, Ash Barrens, Bant Panorama, Battlefield Forge, Boros Signet, Brokers Hideout, Cabaretti Courtyard, Sunbaked Canyon` | `Boltwave, Coruscation Mage, Explosive Singularity, Guttersnipe, Rise of the Eldrazi, Soul Immolation, Stuffy Doll, Worldfire` | -3 | 3 | `-` | `block_package_until_new_source_lane_cut_or_strategy` |

## Policy

- exact_pair_memory: An exact add/cut pair rejected by equal battle evidence is blocked until a new source lane, cut, or package hypothesis changes the pair.
- exact_package_memory: An exact package rejected by a protected-baseline larger gate is blocked until a new source lane, cut set, or strategy hypothesis changes the package.
- protected_baseline_supersession: A candidate package that improves a weak immediate shell but loses to a protected benchmark is negative global learning, not promotion evidence.
- small_probe_supersession: A small positive probe is superseded when a larger equal gate for the same add/cut pair underperforms.
- card_exposure: Added cards must be exercised in replay events before the result can teach card-level value.
- review_only: This model is a learning feedback layer and cannot materialize, battle, mutate, or promote a deck.
