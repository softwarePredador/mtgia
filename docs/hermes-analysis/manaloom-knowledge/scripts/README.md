# Hermes Battle Scripts

## Active Engine

`battle_analyst_v9.py` is the active battle engine for ManaLoom/Hermes.

Operational scripts should use:

```bash
export MANALOOM_BATTLE_SCRIPT="/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py"
```

Local fallbacks in optimizer, replay, sync and audit scripts now point to v9.
When `MANALOOM_BATTLE_SCRIPT` / `BATTLE_SCRIPTS_DIR` are absent, the local
helpers under `server/bin/` resolve the current repo root dynamically instead of
assuming `/opt/data/workspace/mtgia`.

## Legacy Engines

Legacy engines (`battle_analyst.py`, `battle_analyst_v6.py`,
`battle_analyst_v7.py` and `battle_analyst_v8.py`) were removed from the
operational scripts directory. Old reports may mention them for historical
context only; no cron, optimizer, audit script or local validation should import
or execute them.

One-shot patch/build utilities that targeted v8 were also removed from
`server/bin/legacy/hermes_battle_patchers/`. Future battle changes must be made
directly in `battle_analyst_v9.py` or extracted support modules with focused
tests.

One-shot card rule patchers such as `update_thassa_oracle.py`,
`update_ad_nauseam.py`, `update_cyclonic_rift.py`, `seed_cyclonic_rift.py` and
similar historical helpers were removed from the operational scripts directory.
New card-specific battle behavior must be represented as reviewed data in
`reviewed_battle_card_rules.json`, synced through `sync_battle_card_rules*.py`,
and covered by a focused regression test.

## Validation

Run the operational surface alignment audit before claiming scripts/docs are
aligned with the current XMage and Commander deckbuilding contracts:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/operational_surface_alignment_audit.py \
  --out-prefix docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260629_current
```

Run the legacy contamination compatibility audit before merging broad branch
work into `master`:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/legacy_contamination_audit.py \
  --out-prefix docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_current
```

Run the v9 regression harness explicitly:

```bash
BATTLE_ANALYST_PATH=docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py \
python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py
```

The default harness also resolves to v9.

## Commander Deckbuilding Gates

After `global_commander_stage_only_cut_evidence_plan.py` names contextual
stage-only cuts, run `global_commander_contextual_stage_cut_evidence_collector.py`
before any value-safe reclassification. The collector is read-only: it records
current deck context, local format-staple context, and missing usage/same-lane
or replay proof. It must keep candidate copy, battle, and promotion closed.

Then run `global_commander_contextual_usage_trace_scout.py` to search existing
local artifacts for current-scope replay/trace evidence. Historical planning,
rule-coherence, Lorehold, or cross-deck occurrences are non-proof references;
they must not unlock value-safe cuts without current-scope trace review.

When existing artifacts have no current-scope trace, run
`global_commander_contextual_usage_trace_generator.py` against the isolated
candidate DB. Follow it with
`global_commander_contextual_usage_trace_reviewer.py`; observed use by the
target deck blocks automatic value-safe reclassification until a same-lane
replacement proof exists.

After the reviewer blocks contextual cuts, run
`global_commander_same_lane_replacement_model.py`. It cross-checks usage-blocked
cuts against the synthesized add package and the remaining stage-only cut pool.
Incidental role overlap from a payoff card is not same-lane proof; if no
explicit route exists, candidate copy stays closed and the next gate is a new
cut-source-lane evidence pass.

Then run `global_commander_new_cut_source_lane_trace_collector.py` before
starting any new replay. It reuses existing current-scope replay artifacts for
the remaining stage-only cut pool, counts only target-deck traces, and keeps
value-safe reclassification closed for cards that were used, merely seen without
usage, or not seen in that replay window.

If that collector leaves cards unresolved, run
`global_commander_forced_cut_access_trace_generator.py` with forced access
against the current evaluation target. The battle runtime must apply
`MANALOOM_FORCE_FOCUS_ACCESS_MODE` to the evaluation target, not only to
Lorehold. Forced access is diagnostic: card use still blocks value-safe
reclassification, and no candidate copy, battle gate, or promotion opens from
forced-access traces.

After forced access blocks unresolved cuts, rerun
`global_commander_cut_source_lane_expander.py` with
`--forced-cut-access-report` and then run
`global_commander_package_scope_reducer.py` against that post-forced cut report.
If `value_safe_cut_count=0` and `scoped_pair_count=0`, the next valid route is a
new value-safe cut source or a smaller package with fresh cut proof, not
candidate copy or battle.

