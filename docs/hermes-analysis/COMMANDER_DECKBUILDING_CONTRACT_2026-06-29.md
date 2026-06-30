# Commander Deckbuilding Contract - 2026-06-29

Status: `frozen_operating_contract`.

This file freezes the operating contract for ManaLoom Commander deckbuilding.
It is separate from `XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md` and
`BATTLE_RULES_FAMILY_PIPELINE_CONTRACT_2026-06-29.md`.

Card-rule work answers: "can the battle runtime execute this card correctly?"
Deckbuilding work answers: "does this commander deck have the right plan,
package density, legality, source provenance, and battle proof?"

## Research-Backed Deck Planning Flow

External research was reviewed on 2026-06-29 and folded into the current
ManaLoom deckbuilding contract. The relevant learning is not "copy one public
template"; it is a planning order:

1. validate Commander format, color identity, singleton, commander count, and
   intended power bracket;
2. read the commander as the deck's strategic center: what it enables, what
   it pays off, when it must be cast, and what failure modes kill it;
3. state the primary and backup win plans before selecting flex cards;
4. build the mana foundation and curve first: lands, color sources, ramp type,
   commander turn target, and whether ramp competes with the commander's curve;
5. add card flow: draw, selection, rummage, impulse, tutors, and engines that
   let the deck keep executing after the opening setup;
6. add interaction and survival: targeted removal, protection/resilience,
   board wipes, graveyard hate or table-specific answers;
7. fill commander-specific package lanes: enablers, payoffs, recursion,
   pressure absorbers, and any mechanic the commander uniquely exploits;
8. check deterministic win lines, combo packages, or finishers through
   Commander Spellbook/public primers/reference corpus;
9. score public reference decks and EDHREC data as evidence lanes, not as
   automatic truth;
10. cut by lane: each added card must compete with the same functional slot or
    carry an explicit package hypothesis and equal-gate evidence;
11. validate by legal service, strategy matrix, goldfish/curve checks, battle
    gates, and replay traces, then iterate.

Canonical planning flow identifiers exposed by backend diagnostics:

1. `format_legality_and_power_bracket`
2. `commander_intent_and_archetype`
3. `primary_and_backup_win_plan`
4. `mana_foundation_and_curve`
5. `card_flow_and_resource_engine`
6. `interaction_protection_and_resilience`
7. `commander_specific_packages`
8. `combo_synergy_and_finishers`
9. `reference_corpus_and_learned_usage`
10. `lane_balanced_cuts_and_anchor_protection`
11. `goldfish_battle_replay_iteration`

Current source learning:

| Source | URL | Learning imported into ManaLoom | Guardrail |
| --- | --- | --- | --- |
| Wizards Commander format page | https://magic.wizards.com/en/formats/commander | official 99+1 shape, singleton, color identity, multiplayer/power bracket framing | legality and bracket only, not strategy quality |
| EDHREC Commander deckbuilding guide | https://edhrec.com/articles/how-to-build-a-commander-deck | deckbuilding starts from categories and then checks whether the list plays the intended way | category counts are starting points, not final proof |
| The Command Zone template discussion via EDHREC | https://edhrec.com/articles/the-command-zone-commander-deckbuilding-template-for-the-new-era-the-command-zone-658-mtg-edh-magic-gathering | Commander decks need balanced ratios of ramp, draw, disruption, and related roles | template ratios must bend to commander intent and table speed |
| EDHREC ramp guide | https://edhrec.com/guides/the-edhrec-guide-to-ramp-in-commander | ramp is about playing ahead of curve; commander mana value and ramp timing matter | "more mana" is not enough if ramp competes with the commander turn |
| BinderBrew Commander template | https://binderbrew.com/commander-deck-building-template | core slots are lands, ramp, draw, removal before commander-specific payoffs | template is flexible by power, budget, theme, and commander |
| Card Kingdom ramp/draw article | https://blog.cardkingdom.com/whats-better-in-commander-card-draw-or-ramp/ | ramp, draw, removal, and recursion are structural pillars | pillar counts do not replace package synergy or battle proof |
| Commander Spellbook | https://commanderspellbook.com/ | combo package discovery, variants, bracket hints, and deterministic finishers | combo relation is not full deck balance or runtime proof |

## Lane Order And Deck Overview Contract

