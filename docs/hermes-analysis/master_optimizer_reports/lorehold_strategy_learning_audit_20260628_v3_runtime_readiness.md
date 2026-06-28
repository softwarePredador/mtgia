# Lorehold Strategy Learning Audit - 2026-06-28

- Generated at: `2026-06-28T09:59:56Z`
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
- Runtime/package readiness now tracks new modeled hypotheses outside the champion list: `2` cards, families `{"static_damage_modifier": 1, "topdeck_play": 1}`, readiness `{"runtime_ready_pg_precheck_blocked": 2}`.
- Consolidated runtime-candidate readiness now separates card readiness from bad cut evidence: `66` cards, statuses `{"manual_mapper_required": 52, "pg_package_prepared_pending_apply_approval": 1, "pg_precheck_blocked": 2, "review_required": 3, "runtime_model_blocked": 1, "split_scope_review_required": 7}`, cut-specific negatives `2`.
- The broad synergy-confirm gate rejected the tested Past in Flames, Overmaster, and combined spellchain packages; do not promote them from the current evidence.
- The cut-safety-aware safe queue v3 produced `7` executable packages that avoided the protected cuts, but the smoke gate still found no promotion. Best smoke result was `overmaster_protect_draw_cut_tibalts_trickery` at `2-1-0` with delta `-33.33` pp.
- `Overmaster` over `Tibalt's Trickery` is only a watch-list clue, not a deck change: candidate `2-1` vs baseline `3-0` (`-33.33` pp), decision `watch_only_needs_stronger_justification`.
- Post-Squee package gates now cover Brainstone, Faithless Looting, Galvanoth, Birgi, Seething Song, Penance, Primal Amulet, and Gamble against the Squee champion. Best aggregate was `galvanoth_topdeck_freecast` at `9-18` vs baseline `8-19` (`+3.70` pp), but seed 42 moved `-44.45` pp, so it is not an automatic deck promotion.
- Birgi is now instrumented and produced `+13` spell-cast mana triggers, but its aggregate result was `7-20` vs baseline `8-19` (`-3.70` pp); mana telemetry alone is not enough to promote it.
- Birgi + Seething Song over Pearl/Ruby Medallion is a useful but rejected spell-chain clue: `8-19` vs `8-19` (`+0.00` pp), seed 42 `-55.56` pp, ritual delta `-2`, Birgi mana delta `+15`. It helps weak seeds, but losing both medallions breaks the known strong conversion pattern.
- Penance is not a proven topdeck engine yet: observed `hand_to_topdeck_activation` delta was `+0` and the package lost `-7.41` pp aggregate.
- Library/pressure conversion retest is now closed for the first pass: `Brainstone` over Hexing Squelcher finished `8-19` vs `8-19` (`+0.00` pp) but broke seed 42 by `-77.78` pp; `Ghostly Prison` was `-3.70` pp and `The One Ring` was `-14.82` pp. None promotes from this evidence.
- Angel's Grace life-floor retest also rejects the intuitive cheap-protection swap: `3-24` vs `8-19` (`-18.52` pp) and seed 42 moved `-88.89` pp.
- Primal Amulet over Bender's Waterskin closes the revised top-freecast test from 615 as a reject/rework: `7-20` vs `8-19` (`-3.70` pp), seed 42 `-44.45` pp, spell delta `+17`, miracle delta `-9`. It helps low-performing seeds but again breaks the known strong conversion pattern.
- Galvanoth over Thor was the controlled topdeck/freecast retest after Bender, Hexing, and Chimes cuts failed: `3-6` vs `8-1` (`-55.56` pp), seed 42 `-55.56` pp. This was only run as a seed-42 triage because it failed the strong-seed promotion filter; do not spend weak-seed runs on this cut.
- Gamble over Creative Technique is the first narrow tutor-access benchmark against the current loss classifier: `9-18` vs `8-19` (`+3.70` pp), seed 42 `-44.45` pp, tutor delta `+3`, random-discard delta `+5`. Because it breaks the known strong seed, do not replace Creative Technique yet; treat this as a tutor-access clue that needs a different cut or a seed-42-preserving follow-up.
- Gamble over Thor was the attempted seed-42-preserving tutor retest after the Creative Technique cut failed: `3-6` vs `8-1` (`-55.56` pp), seed 42 `-55.56` pp, tutor delta `-2`, random-discard delta `+3`. This was only run as a seed-42 triage because it failed the strong-seed promotion filter.
- Enlightened Tutor over Thor tests access without Gamble's random discard: `4-5` vs `8-1` (`-44.45` pp), seed 42 `-44.45` pp, tutor delta `-3`, topdeck delta `-21`. This was only run as a seed-42 triage because it failed the strong-seed promotion filter.
- Boseiju, Who Shelters All over Reliquary Tower was the land-slot spell-protection test: `3-6` vs `8-1` (`-55.56` pp), seed 42 `-55.56` pp. It preserves land count and has active rules, but the losses still show life-zero combat pressure rather than counterspell denial.
- Boros Charm over Fated Clash tested the cheap pressure-absorber idea from the stronger variants: `0-9` vs `8-1` (`-88.89` pp), seed 42 `-88.89` pp. The card may still be coherent in another slot, but cutting Fated Clash removed too much pressure response.
- Loss classifier is now the driver for the next swap: baseline seed 7 losses are mostly `{"mana_spell_bottleneck_under_pressure": 3, "missing_engine_under_combat_pressure": 2, "topdeck_miracle_without_approach_under_pressure": 4}`, while seed 20260625 losses are `{"mana_spell_bottleneck_under_pressure": 4, "missing_engine_under_combat_pressure": 1, "second_approach_window_failed_under_pressure": 1, "topdeck_miracle_without_approach_under_pressure": 2, "topdeck_without_miracle_conversion_under_pressure": 1}`. Every classified baseline loss carries the combat-pressure death flag, so the next package must improve early survival without breaking the seed-42 engine pattern.
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

## Loss Failure Classifier

