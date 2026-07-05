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
10. classify staple impact before deciding cuts: a staple is a floor,
    consistency, or role-density signal, not automatic deck truth;
11. cut by lane: each added card must compete with the same functional slot or
    carry an explicit package hypothesis and equal-gate evidence;
12. validate by legal service, strategy matrix, goldfish/curve checks, battle
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
10. `staple_impact_and_role_policy`
11. `lane_balanced_cuts_and_anchor_protection`
12. `goldfish_battle_replay_iteration`

Current source learning:

| Source | URL | Learning imported into ManaLoom | Guardrail |
| --- | --- | --- | --- |
| Wizards Commander format page | https://magic.wizards.com/en/formats/commander | official 99+1 shape, singleton, color identity, multiplayer/power bracket framing | legality and bracket only, not strategy quality |
| EDHREC Commander deckbuilding guide | https://edhrec.com/articles/how-to-build-a-commander-deck | deckbuilding starts from categories and then checks whether the list plays the intended way | category counts are starting points, not final proof |
| The Command Zone template discussion via EDHREC | https://edhrec.com/articles/the-command-zone-commander-deckbuilding-template-for-the-new-era-the-command-zone-658-mtg-edh-magic-gathering | Commander decks need balanced ratios of ramp, draw, disruption, and related roles | template ratios must bend to commander intent and table speed |
| EDHREC ramp guide | https://edhrec.com/guides/the-edhrec-guide-to-ramp-in-commander | ramp is about playing ahead of curve; commander mana value and ramp timing matter | "more mana" is not enough if ramp competes with the commander turn |
| EDHREC Top/Staples pages | https://edhrec.com/top | global popularity identifies common format staples and structural floor cards | global staple rank does not override commander-specific inclusion, role fit, or battle proof |
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
19. `staple_floor_and_context`
20. `same_lane_cuts`
21. `battle_and_replay_validation`

The deck overview is not allowed to be a loose card list. It must include:

- one sentence for the commander's intended game plan;
- target power bracket or documented unknown bracket;
- primary and backup win lines;
- role counts versus commander-specific targets;
- mana curve and color-source/ramp summary;
- package lanes with key cards, enablers, payoffs, and protected anchors;
- source provenance for important cards;
- staple impact by role, including which staples are structural floor versus
  contextual commander package cards;
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
9. `staple_impact_by_role`
10. `protected_anchors_and_cut_rules`
11. `known_risks_and_validation_status`

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

## Global Commander Core Pivot - 2026-07-05

The active product focus is now global Commander deckbuilding quality, not
proving one more marginal swap in protected Lorehold deck `607`. Deck `607`
remains valuable as a benchmark/regression deck because it is a complex,
well-instrumented shell with many failed cut experiments. It must not become the
objective function for every commander.

Operational priority after this pivot:

1. run global Commander contract and strategy-matrix audits first;
2. classify each deck by product truth, registered variant, Hermes lab, or
   fixture before using it in any promotion decision;
3. require commander-specific profile/source lanes before strategy matrices;
4. run `global_commander_core_role_audit.py` for role/core diagnostics over
   mana, curve, ramp, draw, removal, wipes, protection, recursion, win plans,
   staples, and same-lane cuts across all commanders before commander-specific
   matrices or battle gates;
5. run `global_commander_core_repair_hypothesis.py` to convert critical core
   gaps into read-only repair hypotheses, candidate-source lanes, cut pressure,
   and required gates before any materialized deck or card swap;
6. run `global_commander_mana_base_profile.py` for land gaps before naming land
   additions; it must measure commander color identity, direct/fetchable access,
   tapped-land pressure, colorless-only pressure, and utility-land risk;
7. run `global_commander_named_land_candidate_pool.py` only after the mana
   profile is ready; named lands are review-only candidate-pool rows and still
   require same-lane cuts, structure/legal recheck, strategy matrix, battle gate,
   and replay trace before promotion;
8. run `global_commander_land_cut_candidate_model.py` to convert named land
   candidates and excess-role pressure into review-only add/cut hypotheses while
   blocking cards that carry missing core roles or protected package signals;
9. run `global_commander_nonland_core_candidate_model.py` for nonland core gaps
   after repair hypotheses; it can expand trusted local staple pools for roles
   such as removal, but win plans remain commander-specific source-lane work
   before named cards;
10. run `global_commander_learning_priority_audit.py` to combine core gaps,
   source-lane availability, current external research, staple/bracket
   guardrails, and the Lorehold benchmark rule into one global next-action
   queue;
11. keep Lorehold-specific micro-optimizations, including DRC/Brain/Mana Vault
   probes, as regression evidence only unless they produce a named safe cut and
   equal-gate proof under the Lorehold promotion gate.

Current pivot evidence:

- `docs/hermes-analysis/master_optimizer_reports/deckbuilding_contract_surface_audit_20260705_global_core_pivot.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_deck_contract_audit_20260705_global_core_pivot_hermes_only.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_strategy_matrix_20260705_global_core_pivot_hermes_only.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_core_role_audit_20260705_global_goal_hermes_only.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_core_repair_hypothesis_20260705_global_goal_hermes_only.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_mana_base_profile_20260705_global_goal_hermes_only.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_named_land_candidate_pool_20260705_global_goal_hermes_only.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_land_cut_candidate_model_20260705_global_goal_hermes_only.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_nonland_core_candidate_model_20260705_global_goal_hermes_only.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_learning_priority_audit_20260705_global_goal_hermes_only.md`

The Hermes-only matrix is allowed as a local degraded diagnostic when PostgreSQL
credentials are unavailable. It must report source lanes as unavailable and route
ready lab decks to `structure_ready_source_missing`; it must not silently treat
missing PostgreSQL source evidence as complete product readiness.

Current external refresh on 2026-07-05:

- The official Wizards Commander format page now exposes five Commander
  Brackets and Game Changers as power-intent signals. ManaLoom must treat them
  as bracket/pregame-context evidence, not as proof a deck is strategically
  correct.
- `server/lib/edh_bracket_policy.dart` now accepts brackets `1..5` and applies
  the current Game Changer budgets: zero in brackets 1/2, up to three in
  bracket 3, and unlimited in brackets 4/5. Bracket checks remain a
  warning/gate signal and must not be used as final deck-quality proof.
- The external deckbuilding template evidence remains directional: core ranges
  for lands, ramp, draw, interaction, and wipes identify floor gaps, while the
  commander profile decides which ranges bend up or down.
- Current core repair hypothesis output is read-only. Land gaps require a mana
  base profile before named cards, wincon gaps require commander win-plan/source
  proof before named cards, and format staples are review candidates only.
- Current mana-base profile output is read-only. It can unlock a named land
  candidate pool only after color identity, color access, tapped-land pressure,
  colorless utility, and same-lane cut pressure are visible.
- Current named land candidate pool output is read-only. It filters local Oracle
  land rows by commander color identity and Commander legality, excludes current
  deck cards, and ranks candidates for same-lane cut review only.
- Current land cut candidate output is read-only. It uses excess role pressure
  to name nonland cut candidates, blocks cards carrying missing core roles, and
  flags multi-copy/package and topdeck-engine signals as requiring commander
  source-lane review before any candidate copy.
- Current nonland core candidate output is read-only. It expands compatible
  `format_staples` pools for supported roles, filters by commander color
  identity, Commander legality, current deck membership, nonland type, and
  role-confirming Oracle text, then emits add/cut hypotheses only. Wincon gaps
  stay blocked on commander-specific win-plan/source evidence.
- Current runtime profile fallback now includes `Kaalia of the Vast` in
  `server/lib/ai/commander_reference_profile_support.dart`. This is a local
  aggregate source lane for generation prompts only: it requires Mardu color
  identity, haste/protection, real interaction, Angel/Demon/Dragon payoff
  density, and an explicit plan-B lane; it must not copy public decklists or
  promote the current Kaalia variant without the normal structure, strategy,
  battle, and replay gates.

## Global Commander Rollout - 2026-07-01

The Lorehold work is now the pilot methodology, not a special-case deckbuilder
path. Before applying the Commander contract to all decks, run:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/global_commander_deck_contract_audit.py \
  --out-prefix docs/hermes-analysis/master_optimizer_reports/global_commander_deck_contract_audit_20260701_post_scope_legalities
python3 docs/hermes-analysis/manaloom-knowledge/scripts/global_commander_strategy_matrix.py \
  --out-prefix docs/hermes-analysis/master_optimizer_reports/global_commander_strategy_matrix_20260701_current
```

Current global audit evidence:

- `docs/hermes-analysis/master_optimizer_reports/global_commander_deck_contract_audit_20260701_post_scope_legalities.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_strategy_matrix_20260701_current.md`
- PostgreSQL registered variants: `13/13` are `structure_ready`.
- Hermes local lab decks: Lorehold baseline `6`, Lorehold variants `606-616`,
  and non-Lorehold variants `617-621` are structurally ready.
- Product/user Commander scope after fixture/probe refinement: `16` likely user
  decks; `6` are `structure_ready`, `10` need repair or exclusion before
  entering global promotion gates.
- The remaining product repair queue is shape/legality, not unknown legality:
  `9` decks are incomplete or missing commander data, and `goblins` is blocked
  by `Auntie Flint` as `not_legal` in Commander.
- Test/fixture decks are explicitly excluded from product promotion decisions.
- Deck `607` materialized for `rafaelhalder@gmail.com` is structurally ready
  after legalities sync: `100` cards, `1` commander, `0` missing legalities,
  and `0` illegal rows.
- Legalities syncs applied on 2026-07-01:
  `msh` upserted `2921` `card_legalities` rows; `tdc,tle,blc,drc` upserted
  `207` rows; `eoc,sld,soc,unk` upserted `12604` rows. These syncs updated
  legalities only, not cards or deck contents.
- Global Commander strategy matrix status: `10` commanders considered, `36`
  ready deck candidates, `19` product-ready decks, `8` blocked product decks;
  `Lorehold`, `Kaalia`, `Kefka`, and `Y'shtola` are ready for commander-specific
  strategy matrix, while `Sauron`, `Valgavoth`, `Animar`, and `Jin-Gitaxias //
  The Great Synthesis` need a reference/profile/learned source lane before
  strategy-matrix promotion.

Global promotion rules:

- A deck cannot enter global deck-quality comparison until it is in an intended
  scope (`user_product`, `registered_pg_variant`, or an explicitly selected
  Hermes lab deck) and passes structure/legality gates.
- Partner/background or multi-commander decks are blocked from automatic
  promotion until the project has an explicit partner/background profile
  contract.
- Cards with printed deck-construction exceptions, such as `Nazgûl`, must be
  handled by rule-aware duplicate validation rather than generic singleton
  counting.
- The global audit is a readiness and prioritization gate. It does not replace
  commander intent profiles, source corpus, strategy matrix, or battle gate
  evidence.
