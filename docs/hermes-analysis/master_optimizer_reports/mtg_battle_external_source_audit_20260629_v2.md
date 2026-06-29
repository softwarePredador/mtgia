# MTG Battle External Source Audit

- Generated UTC: `2026-06-29T06:22:30+00:00`
- PostgreSQL writes: `False`
- Sources inventoried: `10`
- Requirements audited: `17`
- Gate status: `pass`
- Required gaps: `0`
- Required partials: `0`
- Optional gaps: `0`

## Source Inventory

| Source | Type | Reliability | Use | Do not use for |
| --- | --- | --- | --- | --- |
| [Magic: The Gathering Comprehensive Rules](https://media.wizards.com/2026/downloads/MagicCompRules%2020260619.txt) | `official_rules` | `authoritative` | Primary semantics for phases, priority, stack, combat, zones, state-based actions, replacement effects, and layers. | Card telemetry, deck performance, or player behavior frequency. |
| [Wizards Rules and Documents](https://magic.wizards.com/en/rules) | `official_index` | `authoritative_index` | Current official rules landing page and document freshness checks. | Executable card implementation details. |
| [MTG Arena detailed log support article](https://mtgarena-support.wizards.com/hc/en-us/articles/360000726823-Creating-Log-Files-on-PC-Mac-Steam) | `official_telemetry_availability` | `official_availability_not_schema_contract` | Evidence that Arena detailed logs exist and must be enabled for local telemetry collection. | Stable public schema, bulk corpus availability, or Commander strategy truth. |
| [gathering-gg MTG Arena log parser](https://github.com/gathering-gg/parser) | `open_source_log_parser_reference` | `community_parser_reference` | Implementation precedent for extracting local Arena log telemetry into structured local analysis. | Official schema guarantees, rules authority, or promotion without ManaLoom tests. |
| [Scryfall API](https://scryfall.com/docs/api) | `card_oracle_api` | `high_quality_card_metadata` | Oracle text, rulings endpoints, identifiers, and card search metadata. | Turn order, priority, stack execution, or battle outcome priors. |
| [MTGJSON v5](https://mtgjson.com/) | `bulk_card_data` | `high_quality_aggregated_metadata` | Bulk card, set, legality, keyword, and ruling-shaped data models. | Battle sequence telemetry or rules authority over Wizards documents. |
| [17Lands public datasets](https://www.17lands.com/public_datasets) | `public_game_history_corpus` | `high_for_arena_limited_telemetry` | Observed turn cadence, card access/use lifecycle, and game history priors. | Commander staples, exact Oracle semantics, or paper multiplayer metagame truth. |
| [Forge rules engine](https://github.com/Card-Forge/forge) | `independent_open_engine` | `useful_comparison_not_authority` | Independent implementation comparison for families not covered by XMage. | Replacing official rules or bypassing ManaLoom runtime tests. |
| [Cockatrice](https://github.com/Cockatrice/Cockatrice) | `open_client_and_replay_surface` | `manual_game_replay_reference` | Replay/client concepts and manual game-state references. | Automatic rules enforcement truth. |
| [Magarena](https://github.com/magarena/magarena) | `independent_open_engine` | `comparison_reference` | Additional card scripting and AI implementation comparison when XMage/Forge disagree or lack coverage. | Authoritative rule interpretation. |

## Requirement Coverage

| Requirement | Area | Required | Status | Evidence paths | Missing globs |
| --- | --- | ---: | --- | ---: | ---: |
| `official_rules_authority_anchored` | source hierarchy | `True` | `covered` | `2` | `0` |
| `turn_structure_and_phase_order` | turn structure | `True` | `covered` | `2` | `0` |
| `priority_stack_and_resolution` | priority and stack | `True` | `covered` | `3` | `0` |
| `casting_cost_target_legality` | casting, costs, and targets | `True` | `covered` | `3` | `0` |
| `combat_step_model` | combat | `True` | `covered` | `2` | `0` |
| `state_based_actions` | state-based actions | `True` | `covered` | `2` | `0` |
| `replacement_and_prevention_effects` | replacement and prevention | `True` | `covered` | `2` | `0` |
| `continuous_effect_layers` | continuous effects and layers | `True` | `covered` | `2` | `0` |
| `triggered_ability_resolution` | triggered abilities | `True` | `covered` | `2` | `0` |
| `zone_transition_ledger` | zones | `True` | `covered` | `2` | `0` |
| `commander_and_deck_legality` | Commander constraints | `True` | `covered` | `2` | `0` |
| `oracle_rulings_metadata_pipeline` | Oracle/rulings metadata | `True` | `covered` | `3` | `0` |
| `xmage_semantic_family_absorption` | XMage source absorption | `True` | `covered` | `4` | `0` |
| `seventeenlands_history_learning` | public battle history learning | `True` | `covered` | `4` | `0` |
| `structured_replay_and_event_contracts` | structured replay logs | `True` | `covered` | `3` | `0` |
| `mtga_player_log_ingestion` | local Arena Player.log ingestion | `False` | `covered` | `2` | `0` |
| `independent_engine_crosscheck_beyond_xmage` | independent engine comparison | `False` | `covered` | `2` | `0` |

## Method Notes

- Official Wizards rules remain the authority for runtime semantics.
- Scryfall and MTGJSON are metadata/rulings inputs, not battle-order authorities.
- 17Lands and Player.log-style sources are telemetry inputs; they can expose cadence and coverage gaps but do not define card rules.
- Open engines such as Forge, Magarena, and Cockatrice are comparison references only.
