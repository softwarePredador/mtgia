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
   source-lane availability, current external research, source-expansion cycle
   detection, staple/bracket guardrails, and the Lorehold benchmark rule into
   one global next-action queue;
11. run `global_commander_cross_commander_role_axis_learning_pivot.py` whenever
   the learning queue reports `source_expansion_cycle_requires_global_learning_pivot`;
   it must group role floor/excess evidence across commanders, exclude deck
   `607` from actionable counts, and choose a global role axis before any
   further same-deck source expansion, candidate copy, battle, or promotion;
   then run `global_commander_role_axis_policy_builder.py` to convert the
   chosen role axis into explicit floor/ceiling/cut-pressure policy, treating
   above-range `engine` as capacity pressure rather than a missing-role add
   lane, while keeping same-deck source expansion, candidate copy, battle,
   mutation, and promotion closed; then run
   `global_commander_engine_axis_nonland_cut_policy_model.py` to apply that
   policy to the current nonland cut model, split engine-only and
   excess-overlap cut pressure from protected commander-plan engines, and route
   all pairs to card-level usage/same-lane proof before candidate copy; then
   run `global_commander_engine_cut_usage_same_lane_proof_scout.py` to consume
   existing current-scope trace/proof artifacts for those cut-pressure cards,
   block used cuts, and require explicit same-lane replacement before any
   candidate copy can open; then run
   `global_commander_engine_cut_followup_router.py` to split blockers into
   trace-required cuts and replacement-required used cuts before any candidate
   copy, battle, mutation, or promotion can open;
12. run `global_commander_candidate_copy_materializer.py` only after a named
   add/cut pool is ready; it may materialize one hypothesis inside an isolated
   copied Hermes SQLite DB, must prove the source DB hash is unchanged, and
   must reject stale chained sources unless explicitly overridden. Protected
   blocked cut cards from the pair report must still be present in the source DB.
   Promotion/battle gates stay closed until strategy, battle, and replay
   evidence pass;
13. run `global_commander_candidate_battle_probe_audit.py` after a candidate
   copy has a small equal-seed battle/replay probe; it must compare base versus
   candidate metrics, prove replay target identity is commander-specific, and
   require added cards to be exercised in replay events before any larger gate
   can be trusted;
14. run `global_commander_battle_feedback_model.py` after battle probe/gate
   audit artifacts exist; it consolidates exact add/cut signatures into
   reusable learning feedback, blocks pairs with failed exercised equal-gate
   evidence, supersedes smaller positive probes when a larger gate rejects the
   same pair, and routes unexercised packages to exposure replay instead of
   requeueing them as fresh hypotheses;
15. run `global_commander_candidate_package_chain_audit.py` when multiple
   isolated candidate-copy swaps are chained into one package; it must prove
   every source DB stayed unchanged, every pair report matched its source,
   final core floors are repaired, strategy readiness exists, and battle plus
   promotion remain closed until a commander-specific package strategy matrix
   and replay-backed equal gate exist;
16. run `global_commander_candidate_package_strategy_matrix.py` after a clean
   package chain and before any battle probe; it must compare the base deck and
   final copied candidate against the commander's role targets, expected
   packages, and cut-risk lanes, then keep battle and promotion closed when a
   package fixes generic core floors but weakens commander-specific strategy;
17. run `global_commander_profile_blocker_repair_plan.py` whenever the package
   strategy matrix blocks battle; it must convert profile blockers into repair
   axes, source lanes, same-lane cut policies, and a rerun sequence without
   mutating decks or opening battle/promotion;
18. run `global_commander_profile_repair_candidate_model.py` after a repair
   plan and before any profile-repair candidate copy; it must name legal,
   color-identity-compatible add candidates, review-only cut pressure, blocked
   cuts, and materialization blockers for each repair axis. Large
   commander-payoff shortfalls must route to a broader commander source lane
   instead of a narrow add/cut materialization;
19. run `global_commander_payoff_source_lane_expander.py` when a commander
   payoff axis is too sparse for materialization; it must scan local Oracle
   rows by commander color identity, Commander legality, creature payoff type,
   current deck membership, and role-confirming text, then keep candidate copy
   and battle closed while routing broad shortfalls to package synthesis;
20. run `global_commander_payoff_package_synthesizer.py` after a payoff source
   lane is expanded; it must synthesize a full-profile package, exploit
   cross-axis cards such as attack-window lands, pair every add with a reviewed
   cut, enforce package-size limits, and keep materialization closed when cuts
   or stage sizing are insufficient;
21. run `global_commander_cut_source_lane_expander.py` when a synthesized
   package has too few reviewed cuts; it must scan the current deck for
   above-target role pressure, protect lands/payoffs/interaction/attack-window
   lanes, separate format staples and expected package anchors into stage-only
   rows, and keep materialization closed when value-safe cuts or package size
   still fail;
22. run `global_commander_value_safe_stage_splitter.py` after cut source-lane
   expansion; it may open only the next isolated stage-copy gate when a stage
   has paired value-safe adds/cuts under the package-size limit. It must keep
   full-package materialization closed while any add is unpaired, and it must
   keep battle/promotion closed until candidate-copy, strategy-matrix, and
   replay gates pass;
23. run `global_commander_package_scope_reducer.py` when a profile-repair
   package is blocked because the full package has fewer value-safe cuts than
   adds; it may open only the strongest smaller paired scope in an isolated DB
   copy, preferring a scope that closes a whole blocker axis, while keeping the
   original full package, battle, and promotion closed;
24. run `global_commander_contextual_stage_cut_evidence_collector.py` after
   `global_commander_stage_only_cut_evidence_plan.py` names contextual staple
   cuts; it must inspect current deck context, local format-staple context, and
   missing usage/same-lane/replay proof, but it must not reclassify a cut,
   materialize a candidate, run battle, or promote a package;
25. run `global_commander_contextual_usage_trace_scout.py` after contextual
   stage-cut collection; it must search existing local artifacts for current
   commander/deck usage traces, classify planning/rule-coherence/cross-deck
   references as non-proof, and keep candidate copy plus reclassification closed
   when no current-scope trace exists;
26. run `global_commander_contextual_usage_trace_generator.py` when the scout
   finds no current-scope trace; it may run structured replays against the
   isolated candidate DB and summarize target-deck exposure/usage, but it is
   evidence collection only, not a battle gate or promotion gate;
27. run `global_commander_contextual_usage_trace_reviewer.py` after generated
   trace exists; observed use by the target deck blocks automatic value-safe
   reclassification until same-lane replacement proof or stronger negative trace
   exists;
28. run `global_commander_same_lane_replacement_model.py` after usage review
   blocks contextual cuts; it must compare usage-blocked cuts with explicit
   same-lane replacement routes from the synthesized package, treat incidental
   role overlap as non-proof, and route to a new cut-source-lane evidence pass
   when no explicit replacement route exists;
29. run `global_commander_new_cut_source_lane_trace_collector.py` after the
   same-lane model routes to new cut-source-lane evidence; it must reuse
   existing replay artifacts first, count only target-deck traces, and keep
   value-safe reclassification closed for any remaining cut that was used,
   merely seen without usage, or not seen in the current replay window;
30. run `global_commander_forced_cut_access_trace_generator.py` only for
   unresolved remaining cuts after natural/current-scope trace collection; it
   may use `MANALOOM_FORCE_FOCUS_ACCESS_MODE=opening_hand` against the current
   evaluation target player, but forced access is diagnostic evidence only and
   must not count as a natural battle gate or promotion gate;
31. rerun `global_commander_cut_source_lane_expander.py` with the forced
   cut-access report before reducing scope again; if forced access proves the
   unresolved cuts are used, candidate copy remains closed and the next route is
   a new value-safe cut source or a smaller package with fresh cut proof;
32. run `global_commander_post_forced_recovery_synthesizer.py` after post-forced
   cut-lane expansion and scope reduction; it must select the next evidence
   lane without deck action, and if no value-safe cut pair exists it must route
   to mining a fresh value-safe cut source before package resynthesis;
33. run `global_commander_value_safe_cut_source_miner.py` after post-forced
    recovery routes to a fresh cut source; it may mine hypotheses from the
    current deck, but fresh hypotheses are not value-safe cuts until trace,
    same-lane, or equal-gate proof is collected;
34. run `global_commander_cut_source_hypothesis_trace_collector.py` after fresh
    hypotheses exist; it must reuse current replay artifacts first, count only
    target-deck usage, and keep candidate copy closed when a hypothesis was used
    or only seen without a negative proof;
35. run `global_commander_cut_hypothesis_same_lane_proof.py` after fresh
    hypothesis trace collection blocks value-safe reclassification; it must
    compare used/seen hypotheses against explicit package add axes, treat
    profile-role overlap as incidental unless the add covers that lane, and
    route to more cut-source mining or external cut research when no explicit
    same-lane route exists;
36. run `global_commander_external_cut_source_research_plan.py` when same-lane
    proof routes to more mining or external research; it must record current
    official/Commander source lanes, separate popularity and strategy articles
    from deck truth, and route to external commander reference corpus collection
    without opening candidate copy, battle, promotion, or value-safe
    reclassification;
37. run `global_commander_external_reference_corpus_collector.py` after the
    external research plan; it must map external corpus presence, absence,
    bracket context, and strategy-article signals back to named cut candidates,
    while preserving the rule that external absence cannot override target-deck
    usage and external presence cannot replace same-lane/equal-gate proof;
38. run `global_commander_external_corpus_cut_policy_mapper.py` after corpus
    collection; it must convert corpus rows into explicit miner exclusions and
    negative-review holds so the next miner pass cannot recycle the same
    blocked hypotheses as fresh value-safe cuts without new evidence;
39. rerun `global_commander_value_safe_cut_source_miner.py` with
    `--external-cut-policy-report` after policy mapping; if the policy consumes
    all current hypotheses and no fresh value-safe cut source remains, the route
    must broaden the package axis or external cut research rather than opening
    candidate copy, battle, or promotion;
40. run `global_commander_package_axis_broadening_plan.py` after policy-aware
    mining exhausts the current cut lane; it must compare current package add
    axes with target cut roles, treat secondary text on payoff cards as
    incidental rather than same-lane proof, and route to package resynthesis
    with same-lane axis requirements or external nonpayoff cut-lane corpus
    research without opening candidate copy, battle, promotion, or value-safe
    reclassification;