- The global strategy matrix is a routing gate. It can say which commander
  should receive a commander-specific strategy matrix next, but it cannot
  promote a deck without equal battle gate evidence.

## Source Hierarchy

| Source lane | Use for | Must not be used for |
| --- | --- | --- |
| Official Commander rules | 100-card shape, commander requirement, singleton, color identity, ban/legal framing | Card popularity or strategic package proof |
| Scryfall and MTGJSON | Identity, Oracle text, layout, legality, rulings, hashes, resolver inputs | Commander-specific strategic quality by itself |
| EDHREC | Commander-specific popular cards, themes, role expectations, aggregate strategy signals | Exact deck copying or executable battle-rule truth |
| EDHREC Top/Staples and `format_staples` | Global format staples, legal/color-filtered staple pool, role-floor candidates, banlist-backed fallback | Commander-specific fit, cross-lane cut proof, or reason to replace a protected engine |
| Moxfield, Archidekt, public decklists | Reference corpus, recurring package choices, sample shells, bracket/style clues | Automatic promotion without legality/source validation |
| Commander Spellbook | Combo package discovery and deterministic synergy candidates | General deck balance or rule execution by itself |
| Local learned decks | Product-specific successful candidates and prior promoted shells | Replacing source provenance or current legality checks |
| ManaLoom battles/replays | Outcome proof, pressure matchup proof, drawn/cast/used evidence for chosen cards | Card-level rule proof unless the card was exercised |
| XMage | Runtime/rule behavior reference for cards used by decks | Deck popularity, intent, or metagame quality |

## Staple Impact Policy

`server/lib/ai/commander_staple_impact_policy.dart` defines the executable
policy version `commander_staple_impact_policy_v1_2026-06-30`.

Staples are useful because they raise the deck's floor: they improve opening
hand quality, fixing, card flow, interaction density, recovery, and resilience.
That makes them high-impact when the deck is missing that role. It does not
mean every popular card belongs in every deck, and it does not mean a global
staple can cut a commander-specific engine.

ManaLoom must classify staples in this order:

1. `structural_foundation`: high commander inclusion in ramp, fixing, draw,
   removal, board wipe, protection, tutor, or land roles. These are protected
   floor cards unless a same-role replacement or battle-proven package beats
   them. Example: `Arcane Signet` in Lorehold is early-mana/fixing floor.
2. `commander_contextual_staple`: high commander-specific adoption or synergy
   with the plan. These are preferred package cards, but they still need
   lane density and pressure validation. Example: `Storm-Kiln Artist` is a
   spell-chain card for Lorehold, not a two-mana-rock replacement.
3. `commander_synergy_candidate`: strong synergy with lower adoption or narrow
   role fit. These become hypotheses, not automatic inclusions.
4. `generic_or_low_context_signal`: global staples or low commander inclusion
   cards. These may fill a missing role, but cannot override commander intent
   or protected anchors. Example: `The One Ring` is globally powerful but low
   adoption in the current Lorehold page, so it needs same-lane value/draw proof.

Required scoring rule:

- use `inclusionRate = num_decks / potential_decks`, not raw EDHREC
  `inclusion` count, when measuring commander adoption;
- combine commander-specific synergy and inclusion rate, with structural role
  categories getting extra protection;
- use `format_staples` as a candidate source and banlist/color/legal filter,
  not as commander-specific proof;
- never cut a structural staple across lanes just because the added card is
  also famous or high-rank.

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
- a positive aggregate result is still rejected when a critical matchup record
  regresses versus `607`; seed-matrix reports must surface those matchup
  records before a package can be promoted;
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
- a global staple rank or fixed staple list overrides commander-specific
  inclusion rate, role fit, or package-lane evidence;
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
exercised in battle but did not pass the promotion contract. Also do not
promote `electro_assaulting_battery_same_lane_benchmark_cut_bender_s_waterskin`;
the corrected 607-baseline package gate exercised `Electro` but lost the smoke
gate and collapsed Winota. Also do not promote
`cloud_key_same_lane_benchmark_cut_bender_s_waterskin`; `Cloud Key` was
exercised in the natural gate but lost to protected `607` and regressed Winota
and miracle cadence. Also do not promote
`cool_but_rude_same_lane_benchmark_cut_monument_to_endurance` or
`currency_converter_same_lane_benchmark_cut_monument_to_endurance`; both were
same-lane discard-ramp-value tests over `Monument to Endurance`, and neither
passed the protected fast-pressure gate. Also do not promote
`glint_horn_buccaneer_same_lane_benchmark_cut_monument_to_endurance`,
`magmakin_artillerist_same_lane_benchmark_cut_monument_to_endurance`, or
`surly_badgersaur_same_lane_benchmark_cut_monument_to_endurance`; the remaining
same-lane discard-ramp-value candidates also lost the protected gate and
regressed Winota. Also do not promote
`possibility_storm_same_lane_benchmark_cut_creative_technique`; it was the
remaining all-lanes package after prior filtering, but it lost the smoke gate
and regressed Winota while collecting too little used-game outcome sample for a
positive card-level claim. The current profiled same-lane one-for-one queue is
closed: the latest all-lanes pass evaluated `1080` candidate/cut pairs, found
`0` preflight-ready packages, and blocked `31` exact prior rejects. The
protected baseline remains `607`.

Package-gate correction generated on 2026-06-30:

- The package gate and profiled-cut generator were corrected to use protected
  deck `607` as the default current shell instead of historical deck `6`.
- `lorehold_variant_battle_gate.py` now accepts `--candidate-deck-id`; package
  gates pass `607` so the candidate battle loads the modified `607` deck from
  the copied candidate DB.
- Any `lorehold_electro_waterskin_gate_20260630_20260630_042012` artifact is
  invalid for deck promotion because it loaded the candidate from deck `6`.
  Use the fixed gate only:
  `lorehold_electro_waterskin_gate_20260630_fixed_20260630_042339`.

Cut-model baseline correction generated on 2026-06-30:

- `lorehold_access_cut_model.py`, `lorehold_hand_filter_cut_model.py`,
  `lorehold_tutor_cut_model.py`, `lorehold_recursion_cut_model.py`,
  `lorehold_safe_cut_replanner.py`, and `lorehold_manual_cut_review.py` now
  default to protected baseline deck `607`, not historical deck `6`.
- The current corrected access model is
  `docs/hermes-analysis/master_optimizer_reports/lorehold_access_cut_model_20260630_post_pg276_lane_core_blocked.md`.
  It evaluated deck `607` directly (`94` deck rows), found `0` preflight-ready
  access swaps, and still requires a safe cut before any battle gate. It also
  corrects misleading local draw tags by Oracle text, so `Redirect Lightning`
  is treated as interaction/protection rather than a draw/topdeck cut; it also
  blocks `Improvisation Capstone` as a spell-chain/free-cast/paradigm core
  slot instead of allowing `Brainstone` to test over it as generic draw. The
  earlier PG272 Brainstone correction removed the invalid `Penance` over
  `Brainstone` path because `Brainstone` exists in deck `6`, not in protected
  deck `607`; PG275/PG276 did not change the safe-cut result.
- The corrected hand-filter, tutor, and recursion models also produced `0`
  gate-ready direct swaps from deck `607`:
  `lorehold_hand_filter_cut_model_20260630_after_pg269_alhammarret.md`,
  `lorehold_tutor_cut_model_20260630_after_pg269_alhammarret.md`, and
  `lorehold_recursion_cut_model_20260630_after_pg269_alhammarret.md`.
- `operational_surface_alignment_audit.py` now checks these active cut models
  for `DEFAULT_BASELINE_DECK_ID = 607` before the project can claim script/doc
  alignment.

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

Chaos Warp/Generous Gift profiled-removal decision generated on 2026-06-30:

- Candidate:
  `chaos_warp_same_lane_benchmark_cut_generous_gift`.
- Why it was tested: the current exposure/manual-cut pass found no automatic
  safe cut, but did find a same-lane spot-removal benchmark where `Chaos Warp`
  has active battle-rule support and appears in Lorehold variants while
  `Generous Gift` had measured low exposure in deck `607`.
- Smoke result at `opponent_seed=20260629`, `simulation_seed=20260630`:
  candidate `14/24` versus `607` `11/24`.
- Direct card-use evidence in the smoke gate: candidate `Chaos Warp` recorded
  `31` use events, was accessed in `10/24` games, used in `9/24` games, and
  its used-game record was `8W/1L/0S`. Baseline `Generous Gift` recorded `9`
  use events and was accessed in `4/24` games.
- Confirmed result over seeds `20260630`, `123`, and `999`: candidate
  `30/72` versus `607` `27/72`, but seed `999` regressed `10/24` versus
  `607` `11/24`.
- Critical matchup failure: Winota fell from `4/9` on baseline `607` to `3/9`
  on the candidate.
- Decision: reject this exact `+Chaos Warp; -Generous Gift` swap despite the
  positive aggregate. The swap is real and exercised, but it violates the
  protected fast-pressure gate.
