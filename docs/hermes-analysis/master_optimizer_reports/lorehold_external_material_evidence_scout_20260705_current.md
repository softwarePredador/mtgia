# Lorehold External Material Evidence Scout

- Generated at: `2026-07-05T01:31:25Z`
- Status: `external_material_evidence_found_but_no_gate_ready_keep_607`
- Current baseline: `deck_607`
- Source DB mutated: `False`
- Deck 607 mutated: `False`

## Summary

| Metric | Value |
| --- | ---: |
| `external_source_count` | `6` |
| `external_candidate_count` | `24` |
| `in_607_count` | `0` |
| `local_lorehold_variant_candidate_count` | `10` |
| `rule_known_external_not_in_lorehold_candidate_pool_count` | `1` |
| `missing_from_local_deck_pool_count` | `13` |
| `archetype_fork_candidate_count` | `9` |
| `gate_ready_now_count` | `0` |

## External Source Lanes

| Source | Route | Candidate Cards | Learning |
| --- | --- | --- | --- |
| [EDHREC Lorehold upgraded spellslinger page](https://edhrec.com/commanders/lorehold-the-historian/upgraded/spellslinger) | `reference_corpus` | Storm-Kiln Artist, Guttersnipe, Young Pyromancer, Monastery Mentor, Surly Badgersaur, Goldspan Dragon, Glint-Horn Buccaneer, Inti, Seneschal of the Sun | The current public Lorehold surface is tagged Topdeck, Spellslinger, Discard, and Burn; high-synergy cards still point toward topdeck, miracle, big-spell conversion, and pressure payoffs. |
| [GameTyrant Lorehold deck tech](https://gametyrant.com/news/how-to-build-a-lorehold-the-historian-commander-deck-deck-tech) | `topdeck_pressure_reference` | Brain in a Jar, Galvanoth, Burning Prophet, Dragon's Rage Channeler, Planetarium of Wan Shi Tong, Entreat the Angels | The article reinforces Library of Leng, miracle setup, topdeck control, alternate casting, and pressure conversion rather than generic Boros goodstuff. |
| [Card Kingdom Lorehold synergy cards](https://blog.cardkingdom.com/10-crazy-synergy-cards-for-lorehold-the-historian-secrets-of-strixhaven/) | `archetype_fork` | Storm of Souls, Late to Dinner, Miraculous Recovery, Karmic Guide | A reanimator build is a separate direction: expensive white reanimation spells and Karmic Guide can exploit discard and cost reduction, but that is not a one-card update to the current 607 shell. |
| [CoolStuffInc Lorehold commander article](https://www.coolstuffinc.com/a/stephenjohnson-04202026-lorehold-the-historian-commander) | `archetype_fork` | Anointed Procession, Cathars' Crusade, Blackblade Reforged, Strata Scythe, Excalibur, Sword of Eden | The article frames token swarm, combo, burn/damage, and Voltron as directions beyond the instant/sorcery shell. These need full-shell contracts, not isolated cuts from 607. |
| [Commander Spellbook Storm-Kiln Artist + Haze of Rage](https://commanderspellbook.com/combo/3940-5195/) | `combo_package` | Storm-Kiln Artist, Haze of Rage | Storm-Kiln Artist plus Haze of Rage is a red combo lane with mana, storm, magecraft, Treasure, and creature-power outputs. It remains a package hypothesis until local identity, runtime, cuts, and natural battle proof all exist. |
| [Archidekt Lorehold commander search](https://archidekt.com/commanders/Lorehold%2C_the_Historian) | `reference_corpus` | source_lane_only | The public corpus is broad and fresh enough to mine, but raw public deck presence is only reference evidence until normalized into local identity, legality, lane, and battle-gate artifacts. |

## Candidate Classification

| Card | Classification | Actionability | 607 | Lorehold Variants | Rules |
| --- | --- | --- | ---: | --- | ---: |
| Anointed Procession | `external_missing_from_local_deck_pool` | `archetype_fork_only_requires_full_shell_contract` | `False` | - | `0` |
| Blackblade Reforged | `external_missing_from_local_deck_pool` | `archetype_fork_only_requires_full_shell_contract` | `False` | - | `0` |
| Brain in a Jar | `external_missing_from_local_deck_pool` | `requires_import_or_identity_resolution_before_deckbuilding_test` | `False` | - | `0` |
| Burning Prophet | `external_missing_from_local_deck_pool` | `requires_import_or_identity_resolution_before_deckbuilding_test` | `False` | - | `0` |
| Cathars' Crusade | `external_missing_from_local_deck_pool` | `archetype_fork_only_requires_full_shell_contract` | `False` | - | `0` |
| Entreat the Angels | `external_missing_from_local_deck_pool` | `requires_import_or_identity_resolution_before_deckbuilding_test` | `False` | - | `0` |
| Excalibur, Sword of Eden | `external_missing_from_local_deck_pool` | `archetype_fork_only_requires_full_shell_contract` | `False` | - | `0` |
| Haze of Rage | `external_missing_from_local_deck_pool` | `combo_package_research_only_requires_runtime_cut_and_battle_proof` | `False` | - | `0` |
| Inti, Seneschal of the Sun | `external_missing_from_local_deck_pool` | `requires_import_or_identity_resolution_before_deckbuilding_test` | `False` | - | `0` |
| Late to Dinner | `external_missing_from_local_deck_pool` | `archetype_fork_only_requires_full_shell_contract` | `False` | - | `0` |
| Miraculous Recovery | `external_missing_from_local_deck_pool` | `archetype_fork_only_requires_full_shell_contract` | `False` | - | `0` |
| Storm of Souls | `external_missing_from_local_deck_pool` | `archetype_fork_only_requires_full_shell_contract` | `False` | - | `0` |
| Strata Scythe | `external_missing_from_local_deck_pool` | `archetype_fork_only_requires_full_shell_contract` | `False` | - | `0` |
| Dragon's Rage Channeler | `local_lorehold_variant_candidate_not_in_607` | `local_candidate_but_blocked_by_current_cut_safety_or_prior_route` | `False` | 609,613,614 | `1` |
| Galvanoth | `local_lorehold_variant_candidate_not_in_607` | `local_candidate_but_blocked_by_current_cut_safety_or_prior_route` | `False` | 611,613,614,615 | `1` |
| Glint-Horn Buccaneer | `local_lorehold_variant_candidate_not_in_607` | `local_candidate_but_blocked_by_current_cut_safety_or_prior_route` | `False` | 613 | `1` |
| Goldspan Dragon | `local_lorehold_variant_candidate_not_in_607` | `local_candidate_but_blocked_by_current_cut_safety_or_prior_route` | `False` | 608,611,614,615 | `1` |
| Guttersnipe | `local_lorehold_variant_candidate_not_in_607` | `local_candidate_but_blocked_by_current_cut_safety_or_prior_route` | `False` | 615,616 | `1` |
| Monastery Mentor | `local_lorehold_variant_candidate_not_in_607` | `local_candidate_but_blocked_by_current_cut_safety_or_prior_route` | `False` | 616 | `1` |
| Planetarium of Wan Shi Tong | `local_lorehold_variant_candidate_not_in_607` | `local_candidate_but_blocked_by_current_cut_safety_or_prior_route` | `False` | 611,613 | `1` |
| Storm-Kiln Artist | `local_lorehold_variant_candidate_not_in_607` | `combo_package_research_only_requires_runtime_cut_and_battle_proof` | `False` | 608,611,612,613,614 | `1` |
| Surly Badgersaur | `local_lorehold_variant_candidate_not_in_607` | `local_candidate_but_blocked_by_current_cut_safety_or_prior_route` | `False` | 608 | `1` |
| Young Pyromancer | `local_lorehold_variant_candidate_not_in_607` | `local_candidate_but_blocked_by_current_cut_safety_or_prior_route` | `False` | 612,616 | `1` |
| Karmic Guide | `rule_known_external_not_in_lorehold_candidate_pool` | `archetype_fork_only_requires_full_shell_contract` | `False` | - | `1` |

## Package Assessments

| Package | Route | Status | Natural Battle Allowed | Reason |
| --- | --- | --- | ---: | --- |
| `storm_kiln_artist_haze_of_rage_combo` | `combo_package` | `research_only_mixed_local_and_missing_material` | `False` | Storm-Kiln Artist is visible locally, but Haze of Rage is not a current local Lorehold deck candidate. Even if imported, the package still needs cut-safety, runtime scope, and natural battle proof. |
| `white_reanimator_lorehold_shell` | `archetype_fork` | `archetype_fork_only_requires_full_shell_contract` | `False` | This changes the deck thesis toward reanimator and cannot justify one-for-one cuts from 607. |
| `voltron_or_token_closure_shell` | `archetype_fork` | `archetype_fork_only_requires_full_shell_contract` | `False` | This is a new closure plan, not direct evidence that a protected 607 anchor should be cut. |

## Decision

- Keep 607 as protected baseline: `True`
- Natural battle allowed now: `False`
- Promotion allowed: `False`
- Reason: External sources add real learning lanes, but the current internal state still has zero seed-safe cuts, prior natural rejects on the only same-lane static package, and no package that is ready for a natural battle gate.

## Next Actions

- do_not_mutate_or_replace_deck_607
- run identity/import preflight for missing material cards before any deck test
- separate archetype forks from one-for-one 607 cut work
- keep Storm-Kiln/Haze as combo research until Haze exists locally and a safe package is declared
- rerun safe-cut logic only after material evidence changes a candidate or cut row