41. run `global_commander_same_lane_package_resynthesizer.py` after package-axis
    broadening routes to same-lane resynthesis; it must convert each exhausted
    target cut role into an explicit required add axis, hold payoff-only adds
    until they have their own same-lane cuts, and route to same-lane add source
    lane expansion while candidate copy, battle, promotion, and value-safe
    reclassification remain closed;
42. run `global_commander_same_lane_add_source_lane_expander.py` after same-lane
    package resynthesis; it must scan the current evaluation DB for legal,
    commander-color-compatible source candidates for each required add axis,
    separate review-only candidates from blocked color/legality/existing-deck
    rows, and route to package resynthesis from source lanes while candidate
    copy, battle, promotion, and value-safe reclassification stay closed;
43. run `global_commander_same_lane_package_source_synthesizer.py` after all
    required same-lane add source lanes have review candidates; it must select a
    bounded review-only add package with explicit required axes, keep every add
    unpaired until value-safe cuts are proven, and route to same-lane cut-pair
    collection without opening candidate copy, battle, promotion, or value-safe
    reclassification;
44. run `global_commander_same_lane_cut_pair_collector.py` after same-lane
    package source synthesis; it must pair each selected add only with a cut in
    the exact `replaces_cut_role`, classify protected/staple/expected-package
    cuts as stage-only or blocked, and keep candidate copy, battle, promotion,
    and value-safe reclassification closed when no same-lane value-safe pairs
    exist;
45. run `global_commander_same_lane_cut_evidence_plan.py` when same-lane cut
    pairing finds only stage-only or hard-blocked cuts; it must map every
    stage-only reason to trace, staple, anchor, prior-gate, cross-role, or
    manual evidence lanes without reclassifying cuts or opening candidate copy,
    battle, promotion, or value-safe reclassification;
46. run `global_commander_same_lane_stage_cut_trace_collector.py` after the
    same-lane cut evidence plan; it must reuse existing current-scope traces and
    local external/reference artifacts to classify stage-only cuts as used,
    seen-needs-negative-review, external-reference-only, or trace-missing while
    keeping candidate copy, battle, promotion, and value-safe reclassification
    closed;
47. run `global_commander_same_lane_used_cut_recovery_router.py` when stage-cut
    trace collection shows used cuts; it must route used cuts to explicit
    same-lane replacement proof or fresh cut-source mining/research, and it
    must keep every used cut non-value-safe until that later evidence exists;
48. run `global_commander_same_lane_new_cut_source_miner.py` after used-cut
    recovery routes to fresh cut-source mining; it must scan the current
    evaluation DB for unconsumed same-lane cut sources, block any card already
    used, seen, stage-only, blocked, or traced in the current evidence chain,
    and route to trace collection only when a genuinely fresh same-lane source
    exists. If none exists, it must broaden same-lane cut research or package
    axis before candidate copy, battle, promotion, or value-safe
    reclassification;
49. run `global_commander_same_lane_cut_axis_broadening_plan.py` when same-lane
    new cut-source mining exhausts the current deck; it must convert exhausted
    target roles into explicit external nonpayoff same-lane corpus actions,
    hold the selected add package, forbid recycling used/seen/stage-only or
    blocked cuts, and keep candidate copy, battle, promotion, and value-safe
    reclassification closed;
50. run `global_commander_external_nonpayoff_same_lane_cut_corpus_collector.py`
    after cut-axis broadening routes to external nonpayoff same-lane corpus; it
    must record role-level external source signals, source limitations, bracket
    and combo-dependency context, and target-deck trace override boundaries
    without creating cut permission, candidate copy, battle, promotion, or
    value-safe reclassification;
51. run `global_commander_external_nonpayoff_same_lane_cut_policy_mapper.py`
    after corpus collection; it must convert role-level corpus into explicit
    source-discovery policy, keep the policy role-level rather than card-level
    cut permission, require named external source candidates before miner
    reruns, and keep candidate copy, battle, promotion, and value-safe
    reclassification closed;
52. run `global_commander_external_nonpayoff_same_lane_source_candidate_discoverer.py`
    after policy mapping; it must turn allowed role-level source-discovery
    policy into named external source-candidate rows, classify current-deck,
    held-package, locally resolved, and unresolved cards, and keep card-level
    cut permission, candidate copy, battle, promotion, and value-safe
    reclassification closed;
53. run `global_commander_external_nonpayoff_same_lane_source_candidate_reviewer.py`
    after source-candidate discovery; it must locally review named candidates
    against identity, commander color identity, and role-text evidence, allow
    only resolved outside-deck/outside-package candidates as miner source seeds,
    and keep card-level cut permission, candidate copy, battle, promotion, and
    value-safe reclassification closed;
54. run `global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner.py`
    after local seed review; it must rerun same-lane cut-source mining with
    reviewed external nonpayoff seeds, prove whether any current-deck cut source
    is fresh for a seeded role, route fresh hypotheses to trace collection, and
    keep card-level cut permission, candidate copy, battle, promotion, and
    value-safe reclassification closed;
55. run `global_commander_reviewed_external_seeded_cut_trace_collector.py`
    after seeded cut-source mining finds fresh hypotheses; it must reuse
    existing replay/decision trace artifacts to classify each seeded hypothesis
    as used, seen without usage, or unseen, and keep card-level cut permission,
    candidate copy, battle, promotion, and value-safe reclassification closed;
56. run `global_commander_reviewed_external_seeded_force_access_trace_generator.py`
    only for unseen reviewed external seeded hypotheses; it must use forced
    access against the current evaluation target, classify `not_found` as
    absent from the selected evaluation DB rather than negative proof, and keep
    card-level cut permission, candidate copy, battle, promotion, and
    value-safe reclassification closed;
57. rerun `global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner.py`
    with `--db` pointing at the current evaluation DB whenever seeded
    force-access proves prior hypotheses are absent from that DB; if no fresh
    seeded same-lane source remains, route to broader external nonpayoff seed
    research or current-deck negative review before any candidate copy, battle,
    promotion, or value-safe reclassification;
58. run `global_commander_external_nonpayoff_seed_exhaustion_recovery_router.py`
    after current-DB seeded mining exhausts; it must separate exhausted seeded
    roles, unseeded roles, current-deck external candidates, held package adds,
    and identity gaps before opening any further source research;
59. run `global_commander_external_nonpayoff_current_deck_negative_review_collector.py`
    when the recovery router finds external candidates already in the current
    deck; it must reuse current-scope traces, block any used card from
    negative-review cut consideration, and keep candidate copy, battle,
    promotion, and value-safe reclassification closed;
60. run `global_commander_external_nonpayoff_new_source_or_replacement_finder.py`
    after current-deck negative review blocks used cards; it must separate
    current-deck replacement blockers, held package adds, recycled prior seeds,
    land-lane candidates, legality/identity blockers, and genuinely fresh
    outside-deck source candidates before any miner rerun, candidate copy,
    battle, promotion, or value-safe reclassification;
61. run `global_commander_external_nonpayoff_new_source_candidate_reviewer.py`
    after new-source finding; it must locally revalidate finder-ready rows
    against current evaluation DB identity, deck presence, held package state,
    recycled seed state, commander legality, land-lane routing, and role text,
    then expose reviewed cards only as scoped miner seeds. It must keep
    card-level cut permission, candidate copy, battle, promotion, and
    value-safe reclassification closed. If those seeds do not find a fresh
    current-deck same-lane cut source when the seeded miner reruns, route back
    to broader external nonpayoff seed research or current-deck negative review
    before any deck action; its immediate next gate is
    `rerun_seeded_cut_source_miner_with_new_reviewed_external_nonpayoff_sources`;
62. run `global_commander_external_nonpayoff_source_candidate_pool_expander.py`
    when the post-review seeded miner and seed-exhaustion router route to source
    expansion; it must use current external source snapshots, local DB identity,
    current-deck presence, prior seed recycling checks, Commander legality,
    and role-text evidence to broaden the candidate pool without reusing
    exhausted cards. It may create review-ready source candidates only; it must
    keep card-level cut permission, candidate copy, battle, promotion, and
    value-safe reclassification closed;
63. run `global_commander_external_nonpayoff_expanded_source_candidate_reviewer.py`
    after source-candidate pool expansion; it must revalidate expanded rows
    against current deck presence, prior recycling, Commander legality, local
    identity, color identity, land-lane routing, and role text before allowing
    only locally valid outside-deck candidates as scoped miner seeds. Banned
    cards and cards already present in the current evaluation deck remain
    blocked. It must keep card-level cut permission, candidate copy, battle,
    promotion, and value-safe reclassification closed;
64. run `global_commander_external_nonpayoff_followup_source_candidate_expander.py`
    when the expanded seeded miner and current-deck negative review still block
    every cut source; it must treat all prior finder, reviewer, and expander
    rows as cumulatively recycled, then use current external source snapshots,
    local identity, current-deck presence, Commander legality, and role-text
    evidence to produce only genuinely new follow-up source candidates. It may
    feed the existing expanded reviewer shape, but it must keep card-level cut
    permission, candidate copy, battle, promotion, and value-safe
    reclassification closed;
65. run `global_commander_external_nonpayoff_live_source_research_expander.py`
    after a cumulative source-candidate expansion finds no ready candidates; it
    must broaden current external source types, map live nonpayoff cards into
    the existing expanded-reviewer row shape, recheck local identity, current
    deck presence, Commander legality, land-lane routing, prior recycling, and
    role text, and keep card-level cut permission, candidate copy, battle,
    promotion, and value-safe reclassification closed;
66. run `global_commander_external_nonpayoff_manual_negative_trace_reviewer.py`
    after current-deck negative review finds candidates seen without usage; it
    must distinguish used cards, static/passive effects, land-lane context, and
    weak seen-without-usage evidence before any cut consideration. It may block
    weak negative evidence only; it must keep card-level cut permission,
    candidate copy, battle, promotion, and value-safe reclassification closed;
67. run `global_commander_external_nonpayoff_followup_live_source_research_expander.py`
    when manual negative trace review clears no current-deck cuts; it must carry
    all prior source, reviewer, miner, router, negative-review, and manual
    reports as cumulative recycling evidence, broaden only genuinely fresh live
    source lanes, and keep card-level cut permission, candidate copy, battle,
    promotion, and value-safe reclassification closed;