- Evidence reports:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_chaos_warp_generous_gift_gate_20260630_goal_learning_smoke_20260630_205058.md`,
  `docs/hermes-analysis/master_optimizer_reports/lorehold_chaos_warp_generous_gift_seed_matrix_20260630_goal_learning_confirm_20260630_205527.md`,
  and
  `docs/hermes-analysis/master_optimizer_reports/lorehold_chaos_warp_generous_gift_decision_20260630_goal_learning.md`.

Discard-ramp-value / Monument decision generated on 2026-06-30:

- Candidates:
  `cool_but_rude_same_lane_benchmark_cut_monument_to_endurance`,
  `currency_converter_same_lane_benchmark_cut_monument_to_endurance`,
  `glint_horn_buccaneer_same_lane_benchmark_cut_monument_to_endurance`,
  `magmakin_artillerist_same_lane_benchmark_cut_monument_to_endurance`, and
  `surly_badgersaur_same_lane_benchmark_cut_monument_to_endurance`.
- Why they were tested: `Monument to Endurance` is not generic ramp in the
  current shell; it is a discard-trigger value/ramp payoff tied to hand
  filtering, treasure, and opponent life-loss pressure. The profiled-cut
  generator was expanded with `discard_ramp_value` and `--cut-card` so this
  lane can be benchmarked directly from the full manual-review expansion.
- Smoke result for `Cool but Rude`: candidate `9W/15L/0S` versus `607`
  `11W/12L/1S`; Winota regressed from `2W/1L/0S` to `0W/3L/0S`. The card was
  used `20` times and accessed in `4` games, so the rejection is not a
  no-exposure artifact.
- Smoke result for `Currency Converter`: candidate tied total wins at
  `11W/13L/0S` versus `607` `11W/12L/1S`, but Winota regressed from
  `2W/1L/0S` to `1W/2L/0S`. The card was used `41` times and accessed in
  `8` games.
- Residual same-lane smoke results after prior-reject filtering:
  `Glint-Horn Buccaneer` lost `10W/14L/0S` and Winota `0W/3L/0S`;
  `Magmakin Artillerist` lost `7W/17L/0S` and Winota `1W/2L/0S`; and
  `Surly Badgersaur` lost `10W/14L/0S` and Winota `0W/3L/0S`.
- Direct card-use evidence exists for the residual candidates:
  `Glint-Horn Buccaneer` use `13` / access `7`, `Magmakin Artillerist` use
  `16` / access `11`, and `Surly Badgersaur` use `6` / access `7`.
- Tooling decision: package gates now return
  `reject_regresses_critical_matchup` when a critical matchup record drops,
  even if aggregate win rate ties or improves.
- Decision: keep `Monument to Endurance` protected in deck `607`. The current
  discard-ramp-value one-for-one replacement pool over `Monument to Endurance`
  is exhausted and rejected; revisit these cards only with a safer cut or a
  package-level hypothesis that preserves the fast-pressure matchup.
- Evidence reports:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_benchmark_generator_20260630_goal_learning_discard_ramp_value_monument.md`,
  `docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_benchmark_generator_20260630_goal_learning_discard_ramp_value_monument_remaining.md`,
  `docs/hermes-analysis/master_optimizer_reports/lorehold_discard_ramp_value_monument_gate_20260630_goal_learning_smoke_20260630_210849.md`,
  `docs/hermes-analysis/master_optimizer_reports/lorehold_currency_converter_monument_gate_20260630_goal_learning_critical_guard_20260630_212135.md`,
  `docs/hermes-analysis/master_optimizer_reports/lorehold_discard_ramp_value_monument_remaining_gate_20260630_goal_learning_smoke_20260630_213021.md`,
  and
  `docs/hermes-analysis/master_optimizer_reports/lorehold_discard_ramp_value_monument_decision_20260630_goal_learning.md`.

Possibility Storm / Creative Technique decision generated on 2026-06-30:

- Candidate:
  `possibility_storm_same_lane_benchmark_cut_creative_technique`.
- Why it was tested: after prior-exact blockers for `Chaos Warp / Generous
  Gift` and the five current `Monument to Endurance` discard-ramp-value
  replacements, the profiled all-lanes queue had one remaining
  preflight-ready same-lane package. `Creative Technique` is protected, but the
  registry allows a same-function `big_spell_value` benchmark.
- Smoke result at `opponent_seed=20260629`, `simulation_seed=20260630`:
  candidate `3W/21L/0S` versus `607` `11W/12L/1S`.
- Critical matchup failure: Winota fell from `2W/1L/0S` on baseline `607` to
  `0W/3L/0S` on the candidate.
- Direct card-use evidence: `Possibility Storm` was accessed in `6` games and
  recorded `3` use events, but produced only one used-game outcome sample; the
  gate decision is therefore `insufficient_card_outcome_sample`, not a
  promotion signal.
- Decision: reject this exact natural package and keep `Creative Technique`
  protected. Revisit `Possibility Storm` only through a forced-access
  diagnostic or a materially different package hypothesis.
- Evidence reports:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_benchmark_generator_20260630_goal_learning_all_lanes_after_monument_closure.md`,
  `docs/hermes-analysis/master_optimizer_reports/lorehold_big_spell_value_creative_technique_gate_20260630_goal_learning_smoke_20260630_213730.md`,
  and
  `docs/hermes-analysis/master_optimizer_reports/lorehold_possibility_storm_creative_technique_decision_20260630_goal_learning.md`.

Profiled cut queue closure generated on 2026-06-30:

- Scope: current same-lane one-for-one package queue over protected deck `607`,
  with variant decks `608` through `616` used as candidate context.
- Latest all-lanes generator result:
  `candidate_pool_count=270`, `pair_evaluation_count=1080`,
  `preflight_ready_pair_count=0`, and `selected_package_count=0`.
- The prior-reject registry now blocks the current rejected package signatures
  for `Chaos Warp / Generous Gift`, all five current `Monument to Endurance`
  discard-ramp-value replacements, and `Possibility Storm / Creative
  Technique`.
- Decision: stop this one-for-one queue. The next Lorehold learning cycle must
  either introduce a new strategic safe-cut model, a multi-card package
  hypothesis that preserves the Winota/fast-pressure guard, or a forced-access
  diagnostic used only for card-understanding evidence.
- Updated planner result:
  `gate_ready_now_count=0`, `prior_rejected_package_count=59`, and
  recommended next action
  `review_focus_access_trace_then_define_next_deck_or_runtime_package`.
- Evidence report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_queue_closed_decision_20260630_goal_learning.md`.
- Next-action report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_next_action_planner_20260630_goal_learning_queue_closed.md`.

Seed-safe cut synthesis generated on 2026-06-30:

- Scope: protected baseline deck `607`, current manual cut review, current
  deck-607 exposure profile, current cut-safety manifest, and current
  safe-cut replanner blockers.
- Result: `seed_safe_cut_ready_count=0` across `94` deck cards. The only
  same-lane-only slots are `Creative Technique` and `Bender's Waterskin`; both
  remain blocked for generic package work because they require concrete
  same-lane replacement proof and have prior/protected evidence.
- Decision: do not keep generating one-card swaps from the old queue. The next
  deck-learning step is `expand_cut_safety_model_or_multi_card_shell_before_gate`:
  build a new cut-safety model from failed-seed traces/current utilization, or
  design a multi-card shell that preserves mana floor, protection, and miracle
  density before any natural battle gate.
- Evidence reports:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_seed_safe_cut_hypothesis_20260630_goal_learning.md`
  and
  `docs/hermes-analysis/master_optimizer_reports/lorehold_next_action_planner_20260630_goal_learning_seed_safe_synthesis.md`.

From-scratch shell handoff generated on 2026-06-30:

- Scope: full 100-card challengers generated from the Lorehold `607-616`
  corpus, with protected `607` fixed as the baseline opponent rather than
  treated as a swap list.
- Confirmed shell evidence now consumed by the current next-action planner:
  `challenger_lorehold_recursion_discard_engine_v1` lost the 8x3 gate
  `4/24` versus `607` at `6/24`, and
  `challenger_lorehold_recursion_discard_pressure_repair_v1` lost `3/24`
  versus `607` at `6/24`.
- Interpretation: the recursion/Squee shell produced useful telemetry, but it
  did not convert into wins. Shell-level telemetry is not card-level proof and
  cannot promote an individual card or a full deck by itself.
- Current planner top action:
  `rework_from_scratch_shell_after_current_shells_rejected`. The next shell
  must materially repair pressure conversion and closing windows while
  preserving the `607` mana/protection/miracle floor before any new natural
  battle gate.
- Evidence reports:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_goal_definitive_learning_v1_recursion_discard_engine_confirm8x3.md`,
  `docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_goal_pressure_repair_v1_recursion_discard_pressure_repair_confirm8x3_sources_v3.md`,
  and
  `docs/hermes-analysis/master_optimizer_reports/lorehold_next_action_planner_20260630_goal_learning_seed_safe_synthesis.md`.

Miracle pressure-conversion shell decision generated on 2026-06-30:

- Candidate:
  `challenger_lorehold_miracle_pressure_conversion_v1`.
- Why it was tested: preserve the `607` land base and protected
  miracle/protection floor while adding a compact conversion package
  (`Aetherflux Reservoir`, `Birgi`, `Squee`, `Faithless Looting`,
  `Underworld Breach`, `Wheel of Fortune`, `Boros Charm`, and `Silence`).
- Smoke result against fixed `607`: baseline `607` = `1/4`; candidate =
  `0/4`.
- Direct strategic signal: candidate miracle games fell to `2/4` versus
  baseline `4/4`; `Squee` reached the graveyard once but returned `0` times;
  `Birgi` generated `0` mana-trigger games.
- Decision: reject this exact shell and do not confirm it to 8x3. Preserving
  the `607` floor was necessary but not sufficient; the next shell must improve
  actual closing-window execution instead of merely adding compact conversion
  cards.
- Evidence report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_pressure_conversion_decision_20260630_goal_learning.md`.

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

Access-density from-scratch decision generated on 2026-06-30:

- Candidate:
  `challenger_lorehold_access_density_control_v1`.
- Purpose: test whether the weak-seed access issue could be repaired by a full
  shell that preserves the protected `607` miracle engine while adding both
  `Enlightened Tutor` and `Gamble`.
- Structural result: legal 100-card challenger with no missing required cards,
  but the matrix flagged overfilled `topdeck_miracle_setup`, `hand_filter`,
  `spell_chain_conversion`, and `graveyard_recursion`.
- Natural smoke result against fixed `607`: candidate `0/4` versus `607`
  `1/4`; the tutors did not naturally appear enough to prove card-level impact.
- Forced tutor-access result with `Enlightened Tutor|Gamble` in opening hand:
  candidate still `0/4` versus `607` `1/4`; `Enlightened Tutor` was accessed
  `4/4`, cast `3`, resolved `4`, while `Gamble` was accessed `4/4`, cast `3`,
  resolved `2`.
- Decision: reject this exact from-scratch access-density shell. More access
  alone is not sufficient evidence; future tutor work must use a smaller
  same-lane package or a seed-safe cut model, not a broad overfilled shell.
- Evidence report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_access_density_control_decision_20260630_goal_current.md`.

From-scratch shell failure synthesis generated on 2026-06-30:

- Scope: all current from-scratch shell gates consumed by the planner,
  including recursion/discard, pressure repair, miracle pressure conversion,
  and access-density natural plus forced tutor-access gates.
- Result: `4` unique shells and `5` shell gate rows were evaluated; all were
  rejected against protected `607`. Best natural delta was `-1` win and best
  forced-access delta was also `-1` win.
- Failure-mode counts now include `wins_below_protected_607=5`,
  `upkeep_rummage_floor_regressed=5`, `package_lanes_overfilled=4`,
  `miracle_floor_regressed=3`, and
  `positive_squee_telemetry_not_converting=3`.
- Decision: do not run another broad from-scratch shell gate now. The current
  planner top action is `mine_closing_window_trace_before_next_shell`.
- Required before the next shell: mine `607` win traces versus candidate loss
  traces for closing-window sequence differences, name the exact lane or
  pressure failure being repaired, predeclare miracle/topdeck/conversion-card
  targets, and keep forced-access diagnostics separate from natural promotion
  evidence.