- Source: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_loss_failure_classifier_20260627_conversion_pressure_v8.json`
- Read: this classifier uses per-game observed events over stale reason text; for example, an `approach_cast_tracked` event outranks a legacy `found=False` reason string.

| Seed | Package | Deck | Losses | Avg Loss Turn | Primary Causes | Pressure | Approach | Discard-Top | Topdeck | Miracle | Low Spell |
| ---: | --- | --- | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 7 | `angel_grace_life_floor_cut_dawn` | `synergy_angel_grace_life_floor_cut_dawn` | 9 | 7.33 | mana_spell_bottleneck_under_pressure=1, missing_engine_under_combat_pressure=5, topdeck_miracle_without_approach_under_pressure=2, topdeck_without_miracle_conversion_under_pressure=1 | 9 | 0 | 3 | 0 | 2 | 1 |
| 7 | `baseline_squee_champion` | `deck_6` | 9 | 6.33 | mana_spell_bottleneck_under_pressure=3, missing_engine_under_combat_pressure=2, topdeck_miracle_without_approach_under_pressure=4 | 9 | 0 | 0 | 1 | 4 | 5 |
| 7 | `birgi_seething_chain_cut_medallions` | `synergy_birgi_seething_chain_cut_medallions` | 7 | 6.86 | mana_spell_bottleneck_under_pressure=3, missing_engine_under_combat_pressure=2, topdeck_miracle_without_approach_under_pressure=2 | 7 | 0 | 0 | 0 | 2 | 5 |
| 7 | `brainstone_topdeck_miracle_cut_squelcher` | `synergy_brainstone_topdeck_miracle_cut_squelcher` | 7 | 6.86 | mana_spell_bottleneck_under_pressure=1, missing_engine_under_combat_pressure=2, topdeck_miracle_without_approach_under_pressure=2, topdeck_without_miracle_conversion_under_pressure=2 | 7 | 0 | 1 | 2 | 2 | 2 |
| 7 | `gamble_approach_access_cut_creative` | `synergy_gamble_approach_access_cut_creative` | 7 | 6.43 | mana_spell_bottleneck_under_pressure=1, second_approach_window_failed_under_pressure=1, topdeck_miracle_without_approach_under_pressure=4, topdeck_without_miracle_conversion_under_pressure=1 | 7 | 1 | 1 | 2 | 4 | 4 |
| 7 | `ghostly_prison_pressure_cut_squelcher` | `synergy_ghostly_prison_pressure_cut_squelcher` | 7 | 7.57 | mana_spell_bottleneck_under_pressure=2, missing_engine_under_combat_pressure=1, second_approach_window_failed_under_pressure=1, topdeck_miracle_without_approach_under_pressure=3 | 7 | 1 | 0 | 1 | 4 | 3 |
| 7 | `one_ring_protection_draw_cut_squelcher` | `synergy_one_ring_protection_draw_cut_squelcher` | 9 | 7.33 | mana_spell_bottleneck_under_pressure=2, second_approach_window_failed_under_pressure=1, topdeck_miracle_without_approach_under_pressure=4, topdeck_without_miracle_conversion_under_pressure=2 | 9 | 1 | 0 | 4 | 4 | 3 |
| 7 | `primal_amulet_spell_engine` | `synergy_primal_amulet_spell_engine` | 7 | 6.29 | mana_spell_bottleneck_under_pressure=4, second_approach_window_failed_under_pressure=1, topdeck_miracle_without_approach_under_pressure=2 | 7 | 1 | 0 | 0 | 3 | 6 |
| 42 | `angel_grace_life_floor_cut_dawn` | `synergy_angel_grace_life_floor_cut_dawn` | 9 | 7.44 | mana_spell_bottleneck_under_pressure=2, missing_engine_under_combat_pressure=1, second_approach_window_failed_under_pressure=2, topdeck_miracle_without_approach_under_pressure=3, topdeck_without_miracle_conversion_under_pressure=1 | 9 | 2 | 1 | 2 | 5 | 3 |
| 42 | `baseline_squee_champion` | `deck_6` | 1 | 6.00 | missing_engine_under_combat_pressure=1 | 1 | 0 | 0 | 0 | 0 | 0 |
| 42 | `birgi_seething_chain_cut_medallions` | `synergy_birgi_seething_chain_cut_medallions` | 6 | 7.50 | mana_spell_bottleneck_under_pressure=1, second_approach_window_failed_under_pressure=2, topdeck_miracle_without_approach_under_pressure=3 | 6 | 2 | 1 | 1 | 5 | 1 |
| 42 | `boros_charm_pressure_cut_fated` | `synergy_boros_charm_pressure_cut_fated` | 9 | 7.67 | missing_engine_under_combat_pressure=3, topdeck_miracle_without_approach_under_pressure=5, topdeck_without_miracle_conversion_under_pressure=1 | 9 | 0 | 1 | 2 | 5 | 2 |
| 42 | `boseiju_spell_protection_land` | `synergy_boseiju_spell_protection_land` | 6 | 6.83 | mana_spell_bottleneck_under_pressure=3, missing_engine_under_combat_pressure=1, second_approach_window_failed_under_pressure=1, topdeck_miracle_without_approach_under_pressure=1 | 6 | 1 | 0 | 1 | 2 | 3 |
| 42 | `brainstone_topdeck_miracle_cut_squelcher` | `synergy_brainstone_topdeck_miracle_cut_squelcher` | 8 | 7.88 | mana_spell_bottleneck_under_pressure=1, missing_engine_under_combat_pressure=1, topdeck_miracle_without_approach_under_pressure=4, topdeck_without_miracle_conversion_under_pressure=2 | 8 | 0 | 2 | 2 | 4 | 2 |
| 42 | `enlightened_engine_access_cut_thor` | `synergy_enlightened_engine_access_cut_thor` | 5 | 7.60 | mana_spell_bottleneck_under_pressure=1, missing_engine_under_combat_pressure=1, topdeck_miracle_without_approach_under_pressure=1, topdeck_without_miracle_conversion_under_pressure=2 | 5 | 0 | 1 | 2 | 1 | 2 |
| 42 | `galvanoth_topdeck_freecast_cut_thor` | `synergy_galvanoth_topdeck_freecast_cut_thor` | 6 | 6.33 | mana_spell_bottleneck_under_pressure=3, topdeck_miracle_without_approach_under_pressure=2, topdeck_without_miracle_conversion_under_pressure=1 | 6 | 0 | 1 | 1 | 2 | 4 |
| 42 | `gamble_access_cut_thor` | `synergy_gamble_access_cut_thor` | 6 | 7.33 | mana_spell_bottleneck_under_pressure=1, missing_engine_under_combat_pressure=1, topdeck_miracle_without_approach_under_pressure=3, topdeck_without_miracle_conversion_under_pressure=1 | 6 | 0 | 1 | 2 | 3 | 2 |
| 42 | `gamble_approach_access_cut_creative` | `synergy_gamble_approach_access_cut_creative` | 5 | 7.80 | mana_spell_bottleneck_under_pressure=1, missing_engine_under_combat_pressure=2, second_approach_window_failed_under_pressure=1, topdeck_miracle_without_approach_under_pressure=1 | 5 | 1 | 0 | 2 | 2 | 1 |
| 42 | `ghostly_prison_pressure_cut_squelcher` | `synergy_ghostly_prison_pressure_cut_squelcher` | 6 | 6.83 | mana_spell_bottleneck_under_pressure=2, missing_engine_under_combat_pressure=3, topdeck_miracle_without_approach_under_pressure=1 | 6 | 0 | 0 | 0 | 1 | 3 |
| 42 | `one_ring_protection_draw_cut_squelcher` | `synergy_one_ring_protection_draw_cut_squelcher` | 8 | 7.38 | mana_spell_bottleneck_under_pressure=1, missing_engine_under_combat_pressure=2, second_approach_window_failed_under_pressure=1, topdeck_miracle_without_approach_under_pressure=4 | 8 | 1 | 0 | 1 | 4 | 1 |
| 42 | `primal_amulet_spell_engine` | `synergy_primal_amulet_spell_engine` | 5 | 8.00 | mana_spell_bottleneck_under_pressure=1, second_approach_window_failed_under_pressure=2, topdeck_miracle_without_approach_under_pressure=2 | 5 | 2 | 1 | 2 | 4 | 1 |
| 20260625 | `angel_grace_life_floor_cut_dawn` | `synergy_angel_grace_life_floor_cut_dawn` | 6 | 7.00 | mana_spell_bottleneck_under_pressure=1, missing_engine_under_combat_pressure=2, second_approach_window_failed_under_pressure=1, topdeck_miracle_without_approach_under_pressure=2 | 6 | 1 | 0 | 1 | 3 | 2 |
| 20260625 | `baseline_squee_champion` | `deck_6` | 9 | 7.00 | mana_spell_bottleneck_under_pressure=4, missing_engine_under_combat_pressure=1, second_approach_window_failed_under_pressure=1, topdeck_miracle_without_approach_under_pressure=2, topdeck_without_miracle_conversion_under_pressure=1 | 9 | 1 | 3 | 1 | 2 | 5 |
| 20260625 | `birgi_seething_chain_cut_medallions` | `synergy_birgi_seething_chain_cut_medallions` | 6 | 7.33 | mana_spell_bottleneck_under_pressure=1, missing_engine_under_combat_pressure=2, topdeck_miracle_without_approach_under_pressure=2, topdeck_without_miracle_conversion_under_pressure=1 | 6 | 0 | 0 | 2 | 2 | 1 |
| 20260625 | `brainstone_topdeck_miracle_cut_squelcher` | `synergy_brainstone_topdeck_miracle_cut_squelcher` | 4 | 7.25 | second_approach_window_failed_under_pressure=1, topdeck_miracle_without_approach_under_pressure=3 | 4 | 1 | 2 | 1 | 3 | 1 |
| 20260625 | `gamble_approach_access_cut_creative` | `synergy_gamble_approach_access_cut_creative` | 6 | 7.17 | mana_spell_bottleneck_under_pressure=2, second_approach_window_failed_under_pressure=1, topdeck_miracle_without_approach_under_pressure=3 | 6 | 1 | 2 | 3 | 3 | 2 |
| 20260625 | `ghostly_prison_pressure_cut_squelcher` | `synergy_ghostly_prison_pressure_cut_squelcher` | 7 | 7.29 | mana_spell_bottleneck_under_pressure=4, missing_engine_under_combat_pressure=1, second_approach_window_failed_under_pressure=1, topdeck_miracle_without_approach_under_pressure=1 | 7 | 1 | 1 | 0 | 1 | 4 |
| 20260625 | `one_ring_protection_draw_cut_squelcher` | `synergy_one_ring_protection_draw_cut_squelcher` | 6 | 7.67 | mana_spell_bottleneck_under_pressure=1, missing_engine_under_combat_pressure=2, second_approach_window_failed_under_pressure=1, topdeck_miracle_without_approach_under_pressure=2 | 6 | 1 | 0 | 2 | 3 | 1 |
| 20260625 | `primal_amulet_spell_engine` | `synergy_primal_amulet_spell_engine` | 8 | 6.88 | missing_engine_under_combat_pressure=5, topdeck_miracle_without_approach_under_pressure=3 | 8 | 0 | 0 | 1 | 3 | 1 |

Interpretation: the problem is not a single missing prison/tax card. The failure mode alternates between no early engine, low early spell volume, and engine without Approach conversion, but all checked losses still die through combat-pressure/life-zero. `Angel's Grace` proves a one-mana life-floor can help the weak 20260625 seed, yet it destroys the seed-42 success pattern when it replaces Dawn's Truce; the next test needs to preserve the existing protection shell and change a less structurally important slot.

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

