# Global Commander External Exact Artifact Engine Source Expander

- generated_at: `2026-07-06T04:43:11.362113+00:00`
- status: `external_exact_artifact_engine_source_lanes_expanded_no_deck_action`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- source_query_count: `5`
- fetched_query_count: `5`
- external_candidate_count: `8`
- ready_for_local_review_count: `5`
- candidate_copy_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `review_external_exact_artifact_engine_candidates_locally_before_candidate_copy`

## Source Queries

| Query | Status | Total | URL |
| --- | --- | ---: | --- |
| `legal:commander id<=wbr o:"whenever you cast an artifact spell"` | `fetched` | 9 | https://api.scryfall.com/cards/search?unique=cards&order=name&q=legal%3Acommander%20id%3C%3Dwbr%20o%3A%22whenever%20you%20cast%20an%20artifact%20spell%22 |
| `legal:commander id<=wbr o:"artifact spells you cast"` | `fetched` | 3 | https://api.scryfall.com/cards/search?unique=cards&order=name&q=legal%3Acommander%20id%3C%3Dwbr%20o%3A%22artifact%20spells%20you%20cast%22 |
| `legal:commander id<=wbr o:"creatures you control are artifacts"` | `fetched` | 1 | https://api.scryfall.com/cards/search?unique=cards&order=name&q=legal%3Acommander%20id%3C%3Dwbr%20o%3A%22creatures%20you%20control%20are%20artifacts%22 |
| `legal:commander id<=wbr o:"creature spells you control"` | `fetched` | 4 | https://api.scryfall.com/cards/search?unique=cards&order=name&q=legal%3Acommander%20id%3C%3Dwbr%20o%3A%22creature%20spells%20you%20control%22 |
| `legal:commander id<=wbr o:"artifact spell"` | `fetched` | 37 | https://api.scryfall.com/cards/search?unique=cards&order=name&q=legal%3Acommander%20id%3C%3Dwbr%20o%3A%22artifact%20spell%22 |

## External Candidates

| Card | Status | Signals | Color | Blockers |
| --- | --- | --- | --- | --- |
| `Digsite Engineer` | `external_exact_engine_candidate_ready_for_local_review` | `artifact_spell_token_payoff` | `W` | - |
| `Golem Foundry` | `external_exact_engine_candidate_ready_for_local_review` | `artifact_spell_token_payoff` | `` | - |
| `Myrsmith` | `external_exact_engine_candidate_ready_for_local_review` | `artifact_spell_token_payoff` | `W` | - |
| `Poetic Ingenuity` | `external_exact_engine_candidate_ready_for_local_review` | `artifact_spell_token_payoff` | `R` | - |
| `Ravenous Robots` | `external_exact_engine_candidate_ready_for_local_review` | `artifact_spell_token_payoff` | `R` | - |
| `Biotransference` | `exact_type_conversion_engine_candidate` | `artifact_spell_token_payoff,artifact_type_conversion_engine` | `B` | already_in_current_deck |
| `Foundry Inspector` | `artifact_spell_support_not_biotransference_replacement` | `artifact_spell_cost_reducer` | `` | support_only_no_token_or_draw_payoff |
| `Voyager Quickwelder` | `artifact_spell_support_not_biotransference_replacement` | `artifact_spell_cost_reducer` | `W` | support_only_no_token_or_draw_payoff |

## Blockers

- `candidate_copy_closed_after_external_exact_engine_source_expansion`

## Policy

- external_source_boundary: Scryfall Oracle search is external source-lane evidence, not deck permission.
- same_lane_boundary: Candidates still need local review, current-deck trace, and exact add/cut proof before candidate copy.
- mutation_boundary: This expander reads local deck membership and remote Scryfall data only.
