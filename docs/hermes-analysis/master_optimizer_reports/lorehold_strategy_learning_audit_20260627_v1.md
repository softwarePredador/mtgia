# Lorehold Strategy Learning Audit - 2026-06-27

- Generated at: `2026-06-27T17:56:05Z`
- Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- Structural matrix: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_variant_strategy_matrix_20260626_v3.json`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Commander Intent

Use topdeck setup, hand filtering, and Lorehold's miracle discount to cast high-impact instant/sorcery spells ahead of curve, then convert that window into a deterministic finisher while surviving fast combat pressure.

Operationally, a better deck must increase at least one of these without breaking the others: early mana/setup, topdeck/miracle conversion, hand filtering, pressure absorption, deterministic closing, or rule-confidence for the cards being tested.

## Current Finding

- Current evidence champion: `candidate_607_squee_hashseed0_isolated_cached_timeout_v3`.
- The strongest current direction is not a generic big-spell upgrade; it is improving the 607 shell by testing the expensive `Insurrection` slot against `Squee, Goblin Nabob` and then validating that result across seeds.
- Decisive gate evidence now uses `PYTHONHASHSEED=0`, `deck_process_isolation=true`, per-game timeout, and the optimized battle-rule lookup cache; seed-42 baseline/candidate-only reproductions match the comparative gate exactly.
- The 10-seed suite keeps Squee barely ahead but downgrades confidence: champion `24W/66L/0S` (`26.67%`) vs `deck_607` `21W/69L/0S` (`23.33%`) and source `deck_6` `16W/74L/0S` (`17.78%`).
- Zone-trace evidence proves `Squee` can be cast, move to graveyard, and return during games, not only in a unit test. Across the 10-seed suite it has `squee_to_graveyard=16`, `squee_upkeep_return=12`, `squee_return_after_known_graveyard_entry=12`, and `squee_return_without_known_graveyard_entry=0`.
- Proven Squee routes in this suite are battlefield-to-graveyard through combat/wipes plus one opponent mill (`Brain Freeze`), but Squee does not appear in enough games to explain the whole deck result.
- Important caveat: the trace gate still did not show `Squee` being discarded by Lorehold rummage or spell-rummage. Treat the discard-fuel loop as a hypothesis; the proven loop is graveyard recurrence after observed zone entries.
- The per-game seed diagnostic shows the real failure mode: Squee is not yet self-sufficient. Seed 42 wins when topdeck/miracle/spell volume is high; seeds 7 and 20260625 go `0W/9L` with no Squee graveyard/return events and very low topdeck/miracle conversion.
- Squee rule materialization is now fixed in the equal-gate loader evidence: Squee now materializes one verified/auto graveyard-recursion rule in the equal-gate candidate; across seeds 42, 7, and 20260625 candidate is 8/19 versus deck_607 10/17, so the fix improves rule evidence but does not prove a stronger deck by itself.
- Remaining rule-row audit now separates aggregate sync gaps from real model gaps: `5` deck materialization gaps and `1` missing battle-rule/model gap.
- Thor rule/runtime audit now closes the local model gap: `local_reviewed_runtime_rule_added_pending_durable_pg_sync`, temp materialized Thor rule count `1`. It still needs durable PostgreSQL/Hermes sync approval before promotion gates use it as source truth.
- Thor synced-rule battle gate now has natural exposure evidence: `1` trigger for `7` damage across `21` candidate games, with win-rate delta `+0.00` pp.
- The broad synergy-confirm gate rejected the tested Past in Flames, Overmaster, and combined spellchain packages; do not promote them from the current evidence.
- Post-Squee package gates now cover Brainstone, Faithless Looting, Galvanoth, Birgi, and Penance against the Squee champion. Best aggregate was `galvanoth_topdeck_freecast` at `9-18` vs baseline `8-19` (`+3.70` pp), but seed 42 moved `-44.45` pp, so it is not an automatic deck promotion.
- Birgi is now instrumented and produced `+13` spell-cast mana triggers, but its aggregate result was `7-20` vs baseline `8-19` (`-3.70` pp); mana telemetry alone is not enough to promote it.
- Penance is not a proven topdeck engine yet: observed `hand_to_topdeck_activation` delta was `+0` and the package lost `-7.41` pp aggregate.
- Library/pressure conversion retest is now closed for the first pass: `Brainstone` over Hexing Squelcher finished `8-19` vs `8-19` (`+0.00` pp) but broke seed 42 by `-77.78` pp; `Ghostly Prison` was `-3.70` pp and `The One Ring` was `-14.82` pp. None promotes from this evidence.
- Library of Leng / discard-to-top telemetry is now visible in gates: seed 42 went `8-1` with `16` discard-to-top replacements, `30` topdeck activations, and `33` miracle casts.
- Failure seeds split into two problems: seed 7 had `0` discard-to-top replacements, while seed 20260625 had `14` replacements but still went `0-9`; the issue is not only finding Library of Leng, but converting the topdecked card into survival or a second Approach window.

## Squee Vs 607 Battle Evidence

| Hash | Isolated | Timeout | Seed | Deck | Games | W | L | S | WR | Miracle | Topdeck | Spell Cast | Cost Paid | Squee GY | Squee Return | Explained | Unknown | Rummage | Spell Rummage | Rummage Squee |
| --- | --- | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | true | 20.0 | 7 | deck_6 | 9 | 2 | 7 | 0 | 22.22% | 9 | 11 | 80 | 95 | 0 | 0 | 0 | 0 | 10 | 0 | 0 |
| 0 | true | 20.0 | 7 | deck_607 | 9 | 1 | 8 | 0 | 11.11% | 12 | 0 | 65 | 83 | 0 | 0 | 0 | 0 | 36 | 0 | 0 |
| 0 | true | 20.0 | 7 | candidate_607_squee_hashseed0_isolated_cached_timeout_v3 | 9 | 0 | 9 | 0 | 0.00% | 4 | 2 | 42 | 53 | 0 | 0 | 0 | 0 | 27 | 2 | 0 |
| 0 | true | 20.0 | 13 | deck_6 | 9 | 1 | 8 | 0 | 11.11% | 6 | 3 | 56 | 62 | 0 | 0 | 0 | 0 | 2 | 0 | 0 |
| 0 | true | 20.0 | 13 | deck_607 | 9 | 2 | 7 | 0 | 22.22% | 7 | 4 | 56 | 64 | 0 | 0 | 0 | 0 | 28 | 3 | 0 |
| 0 | true | 20.0 | 13 | candidate_607_squee_hashseed0_isolated_cached_timeout_v3 | 9 | 1 | 8 | 0 | 11.11% | 9 | 6 | 65 | 76 | 3 | 2 | 2 | 0 | 21 | 6 | 0 |
| 0 | true | 20.0 | 21 | deck_6 | 9 | 1 | 8 | 0 | 11.11% | 5 | 2 | 51 | 70 | 0 | 0 | 0 | 0 | 14 | 0 | 0 |
| 0 | true | 20.0 | 21 | deck_607 | 9 | 1 | 8 | 0 | 11.11% | 12 | 14 | 51 | 70 | 0 | 0 | 0 | 0 | 41 | 0 | 0 |
| 0 | true | 20.0 | 21 | candidate_607_squee_hashseed0_isolated_cached_timeout_v3 | 9 | 1 | 8 | 0 | 11.11% | 10 | 0 | 63 | 74 | 0 | 0 | 0 | 0 | 45 | 6 | 0 |
| 0 | true | 20.0 | 42 | deck_6 | 9 | 0 | 9 | 0 | 0.00% | 9 | 18 | 66 | 89 | 0 | 0 | 0 | 0 | 15 | 0 | 0 |
| 0 | true | 20.0 | 42 | deck_607 | 9 | 5 | 4 | 0 | 55.56% | 25 | 9 | 98 | 122 | 0 | 0 | 0 | 0 | 36 | 4 | 0 |
| 0 | true | 20.0 | 42 | candidate_607_squee_hashseed0_isolated_cached_timeout_v3 | 9 | 8 | 1 | 0 | 88.89% | 33 | 30 | 118 | 148 | 7 | 5 | 5 | 0 | 41 | 19 | 0 |
| 0 | true | 20.0 | 99 | deck_6 | 9 | 1 | 8 | 0 | 11.11% | 13 | 14 | 72 | 90 | 0 | 0 | 0 | 0 | 19 | 0 | 0 |
| 0 | true | 20.0 | 99 | deck_607 | 9 | 0 | 9 | 0 | 0.00% | 11 | 8 | 57 | 74 | 0 | 0 | 0 | 0 | 27 | 2 | 0 |
| 0 | true | 20.0 | 99 | candidate_607_squee_hashseed0_isolated_cached_timeout_v3 | 9 | 2 | 7 | 0 | 22.22% | 14 | 13 | 84 | 103 | 1 | 1 | 1 | 0 | 41 | 21 | 0 |
| 0 | true | 20.0 | 123 | deck_6 | 9 | 5 | 4 | 0 | 55.56% | 17 | 20 | 99 | 124 | 0 | 0 | 0 | 0 | 14 | 0 | 0 |
| 0 | true | 20.0 | 123 | deck_607 | 9 | 3 | 6 | 0 | 33.33% | 16 | 2 | 72 | 89 | 0 | 0 | 0 | 0 | 25 | 0 | 0 |
| 0 | true | 20.0 | 123 | candidate_607_squee_hashseed0_isolated_cached_timeout_v3 | 9 | 5 | 4 | 0 | 55.56% | 19 | 11 | 87 | 105 | 0 | 0 | 0 | 0 | 46 | 0 | 0 |
| 0 | true | 20.0 | 20260624 | deck_6 | 9 | 1 | 8 | 0 | 11.11% | 10 | 5 | 71 | 79 | 0 | 0 | 0 | 0 | 21 | 0 | 0 |
| 0 | true | 20.0 | 20260624 | deck_607 | 9 | 2 | 7 | 0 | 22.22% | 15 | 13 | 64 | 81 | 0 | 0 | 0 | 0 | 36 | 3 | 0 |
| 0 | true | 20.0 | 20260624 | candidate_607_squee_hashseed0_isolated_cached_timeout_v3 | 9 | 3 | 6 | 0 | 33.33% | 10 | 11 | 82 | 99 | 4 | 4 | 4 | 0 | 25 | 16 | 0 |
| 0 | true | 20.0 | 20260625 | deck_6 | 9 | 3 | 6 | 0 | 33.33% | 10 | 4 | 79 | 100 | 0 | 0 | 0 | 0 | 4 | 0 | 0 |
| 0 | true | 20.0 | 20260625 | deck_607 | 9 | 4 | 5 | 0 | 44.44% | 25 | 17 | 84 | 97 | 0 | 0 | 0 | 0 | 46 | 0 | 0 |
| 0 | true | 20.0 | 20260625 | candidate_607_squee_hashseed0_isolated_cached_timeout_v3 | 9 | 0 | 9 | 0 | 0.00% | 4 | 3 | 48 | 64 | 0 | 0 | 0 | 0 | 38 | 2 | 0 |
| 0 | true | 20.0 | 20260626 | deck_6 | 9 | 1 | 8 | 0 | 11.11% | 1 | 4 | 56 | 72 | 0 | 0 | 0 | 0 | 5 | 0 | 0 |
| 0 | true | 20.0 | 20260626 | deck_607 | 9 | 1 | 8 | 0 | 11.11% | 9 | 8 | 60 | 73 | 0 | 0 | 0 | 0 | 31 | 0 | 0 |
| 0 | true | 20.0 | 20260626 | candidate_607_squee_hashseed0_isolated_cached_timeout_v3 | 9 | 1 | 8 | 0 | 11.11% | 11 | 9 | 102 | 85 | 0 | 0 | 0 | 0 | 28 | 6 | 0 |
| 0 | true | 20.0 | 20260627 | deck_6 | 9 | 1 | 8 | 0 | 11.11% | 9 | 7 | 60 | 73 | 0 | 0 | 0 | 0 | 6 | 0 | 0 |
| 0 | true | 20.0 | 20260627 | deck_607 | 9 | 2 | 7 | 0 | 22.22% | 13 | 6 | 87 | 106 | 0 | 0 | 0 | 0 | 29 | 5 | 0 |
| 0 | true | 20.0 | 20260627 | candidate_607_squee_hashseed0_isolated_cached_timeout_v3 | 9 | 3 | 6 | 0 | 33.33% | 21 | 12 | 80 | 95 | 1 | 0 | 0 | 0 | 46 | 15 | 0 |

Aggregate across the checked seeds/gates:

| Deck | Games | W | L | S | WR | Miracle | Topdeck | Spell Cast | Cost Paid | Squee GY | Squee Return | Explained | Unknown | Rummage | Spell Rummage | Rummage Squee |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `deck_6` | 90 | 16 | 74 | 0 | 17.78% | 89 | 88 | 690 | 854 | 0 | 0 | 0 | 0 | 110 | 0 | 0 |
| `deck_607` | 90 | 21 | 69 | 0 | 23.33% | 145 | 81 | 694 | 859 | 0 | 0 | 0 | 0 | 335 | 17 | 0 |
| `candidate_607_squee_hashseed0_isolated_cached_timeout_v3` | 90 | 24 | 66 | 0 | 26.67% | 135 | 97 | 771 | 902 | 16 | 12 | 12 | 0 | 358 | 93 | 0 |

Interpretation: under fixed hash-seed, process-isolated, timeout-bounded conditions, the Squee candidate remains the best current candidate across the 10-seed suite, but only by a narrow margin. This is enough to keep studying the package, not enough to promote it as the final list. The trace evidence still proves every observed `squee_upkeep_return` occurred after an observed Squee graveyard entry, mostly battlefield-to-graveyard movement plus one mill event. It did not prove `lorehold_rummage_discards_squee` or `lorehold_spell_rummage_discards_squee`, so the exact discard-fuel loop remains a targeted next hypothesis rather than a closed fact.

## Squee Seed Diagnostic

- Source: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_seed_diagnostic_20260627_v1.json`
- The 10-seed suite keeps Squee only narrowly ahead: 24W/66L vs deck_607 21W/69L. That is evidence to keep testing, not evidence to lock the final list.
- Seed 42 is the success case: candidate 8W/1L with topdeck=30, miracle=33, squee_gy=7, squee_return=5.
- Seeds 7 and 20260625 are the anti-cases: candidate 0W/9L and 0W/9L, with squee_gy=0/0 and squee_return=0/0.
- The practical read is that Squee is not yet a self-sufficient plan. It helps when the topdeck/miracle/spell-volume engine is alive, but in failure seeds it does not appear or convert.