## Runtime Package Readiness

These rows are not deck promotions. They are modeled hypotheses whose effect family is now executable/package-ready, but durable PostgreSQL precheck/apply/sync or an isolated materialized gate is still required before judging deck value.

- Summary: `{"blocked_card_count": 2, "blocker_count": 1, "candidate_readiness_card_count": 66, "candidate_readiness_promotion_lane_counts": {"access_density_candidate": 5, "batch_metadata_candidate_requires_pg_precheck": 2, "mapper_metadata_or_test_scenario_required": 52, "split_family_scope_review_required": 7}, "candidate_readiness_recommended_next_action": "rerun_pg245_precheck_then_sync_or_split_scope_runtime_families", "candidate_readiness_status_counts": {"manual_mapper_required": 52, "pg_package_prepared_pending_apply_approval": 1, "pg_precheck_blocked": 2, "review_required": 3, "runtime_model_blocked": 1, "split_scope_review_required": 7}, "card_count": 2, "cut_specific_negative_count": 2, "family_counts": {"static_damage_modifier": 1, "topdeck_play": 1}, "manifest_count": 1, "manual_mapper_required_count": 52, "pg_package_prepared_pending_apply_approval_count": 1, "pg_precheck_blocked_count": 2, "readiness_counts": {"runtime_ready_pg_precheck_blocked": 2}, "split_scope_review_required_count": 7}`

| Card | Family | Role | Scope | Readiness | Package | Blocker |
| --- | --- | --- | --- | --- | --- | --- |
| Twinflame Tyrant | `static_damage_modifier` | `wincon` | `controlled_source_damage_to_opponent_or_opponent_permanent_doubled_v1` | `runtime_ready_pg_precheck_blocked` | PG245/lorehold_topdeck_damage_runtime | precheck: server closed the connection unexpectedly before precheck execution |
| Verge Rangers | `topdeck_play` | `ramp` | `look_top_library_play_lands_from_top_if_opponent_more_lands_v1` | `runtime_ready_pg_precheck_blocked` | PG245/lorehold_topdeck_damage_runtime | precheck: server closed the connection unexpectedly before precheck execution |

Read: `runtime_ready_pg_precheck_blocked` means the card should stay in the hypothesis pool, not be discarded as unmodeled. The next valid evidence is either successful PG precheck/apply/postcheck plus Hermes sync, or a clearly isolated candidate DB where the same rule rows are materialized for battle gates.

## Runtime Candidate Readiness Queue

This is the broader queue used to avoid judging strategy before the battle runtime can execute the relevant effect family. A cut-specific negative means the tested add/cut pair failed; it is not a global rejection of the card.