Every generated or optimized Commander deck must expose this lane order in
diagnostics and use it when deciding cuts:

1. `legal_identity`
2. `power_bracket`
3. `commander_intent`
4. `win_plan`
5. `mana_base`
6. `ramp`
7. `curve`
8. `card_draw_selection`
9. `tutors_access`
10. `interaction_removal`
11. `protection_resilience`
12. `board_wipes`
13. `recursion_recovery`
14. `commander_synergy_engine`
15. `payoffs_finishers`
16. `combo_lines`
17. `meta_pressure_answers`
18. `budget_collection_constraints`
19. `same_lane_cuts`
20. `battle_and_replay_validation`

The deck overview is not allowed to be a loose card list. It must include:

- one sentence for the commander's intended game plan;
- target power bracket or documented unknown bracket;
- primary and backup win lines;
- role counts versus commander-specific targets;
- mana curve and color-source/ramp summary;
- package lanes with key cards, enablers, payoffs, and protected anchors;
- source provenance for important cards;
- cut rules and cross-lane tradeoffs;
- known risks, validation status, battle status, and next gate.

Canonical deck overview field identifiers exposed by backend diagnostics:

1. `commander_plan_sentence`
2. `power_bracket_target`
3. `primary_win_lines`
4. `backup_win_lines`
5. `role_counts_vs_targets`
6. `mana_curve_and_sources`
7. `package_lanes_with_key_cards`
8. `source_provenance_by_anchor`
9. `protected_anchors_and_cut_rules`
10. `known_risks_and_validation_status`

## Frozen Decision

Do not optimize every commander by copying the current Lorehold deck 607 flow.
Use one Commander deckbuilding pipeline for all commanders:

1. official format and card-data validation;
2. commander intent profile;
3. external/reference corpus;
4. learned deck and local usage evidence;
5. deterministic legal shell;
6. optimizer or AI proposal;
7. validation, strategy matrix, and battle gate.

For Lorehold specifically, deck `607` is the current protected structural
baseline, not universal truth. A future Lorehold candidate can replace it only
when it ties or beats the protected baseline under the same strategy and battle
gate rules.

## Source Hierarchy

| Source lane | Use for | Must not be used for |
| --- | --- | --- |
| Official Commander rules | 100-card shape, commander requirement, singleton, color identity, ban/legal framing | Card popularity or strategic package proof |
| Scryfall and MTGJSON | Identity, Oracle text, layout, legality, rulings, hashes, resolver inputs | Commander-specific strategic quality by itself |
| EDHREC | Commander-specific popular cards, themes, role expectations, aggregate strategy signals | Exact deck copying or executable battle-rule truth |
| Moxfield, Archidekt, public decklists | Reference corpus, recurring package choices, sample shells, bracket/style clues | Automatic promotion without legality/source validation |
| Commander Spellbook | Combo package discovery and deterministic synergy candidates | General deck balance or rule execution by itself |
| Local learned decks | Product-specific successful candidates and prior promoted shells | Replacing source provenance or current legality checks |
| ManaLoom battles/replays | Outcome proof, pressure matchup proof, drawn/cast/used evidence for chosen cards | Card-level rule proof unless the card was exercised |
| XMage | Runtime/rule behavior reference for cards used by decks | Deck popularity, intent, or metagame quality |

## Required Contract Per Commander

Before a commander is considered deckbuilder-ready, the project must have:

- a resolved commander identity and legal color identity;
- a usable commander profile or a documented fallback reason;
- role targets for land, ramp, draw, removal, protection, board wipes,
  recursion, tutors, win conditions, and commander-specific packages;
- at least one source-backed reference lane:
  `commander_reference_card_stats`, `commander_reference_deck_analysis`,
  EDHREC/cache, public corpus, or active learned deck;
- a deterministic fallback that produces a legal deck without unresolved cards;
- validation through `GeneratedDeckValidationService`;
- provenance diagnostics that show which source lane placed each important
  card;
- a strategy matrix or equivalent scorer before battle;
- battle gate proof for promoted structural changes.

If a commander has no reliable external/reference corpus, the deckbuilder must
return a conservative legal deck with diagnostics instead of pretending that
generic Commander heuristics are commander-specific proof.

## Lorehold Current Contract

Current commander intent:

> Use topdeck setup, hand filtering, and Lorehold's commander discount to cast
> high-impact instant/sorcery spells ahead of curve, then convert that window
> into a deterministic finisher while surviving fast combat pressure.

Required Lorehold package lanes:

| Lane | Meaning |
| --- | --- |
| `early_plan` | early mana, low-cost setup, cheap protection, early interaction |
| `topdeck_miracle_setup` | topdeck control and first-draw setup for miracle timing |
| `hand_filter` | rummage, wheels, discard/draw setup, hand smoothing |
| `spell_chain_conversion` | instants/sorceries, copy engines, cost reducers, ritual turns |
| `protection_window` | cards that keep the critical spell turn from being stopped |
| `pressure_absorber` | cards that stop fast combat decks from killing Lorehold first |
| `graveyard_recursion` | secondary value from discarded or used spells |
| `deterministic_finisher` | clear ways to close after the discounted spell window |

Current Lorehold evidence generated on 2026-06-29:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_strategy_matrix_20260629_deckbuilding_contract.md`
- `server/test/artifacts/commander_generate_provenance_20260629_deckbuilding_contract/commander_generate_provenance_summary.json`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_artifact_contract_audit_20260629_current.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_promotion_gate_decision_audit_20260629_real8_games3_seed42_7_20260625.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260629_v615_mana_engine_v1.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260629_v615_mana_engine_v1.decklist.txt`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_strategy_matrix_20260629_v615_mana_engine_candidate_v1.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_decision_audit_20260629_v615_mana_engine_v1.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_artifact_contract_audit_20260629_v615_mana_engine_current.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_cut_methodology_reaudit_20260629.md`

The current canonical Lorehold strategy matrix JSON schema is
`decks[] + ranked_deck_keys`. Historical `ranked_decks` reports are supported
only through `lorehold_artifact_contract_audit.py` as legacy artifacts; they
must not be consumed directly by continuation gates or deck-change logic.

Current structural ranking from decks `607-616`:

1. `607`: score `141.2`, intent `100.0`, rule-ready `100.0%`.
2. `615`: score `134.8`, intent `97.2`, rule-ready `98.8%`.
3. `614`: score `131.7`, intent `95.6`, rule-ready `100.0%`.

Interpretation:

- `607` remains the protected baseline because it is structurally aligned and
  fully rule-ready.
- `615` and `614` are close enough to keep as serious candidates, especially
  because they contain strong package signals such as Birgi/Mana Vault and
  Aetherflux-style spell conversion.
- None of these three is final from structure alone. The next decision must use
  an equal battle gate and decision trace inspection.

Promotion-gate decision generated on 2026-06-29:

- Scope: natural equal battle gate, no forced access, 8 real opponents,
  3 games per opponent, simulation seeds `42`, `7`, and `20260625`.
- Aggregate result: `607` = `18/72` wins, `615` = `16/72`, `614` = `14/72`.
- Fast-pressure check against Winota: `607` = `1/9`, `615` = `3/9`,
  `614` = `0/9`.
- Decision: keep `607` as protected baseline. No challenger is ready for a
  real deck replacement.
- Follow-up: `615` is the best package-learning candidate because its traces
  show real Mana Vault, Birgi, Sensei's Divining Top, The One Ring, and
  Mizzix's Mastery usage, but this supports a narrow package/cut experiment,
  not a whole-deck swap.

Narrow package decision generated on 2026-06-29, then corrected by cut-method
reaudit:

- Candidate: `candidate_607_v615_mana_engine_v1`, built from protected `607`.
- Adds from `615`: `Mana Vault`, `Birgi, God of Storytelling // Harnfel, Horn
  of Bounty`, and `The One Ring`.
- Cuts from `607`: `Bender's Waterskin`, `The Scarlet Witch`, and `Molecule
  Man`.
- Structural matrix result: candidate rank `1`, `607` rank `2`, `615` rank
  `3`, `614` rank `4`.
- Natural equal battle gate: `candidate_607_v615_mana_engine_v1` = `18/72`,
  `607` = `18/72`, `615` = `16/72`, `614` = `14/72`.
- Seed windows for the candidate: seed `42` = `6/24`, seed `7` = `2/24`,
  seed `20260625` = `10/24`.
- Fast-pressure Winota check: candidate = `1/9`, `607` = `1/9`.
- Direct card-use evidence in the candidate: `Mana Vault` cost-paid/cast
  `20`, `Birgi` trigger-resolved `87`, `The One Ring` utility activations
  `18`.
- Initial decision before cut-method reaudit:
  `promote_challenger`; `ready_for_real_deck_change=true`.
- Corrected decision after
  `lorehold_cut_methodology_reaudit_20260629`: the package is
  `battle_cleared_with_cut_methodology_caveat`, not ready for final real deck
  change. `Mana Vault` over `Bender's Waterskin` is valid same-lane ramp;
  `Birgi` over `The Scarlet Witch` is same-macro but needs confirmation; `The
  One Ring` over `Molecule Man` is cross-lane and must be recut before any
  ideal-deck claim.