| Seed | Result | Games | Avg Turns | Miracle | Topdeck | Spell Cast | Squee GY | Squee Return | Games With Topdeck | Games With Squee GY |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 42 | loss | 1 | 6.00 | 0 | 0 | 5 | 1 | 0 | 0 | 1 |
| 42 | win | 8 | 15.12 | 33 | 30 | 113 | 6 | 5 | 5 | 3 |
| 20260625 | loss | 9 | 7.00 | 4 | 3 | 48 | 0 | 0 | 1 | 0 |
| 7 | loss | 9 | 6.33 | 4 | 2 | 42 | 0 | 0 | 1 | 0 |

## Library of Leng / Discard-To-Top Telemetry

These gates rerun the Squee champion with the battle gate instrumented for discard-to-top replacement. The goal is to separate three questions: whether Library of Leng appears, whether it places a meaningful card on top, and whether the deck converts that into miracle/survival before combat pressure kills it.

| Seed | W | L | S | WR | Miracle | Topdeck | Discard-To-Top | Rummage-To-Top | Spell-Rummage-To-Top | Rummage | Spell Rummage | Squee GY | Squee Return | Discard-To-Top Games | Topdeck Games | Miracle Games |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 7 | 0 | 9 | 0 | 0.00% | 4 | 2 | 0 | 0 | 0 | 27 | 2 | 0 | 0 | 0 | 1 | 4 |
| 42 | 8 | 1 | 0 | 88.89% | 33 | 30 | 16 | 13 | 3 | 41 | 19 | 7 | 5 | 3 | 5 | 8 |
| 20260625 | 0 | 9 | 0 | 0.00% | 4 | 3 | 14 | 14 | 0 | 38 | 2 | 0 | 0 | 3 | 1 | 2 |