- Source: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_candidate_readiness_20260628_v1.json`
- Summary: `{"candidate_readiness_card_count": 66, "candidate_readiness_promotion_lane_counts": {"access_density_candidate": 5, "batch_metadata_candidate_requires_pg_precheck": 2, "mapper_metadata_or_test_scenario_required": 52, "split_family_scope_review_required": 7}, "candidate_readiness_recommended_next_action": "rerun_pg245_precheck_then_sync_or_split_scope_runtime_families", "candidate_readiness_status_counts": {"manual_mapper_required": 52, "pg_package_prepared_pending_apply_approval": 1, "pg_precheck_blocked": 2, "review_required": 3, "runtime_model_blocked": 1, "split_scope_review_required": 7}, "cut_specific_negative_count": 2}`

| Rank | Card | Status | Family | Lane | Cut-specific negatives | Global reject | Next action |
| ---: | --- | --- | --- | --- | ---: | --- | --- |
| 1 | Twinflame Tyrant | `pg_precheck_blocked` | `static_damage_modifier` | `batch_metadata_candidate_requires_pg_precheck` | 1 | `false` | Rerun PostgreSQL precheck; do not apply package until every selected card has a matched card row. |
| 2 | Verge Rangers | `pg_precheck_blocked` | `topdeck_play` | `batch_metadata_candidate_requires_pg_precheck` | 1 | `false` | Rerun PostgreSQL precheck; do not apply package until every selected card has a matched card row. |
| 3 | Hidden Retreat | `pg_package_prepared_pending_apply_approval` | `access_density` | `access_density_candidate` | 0 | `false` | Apply only after explicit approval for the exact precheck/apply/postcheck command sequence, then sync PG to Hermes. |
| 4 | Goliath Daydreamer | `split_scope_review_required` | `free_cast` | `split_family_scope_review_required` | 0 | `false` | Split the family scope and write focused runtime tests before creating a metadata package. |
| 5 | Boros Reckoner | `split_scope_review_required` | `targeted_interaction` | `split_family_scope_review_required` | 0 | `false` | Split the family scope and write focused runtime tests before creating a metadata package. |
| 6 | Terror of the Peaks | `split_scope_review_required` | `targeted_interaction` | `split_family_scope_review_required` | 0 | `false` | Split the family scope and write focused runtime tests before creating a metadata package. |
| 7 | Balefire Liege | `split_scope_review_required` | `targeted_interaction` | `split_family_scope_review_required` | 0 | `false` | Split the family scope and write focused runtime tests before creating a metadata package. |
| 8 | Firesong and Sunspeaker | `split_scope_review_required` | `targeted_interaction` | `split_family_scope_review_required` | 0 | `false` | Split the family scope and write focused runtime tests before creating a metadata package. |
| 9 | Repercussion | `split_scope_review_required` | `targeted_interaction` | `split_family_scope_review_required` | 0 | `false` | Split the family scope and write focused runtime tests before creating a metadata package. |
| 10 | Toralf, God of Fury // Toralf's Hammer | `split_scope_review_required` | `targeted_interaction` | `split_family_scope_review_required` | 0 | `false` | Split the family scope and write focused runtime tests before creating a metadata package. |
| 11 | Ancient Copper Dragon | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | 0 | `false` | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 12 | Beacon of Immortality | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | 0 | `false` | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 13 | Heroes Remembered | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | 0 | `false` | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 14 | Invincible Hymn | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | 0 | `false` | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 15 | Planetarium of Wan Shi Tong | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | 0 | `false` | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 16 | Semblance Anvil | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | 0 | `false` | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 17 | Taunt from the Rampart | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | 0 | `false` | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 18 | Alhammarret's Archive | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | 0 | `false` | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 19 | Ancient Gold Dragon | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | 0 | `false` | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 20 | Assemble the Players | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | 0 | `false` | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 21 | Blood Moon | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | 0 | `false` | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 22 | Chandra's Ignition | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | 0 | `false` | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 23 | Chaos Wand | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | 0 | `false` | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |
| 24 | Charmbreaker Devils | `manual_mapper_required` | `manual_model` | `mapper_metadata_or_test_scenario_required` | 0 | `false` | Add mapper metadata or a focused test scenario before treating the XMage source as executable. |

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

| Package | Adds | Cuts | Aggregate Baseline | Aggregate Candidate | Delta pp | Seed 42 pp | Miracle | Topdeck | Discard-Top | Rummage-Top | Spell-Rummage-Top | Hand-Top | Spell | Mana | Birgi Mana | Ritual | Squee GY | Squee Return | Decision |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `galvanoth_topdeck_freecast` | Galvanoth | Bender's Waterskin | 8-19 | 9-18 | +3.70 | -44.45 | +12 | +12 | +0 | +0 | +0 | +0 | +36 | +0 | +0 | -6 | +0 | -2 | probation_deeper_gate_only |
| `gamble_approach_access_cut_creative` | Gamble | Creative Technique | 8-19 | 9-18 | +3.70 | -44.45 | +8 | +7 | -20 | -17 | -3 | +0 | +34 | +0 | +0 | -12 | +1 | +1 | probation_deeper_gate_only |
| `birgi_seething_chain_cut_medallions` | Birgi, God of Storytelling // Harnfel, Horn of Bounty, Seething Song | Pearl Medallion, Ruby Medallion | 8-19 | 8-19 | +0.00 | -55.56 | +1 | +12 | -12 | -13 | +1 | +0 | -2 | +15 | +15 | -2 | -3 | -3 | reject_or_rework |
| `brainstone_topdeck_miracle_cut_squelcher` | Brainstone | Hexing Squelcher | 8-19 | 8-19 | +0.00 | -77.78 | +7 | +4 | -1 | -4 | +3 | +0 | +24 | +0 | +0 | -7 | +8 | +3 | reject_or_rework |
| `birgi_spellchain_cut_squelcher` | Birgi, God of Storytelling // Harnfel, Horn of Bounty | Hexing Squelcher | 8-19 | 7-20 | -3.70 | -55.56 | -13 | -14 | +0 | +0 | +0 | +0 | -22 | +13 | +13 | -10 | -1 | -1 | reject_or_rework |
| `core_challenge_dance_over_storm` | Dance with Calamity | Storm Herd | 8-19 | 7-20 | -3.70 | -88.89 | +18 | +25 | +0 | +0 | +0 | +0 | +37 | +0 | +0 | -3 | -3 | -2 | reject_or_rework |
| `galvanoth_topdeck_freecast_cut_chimes` | Galvanoth | Victory Chimes | 8-19 | 7-20 | -3.70 | -55.56 | +9 | +7 | +0 | +0 | +0 | +0 | +24 | +0 | +0 | -9 | +3 | +4 | reject_or_rework |
| `ghostly_prison_pressure_cut_squelcher` | Ghostly Prison | Hexing Squelcher | 8-19 | 7-20 | -3.70 | -55.56 | +3 | -13 | -22 | -19 | -3 | +0 | +37 | +0 | +0 | -2 | -5 | -4 | reject_or_rework |
| `primal_amulet_spell_engine` | Primal Amulet // Primal Wellspring | Bender's Waterskin | 8-19 | 7-20 | -3.70 | -44.45 | -9 | -20 | -28 | -26 | -2 | +0 | +17 | +0 | +0 | -4 | -6 | -5 | reject_or_rework |
| `brainstone_topdeck_miracle` | Brainstone | Bender's Waterskin | 8-19 | 6-21 | -7.41 | -33.33 | -6 | +2 | +0 | +0 | +0 | +0 | +43 | +0 | +0 | -5 | -5 | -2 | reject_or_rework |
| `galvanoth_topdeck_freecast_cut_squelcher` | Galvanoth | Hexing Squelcher | 8-19 | 6-21 | -7.41 | -66.67 | +5 | -3 | +0 | +0 | +0 | +0 | +28 | +0 | +0 | -5 | -4 | -4 | reject_or_rework |
| `penance_topdeck_protection_cut_squelcher` | Penance | Hexing Squelcher | 8-19 | 6-21 | -7.41 | -44.45 | +9 | -1 | +0 | +0 | +0 | +0 | +36 | +0 | +0 | -5 | -5 | -4 | reject_or_rework |
| `core_challenge_aetherflux_over_storm` | Aetherflux Reservoir | Storm Herd | 8-19 | 5-22 | -11.11 | -66.67 | -3 | -14 | +0 | +0 | +0 | +0 | +9 | +0 | +0 | -3 | -4 | -3 | reject_or_rework |
| `faithless_looting_squee_enabler` | Faithless Looting | Hexing Squelcher | 8-19 | 4-23 | -14.82 | -66.67 | +4 | +6 | +0 | +0 | +0 | +0 | +25 | +0 | +0 | +0 | -5 | -3 | reject_or_rework |
| `one_ring_protection_draw_cut_squelcher` | The One Ring | Hexing Squelcher | 8-19 | 4-23 | -14.82 | -77.78 | -9 | -17 | -30 | -27 | -3 | +0 | -7 | +0 | +0 | -2 | -3 | -2 | reject_or_rework |
| `angel_grace_life_floor_cut_dawn` | Angel's Grace | Dawn's Truce | 8-19 | 3-24 | -18.52 | -88.89 | -7 | -8 | -8 | -10 | +2 | +0 | +1 | +0 | +0 | -8 | -1 | -1 | reject_or_rework |
| `enlightened_engine_access_cut_thor` | Enlightened Tutor | Thor, God of Thunder | 8-1 | 4-5 | -44.45 | -44.45 | -15 | -21 | -9 | -6 | -3 | +0 | -43 | +0 | +0 | -5 | -7 | -5 | reject_or_rework |
| `boseiju_spell_protection_land` | Boseiju, Who Shelters All | Reliquary Tower | 8-1 | 3-6 | -55.56 | -55.56 | -21 | -22 | -16 | -13 | -3 | +0 | -58 | +0 | +0 | -2 | -5 | -3 | reject_or_rework |
| `galvanoth_topdeck_freecast_cut_thor` | Galvanoth | Thor, God of Thunder | 8-1 | 3-6 | -55.56 | -55.56 | -19 | -24 | -9 | -6 | -3 | +0 | -53 | +0 | +0 | -4 | -2 | +0 | reject_or_rework |
| `gamble_access_cut_thor` | Gamble | Thor, God of Thunder | 8-1 | 3-6 | -55.56 | -55.56 | -16 | -21 | -9 | -6 | -3 | +0 | -34 | +0 | +0 | -3 | -1 | -1 | reject_or_rework |
| `boros_charm_pressure_cut_fated` | Boros Charm | Fated Clash | 8-1 | 0-9 | -88.89 | -88.89 | -24 | -24 | -7 | -4 | -3 | +0 | -63 | +0 | +0 | -2 | -7 | -5 | reject_or_rework |

Read: Brainstone can improve weak seeds when it preserves the ramp shell, but the Hexing Squelcher cut is only aggregate-neutral and collapses seed 42, so it is not a deck insert. Ghostly Prison was a coherent pressure hypothesis, but the retest avoiding the old High Noon cut still lost aggregate. The One Ring does not justify the slot here despite the Mind Stone interaction idea; it reduced the aggregate result and the Library discard-to-top metrics. Angel's Grace confirms that a one-mana life-floor can help seed 20260625, but replacing Dawn's Truce destroys seed 42 and loses aggregate, so this exact protection swap is rejected. Faithless Looting does not prove the intended Squee-discard loop here and loses badly overall. The original Galvanoth/Bender's Waterskin swap is the only positive aggregate signal, but it loses the strong seed 42; the follow-ups cutting Hexing Squelcher, Victory Chimes, or Thor are worse on seed 42, so Galvanoth stays a probation hypothesis, not a deck insert. Primal Amulet over Bender's Waterskin repeats the same weak-seed improvement and strong-seed collapse pattern, so Bender is not a free cut. Gamble over Creative Technique shows that cheap universal access can help weak seeds, but the current result still breaks seed 42, so it is probation/rework rather than a deck change. The Thor-cut access retests were worse on seed 42, so Thor is not the clean cut for tutor access despite being modeled-not-deck-proven. Boseiju over Reliquary Tower preserves land count and spell-protection rules but still collapses seed 42, so land-slot anti-counter protection is not the current missing piece. Boros Charm over Fated Clash collapsed seed 42 completely, so Fated Clash is not a free slow-response cut even for a cheaper pressure card. Dance with Calamity and Aetherflux Reservoir both improve some weak seeds over Storm Herd, but both lose aggregate and break seed 42, so Storm Herd remains protected for now. Birgi proves the new spell-cast mana telemetry can fire, but it does not improve results alone. Birgi + Seething Song over both medallions improves the weak seeds while losing badly on seed 42, so medallions are part of the strong-seed conversion pattern and the ritual lane needs a different cut before any promotion. Penance did not fire its hand-to-library activation in this gate, so it is not evidence for a working topdeck-protection engine yet.

## Cut-Safety-Aware Safe Queue V3

This queue was generated after the cut-safety manifest blocked the earlier package list. Every row below cleared cut-safety and prior-exact-package preflight, then ran as an isolated smoke gate against real opponents. Because the baseline was 3-0 in this smoke, any negative result is treated as no-promotion evidence, not as permission to mutate the deck.

| Package | Adds | Cuts | Baseline | Candidate | Delta pp | Miracle | Topdeck | Spell | Mana Trigger | Birgi Mana | Ritual | Decision |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `overmaster_protect_draw_cut_tibalts_trickery` | Overmaster | Tibalt's Trickery | 3-0-0 | 2-1-0 | -33.33 | -7 | -12 | -22 | +0 | +0 | +2 | watch_only_needs_stronger_justification |
| `storm_kiln_artist_cut_arcane_signet` | Storm-Kiln Artist | Arcane Signet | 3-0-0 | 1-2-0 | -66.67 | -6 | -7 | -22 | +0 | +0 | +0 | smoke_negative_do_not_promote |
| `birgi_spellchain_cut_jeskas_will` | Birgi, God of Storytelling // Harnfel, Horn of Bounty | Jeska's Will | 3-0-0 | 0-3-0 | -100.00 | -13 | -12 | -38 | +1 | +1 | +0 | smoke_negative_do_not_promote |
| `boros_charm_pressure_cut_avatar_wrath` | Boros Charm | Avatar's Wrath | 3-0-0 | 0-3-0 | -100.00 | -7 | -6 | -21 | +0 | +0 | +0 | smoke_negative_do_not_promote |
| `ghostly_prison_pressure_cut_promise` | Ghostly Prison | Promise of Loyalty | 3-0-0 | 0-3-0 | -100.00 | -10 | -11 | -27 | +0 | +0 | +0 | smoke_negative_do_not_promote |
| `runaway_steamkin_cut_talisman` | Runaway Steam-Kin | Talisman of Conviction | 3-0-0 | 0-3-0 | -100.00 | -13 | -11 | -35 | +0 | +0 | +0 | smoke_negative_do_not_promote |
| `seething_song_cut_fellwar_stone` | Seething Song | Fellwar Stone | 3-0-0 | 0-3-0 | -100.00 | -8 | -8 | -22 | +0 | +0 | +0 | smoke_negative_do_not_promote |

Read: this is the strongest current evidence against replacing generic ramp/support slots blindly. Birgi, Seething Song, Storm-Kiln Artist, and Runaway Steam-Kin all reduced the miracle/topdeck conversion pattern in the smoke. Boros Charm and Ghostly Prison still did not solve pressure when moved to safer non-protected cuts. Overmaster is the only watch-list row because it retained two wins, but it still trailed the current shell and needs a different, explicit follow-up before any deeper gate.

## Current Champion Card-Role Coverage

- Quantity: `100` across `94` rows.
- Primary role counts: `{"board_wipe": 6, "creature": 2, "draw": 12, "engine": 3, "land": 34, "protection": 9, "ramp": 15, "removal": 7, "tutor": 1, "unknown": 2, "wincon": 9}`
- Slot decision counts: `{"core_engine_or_probation": 22, "core_finisher": 1, "core_support": 21, "finisher_benchmark_lane": 2, "flex_but_cut_risky": 1, "flex_cut_tested_negative": 2, "locked_core": 1, "mana_base_core": 28, "manual_review": 1, "modeled_not_deck_proven": 1, "modeled_pending_durable_sync": 5, "probation_engine": 1, "support_flex": 8}`
- Package lane counts: `{"commander_engine": 1, "contextual": 1, "early_mana": 14, "finisher_or_big_spell": 4, "graveyard_recursion": 7, "hand_filter": 11, "interaction": 8, "mana_base": 28, "pressure_absorber_or_protection": 12, "selection": 1, "topdeck_miracle_setup": 7}`
- Missing aggregated battle-rule rows in the legacy champion DB: `7` cards: The Scarlet Witch, Molecule Man, The Mind Stone, Thor, God of Thunder, Emeria's Call // Emeria, Shattered Skyclave, Tragic Arrogance, Squee, Goblin Nabob.
- Superseded by rule-materialization audit: `Squee, Goblin Nabob` now has materialized rule evidence in the equal-gate candidate.
- Effective unresolved rule rows after only that audit: `6` cards: The Scarlet Witch, Molecule Man, The Mind Stone, Thor, God of Thunder, Emeria's Call // Emeria, Shattered Skyclave, Tragic Arrogance.
- Reclassified by remaining-row audit as deck materialization gaps: `Emeria's Call // Emeria, Shattered Skyclave, Molecule Man, The Mind Stone, The Scarlet Witch, Tragic Arrogance`.
- Effective unresolved rule/model rows after deck materialization evidence: `1` cards: Thor, God of Thunder.
- Reclassified by Thor runtime audit as local reviewed rule added pending durable sync: `Thor, God of Thunder`.
- Effective unresolved local runtime/model rows after Thor audit: `0` cards: none.
- Full per-card role, tags, rule keys, package lane, and slot decision are in the companion JSON under `deck_summaries.6.cards` and `card_decision_manifest.cards`.