Method-repair decision generated on 2026-06-30:

- Candidate: `candidate_607_v615_mana_vault_method_repair_v1`, built from
  protected `607`.
- Adds from `615`: `Mana Vault`.
- Cuts from `607`: `Bender's Waterskin`.
- Protected cards intentionally preserved: `Molecule Man`, `The Scarlet
  Witch`, and `Victory Chimes`.
- Structural matrix result: candidate rank `1`, `607` rank `2`, effectively
  tied at score `141.0`, intent `100.0`, lands `34`, rule-ready `97.9%`.
- Natural equal battle gate: `607` = `30/72`; repaired candidate = `24/72`.
- Seed windows: seed `20260630` = `607 11/24` versus candidate `7/24`; seed
  `123` = `607 8/24` versus candidate `7/24`; seed `999` = `607 11/24`
  versus candidate `10/24`.
- Direct card-use evidence: candidate `Mana Vault` cost-paid `36` and
  spell-cast `18`, so the rejection is not caused by invisible-card sampling.
- Decision: reject this exact one-card swap. `Bender's Waterskin` remains a
  protected miracle-timing/ramp lane card until a same-lane replacement beats
  `607` in an equal gate.
- Evidence report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_vault_method_repair_decision_20260630.md`.

The One Ring cut decision generated on 2026-06-30:

- Scope: retest `The One Ring` only against draw/protection/value slots, not
  against `Molecule Man`.
- Protected cards intentionally preserved in all candidates:
  `Bender's Waterskin`, `Victory Chimes`, `Molecule Man`, `The Scarlet Witch`,
  and `The Mind Stone`.
- Smoke candidates:
  `candidate_607_one_ring_creative_technique_v1`,
  `candidate_607_one_ring_improvisation_capstone_v1`, and
  `candidate_607_one_ring_redirect_lightning_v1`.
- Smoke result: the `Creative Technique` cut was closest at `10/24` versus
  `607` at `11/24`; the `Improvisation Capstone` and `Redirect Lightning` cuts
  both fell to `6/24` versus `607` at `11/24`.
- Confirmed `Creative Technique` cut over seeds `20260630`, `123`, and `999`:
  `607` = `30/72`; candidate = `25/72`.
- Direct card-use evidence: candidate `The One Ring` accessed `24` games,
  cost-paid `42`, spell-cast `21`, resolved `17`, and utility-activated `26`,
  so the rejection is not caused by invisible-card sampling.
- Decision: reject `The One Ring` for the current `607` shell. It is a real
  value engine, but the current Lorehold spell/value and miracle cadence still
  converts better.
- Evidence report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_one_ring_cut_decision_20260630.md`.

Tutor/selection decision generated on 2026-06-30:

- Scope: test true tutor/selection improvements after rejecting generic ramp
  and value swaps.
- Protected cards intentionally preserved:
  `Bender's Waterskin`, `Victory Chimes`, `Molecule Man`, `The Scarlet Witch`,
  `The Mind Stone`, and the core pressure/protection package.
- Candidates:
  `candidate_607_enlightened_tutor_insurrection_v1`,
  `candidate_607_enlightened_tutor_creative_technique_v1`, and
  `candidate_607_gamble_storm_herd_v1`.
- Local source support: `Enlightened Tutor` appears in variants `608`, `611`,
  `612`, `613`, `614`, and `615`; `Gamble` appears in `609`, `612`, `613`,
  `614`, and `615`.
- Runtime support: `Enlightened Tutor` has active PG063
  `artifact_enchantment_tutor_to_library_top_v1`; `Gamble` has verified PG070
  `any_card_to_hand_then_random_discard_v1`.