Aggregate read: `8-19-0` over `27` games, with `30` discard-to-top replacements, `35` topdeck activations, and `41` miracle casts.
Top discard-to-top signals: `discard_to_top:Deflecting Swat`=7, `lorehold_rummage_to_top:Approach of the Second Sun`=7, `discard_to_top:Approach of the Second Sun`=7, `lorehold_rummage_to_top:Deflecting Swat`=6, `lorehold_rummage_to_top:Dawn's Truce`=3, `discard_to_top:Dawn's Truce`=3.
Interpretation: Library of Leng is not a missing runtime feature anymore; it is a measurable engine. Seed 42 shows the intended conversion pattern, seed 7 lacks the engine almost entirely, and seed 20260625 proves that repeated Approach-to-top loops can still fail under fast life-total pressure. The next deck work should pair topdeck consistency with either faster protection/pressure absorption or a cleaner second-Approach/finisher conversion, rather than treating discard-to-top alone as the solution.

## Squee Rule Materialization Audit

- Source: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_rule_materialization_audit_20260627_v1.json`
- Decision: `loader_gap_fixed_but_not_deck_promotion`
- Squee now materializes one verified/auto graveyard-recursion rule in the equal-gate candidate; across seeds 42, 7, and 20260625 candidate is 8/19 versus deck_607 10/17, so the fix improves rule evidence but does not prove a stronger deck by itself.

| Seed | Deck | W | L | S | WR | Miracle | Topdeck | Squee GY | Squee Return | Rule Count | Rule Keys | Tags |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 42 | `deck_607` | 5 | 4 | 0 | 55.56% | 25 | 9 | 0 | 0 | 0 |  |  |
| 42 | `candidate_607_squee_goblin_nabob_equal_gate` | 8 | 1 | 0 | 88.89% | 33 | 30 | 7 | 5 | 1 | battle_rule_v1:4565272d5decc69322e01a4f919df77e | graveyard_recursion, engine, board_presence, wincon |
| 7 | `deck_607` | 1 | 8 | 0 | 11.11% | 12 | 0 | 0 | 0 | 0 |  |  |
| 7 | `candidate_607_squee_goblin_nabob_equal_gate` | 0 | 9 | 0 | 0.00% | 4 | 2 | 0 | 0 | 1 | battle_rule_v1:4565272d5decc69322e01a4f919df77e | graveyard_recursion, engine, board_presence, wincon |
| 20260625 | `deck_607` | 4 | 5 | 0 | 44.44% | 25 | 17 | 0 | 0 | 0 |  |  |
| 20260625 | `candidate_607_squee_goblin_nabob_equal_gate` | 0 | 9 | 0 | 0.00% | 4 | 3 | 0 | 0 | 1 | battle_rule_v1:4565272d5decc69322e01a4f919df77e | graveyard_recursion, engine, board_presence, wincon |

## Remaining Rule Row Audit

- Source: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_unresolved_rule_rows_audit_20260627_v1.json`
- Read: cards marked `deck_rule_materialization_gap` already have active reviewed `battle_card_rules`; future equal gates now materialize those rows deck-wide. Cards marked `missing_battle_rule_model` need a new rule/runtime family before battle evidence is trusted.