- Evidence reports:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_shell_failure_synthesis_20260630_goal_learning.md`
  and
  `docs/hermes-analysis/master_optimizer_reports/lorehold_next_action_planner_20260630_goal_learning_shell_failure_synthesis.md`.

Closing-window trace mining generated on 2026-06-30:

- Scope: exact same-opponent slots where protected `607` won and a rejected
  from-scratch shell lost, across the current recursion/discard, pressure
  repair, and access-density gates.
- Result: `13` direct comparisons; every compared challenger loss died before
  the 607 closing window. Average 607 turn advantage was `10.15` turns.
- Dominant strategic deficits were `lorehold_cost_paid=153`,
  `lorehold_spell_cast=134`, `miracle_cast=71`,
  `lorehold_upkeep_rummage=63`, `topdeck_manipulation_activated=41`, and
  `static_cost_reduction_total=37`.
- Dominant anchor deficits were `Sensei's Divining Top`, `Scroll Rack`,
  `Approach of the Second Sun`, `Victory Chimes`, `Mizzix's Mastery`,
  `Bender's Waterskin`, and `Jeska's Will`.
- Decision: the next deck-learning step is
  `build_trace_targeted_micro_package_from_closing_window`. Build only a
  micro-package that preserves those 607 anchors, predeclares miracle/topdeck
  and spell-volume targets, and repairs pressure/closing-window execution.
- Evidence reports:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_closing_window_trace_miner_20260630_goal_learning.md`
  and
  `docs/hermes-analysis/master_optimizer_reports/lorehold_next_action_planner_20260630_goal_learning_closing_window_trace.md`.

Trace-targeted micro-package model generated on 2026-06-30:

- Scope: consume the closing-window hypotheses and the current seed-safe cut
  synthesis before allowing any new Lorehold swap or shell gate.
- Result: `3` trace hypotheses were evaluated, but `ready_micro_package_count`
  is `0` because `seed_safe_cut_ready_count` is also `0`.
- Current same-lane-only cut slots are `Creative Technique` and
  `Bender's Waterskin`; both remain non-seed-safe/protected under the current
  model and cannot be used as generic cuts.
- Decision: freeze protected `607` as the current champion snapshot until new
  cut evidence exists. Do not run another deck gate unless it has a named
  add/cut package, seed-safe cut status, and predeclared miracle/topdeck,
  spell-volume, and pressure-window targets.
- Evidence reports:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_trace_targeted_micro_package_model_20260630_goal_learning.md`
  and
  `docs/hermes-analysis/master_optimizer_reports/lorehold_next_action_planner_20260630_goal_learning_micro_package_model.md`.

Current champion snapshot generated on 2026-06-30:

- Scope: read-only snapshot of deck `607` after the micro-package model blocked
  new swaps without seed-safe cuts.
- Validation: `100` cards, `94` deck rows, `1` commander, `34` lands, `0`
  validation errors, and all `9` protected anchors present.
- Role profile: `15` ramp, `12` draw, `9` protection, `9` wincon, `7`
  removal, `6` board wipe, `2` engine, `2` creature, `2` unknown, `1` tutor,
  plus commander and lands.
- Decision: keep `607` as the current champion snapshot. After this snapshot
  exists, the planner moves to
  `expand_trace_cut_evidence_after_607_champion_snapshot`; it must not keep
  repeating the snapshot or start a new shell gate.
- Evidence reports:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_current_champion_snapshot_20260630_goal_learning.md`,
  `docs/hermes-analysis/master_optimizer_reports/lorehold_current_champion_snapshot_20260630_goal_learning.decklist.txt`,
  and
  `docs/hermes-analysis/master_optimizer_reports/lorehold_next_action_planner_20260630_goal_learning_champion_snapshot.md`.

Trace cut-evidence expansion generated on 2026-06-30:

- Scope: classify every current `607` cut slot after the champion snapshot to
  determine whether cut-safety evidence can still be expanded before a new
  package gate.
- Result: `94` cut slots evaluated, `0` seed-safe cuts, `0` reviewable
  evidence gaps, `92` hard-blocked slots, and `2` same-lane hard-blocked slots.
- Same-lane hard-blocked slots remain `Creative Technique` and
  `Bender's Waterskin`; neither is a current generic cut.
- Decision: the current `607` one-for-one deck-improvement contract is
  exhausted. Do not run more one-for-one swap gates against `607` unless new
  external/card evidence changes a cut-safety row, the owner explicitly relaxes
  the cut contract, or a new full-shell archetype is evaluated under a separate
  contract.
- Current planner top action:
  `no_cut_slot_to_expand_under_current_607_contract`.
- Evidence reports:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_trace_cut_evidence_expander_20260630_goal_learning.md`
  and
  `docs/hermes-analysis/master_optimizer_reports/lorehold_next_action_planner_20260630_goal_learning_cut_evidence_exhausted.md`.

Lorehold deckbuilding final closure generated on 2026-06-30:

- Scope: final read-only closure over the current champion snapshot,
  trace-targeted micro-package model, cut-evidence expander, and final planner.
- Result: status `closed_current_607_champion`; deck `607` remains the current
  Lorehold champion under the active contract.
- Closure evidence: `100` cards, `1` commander, `34` lands, `9` protected
  anchors, `0` micro-packages ready, `0` seed-safe cuts, `0` reviewable
  cut-evidence gaps, `92` hard-blocked slots, and `2` same-lane hard-blocked
  slots.
- Final planner top action:
  `lorehold_deckbuilding_closed_current_607_champion`.
- Reopen conditions: new external/card evidence changes a cut-safety row; the
  owner explicitly relaxes protected-cut rules for a named slot; a new
  full-shell archetype is evaluated under a separate declared contract; or
  battle/runtime changes materially alter the current `607` evidence inputs.
- Forbidden under this closure: do not run another one-for-one swap gate
  against `607`, do not cut `Creative Technique` or `Bender's Waterskin` as
  generic cuts, do not promote from forced-access signal alone, and do not
  replace `607` from structure-only or aggregate-only evidence.
- Evidence reports:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_deckbuilding_final_closure_20260630_goal_learning.md`
  and
  `docs/hermes-analysis/master_optimizer_reports/lorehold_next_action_planner_20260630_goal_learning_final_closure.md`.

Electro ramp-benchmark decision generated on 2026-06-30:

- Candidate:
  `electro_assaulting_battery_same_lane_benchmark_cut_bender_s_waterskin`.
- Add/cut: `+Electro, Assaulting Battery`; `-Bender's Waterskin`.
- Scope: natural equal package gate, no forced access, 8 real opponents,
  3 games per opponent, baseline deck `607`, candidate deck id `607`.
- Corrected result: `607` = `11W/12L/1S`; candidate = `6W/18L/0S`.
- Fast-pressure Winota check: `607` = `2W/1L`; candidate = `0W/3L`.
- Direct card-use evidence: `Electro, Assaulting Battery` recorded `9` use
  events; baseline `Bender's Waterskin` recorded `8` use events.
- Promotion failure: candidate lost five wins, dropped miracle casts by `23`,
  Lorehold spell casts by `65`, discard-to-top replacements by `4`, and
  topdeck activations by `6`.
- Decision: reject this exact same-lane ramp benchmark. `Electro` is legal and
  battle-ready enough to test, but it is not a better replacement for
  `Bender's Waterskin` in the current `607` shell.
- Evidence report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_electro_waterskin_decision_20260630.md`.

Forced-exposure probe decision generated on 2026-06-30:

- Scope: `11` prior-negative or low-exposure packages, forced access mode
  `opening_hand`, protected baseline `607`, `8` real opponents, `3` games per
  opponent, opponent seed `20260629`, simulation seed `20260630`.
- Purpose: prove whether the candidate card matters when actually accessed.
  This is diagnostic only and cannot promote a deck without natural
  confirmation.
- Result counts: `6` packages showed forced-access signal requiring natural
  confirmation, `3` tied and require natural confirmation if revisited, `1`
  showed no lift, and `1` remained inconclusive because the card was accessed
  but effectively not used.
- Highest forced signals: `storm_kiln_artist_cut_arcane_signet` at `+16.66pp`,
  `valakut_hand_filter_cut_big_score` at `+12.50pp`, and
  `enlightened_access_benchmark_cut_land_tax` at `+8.33pp`.
- Rejected from this diagnostic: `gamble_access_benchmark_cut_land_tax`.
- Runtime/play-heuristic review: `volcanic_recursion_cut_pinnacle`, because
  `Volcanic Vision` was accessed in forced mode but recorded `0` use.
- Decision: do not change `deck_607` from forced-access evidence. Run natural
  confirmation only for the forced-signal queue, starting with the largest
  signal and smallest strategic-regression risk.
- Evidence report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_forced_exposure_probe_decision_20260630.md`.

Forced-signal natural confirmation generated on 2026-06-30:

- Scope: natural confirmation for the three largest forced-access signals:
  `storm_kiln_artist_cut_arcane_signet`,
  `valakut_hand_filter_cut_big_score`, and
  `enlightened_access_benchmark_cut_land_tax`.
- Forced access mode: `none`; protected baseline `607`, `8` real opponents,
  `3` games per opponent, opponent seed `20260629`, simulation seed
  `20260630`.
- Result: all three packages failed promotion under natural access.
  `Storm-Kiln Artist` over `Arcane Signet` lost `9W/15L/0S` versus `607`
  `11W/12L/1S`; `Valakut Awakening // Valakut Stoneforge` over `Big Score`
  lost `9W/15L/0S` versus `607` `11W/12L/1S`; `Enlightened Tutor` over
  `Land Tax` tied wins at `11W` but regressed the loss/stall profile
  `11W/13L/0S` versus `607` `11W/12L/1S`.
- Direct card-use evidence exists for all three candidates, so the rejection
  is not an invisible-card sampling artifact.
- Decision: no natural promotion. Keep `Arcane Signet`, `Big Score`, and
  `Land Tax` in protected `deck_607`; do not rerun these exact swaps unless a
  different same-lane or package-level hypothesis changes the cut logic.
- Evidence report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_forced_signal_natural_confirm_decision_20260630.md`.

Storm-Kiln runtime-corrected confirmation generated on 2026-06-30:

- The earlier `Storm-Kiln Artist` result is historical but under-modeled:
  the active rule treated the card as creature body plus artifact-power
  annotation and did not execute the magecraft Treasure trigger.
- Runtime was upgraded to
  `creature_body_artifact_power_annotation_magecraft_treasure_runtime_v1`.
  The battle executor now creates one Treasure when the controller casts or
  copies an instant or sorcery; artifact-power scaling remains
  `annotation_only`.
- Retest scope: `Storm-Kiln Artist` over `Arcane Signet`, forced access mode
  `none`, protected baseline `607`, `8` real opponents, `3` games per
  opponent, opponent seed `20260629`, simulation seeds `20260630,123,999`.
- Aggregate result: candidate `29W/43L/0S` across `72` games versus `607`
  `27W/44L/1S`, with `Storm-Kiln Artist` recording `23` cast/cost events,
  `17` `trigger_resolved` events, and `17` `treasure_created` events.
- Strategic signal was real: miracle casts `+69`, topdeck activations `+65`,
  discard-to-top replacements `+107`, Lorehold spell casts `+59`, and
  spell-rummage events `+63` versus protected `607`.
- Promotion failure: the Winota fast-pressure slice regressed to `3W/6L`
  versus `607` `4W/5L`. Therefore do not change the deck. Keep
  `Arcane Signet` protected until a pressure-safe same-lane or package-level
  hypothesis beats `607` with direct card-use evidence.
- Evidence report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_storm_kiln_arcane_runtime_decision_20260630.md`.