68. keep Lorehold-specific micro-optimizations, including DRC/Brain/Mana Vault
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
- `docs/hermes-analysis/master_optimizer_reports/global_commander_learning_priority_audit_20260706_source_exhaustion_current.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_learning_priority_audit_20260706_source_expansion_cycle_current.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_cross_commander_role_axis_learning_pivot_20260706_source_expansion_cycle_current.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_role_axis_policy_builder_20260706_engine_axis_current.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_engine_axis_nonland_cut_policy_model_20260706_current.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_engine_cut_usage_same_lane_proof_scout_20260706_current.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_engine_cut_followup_router_20260706_current.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_engine_cut_trace_replacement_gate_20260706_current.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_engine_cut_trace_replacement_reviewer_20260706_current.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_manual_negative_trace_reviewer_20260706_kaalia_value_safe_stage1_live_research.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_followup_live_source_research_expander_20260706_kaalia_value_safe_stage1_after_manual_trace.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_expanded_source_candidate_reviewer_20260706_kaalia_value_safe_stage1_followup_live_after_manual_trace.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner_20260706_kaalia_value_safe_stage1_followup_live_after_manual_trace.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_seed_exhaustion_recovery_router_20260706_kaalia_value_safe_stage1_followup_live_after_manual_trace.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_candidate_copy_materializer_20260705_kaalia_nonland_top_pair.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_candidate_battle_probe_audit_20260705_kaalia_nonland_floor_dynamic_target.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_battle_feedback_model_20260705_current.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_candidate_package_chain_audit_20260705_kaalia_removal_floor_step5.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_candidate_package_strategy_matrix_20260705_kaalia_removal_floor_step5.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_profile_blocker_repair_plan_20260705_kaalia_removal_floor_step5.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_profile_repair_candidate_model_20260705_kaalia_removal_floor_step5.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_payoff_source_lane_expander_20260705_kaalia_removal_floor_step5.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_payoff_package_synthesizer_20260705_kaalia_removal_floor_step5.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_cut_source_lane_expander_20260705_kaalia_removal_floor_step5.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_value_safe_stage_splitter_20260705_kaalia_removal_floor_step5.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_package_scope_reducer_20260705_kaalia_value_safe_stage1_repair_stage2.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_candidate_copy_materializer_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_core_role_audit_20260705_kaalia_value_safe_stage1_repair_scope1_hermes_only.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_strategy_matrix_20260705_kaalia_value_safe_stage1_repair_scope1_hermes_only.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_candidate_package_chain_audit_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_candidate_package_strategy_matrix_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_profile_blocker_repair_plan_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_profile_repair_candidate_model_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_payoff_source_lane_expander_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_payoff_package_synthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_cut_source_lane_expander_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_package_scope_reducer_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_stage_only_cut_evidence_plan_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_contextual_stage_cut_evidence_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_contextual_usage_trace_scout_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_contextual_usage_trace_generator_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_contextual_usage_trace_reviewer_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_same_lane_replacement_model_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_new_cut_source_lane_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_forced_cut_access_trace_generator_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_cut_source_lane_expander_20260705_kaalia_value_safe_stage1_repair_scope1_post_forced.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_package_scope_reducer_20260705_kaalia_value_safe_stage1_repair_scope1_post_forced.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_post_forced_recovery_synthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_value_safe_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_cut_source_hypothesis_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_cut_hypothesis_same_lane_proof_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_external_cut_source_research_plan_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_external_reference_corpus_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_external_corpus_cut_policy_mapper_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_value_safe_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1_external_policy.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_package_axis_broadening_plan_20260705_kaalia_value_safe_stage1_repair_scope1_external_policy.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_same_lane_package_resynthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_same_lane_add_source_lane_expander_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_same_lane_package_source_synthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_same_lane_cut_pair_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_same_lane_cut_evidence_plan_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_same_lane_stage_cut_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_same_lane_used_cut_recovery_router_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_same_lane_new_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_same_lane_cut_axis_broadening_plan_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_same_lane_cut_corpus_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_same_lane_cut_policy_mapper_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_same_lane_source_candidate_discoverer_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_same_lane_source_candidate_reviewer_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_reviewed_external_seeded_cut_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_reviewed_external_seeded_force_access_trace_generator_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1_current_db.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_seed_exhaustion_recovery_router_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_current_deck_negative_review_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_new_source_or_replacement_finder_20260706_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_new_source_candidate_reviewer_20260706_kaalia_value_safe_stage1_repair_scope1.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner_20260706_kaalia_value_safe_stage1_repair_scope1_new_sources.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_seed_exhaustion_recovery_router_20260706_kaalia_value_safe_stage1_repair_scope1_new_sources.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_source_candidate_pool_expander_20260706_kaalia_value_safe_stage1_repair_scope1_new_sources.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_expanded_source_candidate_reviewer_20260706_kaalia_value_safe_stage1_repair_scope1_new_sources.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner_20260706_kaalia_value_safe_stage1_repair_scope1_expanded_sources.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_seed_exhaustion_recovery_router_20260706_kaalia_value_safe_stage1_repair_scope1_expanded_sources.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_current_deck_negative_review_collector_20260706_kaalia_value_safe_stage1_repair_scope1_expanded_sources.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_followup_source_candidate_expander_20260706_kaalia_value_safe_stage1_repair_scope1_after_mana_vault.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_expanded_source_candidate_reviewer_20260706_kaalia_value_safe_stage1_repair_scope1_followup_after_mana_vault.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner_20260706_kaalia_value_safe_stage1_repair_scope1_followup_after_mana_vault.md`
- `docs/hermes-analysis/master_optimizer_reports/global_commander_external_nonpayoff_seed_exhaustion_recovery_router_20260706_kaalia_value_safe_stage1_repair_scope1_followup_after_mana_vault.md`

Historical candidate-copy, battle-probe, battle-feedback, and package-chain
snapshots are local ignored evidence artifacts. The surface auditor must show
missing or degraded local copies as volatile historical warnings, not as active
contract failures, but any new candidate copy, battle, requeue, or promotion
must regenerate the exact evidence before use.

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
  stay blocked on commander-specific win-plan/source evidence. Generic
  excess-role cuts must also respect commander-specific package payoffs; for
  example Kaalia Angel/Demon/Dragon creatures are blocked from generic cut pools
  until source-lane review proves they are expendable.
- Current runtime profile fallback now includes `Kaalia of the Vast` in
  `server/lib/ai/commander_reference_profile_support.dart`. This is a local
  aggregate source lane for generation prompts only: it requires Mardu color
  identity, haste/protection, real interaction, Angel/Demon/Dragon payoff
  density, and an explicit plan-B lane; it must not copy public decklists or
  promote the current Kaalia variant without the normal structure, strategy,
  battle, and replay gates.
- Current candidate-copy materialization exists only as an isolated Hermes DB
  copy step. The first global nonland candidate copy used deck `619` as a
  Kaalia test case, materialized `+Feed the Swarm / -Birgi, God of Storytelling
  // Harnfel, Horn of Bounty`, passed 100-card/singleton/source-unchanged
  structure checks, and still reports `promotion_allowed=false` plus
  `allow_battle_gate_now=false`. The materializer now also guards against stale
  chained sources: the source DB must match the pair report source unless
  explicitly overridden, and protected blocked cut cards must still be present.
  This invalidates the old five-swap Kaalia chain because `Bloodthirster` was
  already absent from that source DB.
- Current candidate battle probe auditing is diagnostic only. The Kaalia
  nonland-floor candidate copy fixed the removal floor structurally, and the
  replay wrapper now names the target as `Kaalia of the Vast` instead of stale
  `Lorehold`; however the small equal-seed probe underperformed the base
  (`33.3%` versus `66.7%`) and none of the five added removal cards were
  exercised in replay events, so promotion remains blocked.
- Current clean one-swap Kaalia candidate evidence is a useful negative
  learning example. A guarded source copy with only `+Feed the Swarm / -Birgi,
  God of Storytelling // Harnfel, Horn of Bounty` first produced local
  `battle_probe_ready_for_larger_gate` evidence on the same three real
  opponents/seed: base `33.3%`, candidate `66.7%`, stale Lorehold mentions `0`.
  Replay evidence showed `Demonic Tutor` selecting `Feed the Swarm`, then `Feed
  the Swarm` being cast/resolved and removing `Kinnan, Bonder Prodigy`.
  However the larger 9-game equal gate blocked promotion: base `66.7%`,
  candidate `22.2%`, blocker `candidate_underperformed_base_probe`. The global
  lesson is that a situational removal upgrade can be real while its cut is
  still wrong; do not cut `Birgi` from this Kaalia shell for generic removal
  without a better same-lane replacement and a passing larger gate.
- Current nonland candidate modeling now blocks cross-lane ramp cuts via
  `cross_lane_ramp_cut_requires_same_lane_source_or_gate`; this removes
  `Birgi` from generic removal cut pools. The next guarded top pair became
  `+Feed the Swarm / -Archaeomancer's Map`, but the 9-game equal gate also
  blocked promotion: base `66.7%`, candidate `33.3%`, blocker
  `candidate_underperformed_base_probe`, with `Feed the Swarm` exercised in
  replay. The current lesson is not "add Feed anywhere"; it is "interaction is
  useful, but Kaalia needs a safer same-lane cut or a different package."
- Current battle feedback modeling is read-only and aggregates the existing
  global candidate battle audits by exact add/cut signature. It found `3`
  feedback pairs: `2` `pair_blocked_by_failed_gate` rows
  (`+Feed the Swarm / -Birgi, God of Storytelling // Harnfel, Horn of Bounty`
  and `+Feed the Swarm / -Archaeomancer's Map`) and `1`
  `pair_needs_exposure_replay_before_gate` wide package where added removal
  cards were not exercised. The `+Feed / -Birgi` small positive probe is now
  explicitly superseded by the larger failed gate, and the reusable
  recommendation is `block_pair_until_new_source_lane_or_cut`, not requeueing
  the same pair as a fresh candidate.
- Current nonland candidate modeling consumes this battle feedback before
  emitting fresh add/cut hypotheses. Exact pairs marked by feedback are moved to
  `blocked_by_global_battle_feedback` / `blocked_pair_hypotheses`, so a failed
  exercised pair such as `+Feed the Swarm / -Archaeomancer's Map` cannot stay
  as the top review-ready nonland candidate without a new source lane, cut, or
  package hypothesis.
- Current package-chain auditing converted the surviving Kaalia removal-floor
  route into a single isolated copied-DB package with five swaps:
  `+Path to Exile / -Archaeomancer's Map`,
  `+Feed the Swarm / -Genji Glove`,
  `+Swords to Plowshares / -Karlach, Fury of Avernus`,
  `+Rakdos Charm / -Ardenn, Intrepid Archaeologist`, and
  `+Terminate / -Grim Tutor`. The chain report passed with
  `materializer_chain_pass=true`, `core_floor_repaired=true`, final
  `removal=6`, and `strategy_ready=true`; however `battle_gate_allowed_now`
  and `promotion_allowed` remain `false`. The next allowed gate is
  `run_commander_specific_strategy_matrix_for_package_before_battle`, not a
  natural battle or real deck mutation.