| Card | Deck Rule Count | Active Rule Count | Decision | Action | Rule Keys |
| --- | ---: | ---: | --- | --- | --- |
| The Scarlet Witch | 0 | 1 | `deck_rule_materialization_gap` | `fixed_for_future_equal_gates_by_deck_rule_materialization_sweep` | battle_rule_v1:0b23c5f26d2bc884b7f506cdd9d422fc |
| Molecule Man | 0 | 1 | `deck_rule_materialization_gap` | `fixed_for_future_equal_gates_by_deck_rule_materialization_sweep` | battle_rule_v1:752f8cfd0a44d1889ffdb40610847374 |
| The Mind Stone | 0 | 1 | `deck_rule_materialization_gap` | `fixed_for_future_equal_gates_by_deck_rule_materialization_sweep` | battle_rule_v1:57bb1f91d9eea2ad14a8e8d24d2f8d53 |
| Thor, God of Thunder | 0 | 0 | `missing_battle_rule_model` | `create_reviewed_battle_card_rule_and_runtime_family_before_trusting_gate_result` | none |
| Emeria's Call // Emeria, Shattered Skyclave | 0 | 1 | `deck_rule_materialization_gap` | `fixed_for_future_equal_gates_by_deck_rule_materialization_sweep` | battle_rule_v1:ae4a933d873bec332ec2a46106b79277 |
| Tragic Arrogance | 0 | 1 | `deck_rule_materialization_gap` | `fixed_for_future_equal_gates_by_deck_rule_materialization_sweep` | battle_rule_v1:d4d676e6ecea500f7aca4cbc7f7ae04a |