Then run `global_commander_post_forced_recovery_synthesizer.py`. It consolidates
the post-forced cut report, package reducer, selected adds, and stage-only cut
reasons into the next evidence lane. When it returns
`post_forced_recovery_blocks_candidate_copy_needs_new_cut_source`, the next work
is `mine_new_value_safe_cut_source_before_package_resynthesis`; do not run a
candidate copy, natural battle, promotion, or deck mutation from the closed
package.

Use `global_commander_value_safe_cut_source_miner.py` for that next gate. It may
surface fresh cut-source hypotheses from the current deck, but those rows are
trace targets only. Candidate copy and value-safe reclassification stay closed
until the follow-up trace proves a named hypothesis is unused/safe or has
same-lane/equal-gate proof.

Then run `global_commander_cut_source_hypothesis_trace_collector.py` before any
new replay. It reuses existing current-scope replay artifacts for mined
hypotheses. If it returns `cut_source_hypothesis_trace_blocks_used_hypotheses`,
the used hypotheses are not value-safe cuts; rows merely seen in decision trace
need manual negative review or force-access before reclassification.

After that blocker, run `global_commander_cut_hypothesis_same_lane_proof.py`.
It compares mined hypotheses against the current package's explicit add axes,
not incidental profile-role overlap. When no explicit same-lane route exists,
candidate copy, battle, promotion, and value-safe reclassification stay closed
and the next work is more cut-source mining or external cut research.

When same-lane proof routes to external research, run
`global_commander_external_cut_source_research_plan.py`. It records the current
official Commander policy and public commander/source lanes as evidence only,
then routes to external commander reference corpus collection. Popularity,
articles, and bracket context must not override target-deck usage traces or open
candidate copy by themselves.

Then run `global_commander_external_reference_corpus_collector.py`. It maps
external presence, absence, bracket context, and strategy signals back to each
named cut hypothesis. External absence is not proof that a used card is safe to
cut; external presence protects or routes review, and the next step is mapping
the corpus into internal cut policy before rerunning the miner.

Use `global_commander_external_corpus_cut_policy_mapper.py` for that mapping.
It emits explicit exclusions and negative-review holds for the next miner pass.
The miner must consume those exclusions before re-emitting any of the same
cards as fresh value-safe hypotheses.

Rerun `global_commander_value_safe_cut_source_miner.py` with
`--external-cut-policy-report` after the mapper. If the rerun returns no fresh
hypotheses, the current cut lane is exhausted and the next route is to broaden
the package axis or external cut research, not candidate copy or battle.

Use `global_commander_package_axis_broadening_plan.py` for that route decision.
It compares the selected add axes against target cut roles, treats incidental
secondary text on payoff cards as non-proof, and routes to
`resynthesize_package_with_same_lane_axis_requirements` or external nonpayoff
cut-lane corpus research. Candidate copy, battle, promotion, and value-safe
reclassification remain closed.

Then run `global_commander_same_lane_package_resynthesizer.py`. It converts each
exhausted cut role into a required same-lane add axis, holds payoff-only adds
until payoff-lane cuts exist, and routes to
`expand_same_lane_add_source_lanes_for_target_cut_roles`. This is still a
requirements gate only; no deck copy, battle, promotion, or value-safe
reclassification opens.

Then run `global_commander_same_lane_add_source_lane_expander.py`. It scans the
current evaluation DB for legal, commander-color-compatible add candidates for
each required same-lane axis, excluding existing-deck rows and blocked
color/legality matches. If all lanes have review-only source candidates, route
to `resynthesize_same_lane_package_from_source_lanes_before_cut_pairing`; this
still does not pair cuts, copy a deck, run battle, or promote anything.

Then run `global_commander_same_lane_package_source_synthesizer.py`. It selects a
bounded, review-only add package from the source lanes and keeps every add
unpaired until a later cut-pairing gate proves value-safe same-lane cuts. The
next route is `collect_value_safe_same_lane_cut_pairs_for_resynthesized_package`,
not candidate copy or battle.

Then run `global_commander_same_lane_cut_pair_collector.py`. It pairs selected
adds only against cuts in the exact `replaces_cut_role`; protected commander
lanes, structural staples, expected package anchors, prior failed-gate cuts,
lands, and payoff slots stay stage-only or blocked. If no review-only
value-safe pairs exist, candidate copy, battle, promotion, and value-safe
reclassification remain closed and the next route is
`collect_more_same_lane_cut_evidence_or_broaden_cut_source_lanes`.

