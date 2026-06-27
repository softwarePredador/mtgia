# Lorehold Manual Cut Review - 2026-06-27

- Generated at: `2026-06-27T23:18:03Z`
- Strategy audit: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260627_v3.json`
- Cut model: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_variant_gap_miner_20260627_v2_cut_model.json`
- Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Manual cut reviews: `3`
- Contextual lane reviews: `2`
- Decision counts: `{"do_not_cut_current_champion_engine": 2, "manual_review_role_gap_before_gate": 1, "tutor_lane_probation_needs_seed_safe_cut": 2}`
- Automatic gate-ready count: `0`
- Safe next action: Do not spend a gate on Squee/Emeria cuts yet; find a non-engine cut or run a targeted exposure gate that measures the unresolved role first.

## External Research Used As Heuristic Context

- [EDHREC - Miracles Every Turn With Lorehold, the Historian](https://edhrec.com/articles/miracles-every-turn-with-lorehold-the-historian-in-commander): Lorehold's core loop is first-draw miracle timing, opponent-upkeep rummage, topdeck manipulation, Library of Leng, and high-impact instant/sorcery hits.
- [EDHREC - Lorehold, the Historian: Boros Miracles on a Budget](https://edhrec.com/articles/lorehold-the-historian-boros-miracles-on-a-budget): The deck needs a high instant/sorcery density so miracle draws do not become dead non-spell hits.
- [Card Kingdom - 10 Crazy Synergy Cards for Lorehold, the Historian](https://blog.cardkingdom.com/10-crazy-synergy-cards-for-lorehold-the-historian-secrets-of-strixhaven/): Community deck tech highlights Library of Leng and reanimation/discard routes as real Lorehold subpackages.
- [Reddit r/EDHBrews - Commander Deck Tech: Lorehold, the Historian](https://www.reddit.com/r/EDHBrews/comments/1ssny05/commander_deck_tech_lorehold_the_historian/): Community discussion reinforces discard, topdeck control, suspend/miracle, and reanimation as plausible lanes, but not as promotion evidence by itself.

## Manual Cut Reviews

| Candidate | Proposed Cut | Decision | Action | Main Reasons |
| --- | --- | --- | --- | --- |
| Volcanic Vision | Squee, Goblin Nabob | `do_not_cut_current_champion_engine` | `blocked` | Squee is the current champion's probation recursion engine.; Squee's graveyard return is already materialized in the equal-gate candidate.; Variant recursion cards must prove a non-Squee cut or a multi-card recursion package. |
| Restoration Seminar | Squee, Goblin Nabob | `do_not_cut_current_champion_engine` | `blocked` | Squee is the current champion's probation recursion engine.; Squee's graveyard return is already materialized in the equal-gate candidate.; Variant recursion cards must prove a non-Squee cut or a multi-card recursion package. |
| Austere Command | Emeria's Call // Emeria, Shattered Skyclave | `manual_review_role_gap_before_gate` | `manual_review` | Emeria has a ready local rule but still needs durable role sync.; Emeria's strategic role is still unknown, so cutting it hides whether the deck needs board/protection density.; Austere-style board wipes can be tested only after Emeria exposure/role is measured or a safer cut is found. |

## Contextual Lane Reviews

| Candidate | Decision | Action | Prior Evidence | Cut Search |
| --- | --- | --- | --- | --- |
| Enlightened Tutor | `tutor_lane_probation_needs_seed_safe_cut` | `manual_review` | enlightened_engine_access_cut_thor: -44.45 pp / strong seed -44.45 pp | Search artifact/enchantment access cuts separately; do not use Thor as the tutor-access cut. |
| Gamble | `tutor_lane_probation_needs_seed_safe_cut` | `manual_review` | gamble_approach_access_cut_creative: +3.70 pp / strong seed -44.45 pp; gamble_access_cut_thor: -55.56 pp / strong seed -55.56 pp | Keep Gamble on probation only if the cut does not touch Thor and does not repeat Creative Technique without a seed-42 protection explanation. |

## Next Actions

- P1 `preserve_squee_while_testing_recursion_variants`: Squee is an observed champion/probation recursion engine; Volcanic Vision and Restoration Seminar need another cut or multi-card package.
- P2 `measure_emeria_role_before_austere_command_cut`: Emeria has rule coverage but unknown strategic role; Austere Command cannot prove improvement if it deletes an unmeasured board/protection slot.
- P3 `rebuild_tutor_tests_around_seed_safe_cuts`: Gamble and Enlightened Tutor are runtime-ready, but prior tests over Thor/Creative regressed the protected seed.