Profiled same-lane benchmark decision generated on 2026-06-30:

- Scope: `3` same-lane benchmarks from profiled cut slots after current forced
  confirmation evidence was added to prior-result defaults.
- Forced access mode: `none`; protected baseline `607`, `8` real opponents,
  `3` games per opponent, opponent seed `20260629`, simulation seed
  `20260630`.
- Result: `The Warring Triad` over `Bender's Waterskin` lost `6W/18L/0S`
  versus `607` `11W/12L/1S` and regressed Winota to `0W/3L`; `Ephemerate`
  over `Winds of Abandon` lost `9W/15L/0S` and also regressed Winota to
  `0W/3L`.
- `Planetarium of Wan Shi Tong` over `Creative Technique` lost `8W/16L/0S`
  versus `607` `11W/12L/1S`; the card was used, but the package lost three
  wins and the card-level outcome sample is not enough to override the
  protected baseline.
- Direct card-use evidence exists for all three candidates:
  `The Warring Triad` use `12`, `Planetarium of Wan Shi Tong` use `21`, and
  `Ephemerate` use `30`.
- Decision: no deck change. Keep `Bender's Waterskin`, `Creative Technique`,
  and `Winds of Abandon` in protected `deck_607`.
- Evidence report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_benchmark_gate_decision_20260630.md`.

Cloud Key same-lane benchmark decision generated on 2026-06-30:

- Candidate:
  `cloud_key_same_lane_benchmark_cut_bender_s_waterskin`.
- Add/cut: `+Cloud Key`; `-Bender's Waterskin`.
- Scope: natural equal package gate, no forced access, baseline deck `607`,
  candidate deck id `607`, `8` real opponents, `3` games per opponent.
- Corrected result: `607` = `11W/12L/1S`; candidate = `9W/15L/0S`.
- Fast-pressure Winota check: `607` = `2W/1L`; candidate = `0W/3L`.
- Direct card-use evidence: `Cloud Key` recorded `15` use events and was
  accessed in `6` games; baseline `Bender's Waterskin` recorded `8` use
  events.
- Promotion failure: candidate lost two wins, dropped miracle casts from `48`
  to `38`, spell casts from `240` to `229`, static cost reduction from `70` to
  `65`, and upkeep rummage from `95` to `49`.
- Decision: reject this exact same-lane ramp benchmark. `Cloud Key` is a
  coherent cost-reduction hypothesis, but it is not a better replacement for
  `Bender's Waterskin` in the current `607` shell.
- Evidence report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_lane_decision_20260630_cloud_key_reject.md`.

Hand-filter expanded decision generated after PG270 on 2026-06-30:

- Scope: protected baseline deck `607`, full deck-607 exposure profile, and
  hand-filter/value candidates from the current miner after `Currency
  Converter` runtime promotion/sync.
- Tooling correction: `lorehold_card_exposure_profiler.py` can profile a full
  deck by `--deck-id`, records active effects/scopes, and prevents disabled
  generated rules from overriding active card lanes.
- Cut-model result: original miner pairs `25`, expanded deck-607 pairs `445`,
  normal preflight-ready pairs `0`, expanded preflight-ready pairs `0`.
- Natural gate evidence: `Valakut Awakening // Valakut Stoneforge` over
  `Improvisation Capstone` lost `7W/17L/0S` versus `607` at `11W/12L/1S`;
  `Wheel of Fortune` over `Improvisation Capstone` lost `9W/15L/0S`; `Olórin's
  Searing Light` over `Improvisation Capstone` showed a positive smoke result
  but was invalid for hand-filter promotion because the active lane is removal,
  not hand-filter.
- Decision: no deck change. Future Olórin work belongs in
  interaction/removal benchmarking, and hand-filter work must first find a new
  safe cut or runtime evidence.
- Evidence report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_expanded_decision_20260630_post_pg270.md`.

Runtime enablement checkpoint generated on 2026-06-30:

- PG263 promoted and synced eight runtime-gap cards that occur in the
  Lorehold/opponent candidate surface:
  `Goliath Daydreamer`, `Twinflame Tyrant`, `Verge Rangers`,
  `Boros Reckoner`, `Terror of the Peaks`, `Balefire Liege`,
  `Firesong and Sunspeaker`, and `Repercussion`.
- PG264 promoted and synced `Gisela, Blade of Goldnight` with the exact
  static-damage scope
  `opponent_or_opponent_permanent_damage_doubled_self_damage_halved_v1`.
- PG265-PG271 subsequently promoted and synced `Lens of Clarity`,
  `Eight-and-a-Half-Tails`, `Neheb, the Eternal`, `Cloud Key`,
  `Alhammarret's Archive`, `Currency Converter`, and `Hidden Retreat`; the
  focus-access generator then advanced through PG272 Brainstone.
- PG272 promoted and synced `Brainstone` from stale
  `brainstone_draw_three_put_two_back_unexecuted_v1` naming to exact executable
  scope `brainstone_draw_three_put_two_back_for_first_draw_miracle_v1`, with
  PostgreSQL postcheck proving `active_unexecuted_rows_after=0` and the focused
  Brainstone runtime test passing.
- PG273 promoted and synced `Codex Shredder` with exact activated artifact
  runtime for target-player mill one and five-mana tap/sacrifice graveyard-card
  recursion to hand. This removes one recursion split item from the runtime
  gap queue but is not deck-promotion evidence by itself.
- PG274 promoted and synced `Perpetual Timepiece` with exact activated artifact
  runtime for self-mill two and two-mana exile/shuffle of selected graveyard
  cards into library. This removes one more recursion split item from the
  runtime-gap queue but is also not deck-promotion evidence by itself.
- PG275 promoted and synced `Chaos Wand` with exact activated artifact runtime
  for four-mana tap target-opponent library exile until instant/sorcery, free
  cast of the hit card, and random bottoming of uncast exiled cards. This
  removes one free-cast split item from the runtime-gap queue but is not
  deck-promotion evidence by itself.
- PG276 promoted and synced `Assemble the Players` with exact static
  top-library permission runtime: look at the top card any time and, once each
  turn, cast a creature spell with power 2 or less from the top by paying its
  normal mana cost. This removes one split-scope top-library cast-permission
  item from the runtime-gap queue but is not deck-promotion evidence by itself.
- PG277 promoted and synced `Ghoulcaller's Bell` with exact activated artifact
  runtime for `{T}: each player mills one card`, using
  `artifact_tap_each_player_mill_one_v1`. This removes the `mill_spell`
  residual item from the runtime-gap queue but is not deck-promotion evidence
  by itself.
- PG278 promoted and synced `Lantern of Insight` with exact static plus
  activated top-library runtime: each player's top card is revealed, and `{T}`,
  sacrifice this artifact shuffles target player's library. The battle runtime
  uses only revealed-top information when deciding whether to cash in the
  artifact, so this is runtime/scope evidence, not deck-promotion evidence by
  itself.
- PG279 promoted and synced `Possibility Storm` with exact spell-cast
  replacement runtime: hand-cast spells are exiled, the controller exiles from
  the top until a shared card type, may cast the hit for free, and bottoms the
  remaining cards randomly. Runtime marks the original spell as replaced so it
  cannot resolve later from the stack. This is a high-impact `free_cast`
  runtime unlock, not deck-promotion evidence by itself.
- PG280 promoted and synced `Kayla's Music Box` with exact activated artifact
  runtime: `{W}, {T}` exiles the controller's top library card face down with
  controller-only look permission, and `{T}` lets the controller play owned
  cards exiled with that source until end of turn by paying normal costs. This
  removes one `free_cast` split item but is not deck-promotion evidence by
  itself.
- The current runtime-gap queue is
  `docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260630_post_pg282_final_eight.md`.
  PG281/PG282 closed the residual runtime queue; the current SQLite
  verified/auto filter removes all `61` raw blocked runtime cards and the
  remaining blocked runtime gap count is `0`.
- The current focus generator output is
  `docs/hermes-analysis/master_optimizer_reports/lorehold_focus_access_package_generator_20260630_after_profiled_gate.md`.
- The current readiness handoff is
  `docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_candidate_readiness_20260630_post_pg282_final_eight.md`;
  applied/synced runtime packages must not be routed back to PG apply.
- Interpretation for deck work: this unlocks future candidate testing for more
  cards, but it is not deck-promotion evidence by itself. `deck_607` remains
  protected until a same-lane candidate ties or beats it with card-use and
  replay-trace proof.

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

Learning-frontier closure generated on 2026-07-05:

- Scope: consume the current topdeck sidecar probe evidence miner, sidecar
  candidate queue, hypothesis queue, from-scratch shell synthesis, post-safe-cut
  route, and mana-base decision integrator.
- Result: `probe_row_count=48`, `queue_row_count=40`,
  `matrix_candidate_row_eligible_count=0`, `safe_cut_ready_count=0`,
  `mana_eligible_pair_count=0`, `hypothesis_natural_gate_ready_count=0`, and
  `from_scratch_can_run_next_battle_gate=false`.
- Decision: all current execution routes are closed. Do not materialize a
  sidecar deck, run forced access, open a natural battle gate, or retest the
  exact rejected Plateau pairs from watchlist evidence alone.
- Next allowed work: write a `topdeck_floor_trace_target_contract` for target
  cards such as `Penance`, `Galvanoth`, `Dragon's Rage Channeler`,
  `Valakut Awakening // Valakut Stoneforge`, and `Wheel of Fortune`; pressure
  and spell-chain followups must wait until the topdeck/miracle floor is
  preserved by trace evidence.
- The trace target contract is now written with `target_card_count=5` and
  `trace_collection_allowed_now=true`, but still has
  `candidate_deck_materialization_allowed_now=false`,
  `structure_matrix_allowed_now=false`, `forced_access_allowed_now=false`,
  `natural_battle_gate_allowed_now=false`, and `promotion_allowed_now=false`.
- Generic staples remain blocked for the current `607` shell: `Mana Vault` and
  `The One Ring` need same-lane nonanchor cut proof, drawn/cast/used trace, no
  miracle/topdeck regression, and an equal opponent/seed gate before any real
  deck action.