## Thor Rule Runtime Audit

- Source: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_thor_rule_runtime_audit_20260627_v1.json`
- Decision: `local_reviewed_runtime_rule_added_pending_durable_pg_sync`
- Runtime test: `30 passed`
- Temp SQLite sync/materialization: Thor rule count `1`; deck materialized Thor rule count `1`; rule key `battle_rule_v1:280e17ec34ac105baeb6989491c6ff25`.
- Executed branch: noncreature spell casts deal damage equal to the triggering spell mana value to any target. ETB graveyard recast is recorded as annotation until a safe temporary-play executor is promoted.

## Thor Synced Rule Battle Gate

- Source: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_thor_synced_rule_gate_audit_20260627_v1.json`
- Decision: `rule_sync_verified_battle_exposure_observed_no_winrate_delta`
- Natural exposure: `1`/`21` candidate games; damage triggers `1`; damage amount `7`; win-rate delta `+0.00` pp.

| Deck | Games | W | L | S | WR | Thor Cost | Thor Cast | Thor Damage Triggers | Thor Damage | Miracle | Topdeck | Spell Cast |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `deck_6` | 21 | 6 | 15 | 0 | 28.57% | 1 | 1 | 0 | 0 | 39 | 32 | 170 |
| `deck_6_thor_synced` | 21 | 6 | 15 | 0 | 28.57% | 1 | 0 | 1 | 7 | 40 | 32 | 170 |