## Cut Safety Manifest

- Summary: `{"locked_do_not_cut": 9, "risky_cut_only_same_lane": 2}`; tested cuts `11`, blocked/protected cuts `11`, untested flex pool `6`.

| Card | Status | Lane | Role | Worst Seed 42 pp | Best Delta pp | Worst Delta pp | Obs | Read |
| --- | --- | --- | --- | ---: | ---: | ---: | ---: | --- |
| Dawn's Truce | `locked_do_not_cut` | hand_filter | protection | -88.89 | -18.52 | -18.52 | 1 | one or more packages collapsed the known strong seed when cutting this slot |
| Fated Clash | `locked_do_not_cut` | pressure_absorber_or_protection | removal | -88.89 | -88.89 | -88.89 | 1 | one or more packages collapsed the known strong seed when cutting this slot |
| Hexing Squelcher | `locked_do_not_cut` | contextual | creature | -77.78 | +0.00 | -14.82 | 7 | one or more packages collapsed the known strong seed when cutting this slot |
| Pearl Medallion | `locked_do_not_cut` | early_mana | ramp | -55.56 | +0.00 | +0.00 | 1 | one or more packages collapsed the known strong seed when cutting this slot |
| Reliquary Tower | `locked_do_not_cut` | mana_base | land | -55.56 | -55.56 | -55.56 | 1 | one or more packages collapsed the known strong seed when cutting this slot |
| Ruby Medallion | `locked_do_not_cut` | early_mana | ramp | -55.56 | +0.00 | +0.00 | 1 | one or more packages collapsed the known strong seed when cutting this slot |
| Storm Herd | `locked_do_not_cut` | finisher_or_big_spell | wincon | -88.89 | -3.70 | -11.11 | 2 | one or more packages collapsed the known strong seed when cutting this slot |
| Thor, God of Thunder | `locked_do_not_cut` | graveyard_recursion | spell_damage_engine | -55.56 | -44.45 | -55.56 | 3 | one or more packages collapsed the known strong seed when cutting this slot |
| Victory Chimes | `locked_do_not_cut` | early_mana | ramp | -55.56 | -3.70 | -3.70 | 1 | one or more packages collapsed the known strong seed when cutting this slot |
| Bender's Waterskin | `risky_cut_only_same_lane` | early_mana | ramp | -44.45 | +3.70 | -7.41 | 3 | aggregate upside exists, but it broke the known strong seed |
| Creative Technique | `risky_cut_only_same_lane` | finisher_or_big_spell | big_spell_value | -44.45 | +3.70 | +3.70 | 1 | aggregate upside exists, but it broke the known strong seed |