- Current package strategy matrix evidence shows why generic core repair is not
  enough. The Kaalia step5 package now reports `package_strategy_blocks_battle`
  in
  `global_commander_candidate_package_strategy_matrix_20260705_kaalia_removal_floor_step5.md`:
  lands stay `34` against target `35-37`, Angel/Demon/Dragon payoffs stay `4`
  against target `22-30`, spot interaction rises from `1` to `6` but still
  misses target `8-12`, and the package cuts attack-window cards without adding
  a same-lane replacement. Blockers are `profile_lands_below_target`,
  `profile_angels_demons_dragons_payoffs_below_target`,
  `profile_spot_interaction_below_target`, and
  `attack_window_cut_without_replacement`; `battle_gate_allowed_now=false`,
  `promotion_allowed=false`, and the next gate is
  `repair_commander_profile_blockers_before_battle`.
- Current profile blocker repair planning is read-only and maps the blocked
  Kaalia package to concrete repair axes in
  `global_commander_profile_blocker_repair_plan_20260705_kaalia_removal_floor_step5.md`.
  The report status is `profile_blocker_repair_plan_ready`, and the required
  sequence is `repair_or_restore_commander_attack_window_before_more_interaction`,
  `repair_mana_base_to_commander_land_floor`,
  `repair_commander_payoff_density_with_legal_source_lanes`,
  `finish_spot_interaction_floor_with_same_lane_cut`, and
  `rerun_global_commander_candidate_package_strategy_matrix`. Above-target mana
  acceleration, card-flow, and tutor roles are review pressure only, not
  automatic cut authorization.
- Current profile repair candidate modeling is read-only and names candidates
  without materializing a deck in
  `global_commander_profile_repair_candidate_model_20260705_kaalia_removal_floor_step5.md`.
  It found legal WBR-compatible candidate pools for the land floor, spot
  interaction, and attack-window axes, including cross-axis attack/land options
  such as `Arena of Glory` and `Hall of the Bandit Lord`, plus spot interaction
  options such as `Despark` and `Anguished Unmaking`. It still reports
  `profile_repair_candidate_model_blocks_materialization` because the
  Angel/Demon/Dragon payoff shortfall is `18` and the ready expected-package
  candidates are only `5`; therefore `candidate_copy_allowed_now=false`,
  `battle_gate_allowed_now=false`, and the next gate is
  `expand_commander_payoff_source_lane_before_candidate_copy`, not another
  narrow removal swap.
- Current payoff source-lane expansion is read-only and broadens the Kaalia ADD
  lane in
  `global_commander_payoff_source_lane_expander_20260705_kaalia_removal_floor_step5.md`.
  The local Oracle/Hermes scan found `30` legal WBR-compatible Angel/Demon/Dragon
  payoff candidates against shortfall `18`, so the lane status is
  `commander_payoff_source_lane_expanded` and
  `ready_candidates_cover_shortfall=true`. Top evidence includes
  `Balefire Dragon`, `Ancient Copper Dragon`, `Angel of the Ruins`,
  `Hoarding Broodlord`, `Hellkite Charger`, and `Avacyn, Angel of Hope`;
  off-color or already-present cards remain blocked. This still keeps
  `candidate_copy_allowed_now=false`, `battle_gate_allowed_now=false`, and
  `promotion_allowed=false`; the next gate is
  `synthesize_commander_payoff_package_before_candidate_copy`.
- Current payoff package synthesis is read-only and consumes the expanded ADD
  lane in
  `global_commander_payoff_package_synthesizer_20260705_kaalia_removal_floor_step5.md`.
  The synthesis uses `Arena of Glory` as a cross-axis attack-window/land repair,
  then adds `Despark`, `Anguished Unmaking`, and `18` Angel/Demon/Dragon
  payoffs to cover all current profile requirements. That creates `21` required
  adds but only `10` review-only cuts, leaving `11` unpaired adds and exceeding
  the materializer review limit of `8` swaps. Therefore the status is
  `commander_payoff_package_synthesis_blocks_candidate_copy`,
  blocker `insufficient_reviewable_cuts_for_full_profile_package:required_21_ready_10`,
  `candidate_copy_allowed_now=false`, `battle_gate_allowed_now=false`, and the
  next gate is `expand_commander_cut_source_lane_for_full_profile_package`.
- Current cut source-lane expansion is read-only and consumes the synthesized
  package in
  `global_commander_cut_source_lane_expander_20260705_kaalia_removal_floor_step5.md`.
  The scan expands from `10` previous review cuts to `18` value-safe cuts, with
  role budgets `mana_acceleration=9`, `card_draw_selection=2`, and
  `tutors_access=10`. It keeps `17` additional cuts in stage-only status,
  including `Birgi, God of Storytelling // Harnfel, Horn of Bounty` due global
  battle feedback, `Necropotence` due expected-package anchor protection, and
  structural staples such as `Demonic Tutor`, `Vampiric Tutor`, `Enlightened
  Tutor`, `Esper Sentinel`, `Smothering Tithe`, `Mana Vault`, `Arcane Signet`,
  and `Sol Ring`. Because the full package still needs `21` cuts and the
  stage limit is `8`, the status is
  `commander_cut_source_lane_expanded_stage_split_required`; blockers are
  `value_safe_cut_shortfall:required_21_ready_18` and
  `full_package_size_exceeds_stage_limit:required_21_limit_8`; the next gate is
  `split_synthesized_package_into_value_safe_stages`.
- Current value-safe stage splitting is read-only and consumes the synthesized
  adds plus expanded cut lane in
  `global_commander_value_safe_stage_splitter_20260705_kaalia_removal_floor_step5.md`.
  Its status is
  `commander_value_safe_stage_split_ready_for_stage_candidate_copy`; it pairs
  `18` swaps into `3` stages under the `8`-swap limit, with stage 1 containing
  `8` pairs and status `stage_ready_for_candidate_copy`. The full package
  remains blocked because `The Balrog of Moria`, `Wrathful Red Dragon`, and
  `Akroma, Angel of Wrath` are still unpaired; blocker
  `full_package_unpaired_adds:required_21_paired_18` remains active.
  Therefore `stage_candidate_copy_allowed_now=true` for the next isolated
  copy gate only, `full_package_candidate_copy_allowed_now=false`,
  `battle_gate_allowed_now=false`, and the next gate is
  `materialize_value_safe_stage_1_candidate_copy`.
- Current value-safe stage 1 materialization is isolated copied-DB evidence,
  not a deck change. The materializer report
  `global_commander_candidate_copy_materializer_20260705_kaalia_value_safe_stage1.md`
  has status `candidate_materialized_structure_ready_next_gate_closed` and
  applies `8` swaps from stage 1 into
  `global_commander_candidate_copy_materializer_20260705_kaalia_value_safe_stage1_candidate/knowledge_candidate.db`.
  It proves `source_unchanged=true`, `source_matches_pair_report=true`, all
  adds present once, all cuts absent, `total_cards_100=true`,
  `commander_count_1=true`, `promotion_allowed=false`, and
  `allow_battle_gate_now=false`. Follow-up candidate audits are
  `global_commander_core_role_audit_20260705_kaalia_value_safe_stage1_hermes_only.md`,
  `global_commander_strategy_matrix_20260705_kaalia_value_safe_stage1_hermes_only.md`,
  `global_commander_candidate_package_chain_audit_20260705_kaalia_value_safe_stage1.md`,
  and
  `global_commander_candidate_package_strategy_matrix_20260705_kaalia_value_safe_stage1.md`.
  The stage remains blocked before battle: chain status is `blocked`,
  `final_core_status=core_role_gap`, final generic core counts include
  `removal=3` below the floor `6`, and the commander-specific strategy matrix
  returns `package_strategy_blocks_battle` with blockers
  `package_core_floor_not_repaired`,
  `profile_angels_demons_dragons_payoffs_below_target`, and
  `profile_spot_interaction_below_target`. The next gate is
  `repair_commander_profile_blockers_before_battle`, not battle or promotion.
- Follow-up value-safe repair chaining kept the same copied-DB boundary. The
  reports
  `global_commander_candidate_copy_materializer_20260705_kaalia_value_safe_stage1_repair_stage1.md`
  and
  `global_commander_candidate_copy_materializer_20260705_kaalia_value_safe_stage1_repair_stage2.md`
  add another `12` paired swaps on top of the stage 1 candidate. The second
  chained copy uses explicit `allow_chained_source=true`; the chain audit must
  treat that as accepted source lineage only when the source hash stays
  unchanged and promotion remains closed. The consolidated chain report
  `global_commander_candidate_package_chain_audit_20260705_kaalia_value_safe_stage1_repair_stage2.md`
  reaches `core_floor_repaired=true`, `final_core_status=core_review_ready`,
  `removal=8`, `lands=35`, and `ramp=16`, but the commander-specific matrix
  `global_commander_candidate_package_strategy_matrix_20260705_kaalia_value_safe_stage1_repair_stage2.md`
  still blocks battle on `profile_angels_demons_dragons_payoffs_below_target`
  and `profile_reanimation_plan_b_below_target`.
- Current learning from the repair loop: `package_core_floor_not_repaired` must
  be resolved through the exact failed core role, currently
  `core_removal_floor` mapped to the `spot_interaction` source lane; the
  candidate model must also support `reanimation_plan_b`. Global battle
  feedback keeps `Birgi, God of Storytelling // Harnfel, Horn of Bounty` out of
  automatic profile-repair cuts, and structural staples such as `Demonic
  Tutor`, `Vampiric Tutor`, `Enlightened Tutor`, `Smothering Tithe`, `Mana
  Vault`, `Arcane Signet`, and `Sol Ring` stay protected unless a same-lane or
  battle-backed gate explicitly clears them. After these protections, the
  final repair package in
  `global_commander_payoff_package_synthesizer_20260705_kaalia_value_safe_stage1_repair_stage2.md`
  is correctly blocked: it needs `7` repairs including `Necromancy`, has only
  `6` safe reviewed cuts, and the expanded cut lane
  `global_commander_cut_source_lane_expander_20260705_kaalia_value_safe_stage1_repair_stage2.md`
  reports `value_safe_cut_shortfall:required_7_ready_1`. The next gate is
  `backfill_value_safe_cuts_or_reduce_package_scope`; battle and promotion stay
  closed.