- Structural result: all three candidates kept intent `100.0` and scored above
  `607`, but structure alone was not promotion evidence.
- Battle result: `Enlightened Tutor` over `Creative Technique` lost smoke
  `7/24` versus `607` `11/24`; `Enlightened Tutor` over `Insurrection` lost
  confirmed aggregate `25/72` versus `607` `30/72`; `Gamble` over `Storm Herd`
  lost smoke `9/24` versus `607` `11/24`.
- Direct card-use evidence: `Enlightened Tutor` over `Insurrection` accessed
  tutor `15` games, spell-cast `18`, resolved `19`; `Gamble` accessed `7`
  games, spell-cast `7`, resolved `7`.
- Decision: reject the tested tutor/selection swaps. The tested tutors are
  coherent cards, but the current 607 high-impact finisher/value package still
  converts better.
- Evidence report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_selection_decision_20260630.md`.

## General Deckbuilding Gate

Every generated or optimized Commander deck must pass:

1. exact commander and deck-size validation;
2. singleton and Commander legality validation;
3. color identity validation, including split/MDFC/back-face/adventure cards;
4. unresolved-card count equals zero;
5. role/package target check;
6. source provenance check;
7. no raw multi-row rule/tag fanout in deck joins;
8. artifact-contract check for every matrix, gate, exposure, replay, and
   historical Lorehold report consumed by the decision;
9. battle gate for any structural promotion;
10. drawn/cast/used or focused-test evidence for any card-specific conclusion.

## Lorehold Promotion Gate

A Lorehold candidate can replace `607` only when all are true:

- it passes the structural strategy matrix;
- it keeps land/ramp/draw/removal/protection/wincon counts inside the frozen
  profile ranges unless a documented battle result justifies the deviation;
- it does not cut protected anchors without same-lane replacement proof;
- it does not use a cross-lane cut as deck-quality proof. Example: a
  draw/protection value card such as `The One Ring` can be useful, but it must
  not be treated as proof that a miracle-engine card such as `Molecule Man`
  belongs out unless an explicit package hypothesis and equal-gate card-use
  evidence prove that functional tradeoff;
- it ties or beats `607` in the same opponent set and seed window;
- it does not regress the fast pressure matchup, especially Winota-style
  combat pressure;
- decision traces show Lorehold actually uses topdeck/miracle setup and
  discounted spell-chain conversion before the game is decided.

## Current Validation Commands

Read-only provenance audit:

```bash
cd server && dart run bin/commander_generate_provenance_audit.dart \
  --commander="Lorehold, the Historian" \
  --artifact-dir=test/artifacts/commander_generate_provenance_20260629_deckbuilding_contract
```

Lorehold variant strategy matrix:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_variant_strategy_matrix.py \
  --deck-ids 607,608,609,610,611,612,613,614,615,616 \
  --out-prefix docs/hermes-analysis/master_optimizer_reports/lorehold_variant_strategy_matrix_20260629_deckbuilding_contract
```

Lorehold artifact contract audit:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_artifact_contract_audit.py \
  --out-prefix docs/hermes-analysis/master_optimizer_reports/lorehold_artifact_contract_audit_20260629_current
```

Lorehold promotion-gate decision audit:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_promotion_gate_decision_audit.py \
  --out-prefix docs/hermes-analysis/master_optimizer_reports/lorehold_promotion_gate_decision_audit_20260629_real8_games3_seed42_7_20260625
```

Focused backend tests:

```bash
cd server && dart test \
  test/commander_reference_readiness_support_test.dart \
  test/optimize_swap_candidate_support_test.dart \
  test/generated_deck_validation_service_test.dart
```

External source availability check used for this contract:

```bash
curl -L -s -o /tmp/manaloom_ext_check.html -w "%{http_code}" \
  https://magic.wizards.com/en/formats/commander
curl -L -s -o /tmp/manaloom_ext_check.html -w "%{http_code}" \
  https://edhrec.com/commanders/lorehold-the-historian
curl -L -s -o /tmp/manaloom_ext_check.html -w "%{http_code}" \
  https://edhrec.com/guides/edhrec-guide-to-spellslinger-in-commander
curl -L -s -o /tmp/manaloom_ext_check.html -w "%{http_code}" \
  https://edhrec.com/articles/how-to-build-a-commander-deck
curl -L -s -o /tmp/manaloom_ext_check.html -w "%{http_code}" \
  https://archidekt.com/commanders/Lorehold%2C%20the%20Historian
curl -L -s -o /tmp/manaloom_ext_check.html -w "%{http_code}" \
  https://commanderspellbook.com/
```