Then run `global_commander_same_lane_cut_evidence_plan.py`. It converts
stage-only same-lane cut blockers into required evidence lanes: protected-lane
trace/equal-gate proof, structural-staple proof, expected-package anchor proof,
cross-role risk review, contextual staple review, or prior failed-gate reopen
proof. This plan still does not reclassify cuts, copy a deck, run battle, or
promote anything.

Then run `global_commander_same_lane_stage_cut_trace_collector.py`. It reuses
existing current-scope replay artifacts and scans local external/reference
artifacts for every same-lane stage-only cut. A cut used by the target deck
blocks value-safe reclassification; seen-without-usage needs negative review;
external references still need internal trace proof. Candidate copy, battle,
promotion, and value-safe reclassification remain closed.

Then run `global_commander_same_lane_used_cut_recovery_router.py` for used
stage-only cuts. It separates structural/anchor/prior-failed cuts that should
prefer a fresh cut-source lane from non-structural used cuts that could proceed
only after explicit same-lane replacement proof. This router still does not open
candidate copy, battle, promotion, or value-safe reclassification.

Then run `global_commander_same_lane_new_cut_source_miner.py` after the recovery
router asks for fresh cut-source mining. It scans the current evaluation DB for
unconsumed same-lane cut sources and blocks anything already used, seen,
stage-only, blocked, or traced in the current evidence chain. If no genuinely
fresh same-lane source remains, the next route is to broaden same-lane cut
research or the package axis before candidate copy, battle, promotion, or
value-safe reclassification.

Then run `global_commander_same_lane_cut_axis_broadening_plan.py` after the new
cut-source miner exhausts the current deck. It converts exhausted target roles
into explicit external nonpayoff same-lane corpus work, holds the selected add
package, and forbids recycling used, seen, stage-only, blocked, or traced cuts.
Candidate copy, battle, promotion, and value-safe reclassification remain
closed.

Then run `global_commander_external_nonpayoff_same_lane_cut_corpus_collector.py`
after cut-axis broadening routes to external nonpayoff corpus. It records
role-level public Commander, combo, bracket/Game Changer, and strategy-source
signals plus their limitations. External corpus is source-policy evidence only;
it does not create cut permission, candidate copy, battle, promotion, or
value-safe reclassification.

Then run `global_commander_external_nonpayoff_same_lane_cut_policy_mapper.py`
after external nonpayoff corpus collection. It converts role-level corpus into
source-discovery policy and requires named external source candidates before
any miner rerun. It still does not create card-level cut permission, candidate
copy, battle, promotion, or value-safe reclassification.

Then run `global_commander_external_nonpayoff_same_lane_source_candidate_discoverer.py`
after external nonpayoff policy mapping. It converts only eligible role-level
source-discovery policy into named source-candidate rows and classifies whether
each card is already in the current deck, already in the held package, locally
resolved, or still unresolved. Named candidates are source-lane evidence only;
card-level cut permission, candidate copy, battle, promotion, and value-safe
reclassification remain closed.

## XMage Authoritative Adaptation

For all-card battle-rule acceleration, use local XMage as the authoritative
behavior source whenever a card resolves to a local XMage Java class. Build the
current global queue with:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_adaptation_queue.py \
  --xmage-root /Users/desenvolvimentomobile/Downloads/mage-master \
  --scope all_battle_gap \
  --out-prefix docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_$(date -u +%Y%m%d)_current_all_battle_gap
```

This queue separates source truth from runtime execution: resolved XMage cards
need ManaLoom adapter work by effect/signature; only missing XMage sources stay
in the residual manual/external-source queue.

Before building a PostgreSQL package from the global queue, split broad work
units into exact runtime-backed scopes:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py \
  --queue docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg323_creature_etb_add_counters_wave_commander_legal.json \
  --output-prefix docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_$(date -u +%Y%m%d)_next_wave
```

Only proposals marked `safe_for_batch_pg_package=true` may feed
`xmage_batch_pg_package_builder.py`. Generic `xmage_*_review_v1` scopes must
remain blocked until this split produces an exact `battle_model_scope` with
focused runtime tests.