| Seed | Deck | Opponent | Result | Turns | Thor Cost | Thor Cast | Thor Damage | Damage Amount |
| ---: | --- | --- | --- | ---: | ---: | ---: | ---: | ---: |
| 123 | `deck_6` | Vivi Ornitier #99 (real) | win | 10 | 1 | 1 | 0 | 0 |
| 123 | `deck_6_thor_synced` | Vivi Ornitier #99 (real) | win | 10 | 1 | 0 | 1 | 7 |

The synced Thor rule executed once in natural battle exposure and dealt 7 damage, but the 21-game candidate sample had the same 6-15 record as the baseline. This proves runtime behavior can matter, but not that Thor improves the deck at current sample size/exposure rate.

Use a stratified Thor-exposure gate or larger sample before treating Thor as a keep/cut decision; ETB temporary graveyard play remains a separate runtime gap.

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

## Post-Squee Package And Finalizer Gates

These gates use the Squee champion as source deck id `6`, fixed `PYTHONHASHSEED=0`, process isolation, and per-game timeout. The promotion bar is stricter than a single positive seed: the package must improve aggregate results without breaking the known strong seed.

| Package | Adds | Cuts | Aggregate Baseline | Aggregate Candidate | Delta pp | Seed 42 pp | Miracle | Topdeck | Discard-Top | Rummage-Top | Spell-Rummage-Top | Hand-Top | Spell | Mana | Birgi Mana | Squee GY | Squee Return | Decision |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `galvanoth_topdeck_freecast` | Galvanoth | Bender's Waterskin | 8-19 | 9-18 | +3.70 | -44.45 | +12 | +12 | +0 | +0 | +0 | +0 | +36 | +0 | +0 | +0 | -2 | probation_deeper_gate_only |
| `brainstone_topdeck_miracle_cut_squelcher` | Brainstone | Hexing Squelcher | 8-19 | 8-19 | +0.00 | -77.78 | +7 | +4 | -1 | -4 | +3 | +0 | +24 | +0 | +0 | +8 | +3 | reject_or_rework |
| `birgi_spellchain_cut_squelcher` | Birgi, God of Storytelling // Harnfel, Horn of Bounty | Hexing Squelcher | 8-19 | 7-20 | -3.70 | -55.56 | -13 | -14 | +0 | +0 | +0 | +0 | -22 | +13 | +13 | -1 | -1 | reject_or_rework |
| `core_challenge_dance_over_storm` | Dance with Calamity | Storm Herd | 8-19 | 7-20 | -3.70 | -88.89 | +18 | +25 | +0 | +0 | +0 | +0 | +37 | +0 | +0 | -3 | -2 | reject_or_rework |
| `galvanoth_topdeck_freecast_cut_chimes` | Galvanoth | Victory Chimes | 8-19 | 7-20 | -3.70 | -55.56 | +9 | +7 | +0 | +0 | +0 | +0 | +24 | +0 | +0 | +3 | +4 | reject_or_rework |
| `ghostly_prison_pressure_cut_squelcher` | Ghostly Prison | Hexing Squelcher | 8-19 | 7-20 | -3.70 | -55.56 | +3 | -13 | -22 | -19 | -3 | +0 | +37 | +0 | +0 | -5 | -4 | reject_or_rework |
| `brainstone_topdeck_miracle` | Brainstone | Bender's Waterskin | 8-19 | 6-21 | -7.41 | -33.33 | -6 | +2 | +0 | +0 | +0 | +0 | +43 | +0 | +0 | -5 | -2 | reject_or_rework |
| `galvanoth_topdeck_freecast_cut_squelcher` | Galvanoth | Hexing Squelcher | 8-19 | 6-21 | -7.41 | -66.67 | +5 | -3 | +0 | +0 | +0 | +0 | +28 | +0 | +0 | -4 | -4 | reject_or_rework |
| `penance_topdeck_protection_cut_squelcher` | Penance | Hexing Squelcher | 8-19 | 6-21 | -7.41 | -44.45 | +9 | -1 | +0 | +0 | +0 | +0 | +36 | +0 | +0 | -5 | -4 | reject_or_rework |
| `core_challenge_aetherflux_over_storm` | Aetherflux Reservoir | Storm Herd | 8-19 | 5-22 | -11.11 | -66.67 | -3 | -14 | +0 | +0 | +0 | +0 | +9 | +0 | +0 | -4 | -3 | reject_or_rework |
| `faithless_looting_squee_enabler` | Faithless Looting | Hexing Squelcher | 8-19 | 4-23 | -14.82 | -66.67 | +4 | +6 | +0 | +0 | +0 | +0 | +25 | +0 | +0 | -5 | -3 | reject_or_rework |
| `one_ring_protection_draw_cut_squelcher` | The One Ring | Hexing Squelcher | 8-19 | 4-23 | -14.82 | -77.78 | -9 | -17 | -30 | -27 | -3 | +0 | -7 | +0 | +0 | -3 | -2 | reject_or_rework |