- Untested flex pool sample: `Arcane Signet`, `Boros Signet`, `Fellwar Stone`, `Jeska's Will`, `Sol Ring`, `Talisman of Conviction`.

## Strategy Dependency Map

- Current benchmark contract: `candidate_607_squee_hashseed0_isolated_cached_timeout_v3` `24-66-0` (26.67%) vs `deck_607` `21-69-0` (23.33%) and `deck_6` `16-74-0` (17.78%).
- Read: a new idea must improve a named pillar and preserve the benchmark pattern. A card being popular externally or cut-safe locally only creates a hypothesis.

| Pillar | Depends On | Current Evidence | Risk | Next Requirement |
| --- | --- | --- | --- | --- |
| `topdeck_miracle_setup` | Library of Leng, Scroll Rack, Sensei's Divining Top, Molecule Man, Bender's Waterskin | seed42 library gate: discard_to_top=16, topdeck=30, miracle=33 | seed 7 shows the deck can miss the engine entirely | improve early access or topdeck quality without reducing seed-42 miracle/topdeck counts |
| `spell_chain_conversion` | Ruby Medallion, Pearl Medallion, Jeska's Will, Big Score, Unexpected Windfall | Birgi and Seething Song produced mana telemetry, but medallion cuts broke seed 42 | ritual mana that lowers miracle density or removes persistent reducers is not a win | preserve at least one medallion or prove the cut in a same-lane seed-42 benchmark |
| `pressure_absorption` | Dawn's Truce, Teferi's Protection, High Noon, Fated Clash, Hexing Squelcher | classified baseline losses: 3 rows, all focused on combat-pressure/life-zero failure modes | cheap protection swaps can help weak seeds while destroying the known strong seed | target survival/second-window conversion while preserving the existing protection shell |
| `deterministic_finishers` | Approach of the Second Sun, Storm Herd, Mizzix's Mastery, Surge to Victory | Dance with Calamity and Aetherflux Reservoir lost the Storm Herd slot benchmark | replacing finishers with generic value lowers closing certainty | benchmark finishers against Approach/Storm Herd lanes, not against unrelated support slots |
| `graveyard_recursion` | Squee, Goblin Nabob, Pinnacle Monk // Mystic Peak, Mizzix's Mastery | Squee champion 24-66-0 vs deck_607 21-69-0; squee_return=12 | Squee returns are proven after graveyard entry, but Lorehold discard-to-Squee is still not proven | test recursion as a package only when the gate tracks actual discard/graveyard entry route |