All returned HTTP `200` on 2026-06-29.

## Stop Rules

Stop and fix the deckbuilder contract before promoting a deck if any of these
happen:

- a deck is called better only because it has strong individual cards;
- a battle aggregate is treated as card-level proof without drawn/cast/used
  evidence;
- a candidate replaces a protected baseline without equal opponent and seed
  comparison;
- external popularity is treated as legality or battle-rule proof;
- XMage rule availability is treated as proof that the card belongs in the
  deck;
- a generic Commander ratio overrides a commander-specific intent profile;
- unresolved/off-color cards are repaired silently without diagnostics;
- raw multi-row intelligence tables are joined into deck rows without
  aggregation.
- a historical Lorehold artifact is consumed as if it had the current schema
  without first passing `lorehold_artifact_contract_audit.py`.

## Next Product Step

For Lorehold, do not promote `614`, `615`, `candidate_607_v615_mana_engine_v1`,
`candidate_607_v615_mana_vault_method_repair_v1`, any 2026-06-30
`The One Ring` candidate, any 2026-06-30 tested tutor/selection candidate, or
any 2026-06-30 tested `Tibalt's Trickery` replacement as the final ideal deck
from the current evidence. Also do not promote
`candidate_607_deflecting_palm_redirect_lightning_v1`; it tied total wins in
the smoke gate but regressed Winota and miracle/discard-to-top cadence. The
tested `candidate_607_chaos_warp_stroke_of_midnight_v1` is also rejected from
the current evidence after losing the confirmed 72-game gate. Also do not
promote `candidate_607_return_the_favor_redirect_lightning_v1`; it ranked below
`607` structurally and lost the smoke gate. Also do not promote
`candidate_607_past_in_flames_pinnacle_monk_v1`; it generated real spell-chain
telemetry but lost the smoke gate and collapsed Winota. The tested cards were
exercised in battle but did not pass the promotion contract, so the protected
baseline remains `607`.

Tibalt replacement decision generated on 2026-06-30:

- Candidates:
  `candidate_607_boros_charm_tibalts_trickery_v1`,
  `candidate_607_silence_tibalts_trickery_v1`, and
  `candidate_607_grand_abolisher_tibalts_trickery_v1`.
- Structural result: all three tied `607` at score `141.036`, intent `100.0`,
  lands `34`, and rule-ready `97.87%`.
- Smoke result at `opponent_seed=20260630`: `Boros Charm` beat the local smoke
  baseline `8/24` versus `607` `6/24` with real card use; `Silence` beat the
  smoke baseline `10/24` versus `607` `6/24` but had only one cast; `Grand
  Abolisher` lost immediately `4/24` versus `607` `6/24`.
- Confirmed result at `opponent_seed=20260629`, seeds `20260630`, `123`, and
  `999`: `Boros Charm` lost `21/72` versus `607` `30/72`; `Silence` lost
  `27/72` versus `607` `30/72`.
- Direct card-use evidence: `Boros Charm` resolved `8` times in confirmation;
  `Silence` was accessed in `22/72` games, drawn in `12/72`, cast `15` times,
  and resolved `13` times.
- Decision: keep `Tibalt's Trickery` protected until a different
  same-function replacement beats `607`. The low recent event count is not
  enough to cut it when exercised same-lane replacements lose confirmed gates.
- Evidence report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_tibalt_replacement_decision_20260630.md`.

Deflecting Palm pressure-probe decision generated on 2026-06-30:

- Candidate:
  `candidate_607_deflecting_palm_redirect_lightning_v1`.
- Structural result: rank `1`, score `141.058`, intent `100.0`, lands `34`,
  rule-ready `97.9%`.
- Smoke result at `opponent_seed=20260629`, `simulation_seed=20260630`:
  candidate `11/24` versus `607` `11/24`.
- Direct card-use evidence: `Deflecting Palm` had card events in `8/24`
  games, spell-cast `6`, miracle-cast `1`, and resolved `8`.
- Promotion failure: Winota regressed to `1/3` versus `607` `2/3`; miracle
  casts fell from `48` to `37`; discard-to-top replacements fell from `14` to
  `6`.
- Decision: reject this exact `+Deflecting Palm; -Redirect Lightning` swap.
  The card is battle-ready, but this replacement does not improve the current
  `607` shell.
- Evidence report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_deflecting_palm_redirect_lightning_decision_20260630.md`.