Read: Brainstone can improve weak seeds when it preserves the ramp shell, but the Hexing Squelcher cut is only aggregate-neutral and collapses seed 42, so it is not a deck insert. Ghostly Prison was a coherent pressure hypothesis, but the retest avoiding the old High Noon cut still lost aggregate. The One Ring does not justify the slot here despite the Mind Stone interaction idea; it reduced the aggregate result and the Library discard-to-top metrics. Faithless Looting does not prove the intended Squee-discard loop here and loses badly overall. The original Galvanoth/Bender's Waterskin swap is the only positive aggregate signal, but it loses the strong seed 42; the follow-ups cutting Hexing Squelcher or Victory Chimes are both worse, so Galvanoth stays a probation hypothesis, not a deck insert. Dance with Calamity and Aetherflux Reservoir both improve some weak seeds over Storm Herd, but both lose aggregate and break seed 42, so Storm Herd remains protected for now. Birgi proves the new spell-cast mana telemetry can fire, but it does not improve results. Penance did not fire its hand-to-library activation in this gate, so it is not evidence for a working topdeck-protection engine yet.

## Current Champion Card-Role Coverage

- Quantity: `100` across `94` rows.
- Primary role counts: `{"board_wipe": 6, "creature": 2, "draw": 12, "engine": 3, "land": 34, "protection": 9, "ramp": 15, "removal": 7, "tutor": 1, "unknown": 2, "wincon": 9}`
- Slot decision counts: `{"core_engine_or_probation": 22, "core_finisher": 1, "core_support": 21, "finisher_benchmark_lane": 2, "flex_but_cut_risky": 1, "flex_cut_tested_negative": 2, "locked_core": 1, "mana_base_core": 28, "manual_review": 1, "modeled_not_deck_proven": 1, "modeled_pending_durable_sync": 5, "probation_engine": 1, "support_flex": 8}`
- Package lane counts: `{"commander_engine": 1, "contextual": 1, "early_mana": 14, "finisher_or_big_spell": 4, "graveyard_recursion": 7, "hand_filter": 11, "interaction": 8, "mana_base": 28, "pressure_absorber_or_protection": 12, "selection": 1, "topdeck_miracle_setup": 7}`
- Missing aggregated battle-rule rows in the legacy champion DB: `7` cards: The Scarlet Witch, Molecule Man, The Mind Stone, Thor, God of Thunder, Emeria's Call // Emeria, Shattered Skyclave, Tragic Arrogance, Squee, Goblin Nabob.
- Superseded by rule-materialization audit: `Squee, Goblin Nabob` now has materialized rule evidence in the equal-gate candidate.
- Effective unresolved rule rows after that audit: `0` cards: none.
- Reclassified by remaining-row audit as deck materialization gaps: `Emeria's Call // Emeria, Shattered Skyclave, Molecule Man, The Mind Stone, The Scarlet Witch, Tragic Arrogance`.
- Effective unresolved rule/model rows after all current materialization evidence: `0` cards: none.
- Reclassified by Thor runtime audit as local reviewed rule added pending durable sync: `Thor, God of Thunder`.
- Effective unresolved local runtime/model rows after Thor audit: `0` cards: none.
- Full per-card role, tags, rule keys, package lane, and slot decision are in the companion JSON under `deck_summaries.6.cards` and `card_decision_manifest.cards`.