- Current package-scope reduction closed only the repair axis that had enough
  reviewed cut support. The report
  `global_commander_package_scope_reducer_20260705_kaalia_value_safe_stage1_repair_stage2.md`
  has status `commander_package_scope_reduced_ready_for_candidate_copy`,
  selects exactly `+Necromancy / -Cabal Ritual`, sets
  `reduced_scope_candidate_copy_allowed_now=true`, keeps
  `full_package_candidate_copy_allowed_now=false`, routes the next isolated
  copy gate to `materialize_reduced_scope_candidate_copy`, and reduces
  `reanimation_plan_b` remaining requirement from `1` to `0` while leaving the
  Angel/Demon/Dragon payoff shortfall open. The materializer report
  `global_commander_candidate_copy_materializer_20260705_kaalia_value_safe_stage1_repair_scope1.md`
  proves the source DB unchanged and keeps `allow_battle_gate_now=false`.
  The consolidated chain report
  `global_commander_candidate_package_chain_audit_20260705_kaalia_value_safe_stage1_repair_scope1.md`
  passes with `swap_count=21`, `core_floor_repaired=true`,
  `final_core_status=core_review_ready`, and final role counts including
  `lands=35`, `ramp=15`, `removal=8`, and `recursion=3`. The commander-specific
  package matrix
  `global_commander_candidate_package_strategy_matrix_20260705_kaalia_value_safe_stage1_repair_scope1.md`
  still blocks battle: `reanimation_plan_b` is now in range, but
  `angels_demons_dragons_payoffs` is only `16` against the `22-30` target.
  Therefore the next gate remains `repair_commander_profile_blockers_before_battle`,
  focused on payoff density, not battle or promotion.
- Current payoff-density follow-up is still blocked by cut evidence, not by ADD
  candidates. The repair plan
  `global_commander_profile_blocker_repair_plan_20260705_kaalia_value_safe_stage1_repair_scope1.md`
  has one action, `repair_commander_payoff_density_with_legal_source_lanes`, for
  shortfall `6`. The narrow profile candidate model routes to
  `expand_commander_payoff_source_lane_before_candidate_copy`; the expanded
  source lane finds `30` legal WBR Angel/Demon/Dragon candidates and covers the
  shortfall. The synthesized package selects `Dragon Mage`,
  `Bonehoard Dracosaur`, `Drakuseth, Maw of Flames`, `The Balrog of Moria`,
  `Wrathful Red Dragon`, and `Akroma, Angel of Wrath`, but has only `5`
  tentative cuts and remains blocked by
  `insufficient_reviewable_cuts_for_full_profile_package:required_6_ready_5`.
  The current cut-source expander over the scope1 copied DB finds
  `value_safe_cut_count=0`, `stage_only_cut_count=15`, and blocker
  `value_safe_cut_shortfall:required_6_ready_0`; rerunning the scope reducer
  correctly returns `commander_package_scope_reduction_blocks_candidate_copy`
  with `no_value_safe_reduced_scope_pair_ready`. The stage-only evidence plan
  `global_commander_stage_only_cut_evidence_plan_20260705_kaalia_value_safe_stage1_repair_scope1.md`
  names the lowest-burden evidence rows as `Professional Face-Breaker`,
  `Diabolic Intent`, and `Ornithopter of Paradise`, all under
  `contextual_staple_same_lane_usage_review`. This still does not reclassify a
  cut or open battle; the next gate is
  `collect_stage_only_cut_evidence_before_value_safe_reclassification`.
- Current contextual stage-cut evidence collection is read-only and still keeps
  materialization closed. The report
  `global_commander_contextual_stage_cut_evidence_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md`
  inspects `Professional Face-Breaker`, `Diabolic Intent`, and `Ornithopter of
  Paradise` in the current copied DB, confirms contextual deck roles and local
  format-staple context, and records `reclassification_ready_count=0` with
  `missing_usage_or_trace_count=3`. Therefore
  `contextual_stage_cut_evidence_collected_no_value_safe_reclassification` is
  the current status, and the next gate is
  `collect_usage_or_trace_evidence_for_contextual_stage_cuts`.
- Current contextual usage-trace scouting found no current-scope usage proof.
  The report
  `global_commander_contextual_usage_trace_scout_20260705_kaalia_value_safe_stage1_repair_scope1.md`
  scans existing local artifacts for `Professional Face-Breaker`,
  `Diabolic Intent`, and `Ornithopter of Paradise`; it records `163`
  occurrences, but `current_usage_trace_evidence_count=0` because all matches
  are planning references, rule-coherence/current-scope non-trace references,
  or historical/cross-deck traces. Therefore
  `contextual_usage_trace_scout_no_current_trace_evidence` keeps
  `value_safe_reclassification_allowed_now=false` and routes to
  `generate_or_import_current_scope_usage_trace_before_reclassification`.
- Current contextual usage-trace generation produced current target-deck
  evidence without opening battle gates. The report
  `global_commander_contextual_usage_trace_generator_20260705_kaalia_value_safe_stage1_repair_scope1.md`
  runs `8` structured replays from seeds `42-49` against the isolated scope1 DB
  for deck `619`, confirms provenance `deck_id:619`, and records target-player
  usage events for `Professional Face-Breaker`, `Diabolic Intent`, and
  `Ornithopter of Paradise`. It keeps `battle_gate_performed=false`,
  `candidate_copy_allowed_now=false`, and
  `value_safe_reclassification_allowed_now=false`.
- Current contextual usage-trace review blocks all three contextual cuts from
  automatic value-safe reclassification. The report
  `global_commander_contextual_usage_trace_reviewer_20260705_kaalia_value_safe_stage1_repair_scope1.md`
  returns `contextual_usage_trace_review_blocks_value_safe_reclassification`
  because target-deck usage was observed for all three cards. The next gate is
  `find_new_cut_source_lane_or_same_lane_replacement_proof_before_candidate_copy`,
  not candidate copy, battle, or promotion.
- Current same-lane replacement modeling finds no explicit replacement route
  for those usage-blocked contextual cuts. The report
  `global_commander_same_lane_replacement_model_20260705_kaalia_value_safe_stage1_repair_scope1.md`
  returns `same_lane_replacement_model_routes_to_new_cut_source_lane` with
  `usage_blocked_cut_count=3`, `same_lane_replacement_route_count=0`,
  `incidental_role_overlap_count=4`, and
  `remaining_stage_only_cut_source_count=12`. `Bonehoard Dracosaur` and
  `The Balrog of Moria` overlap incidentally with mana/card roles, but they
  were selected for the Angel/Demon/Dragon payoff axis, so they are not proof
  that `Professional Face-Breaker` or `Ornithopter of Paradise` can be cut.
  Therefore candidate copy, battle, promotion, and value-safe reclassification
  remain closed; the next gate is
  `collect_new_cut_source_lane_evidence_after_contextual_usage_block`.
- Current new cut-source-lane trace collection reused the existing eight
  current-scope replays before generating any new battle. The report
  `global_commander_new_cut_source_lane_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md`
  returns `new_cut_source_lane_trace_blocks_used_remaining_cuts` over the
  remaining `12` stage-only cuts: `9` were used by the target deck, `2` were
  seen only in decision trace, and `1` (`Dark Ritual`) was not seen. Used
  remaining cuts include `Sunforger`, `Jeska's Will`, `Smothering Tithe`,
  `Demonic Tutor`, `Enlightened Tutor`, `Arcane Signet`, `Mana Vault`,
  `Sol Ring`, and `Birgi, God of Storytelling // Harnfel, Horn of Bounty`.
  Therefore candidate copy, battle, promotion, and value-safe reclassification
  remain closed; the next gate is
  `force_access_or_expand_cut_source_lane_for_unresolved_remaining_cuts`.
- Current forced cut-access trace generation fixed the old Lorehold-only focus
  hook by applying force access to the current evaluation target player, then
  tested only the unresolved cuts from the prior collector. The report
  `global_commander_forced_cut_access_trace_generator_20260705_kaalia_value_safe_stage1_repair_scope1.md`
  forced opening-hand access for `Alicia Masters, Skilled Sculptor`,
  `Vampiric Tutor`, and `Dark Ritual` over seeds `50-52`. All three were
  present through force access and then used by the target deck, so the report
  status is `forced_cut_access_trace_blocks_used_unresolved_cuts` with
  `usage_blocked_count=3`, `manual_review_count=0`, and
  `force_failure_count=0`. This closes the current stage-only cut lane for
  value-safe reclassification. Candidate copy, battle, promotion, and
  value-safe reclassification remain closed; the next gate is
  `expand_cut_source_lane_after_forced_access_blocks_current_unresolved_cuts`.
- Current post-forced cut source-lane expansion consumed that forced-access
  report and returned
  `commander_cut_source_lane_still_blocks_full_package` with
  `value_safe_cut_count=0`, `forced_usage_blocked_count=3`, and
  `forced_cut_access_blocks_unresolved_cut_reclassification:3`. The reducer
  `global_commander_package_scope_reducer_20260705_kaalia_value_safe_stage1_repair_scope1_post_forced.md`
  also returns `commander_package_scope_reduction_blocks_candidate_copy` with
  `scoped_pair_count=0`, `dropped_add_count=6`, and candidate copy, battle, and
  promotion still closed. The next gate is
  `synthesize_new_value_safe_cut_source_or_smaller_package_after_forced_access_block`.
- Current post-forced recovery synthesis returns
  `post_forced_recovery_blocks_candidate_copy_needs_new_cut_source` with
  `selected_add_count=6`, `required_cut_count=6`, `value_safe_cut_count=0`,
  `stage_only_cut_count=15`, `forced_usage_blocked_count=3`, and
  `scoped_pair_count=0`. It names the only valid next gate as
  `mine_new_value_safe_cut_source_before_package_resynthesis`; the current
  package remains closed and no candidate copy, natural battle, promotion, or
  deck mutation is authorized.
- Current value-safe cut-source mining returns
  `value_safe_cut_source_hypotheses_ready_for_trace` with `hypothesis_count=8`,
  `blocked_hypothesis_count=80`, and next gate
  `collect_usage_trace_for_new_cut_source_hypotheses`. The mined hypotheses are
  `Biotransference`, `Maskwood Nexus`, `Sigarda's Aid`, `Necromancy`,
  `Necropotence`, `Trouble in Pairs`, `Puresteel Paladin`, and
  `Sram, Senior Edificer`. These are trace targets only; candidate copy, battle,
  promotion, and value-safe reclassification remain closed.