Current applied checkpoint: PG426. PG420 closed exact basic landwalk, PG421
closed flying block-only-flying, PG422 closed exact filtered-evasion, PG423
closed static cant-block blocker legality, and PG424 closed static
horsemanship blocker legality. PG424b backfilled `oracle_hash` for `44` older
trusted PostgreSQL executable rules on the new server. PG425 closed static
flash timing keywords for `33` creature permanents and left only the separate
flash/protection and flash/activated-damage candidates for later adapters.
PG426 closed those `4` flash auxiliary residuals and the current exact split
recheck reports `proposal_count=0`; continue by selecting the next exact
subpattern from the rebuilt authoritative queue instead of reusing old split
artifacts.
Earlier package trail:
PG323. PG283
promoted and synced 312 exact one-shot
spell rules; PG284 added 53 exact utility rules; PG285 closed 8 all-card
supported residuals; PG286 added 12 pure counterspells with stack target
constraints; PG287 added 7 pure bounce spells with runtime `destination=hand`;
PG288 added 22 graveyard-to-hand recursion spells; PG289 added 13 mass-removal
spells across destroy-all and fixed damage-all scopes; PG290 added 3 fixed
target-creature add-counters spells; PG291 added 42 fixed target-creature
boost/debuff spells until end of turn; PG292 added 409 static self
combat-keyword creatures; PG293 added 85 additional static self keyword
creatures, including multiline Oracle keywords and safe
`hexproof`/`shroud`/`indestructible` enforcement; PG294 added 37 exact
creatures with fixed enter-the-battlefield life gain and blocked proportional
"for each" variants; PG295 added 28 exact creatures with fixed
enter-the-battlefield draw and blocked proportional/dynamic draw variants;
PG296 added 6 exact creatures with tap-only fixed activated damage and no
mana/sacrifice activation costs; PG297 added 19 exact creatures with
enter-the-battlefield destroy-target triggers and strict unrestricted Oracle
matching; PG298 added 22 exact creatures with enter-the-battlefield graveyard
recursion-to-hand triggers; PG299 added 4 more ETB graveyard recursion
creatures where static self keywords such as `flying` or `defender` are
preserved; PG300 added 8 exact one-shot self-graveyard recursion spells
returning artifact, creature, or permanent cards to the battlefield; PG301
added 20 exact creatures with fixed dies-draw triggers, including static
self-keyword preservation and optional draw handling; PG302 added 8 exact
creatures with fixed enter-the-battlefield damage triggers; PG303 added 27
exact one-shot fixed token spells from `CreateTokenEffect`; PG304 added 27
exact creatures with fixed enter-the-battlefield token creation; PG305 added
27 exact one-shot target-creature boost plus until-end-of-turn keyword spells;
PG306 added 13 exact one-shot damage plus controller life-gain spells; PG307
added 13 exact one-shot destroy-target plus controller life-gain spells; PG308
added 38 exact restricted target spells; PG309 added 18 exact permanent
activated draw rules with mana/tap/self-sacrifice activation handling; PG310
added 23 exact permanent activated damage rules with mana/tap/self-sacrifice
activation handling; PG311 added 11 exact permanent activated graveyard-to-hand
recursion rules with mana/tap/self-sacrifice activation handling and supported
graveyard targets including creature, artifact, enchantment, artifact creature,
basic land, permanent, instant/sorcery, artifact or enchantment, and any card;
PG312 added 19 exact permanent activated destroy-target rules with
mana/tap/self-sacrifice activation handling and supported battlefield target
constraints; PG313 added 63 exact permanent activated self-boost rules with
mana/tap activation handling and until-end-of-turn cleanup; PG314 added 12
exact permanent activated target-keyword rules with mana/tap activation
handling, target-creature legality, supported `haste`/`flying`/`trample`/
`first_strike` grants, and until-end-of-turn cleanup; PG315 added 19 exact
permanent activated target-creature boost/debuff rules with mana/tap activation
handling, beneficial/harmful target selection, zero-toughness cleanup, and
until-end-of-turn cleanup; PG316 added 9 source-sacrifice target-boost rules;
PG317 added 5 target-keyword rules on sources that also carry static self
keywords; PG318 added 13 exact library tutors to battlefield or library top;
PG319 added 6 graveyard self-return activated rules; PG320 added 14 fixed
activated life-gain permanents; PG321 added 32 exact static controlled-creature
power/toughness boosts from `BoostControlledEffect + SimpleStaticAbility`;
PG322 added 19 exact one-shot controlled-creature boost spells from fixed
`BoostControlledEffect` source rows; PG323 added 11 exact creatures with
enter-the-battlefield fixed add-counters triggers to one target creature.
The current splitter supports fixed draw, fixed direct damage, destroy target,
fixed controller life gain, exile target, simple tap mana-source permanents,
counter target spell, return target permanent/creature to hand, graveyard
recursion to hand, graveyard recursion to battlefield, simple board wipes,
fixed damage wipes, and fixed target-creature `+1/+1`/`-1/-1` counters, plus
supported restricted battlefield targets for damage/destroy/exile spells
(attacking/blocking, tapped/untapped, flying, color, power and mana value), plus
fixed target-creature power/toughness modifiers until end of turn, plus exact
one-shot controlled-creature power/toughness modifiers until end of turn, plus exact
static self combat and safe defensive keywords on creatures, plus fixed ETB
life gain on creatures, fixed ETB draw on creatures, creature tap-only
activated fixed damage, creature ETB destroy-target triggers, creature ETB
graveyard recursion-to-hand triggers, fixed creature dies-draw triggers, and
fixed creature enter-the-battlefield damage triggers, fixed creature
enter-the-battlefield add-counters triggers, plus fixed one-shot
spell token creation with literal creature token classes and safe
`flying`/`haste` token keywords, plus fixed creature ETB token creation with
literal creature token classes and safe token keyword preservation, plus fixed
target-creature boost plus temporary keyword spells with until-end-of-turn
cleanup, plus fixed one-shot damage plus controller life-gain spells, plus fixed
one-shot destroy-target plus controller life-gain spells; PG308 added 38 exact
restricted target fixed damage, destroy and exile spells with runtime legality
for attacking/blocking, tapped/untapped, flying, color, power and mana-value
constraints; PG309 added permanent simple activated draw support for fixed draw
abilities with mana/tap/self-sacrifice costs and focused blocking for unsafe
costs or dynamic counts; PG310 added permanent simple activated damage support
for fixed any-target or target-creature damage abilities with mana/tap/source
sacrifice costs and focused blocking for target-sacrifice costs, dynamic
amounts, and unsupported player-or-planeswalker targets; PG311 added permanent
simple activated graveyard-to-hand recursion support for exact simple activated
abilities with mana/tap/source self-sacrifice costs, summoning-sickness checks
for tap-creature activations, `basic_land` graveyard target matching, and
focused blocking for discard/exile/OrCost/CompositeCost costs, graveyard-source
activations, watcher conditions, multi-target mismatches, and unsupported
subtype restrictions; PG312 added permanent simple activated destroy-target
support for exact simple activated abilities with mana/tap/source
self-sacrifice costs, target-constraint legality, ward handling after activation
cost payment, and focused blocking for sacrifice-target costs, discard/exile
costs, OrCost/CompositeCost, non-simple destroy constructors, unsupported
targets, and extra Oracle clauses.
PG313 added permanent simple activated self-boost support for exact simple
activated abilities with simple mana/tap source costs, target `self`, explicit
power/toughness deltas, summoning-sickness handling for tap-creature
activations, profitable non-tap auto-activation, and focused blocking for
life/discard/sacrifice-target/target-tap/untap costs, hybrid/Phyrexian/untap
symbols, dynamic X boosts, modes, and compound text.
PG314 added permanent simple activated target-keyword support for exact simple
activated abilities with simple mana/tap source costs, target creature
selection, supported temporary keyword grants, summoning-sickness handling for
tap-creature activations, and focused blocking for source sacrifice,
subtype-filtered targets, unsupported Oracle text, and compound costs.
PG315 added permanent simple activated target-boost support for exact simple
activated abilities with simple mana/tap source costs, target creature
selection, positive and negative power/toughness modifiers, summoning-sickness
handling for tap-creature activations, zero-toughness cleanup, and focused
blocking for sacrifice costs, filtered targets, dynamic modifiers, target
pointers, and compound costs.
Evidence:

- `master_optimizer_reports/pg283_xmage_fixed_spell_wave_package.md`
- `master_optimizer_reports/pg283_xmage_fixed_spell_wave_e2e_validation.md`
- `master_optimizer_reports/pg284_xmage_utility_wave_package.md`
- `master_optimizer_reports/pg284_xmage_utility_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg284_xmage_utility_wave_e2e_validation.md`
- `master_optimizer_reports/pg285_xmage_all_scope_supported_residual_package.md`
- `master_optimizer_reports/pg285_xmage_all_scope_supported_residual_e2e_validation.md`
- `master_optimizer_reports/pg286_xmage_counter_spell_wave_package.md`
- `master_optimizer_reports/pg286_xmage_counter_spell_wave_e2e_validation.md`
- `master_optimizer_reports/pg287_xmage_bounce_spell_wave_package.md`
- `master_optimizer_reports/pg287_xmage_bounce_spell_wave_e2e_validation.md`
- `master_optimizer_reports/pg288_xmage_recursion_spell_wave_package.md`
- `master_optimizer_reports/pg288_xmage_recursion_spell_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg288_xmage_recursion_spell_wave_e2e_validation.md`
- `master_optimizer_reports/pg289_xmage_board_wipe_spell_wave_package.md`
- `master_optimizer_reports/pg289_xmage_board_wipe_spell_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg289_xmage_board_wipe_spell_wave_e2e_validation.md`
- `master_optimizer_reports/pg290_xmage_add_counters_spell_wave_package.md`
- `master_optimizer_reports/pg290_xmage_add_counters_spell_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg290_xmage_add_counters_spell_wave_e2e_validation.md`
- `master_optimizer_reports/pg291_xmage_boost_target_spell_wave_package.md`
- `master_optimizer_reports/pg291_xmage_boost_target_spell_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg291_xmage_boost_target_spell_wave_e2e_validation.md`
- `master_optimizer_reports/pg292_xmage_static_keyword_creature_wave_package.md`
- `master_optimizer_reports/pg292_xmage_static_keyword_creature_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg292_xmage_static_keyword_creature_wave_e2e_validation.md`
- `master_optimizer_reports/pg293_xmage_static_self_keyword_creature_v2_wave_package.md`
- `master_optimizer_reports/pg293_xmage_static_self_keyword_creature_v2_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg293_xmage_static_self_keyword_creature_v2_wave_e2e_validation.md`
- `master_optimizer_reports/pg294_xmage_creature_etb_life_gain_wave_package.md`
- `master_optimizer_reports/pg294_xmage_creature_etb_life_gain_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg294_xmage_creature_etb_life_gain_wave_e2e_validation.md`
- `master_optimizer_reports/pg295_xmage_creature_etb_draw_wave_package.md`
- `master_optimizer_reports/pg295_xmage_creature_etb_draw_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg295_xmage_creature_etb_draw_wave_e2e_validation.md`
- `master_optimizer_reports/pg296_xmage_creature_tap_damage_wave_package.md`
- `master_optimizer_reports/pg296_xmage_creature_tap_damage_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg296_xmage_creature_tap_damage_wave_e2e_validation.md`
- `master_optimizer_reports/pg297_xmage_creature_etb_destroy_wave_package.md`
- `master_optimizer_reports/pg297_xmage_creature_etb_destroy_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg297_xmage_creature_etb_destroy_wave_e2e_validation.md`
- `master_optimizer_reports/pg298_xmage_creature_etb_recursion_wave_package.md`
- `master_optimizer_reports/pg298_xmage_creature_etb_recursion_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg298_xmage_creature_etb_recursion_wave_e2e_validation.md`
- `master_optimizer_reports/pg299_xmage_creature_etb_recursion_keyword_wave_package.md`
- `master_optimizer_reports/pg299_xmage_creature_etb_recursion_keyword_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg299_xmage_creature_etb_recursion_keyword_wave_e2e_validation.md`
- `master_optimizer_reports/pg300_xmage_recursion_battlefield_spell_wave_package.md`
- `master_optimizer_reports/pg300_xmage_recursion_battlefield_spell_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg300_xmage_recursion_battlefield_spell_wave_e2e_validation.md`
- `master_optimizer_reports/pg301_xmage_creature_dies_draw_wave_package.md`
- `master_optimizer_reports/pg301_xmage_creature_dies_draw_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg301_xmage_creature_dies_draw_wave_e2e_validation.md`
- `master_optimizer_reports/pg302_xmage_creature_etb_damage_wave_package.md`
- `master_optimizer_reports/pg302_xmage_creature_etb_damage_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg302_xmage_creature_etb_damage_wave_e2e_validation.md`
- `master_optimizer_reports/pg303_xmage_fixed_token_spell_wave_package.md`
- `master_optimizer_reports/pg303_xmage_fixed_token_spell_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg303_xmage_fixed_token_spell_wave_e2e_validation.md`
- `master_optimizer_reports/pg304_xmage_creature_etb_token_wave_package.md`
- `master_optimizer_reports/pg304_xmage_creature_etb_token_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg304_xmage_creature_etb_token_wave_e2e_validation.md`
- `master_optimizer_reports/pg305_xmage_boost_keyword_spell_wave_package.md`
- `master_optimizer_reports/pg305_xmage_boost_keyword_spell_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg305_xmage_boost_keyword_spell_wave_e2e_validation.md`
- `master_optimizer_reports/pg306_xmage_damage_gain_life_spell_wave_package.md`
- `master_optimizer_reports/pg306_xmage_damage_gain_life_spell_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg306_xmage_damage_gain_life_spell_wave_e2e_validation.md`
- `master_optimizer_reports/pg307_xmage_destroy_gain_life_spell_wave_package.md`
- `master_optimizer_reports/pg307_xmage_destroy_gain_life_spell_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg307_xmage_destroy_gain_life_spell_wave_e2e_validation.md`
- `master_optimizer_reports/pg308_xmage_restricted_target_spell_wave_package.md`
- `master_optimizer_reports/pg308_xmage_restricted_target_spell_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg308_xmage_restricted_target_spell_wave_e2e_validation.md`
- `master_optimizer_reports/pg309_xmage_permanent_activated_draw_wave_package.md`
- `master_optimizer_reports/pg309_xmage_permanent_activated_draw_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg309_xmage_permanent_activated_draw_wave_e2e_validation.md`
- `master_optimizer_reports/pg309_xmage_permanent_activated_draw_wave_pg_to_sqlite_sync.json`
- `master_optimizer_reports/pg310_xmage_permanent_activated_damage_wave_package.md`
- `master_optimizer_reports/pg310_xmage_permanent_activated_damage_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg310_xmage_permanent_activated_damage_wave_e2e_validation.md`
- `master_optimizer_reports/pg310_xmage_permanent_activated_damage_wave_pg_to_sqlite_sync.json`
- `master_optimizer_reports/pg311_xmage_permanent_activated_recursion_to_hand_wave_package.md`
- `master_optimizer_reports/pg311_xmage_permanent_activated_recursion_to_hand_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg311_xmage_permanent_activated_recursion_to_hand_wave_e2e_validation.md`
- `master_optimizer_reports/pg311_xmage_permanent_activated_recursion_to_hand_wave_pg_to_sqlite_sync.json`
- `master_optimizer_reports/pg311_xmage_permanent_activated_recursion_to_hand_wave_battle_rules_pg_to_sqlite_sync.json`
- `master_optimizer_reports/pg312_xmage_permanent_activated_destroy_wave_package.md`
- `master_optimizer_reports/pg312_xmage_permanent_activated_destroy_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg312_xmage_permanent_activated_destroy_wave_e2e_validation.md`
- `master_optimizer_reports/pg312_xmage_permanent_activated_destroy_wave_pg_to_sqlite_sync.json`
- `master_optimizer_reports/pg312_xmage_permanent_activated_destroy_wave_battle_rules_pg_to_sqlite_sync.json`
- `master_optimizer_reports/pg313_xmage_permanent_activated_self_boost_wave_package.md`
- `master_optimizer_reports/pg313_xmage_permanent_activated_self_boost_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg313_xmage_permanent_activated_self_boost_wave_e2e_validation.md`
- `master_optimizer_reports/pg313_xmage_permanent_activated_self_boost_wave_pg_to_sqlite_sync.json`
- `master_optimizer_reports/pg313_xmage_permanent_activated_self_boost_wave_battle_rules_pg_to_sqlite_sync.json`
- `master_optimizer_reports/pg314_xmage_permanent_activated_target_keyword_wave_package.md`
- `master_optimizer_reports/pg314_xmage_permanent_activated_target_keyword_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg314_xmage_permanent_activated_target_keyword_wave_e2e_validation.md`
- `master_optimizer_reports/pg314_xmage_permanent_activated_target_keyword_wave_pg_to_sqlite_sync.json`
- `master_optimizer_reports/pg314_xmage_permanent_activated_target_keyword_wave_battle_rules_pg_to_sqlite_sync.json`
- `master_optimizer_reports/pg315_xmage_permanent_activated_target_boost_wave_package.md`
- `master_optimizer_reports/pg315_xmage_permanent_activated_target_boost_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg315_xmage_permanent_activated_target_boost_wave_e2e_validation.md`
- `master_optimizer_reports/pg315_xmage_permanent_activated_target_boost_wave_pg_to_sqlite_sync.json`
- `master_optimizer_reports/pg315_xmage_permanent_activated_target_boost_wave_battle_rules_pg_to_sqlite_sync.json`
- `master_optimizer_reports/pg316_xmage_permanent_activated_target_boost_source_sacrifice_wave_package.md`
- `master_optimizer_reports/pg316_xmage_permanent_activated_target_boost_source_sacrifice_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg316_xmage_permanent_activated_target_boost_source_sacrifice_wave_e2e_validation.md`
- `master_optimizer_reports/pg317_xmage_permanent_activated_target_keyword_static_self_keyword_wave_package.md`
- `master_optimizer_reports/pg317_xmage_permanent_activated_target_keyword_static_self_keyword_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg317_xmage_permanent_activated_target_keyword_static_self_keyword_wave_e2e_validation.md`
- `master_optimizer_reports/pg318_xmage_library_tutor_spell_wave_package.md`
- `master_optimizer_reports/pg318_xmage_library_tutor_spell_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg318_xmage_library_tutor_spell_wave_e2e_validation.md`
- `master_optimizer_reports/pg319_xmage_graveyard_self_return_wave_package.md`
- `master_optimizer_reports/pg319_xmage_graveyard_self_return_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg319_xmage_graveyard_self_return_wave_e2e_validation.md`
- `master_optimizer_reports/pg320_xmage_permanent_activated_life_gain_wave_package.md`
- `master_optimizer_reports/pg320_xmage_permanent_activated_life_gain_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg320_xmage_permanent_activated_life_gain_wave_e2e_validation.md`
- `master_optimizer_reports/pg320_xmage_permanent_activated_life_gain_wave_pg_to_sqlite_sync.json`
- `master_optimizer_reports/pg320_xmage_permanent_activated_life_gain_wave_battle_rules_pg_to_sqlite_sync.json`
- `master_optimizer_reports/pg321_xmage_static_controlled_power_toughness_boost_wave_package.md`
- `master_optimizer_reports/pg321_xmage_static_controlled_power_toughness_boost_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg321_xmage_static_controlled_power_toughness_boost_wave_e2e_validation.md`
- `master_optimizer_reports/pg321_xmage_static_controlled_power_toughness_boost_wave_pg_to_sqlite_sync.json`
- `master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg321_static_controlled_power_toughness_boost_wave_commander_legal.md`
- `master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_pg321_static_controlled_pt_wave.md`
- `master_optimizer_reports/pg322_xmage_boost_controlled_until_eot_wave_package.md`
- `master_optimizer_reports/pg322_xmage_boost_controlled_until_eot_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg322_xmage_boost_controlled_until_eot_wave_e2e_validation.md`
- `master_optimizer_reports/pg322_xmage_boost_controlled_until_eot_wave_pg_to_sqlite_sync.json`
- `master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg322_boost_controlled_until_eot_wave_commander_legal.md`
- `master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_pg322_boost_controlled_until_eot_wave.md`
- `master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg322_existing_supported_recheck.md`
- `master_optimizer_reports/pg323_xmage_creature_etb_add_counters_wave_package.md`
- `master_optimizer_reports/pg323_xmage_creature_etb_add_counters_wave_pg_apply_evidence.md`
- `master_optimizer_reports/pg323_xmage_creature_etb_add_counters_wave_e2e_validation.md`
- `master_optimizer_reports/pg323_xmage_creature_etb_add_counters_wave_pg_to_sqlite_sync.json`
- `master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg323_creature_etb_add_counters_wave_commander_legal.md`
- `master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_pg323_creature_etb_add_counters_wave.md`
- `master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg323_existing_supported_recheck.md`