## What Still Must Be Understood

- Use the per-game Squee diagnostic to decide whether the next improvement is topdeck consistency, explicit discard/rummage enablement, or a different closing package.
- Treat Squee as a provisional micro-upgrade, not a promoted final deck slot, until a support package or alternative cut shows a larger reproducible edge.
- Make all decisive battle gates run with `PYTHONHASHSEED=0`, `--isolate-deck-process`, and per-game timeout; same simulation seed without fixed hash seed/process isolation is not enough for deck promotion.
- Review DB-role versus effective-role divergences surfaced by the card-role manifest, especially cards stored as `draw` or `unknown` while functioning as protection, removal, miracle engine, or board wipe.
- `Thor, God of Thunder` now has a local reviewed runtime rule and one natural synced-rule battle exposure for 7 damage, but the checked 21-game candidate sample had +0.00 pp win-rate delta; keep it as modeled-but-not-proven until a stratified or larger gate proves deck value.
- Separate finalizer slots from engine slots: Dance with Calamity and Aetherflux Reservoir have now failed the Storm Herd slot benchmark; remaining finalizer work should focus on other closing packages or different cuts, not repeating those two swaps.
- Re-test 615 and 614 only as controlled packages against the 607+Squee champion; their full-deck changes are too broad to diagnose one cause.
- Keep runtime-rule readiness in the decision loop; a card with a good paper function cannot be rejected until the battle model understands the relevant effect family.
- Library of Leng is now measurable in battle telemetry; separate missing-engine games from games where discard-to-top happens but fails to convert before life-total pressure.
- The first Library/pressure retest rejected Brainstone, Ghostly Prison, and The One Ring over Hexing Squelcher; future tests need a new cut logic or a narrower per-game failure target.

## Next Gates

- Keep the regression assertion that every `squee_upkeep_return` has an earlier same-game `squee_to_graveyard` or equivalent zone-entry event with source reason.
- Run a per-game failure classifier for seeds 7 and 20260625: classify losses as missing Library/topdeck, topdeck without miracle conversion, second-Approach blocked, combat-pressure death, or mana bottleneck before choosing the next swap.
- Do not repeat Brainstone, Ghostly Prison, or The One Ring over Hexing Squelcher from the current evidence; only retest them if the failure classifier identifies a different cut or a narrower matchup-specific role.
- Do not promote Faithless Looting from the current package gate; it did not increase Squee graveyard/return enough and lost aggregate win rate.
- Do not promote Galvanoth, Dance with Calamity, or Aetherflux Reservoir from current gates; each either loses aggregate or breaks the known strong seed 42.
- Build two narrow packages from 615: one Birgi/ritual package and one revised topdeck-freecast package, each with one or two cuts only, then gate them against the Squee champion.
- Use the generated card-role manifest to mark each card as core, flex, or unresolved before proposing the next swap.
- Use deck-wide rule materialization in the equal-gate loader for every candidate snapshot, then run battle-card-specific tests only for cards with no active reviewed/runtime rule row.
- For Thor, the next decisive test is a stratified exposure gate or larger sample; temporary graveyard recast from ETB is still a separate runtime/model gap.

## External Method Sources

- [EDHREC Lorehold commander page](https://edhrec.com/commanders/lorehold-the-historian): commander-specific package comparison lane.
- [EDHREC spellslinger Commander guide](https://edhrec.com/guides/edhrec-guide-to-spellslinger-in-commander): spellslinger criteria: card flow, cheap interaction, protection, recursion, payoffs.
- [EDHREC Commander deckbuilding guide](https://edhrec.com/articles/how-to-build-a-commander-deck): baseline structure guardrails for lands, ramp, draw, removal, and focused packages.
- [Archidekt Lorehold corpus](https://archidekt.com/commanders/Lorehold%2C%20the%20Historian): user-built Lorehold shells and recurring package choices.
- [Card Kingdom Lorehold synergy article](https://blog.cardkingdom.com/10-crazy-synergy-cards-for-lorehold-the-historian-secrets-of-strixhaven/): external confirmation that Library of Leng and topdeck/discard loops are a commander-specific synergy lane.
- [Draftsim Lorehold EDH deck tech](https://draftsim.com/lorehold-the-historian-edh-deck/): external deck-tech framing for miracle setup, draw timing, and support packages.
