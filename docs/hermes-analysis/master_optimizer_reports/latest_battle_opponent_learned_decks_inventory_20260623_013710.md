# Latest Battle Opponent Learned Deck Inventory

Generated at: `2026-06-23T01:38:47.622368+00:00`

- source_summary_path: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- source_latest_dir: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest`
- run_profile: `lorehold_variant01_deck606_16_seed_trusted_final`
- battle_replay_final_status: `trusted_for_strategy_learning`
- seeds_completed: `16`
- seed_count_with_provenance: `16`
- unique_learned_opponent_deck_count: `12`
- apply: `False`

## Identity Coverage

- card_instances: `1200`
- resolved_instances: `1151`
- oracle_resolved_instances: `49`
- unresolved_instances: `0`
- ambiguous_instances: `0`
- resolution_coverage: `0.959167`
- semantic_identity_coverage: `1.0`
- unique_names: `488`
- resolved_unique_names: `479`
- oracle_resolved_unique_names: `9`
- ambiguous_unique_names: `0`

## Opponent Decks

| Learned deck | Appearances | Commander | Archetype | Expanded | Resolved | Oracle resolved | Unresolved | Ambiguous |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: |
| 25 | 5 | Tayam, Luminous Enigma | aristocrats | 100 | 96 | 4 | 0 | 0 |
| 31 | 4 | Sisay, Weatherlight Captain | combo | 100 | 96 | 4 | 0 | 0 |
| 42 | 5 | The Emperor of Palamecia | ramp_value | 100 | 99 | 1 | 0 | 0 |
| 54 | 2 | Thrasios, Triton Hero | combo | 100 | 96 | 4 | 0 | 0 |
| 58 | 4 | Thrasios, Triton Hero | combo | 100 | 96 | 4 | 0 | 0 |
| 62 | 5 | Rograkh, Son of Rohgahh | combo | 100 | 95 | 5 | 0 | 0 |
| 74 | 3 | Dargo, the Shipwrecker | aggro | 100 | 96 | 4 | 0 | 0 |
| 83 | 2 | Kraum, Ludevic's Opus | combo | 100 | 97 | 3 | 0 | 0 |
| 84 | 4 | Kinnan, Bonder Prodigy | control | 100 | 95 | 5 | 0 | 0 |
| 104 | 5 | Kinnan, Bonder Prodigy | control | 100 | 94 | 6 | 0 | 0 |
| 105 | 3 | Etali, Primal Conqueror | aggro | 100 | 95 | 5 | 0 | 0 |
| 116 | 6 | Tayam, Luminous Enigma | aristocrats | 100 | 96 | 4 | 0 | 0 |

## Top Resolver Issues

- unresolved_top: `[]`
- ambiguous_top: `[]`

## Notes

- Report-only inventory of learned_decks used as opponents in the latest battle-strategy-audit artifact.
- PostgreSQL was queried by the identity resolver only for card identity coverage; no rows were mutated.
- This recut is exact for the latest/seed_*/deck_provenance.json files, not a random learned_decks sample.