- Locked/protected cuts: `Dawn's Truce`, `Fated Clash`, `Hexing Squelcher`, `Pearl Medallion`, `Reliquary Tower`, `Ruby Medallion`, `Storm Herd`, `Thor, God of Thunder`, `Victory Chimes`.
- Risky same-lane-only cuts: `Bender's Waterskin`, `Creative Technique`.
- Package learning summary: post-Squee decisions `{"probation_deeper_gate_only": 2, "reject_or_rework": 19}`, safe-queue watch `1`, safe-queue rejected `6`.

| Probation / Watch Item | Adds | Cuts | Delta pp | Seed 42 pp | Decision |
| --- | --- | --- | ---: | ---: | --- |
| `galvanoth_topdeck_freecast` | Galvanoth | Bender's Waterskin | +3.70 | -44.45 | `probation_deeper_gate_only` |
| `gamble_approach_access_cut_creative` | Gamble | Creative Technique | +3.70 | -44.45 | `probation_deeper_gate_only` |
| `overmaster_protect_draw_cut_tibalts_trickery` | Overmaster | Tibalt's Trickery | -33.33 | +0.00 | `watch_only_needs_stronger_justification` |

| Variant | Action | Reason |
| --- | --- | --- |
| `deck_607` VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 | `baseline_shell` | best structural match to commander intent and the current benchmark shell |
| `deck_615` VARIANT Lorehold Variant 10 - Rafael Paste 2026-06-24 | `extract_controlled_packages_only` | high structural rank but many slot changes; test one package at a time against 607+Squee |
| `deck_614` VARIANT Lorehold Variant 09 - Rafael Paste 2026-06-24 | `extract_controlled_packages_only` | high structural rank but many slot changes; test one package at a time against 607+Squee |
| `deck_616` VARIANT Lorehold Variant 11 - Rafael Paste 2026-06-24 | `do_not_import_full_list` | land count below current guardrail; use only isolated ideas if battle-ready |
| `deck_612` VARIANT Lorehold Variant 07 - Rafael Paste 2026-06-24 | `do_not_import_full_list` | land count below current guardrail; use only isolated ideas if battle-ready |

Next hypothesis contract:
- Promotion bar: tie or beat the Squee champion aggregate record across the same seed/opponent window
- Promotion bar: do not regress seed 42 unless a larger gate proves the strong-seed pattern moved elsewhere
- Promotion bar: do not promote from popularity or static structure without battle evidence
- Promotion bar: a negative smoke result remains no-promotion unless a specific failure classifier target explains why to override it
- Must target: seed 7: missing early topdeck/Library/Squee engine
- Must target: seed 20260625: engine appears but fails to convert Approach/topdeck loops into survival or a second win window
- Must target: combat-pressure/life-zero losses without cutting the known protection shell
- Required telemetry: miracle_cast and topdeck_manipulation_activated must not fall in the strong seed
- Required telemetry: discard_to_top_replacement should connect to survival, Approach recast, or a finisher window
- Required telemetry: spell_cast_mana_trigger or ritual_mana_added is useful only if win rate and seed-42 conversion survive
- Required telemetry: Squee value must be tied to observed graveyard entry route, not assumed discard synergy
- Hard reject if: candidate cuts a locked/protected card without same-lane proof
- Hard reject if: candidate only adds generic ramp/value and lowers miracle/topdeck/spell volume
- Hard reject if: candidate wins weak seeds but collapses seed 42 in the first controlled gate
- Hard reject if: candidate depends on a card with unresolved battle runtime/model evidence

## What Still Must Be Understood

