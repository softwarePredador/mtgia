# Lorehold Strategy Learning Audit - 2026-06-27

- Generated at: `2026-06-27T15:22:14Z`
- Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- Structural matrix: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_variant_strategy_matrix_20260626_v3.json`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Commander Intent

Use topdeck setup, hand filtering, and Lorehold's miracle discount to cast high-impact instant/sorcery spells ahead of curve, then convert that window into a deterministic finisher while surviving fast combat pressure.

Operationally, a better deck must increase at least one of these without breaking the others: early mana/setup, topdeck/miracle conversion, hand filtering, pressure absorption, deterministic closing, or rule-confidence for the cards being tested.

## Current Finding

- Current evidence champion: `candidate_607_squee_hashseed0_isolated_cached_timeout_v3`.
- The strongest proven direction is not a generic big-spell upgrade; it is improving the 607 shell by cutting the expensive `Insurrection` slot for `Squee, Goblin Nabob`.
- Decisive gate evidence now uses `PYTHONHASHSEED=0`, `deck_process_isolation=true`, per-game timeout, and the optimized battle-rule lookup cache; baseline/candidate-only reproductions match the comparative gate exactly.
- New zone-trace evidence proves `Squee` can be cast, move to graveyard, and return during games, not only in a unit test. The clean gate has `squee_to_graveyard=7`, `squee_upkeep_return=5`, `squee_return_after_known_graveyard_entry=5`, and `squee_return_without_known_graveyard_entry=0`.
- Proven Squee routes in this gate are battlefield-to-graveyard through combat/wipes plus one opponent mill (`Brain Freeze`).
- Important caveat: the trace gate still did not show `Squee` being discarded by Lorehold rummage or spell-rummage. Treat the discard-fuel loop as a hypothesis; the proven loop is graveyard recurrence after observed zone entries.
- `Squee` still has an aggregate-loader gap: the verified runtime rule exists in `battle_card_rules`, but the candidate snapshot row keeps `deck_cards.battle_rules_json=[]` for that card.
- The broad synergy-confirm gate rejected the tested Past in Flames, Overmaster, and combined spellchain packages; do not promote them from the current evidence.

## Squee Vs 607 Battle Evidence

| Hash | Isolated | Timeout | Seed | Deck | Games | W | L | S | WR | Miracle | Topdeck | Spell Cast | Cost Paid | Squee GY | Squee Return | Explained | Unknown | Rummage | Spell Rummage | Rummage Squee |
| --- | --- | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | true | 20.0 | 42 | deck_607 | 9 | 5 | 4 | 0 | 55.56% | 25 | 9 | 98 | 122 | 0 | 0 | 0 | 0 | 36 | 4 | 0 |
| 0 | true | 20.0 | 42 | candidate_607_squee_hashseed0_isolated_cached_timeout_v3 | 9 | 8 | 1 | 0 | 88.89% | 33 | 30 | 118 | 148 | 7 | 5 | 5 | 0 | 41 | 19 | 0 |

Aggregate across the checked seeds/gates:

| Deck | Games | W | L | S | WR | Miracle | Topdeck | Spell Cast | Cost Paid | Squee GY | Squee Return | Explained | Unknown | Rummage | Spell Rummage | Rummage Squee |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `deck_607` | 9 | 5 | 4 | 0 | 55.56% | 25 | 9 | 98 | 122 | 0 | 0 | 0 | 0 | 36 | 4 | 0 |
| `candidate_607_squee_hashseed0_isolated_cached_timeout_v3` | 9 | 8 | 1 | 0 | 88.89% | 33 | 30 | 118 | 148 | 7 | 5 | 5 | 0 | 41 | 19 | 0 |

Interpretation: under fixed hash-seed, process-isolated, timeout-bounded conditions, the Squee candidate has better relative results and materially more topdeck/miracle/spell activity. The trace gate proves every observed `squee_upkeep_return` occurred after an observed Squee graveyard entry, mostly battlefield-to-graveyard movement plus one mill event. It did not prove `lorehold_rummage_discards_squee` or `lorehold_spell_rummage_discards_squee`, so the exact discard-fuel loop remains a targeted next hypothesis rather than a closed fact.

## Variant Learning

| Rank | Deck | Score | Intent | Lands | Rule Ready | Main Risks |
| ---: | --- | ---: | ---: | ---: | ---: | --- |
| 1 | `deck_607` VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 | 141.0 | 100.0 | 34 | 97.9% | recursion_role, tutor_role |
| 2 | `deck_615` VARIANT Lorehold Variant 10 - Rafael Paste 2026-06-24 | 134.9 | 97.2 | 34 | 100.0% | removal_role, recursion_role, tutor_role |
| 3 | `deck_614` VARIANT Lorehold Variant 09 - Rafael Paste 2026-06-24 | 131.7 | 95.6 | 33 | 100.0% | removal_role, protection_role, recursion_role |
| 4 | `deck_606` VARIANT Lorehold Variant 01 - Rafael Paste 2026-06-22 | 126.2 | 94.9 | 39 | 100.0% | deterministic_finisher, removal_role, protection_role, recursion_role, tutor_role, wincon_role, high_land_count |
| 5 | `deck_613` VARIANT Lorehold Variant 08 - Rafael Paste 2026-06-24 | 121.4 | 86.1 | 32 | 100.0% | land_role, removal_role, recursion_role |
| 6 | `deck_609` VARIANT Lorehold Variant 04 - Rafael Paste 2026-06-24 | 120.2 | 89.9 | 30 | 100.0% | land_role, protection_role, recursion_role, low_land_count |
| 7 | `deck_616` VARIANT Lorehold Variant 11 - Rafael Paste 2026-06-24 | 117.7 | 87.6 | 29 | 85.7% | graveyard_recursion, land_role, ramp_role, recursion_role, tutor_role, battle_rule_readiness, low_land_count |
| 8 | `deck_6` Runtime Lorehold Learned 19e93de3cca | 116.6 | 83.0 | 33 | 100.0% | wincon_role |
| 9 | `candidate_v7` Lorehold strategy-first candidate v7 | 113.7 | 79.3 | 33 | 100.0% | none |
| 10 | `deck_611` VARIANT Lorehold Variant 06 - Rafael Paste 2026-06-24 | 108.1 | 79.5 | 34 | 100.0% | protection_window, removal_role, protection_role, recursion_role |
| 11 | `deck_610` VARIANT Lorehold Variant 05 - Rafael Paste 2026-06-24 | 95.0 | 72.1 | 30 | 85.3% | protection_window, deterministic_finisher, land_role, draw_role, removal_role, protection_role, recursion_role, wincon_role |
| 12 | `deck_612` VARIANT Lorehold Variant 07 - Rafael Paste 2026-06-24 | 91.8 | 72.2 | 27 | 93.0% | protection_window, land_role, draw_role, removal_role, protection_role, recursion_role, tutor_role, low_land_count |
| 13 | `deck_608` VARIANT Lorehold Variant 03 - Rafael Paste 2026-06-23 | 85.3 | 66.6 | 31 | 98.5% | protection_window, deterministic_finisher, land_role, removal_role, protection_role, recursion_role, board_wipe_role, wincon_role |

Main read: 607 is the best structural shell because it is closest to the commander intent. 615 and 614 are the next serious hypotheses, but they are not automatically better because they change many slots at once. 612 has high copy density but too few lands. 616 is off-axis for this commander and has rule-readiness risk.

## Broad Synergy Packages Checked

| Package | Adds | Cuts | Baseline | Candidate | Delta pp | Decision |
| --- | --- | --- | ---: | ---: | ---: | --- |
| `past_in_flames_recast` | Past in Flames | Bender's Waterskin | 3-0-0 | 1-2-0 | -66.67 | reject_or_rework |
| `past_in_flames_cut_squelcher` | Past in Flames | Hexing Squelcher | 3-0-0 | 1-2-0 | -66.67 | reject_or_rework |
| `overmaster_protect_draw` | Overmaster | Hexing Squelcher | 3-0-0 | 1-2-0 | -66.67 | reject_or_rework |
| `past_overmaster_spellchain` | Past in Flames, Overmaster | Bender's Waterskin, Hexing Squelcher | 3-0-0 | 0-3-0 | -100.0 | reject_or_rework |

## Current Champion Card-Role Coverage

- Quantity: `100` across `94` rows.
- Primary role counts: `{"board_wipe": 6, "creature": 2, "draw": 12, "engine": 3, "land": 34, "protection": 9, "ramp": 15, "removal": 7, "tutor": 1, "unknown": 2, "wincon": 9}`
- Missing aggregated battle-rule rows: `7` cards: The Scarlet Witch, Molecule Man, The Mind Stone, Thor, God of Thunder, Emeria's Call // Emeria, Shattered Skyclave, Tragic Arrogance, Squee, Goblin Nabob.
- Full per-card role, tags, and rule keys are in the companion JSON under `deck_summaries.6.cards`.

## What Still Must Be Understood

- Scale the trusted gate from one fixed hash seed to a 3-seed or 5-seed process-isolated suite before promoting the deck as final.
- Make all decisive battle gates run with `PYTHONHASHSEED=0`, `--isolate-deck-process`, and per-game timeout; same simulation seed without fixed hash seed/process isolation is not enough for deck promotion.
- Review DB-role versus effective-role divergences surfaced by the card-role manifest, especially cards stored as `draw` or `unknown` while functioning as protection, removal, miracle engine, or board wipe.
- Separate finalizer slots from engine slots: Insurrection, Storm Herd, Approach, Rise of the Eldrazi, and Aetherflux Reservoir should be benchmarked as closing packages, not generic wincon labels.
- Re-test 615 and 614 only as controlled packages against the 607+Squee champion; their full-deck changes are too broad to diagnose one cause.
- Keep runtime-rule readiness in the decision loop; a card with a good paper function cannot be rejected until the battle model understands the relevant effect family.

## Next Gates

- Keep the regression assertion that every `squee_upkeep_return` has an earlier same-game `squee_to_graveyard` or equivalent zone-entry event with source reason.
- Run a 3-seed or 5-seed equal gate with `PYTHONHASHSEED=0`, process isolation, and timeout: trusted Squee champion vs `deck_607` vs the source deck 6, same real opponents.
- Build two narrow packages from 615: one Birgi/ritual package and one topdeck-freecast package, each with one or two cuts only, then gate them against the Squee champion.
- Use the generated card-role manifest to mark each card as core, flex, or unresolved before proposing the next swap.
- If a candidate uses a rule missing from aggregated deck rows, run the battle-card-specific test plus one replay trace before trusting the battle result.

## External Method Sources

- [EDHREC Lorehold commander page](https://edhrec.com/commanders/lorehold-the-historian): commander-specific package comparison lane.
- [EDHREC spellslinger Commander guide](https://edhrec.com/guides/edhrec-guide-to-spellslinger-in-commander): spellslinger criteria: card flow, cheap interaction, protection, recursion, payoffs.
- [EDHREC Commander deckbuilding guide](https://edhrec.com/articles/how-to-build-a-commander-deck): baseline structure guardrails for lands, ramp, draw, removal, and focused packages.
- [Archidekt Lorehold corpus](https://archidekt.com/commanders/Lorehold%2C%20the%20Historian): user-built Lorehold shells and recurring package choices.