Chaos Warp removal-probe decision generated on 2026-06-30:

- Candidate:
  `candidate_607_chaos_warp_stroke_of_midnight_v1`.
- Structural result: rank `1`, score `141.058`, intent `100.0`, lands `34`,
  rule-ready `97.9%`.
- Smoke result at `opponent_seed=20260629`, `simulation_seed=20260630`:
  candidate `12/24` versus `607` `11/24`, with equal Winota `2/3` and improved
  miracle/topdeck telemetry.
- Confirmed result over seeds `20260630`, `123`, and `999`: candidate `25/72`
  versus `607` `30/72`.
- Direct card-use evidence: `Chaos Warp` had card events in `17/72` games,
  spell-cast `10`, miracle-cast `5`, and resolved/removal-resolved `15`.
- Promotion failure: Winota regressed to `2/9` versus `607` `3/9`; Lorehold
  spell casts fell from `729` to `598`; topdeck activations fell from `132` to
  `117`; static cost-reduction total fell from `221` to `144`.
- Decision: reject this exact `+Chaos Warp; -Stroke of Midnight` swap. The
  card is battle-ready, but `Stroke of Midnight` remains better in the current
  `607` removal slot.
- Evidence report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_chaos_warp_stroke_decision_20260630.md`.

Return the Favor redirect/copy probe decision generated on 2026-06-30:

- Candidate:
  `candidate_607_return_the_favor_redirect_lightning_v1`.
- Structural result: rank `2`, score `140.9`, intent `100.0`, lands `34`,
  rule-ready `97.9%`; `607` remained structurally ahead at score `141.0`.
- Smoke result at `opponent_seed=20260629`, `simulation_seed=20260630`:
  candidate `8/24` versus `607` `11/24`.
- Direct card-use evidence: `Return the Favor` was spell-cast/resolved `2`
  times; `Redirect Lightning` in the baseline was spell-cast `1` time.
- Promotion failure: Winota regressed to `1/3` versus `607` `2/3`; total wins
  fell by three games.
- Decision: reject this exact `+Return the Favor; -Redirect Lightning` swap at
  smoke. The card is a coherent copy/redirect hypothesis, but this replacement
  does not improve the current `607` shell.
- Evidence report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_return_the_favor_redirect_decision_20260630.md`.

Past in Flames recursion-probe decision generated on 2026-06-30:

- Candidate:
  `candidate_607_past_in_flames_pinnacle_monk_v1`.
- Structural result: rank `2`, score `141.0`, intent `100.0`, lands `34`,
  rule-ready `97.9%`; `607` remained structurally ahead.
- Smoke result at `opponent_seed=20260629`, `simulation_seed=20260630`:
  candidate `8/24` versus `607` `11/24`.
- Direct card-use evidence: `Past in Flames` had card events in `6/24` games,
  spell-cast `4`, miracle-cast `2`, and resolved `6`.
- Promotion failure: Winota regressed to `0/3` versus `607` `2/3`; battle
  report removal count fell from `16` to `15`.
- Decision: reject this exact `+Past in Flames; -Pinnacle Monk // Mystic Peak`
  swap at smoke. The card is battle-ready and increased spell-chain telemetry,
  but this replacement does not improve the current `607` shell.
- Evidence report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_past_in_flames_pinnacle_decision_20260630.md`.

The next real product step is to stop cutting already-used finishers or value
spells for generic access cards. Keep the `607` miracle/topdeck/ramp shell
intact and look only for:

- pressure-matchup improvements that do not reduce miracle/topdeck frequency;
  or
- tutor/selection packages that add access while removing a demonstrably low-use
  nonpressure slot.

Keep `Bender's Waterskin`, `Victory Chimes`, `Molecule Man`, `The Scarlet
Witch`, `The Mind Stone`, `Insurrection`, `Storm Herd`, and `Creative
Technique` protected until a direct same-lane challenger beats `607`.

For other commanders, first create the same commander intent profile and source
provenance layer, then use the same gate.