- Use the per-game Squee diagnostic to decide whether the next improvement is topdeck consistency, explicit discard/rummage enablement, or a different closing package.
- Treat Squee as a provisional micro-upgrade, not a promoted final deck slot, until a support package or alternative cut shows a larger reproducible edge.
- Make all decisive battle gates run with `PYTHONHASHSEED=0`, `--isolate-deck-process`, and per-game timeout; same simulation seed without fixed hash seed/process isolation is not enough for deck promotion.
- Review DB-role versus effective-role divergences surfaced by the card-role manifest, especially cards stored as `draw` or `unknown` while functioning as protection, removal, miracle engine, or board wipe.
- `Thor, God of Thunder` now has a local reviewed runtime rule and one natural synced-rule battle exposure for 7 damage, but the checked 21-game candidate sample had +0.00 pp win-rate delta; keep it as modeled-but-not-proven until a stratified or larger gate proves deck value.
- Separate finalizer slots from engine slots: Dance with Calamity and Aetherflux Reservoir have now failed the Storm Herd slot benchmark; remaining finalizer work should focus on other closing packages or different cuts, not repeating those two swaps.
- Re-test 615 and 614 only as controlled packages against the 607+Squee champion; their full-deck changes are too broad to diagnose one cause.
- Keep runtime-rule readiness in the decision loop; a card with a good paper function cannot be rejected until the battle model understands the relevant effect family.
- Treat PG245 cards as modeled-but-not-durable hypotheses: Twinflame Tyrant and Verge Rangers now have runtime-backed package proposals, but PostgreSQL precheck is blocked, so they need PG apply/sync or isolated materialized gates before deck-value judgment.
- Use the consolidated runtime-candidate readiness queue as the strategy gatekeeper: Hidden Retreat is package-prepared pending PG approval, Twinflame Tyrant and Verge Rangers are precheck-blocked, and split-scope/manual-mapper cards should not be treated as strategic failures yet.
- Library of Leng is now measurable in battle telemetry; separate missing-engine games from games where discard-to-top happens but fails to convert before life-total pressure.
- The first Library/pressure retest rejected Brainstone, Ghostly Prison, and The One Ring over Hexing Squelcher; future tests need a new cut logic or a narrower per-game failure target.
- Angel's Grace over Dawn's Truce confirms that one-mana life-floor protection can improve a weak seed but is not free; cutting the existing protection shell breaks seed 42 completely.
- Birgi + Seething Song over Pearl/Ruby Medallion confirms the ritual lane can help weak seeds, but cutting both medallions breaks seed 42; treat medallions as protected until a same-lane benchmark proves a safer cut.
- Primal Amulet over Bender's Waterskin confirms the revised top-freecast/cost-reduction lane can help weak seeds, but the Bender cut still breaks seed 42; treat Bender as protected until a same-slot benchmark preserves the strong seed.
- Gamble over Creative Technique is now a resolved probation clue: it improves aggregate and weak seeds but breaks seed 42, so the tutor lane needs a different cut or stronger exposure before promotion.
- Gamble or Enlightened Tutor over Thor failed seed-42 triage; do not treat Thor as the obvious tutor-access cut just because Thor is not deck-proven yet.
- Galvanoth over Thor also failed seed-42 triage; Thor is not a clean cut for either the tutor-access lane or the topdeck/freecast lane from current evidence.
- Boseiju, Who Shelters All over Reliquary Tower failed seed-42 triage; anti-counter land-slot protection does not address the observed life-zero combat-pressure losses by itself.
- Boros Charm over Fated Clash failed seed-42 triage at 0-9; protect Fated Clash until a same-lane replacement proves it can preserve the strong seed.
- The cut-safety manifest now blocks repeated cuts that already collapsed seed 42 and separates them from unresolved flex slots; use that manifest before generating another package.
- The safe queue v3 proves that avoiding protected cuts is necessary but not sufficient: all seven cut-safe smoke packages were still worse than the baseline, so a future package needs a positive strategic reason plus a clean cut, not only cut-safety clearance.

## Next Gates

- Keep the regression assertion that every `squee_upkeep_return` has an earlier same-game `squee_to_graveyard` or equivalent zone-entry event with source reason.
- Build the next pressure/conversion package only after selecting a cut that preserves Dawn's Truce, Teferi's Protection, High Noon, Hexing Squelcher, Storm Herd, and the three-mana ramp shell unless a direct same-slot benchmark proves otherwise.
- Do not repeat Brainstone, Ghostly Prison, or The One Ring over Hexing Squelcher from the current evidence; only retest them if the failure classifier identifies a different cut or a narrower matchup-specific role.
- Do not promote Angel's Grace over Dawn's Truce; any future Angel's Grace test must be a different cut and must preserve seed 42.
- Do not promote Faithless Looting from the current package gate; it did not increase Squee graveyard/return enough and lost aggregate win rate.
- Do not promote Galvanoth, Dance with Calamity, or Aetherflux Reservoir from current gates; each either loses aggregate or breaks the known strong seed 42.
- Do not promote Birgi + Seething Song over Pearl/Ruby Medallion; any future ritual package must preserve at least one medallion or prove the medallion cut with a stronger seed-42 result.
- Do not promote Primal Amulet over Bender's Waterskin; future topdeck/freecast work needs a different cut or a deeper Galvanoth-style exposure gate that preserves seed 42.
- Do not promote Gamble over Creative Technique from the current gate; if continuing tutor access, preserve seed 42 and test a different cut or a narrower access package rather than assuming the tutor lane is solved.
- Do not continue tutor-access testing by cutting Thor unless a new hypothesis explains why the seed-42 collapse would not repeat.
- Do not continue topdeck/freecast testing by cutting Thor unless a new hypothesis explains why the seed-42 collapse would not repeat.
- Do not promote Boseiju over Reliquary Tower from the current land-slot gate; future spell-protection work should include pressure absorption or a conversion-speed gain, not only anti-counter text.
- Do not cut Fated Clash for cheap pressure protection from the current evidence; if Boros Charm is retested, it needs a different cut with an explicit reason.
- Before registering any new package, reject the candidate if every proposed cut is locked or protected by the cut-safety manifest and the package has no explicit same-lane proof rationale.
- Before deep-gating any future cut-safe package, require either a positive smoke result, a matchup-specific failure classifier target, or an explicit reason why a negative smoke should be overridden; the v3 safe queue produced no direct promotion.
- Use the generated card-role manifest to mark each card as core, flex, or unresolved before proposing the next swap.
- Use deck-wide rule materialization in the equal-gate loader for every candidate snapshot, then run battle-card-specific tests only for cards with no active reviewed/runtime rule row.
- For PG245 runtime-package cards, rerun PostgreSQL precheck first; if PG remains unavailable, test them only through an isolated candidate DB with the generated rule rows materialized and clearly labelled as non-durable.
- For PG244 Hidden Retreat, apply only after explicit precheck/apply/postcheck approval and then sync Hermes before judging the topdeck-protection/access package in battle.
- For split-scope runtime families, start with the seven non-manual candidates before touching the 52 manual mapper rows, because they can reduce the queue through focused runtime tests instead of one-card strategy guessing.
- For Thor, the next decisive test is a stratified exposure gate or larger sample; temporary graveyard recast from ETB is still a separate runtime/model gap.

## External Method Sources

- [EDHREC Lorehold commander page](https://edhrec.com/commanders/lorehold-the-historian): commander-specific package comparison lane.
- [EDHREC Lorehold cEDH average deck](https://edhrec.com/average-decks/lorehold-the-historian/cedh): external cross-check for ritual package, Birgi, Seething Song, and medallion retention.
- [Reddit EDHBrews Lorehold thread](https://www.reddit.com/r/EDHBrews/comments/1s8q5nm/lorehold_the_historian/): player-reported failure mode: fizzling, gas depletion, and difficulty finding a win condition.
- [EDHREC spellslinger Commander guide](https://edhrec.com/guides/edhrec-guide-to-spellslinger-in-commander): spellslinger criteria: card flow, cheap interaction, protection, recursion, payoffs.
- [EDHREC Commander deckbuilding guide](https://edhrec.com/articles/how-to-build-a-commander-deck): baseline structure guardrails for lands, ramp, draw, removal, and focused packages.
- [Archidekt Lorehold corpus](https://archidekt.com/commanders/Lorehold%2C%20the%20Historian): user-built Lorehold shells and recurring package choices.
- [Card Kingdom Lorehold synergy article](https://blog.cardkingdom.com/10-crazy-synergy-cards-for-lorehold-the-historian-secrets-of-strixhaven/): external confirmation that Library of Leng and topdeck/discard loops are a commander-specific synergy lane.
- [Draftsim Lorehold EDH deck tech](https://draftsim.com/lorehold-the-historian-edh-deck/): external deck-tech framing for miracle setup, draw timing, and support packages.