- Evidence report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_learning_frontier_after_probe_closure_20260705_current.md`.
- Trace target contract:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_floor_trace_target_contract_20260705_current.md`.
- Trace evidence collector:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_floor_trace_evidence_collector_20260705_current.md`.
- Collector result: all `5` topdeck targets permit trace collection as learning,
  but `microbenchmark_runnable_count=0`, `seed_safe_same_lane_count=0`, and all
  `5` remain cut-safety blocked. `Penance`, `Galvanoth`,
  `Valakut Awakening // Valakut Stoneforge`, and `Wheel of Fortune` also carry
  prior-reject blockers; `Dragon's Rage Channeler` has no current prior reject
  but still needs a nonanchor same-lane cut model before any forced-access run.
- Current next action:
  `mine_new_nonanchor_same_lane_cut_models_before_any_trace_execution`.
- Non-anchor cut model miner:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_nonanchor_cut_model_miner_20260705_current.md`.
- Miner result: `Dragon's Rage Channeler` is the primary clean-prior target, but
  its `6` same-lane slots are hard-blocked and the current model has
  `seed_safe_nonanchor_count=0` and `reviewable_nonanchor_gap_count=0`.
  `Penance`, `Galvanoth`, `Valakut Awakening // Valakut Stoneforge`, and
  `Wheel of Fortune` remain prior-reject targets with no non-anchor cut model.
- Current next action:
  `collect_new_cut_evidence_or_define_new_shell_contract_before_execution`.
- Post-safe-cut route and sidecar queue now consume the non-anchor miner as an
  explicit input. The refreshed route still selects
  `topdeck_access_first_sidecar_shell` with `one_for_one_cut_ready_count=0`,
  `nonanchor_seed_safe_count=0`, and `nonanchor_reviewable_gap_count=0`.
  The refreshed sidecar queue keeps `40` learning rows, `0` matrix-eligible
  rows, and adds non-anchor blockers to all `5` topdeck targets before any
  forced-access or materialization path can open.

Topdeck access-first sidecar shell contract generated on 2026-07-05:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_access_first_sidecar_shell_contract_20260705_current.md`.
- JSON:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_access_first_sidecar_shell_contract_20260705_current.json`.
- Status:
  `topdeck_access_first_sidecar_contract_written_no_matrix_rows_keep_607`.
- Contract key:
  `topdeck_access_first_sidecar_shell_contract`.
- Shell key:
  `topdeck_access_first_sidecar_shell`.
- Current counts: `queue_row_count=40`,
  `matrix_candidate_row_eligible_count=0`, `topdeck_target_row_count=5`,
  `trace_collection_allowed_count=5`, and `microbenchmark_runnable_count=0`.
- Mana floor preserved from the current value model: `34` lands, `15` ramp,
  and `49` land-plus-ramp mana sources. A sidecar cannot reduce that floor
  unless a later mana model and equal gate prove the replacement.
- Primary clean-prior target:
  `Dragon's Rage Channeler`, still blocked as
  `clean_prior_target_blocked_no_nonanchor_cut` with `0` seed-safe non-anchor
  cuts and `0` reviewable non-anchor gaps.
- Contract policy: `Mana Vault` and `The One Ring` remain learning-only, not
  protected-`607` deck changes, until each has lane fit, named same-lane cut,
  direct trace proof, preserved miracle/topdeck floors, and same-seed battle
  evidence.
- Structure-matrix contract allowed now: `false`; structure-matrix scoring:
  `false`; candidate deck materialization: `false`; forced access: `false`;
  natural battle gate: `false`; promotion: `false`.
- Next allowed work:
  `build_named_same_lane_cut_models_for_topdeck_and_mana_rows_before_structure_matrix`.

Operational lesson:

- This contract is the learning surface requested for deckbuilding priorities:
  it records how lands, ramp, topdeck anchors, artifact/staple value, and cut
  safety are weighed before any list is created.
- It does not make a better deck yet. It preserves `607` as champion while the
  system learns which non-anchor cuts could possibly open a fair topdeck
  challenger.

Named same-lane cut frontier generated on 2026-07-05:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_named_same_lane_cut_frontier_20260705_current.md`.
- JSON:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_named_same_lane_cut_frontier_20260705_current.json`.
- Status:
  `named_same_lane_cut_frontier_closed_no_safe_cut_keep_607`.
- Scope: consume the sidecar shell contract, sidecar probe evidence miner,
  non-anchor cut model, and mana-base decision integrator.
- Current counts: `probe_row_count=48`,
  `topdeck_frontier_target_count=5`, `topdeck_matrix_ready_probe_count=0`,
  `mana_generic_probe_count=28`, `mana_eligible_pair_count=0`, and
  `mana_exact_rejected_pair_count=2`.
- Interpretation: the system has now named the same-lane probes, but none are
  safe cuts. Topdeck probes are blocked by material exposure or
  miracle/topdeck floor risk; generic mana probes are blocked by mana-floor
  equivalence; and the dedicated Plateau lines are exact tested rejects unless
  new mana trace evidence changes them.
- Structure-matrix contract allowed now: `false`; structure-matrix scoring:
  `false`; candidate deck materialization: `false`; forced access: `false`;
  natural battle gate: `false`; promotion: `false`.
- Next allowed work:
  `collect_new_topdeck_floor_or_mana_trace_evidence_before_structure_matrix`.

Operational lesson:

- A named cut is only an addressable hypothesis. It becomes usable only after
  exposure, floor-equivalence, prior-reject, and trace checks pass.
- This prevents the deckbuilder from cycling back into already rejected
  `Plateau` pairs or turning exposed topdeck role cards into cuts merely
  because an added card is attractive.

Topdeck and mana trace gap scout generated on 2026-07-05:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_mana_trace_gap_scout_20260705_current.md`.
- JSON:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_mana_trace_gap_scout_20260705_current.json`.
- Status:
  `topdeck_mana_trace_gap_scout_found_unprobed_floor_sensitive_gaps_keep_607`.
- Scope: consume the named same-lane cut frontier, deckbuilding value model,
  deck-607 exposure profile, sidecar probe evidence, mana-base safe-cut model,
  and mana-base decision integrator.
- Current counts: `trace_gap_row_count=10`,
  `unprobed_topdeck_gap_count=6`, `floor_sensitive_gap_count=6`,
  `already_probed_topdeck_count=4`, `mana_safe_model_ready_pair_count=2`,
  `mana_remaining_ready_pair_count_after_exact_reject_filter=0`,
  `mana_eligible_pair_count=0`, and `mana_exact_rejected_pair_count=2`.
- Unprobed floor-sensitive rows now explicitly tracked:
  `Call Forth the Tempest`, `Hit the Mother Lode`,
  `Everything Comes to Dust`, `Rise of the Eldrazi`, `Surge to Victory`, and
  `Esper Sentinel`.
- Already-probed blocked rows remain:
  `Pinnacle Monk // Mystic Peak`, `Reforge the Soul`,
  `Improvisation Capstone`, and `Artist's Talent`.
- Mana route: closed by exact decisions. `Plateau` over `Radiant Summit` and
  `Plateau` over `Turbulent Steppe` remain rejected; there is no remaining
  model-ready mana pair after exact-reject filtering.
- Structure-matrix scoring: `false`; candidate deck materialization: `false`;
  forced access: `false`; natural battle gate: `false`; promotion: `false`.
- Next allowed work:
  `collect_targeted_floor_traces_for_unprobed_gap_rows_before_structure_matrix`.

Operational lesson:

- Low exposure is not a cut recommendation when the card is a miracle
  finisher, draw/filter card, or engine role. It is a trace gap.
- `Hit the Mother Lode` is the clearest example: it has only `11` unique
  exposure events, but it is a `miracle_conversion_finisher`; it needs
  candidate-loss versus protected-`607` floor traces before any cut model can
  treat it as replaceable.
- The scout gives the deckbuilder a better learning target without weakening
  the protected `607` list.

Gap floor trace miner generated on 2026-07-05:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_gap_floor_trace_miner_20260705_current.md`.
- JSON:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_gap_floor_trace_miner_20260705_current.json`.
- Status:
  `gap_floor_trace_miner_found_floor_evidence_keep_607`.
- Scope: consume the trace-gap scout and all current local Lorehold gate JSON
  reports with `game_results`. The miner only uses same-slot rows where
  protected `607` won, a candidate lost, and the target card produced real
  `card_event_counts` for `607`.
- Current counts: `scanned_gate_report_count=953`,
  `scanned_game_result_report_count=171`, `target_card_count=6`,
  `target_with_floor_trace_count=6`,
  `same_slot_607_win_candidate_loss_trace_count=540`, and
  `positive_target_delta_trace_count=520`.
- Cut-blocked floor traces found:
  `Call Forth the Tempest` (`58` traces, `58` positive deltas),
  `Hit the Mother Lode` (`45` traces, `44` positive deltas),
  `Everything Comes to Dust` (`102` traces, `102` positive deltas),
  `Rise of the Eldrazi` (`68` traces, `67` positive deltas),
  `Surge to Victory` (`112` traces, `111` positive deltas), and
  `Esper Sentinel` (`155` traces, `138` positive deltas).
- Structure-matrix scoring: `false`; candidate deck materialization: `false`;
  forced access: `false`; natural battle gate: `false`; promotion: `false`.
- Next allowed work:
  `feed_floor_trace_blockers_back_into_cut_models_before_structure_matrix`.

Operational lesson:

- The six unprobed gap cards are no longer merely suspicious low-exposure
  slots. Current evidence shows they participate in protected-`607` wins in
  same-slot comparisons where candidates lost.
- These cards become cut blockers. A future candidate can still replace one,
  but only with a named same-lane replacement that preserves the observed floor
  and then passes the normal structure and battle gates.
- Do not turn this report into a deck change; it is cut-protection evidence.

Floor blockers wired into cut model planner on 2026-07-05:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_sidecar_cut_model_planner_20260705_current.md`.
- JSON:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_sidecar_cut_model_planner_20260705_current.json`.
- Status:
  `topdeck_sidecar_cut_model_planner_review_probes_ready_no_safe_cut_keep_607`.
- Scope: consume the sidecar queue, deckbuilding value model, safe-cut miner,
  and gap floor trace miner before any structure-matrix input can be trusted.
- Current counts: `target_row_count=12`, `named_cut_probe_count=48`,
  `safe_cut_ready_count=0`, `matrix_candidate_row_eligible_count=0`,
  `floor_trace_cut_blocker_count=6`, and
  `floor_trace_blocked_probe_count=0`.
- The current 48 named probes do not attempt to cut the six floor-blocked
  cards. The planner still records them globally as unavailable cut slots:
  `Call Forth the Tempest`, `Hit the Mother Lode`,
  `Everything Comes to Dust`, `Rise of the Eldrazi`, `Surge to Victory`, and
  `Esper Sentinel`.
- Structure-matrix scoring: `false`; candidate deck materialization: `false`;
  forced access: `false`; natural battle gate: `false`; promotion: `false`.