- Current hypothesis trace collection reuses the existing `8` replay seeds and
  returns `cut_source_hypothesis_trace_blocks_used_hypotheses` with
  `usage_blocked_hypothesis_count=6`, `seen_without_usage_count=2`, and
  `not_seen_count=0`. `Biotransference`, `Maskwood Nexus`, `Sigarda's Aid`,
  `Necromancy`, `Necropotence`, and `Sram, Senior Edificer` were used by the
  target deck; `Trouble in Pairs` and `Puresteel Paladin` were seen in decision
  traces without usage and still require negative review. The next gate is
  `mine_more_hypotheses_or_build_same_lane_proof`; candidate copy, battle,
  promotion, and value-safe reclassification remain closed.
- Current cut-hypothesis same-lane proof returns
  `cut_hypothesis_same_lane_proof_routes_to_more_mining` with
  `explicit_same_lane_route_count=0`, `incidental_role_overlap_count=9`, and
  `package_explicit_add_axes=["angels_demons_dragons_payoffs"]`. The payoff
  package does not explicitly replace draw, reanimation, equipment, or
  off-profile hypothesis lanes, so no mined hypothesis becomes value-safe. The
  next gate is `mine_more_hypotheses_or_external_cut_source_research`;
  candidate copy, battle, promotion, and value-safe reclassification remain
  closed.
- Current external cut-source research planning returns
  `external_cut_source_research_plan_ready_no_deck_action` with
  `external_source_count=6` and next gate
  `collect_external_commander_reference_corpus_for_cut_candidates`. The external
  source snapshot covers Wizards bracket/Game Changer policy plus EDHREC
  commander usage, filtered midrange, Kaalia strategy, and general Commander
  deckbuilding method. These are evidence lanes only: target usage and
  seen-without-usage blockers still prevent candidate copy, battle, promotion,
  and value-safe reclassification.
- Current external reference corpus collection returns
  `external_reference_corpus_collected_no_cut_permission` with
  `corpus_present_count=3`, `corpus_absent_count=5`, `usage_blocked_count=6`,
  and `seen_without_usage_count=2`. `Necromancy`, `Necropotence`, and
  `Trouble in Pairs` have checked Kaalia corpus presence; `Biotransference`,
  `Maskwood Nexus`, `Sigarda's Aid`, `Puresteel Paladin`, and
  `Sram, Senior Edificer` are absent from the checked Kaalia public corpus.
  Presence protects/routes review, and absence is not cut permission when the
  target deck used the card. The next gate is
  `map_external_corpus_to_cut_policy_before_rerun_miner`.
- Current external corpus cut-policy mapping returns
  `external_corpus_cut_policy_blocks_current_hypotheses` with
  `policy_row_count=8`, `excluded_from_rerun_miner_count=6`,
  `held_for_negative_review_count=2`, and `rerun_miner_allowed_card_count=0`.
  The next miner pass must consume these policy exclusions before it can claim
  fresh value-safe cut hypotheses. The next gate is
  `rerun_value_safe_cut_source_miner_with_external_policy_exclusions`.
- Current value-safe cut-source mining with external policy consumed all `8`
  policy exclusions and returned `value_safe_cut_source_mining_blocks_package_resynthesis`
  with `hypothesis_count=0`, `blocked_hypothesis_count=88`, and
  `external_policy_exclusion_count=8`. The current cut lane is exhausted; the
  next gate is `broaden_commander_package_axis_or_external_cut_research`.
- Current package-axis broadening plan returns
  `commander_package_axis_broadening_plan_ready_no_deck_action` with
  `selected_add_count=6`, `selected_cut_count=5`, `value_safe_cut_count=0`,
  and `lane_alignment_status=package_axis_mismatch_with_exhausted_cut_lanes`.
  The selected add package is `angels_demons_dragons_payoffs`, while exhausted
  cut roles are `haste_protection_silence`, `mana_acceleration`, and
  `tutors_access`. Secondary text on payoffs such as haste, treasure, draw, or
  protection is incidental and does not prove a same-lane replacement. The next
  gate is `resynthesize_package_with_same_lane_axis_requirements`.
- Current same-lane package resynthesis returns
  `same_lane_package_resynthesis_blocks_candidate_copy_needs_source_lanes` with
  `held_payoff_add_count=6`, `same_lane_axis_requirement_count=3`,
  `satisfied_same_lane_axis_count=0`, `value_safe_cut_count=0`, and
  `ready_pair_count=0`. The required add axes are `commander_attack_window`,
  `mana_acceleration_replacement`, and `tutors_access_replacement`. The next
  gate is `expand_same_lane_add_source_lanes_for_target_cut_roles`.
- Current same-lane add source-lane expansion returns
  `same_lane_add_source_lanes_expanded_no_deck_action` with
  `requirement_count=3`, `ready_axis_count=3`, `missing_axis_count=0`, and
  ready local source candidates for `commander_attack_window`,
  `mana_acceleration_replacement`, and `tutors_access_replacement`. Top signals
  include attack-window cards such as `Boros Charm`, `Swiftfoot Boots`, and
  `Flawless Maneuver`; mana replacements such as `Fellwar Stone`, signets, and
  talismans; and tutor/access replacements such as `Gamble`, `Wishclaw
  Talisman`, `Entomb`, and `Imperial Seal`. These are review-only source lanes,
  not paired swaps. The next gate is
  `resynthesize_same_lane_package_from_source_lanes_before_cut_pairing`.
- Current same-lane package source synthesis returns
  `same_lane_source_package_synthesized_no_cut_pairs` with
  `package_size_limit=8`, `selected_add_count=8`, `axes_covered_count=3`,
  `unpaired_add_count=8`, and `ready_pair_count=0`. It selects review-only adds
  from the same-lane lanes: `Boros Charm`, `Fellwar Stone`, `Gamble`,
  `Swiftfoot Boots`, `Wishclaw Talisman`, `Entomb`, `Imperial Seal`, and
  `Diabolic Tutor`. Candidate copy, battle, promotion, and value-safe
  reclassification remain closed. The next gate is
  `collect_value_safe_same_lane_cut_pairs_for_resynthesized_package`.
- Current same-lane cut-pair collection returns
  `same_lane_cut_pair_collection_blocks_candidate_copy` with
  `selected_add_count=8`, `required_pair_count=8`, `ready_pair_count=0`,
  `unpaired_add_count=8`, `stage_only_cut_candidate_count=28`, and
  `blocked_cut_candidate_count=19`. Every selected add remains unpaired because
  the available same-lane cuts are protected, structural staples, expected
  package anchors, prior failed-gate cuts, lands, or Kaalia payoff slots. This
  blocks candidate copy, battle, promotion, and value-safe reclassification.
  The next gate is
  `collect_more_same_lane_cut_evidence_or_broaden_cut_source_lanes`.
- Current same-lane cut evidence planning returns
  `same_lane_cut_evidence_plan_ready_no_deck_action` with
  `stage_only_cut_evidence_count=28`, `hard_blocked_cut_count=19`, and
  `ready_pair_count=0`. The largest evidence lanes are protected same-lane
  usage/equal-gate proof, expected-package anchor replacement, structural
  staple proof, cross-role risk review, contextual staple review, multi-role
  protected-lane proof, and one prior failed-gate reopen proof. Candidate copy,
  battle, promotion, and value-safe reclassification remain closed. The next
  gate is `collect_trace_or_external_evidence_for_same_lane_stage_only_cuts`.
- Current same-lane stage-cut trace collection returns
  `same_lane_stage_cut_trace_collection_blocks_used_cuts` after reusing `8`
  existing current-scope seed reports. It classifies `19` stage-cut rows as
  used by the target deck, `4` as seen without usage, `1` as external-reference
  only, and `4` as still needing trace or external research. Candidate copy,
  battle, promotion, and value-safe reclassification remain closed. The next
  gate is
  `build_same_lane_replacement_or_find_new_cut_source_for_used_stage_cuts`.
- Current same-lane used-cut recovery routing returns
  `same_lane_used_cut_recovery_routes_to_new_cut_source` with `used_cut_count=19`,
  `strict_recovery_count=10`, `same_lane_replacement_proof_count=9`, and
  `no_same_lane_route_count=0`. The current package has possible same-lane add
  routes for every used cut, but structural staples, expected anchors, and prior
  failed-gate cuts should prefer a fresh cut-source lane unless explicit
  replacement proof exists. Candidate copy, battle, promotion, and value-safe
  reclassification remain closed. The next gate is
  `mine_or_research_new_same_lane_cut_source_before_candidate_copy`.
- Current same-lane new cut-source mining returns
  `same_lane_new_cut_source_mining_exhausted_current_deck` with
  `target_role_count=3`, `scanned_same_lane_source_count=47`,
  `exhausted_source_card_count=42`, `fresh_same_lane_cut_source_count=0`,
  and `blocked_recycled_cut_source_count=47`. Candidate copy, battle,
  promotion, and value-safe reclassification remain closed. The next gate is
  `broaden_same_lane_cut_research_or_package_axis_before_candidate_copy`.
- Current same-lane cut-axis broadening planning returns
  `same_lane_cut_axis_broadening_plan_ready_no_deck_action` with
  `target_role_count=3`, `fresh_same_lane_cut_source_count=0`,
  `blocked_recycled_cut_source_count=47`, `ready_pair_count=0`, and
  `unpaired_add_count=8`. All three target roles
  (`haste_protection_silence`, `mana_acceleration`, `tutors_access`) are
  current-deck exhausted and route to
  `collect_external_nonpayoff_same_lane_cut_corpus_for_exhausted_roles`.
- Current external nonpayoff same-lane corpus collection returns
  `external_nonpayoff_same_lane_corpus_collected_no_cut_permission` with
  `external_source_count=6`, `role_corpus_count=3`, `exhausted_role_count=3`,
  `fresh_same_lane_cut_source_count=0`, `blocked_recycled_cut_source_count=47`,
  `ready_pair_count=0`, and `unpaired_add_count=8`. External corpus is now
  recorded as source-policy evidence only; it does not create cut permission.
  The next gate is
  `map_external_nonpayoff_same_lane_corpus_to_cut_policy_before_source_discovery`.