After PG428, the post-static-subtype-protection queue is the current
scheduling source:
`target_identity_count=26350`, `xmage_authoritative_source_count=26036`,
`xmage_authoritative_adapter_required_count=26036`, `parser_gap=0`, and
`xmage_missing_source_exception_count=314`. Continue by adding a new exact
subpattern/runtime adapter for a remaining high-volume family from that queue;
do not schedule from any older PG323, PG400, PG425, PG426, or PG427 queue
artifact. PG428 closed `8` creatures with exact self-protection from subtypes
through `xmage_static_self_protection_from_subtypes_creature_v1` plus
`Tel-Jilad Archers` through the existing card-type protection scope after
fixing trailing keyword parsing.

After generating a package with `xmage_batch_pg_package_builder.py`, run the
approved PostgreSQL mutation through the evidence runner instead of ad hoc SQL:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_apply_evidence.py \
  --manifest docs/hermes-analysis/master_optimizer_reports/pgXXX_slug_manifest.json \
  --apply
```

## Local Replay Audit

For local Mac validation, do not trust a raw replay generated from an old
`knowledge.db`. Refresh the SQLite battle cache from PostgreSQL first, then run
the replay and both auditors.

Use the runner below instead of calling `battle_replay_v10_3.py` directly:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
server/bin/run_local_battle_replay_audit.sh
```

That runner:

1. loads `server/.env` when present;
2. mirrors reviewed `card_battle_rules` from PostgreSQL into the local Hermes
   SQLite cache;
3. runs `battle_replay_v10_3.py`;
4. runs `replay_decision_auditor.py`;
5. runs `battle_decision_strategy_auditor.py`;
6. stores replay + audit artifacts under `server/test/artifacts/local_battle_replay_audit/`.

If you intentionally want to audit with the current local cache only, use
`--skip-sync`, but treat that as a degraded/debugging mode rather than a source
of truth replay.