- Next allowed work:
  `collect_probe_evidence_for_non_floor_trace_cut_slots_only`.

Operational lesson:

- Floor-trace blockers must be applied before score-based or same-lane cut
  heuristics. A future planner expansion cannot reintroduce these six cards as
  generic cuts merely because they look underexposed or expensive.
- If a future candidate wants one of those slots, it must name a same-lane
  replacement, preserve the observed floor traces, and then pass structure and
  battle gates.

Governed learning artifact audit generated on 2026-07-05:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_artifact_contract_audit_20260705_governed_learning_artifacts_current.md`.
- JSON:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_artifact_contract_audit_20260705_governed_learning_artifacts_current.json`.
- Status: `pass`.
- Scope: classify all current local `lorehold*.json` artifacts without deleting
  historical evidence or flattening schemas into one shape.
- Current counts: `artifact_count=959`, `unknown_or_invalid_count=0`,
  `status_counts={"pass": 957, "warn": 1}`.
- The single warning is the historical
  `lorehold_role_tag_repair_synthesis_20260704_applied.json`, which declares
  `source_db_mutated=true`; it is now visible as a governed historical mutation
  record instead of an unknown schema.
- Deck universe: `pass`; current matrix: `pass`; artifact contract: `pass`;
  equal battle gate may run: `true`.
- Real deck change remains blocked because there is no explicit promotion
  decision audit with `ready_for_real_deck_change=true`.

Operational lesson:

- An unknown artifact is not neutral evidence. It either needs a specific
  classifier or a governed Lorehold learning classifier that preserves
  mutation flags, decision status, and deck-action gates.
- Passing the artifact contract means the deckbuilder can trust the evidence
  surface enough to run further gates; it does not authorize a 607 mutation or
  a promotion.

Current-best baseline synthesis generated on 2026-07-05:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_current_best_baseline_synthesis_20260705_current.md`.
- JSON:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_current_best_baseline_synthesis_20260705_current.json`.
- Status:
  `current_best_baseline_synthesis_keep_607`.
- Scope: scan the governed Lorehold evidence surface for any still-active
  promotion, candidate materialization, natural-gate, or matrix-ready signal.
- Current counts: `artifact_count=959`, `unknown_or_invalid_count=0`,
  `protected_baseline_rank=1`, `top_deck_is_607=true`,
  `current_positive_signal_count=0`,
  `overridden_historical_positive_signal_count=1`,
  `sidecar_matrix_candidate_row_eligible_count=0`,
  `sidecar_safe_cut_ready_count=0`, and `floor_trace_cut_blocker_count=6`.
- The one historical positive signal is
  `lorehold_ideal_candidate_decision_audit_20260629_v615_mana_engine_v1.json`;
  it is overridden by `lorehold_cut_methodology_reaudit_20260629.json`, which
  sets `ready_for_real_deck_change=false` and keeps the package only as
  `battle_cleared_with_cut_methodology_caveat`.
- Decision: keep `607` as the current best protected baseline. Deck action,
  candidate materialization, natural battle gate, and promotion are all
  `false` until a new shell contract or new cut evidence creates a
  materializable candidate.

Operational lesson:

- `can_run_equal_battle_gate=true` from the artifact contract means the
  evidence surface is trusted enough for a gate. It does not mean there is a
  current candidate ready to battle.
- Before any battle run, the system must first create a materializable
  candidate contract from new shell evidence or new cut evidence.

For other commanders, first create the same commander intent profile and source
provenance layer, then use the same gate.

Next shell contract synthesis generated on 2026-07-05:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_next_shell_contract_synthesis_20260705_current.md`.
- JSON:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_next_shell_contract_synthesis_20260705_current.json`.
- Status:
  `next_shell_cut_path_closed_route_miracle_access_first_keep_607`.
- Scope: merge current-best baseline evidence, value model mana floors,
  Guttersnipe + Storm-Kiln hypothesis requirements, staple accessibility,
  sidecar safe-cut counts, floor-trace blockers, and artifact-contract status
  into one pre-materialization shell contract.
- Current target shell:
  `engine_preserving_pressure_conversion_shell_v1`.
- Current target adds:
  `Guttersnipe` plus `Storm-Kiln Artist`.
- Current mana floor:
  `34` lands, `15` ramp, and `49` land+ramp sources.
- Current cut state:
  `available_named_seed_safe_cut_count=0`, `required_cut_count=2`,
  `cut_shortage=2`, `engine_cut_path_closed=true`,
  `engine_cut_path_hard_stop_cut_count=94`, and
  `engine_cut_path_target_lane_evidence_gap_count=0`.
- Fallback route:
  `miracle_access_first_shell_contract`, with
  `structure_matrix_contract_allowed_now=true`.
- Current gates:
  candidate deck materialization `false`, structure matrix `false`,
  natural battle gate `false`, deck action `false`, and promotion `false`.
- Learning-only staples:
  `Mana Vault` is legal but not owned locally and remains promotion-blocked;
  `The One Ring` is legal and owned locally but remains promotion-blocked.

Operational lesson:

- The engine-preserving pressure/conversion shell is closed under current cut
  evidence because all reviewed `607` cut slots remain hard-stopped or lack a
  target-lane evidence gap.
- The fallback learning route is the miracle/topdeck access-first structure
  matrix contract. Pressure/conversion candidates such as `Guttersnipe` and
  `Storm-Kiln Artist` must wait until that floor is preserved.
- External legality, staple rank, Game Changer status, EDHREC popularity, or
  ownership can raise learning priority, but cannot authorize a protected-607
  deck change.
- The next allowed work is:
  `design_micro_shell_structure_matrix_contract_no_battle`.

Miracle access structure matrix contract generated on 2026-07-05:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_access_structure_matrix_contract_20260705_current_relearn.md`.
- JSON:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_access_structure_matrix_contract_20260705_current_relearn.json`.
- Status:
  `miracle_access_structure_matrix_template_ready_no_candidate_no_battle`.
- Entry route:
  `next_shell_cut_path_closed_route_miracle_access_first_keep_607` from
  `lorehold_next_shell_contract_synthesis_20260705_current`.
- Required fallback route:
  `miracle_access_first_shell_contract`.
- Current matrix facts:
  `matrix_cell_count=6`, `candidate_row_count=0`,
  `matrix_scoring_allowed_now=false`, `named_seed_safe_cut_count=0`,
  `cut_shortage=2`, and `blocking_hard_gate_count=3`.
- Current closed pressure/conversion facts:
  `engine_cut_path_closed=true`,
  `engine_cut_path_hard_stop_cut_count=94`,
  `engine_cut_path_target_lane_evidence_gap_count=0`,
  and fallback structure-matrix contract allowed `true`.
- Current gates:
  candidate deck materialization `false`, natural battle gate `false`, deck
  action `false`, and promotion `false`.
- Blocking hard gates before scoring:
  `candidate_rows_declared`, `named_same_lane_cuts_exist`, and
  `aggregate_blockers_cleared_or_explained`.

Operational lesson:

- A matrix is not deck proof. It only defines how the next miracle/topdeck
  candidate rows will be judged.
- Guttersnipe and Storm-Kiln Artist stay learning-only until a candidate row
  preserves protected `607` miracle/topdeck floors and names same-lane cuts.
- The next allowed work is:
  `declare_candidate_rows_with_named_same_lane_cuts_before_scoring`.

Miracle access candidate row queue refreshed on 2026-07-05:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_access_candidate_row_queue_20260705_current_relearn.md`.
- JSON:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_access_candidate_row_queue_20260705_current_relearn.json`.
- Status:
  `miracle_access_candidate_row_queue_blocked_no_scoreable_rows_keep_607`.
- Matrix route:
  `matrix_route_governed=true`,
  `matrix_next_shell_status=next_shell_cut_path_closed_route_miracle_access_first_keep_607`,
  and `matrix_fallback_route_key=miracle_access_first_shell_contract`.
- Current queue facts:
  `source_candidate_count=5`, `scoreable_candidate_row_count=0`,
  `blocked_candidate_row_count=5`, `named_seed_safe_cut_count=0`,
  and `matrix_contract_blocker_count=28`.
- Current gates:
  matrix scoring `false`, candidate deck materialization `false`, natural battle
  gate `false`, deck action `false`, and promotion `false`.

Operational lesson:

- A candidate row queue may list useful cards, but it is not a deck-change
  permit.
- The queue must reject stale matrices that do not carry the governed
  next-shell fallback route.
- The visible topdeck/miracle candidates still need both runtime proof and named
  same-lane non-anchor cuts before scoring.
- The next allowed work is:
  `resolve_runtime_and_named_same_lane_cut_before_matrix_scoring`.

Miracle next route planner refreshed on 2026-07-05:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_next_route_planner_20260705_current.md`.
- JSON:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_next_route_planner_20260705_current.json`.
- Status:
  `miracle_next_route_planner_selected_brain_floor_protected_no_seed_safe_cut_keep_607`.
- Candidate queue gate:
  `candidate_queue_matrix_route_governed=true`,
  `candidate_queue_matrix_next_shell_status=next_shell_cut_path_closed_route_miracle_access_first_keep_607`,
  and `candidate_queue_scoreable_row_count=0`.
- Selected route:
  `Brain in a Jar`, lane `topdeck_miracle_access`, route state
  `brain_floor_traces_protect_all_cut_slots_no_seed_safe_cut`, learning score
  `110`.
- Brain package state:
  `prepared_read_only_pending_apply_approval`, with
  `brain_pg_package_route_governed=true`, `apply_ready_for_manual_review=true`,
  `apply_executed_by_this_script=false`, active Brain rule rows `0`, and safe
  same-lane cuts `0`.
- Current blockers remain:
  `named_seed_safe_cut_count=0`, Entreat safe cuts `0`, Entreat active rule
  rows `0`, matrix scoring `false`, natural battle `false`, deck action
  `false`, PostgreSQL writes `false`, and promotion `false`.
- Brain unlock audit:
  `brain_seed_safe_cut_unlock_audit_closed_no_unlockable_cut_keep_607`, with
  unlockable cuts `0` and targeted floor trace missing slots `0`.

Operational lesson:

- The route planner chooses the next learning target, not a deck edit.
- The planner must block route selection when the candidate queue is not
  governed by the routed miracle-access matrix.
- The next allowed work is:
  `continue_seed_safe_cut_discovery_or_request_explicit_brain_pg_apply_review_no_deck_action`.

Brain route-governed runtime/package preflight refreshed on 2026-07-05:

- Runtime preflight:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_in_a_jar_runtime_cut_preflight_20260705_current.md`.
- Package preflight:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_in_a_jar_pg_package_preflight_20260705_current.md`.
- Runtime status:
  `brain_in_a_jar_runtime_cut_preflight_blocked_adapter_present_no_active_rule_no_safe_cut_keep_607`.