- Current external nonpayoff same-lane cut-policy mapping returns
  `external_nonpayoff_same_lane_policy_ready_no_cut_permission` with
  `role_policy_count=3`, `source_discovery_required_role_count=3`,
  `rerun_miner_allowed_role_count=0`, and `card_level_cut_permission_count=0`.
  The next gate is
  `discover_external_nonpayoff_same_lane_source_candidates_before_miner`.
- Current external nonpayoff same-lane source-candidate discovery returns
  `external_nonpayoff_same_lane_source_candidates_discovered_no_cut_permission`
  with `source_candidate_count=16`, `role_count=3`,
  `current_deck_present_count=6`, `outside_current_deck_count=10`,
  `local_identity_found_count=15`, `selected_as_package_add_count=4`, and
  `card_level_cut_permission_count=0`. Named candidates are source-lane
  evidence only; candidate copy, battle, promotion, and value-safe
  reclassification remain closed. The next gate is
  `review_external_nonpayoff_same_lane_source_candidates_locally_before_miner`.
- Current external nonpayoff same-lane source-candidate review returns
  `external_nonpayoff_same_lane_source_candidates_reviewed_miner_seed_ready_no_deck_action`
  with `reviewed_candidate_count=16`, `miner_source_seed_allowed_count=5`,
  `current_deck_trace_required_count=6`, `held_package_pair_required_count=4`,
  `identity_resolution_required_count=1`, `role_mismatch_blocked_count=0`,
  `card_level_cut_permission_count=0`, and `candidate_copy_allowed_count=0`.
  The 5 reviewed candidates may seed miner research only; they are not
  card-level cut permission. The next gate is
  `rerun_same_lane_cut_source_miner_with_reviewed_external_nonpayoff_candidates`.
- Current reviewed external nonpayoff seeded cut-source mining returns
  `reviewed_external_seeded_cut_source_hypotheses_ready_for_trace` with
  `reviewed_seed_count=5`, `seeded_role_count=2`, `target_role_count=3`,
  `unseeded_target_role_count=1`, `scanned_seeded_same_lane_source_count=34`,
  `fresh_seeded_same_lane_cut_source_count=10`,
  `blocked_recycled_seeded_cut_source_count=21`,
  `blocked_new_seeded_cut_source_count=3`,
  `card_level_cut_permission_count=0`, and `candidate_copy_allowed_count=0`.
  Fresh hypotheses are trace work only, not cut permission. The next gate is
  `collect_trace_for_reviewed_external_seeded_cut_source_hypotheses`.
- Current reviewed external seeded cut-trace collection returns
  `reviewed_external_seeded_cut_trace_needs_force_access` with
  `hypothesis_count=10`, `usage_blocked_hypothesis_count=0`,
  `seen_without_usage_count=0`, `not_seen_count=10`, `seed_report_count=8`,
  `card_level_cut_permission_count=0`, and `candidate_copy_allowed_count=0`.
  The existing trace window did not expose the hypotheses, so this is not
  negative proof. The next gate is
  `force_access_or_expand_replay_window_for_seeded_hypotheses`.
- Current reviewed external seeded forced-access generation returns
  `reviewed_external_seeded_forced_access_blocks_absent_hypotheses` with
  `source_hypothesis_count=10`, `focus_hypothesis_count=10`,
  `selected_db_absent_count=10`, `usage_blocked_count=0`,
  `card_level_cut_permission_count=0`, and `candidate_copy_allowed_count=0`.
  Forced access applied against the current `Kaalia of the Vast` evaluation
  target, but all 10 seeded hypotheses were absent from the selected scope1
  candidate DB. This is a source-lineage blocker, not negative cut proof.
  Candidate copy, battle, promotion, and value-safe reclassification remain
  closed; the next gate is
  `rerun_seeded_cut_source_miner_against_current_evaluation_db`.
- Current reviewed external nonpayoff seeded cut-source mining rerun against
  the current scope1 DB returns
  `reviewed_external_seeded_cut_source_mining_exhausted_current_deck_no_cut_permission`
  with `reviewed_seed_count=5`, `seeded_role_count=2`,
  `target_role_count=3`, `unseeded_target_role_count=1`,
  `scanned_seeded_same_lane_source_count=31`,
  `fresh_seeded_same_lane_cut_source_count=0`,
  `blocked_recycled_seeded_cut_source_count=31`,
  `blocked_new_seeded_cut_source_count=0`,
  `card_level_cut_permission_count=0`, and `candidate_copy_allowed_count=0`.
  The current scope1 seeded lane is exhausted; the next gate is
  `expand_external_nonpayoff_seed_research_or_collect_current_deck_negative_review_before_candidate_copy`.
- Current external nonpayoff seed-exhaustion recovery routing returns
  `external_nonpayoff_seed_exhaustion_recovery_routes_to_current_deck_negative_review`
  with `target_role_count=3`, `seeded_exhausted_role_count=2`,
  `unseeded_role_count=1`, `current_deck_negative_review_candidate_count=6`,
  `held_package_pair_required_count=4`, `identity_resolution_required_count=1`,
  `prior_fresh_seeded_same_lane_cut_source_count=0`,
  `prior_blocked_recycled_seeded_cut_source_count=31`, and
  `force_access_selected_db_absent_count=10`. The six current-deck candidates
  are `Lightning Greaves`, `Arcane Signet`, `Demonic Tutor`,
  `Enlightened Tutor`, `Vampiric Tutor`, and `Diabolic Intent`; they require
  target-deck negative review before any cut consideration. Candidate copy,
  battle, promotion, and value-safe reclassification remain closed; the next
  gate is
  `collect_current_deck_negative_review_for_external_nonpayoff_candidates`.
- Current external nonpayoff current-deck negative-review collection returns
  `external_current_deck_negative_review_blocks_used_candidates` with
  `current_deck_candidate_count=6`, `usage_blocked_candidate_count=5`,
  `seen_without_usage_count=1`, `not_seen_count=0`, `seed_report_count=8`,
  `card_level_cut_permission_count=0`, `negative_review_cleared_count=0`, and
  `candidate_copy_allowed_count=0`. The target deck used `Lightning Greaves`,
  `Arcane Signet`, `Demonic Tutor`, `Diabolic Intent`, and
  `Enlightened Tutor`; `Vampiric Tutor` was seen in decision trace without
  usage and still needs manual negative review. Therefore this lane does not
  create a safe cut; the next gate is
  `find_new_external_source_or_explicit_same_lane_replacement_proof`.
- Current external nonpayoff new-source/replacement finding returns
  `new_external_source_candidates_ready_for_local_review` with
  `current_deck_negative_review_candidate_count=6`,
  `current_deck_usage_blocked_count=5`,
  `manual_negative_review_required_count=1`,
  `explicit_same_lane_replacement_proof_count=0`,
  `new_external_candidate_count=22`, and
  `new_external_ready_for_review_count=19`. Ready rows cover all target roles:
  `haste_protection_silence=8`, `mana_acceleration=7`, and
  `tutors_access=4`. This is source-review evidence only; it does not create
  cut permission or candidate-copy permission. The next gate is
  `review_new_external_nonpayoff_source_candidates_locally_before_seeded_miner`.
- Current external nonpayoff new-source candidate review returns
  `new_external_source_candidates_reviewed_seed_ready_no_deck_action` with
  `finder_ready_candidate_count=19`, `reviewed_candidate_count=19`,
  `miner_source_seed_allowed_count=19`, and seed coverage
  `haste_protection_silence=8`, `mana_acceleration=7`, and
  `tutors_access=4`. Seed scopes are split into
  `equipment_haste_protection_seed=1`,
  `generic_tutor_seed_bracket_context_required=1`,
  `mana_rock_seed_curve_pressure_review=7`,
  `package_access_limited_seed=3`, `protection_spell_or_haste_seed=6`, and
  `removal_redirection_seed=1`. This only authorizes a seeded miner rerun; it
  keeps cut permission, candidate copy, battle, promotion, and value-safe
  reclassification closed.
- The seeded miner rerun with those new reviewed external seeds returns
  `reviewed_external_seeded_cut_source_mining_exhausted_current_deck_no_cut_permission`
  with `reviewed_seed_count=19`, `seeded_role_count=3`,
  `unseeded_target_role_count=0`, `scanned_seeded_same_lane_source_count=47`,
  `fresh_seeded_same_lane_cut_source_count=0`,
  `blocked_recycled_seeded_cut_source_count=47`, and
  `blocked_new_seeded_cut_source_count=0`. Therefore the new seeds improved
  coverage but still did not find a fresh current-deck cut source; candidate
  copy, battle, promotion, and value-safe reclassification remain closed. The
  next gate is
  `expand_external_nonpayoff_seed_research_or_collect_current_deck_negative_review_before_candidate_copy`.
- The seed-exhaustion router rerun against the new reviewed-source miner returns
  `external_nonpayoff_seed_exhaustion_recovery_routes_to_source_expansion`
  with `target_role_count=3`, `seeded_exhausted_role_count=3`,
  `unseeded_role_count=0`, `current_deck_negative_review_candidate_count=0`,
  `identity_resolution_required_count=0`,
  `prior_fresh_seeded_same_lane_cut_source_count=0`, and
  `prior_blocked_recycled_seeded_cut_source_count=47`. The next gate is
  `expand_external_nonpayoff_source_candidate_pool`.
- Current external nonpayoff source-candidate pool expansion returns
  `external_nonpayoff_source_candidate_pool_expanded_ready_for_local_review`
  with `expanded_candidate_count=26`,
  `expanded_ready_for_review_count=22`, and role coverage
  `haste_protection_silence=8`, `mana_acceleration=8`, and
  `tutors_access=6`. It blocks `Mana Vault` because it is already in the
  current evaluation deck and blocks `Mana Crypt`, `Jeweled Lotus`, and
  `Dockside Extortionist` because current Commander legality marks them banned.
  The ready rows are source-review candidates only; candidate copy, battle,
  promotion, and value-safe reclassification remain closed. The next gate is
  `review_expanded_external_nonpayoff_source_candidates_locally_before_seeded_miner`.
- Current expanded external nonpayoff source-candidate review returns
  `expanded_external_source_candidates_reviewed_seed_ready_no_deck_action` with
  `expander_ready_candidate_count=22`, `reviewed_candidate_count=26`,
  `miner_source_seed_allowed_count=22`, `blocked_current_deck_count=1`,
  `blocked_commander_banned_count=3`, and role coverage
  `haste_protection_silence=8`, `mana_acceleration=8`, and
  `tutors_access=6`. `Mana Vault` remains blocked as a current-deck card;
  `Mana Crypt`, `Jeweled Lotus`, and `Dockside Extortionist` remain blocked by
  Commander legality. The next gate is
  `rerun_seeded_cut_source_miner_with_reviewed_expanded_external_nonpayoff_sources`.
