# Lorehold Cut Methodology Reaudit - 2026-06-29

- status: `ready`
- postgres_writes: `false`
- source_db_mutated: `false`
- promoted_candidate_key: `candidate_607_v615_mana_engine_v1`

## Correction

The previous candidate proved that the imported 615 package is battle-usable, but it did not prove every removed card was the correct slot. The specific cut `The One Ring` over `Molecule Man` is now classified as a cross-lane cut: draw/protection value versus miracle-zero engine.

## Metric Contract

- hard lane equivalence: same primary lane, same macro lane, or explicit package hypothesis
- commander directness: how directly the card advances Lorehold miracle/spell-chain intent
- external commander evidence: EDHREC inclusion/synergy and public guide support
- local battle evidence: equal seed/opponent result plus drawn/cast/used events
- cut safety: protected anchors and previously failed cut signatures
- runtime readiness: rule is modeled before the battle result is trusted

## Pair Reaudit

| Add | Cut | Lane Gate | Decision | External Synergy Delta | Key Local Evidence |
| --- | --- | --- | --- | ---: | --- |
| Mana Vault | Bender's Waterskin | `strict_same_lane` | `allowed_as_local_battle_supported_ramp_upgrade` | -63.0 | 18/72 deck wins; add cast=20; trigger=0; utility=0 |
| Birgi, God of Storytelling // Harnfel, Horn of Bounty | The Scarlet Witch | `same_macro_lane_needs_confirmation` | `same_macro_lane_but_not_final` | -1.0 | 18/72 deck wins; add cast=16; trigger=87; utility=0 |
| The One Ring | Molecule Man | `blocked_cross_lane_cut` | `do_not_use_this_cut_as_deck-quality_proof` | -7.0 | 18/72 deck wins; add cast=13; trigger=0; utility=18 |

## External Evidence Snapshot

| Card | Inclusion | Decks | Synergy | Lane Note |
| --- | ---: | ---: | ---: | --- |
| Molecule Man | 10.0% | 115/1190 | 9.0% | direct topdeck/miracle support bucket |
| The Scarlet Witch | 6.3% | 103/1650 | 5.0% | MV4+ instant/sorcery cost-reduction support bucket |
| The One Ring | 8.4% | 744/8880 | 2.0% | generic draw/protection value bucket |
| Mana Vault | 5.6% | 500/8880 | 2.0% | fast-mana bucket |
| Bender's Waterskin | 71.0% | 6300/8880 | 65.0% | commander-release mana-rock bucket |
| Birgi, God of Storytelling // Harnfel, Horn of Bounty | 7.3% | 647/8880 | 4.0% | spell-chain mana and Harnfel impulse bucket |

## Decision

- current_candidate_status: `battle_cleared_with_cut_methodology_caveat`
- ready_for_real_deck_change: `false`
- blocked_pairs: `the_one_ring_over_molecule_man`
- confirmation_pairs: `birgi_god_of_storytelling_harnfel_horn_of_bounty_over_the_scarlet_witch`
- allowed_pairs: `mana_vault_over_benders_waterskin`

The Mana Vault ramp swap is methodologically valid. Birgi over Scarlet is same-macro but needs confirmation. The One Ring over Molecule Man is a cross-lane cut and must not be used as proof that Molecule belongs out.

## Required Next Actions

- `freeze_cross_lane_cut_guard`: Future package candidates must fail preflight if an added card removes a protected anchor outside its functional lane.
- `one_ring_recut_only_in_draw_protection_value_lane`: The One Ring may still be useful, but it must compete with draw/protection/value slots, not Molecule Man.
- `scarlet_birgi_confirmation_lane`: Birgi and The Scarlet Witch need a focused same-macro confirmation with mana-produced and mana-saved telemetry.
- `molecule_preservation_lane`: Molecule Man stays protected as a direct miracle-zero hypothesis until a same-lane topdeck/miracle replacement beats it.
