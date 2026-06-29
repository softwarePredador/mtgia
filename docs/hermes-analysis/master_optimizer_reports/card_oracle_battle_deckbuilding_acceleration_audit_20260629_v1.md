# Card Oracle, Battle, and Deckbuilding Acceleration Audit

- Generated UTC: `2026-06-29T07:50:22+00:00`
- PostgreSQL writes: `False`
- Sources mapped: `14`
- Project needs audited: `8`
- Gate status: `pass`
- Gaps: `0`
- Partials: `0`

## Source Roles

| Source | Authority | Best for | Not for | Cache policy |
| --- | --- | --- | --- | --- |
| [Scryfall bulk Oracle Cards and Rulings](https://api.scryfall.com/bulk-data) | `card_metadata_high` | oracle_identity_faces, oracle_text, layout, rulings | turn_rules, battle_outcome, commander_meta | cache bulk snapshots; use named lookups only for focused gaps |
| [MTGJSON v5](https://mtgjson.com/api/v5/) | `card_metadata_aggregate` | bulk_cards, legalities, rulings, identifiers | battle_execution_truth, player_intent | cache AtomicCards/AllPrintings; never fetch per-card in hot path |
| [Wizards Comprehensive Rules](https://magic.wizards.com/en/rules) | `official_rules` | turn_rules, priority, stack, layers, state_based_actions | card_popularity, deck_strength, observed_player_behavior | pin rules version in tests and update intentionally |
| [Local XMage source tree](file:///Users/desenvolvimentomobile/Downloads/mage-master) | `implementation_reference_not_authority` | battle_family_mapping, card_implementation_examples, test_scenarios | official_rules_override, direct_pg_promotion_without_tests | index locally and map by semantic family |
| [Forge rules engine](https://github.com/Card-Forge/forge) | `independent_engine_crosscheck` | battle_family_crosscheck, implementation_disagreement_detection | official_rules_override, deckbuilding_meta | use as optional crosscheck when XMage is missing or ambiguous |
| [17Lands public datasets](https://www.17lands.com/public_datasets) | `observed_arena_limited_telemetry` | event_sequence_priors, card_lifecycle_metrics, draw_seen_cast_use_methodology | commander_meta, oracle_text, card_rules_authority | cache snapshots; translate only general battle priors |
| [MTG Arena detailed Player.log](https://mtgarena-support.wizards.com/hc/en-us/articles/360000726823-Creating-Log-Files-on-PC-Mac-Steam) | `local_user_telemetry` | local_replay_ingestion, event_shape_reference, turn_and_action_observation | public_bulk_corpus, privacy_unsafe_raw_storage | parse read-only and do not persist raw player identifiers |
| [Commander Spellbook bulk variants](https://json.commanderspellbook.com/variants.json) | `combo_database` | combo_detection, near_miss_combo_suggestions, combo_piece_tags | non_combo_card_quality, battle_rules_authority | sync offline into card_combos; runtime reads PostgreSQL only |
| [EDHREC JSON pages](https://json.edhrec.com/pages/commanders/lorehold-the-historian.json) | `commander_deckbuilding_meta` | commander_roles, average_deck_structure, community_inclusion | oracle_rules, battle_execution_truth | snapshot aggregate stats; never copy full decklists into prompts |
| [MTGTop8 EDH/cEDH event exports](https://www.mtgtop8.com/format?f=cEDH) | `competitive_event_corpus` | competitive_reference_decks, event_decklists, meta_candidates | multiplayer_commander_default, oracle_rules, casual_role_targets | ingest through vetted meta_decks/candidate pipeline only |
| [EDHTop16 public tournament data](https://edhtop16.com/) | `cedh_tournament_corpus` | cedh_reference_decks, tournament_standings, external_meta_candidates | casual_commander_default, oracle_rules, battle_execution_truth | expand into external candidates, then promote only after validation |
| [cEDH Decklist Database](https://cedh-decklist-database.com/) | `curated_cedh_reference` | cedh_archetype_reference, known_shells, power_lane_context | casual_commander_default, card_rules, raw_prompt_deck_copy | use for research/context until an approved importer exists |
| [Archidekt public deck pages](https://archidekt.com/) | `community_deck_corpus_candidate` | community_reference_decks, package_discovery, human_deckbuilding_examples | oracle_rules, battle_execution_truth, unguarded_prompt_copy | candidate only; sanitize and aggregate before persistence |
| [Moxfield public deck pages](https://www.moxfield.com/) | `community_deck_corpus_candidate_blocked_in_probe` | community_reference_decks, package_discovery, human_deckbuilding_examples | oracle_rules, battle_execution_truth, unguarded_prompt_copy | candidate only; current simple probe returned 403 so do not automate without approved access |

## Local Coverage

| Need | Status | Acceleration | Existing paths | Missing paths | Missing keyword groups |
| --- | --- | ---: | ---: | ---: | ---: |
| `oracle_identity_faces` | `covered` | `100` | `3` | `0` | `0` |
| `oracle_rulings_hash` | `covered` | `88` | `3` | `0` | `0` |
| `battle_runtime_family_mapping` | `covered` | `95` | `3` | `0` | `0` |
| `needs_review_execution_guard` | `covered` | `80` | `3` | `0` | `0` |
| `observed_battle_log_learning` | `covered` | `72` | `3` | `0` | `0` |
| `deckbuilding_combo_and_meta` | `covered` | `90` | `5` | `0` | `0` |
| `reference_deck_corpus_sanitization` | `covered` | `82` | `5` | `0` | `0` |
| `source_conflict_resolution` | `covered` | `84` | `3` | `0` | `0` |

## Queue

All required acceleration surfaces are covered.

## Operating Rules

- Scryfall/MTGJSON resolve Oracle identity, faces, legalities, and rulings.
- Wizards rules define battle semantics; XMage and Forge only propose implementation candidates.
- Commander Spellbook proves combo relations; EDHREC calibrates Commander structure and inclusion.
- 17Lands and MTGA logs provide behavior priors, not Commander truth or Oracle rules.
- PostgreSQL remains the source of truth; Hermes/runtime mirrors must not overwrite reviewed DB state.