- Package status:
  `prepared_read_only_pending_apply_approval`, with
  `apply_executed_by_this_script=false` and PostgreSQL writes still approval
  gated.
- Route gate:
  `route_gate_valid=true`,
  `route_planner_status=miracle_next_route_planner_selected_brain_floor_protected_no_seed_safe_cut_keep_607`,
  `route_planner_candidate_queue_governed=true`,
  and
  `route_planner_candidate_queue_next_shell_status=next_shell_cut_path_closed_route_miracle_access_first_keep_607`.
- Package readiness is valid only when the current runtime preflight carries the
  governed miracle route. A stale Brain preflight, missing route gate, open deck
  action, open natural battle, open promotion, or PostgreSQL write flag must
  block package readiness.
- The Brain safe-cut gap audit must also surface
  `brain_pg_package_route_governed=true`; if a package claims review readiness
  without that inherited route gate, the deckbuilding decision must remain
  blocked and rerun the governed runtime/package preflights.
- Remaining blockers:
  active Brain rule rows `0`, named seed-safe cuts `0`, safe same-lane cuts `0`,
  matrix scoring `false`, candidate deck materialization `false`, natural battle
  `false`, deck action `false`, and promotion `false`.

Operational lesson:

- Brain in a Jar is now a useful runtime learning target with a review-only
  PostgreSQL package, but it is still not a Lorehold deck edit.
- No Brain candidate list may be materialized until the active rule exists,
  Hermes is synced, the Brain runtime preflight is rerun, and a named same-lane
  seed-safe cut exists.

Brain seed-safe cut unlock audit added on 2026-07-05:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_seed_safe_cut_unlock_audit_20260705_current.md`.
- Status:
  `brain_seed_safe_cut_unlock_audit_closed_no_unlockable_cut_keep_607`.
- The audit consumes the Brain safe-cut gap, Brain cut-slot trace miner, and
  current-best baseline synthesis. It must preserve explicit mutation flags:
  PostgreSQL writes `false`, source DB mutation `false`, and deck `607`
  mutation `false`.
- Brain cut-slot trace miner:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_cut_slot_trace_miner_20260705_current.md`.
  The unlock audit consumes the compact summary JSON:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_cut_slot_trace_miner_20260705_current_summary.json`.
  It scanned `966` gate reports and `171` game-result reports, found floor
  trace for all `9` current Brain cut slots, and produced `1435` same-slot
  607-win/candidate-loss traces with `1128` positive target deltas.
- A low-exposure slot is not a safe cut. `Molecule Man` is only the diagnostic
  focus because it has the lowest exposure among prior-rejected rows. The new
  floor trace evidence protects it (`31` traces, `30` positive deltas) rather
  than unlocking it; it still requires active Brain rule proof, named same-lane
  seed-safe evidence, and new trace evidence that reverses the prior rejected
  cut before any matrix scoring.
- Hard locks:
  `Lorehold, the Historian` and `Urza's Saga` cannot unlock under the current
  protected-`607` contract.
- Protected topdeck anchors:
  `Library of Leng`, `Scroll Rack`, and `Sensei's Divining Top` require
  replacement proof that preserves the topdeck/miracle access role.
- Protected floors:
  `The Scarlet Witch` and `The Mind Stone` require floor-replacement trace
  proof before scoring.
- Public deckbuilding evidence, including EDHREC Lorehold lanes and official
  Commander Game Changer guidance for cards such as `Mana Vault` and
  `The One Ring`, is learning context only. It cannot bypass local same-lane
  cut proof, route-governed runtime proof, structure matrix review, or equal
  battle gates.

Brain post-authorized seed-safe cut discovery refreshed on 2026-07-05:

- Handoff:
  `docs/hermes-analysis/LOREHOLD_BRAIN_SEED_SAFE_CUT_DISCOVERY_2026-07-05.md`.
- Current source of truth for Brain route state:
  use the `post_authorized_full_validation` Brain artifacts rather than the
  stale `current` Brain preflight when checking whether Brain's rule is active.
- Current state:
  `brain_active_rule_count=1`, `postgres_rule_active_confirmed_now=true`,
  `safe_cut_count=0`, `unlockable_now_count=0`, matrix scoring `false`,
  candidate deck materialization `false`, natural battle gate `false`, and
  promotion `false`.
- Slot queue:
  `Molecule Man` and `Land Tax` are diagnostic prior-reject rows requiring new
  trace evidence; `Library of Leng`, `Scroll Rack`, and `Sensei's Divining Top`
  are protected topdeck anchors requiring role-preservation proof; `The Scarlet
  Witch` and `The Mind Stone` are protected floor slots requiring floor
  replacement evidence; `Urza's Saga` and `Lorehold, the Historian` cannot
  unlock under the current protected-`607` contract.
- Decision:
  Brain in a Jar is now a valid runtime/deckbuilding learning target, but it is
  still not a Lorehold deck edit. Do not score, materialize, battle, or promote
  a Brain candidate until a named same-lane seed-safe cut exists and the
  miracle-access candidate queue and structure matrix are rerun.
- Next allowed work:
  `mine_named_brain_same_lane_seed_safe_cut_no_deck_action`.

Non-floor sidecar probe evidence closure added on 2026-07-05:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_non_floor_probe_evidence_closure_20260705_current.md`.
- JSON:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_non_floor_probe_evidence_closure_20260705_current.json`.
- Status:
  `non_floor_probe_evidence_closure_closed_no_matrix_rows_keep_607`.
- Scope: consume the current sidecar cut-model planner, probe evidence miner,
  and current-best baseline synthesis. This is a read-only closure artifact:
  PostgreSQL writes `false`, source DB mutation `false`, and deck `607`
  mutation `false`.
- Current facts:
  planner named probes `48`, non-floor probes `48`, missing probe evidence
  rows `0`, safe-cut-ready rows `0`, matrix-eligible rows `0`, natural battle
  gate `false`, deck action `false`, and promotion `false`.
- Probe closure split:
  `20` topdeck probes are closed as `closed_exposed_topdeck_role`, and `28`
  mana probes are closed as `closed_generic_mana_probe_route`.
- Dedicated mana route:
  `mana_route_closed_by_exact_decisions`, with `2` exact rejected pairs and
  `0` eligible mana pairs.
- Operational lesson: the old planner next action
  `collect_probe_evidence_for_non_floor_trace_cut_slots_only` is now complete.
  No non-floor probe can be converted into a cut, matrix row, sidecar deck,
  natural battle gate, or promotion under current evidence.
- Next allowed work:
  `define_new_shell_contract_or_new_cut_evidence_before_any_battle_gate`.

Post-named frontier next-evidence router added on 2026-07-05:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_post_named_frontier_next_evidence_router_20260705_current.md`.
- JSON:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_post_named_frontier_next_evidence_router_20260705_current.json`.
- Status:
  `post_named_frontier_next_evidence_router_learning_only_keep_607`.
- Scope: consume the non-floor probe closure, named same-lane cut frontier,
  topdeck floor trace collector, non-anchor cut model miner, mana-base decision
  integrator, current-best synthesis, and staple accessibility audit.
- Current facts: non-floor probes `48`, non-floor safe cuts `0`, non-floor
  matrix rows `0`, named topdeck matrix-ready probes `0`, named mana eligible
  pairs `0`, topdeck cut-safety blocked targets `5`, topdeck seed-safe
  non-anchor cuts `0`, topdeck reviewable non-anchor gaps `0`, mana exact
  rejected pairs `2`, current positive signals `0`, and current-best top deck
  remains `607`.
- Selected next route:
  `topdeck_new_cut_evidence_scout`.
- Selected target context:
  `Dragon's Rage Channeler` is the clean-prior topdeck target, but its `6`
  same-lane slots are currently hard-blocked; this is not a matrix row and not
  a deck change.
- Secondary learning routes:
  `mana_trace_evidence_scout` is allowed only for materially distinct mana
  equivalence evidence, not exact Plateau-pair retests; `new_shell_contract_scout`
  is allowed only if it names floor metrics and cut evidence; `staple_retest_scout`
  remains closed for `Mana Vault` and `The One Ring`.
- Current gates:
  execution-ready routes `0`, deck action `false`, structure matrix `false`,
  candidate materialization `false`, forced access `false`, natural battle gate
  `false`, and promotion `false`.
- Next allowed work:
  `find_new_nonanchor_same_lane_cut_evidence_not_in_current_hard_blocked_slots`.

Topdeck new cut-evidence scout added on 2026-07-05:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_new_cut_evidence_scout_20260705_current.md`.
- JSON:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_new_cut_evidence_scout_20260705_current.json`.
- Artifact audit:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_artifact_contract_audit_20260705_topdeck_new_cut_evidence_scout_current.md`.
- Current-best synthesis:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_current_best_baseline_synthesis_20260705_topdeck_new_cut_evidence_scout_current.md`.
- Status:
  `topdeck_new_cut_evidence_scout_learning_targets_only_keep_607`.
- Scope: consume the post-named frontier router, non-anchor cut model miner,
  trace cut evidence expander, deckbuilding value model, and card exposure
  profile. This is a read-only learning artifact: PostgreSQL writes `false`,
  source DB mutation `false`, and deck `607` mutation `false`.
- Current facts: router selected `topdeck_new_cut_evidence_scout`; primary
  target remains `Dragon's Rage Channeler`; current hard-blocked same-lane slots
  are `6`; internal review-only targets are `0`; safe cut ready rows are `0`;
  matrix candidate rows are `0`; microbenchmark runnable rows are `0`; candidate
  deck materialization `false`; forced access `false`; natural battle gate
  `false`; and promotion `false`.
- Hard-blocked current DRC same-lane slots:
  `Call Forth the Tempest`, `Everything Comes to Dust`, `Hexing Squelcher`,
  `Blasphemous Act`, `Farewell`, and `Starfall Invocation`.
- Blocked internal near-misses exist, but they do not open cuts. The scout
  currently records `12` near-misses blocked by combinations of miracle core,
  structural dependency, protection shell, floor role, high exposure, protected
  cut, or prior rejected cut evidence.
- External research policy:
  official Commander legality and bracket/Game Changer context, Scryfall card
  identity, and EDHREC Lorehold public lanes are discovery inputs only. They
  may prioritize what to learn next, but they cannot bypass local same-lane cut
  proof, runtime support, matrix review, or equal battle gates.
- Current-best result after this scout: artifact contract `pass`, artifact count
  `978`, unknown or invalid artifacts `0`, validation errors `0`, current
  positive signals `0`, sidecar safe-cut rows `0`, sidecar matrix rows `0`,
  sidecar promotion `false`, ready-for-real-deck-change `false`, and top deck is
  still `607`.
- Next allowed work:
  `collect_external_or_new_trace_evidence_for_drc_nonanchor_cut`.