- The seeded miner rerun with reviewed expanded external seeds returns
  `reviewed_external_seeded_cut_source_mining_exhausted_current_deck_no_cut_permission`
  with `reviewed_seed_count=22`, `seeded_role_count=3`,
  `unseeded_target_role_count=0`, `scanned_seeded_same_lane_source_count=47`,
  `fresh_seeded_same_lane_cut_source_count=0`, and
  `blocked_recycled_seeded_cut_source_count=47`. No candidate copy, battle,
  promotion, or value-safe reclassification opens from this rerun.
- The seed-exhaustion router rerun after the expanded review returns
  `external_nonpayoff_seed_exhaustion_recovery_routes_to_current_deck_negative_review`
  with `current_deck_negative_review_candidate_count=1`; that candidate is
  `Mana Vault`. The current-deck negative-review collector then returns
  `external_current_deck_negative_review_blocks_used_candidates` with
  `current_deck_candidate_count=1`, `usage_blocked_candidate_count=1`,
  `seen_without_usage_count=0`, and `not_seen_count=0`. Mana Vault was used by
  the target in current traces (`usage_event_count=9`,
  `exposure_event_count=17`, `decision_trace_count=4`), so it is not a safe
  cut and cannot justify candidate copy. The next gate is
  `find_new_external_source_or_explicit_same_lane_replacement_proof`.
- Current follow-up external nonpayoff source expansion returns
  `external_nonpayoff_followup_source_candidate_pool_expanded_ready_for_local_review`
  after treating four prior finder/reviewer/expander reports as cumulative
  recycled history. It has `cumulative_previous_candidate_name_count=55`,
  `followup_candidate_count=34`, `followup_ready_for_review_count=34`, and role
  coverage `haste_protection_silence=12`, `mana_acceleration=10`, and
  `tutors_access=12`. This is source-review evidence only; candidate copy,
  battle, promotion, and value-safe reclassification remain closed.
- Current follow-up expanded source-candidate review returns
  `expanded_external_source_candidates_reviewed_seed_ready_no_deck_action` with
  `expander_ready_candidate_count=34`, `reviewed_candidate_count=34`,
  `miner_source_seed_allowed_count=34`, `blocked_current_deck_count=0`,
  `blocked_commander_banned_count=0`, `blocked_recycled_prior_seed_count=0`,
  and `blocked_role_mismatch_count=0`. The next gate is
  `rerun_seeded_cut_source_miner_with_reviewed_expanded_external_nonpayoff_sources`.
- The seeded miner rerun with follow-up reviewed seeds returns
  `reviewed_external_seeded_cut_source_mining_exhausted_current_deck_no_cut_permission`
  with `reviewed_seed_count=34`, `seeded_role_count=3`,
  `unseeded_target_role_count=0`, `scanned_seeded_same_lane_source_count=47`,
  `fresh_seeded_same_lane_cut_source_count=0`, and
  `blocked_recycled_seeded_cut_source_count=47`. The follow-up router returns
  `external_nonpayoff_seed_exhaustion_recovery_routes_to_source_expansion`
  with `current_deck_negative_review_candidate_count=0`; no candidate copy,
  battle, promotion, or value-safe reclassification opens, and the next gate is
  `expand_external_nonpayoff_source_candidate_pool`.
- The current global learning-priority audit consumes that follow-up
  seed-exhaustion router. Even when the nonland add/cut pool and commander
  source lane look ready, deck `619` is now routed to
  `expand_external_nonpayoff_source_candidate_pool_before_candidate_copy`
  because `prior_fresh_seeded_same_lane_cut_source_count=0` and
  `prior_blocked_recycled_seeded_cut_source_count=47`. This is a global
  candidate-copy guardrail, not a Kaalia-only exception.
- The source-candidate pool expander now accepts cumulative `--previous-report`
  history. Rerunning it against the follow-up seed-exhaustion router and seven
  previous source/reviewer reports returns
  `external_nonpayoff_source_candidate_pool_expansion_found_no_ready_candidates`
  with `cumulative_previous_candidate_name_count=84`,
  `expanded_candidate_count=26`, `expanded_ready_for_review_count=0`, and
  `status_counts` split as `22` recycled, `1` already in the current deck, and
  `3` banned. The next gate is
  `broaden_external_nonpayoff_source_research_live`.
- Live source research then broadens beyond the exhausted EDHREC/optimized pool
  and recognizes silence text such as `can't cast spells` as part of the
  `haste_protection_silence` lane. It finds `24` live candidates, of which `7`
  pass local review-seed checks: `Unbreakable Formation`, `Orim's Chant`,
  `Sword of the Animist`, `Simian Spirit Guide`, `Dihada, Binder of Wills`,
  `Fable of the Mirror-Breaker // Reflection of Kiki-Jiki`, and `Collector's
  Vault`. Candidate copy, battle, promotion, and value-safe reclassification
  remain closed.
- The live reviewed-seed miner still finds no fresh same-lane current-deck cut
  source: `reviewed_seed_count=7`,
  `fresh_seeded_same_lane_cut_source_count=0`,
  `blocked_recycled_seeded_cut_source_count=31`, and `tutors_access` remains
  unseeded. The follow-up router therefore routes to current-deck negative
  review for `Grand Abolisher`, `Silence`, and `Arena of Glory`.
- Current-deck negative review blocks all three live candidates:
  `Silence` was used by the target, while `Grand Abolisher` and `Arena of
  Glory` were seen without usage and need manual negative trace review before
  any cut consideration. `negative_review_cleared_count=0`, so the next gate is
  `find_new_external_source_or_explicit_same_lane_replacement_proof`.
- Manual negative trace review blocks those three live candidates without
  creating cut permission: `Silence` remains blocked because target usage was
  observed, `Grand Abolisher` is blocked as a static silence effect without
  activation proof, and `Arena of Glory` is blocked as a land-lane/mana-base
  card where land play is not generic nonuse. `manual_negative_review_cleared_count=0`,
  `candidate_copy_allowed_count=0`, and the next gate remains
  `find_new_external_source_or_explicit_same_lane_replacement_proof`.
- Follow-up live source research after manual trace review carries `14`
  previous reports and `95` cumulative prior candidate names, then finds `13`
  follow-up candidates with `11` locally review-ready seeds across protection,
  mana, and tutor/access lanes. The local reviewer confirms all `11` as miner
  seeds and blocks `2` recycled cards, but the seeded miner still finds
  `fresh_seeded_same_lane_cut_source_count=0` and
  `blocked_recycled_seeded_cut_source_count=47`. The recovery router therefore
  routes all three seeded roles back to broader source expansion with
  `candidate_copy_allowed_now=false`, `battle_gate_allowed_now=false`, and
  `promotion_allowed=false`.
- The global learning queue now treats that router as
  `source_expansion_cycle_requires_global_learning_pivot`, not ordinary source
  expansion. Its top next action is
  `pivot_to_cross_commander_role_axis_learning_before_more_same_deck_source_expansion`.
  The cross-commander pivot groups `10` role axes, excludes `607` benchmark
  evidence from action counts, and selects `engine` as the top global axis
  (`16` actionable decks, `6` commanders, `source_cycle_axis_count=4`). The
  next gate is
  `build_cross_commander_role_axis_policy_before_more_same_deck_source_expansion`;
  candidate copy, battle, and promotion remain closed.
- The role-axis policy builder now converts the engine axis into explicit
  capacity/ceiling policy before any new same-deck source expansion. It keeps
  candidate copy, battle, mutation, and promotion closed and routes the next
  gate to
  `apply_engine_axis_policy_to_nonland_cut_model_before_more_same_deck_source_expansion`.
- The engine-axis nonland cut policy model applies that policy to the current
  nonland cut model. It evaluates `12` old cuts for source-cycle deck `619`,
  keeps `6` engine cuts protected by Kaalia commander-plan signals, leaves `4`
  non-engine tutor cuts outside this axis, and exposes only `2` review-only
  engine cut-pressure rows. Candidate copy remains closed; the next gate is
  `collect_card_level_usage_and_same_lane_proof_for_engine_policy_cut_pressure`.
- The engine cut usage/same-lane scout keeps all `6` candidate pairs blocked:
  `Biotransference` has current-scope usage evidence, `Archaeomancer's Map`
  lacks current-scope usage/negative trace, and no pair has an explicit
  same-lane replacement route (`explicit_same_lane_route_count=0`,
  `pair_ready_count=0`). Candidate copy, battle, and promotion remain closed;
  the next gate is
  `generate_current_scope_trace_or_find_explicit_same_lane_engine_replacement_before_candidate_copy`.
- The engine cut follow-up router converts those blockers into two separate
  gates: `Archaeomancer's Map` needs a current-scope usage or negative trace
  plan, while `Biotransference` needs a different engine cut or explicit
  same-lane replacement proof because target usage was observed. All `6` pairs
  still lack explicit same-lane routes (`no_explicit_same_lane_pair_count=6`),
  `candidate_copy_allowed_now=false`, and the next gate is
  `run_trace_plan_and_replacement_search_before_candidate_copy`.
- The engine cut trace/replacement gate ran `3` natural current-scope replays
  for `Archaeomancer's Map`; it produced no usage event, but did capture a
  decision trace, so the card routes to manual negative trace review rather
  than cut permission. Local staple/oracle mining for replacing the used
  `Biotransference` found `12` engine candidates, including `2` stronger
  artifact/treasure-engine seeds (`Storm-Kiln Artist` and `Pitiless Plunderer`),
  but those are review seeds only, not explicit same-lane proof. Candidate
  copy, battle gate, and promotion remain closed; the next gate is
  `review_engine_cut_trace_results_before_candidate_copy`.
- The engine cut trace/replacement reviewer keeps candidate copy closed:
  `Archaeomancer's Map` was an equal-score tutor candidate against the chosen
  `The One Ring` line (`score_gap_vs_chosen=0.0`), so non-cast/non-use does
  not clear a negative cut. The two stronger local replacement seeds
  (`Storm-Kiln Artist` and `Pitiless Plunderer`) are artifact/treasure-adjacent
  engines, not exact Biotransference-style artifact-spell or type-conversion
  engines (`explicit_same_lane_replacement_proof_count=0`). The next gate is
  `find_exact_artifact_spell_engine_replacement_or_new_engine_cut_before_candidate_copy`.

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
