# Lorehold 607 Deckbuilding Learning Ledger - 2026-07-04

Status: `active_learning_checkpoint`

This ledger records the current deckbuilding lesson for protected Lorehold deck
`607`. It is not a deck promotion, not a PostgreSQL write plan, and not a
replacement list.

## External Evidence Checked

- Wizards Commander format page: Commander is a 99 + 1 singleton format built
  around commander color identity, with colorless cards allowed when legal.
  Source: https://magic.wizards.com/en/formats/commander
- Scryfall API on 2026-07-04:
  - `Lorehold, the Historian`: Commander legal, color identity `R,W`.
  - `Mana Vault`: Commander legal, colorless, `game_changer=true`.
  - `The One Ring`: Commander legal, colorless, `game_changer=true`.
  - `Smothering Tithe`: Commander legal, white, `game_changer=true`.
- EDHREC Lorehold upgraded/discard page on 2026-07-04:
  `Library of Leng`, `Storm Herd`, `Monument to Endurance`, `Big Score`,
  `Approach of the Second Sun`, `Mizzix's Mastery`, `Sensei's Divining Top`,
  and `Scroll Rack` remain high commander-context signals.
  `The One Ring` appears as a game changer but only at low current Lorehold
  inclusion on that page.
  Source: https://edhrec.com/commanders/lorehold-the-historian/upgraded/discard
- EDHREC Lorehold miracle article and Draftsim/Card Kingdom guides agree with
  the main strategic read: the deck is not generic Boros ramp-goodstuff. It
  needs topdeck setup, miracle timing, repeated opponent-upkeep looting, big
  instant/sorcery conversion, and specific finishers such as `Approach of the
  Second Sun`.

## Internal Evidence Generated

Fresh read-only reports generated after the 2026-07-04 role/tag repair:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_closing_window_trace_miner_20260704_role_tag_repair.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_trace_targeted_micro_package_model_20260704_role_tag_repair.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_trace_cut_evidence_expander_20260704_role_tag_repair.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_next_action_planner_20260704_role_tag_repair_learning.md`

Important current outputs:

- Closing-window miner: `13` direct comparisons where `607` won and rejected
  challengers lost. All `13` challenger losses died before the `607` closing
  window. Average `607` turn advantage was `10.15`.
- Dominant strategic deficits in rejected challengers:
  `lorehold_cost_paid=153`, `lorehold_spell_cast=134`, `miracle_cast=71`,
  `lorehold_upkeep_rummage=63`, `topdeck_manipulation_activated=41`, and
  `static_cost_reduction_total=37`.
- Dominant protected anchor deficits: `Sensei's Divining Top`, `Scroll Rack`,
  `Approach of the Second Sun`, `Victory Chimes`, `Mizzix's Mastery`,
  `Bender's Waterskin`, and `Jeska's Will`.
- Seed-safe cut synthesis: `94` deck rows evaluated, `0` seed-safe cuts,
  `92` hard-blocked slots, and `2` same-lane hard-blocked slots.
- The same-lane hard-blocked slots are `Creative Technique` and
  `Bender's Waterskin`; neither is a generic cut under the current contract.
- Trace-targeted micro-package model: `3` trace hypotheses evaluated,
  `0` ready micro-packages because `seed_safe_cut_ready_count=0`.
- Planner top action:
  `no_cut_slot_to_expand_under_current_607_contract`.

## Current Learning

`Mana Vault` and `The One Ring` are accessible to Lorehold by legality and color
identity. They are not accessible to the current `607` champion as automatic
deck changes because the current contract requires a safe cut and equal battle
proof.

Prior controlled tests already exercised both cards:

- `Mana Vault` is a real fast-mana card, but the repaired one-card swap over
  `Bender's Waterskin` lost the confirmed gate and did not replace the
  miracle-timing/ramp lane cleanly.
- `The One Ring` is a real protection/draw engine, but the tested draw/value
  cuts lost to `607`; the card was accessed and used, so the rejection was not
  caused by invisible sampling.

The practical rule for ManaLoom deckbuilding is:

1. A card can be legal, powerful, popular, and even a `game_changer`, and still
   fail this deck.
2. For Lorehold, value must be measured by whether the card preserves or
   improves the miracle/topdeck/rummage/spell-volume closing window.
3. A new card must either replace the same lane with proof or be part of a
   declared package that protects the `607` anchors.
4. Forced-access evidence can teach card value, but it cannot promote a deck
   without natural confirmation and critical-matchup safety.

## What Not To Do Next

- Do not run more one-for-one swap gates against `607` from the exhausted queue.
- Do not cut `Bender's Waterskin` or `Creative Technique` as generic flex.
- Do not treat `Mana Vault`, `The One Ring`, or another game changer as an
  automatic upgrade.
- Do not promote a from-scratch shell from structure, popularity, or forced
  access alone.

## Valid Next Learning Paths

1. External-card-evidence path: find a newly supported card or public package
   that changes a specific cut-safety row, then rerun the safe-cut model before
   any battle gate.
2. Full-shell path: declare a separate archetype contract that keeps the `607`
   topdeck/miracle/protection floor and explicitly repairs pressure conversion.
3. Runtime-change path: if a battle adapter changes materially, rerun the
   exposure and gate evidence for affected cards before drawing deckbuilding
   conclusions.
4. Product-model path: expose `game_changer`, commander inclusion rate,
   commander-context role, same-lane cut status, and battle proof separately in
   the app. Do not collapse them into one "best card" score.

## Mana-Base Learning - 2026-07-05

`Plateau` is Commander legal for Lorehold and is structurally attractive because
it is an untapped `Mountain Plains`. That still was not enough to replace a land
in protected `607` without battle proof.

Two exact mana-base hypotheses were materialized only in copied Hermes DBs and
then rejected:

- `+Plateau / -Radiant Summit`: preflight passed, but natural smoke and forced
  opening-hand diagnostics both lost to `607`.
- `+Plateau / -Turbulent Steppe`: preflight passed, natural smoke was
  inconclusive at `0/1` for both lists, and forced opening-hand diagnostics
  lost `1/3` versus protected `607` at `2/3`.

The important deckbuilding lesson is that a cleaner untapped dual can be a real
structural upgrade and still fail the active Lorehold shell if it does not
improve the actual battle window. The current mana-base model-ready queue is
closed until new material evidence changes the safe-cut pool or proposes a
different land package, not another exact retest of these pairs.

## Post-Mana-Base Route - 2026-07-05

After closing the simple mana-base queue, the current router says the next
valid learning route is `build_pressure_safe_cut_expansion_model`.

Current facts:

- mana-base eligible pairs: `0`;
- natural gate-ready watchlist cards: `0`;
- pressure package gate-ready count: `0`;
- seed-safe cut-ready count: `0`;
- promotable external shell count: `0`.

External evidence continues to support Lorehold as a spellslinger/topdeck/
miracle commander, with pressure/treasure signals such as `Storm-Kiln Artist`,
but that does not create a deck change by itself. The active blocker is cut
safety: before testing more pressure, Treasure, or combo packages, ManaLoom must
find a named cut plan that preserves the protected `607` miracle/topdeck floor.

Do not run another natural battle gate from the current watchlist until a
candidate has safe-cut proof and miracle-access preflight.

Current conclusion: protected deck `607` remains the Lorehold champion under
the active contract. The learning task stays open because a better deck may
exist, but it has not been proven by the current evidence.

## Pressure Safe-Cut Expansion Model - 2026-07-05

The next learning artifact is:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_pressure_safe_cut_expansion_model_20260705_current.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_pressure_safe_cut_expansion_model_20260705_current.json`

It converts the external deckbuilding lesson into an executable local policy:
legal identity, public popularity, game-changer status, and raw card power are
only inputs. A card becomes actionable only after it improves a specific
Lorehold lane, has a named safe cut, and survives battle/replay validation.

Current result:

- status: `pressure_cut_expansion_no_seed_safe_cut_keep_607`;
- seed-safe cuts: `0`;
- same-lane-only diagnostic cuts: `2`;
- hard-blocked cuts: `92`;
- gate-ready pressure packages: `0`;
- natural battle allowed now: `false`;
- promotion allowed: `false`.

Current pressure routes:

- `Monastery Mentor`, `Young Pyromancer`, `Guttersnipe`, and
  `Storm-Kiln Artist` remain the primary four-card pressure package, but it is
  blocked because it needs four named safe cuts and currently has zero.
- `Guttersnipe` plus `Young Pyromancer` remains the smallest natural-trigger
  pressure hypothesis, but it is also blocked because it needs two safe cuts.
- `Storm-Kiln Artist` plus `Haze of Rage` is a valid combo research lane, not a
  promotion lane, until runtime, cut-safety, and battle evidence exist.

Current cut-learning targets:

- `Creative Technique`: same-lane diagnostic only; not a generic flex cut.
- `Bender's Waterskin`: same-lane diagnostic only; not a generic fast-mana cut.
- `Generous Gift`, `Esper Sentinel`, `Path to Exile`,
  `Swords to Plowshares`, `Monument to Endurance`, `Sensei's Divining Top`,
  and `Smothering Tithe` remain blocked by high exposure or protected role
  evidence.

Staple/artifact/land lesson:

- `Mana Vault` is legal and powerful, but remains blocked as an automatic
  include because the prior one-card `Bender's Waterskin` replacement lost.
- `The One Ring` is legal and powerful, but remains blocked as an automatic
  include because tested draw/value cuts lost to protected `607`.
- `Storm-Kiln Artist` is contextual pressure/treasure research, not a generic
  mana-rock replacement.
- `Plateau` is a structurally clean land, but both simple copied-DB swaps were
  rejected, so simple land swaps are not the next learning route.

Current conclusion remains unchanged: protected deck `607` is still the
Lorehold champion. The persistent learning task continues through cut-cost
discovery and diagnostic-only same-lane microbenchmarks, not natural battles.

## Same-Lane Microbenchmark Decision - 2026-07-05

The pressure safe-cut expansion pointed at diagnostic-only same-lane
microbenchmarks for `Creative Technique` and `Bender's Waterskin`. The current
reports are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_same_lane_diagnostic_microbenchmarks_20260705_current.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_same_lane_microbenchmark_decision_synthesis_20260705_current.md`

Implementation note: the profiled cut benchmark generator now preserves
`cut_safety` embedded in the current manual review rows when the external
cut-safety report or registry provides only partial protection metadata. This
keeps the functional lane (`finisher_or_big_spell`, `early_mana`) separate from
generic `registry_protected` status.

Current same-lane scan:

- profiled cuts: `2`;
- supported cuts: `2`;
- candidate pairs evaluated: `540`;
- static preflight-ready pairs: `1`;
- selected static package:
  `Possibility Storm` over `Creative Technique`;
- `Bender's Waterskin` ready pairs: `0`.

Decision synthesis:

- status: `same_lane_static_ready_prior_natural_rejected_keep_607`;
- prior natural rejects: `2`;
- forced-access diagnostic signal: `1`;
- natural battle allowed now: `false`;
- promotion allowed: `false`.

Historical gate evidence for `Possibility Storm` over `Creative Technique`:

- 2026-06-30 natural smoke: protected `607` went `11/24`; candidate went
  `3/24`, delta `-33.33pp`.
- 2026-07-04 natural smoke: protected `607` went `2/4`; candidate went `1/4`,
  delta `-25.0pp`.
- 2026-07-04 forced opening-hand diagnostic: protected `607` went `0/4`;
  candidate went `2/4`, delta `+50.0pp`, but forced access is diagnostic only
  and cannot override natural rejection.

`Bender's Waterskin` remains blocked as an early-mana cut. The highest-scoring
same-lane replacements in the current scan (`Seething Song`, `Birgi`,
`Mana Vault`, `Basalt Monolith`, `Desperate Ritual`, `Pyretic Ritual`,
`Cloud Key`, `Electro`, `Locket of Yesterdays`, `Lotus Petal`, and others)
are blocked by `prior_exact_reject` or explicit premium-Mox/runtime-cost
policy blockers.

Current conclusion remains unchanged: do not mutate or promote over protected
deck `607`. Reopen this same-lane path only with new material evidence, a
changed runtime adapter, or a same-lane candidate not already exhausted by the
current queue.

## External Material Evidence Scout - 2026-07-05

The next learning artifact is:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_external_material_evidence_scout_20260705_current.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_external_material_evidence_scout_20260705_current.json`

It converts current external Lorehold research into local ManaLoom routing
evidence. The purpose is not to add cards directly; it is to decide which
external cards are already local candidates, which require identity/import
work, and which are archetype forks that need a full-shell contract.

External lanes checked:

- EDHREC upgraded spellslinger: Topdeck/Spellslinger/Discard/Burn public
  surface with pressure candidates such as `Storm-Kiln Artist`, `Guttersnipe`,
  `Young Pyromancer`, `Monastery Mentor`, `Surly Badgersaur`, `Goldspan
  Dragon`, `Glint-Horn Buccaneer`, and `Inti, Seneschal of the Sun`.
- GameTyrant Lorehold deck tech: topdeck setup, miracle hits, alternate cast
  support, and pressure conversion cards such as `Brain in a Jar`, `Galvanoth`,
  `Burning Prophet`, `Dragon's Rage Channeler`, `Planetarium of Wan Shi Tong`,
  and `Entreat the Angels`.
- Card Kingdom synergy article: white reanimator direction with `Storm of
  Souls`, `Late to Dinner`, `Miraculous Recovery`, and `Karmic Guide`.
- CoolStuffInc commander article: token, combo, burn/damage, and Voltron
  directions with `Anointed Procession`, `Cathars' Crusade`,
  `Blackblade Reforged`, `Strata Scythe`, and `Excalibur, Sword of Eden`.
- Commander Spellbook: `Storm-Kiln Artist` plus `Haze of Rage` combo lane.
- Archidekt: broad public Lorehold corpus for future reference mining.

Current result:

- status: `external_material_evidence_found_but_no_gate_ready_keep_607`;
- external sources: `6`;
- external candidates: `24`;
- candidates already in protected `607`: `0`;
- local Lorehold variant candidates not in `607`: `10`;
- rule-known external cards not in the Lorehold candidate pool: `1`;
- missing from the local deck pool: `13`;
- archetype-fork candidates: `9`;
- gate-ready packages: `0`;
- natural battle allowed now: `false`;
- promotion allowed: `false`.

Important classifications:

- `Storm-Kiln Artist` is present in local Lorehold variants
  `608,611,612,613,614` and has verified auto rule support, but the
  `Storm-Kiln Artist + Haze of Rage` package is still only research because
  `Haze of Rage` is not in the current local Lorehold deck pool and has no
  local battle-rule row.
- Reanimator cards from the Card Kingdom lane are not one-for-one 607 cuts.
  `Karmic Guide` has a local verified auto battle rule, but no current
  Lorehold variant materialization. The reanimator lane therefore requires a
  full-shell contract before any battle gate.
- Token/Voltron closure cards from the CoolStuffInc lane are missing from the
  local deck pool and represent a different closure plan, not evidence to cut
  a protected 607 anchor.
- Existing pressure cards from EDHREC/GameTyrant that already appear in local
  variants remain blocked by the current cut-safety state, not by lack of
  public support.

Current conclusion remains unchanged: protected deck `607` is still the
Lorehold champion. External evidence has expanded the learning queue, but the
next valid step is `build_external_candidate_identity_import_preflight_before_any_new_gate`,
not a natural battle or mutation of `607`.

## External Candidate Identity Import Preflight - 2026-07-05

The next learning artifact is:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_external_candidate_identity_import_preflight_20260705_current.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_external_candidate_identity_import_preflight_20260705_current.json`

It consumes the external material scout and checks the `14` external material
candidates against local Oracle identity, Commander legality, format-staple
metadata, and verified battle-rule coverage.

Current result:

- status: `external_identity_preflight_blocks_gate_keep_607`;
- material candidates: `14`;
- Commander legal: `14`;
- local Oracle identity ready: `8`;
- local Oracle identity missing: `6`;
- identity-ready without verified rule: `7`;
- isolated runtime/manual-review queue: `2`;
- full-shell contract queue: `6`;
- gate-ready packages: `0`;
- natural battle allowed now: `false`;
- promotion allowed: `false`.

Current queues:

- `identity_import_required`: `Brain in a Jar`, `Entreat the Angels`,
  `Haze of Rage`, `Late to Dinner`, `Miraculous Recovery`, and
  `Strata Scythe`.
- `runtime_or_manual_review_required`: `Burning Prophet` and
  `Inti, Seneschal of the Sun`.
- `shell_contract_required`: `Anointed Procession`, `Blackblade Reforged`,
  `Cathars' Crusade`, `Excalibur, Sword of Eden`, `Karmic Guide`, and
  `Storm of Souls`.
- `cut_safety_contract_required`: none.

Interpretation:

- All material candidates pass Commander legality, so the current blocker is
  not color identity or legality.
- Six candidates cannot be materialized responsibly because local Oracle
  identity is missing.
- `Anointed Procession` already has local Oracle identity through
  `normalized_name=anointed procession` even though its display name is stored
  as `Anointed Procession // Anointed Procession`; this is a shell-contract
  card, not an identity-import row.
- `Burning Prophet` and `Inti, Seneschal of the Sun` have local identity but
  require runtime/manual-review work before any focused deck test.
- The shell-contract queue is a deck-thesis question, not a one-card cut
  question. It must not be routed into the exhausted one-for-one `607` swap
  gate.

Current conclusion remains unchanged: protected deck `607` is still the
Lorehold champion. The next valid learning step is
`resolve_oracle_identity_then_split_runtime_shell_and_cut_safety_queues`, with
identity import/preflight before battle or mutation.

## External Identity Resolution Queue - 2026-07-05

The next learning artifact is:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_external_identity_resolution_queue_20260705_current.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_external_identity_resolution_queue_20260705_current.json`

It resolves the `6` missing identity cards through Scryfall and produces a
report-only queue. It does not write SQLite, does not mutate `607`, and does
not make any card battle-ready by itself.

Current result:

- status: `external_identity_resolution_ready_for_apply_plan_keep_607`;
- identity queue: `6`;
- Scryfall identities found: `6`;
- Commander legal: `6`;
- Lorehold color-identity compatible: `6`;
- cache-insert ready: `6`;
- deck-test ready: `0`;
- natural battle allowed now: `false`;
- promotion allowed: `false`.

Cache identity queue:

- `Brain in a Jar`
- `Entreat the Angels`
- `Haze of Rage`
- `Late to Dinner`
- `Miraculous Recovery`
- `Strata Scythe`

Post-identity routes:

- `Haze of Rage`: combo runtime plus cut-safety route after identity exists
  locally.
- `Late to Dinner`, `Miraculous Recovery`, and `Strata Scythe`:
  shell-contract route; keep them out of one-for-one `607`
  swap gates.
- `Brain in a Jar` and `Entreat the Angels`: runtime or cut-safety route after
  identity exists locally.

Current conclusion remains unchanged: protected deck `607` is still the
Lorehold champion. The next valid step is
`prepare_reviewed_sqlite_identity_cache_apply_package_without_deck_mutation`;
identity readiness is not deck-promotion evidence.

## External Identity Cache Apply Package - 2026-07-05

The next learning artifact is:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_external_identity_cache_apply_package_20260705_current.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_external_identity_cache_apply_package_20260705_current.json`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_external_identity_cache_apply_package_20260705_current_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_external_identity_cache_apply_package_20260705_current_apply_sqlite.sql`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_external_identity_cache_apply_package_20260705_current_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_external_identity_cache_apply_package_20260705_current_rollback_sqlite.sql`

It prepares a reviewed SQLite cache package for the six Scryfall-resolved
external identities. The package was generated but not executed.

Current result:

- status: `external_identity_cache_apply_package_prepared_not_applied_keep_607`;
- cache-insert ready rows: `6`;
- SQLite apply executed: `false`;
- deck-test ready: `0`;
- natural battle allowed now: `false`;
- promotion allowed: `false`.

Safety notes:

- The apply SQL inserts only into `card_oracle_cache`.
- It does not alter `deck_cards`, `battle_card_rules`, or PostgreSQL.
- It uses plain `INSERT`, not `ON CONFLICT DO UPDATE`; if any target identity
  already exists, the apply should fail rather than overwrite local cache data.
- The rollback deletes only rows with source marker
  `lorehold_external_identity_resolution_queue_20260705_current`.
- The package was validated on a temporary copy of `knowledge.db`: precheck
  found `0` existing target rows, apply inserted `6`, postcheck returned `6`,
  rollback returned `0`, and the source database was not touched.

Current conclusion remains unchanged: protected deck `607` is still the
Lorehold champion. Applying identity cache rows, if later approved, is a data
readiness step only; it does not prove any deck change.

## External Identity Cache Simulation - 2026-07-05

The next learning artifact is:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_external_identity_cache_simulation_20260705_current.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_external_identity_cache_simulation_20260705_current.json`

It executes the prepared SQLite identity cache package only against a temporary
copy of `knowledge.db`, reruns the external identity preflight against that
temporary copy after apply, then rolls the temporary copy back. It is a
simulation and does not mutate the source database.

Current result:

- status: `external_identity_cache_simulation_pass_keep_607`;
- source marker rows before/after: `0` / `0`;
- temporary precheck existing target rows: `0`;
- temporary apply return code: `0`;
- temporary postcheck resolved rows: `6`;
- temporary rollback remaining package rows: `0`;
- post-apply identity missing count: `0`;
- post-apply runtime/manual-review queue: `5`;
- post-apply shell-contract queue: `9`;
- deck-test ready: `0`;
- natural battle allowed now: `false`;
- promotion allowed: `false`.

Temporary postcheck resolved all six identity rows as Commander legal:

- `Brain in a Jar`
- `Entreat the Angels`
- `Haze of Rage`
- `Late to Dinner`
- `Miraculous Recovery`
- `Strata Scythe`

Post-identity routing:

- `runtime_or_manual_review_required`: `Brain in a Jar`,
  `Burning Prophet`, `Entreat the Angels`, `Haze of Rage`, and
  `Inti, Seneschal of the Sun`.
- `combo_runtime_required`: `Haze of Rage`.
- `shell_contract_required`: `Anointed Procession`, `Blackblade Reforged`,
  `Cathars' Crusade`, `Excalibur, Sword of Eden`, `Karmic Guide`,
  `Late to Dinner`, `Miraculous Recovery`, `Storm of Souls`, and
  `Strata Scythe`.
- `cut_safety_contract_required`: none.

Interpretation:

- The identity blocker can be removed cleanly in an isolated SQLite simulation.
- The source database stayed untouched, and protected deck `607` stayed
  untouched.
- Removing identity blockers still does not create a battle-ready candidate:
  runtime, combo, and shell-contract work remains before any natural battle or
  cut gate.
- The next valid learning step is
  `split_post_identity_runtime_combo_and_shell_contract_queues_without_deck_mutation`.

Current conclusion remains unchanged: protected deck `607` is still the
Lorehold champion. This checkpoint improves ManaLoom's card-identity readiness
for external Lorehold learning, but it is not deck-promotion evidence.

## Post-Identity Queue Split - 2026-07-05

The next learning artifact is:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_post_identity_queue_split_20260705_current.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_post_identity_queue_split_20260705_current.json`

It consumes the identity-cache simulation and splits the now identity-ready
external candidates into runtime/manual-review, combo, and full-shell
contracts. It is report-only: no PostgreSQL writes, no source SQLite writes,
and no mutation of protected deck `607`.

Current result:

- status: `post_identity_queue_split_no_battle_ready_keep_607`;
- queue cards: `14`;
- remaining identity imports: `0`;
- temporary simulation identities: `6`;
- source DB identities: `8`;
- runtime/manual-review routes: `4`;
- combo runtime contract routes: `1`;
- full-shell contract routes: `9`;
- verified auto-rule-ready cards: `1`;
- battle-ready cards now: `0`;
- natural battle allowed now: `false`;
- promotion allowed: `false`.

Priority split:

- `Brain in a Jar`: priority runtime contract for
  `topdeck_miracle_access`; identity is ready only in the temporary
  simulation, and no verified battle rule or named safe cut exists.
- `Entreat the Angels`: priority runtime contract for
  `miracle_finisher`; identity is ready only in the temporary simulation, and
  miracle/token runtime plus safe-cut proof is still required.
- `Haze of Rage`: combo runtime contract with `Storm-Kiln Artist`, not a
  standalone include; storm/buyback/combat-buff runtime and cut safety are
  both missing.
- `Burning Prophet`: diagnostic runtime/manual-review lane for spell-scry
  pressure; no verified battle rule or named safe cut exists.
- `Inti, Seneschal of the Sun`: diagnostic runtime/manual-review lane for
  discard/exile access; no verified battle rule or named safe cut exists.
- `Karmic Guide`: the only card in this split with a verified auto rule, but
  it is still a `white_reanimator_shell` card and therefore not battle-ready
  as a one-for-one 607 cut.

Full-shell contracts:

- `token_multiplier_shell`: `Anointed Procession` and `Cathars' Crusade`.
  This requires token density and cuts before any battle gate.
- `voltron_equipment_shell`: `Blackblade Reforged`,
  `Excalibur, Sword of Eden`, and `Strata Scythe`. This requires a commander
  damage/equipment shell before any battle gate.
- `white_reanimator_shell`: `Karmic Guide`, `Late to Dinner`,
  `Miraculous Recovery`, and `Storm of Souls`. This requires creature density,
  graveyard setup, recursion targets, and cuts before any battle gate.
- `storm_kiln_haze_combo`: `Storm-Kiln Artist` plus `Haze of Rage`. This
  requires combo runtime and cut safety before any battle gate.

Current conclusion remains unchanged: protected deck `607` is still the
Lorehold champion. The next valid learning step is
`draft_runtime_contracts_for_brain_entreat_haze_before_any_deck_gate`, not a
natural battle, not a shell promotion, and not a direct mutation of `607`.

## Brain/Entreat/Haze Runtime Contract - 2026-07-05

The next learning artifact is:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_entreat_haze_runtime_contract_20260705_current.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_entreat_haze_runtime_contract_20260705_current.json`

It reads the post-identity queue split and local XMage sources under
`/Users/desenvolvimentomobile/Downloads/mage-master` to draft the first runtime
contracts for `Brain in a Jar`, `Entreat the Angels`, and `Haze of Rage`.

Current result:

- status: `runtime_contracts_drafted_no_battle_ready_keep_607`;
- runtime contracts drafted: `3`;
- XMage classes found: `3`;
- cards with active ManaLoom rule rows among these three: `0`;
- battle-ready cards now: `0`;
- best first runtime contract: `Entreat the Angels`;
- natural battle allowed now: `false`;
- promotion allowed: `false`.

XMage evidence:

- `Brain in a Jar`: XMage class includes charge-counter add, exact mana-value
  free-cast from hand, remove-X-charge-counters, and scry. ManaLoom has some
  generic charge-counter/scry surfaces, but no exact-mana-value free-cast
  contract for this card.
- `Entreat the Angels`: XMage class includes `CreateTokenEffect`,
  `AngelToken`, `GetXValue`, and `MiracleAbility`. ManaLoom already has
  miracle and token primitives, so this is the best first runtime candidate.
- `Haze of Rage`: XMage class includes `BuybackAbility`,
  `BoostControlledEffect`, and `StormAbility`. ManaLoom has buyback and some
  storm-copy foundations, but not the global boost storm resolution or the
  full `Storm-Kiln Artist` combo.
- `Storm-Kiln Artist`: XMage class includes `MagecraftAbility`,
  `CreateTokenEffect`, `TreasureToken`, and artifact-count power scaling.
  ManaLoom has one local rule row, but its scope is
  `creature_body_artifact_power_magecraft_treasure_annotation_v1`; the Haze
  combo needs executable treasure on cast/copy, not annotation-only evidence.

Runtime priority:

1. `Entreat the Angels`: implement X-spell miracle/token runtime first because
   it directly tests the protected 607 miracle closing window.
2. `Brain in a Jar`: keep as high-value runtime research, but it needs a new
   charge-counter/free-cast family before battle.
3. `Haze of Rage`: keep as combo research only until storm boost, buyback,
   Storm-Kiln magecraft treasure, loop guard, and cut safety all exist.

Current conclusion remains unchanged: protected deck `607` is still the
Lorehold champion. The next valid learning step is
`prepare_entreat_the_angels_runtime_contract_before_battle`; this is still not
a natural battle gate or deck promotion.

## Entreat X-Token Runtime Primitive - 2026-07-05

The next learning artifact is:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_entreat_x_token_runtime_preflight_20260705_current.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_entreat_x_token_runtime_preflight_20260705_current.json`

It validates the generic runtime foundation needed by `Entreat the Angels`
before any card-rule apply or natural battle gate. The runtime now supports
`token_count_source = x_value`, reads X from the cast/resolution context, and
emits replay evidence for the requested X token count.

Current result:

- status:
  `entreat_x_token_runtime_primitive_ready_rule_still_blocked_keep_607`;
- runtime primitive ready: `true`;
- focused runtime test present: `true`;
- normal `{X}{X}{W}{W}{W}` cast planner coverage: `true`;
- native miracle `{X}{W}{W}` cast planner coverage: `true`;
- active ManaLoom rule rows for `Entreat the Angels`: `0`;
- battle-ready cards now: `0`;
- natural battle allowed now: `false`;
- promotion allowed: `false`;
- source DB mutated: `false`;
- protected deck `607` mutated: `false`.

Test evidence:

- `python3 -m pytest -q docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_entreat_x_token_runtime_preflight.py`
  -> `2 passed`;
- `python3 -m pytest -q docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py -k 'x_create_creature_tokens or x_damage_uses_cast_context'`
  -> `4 passed, 265 deselected`.

Runtime conclusion: ManaLoom can now model an Entreat-style X spell that
creates X 4/4 white Angel creature tokens with flying and can choose X for the
normal `{X}{X}{W}{W}{W}` cost and native miracle `{X}{W}{W}` cost, but this is
still only runtime coverage. The next valid learning step is
`apply_entreat_rule_only_after_pg_precheck_then_run_607_battle_gate`; no natural
battle, cut, shell promotion, or 607 mutation is justified yet.

## Entreat PG472 Auto Rule Package - 2026-07-05

The next learning artifact is:

- `docs/hermes-analysis/master_optimizer_reports/pg472_lorehold_entreat_x_token_rule_20260705_current.md`
- `docs/hermes-analysis/master_optimizer_reports/pg472_lorehold_entreat_x_token_rule_20260705_current.json`
- `docs/hermes-analysis/master_optimizer_reports/pg472_lorehold_entreat_x_token_rule_20260705_current_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg472_lorehold_entreat_x_token_rule_20260705_current_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg472_lorehold_entreat_x_token_rule_20260705_current_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg472_lorehold_entreat_x_token_rule_20260705_current_postcheck.sql`

It prepares the PostgreSQL package for `Entreat the Angels` as `verified` /
`auto`, but does not execute it. The package was generated and tested, not
applied.

Current result:

- status: `auto_rule_package_generated_no_apply_keep_607`;
- PostgreSQL writes executed: `false`;
- source DB mutated: `false`;
- protected deck `607` mutated: `false`;
- proposed effect: `token_maker`;
- proposed scope: `xmage_x_create_creature_tokens_spell_v1`;
- normal cost: `{X}{X}{W}{W}{W}`;
- native miracle cost: `{X}{W}{W}`;
- proposed review status: `verified`;
- proposed execution status: `auto`;
- natural battle allowed now: `false`;
- promotion allowed: `false`.

Rule-source evidence:

- local XMage class `EntreatTheAngels.java` uses `CreateTokenEffect`,
  `AngelToken`, `GetXValue`, and `MiracleAbility`;
- external Oracle surfaces confirm normal cost `{X}{X}{W}{W}{W}` and native
  miracle `{X}{W}{W}`;
- ManaLoom now covers the normal X-token path and native miracle X casting;
  the generated rule marks native miracle runtime as `runtime_executor_v1`.

Test evidence:

- `python3 -m pytest -q docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_entreat_rule_package_preapply.py`
  -> `2 passed`;
- `python3 -m pytest -q docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_entreat_x_token_runtime_preflight.py`
  -> `2 passed`;
- `python3 -m pytest -q docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py -k 'x_create_creature_tokens or x_damage_uses_cast_context'`
  -> `4 passed, 265 deselected`.
- `python3 -m pytest -q docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py`
  -> `269 passed`, `3 subtests passed`;
- `python3 -m pytest -q docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py -k 'miracle or Lorehold or lorehold' docs/hermes-analysis/manaloom-knowledge/scripts/test_lapse_of_certainty_lorehold_runtime.py docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_squee_recursion_priority.py`
  -> `6 passed`, `27 deselected`;
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/deckbuilding_contract_surface_audit.py --out-prefix docs/hermes-analysis/master_optimizer_reports/deckbuilding_contract_surface_audit_20260705_entreat_native_miracle_runtime_current`
  -> `status: pass`;
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_strategy_consistency_audit.py --output-prefix docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260705_entreat_native_miracle_runtime_current`
  -> `status: pass`, `26/26` checks passing.

Current conclusion remains unchanged: protected deck `607` is still the
Lorehold champion. Entreat is not yet a valid battle-gate challenger because
the PostgreSQL rule has not been applied and no natural 607 battle gate has
accepted a named cut.

## Accessibility Layer Matrix - 2026-07-05

The next learning artifact is:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_accessibility_layer_matrix_20260705_current.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_accessibility_layer_matrix_20260705_current.json`

It separates five meanings that must not be collapsed in the app or deckbuilder:
Commander legality, collection ownership, format-staple/Game Changer discovery,
bracket allowance, and protected-607 promotion evidence.

Current result:

- cards reviewed: `2`;
- target bracket: `4`;
- current deck-607 Game Changers detected by policy list: `5`;
- owned cards among reviewed cards: `1`;
- format-staples gaps: `1`;
- promotion-blocked cards: `2`;
- `Mana Vault`: `legal_not_owned_and_promotion_blocked_current_607`;
- `The One Ring`: `legal_owned_but_promotion_blocked_current_607`.

Operational lesson:

- `Mana Vault` is legal, colorless, a Game Changer, and present in
  `format_staples`, but is not in the local collection and remains rejected for
  current 607 promotion after prior equal-gate evidence.
- `The One Ring` is legal, colorless, a Game Changer, and present in the local
  collection, but is missing from the local `format_staples` table and remains
  rejected for current 607 promotion after the value-lane gate.
- Bracket allowance is separate from promotion: bracket `4` allows these Game
  Changers, but the 607 deck change is still blocked by cut/gate evidence.

App/deckbuilder contract note: do not label a card as simply `accessible`
unless the UI or API also states which layer passed: legal, owned,
bracket-allowed, discoverable, or promotion-ready. No card should enter
protected `607` from legality, ownership, or staple rank alone.

## Game Changer Discovery Gap Audit - 2026-07-05

The next learning artifact is:

- `docs/hermes-analysis/master_optimizer_reports/game_changer_discovery_gap_audit_20260705_current.md`
- `docs/hermes-analysis/master_optimizer_reports/game_changer_discovery_gap_audit_20260705_current.json`

It compares the backend bracket-policy Game Changer list with local
`format_staples`, `card_oracle_cache`, Commander legalities, collection, and
deck `607` presence. It is read-only metadata coverage, not a deck-promotion
gate.

Current result:

- status: `game_changer_discovery_gap_found_report_only`;
- Game Changers in policy: `53`;
- local `game_changers` table present: `false`;
- Game Changers present in `format_staples`: `21`;
- Game Changers missing from `format_staples`: `32`;
- Oracle/cache missing: `5`;
- Commander legal rows: `53`;
- Lorehold-legal/color-allowed Game Changers: `21`;
- Lorehold-legal/color-allowed missing from `format_staples`: `12`;
- owned Game Changers: `9`;
- deck-607 Game Changers: `5`.

Lorehold-relevant missing `format_staples` rows include:

- already in protected `607`: `Ancient Tomb` and `Farewell`;
- owned but not in protected `607`: `Drannith Magistrate` and `The One Ring`;
- not owned/currently outside `607`: `Field of the Dead`, `Glacial Chasm`,
  `Grim Monolith`, `Humility`, `Lion's Eye Diamond`, `Mishra's Workshop`,
  `Serra's Sanctum`, and `The Tabernacle at Pendrell Vale`.

Operational lesson:

- `format_staples` is incomplete as a Game Changer discovery source. The
  bracket-policy Game Changer list must be a supplemental discovery lane for
  candidate-source coverage.
- Missing `format_staples` rows should be repaired as metadata/candidate-source
  coverage, not treated as evidence that any missing card belongs in the deck.
- Current `607` remains protected: Game Changer discovery coverage changes
  what the app can explain and queue, but it does not bypass same-lane cut,
  natural battle, Winota/fast-pressure, and card-use gates.

## Mana Foundation And Sequence Relearn - 2026-07-05

The next learning artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_foundation_audit_20260705_current_relearn.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_foundation_audit_20260705_current_relearn.json`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_validator_20260705_current_relearn.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_validator_20260705_current_relearn.json`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_sequence_policy_synthesis_20260705_current_relearn.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_sequence_policy_synthesis_20260705_current_relearn.json`

Current mana-foundation result for protected `607`:

- status: `mana_foundation_pass_with_watch_items`;
- lands: `34`;
- ramp: `15`;
- total mana package including `Land Tax`: `50`;
- early foundation pieces: `8`;
- true early mana pieces: `6`;
- red sources: `24`;
- white sources: `25`;
- blockers: `0`;
- watch items: `colorless_utility_land_pressure`,
  `tapped_land_tempo_pressure`, and
  `late_or_contextual_ramp_should_not_be_counted_as_opening_fixing`.

Current mana-base validator result:

- deck lands: `34` total, `28` unique;
- source counts: `21` red, `22` white, `7` colorless, and `4`
  always-or-conditionally tapped lands under validator heuristics;
- evaluated land swaps: `84`;
- ready swaps: `0`;
- manual review swaps: `4`;
- blocked swaps: `78`.

Current mana-sequence policy result:

- status: `mana_sequence_no_direct_auto_upgrade_current_607`;
- the synthesis now consumes the latest matching report family instead of
  hardcoding `20260704`, so the `20260705` mana foundation evidence is not
  skipped by default;
- current candidate backlog: `50` mana/land/ramp cards;
- `Mana Vault` remains `blocked_prior_gate_rejected`;
- `Grim Monolith`, `City of Traitors`, `Gemstone Caverns`, `Plateau`, `City of
  Brass`, and `Mana Confluence` remain hypotheses requiring a named current
  land/ramp cut plus equal gate, not automatic upgrades;
- `Bender's Waterskin` and `Victory Chimes` remain protected
  turn-cycle-miracle mana, not generic three-mana rocks.

Operational lesson:

- The current `607` mana foundation is not perfect, but it is coherent for the
  Lorehold plan: it balances early Boros access, colorless acceleration, and
  opponent-turn miracle mana.
- Future land/ramp challengers must name the exact sequencing failure they fix
  and the exact current land/ramp slot they cut. Prestige, Game Changer status,
  ownership, or global staple rank is not sufficient.

## Card Value Priority Relearn - 2026-07-05

The next learning artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_card_value_priority_synthesis_20260705_current_relearn.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_card_value_priority_synthesis_20260705_current_relearn.json`

This synthesis converts the current mana, staple, selection, interaction,
payoff, and Game Changer evidence into a deckbuilder-facing priority map for
protected deck `607`. It is read-only: no PostgreSQL writes, no source SQLite
writes, and no mutation of protected deck `607`.

Current result:

- status: `card_value_priority_no_direct_cut_ready_current_607`;
- total cards: `100`;
- evaluated deck rows: `94`;
- ready replacement candidates: `0`;
- role mapping watch cards: `0`;
- candidate pressure rows considered: `173`;
- Game Changer metadata rows considered: `12`.

Source alignment:

- the value synthesis now consumes the latest matching report families instead
  of hardcoding `20260704`, so it picks up the current
  `lorehold_mana_sequence_policy_synthesis_20260705_current_relearn` evidence;
- `game_changer_discovery_gap_audit_20260705_current` is now a supplemental
  discovery source for candidate pressure, but its rows are classified as
  metadata unless separate cut/gate evidence exists;
- current source statuses all keep `607`: mana sequence, staple policy,
  selection/access, interaction/resilience, payoff/finisher/recursion, and
  Game Changer discovery do not produce a direct swap.

Priority lesson:

- `Land Tax`, `Library of Leng`, `Scroll Rack`, and
  `Sensei's Divining Top` remain protected topdeck/miracle access anchors.
- `Bender's Waterskin` and `Victory Chimes` remain protected
  turn-cycle-miracle mana, not generic ramp slots.
- `Creative Technique`, `Mizzix's Mastery`, `Approach of the Second Sun`,
  `Insurrection`, `Storm Herd`, and related finishers remain protected payoff
  or conversion anchors unless a challenger names the same lane and proves the
  tradeoff.
- Interaction and resilience cards such as `Swords to Plowshares`,
  `Path to Exile`, `Generous Gift`, `Deflecting Swat`,
  `Flawless Maneuver`, and `Teferi's Protection` remain floor protection, not
  casual flex slots.

Product/deckbuilder contract:

- Do not collapse legality, ownership, Game Changer status, public staple
  rank, commander-context synergy, and battle promotion into one score.
- A powerful missing card should enter the app as explainable candidate
  pressure first, with its lane, accessibility layer, and blocker displayed.
- A card becomes promotion-ready only after it names the current `607` slot it
  challenges, preserves the protected lane, and passes equal-gate battle/card
  use evidence.
- Current conclusion remains unchanged: protected deck `607` is still the
  Lorehold champion, and the learning task remains open.

## Hypothesis And Promotion Readiness Relearn - 2026-07-05

The next learning artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_hypothesis_queue_from_value_model_20260705_current_relearn.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_hypothesis_queue_from_value_model_20260705_current_relearn.json`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_promotion_readiness_synthesis_20260705_current_relearn.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_promotion_readiness_synthesis_20260705_current_relearn.json`

The hypothesis queue now consumes the current
`lorehold_card_value_priority_synthesis_20260705_current_relearn` report in
addition to the existing value model, miracle-access preflight, and trace
miner. This means candidate hypotheses now carry the current `607` lane
anchors they would have to challenge before any natural battle gate.

Current hypothesis-queue result:

- status: `lorehold_hypothesis_queue_ready_no_natural_gate`;
- hypotheses: `40`;
- natural gate-ready hypotheses: `0`;
- blocked prior rejects: `9`;
- hypotheses needing safe-cut model: `31`;
- hypotheses with same-lane `607` anchors attached: `36`;
- Game Changer metadata rows considered through the value-priority report:
  `12`;
- promotion allowed: `false`.

Current promotion-readiness result:

- status: `promotion_readiness_keep_607_no_candidate_ready`;
- reports loaded: `7/7`;
- unique candidate rows considered: `139`;
- gate-ready candidates: `0`;
- hypotheses needing named cut/gate: `98`;
- blocked/rejected rows: `39`;
- role-mapping watch items: `0`;
- promotion allowed: `false`.

Operational lesson:

- A hypothesis queue is not a battle queue. It is a learning queue until a card
  names the exact current `607` slot and lane it challenges.
- Public Lorehold evidence continues to support multiple shells
  (spellslinger, topdeck, combo, token, burn, Voltron), but each alternate
  direction is a shell contract unless it preserves the current
  miracle/topdeck/protection floor.
- Game Changer, staple rank, variant frequency, and public primer mentions now
  feed candidate pressure, not promotion readiness.
- Current conclusion remains unchanged: protected deck `607` is still the
  Lorehold champion. The next useful step is a safe-cut/diagnostic learning
  step, not a natural promotion gate.

## Diagnostic Contract Planner Relearn - 2026-07-05

The next learning artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_diagnostic_contract_planner_20260705_current_relearn.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_diagnostic_contract_planner_20260705_current_relearn.json`

The diagnostic planner now consumes the current
`lorehold_hypothesis_queue_from_value_model_20260705_current_relearn` queue in
addition to the external reconciliation and shell synthesis reports. This keeps
the next-step planner aligned with the current `607` anchor and safe-cut state.

Current result:

- diagnostics ranked: `8`;
- actionable learning items: `4`;
- ready deck changes: `0`;
- hypothesis-queue card matches: `5`;
- natural gate-ready rows from the hypothesis queue: `0`;
- top diagnostic: `pressure_safe_spell_payoff_micro_shell`;
- recommended next action:
  `draft_pressure_safe_spell_payoff_diagnostic_contract_no_natural_gate`.

Top diagnostic interpretation:

- The pressure-safe spell-payoff route remains the best learning target because
  it addresses the known pressure/closing-window weakness without asking for a
  generic one-for-one cut.
- The current matched hypothesis is `Storm-Kiln Artist`, but it is still a
  prior reject under the current `607` queue and its same-lane anchors include
  protected payoff/topdeck cards such as `Molecule Man`, `Reforge the Soul`,
  and `Call Forth the Tempest`.
- `Monastery Mentor`, `Young Pyromancer`, and `Guttersnipe` are part of the
  pressure package family but are not current natural-gate permissions.
- `Approach + Lapse of Certainty` remains a useful deterministic-line
  diagnostic, but it is telegraphed, depends on the second Approach resolving,
  and has no seed-safe named cut.
- Fast-mana, One Ring, Brainstone/Planetarium, and broad conversion shells
  remain blocked, deferred, or separate-shell work under the current evidence.

Operational lesson:

- A planner can rank learning value without authorizing deck mutation.
- The next implementable step is to draft a pressure-safe diagnostic contract
  that predeclares protected anchors, pressure/Winota guardrails, direct card
  events required, and stop rules. It must not run a natural battle gate until
  the contract has a named shell/cut model and the current preflight moves from
  `0` gate-ready rows.
- Current conclusion remains unchanged: protected deck `607` is still the
  Lorehold champion, and this goal remains open.

## Pressure-Safe Spell-Payoff Contract Relearn - 2026-07-05

The next learning artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_pressure_safe_spell_payoff_contract_20260705_current_relearn.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_pressure_safe_spell_payoff_contract_20260705_current_relearn.json`
- `docs/hermes-analysis/master_optimizer_reports/deckbuilding_contract_surface_audit_20260705_pressure_safe_spell_contract_current.md`
- `docs/hermes-analysis/master_optimizer_reports/deckbuilding_contract_surface_audit_20260705_pressure_safe_spell_contract_current.json`

The pressure-safe contract now consumes the current
`lorehold_hypothesis_queue_from_value_model_20260705_current_relearn` queue
instead of treating local card preflight as enough to authorize a battle. This
keeps four separate states visible: local card/runtime readiness, hypothesis
queue readiness, cut safety, and natural battle permission.

Current result:

- decision status: `preflight_pass_cut_pool_required`;
- diagnostic contract status:
  `pressure_safe_diagnostic_contract_ready_no_battle`;
- diagnostic only: `true`;
- ready deck changes: `0`;
- promotion allowed now: `false`;
- natural battle gate allowed now: `false`;
- natural gate-ready rows from the hypothesis queue: `0`;
- primary pressure package size: `4`;
- primary pressure cards matched in current hypothesis queue: `1`;
- primary pressure cards missing from current hypothesis queue: `3`;
- current matched card: `Storm-Kiln Artist`;
- current missing queue cards: `Monastery Mentor`, `Young Pyromancer`, and
  `Guttersnipe`;
- required named cuts before a legal pressure variant: `4`;
- protected `607` anchors tracked by the contract: `12`;
- deckbuilding contract surface audit: `pass`.

The pressure cards passed local card preflight:

- `Monastery Mentor`: Commander legal, local oracle present, verified auto rule
  present, not in `607`;
- `Young Pyromancer`: Commander legal, local oracle present, verified auto rule
  present, not in `607`;
- `Guttersnipe`: Commander legal, local oracle present, verified auto rule
  present, not in `607`;
- `Storm-Kiln Artist`: Commander legal, local oracle present, verified auto rule
  present, not in `607`.

That pass is not promotion. The current queue still says:

- `Storm-Kiln Artist` is `blocked_prior_reject`, with protected same-lane
  anchors including `Molecule Man`, `Reforge the Soul`,
  `Call Forth the Tempest`, `Hit the Mother Lode`, and
  `Creative Technique`;
- `Monastery Mentor`, `Young Pyromancer`, and `Guttersnipe` require queue/cut
  modeling before they can become natural-gate candidates;
- no natural battle can run while the current queue has `0` gate-ready rows.

Hard stop rules now recorded in the contract:

- stop if a natural battle is requested while the hypothesis queue has `0`
  natural gate-ready candidates;
- stop if a cut plan uses `Molecule Man`, `Bender's Waterskin`,
  `Creative Technique`, or another protected anchor as a generic cut;
- stop if `Storm-Kiln Artist` is retested as a generic `Arcane Signet` or
  `Bender's Waterskin` replacement without a new trace hypothesis;
- stop if the test plan omits Winota/fast-pressure regression checks;
- stop if card-level claims are made without direct draw/cast/trigger/use
  events for the pressure cards.

Accessibility clarification for `Mana Vault` and `The One Ring`:

- `Mana Vault` is Commander legal, colorless, bracket-allowed, a Game Changer,
  and present in `format_staples`, but the local collection layer reports
  `owned=false` and the current `607` promotion layer remains
  `blocked_prior_gate_rejected`.
- `The One Ring` is Commander legal, colorless, bracket-allowed, a Game
  Changer, and owned locally, but it is missing from local `format_staples` and
  the current `607` promotion layer remains
  `blocked_existing_package_rejected` after direct card-use evidence.
- Therefore neither card is "inaccessible to Lorehold" by legality. They are
  inaccessible as automatic protected-`607` changes under the current app/deck
  promotion contract.

Operational lesson:

- A local runtime pass tells us a card can be tested; it does not say a card
  improves the deck.
- The next useful implementation is a pressure-safe cut-pool resolver that
  names four legal cuts without touching protected anchors, then a structure
  matrix. Natural battle remains closed until that preflight changes.
- Current conclusion remains unchanged: protected deck `607` is still the
  Lorehold champion, and this persistent learning goal remains open.

## Pressure-Safe Cut-Pool Resolver Relearn - 2026-07-05

The next learning artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_pressure_safe_cut_pool_resolver_20260705_current_relearn.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_pressure_safe_cut_pool_resolver_20260705_current_relearn.json`

The cut-pool resolver now consumes the current pressure-safe spell-payoff
contract. It also tightens diagnostic eligibility: a four-cut diagnostic plan
cannot use cards marked as structural dependencies, miracle/finisher core,
protected anchors, prior rejects, high-exposure cards, mana-base cards,
early-mana floor cards, or protection-shell cards.

Current result:

- decision status: `no_seed_safe_cut_plan_no_diagnostic_tradeoff_current_607`;
- primary pressure adds considered: `4`;
- gate-ready cut count: `0`;
- gate-ready plan complete: `false`;
- diagnostic tradeoff plan available: `false`;
- ready deck changes: `0`;
- promotion allowed now: `false`;
- natural battle gate allowed now: `false`;
- contract natural gate-ready rows from hypothesis queue: `0`;
- contract blocks natural gate: `true`;
- recommended next action:
  `build_smaller_pressure_package_or_new_cut_safety_model_before_any_battle`.

Primary pressure adds checked by the resolver:

- `Monastery Mentor`;
- `Young Pyromancer`;
- `Guttersnipe`;
- `Storm-Kiln Artist`.

Why no four-card pressure variant exists now:

- the seed-safe cut report has `0` gate-ready cuts;
- the previous loose diagnostic-only four-cut plan depended on structurally
  blocked cards such as miracle/finisher core slots;
- current blockers include `cut_is_miracle_core_big_spell=25`,
  `miracle_or_finisher_core=24`, `structural_dependency=24`,
  `protected_cut=22`, `measured_high_cut_exposure=34`,
  `prior_rejected_cut=37`, `mana_base_never_cut=28`, and
  `early_mana_floor_support=18`;
- therefore a four-card pressure package cannot be turned into a legal
  promotion candidate or even a clean diagnostic variant under the current
  protected-`607` contract.

Operational lesson:

- Preflight-ready pressure payoffs are not enough. The add side and cut side
  must both be valid.
- The current four-card pressure package is too expensive for the protected
  `607` shell because it needs four cuts and the current shell has zero
  safe/reviewable noncore cut slots.
- The next learning step must be smaller or deeper: either evaluate a one- or
  two-card pressure package with a new cut-safety model, or build a separate
  full-shell contract that preserves the `607` mana, topdeck, miracle,
  protection, and fast-pressure floors before any battle.
- Current conclusion remains unchanged: protected deck `607` is still the
  Lorehold champion, and this persistent learning goal remains open.

## Pressure Package Size Router Relearn - 2026-07-05

The next learning artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_pressure_package_size_router_20260705_current_relearn.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_pressure_package_size_router_20260705_current_relearn.json`

This router tests whether the pressure lesson from Monastery Mentor, Young
Pyromancer, Guttersnipe, and Storm-Kiln Artist becomes usable when reduced from
the failed four-card package to smaller one-card or two-card packages.

Current result:

- decision status: `smaller_pressure_packages_blocked_current_607`;
- packages evaluated: `10`;
- singleton packages: `4`;
- pair packages: `6`;
- gate-ready packages: `0`;
- diagnostic-only packages: `0`;
- gate-ready cut count: `0`;
- diagnostic cut count: `0`;
- hypothesis natural gate-ready count: `0`;
- ready deck changes: `0`;
- promotion allowed now: `false`;
- natural battle gate allowed now: `false`;
- best singleton learning package:
  `pressure_1_card_young_pyromancer`;
- recommended next action:
  `build_single_card_cut_safety_model_or_non_deck_forced_diagnostic`.

External learning used by the router:

- GameTyrant's Lorehold deck tech treats Monastery Mentor and Young Pyromancer
  as spell-chain body conversion, Guttersnipe as noncombat spell pressure, and
  Storm-Kiln Artist as Treasure conversion.
- EDHREC's current Lorehold core spellslinger surface keeps the public build
  lane tied to topdeck, spellslinger, discard, and reanimator tags.
- Draftsim's Lorehold guide reinforces that miracle setup and topdeck
  manipulation remain core value axes, so pressure payoffs cannot be accepted
  if they dilute those engines.

Operational lesson:

- Smaller package size reduces add pressure, but it does not create valid cuts
  by itself.
- Young Pyromancer is now the best singleton learning candidate, but only for
  cut-safety modeling or non-deck forced diagnostics; it is not a live 607
  mutation.
- Guttersnipe and Monastery Mentor remain useful pressure lessons, but they
  need current hypothesis rows and safe cuts before any natural gate.
- Storm-Kiln Artist remains blocked by prior rejection and should not be
  retried as an automatic mana-pressure swap.
- Current conclusion remains unchanged: protected deck `607` is still the
  Lorehold champion, and this persistent learning goal remains open.

## Young Pyromancer Singleton Cut-Safety Relearn - 2026-07-05

The next learning artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_young_pyromancer_singleton_cut_safety_model_20260705_current_relearn.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_young_pyromancer_singleton_cut_safety_model_20260705_current_relearn.json`

This model narrows the previous package-size router to the best singleton
learning candidate: `Young Pyromancer`.

Current result:

- decision status: `young_pyromancer_singleton_no_cut_keep_607`;
- target package: `pressure_1_card_young_pyromancer`;
- package status: `blocked_no_cut_or_hypothesis_capacity`;
- evaluated cut slots: `94`;
- eligible cuts: `0`;
- pressure-lane evidence gaps: `0`;
- pressure-lane hard-blocked slots: `1`;
- seed-safe cut count: `0`;
- reviewable evidence gap count: `0`;
- ready deck changes: `0`;
- promotion allowed now: `false`;
- natural battle gate allowed now: `false`;
- recommended next action:
  `mine_pressure_lane_cut_evidence_or_non_deck_forced_diagnostic`.

Why this still cannot mutate `607`:

- `Young Pyromancer` passes identity/runtime preflight and is legal in
  Lorehold, but it remains missing from the current natural-gate hypothesis
  queue.
- The card's value lane is low-curve token pressure from instant/sorcery
  chains. It cannot use generic cuts from mana, topdeck, miracle, protection,
  removal, or draw just because it is a good spellslinger card.
- Current 607 cut evidence has no seed-safe pressure-compatible cut.
- The only pressure/contextual slot surfaced by current cut rows is still
  hard-blocked by protected/prior-reject evidence, so there is no legal
  singleton package to send into a natural battle gate.

External learning used by the model:

- EDHREC's current Lorehold core spellslinger page keeps the public shell tied
  to topdeck, spellslinger, discard, and reanimator tags.
- GameTyrant's Lorehold deck tech treats Young Pyromancer as spell-chain body
  conversion, not as a replacement for ramp, removal, draw, or miracle engines.
- Draftsim's spellslinger overview reinforces that token-pressure is only one
  branch of spellslinger deckbuilding; it must fit the commander shell instead
  of overriding it.

Operational lesson:

- `Young Pyromancer` is now a real learning target, but not a 607 add.
- A pressure singleton still needs one named cut in a compatible pressure lane,
  plus structure matrix, equal battle gate, and direct card-use evidence.
- The next useful work is pressure-window trace mining or a non-deck forced
  diagnostic to learn whether the token-pressure branch repairs a real failure.
- Current conclusion remains unchanged: protected deck `607` is still the
  Lorehold champion, and this persistent learning goal remains open.

## Young Pyromancer Pressure-Window Trace Synthesis - 2026-07-05

The next learning artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_young_pyromancer_pressure_window_trace_synthesis_20260705_current_relearn.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_young_pyromancer_pressure_window_trace_synthesis_20260705_current_relearn.json`

This synthesis crosses the Young Pyromancer singleton cut-safety model with the
current spell-pressure trace, closing-window trace, and miracle-trace failure
miner. It asks whether the best pressure singleton actually repairs a real 607
pressure-window failure mode.

Current result:

- decision status:
  `young_pyromancer_pressure_window_refuted_no_deck_action`;
- target card: `Young Pyromancer`;
- target singleton status: `young_pyromancer_singleton_no_cut_keep_607`;
- target package status: `blocked_no_cut_or_hypothesis_capacity`;
- eligible cuts: `0`;
- seed-safe cuts: `0`;
- wins with pressure-card events: `0`;
- losses with pressure-card events: `1`;
- Young Pyromancer seen only in losses: `true`;
- pressure trace status: `pressure_trace_refutes_pressure_causality`;
- closing-window comparisons consumed: `13`;
- average 607 turn advantage in those comparisons: `10.15`;
- miracle trace failure flags: `7`;
- ready deck changes: `0`;
- promotion allowed now: `false`;
- natural battle gate allowed now: `false`;
- recommended next action:
  `deprioritize_young_pyromancer_until_new_pressure_cut_or_forced_diagnostic`.

Why this matters:

- The current spell-pressure shell did not win because of Young Pyromancer. Its
  only candidate win had no pressure-card events and was carried by the protected
  topdeck/miracle engine.
- Young Pyromancer appeared only in losses in the current pressure trace, so it
  is not positive card-level proof.
- Closing-window failures are dominated by miracle, topdeck, spell-volume,
  mana-timing, and Approach-conversion deficits. Young Pyromancer only
  theoretically helps the "died before closing window" pressure body problem;
  it does not directly repair the engine deficits that separate 607 wins from
  rejected shell losses.
- Therefore the token-pressure branch is not a natural 607 gate path now.

Operational lesson:

- Young Pyromancer remains legal and runtime-preflighted, but it is no longer
  the next natural deck-action candidate.
- If learning continues on Young Pyromancer, it must be a non-deck forced
  diagnostic only, tracking token creation and pressure absorption while also
  preserving miracle, topdeck, and Lorehold spell-cast floors.
- The next deckbuilding priority should favor engine-preserving pressure or
  conversion routes over broad token-pressure shells.
- Current conclusion remains unchanged: protected deck `607` is still the
  Lorehold champion, and this persistent learning goal remains open.

## Engine-Preserving Pressure Conversion Router - 2026-07-05

The next learning artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_engine_preserving_pressure_conversion_router_20260705_current_relearn.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_engine_preserving_pressure_conversion_router_20260705_current_relearn.json`

This router translates the external deckbuilding lesson from Guttersnipe and
Storm-Kiln Artist into the current protected-`607` contract. The purpose is to
avoid two bad loops: adding a public staple just because it is popular, or
retesting Storm-Kiln as the already-rejected `Arcane Signet` swap.

Current result:

- decision status:
  `engine_preserving_pressure_conversion_not_gate_ready_keep_607`;
- routes evaluated: `3`;
- gate-ready routes: `0`;
- diagnostic-ready routes: `0`;
- gate-ready cut count: `0`;
- diagnostic cut count: `0`;
- hypothesis natural gate-ready count: `0`;
- wins with pressure-card events: `0`;
- losses with pressure-card events: `1`;
- miracle trace failure flags: `7`;
- Storm-Kiln prior decision:
  `rejected_for_deck_promotion_pressure_regression`;
- best next learning route:
  `guttersnipe_storm_kiln_engine_preserving_pair`;
- best next learning status:
  `best_next_learning_route_contract_required_no_deck_action`;
- ready deck changes: `0`;
- promotion allowed now: `false`;
- natural battle gate allowed now: `false`;
- recommended next action:
  `build_engine_preserving_hypothesis_contract_and_find_named_safe_cuts`.

Route-level conclusion:

- `Guttersnipe` is the cleaner noncombat pressure lesson, but it is missing
  current hypothesis readiness and has no positive current pressure trace.
- `Storm-Kiln Artist` has real Treasure-conversion evidence, but its direct
  `Arcane Signet` swap is still rejected because the Winota fast-pressure slice
  regressed.
- `Guttersnipe + Storm-Kiln Artist` is now the best next learning route because
  it converts spell volume into both pressure and mana while preserving the
  lesson from the Young Pyromancer refutation. It is not a deck action until
  two named seed-safe same-lane cuts exist and the package protects the 607
  topdeck, miracle, spell-volume, mana-timing, protection, and fast-pressure
  floors.

External learning used by the router:

- EDHREC's current Lorehold core spellslinger surface keeps the public shell
  tied to topdeck, spellslinger, discard, and reanimator lanes.
- Commander Spellbook shows that Storm-Kiln can be a real combo/conversion
  engine with storm/copy chains, so it should be treated as a conversion card,
  not generic ramp.
- GameTyrant's Lorehold deck tech treats Guttersnipe as direct spell damage
  and Storm-Kiln as big-turn Treasure support, but both remain secondary to the
  deck's topdeck/miracle engine.

Operational lesson:

- External value is priority, not permission.
- Do not repeat the Storm-Kiln / Arcane Signet swap.
- Do not return to broad token-pressure shells after the Young Pyromancer trace
  was refuted.
- The next useful work is a written engine-preserving hypothesis contract for
  Guttersnipe + Storm-Kiln, with direct event requirements and named safe cuts
  before any natural battle gate.
- Current conclusion remains unchanged: protected deck `607` is still the
  Lorehold champion, and this persistent learning goal remains open.

## Guttersnipe + Storm-Kiln Hypothesis Contract - 2026-07-05

The next learning artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_guttersnipe_storm_kiln_hypothesis_contract_20260705_current_relearn.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_guttersnipe_storm_kiln_hypothesis_contract_20260705_current_relearn.json`

This contract formalizes the best engine-preserving pressure/conversion route
from the router: `Guttersnipe + Storm-Kiln Artist`.

Current result:

- decision status:
  `hypothesis_contract_written_blocked_no_named_safe_cuts`;
- target route:
  `guttersnipe_storm_kiln_engine_preserving_pair`;
- target adds:
  `Guttersnipe`, `Storm-Kiln Artist`;
- required cuts: `2`;
- available named seed-safe cuts: `0`;
- cut shortage: `2`;
- hard-blocked cut slots: `92`;
- same-lane-only cut slots: `2`;
- closing-window comparisons consumed: `13`;
- average 607 turn advantage in those comparisons: `10.15`;
- miracle trace failure flags: `7`;
- package status:
  `blocked_no_cut_or_hypothesis_capacity`;
- ready deck changes: `0`;
- promotion allowed now: `false`;
- natural battle gate allowed now: `false`;
- structure matrix allowed now: `false`;
- recommended next action:
  `mine_or_create_cut_evidence_for_two_named_same_lane_nonanchor_slots`.

Direct event requirements for any future test:

- `Guttersnipe` must show direct instant/sorcery-triggered opponent damage in a
  candidate win or protected equal-gate game.
- `Storm-Kiln Artist` must show `trigger_resolved` and `treasure_created`
  events that connect to spell-chain or survival value.
- A win carried only by existing 607 topdeck/miracle cards is not proof for the
  new cards.

Engine floor requirements:

- same-seed, same-opponent matrix against protected `607`;
- no Winota fast-pressure regression;
- no miracle-cast or topdeck-manipulation regression;
- no Lorehold spell-cast or upkeep-rummage regression;
- early mana floor and protection shell preserved;
- Approach conversion preserved or replaced by an explicitly proven win path.

Cut conclusion:

- There are no named seed-safe cuts for this pair now.
- `Creative Technique` and `Bender's Waterskin` remain same-lane-only/not
  seed-safe, not free cuts.
- Commander, mana base, early mana, protection, topdeck/miracle setup,
  miracle/finisher core, high-exposure cards, prior rejected cuts, structural
  dependencies, and protected anchors remain hard-stop cut classes.

Operational lesson:

- The pair is the right next hypothesis to learn from, but the deck is not
  legally actionable until two named non-anchor cuts exist.
- No natural battle should be run for this package yet, because a battle without
  legal cuts would only test a fantasy list.
- Current conclusion remains unchanged: protected deck `607` is still the
  Lorehold champion, and this persistent learning goal remains open.

## Engine-Preserving Cut Evidence Miner - 2026-07-05

The next learning artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_engine_preserving_cut_evidence_miner_20260705_current_relearn.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_engine_preserving_cut_evidence_miner_20260705_current_relearn.json`

This miner attacks the exact blocker left by the Guttersnipe + Storm-Kiln
contract: the package needs two named seed-safe cuts before structure matrix or
natural battle can begin.

Current result:

- decision status:
  `no_current_cut_evidence_for_guttersnipe_storm_kiln_keep_607`;
- target route:
  `guttersnipe_storm_kiln_engine_preserving_pair`;
- target adds:
  `Guttersnipe`, `Storm-Kiln Artist`;
- required cuts: `2`;
- named seed-safe cuts: `0`;
- cut shortage: `2`;
- target-lane evidence gaps: `0`;
- total cut slots reviewed: `94`;
- hard-stop cut slots: `94`;
- cross-lane excluded slots: `0`;
- ready deck changes: `0`;
- promotion allowed now: `false`;
- natural battle gate allowed now: `false`;
- recommended next action:
  `do_not_battle_mine_new_nonanchor_trace_or_new_shell_contract`.

Key blocker counts from the current 607 cut surface:

- `mana_base_never_cut`: `28`;
- `never_cut_lane`: `29`;
- `never_cut_or_mana_base`: `29`;
- `cut_is_miracle_core_big_spell`: `25`;
- `miracle_or_finisher_core`: `24`;
- `structural_dependency`: `24`;
- `protected_cut`: `22`;
- `prior_rejected_cut`: `37`;
- `measured_high_cut_exposure`: `34`;
- `early_mana_floor_support`: `18`;
- `cut_is_protection_shell`: `14`;
- `protection_shell`: `14`.

Cut-search conclusion:

- There is no current 607 cut slot that can feed the Guttersnipe + Storm-Kiln
  package.
- There is also no target-lane soft evidence gap to promote into a cut-safety
  candidate now.
- `Creative Technique`, `Bender's Waterskin`, removal staples, draw/selection
  anchors, mana cards, lands, protection cards, and finisher/miracle cards
  remain closed for this package under the current evidence.

Operational lesson:

- The package remains valuable as a learning direction, but not as a mutation
  of the current `607` list.
- The next useful work is not a battle; it is either new non-anchor trace
  mining that discovers a real low-exposure target-lane cut, or a separate
  shell contract that deliberately changes the role profile and starts from
  structure validation.
- Current conclusion remains unchanged: protected deck `607` is still the
  Lorehold champion, and this persistent learning goal remains open.

## From-Scratch Shell Failure Synthesis Relearn - 2026-07-05

The next learning artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_shell_failure_synthesis_20260705_current_relearn.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_shell_failure_synthesis_20260705_current_relearn.json`

This synthesis rechecks whether the "no cut inside 607" finding should route
immediately into another from-scratch shell attempt.

Current result:

- tested shell count: `3`;
- gate rows reviewed: `4`;
- natural gate rows: `3`;
- forced-access diagnostic rows: `1`;
- promotable shell signals: `0`;
- best natural delta wins: `-1`;
- best forced delta wins: `-1`;
- status counts:
  `forced_access_rejected=1`, `natural_rejected=3`;
- recommended next action:
  `mine_closing_window_trace_before_next_shell`;
- can run next battle gate: `false`.

Failure modes observed:

- `wins_below_protected_607`: `4`;
- `losses_above_protected_607`: `4`;
- `package_lanes_overfilled`: `4`;
- `upkeep_rummage_floor_regressed`: `4`;
- `positive_squee_telemetry_not_converting`: `3`;
- `miracle_floor_regressed`: `2`;
- `topdeck_floor_regressed`: `2`;
- `lorehold_spell_floor_regressed`: `2`;
- `forced_access_no_conversion`: `1`.

Operational lesson:

- A separate shell is allowed only after a predeclared trace target; broad
  from-scratch attempts have already failed below protected `607`.
- Forced-access evidence can prove cards were seen or used, but it did not
  convert into wins in the current evidence and cannot promote a shell.
- The next valid shell work must start from closing-window trace differences
  and preserve miracle, topdeck, upkeep-rummage, and spell-floor metrics.
- Current conclusion remains unchanged: protected deck `607` is still the
  Lorehold champion, and this persistent learning goal remains open.

## Closing-Window Next Shell Target Router - 2026-07-05

The next learning artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_closing_window_next_shell_target_router_20260705_current_relearn.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_closing_window_next_shell_target_router_20260705_current_relearn.json`

This router combines the closing-window trace, failed from-scratch shell
synthesis, cut-evidence miner, and miracle-trace failure miner. It decides what
the next shell contract should target before any new structure matrix or battle.

Current result:

- decision status:
  `closing_window_shell_target_selected_no_battle`;
- selected hypothesis:
  `preserve_topdeck_miracle_floor_micro_package`;
- selected status:
  `primary_shell_contract_target_blocked_but_actionable_as_design`;
- candidate hypotheses: `3`;
- closing-window comparisons: `13`;
- average 607 turn advantage: `10.15`;
- ready micro-package hypotheses from the closing trace: `3`;
- from-scratch promotable shell signals: `0`;
- from-scratch next battle gate allowed: `false`;
- named seed-safe cuts: `0`;
- cut shortage: `2`;
- miracle failure flags: `7`;
- ready deck changes: `0`;
- promotion allowed now: `false`;
- natural battle gate allowed now: `false`;
- recommended next action:
  `write_miracle_access_first_shell_contract_no_battle`.

Selected shell contract:

- contract key: `miracle_access_first_shell_contract`;
- shell type: `micro_shell_before_full_generation`;
- must preserve:
  `Sensei's Divining Top`, `Scroll Rack`, `Bender's Waterskin`,
  `Victory Chimes`, and `Approach of the Second Sun`;
- target metrics:
  `miracle_cast`, `topdeck_manipulation_activated`,
  `lorehold_spell_cast`, `lorehold_upkeep_rummage`, and
  `static_cost_reduction_total`.

Routing conclusion:

- Pressure survival and Guttersnipe/Storm-Kiln remain downstream diagnostic
  ideas, not the next shell, because the engine floor is still unproven.
- The next shell cannot be broad from-scratch, because the failed-shell
  synthesis already showed broad shells below protected `607`.
- The next valid work is to write the miracle-access-first shell contract with
  no battle, no deck mutation, and predeclared metric floors.
- Current conclusion remains unchanged: protected deck `607` is still the
  Lorehold champion, and this persistent learning goal remains open.

## Miracle Access First Shell Contract - 2026-07-05

The next learning artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_access_first_shell_contract_20260705_current_relearn.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_access_first_shell_contract_20260705_current_relearn.json`
- `docs/hermes-analysis/master_optimizer_reports/deckbuilding_contract_surface_audit_20260705_miracle_access_first_shell_contract_current.md`
- `docs/hermes-analysis/master_optimizer_reports/deckbuilding_contract_surface_audit_20260705_miracle_access_first_shell_contract_current.json`

This contract converts the router result into a pre-deck gate for the next
Lorehold shell. It does not generate a deck, mutate deck `607`, write
PostgreSQL or SQLite, or allow a battle gate.

Current result:

- decision status:
  `miracle_access_first_contract_written_no_battle_blocked_before_structure_matrix`;
- selected hypothesis:
  `preserve_topdeck_miracle_floor_micro_package`;
- selected contract:
  `miracle_access_first_shell_contract`;
- structure matrix contract allowed now: `true`;
- structure matrix allowed now: `false`;
- natural battle gate allowed now: `false`;
- promotion allowed now: `false`;
- named seed-safe cuts: `0`;
- cut shortage: `2`;
- preflight candidates ready now: `0`;
- from-scratch promotable shell signals: `0`;
- aggregate blockers: `28`;
- recommended next action:
  `design_micro_shell_structure_matrix_contract_no_battle`.

Protected anchors for the next miracle-access shell:

- `Approach of the Second Sun`;
- `Bender's Waterskin`;
- `Creative Technique`;
- `Land Tax`;
- `Library of Leng`;
- `Lorehold, the Historian`;
- `Mizzix's Mastery`;
- `Molecule Man`;
- `Scroll Rack`;
- `Sensei's Divining Top`;
- `Storm Herd`;
- `The Mind Stone`;
- `The Scarlet Witch`;
- `Victory Chimes`.

Predeclared floor requirements:

- `miracle_cast` must meet or exceed the current `607` same-seed floor;
- `topdeck_manipulation_activated` must meet or exceed the current `607`
  same-seed floor;
- `lorehold_spell_cast` must meet or exceed the current `607` same-seed floor;
- `lorehold_upkeep_rummage` must meet or exceed the current `607` same-seed
  floor;
- `static_cost_reduction_total` must not regress in closing-window trace;
- `approach_conversion` must not disappear from candidate closing windows.

External research absorbed into the contract:

- Wizards Commander format remains the legality, singleton, color identity,
  and bracket framing source.
- EDHREC Lorehold evidence is useful as an evidence lane, but it does not
  override protected `607` trace floors or cut safety.
- Lorehold-specific public articles reinforce the same local lesson: the deck
  must first preserve opponent-upkeep first-draw miracle windows, topdeck
  manipulation, instant/sorcery density, protection, and mana available on
  opponents' turns.
- Commander Spellbook remains combo/package discovery evidence, not full-deck
  balance or runtime proof.

Operational lesson:

- Pressure routes, forced-access diagnostics, broad from-scratch shells, and
  global staples such as `Mana Vault` or `The One Ring` remain blocked as
  shortcuts until the miracle/topdeck floor survives a structure matrix and
  later equal battle gate.
- A clean synthetic case would only allow the structure matrix; it would still
  not allow battle, promotion, or mutation.
- Current conclusion remains unchanged: protected deck `607` is still the
  Lorehold champion, and this persistent learning goal remains open.

## Miracle Access Structure Matrix Contract - 2026-07-05

The next learning artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_access_structure_matrix_contract_20260705_current_relearn.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_access_structure_matrix_contract_20260705_current_relearn.json`
- `docs/hermes-analysis/master_optimizer_reports/deckbuilding_contract_surface_audit_20260705_miracle_access_structure_matrix_current.md`
- `docs/hermes-analysis/master_optimizer_reports/deckbuilding_contract_surface_audit_20260705_miracle_access_structure_matrix_current.json`

This matrix is the first scoring surface after the miracle-access-first
contract. It defines how a future candidate row will be scored, but it still
does not generate a deck, mutate deck `607`, write a database, or run battle.

Current result:

- decision status:
  `miracle_access_structure_matrix_template_ready_no_candidate_no_battle`;
- selected contract:
  `miracle_access_first_shell_contract`;
- matrix cells: `6`;
- candidate rows: `0`;
- matrix scoring allowed now: `false`;
- candidate deck materialization allowed now: `false`;
- natural battle gate allowed now: `false`;
- promotion allowed now: `false`;
- named seed-safe cuts: `0`;
- cut shortage: `2`;
- aggregate contract blockers: `28`;
- blocking hard gates: `3`;
- current `607` value-model facts carried into the matrix:
  quantity total `100`, lands `34`, ramp `15`;
- recommended next action:
  `declare_candidate_rows_with_named_same_lane_cuts_before_scoring`.

Matrix cells and weights:

- `topdeck_miracle_access`: weight `30`, metrics `miracle_cast` and
  `topdeck_manipulation_activated`;
- `turn_cycle_miracle_mana`: weight `20`, metrics
  `static_cost_reduction_total` and `lorehold_cost_paid`;
- `spell_volume_density`: weight `15`, metric `lorehold_spell_cast`;
- `approach_finisher_conversion`: weight `15`, metrics `approach_conversion`
  and `miracle_cast:Approach of the Second Sun`;
- `pressure_survival_floor`: weight `10`, Winota/closing-window survival;
- `same_lane_cut_safety`: weight `25`, named same-lane cuts and cut shortage.

Hard gates currently blocking matrix scoring:

- `candidate_rows_declared`;
- `named_same_lane_cuts_exist`;
- `aggregate_blockers_cleared_or_explained`.

Candidate-row schema required before scoring:

- `candidate_key`;
- `add_card`;
- `cut_card`;
- `lane`;
- `same_lane_cut_reason`;
- `protected_anchor_impact`;
- `expected_metric_lift`;
- `rule_runtime_status`;
- `source_provenance`;
- `floor_risk`.

Operational lesson:

- The project now has a real ranking rubric for miracle-access-first learning,
  but the rubric cannot create truth by itself.
- No deck can be materialized from this template alone; a future candidate must
  name adds and same-lane cuts first.
- Current conclusion remains unchanged: protected deck `607` is still the
  Lorehold champion, and this persistent learning goal remains open.

## Miracle Access Candidate Row Queue - 2026-07-05

The next learning artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_access_candidate_row_queue_20260705_current_relearn.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_access_candidate_row_queue_20260705_current_relearn.json`
- `docs/hermes-analysis/master_optimizer_reports/deckbuilding_contract_surface_audit_20260705_miracle_access_candidate_row_queue_current.md`
- `docs/hermes-analysis/master_optimizer_reports/deckbuilding_contract_surface_audit_20260705_miracle_access_candidate_row_queue_current.json`

This queue attempts to convert post-identity external/internal candidates into
the candidate-row schema required by the miracle-access matrix. It is still
read-only and does not generate or mutate any deck.

Current result:

- decision status:
  `miracle_access_candidate_row_queue_blocked_no_scoreable_rows_keep_607`;
- source candidates considered: `5`;
- scoreable candidate rows: `0`;
- blocked candidate rows: `5`;
- named seed-safe cuts: `0`;
- matrix contract blocker count: `28`;
- matrix scoring allowed now: `false`;
- candidate deck materialization allowed now: `false`;
- natural battle gate allowed now: `false`;
- promotion allowed now: `false`;
- recommended next action:
  `resolve_runtime_and_named_same_lane_cut_before_matrix_scoring`.

Blocked candidate rows:

- `Brain in a Jar`: lane `topdeck_miracle_access`, matrix cells
  `topdeck_miracle_access` and `turn_cycle_miracle_mana`, blockers
  `verified_battle_rule_missing`, `named_safe_cut_missing`, and
  `matrix_contract_blockers_not_cleared`;
- `Entreat the Angels`: lane `miracle_finisher`, matrix cells
  `approach_finisher_conversion` and `topdeck_miracle_access`, blockers
  `verified_battle_rule_missing`, `named_safe_cut_missing`, and
  `matrix_contract_blockers_not_cleared`;
- `Haze of Rage`: lane `storm_combo_pressure`, matrix cell
  `pressure_survival_floor`, blockers `combo_runtime_required`,
  `verified_battle_rule_missing`, `named_safe_cut_missing`, and
  `matrix_contract_blockers_not_cleared`;
- `Burning Prophet`: lane `spell_scry_pressure`, matrix cells
  `spell_volume_density` and `pressure_survival_floor`, blockers
  `verified_battle_rule_missing`, `named_safe_cut_missing`, and
  `matrix_contract_blockers_not_cleared`;
- `Inti, Seneschal of the Sun`: lane `rummage_pressure_access`, matrix cells
  `topdeck_miracle_access` and `pressure_survival_floor`, blockers
  `verified_battle_rule_missing`, `named_safe_cut_missing`, and
  `matrix_contract_blockers_not_cleared`.

Operational lesson:

- The strongest current topdeck/miracle additions are visible, but none can
  score yet because the project lacks both verified runtime and named same-lane
  cuts for them.
- The next practical work is not another shell or battle. It is either runtime
  contract work for the top-priority cards or a named same-lane non-anchor cut
  discovery path that clears the matrix hard gates.
- Current conclusion remains unchanged: protected deck `607` is still the
  Lorehold champion, and this persistent learning goal remains open.

## Entreat Same-Lane Cut Scout - 2026-07-05

The next Entreat-specific learning artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_entreat_same_lane_cut_scout_20260705_current.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_entreat_same_lane_cut_scout_20260705_current.json`
- `docs/hermes-analysis/master_optimizer_reports/deckbuilding_contract_surface_audit_20260705_entreat_same_lane_cut_scout_current.md`
- `docs/hermes-analysis/master_optimizer_reports/deckbuilding_contract_surface_audit_20260705_entreat_same_lane_cut_scout_current.json`

This scout narrows the miracle-finisher lane after the Entreat runtime work.
It joins the miracle-access candidate queue, Entreat rule package, Entreat
runtime preflight, protected `607` value model, and current cut-evidence miner.
It is read-only and does not materialize a deck.

Current result:

- decision status:
  `entreat_same_lane_cut_scout_blocked_no_safe_cut_keep_607`;
- `Entreat the Angels` candidate row found: `true`;
- package generated: `true`;
- PostgreSQL writes executed for Entreat package: `false`;
- runtime primitive ready: `true`;
- active Entreat rule rows: `0`;
- same-lane current `607` cuts reviewed: `10`;
- safe same-lane cuts: `0`;
- blocked same-lane cuts: `10`;
- matrix contract blocker count: `28`;
- matrix scoring allowed now: `false`;
- candidate deck materialization allowed now: `false`;
- natural battle gate allowed now: `false`;
- promotion allowed now: `false`;
- recommended next action:
  `do_not_score_entreat_until_pg_apply_and_safe_cut_evidence`.

Blocked same-lane cut set:

- `Approach of the Second Sun`;
- `Storm Herd`;
- `Creative Technique`;
- `Mizzix's Mastery`;
- `Rise of the Eldrazi`;
- `Call Forth the Tempest`;
- `Hit the Mother Lode`;
- `Insurrection`;
- `Surge to Victory`;
- `Everything Comes to Dust`.

Operational lesson:

- `Entreat the Angels` is now a clearer research candidate, not a promoted
  deck card.
- The rule package and X-token runtime primitive remove one old uncertainty,
  but they do not prove deck fit.
- Every current miracle-finisher same-lane slot is hard-blocked under the
  protected `607` evidence. The main blockers are miracle/finisher core status,
  missing cut-safety proof, prior rejection, protected-anchor status, and
  measured exposure.
- Do not run a natural battle for Entreat until both gates are true: an active
  PostgreSQL-backed Entreat rule exists after approved apply, and at least one
  named same-lane cut is seed-safe.
- Current conclusion remains unchanged: protected deck `607` is still the
  Lorehold champion, and this persistent learning goal remains open.

## Miracle Next Route Planner - 2026-07-05

The next route-selection artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_next_route_planner_20260705_current.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_next_route_planner_20260705_current.json`

This planner ranks the current post-identity miracle/topdeck candidates after
the Entreat same-lane scout. It uses the candidate queue, Brain/Entreat/Haze
runtime contracts, Entreat cut scout, protected `607` cut miner, and external
card/combo source lanes. It is read-only and cannot score a deck, materialize a
candidate, run battle, mutate deck `607`, or write PostgreSQL.

Current result:

- decision status:
  `miracle_next_route_planner_selected_brain_runtime_learning_keep_607`;
- route candidates reviewed: `5`;
- selected card: `Brain in a Jar`;
- selected lane: `topdeck_miracle_access`;
- selected route state: `next_single_card_runtime_lesson`;
- selected learning score: `104`;
- `Entreat the Angels` safe same-lane cuts: `0`;
- active Entreat rule rows: `0`;
- named seed-safe cuts across the current cut miner: `0`;
- matrix scoring allowed now: `false`;
- candidate deck materialization allowed now: `false`;
- natural battle gate allowed now: `false`;
- PostgreSQL writes allowed now: `false`;
- recommended next action:
  `draft_brain_in_a_jar_runtime_contract_and_cut_miner_no_deck_action`.

Ranked learning interpretation:

- `Entreat the Angels` remains parked because the rule is not active in
  PostgreSQL and the scout found no named safe same-lane cut.
- `Brain in a Jar` is the next best learning route because it teaches
  charge-counter timing, exact mana-value free casting, and scry decisions in
  the same topdeck/miracle-access thesis without requiring a deck mutation.
- `Haze of Rage` is real combo research with `Storm-Kiln Artist`, but it is a
  package-only route and needs combo runtime plus cut safety before it can
  compete with protected `607`.
- `Burning Prophet` and `Inti, Seneschal of the Sun` stay deferred because they
  are lower-priority runtime/cut reviews after the core miracle-access lane.

Operational lesson:

- The persistent goal should continue with a Brain in a Jar runtime contract
  and cut miner, not by modifying `607` or forcing a battle.
- Current conclusion remains unchanged: protected deck `607` is still the
  Lorehold champion until a candidate ties or beats it under the same strategy,
  matrix, battle, and trace gates.

## Brain in a Jar Runtime/Cut Preflight - 2026-07-05

The Brain-specific learning artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_in_a_jar_runtime_cut_preflight_20260705_current.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_in_a_jar_runtime_cut_preflight_20260705_current.json`

This preflight follows the route planner recommendation. It checks the Brain
runtime contract, candidate row, protected `607` value model, and cut miner. It
also records the official card-text/ruling source lane for Brain. It is
read-only and cannot score a deck, materialize a candidate, run battle, mutate
deck `607`, or write PostgreSQL.

Current result:

- decision status:
  `brain_in_a_jar_runtime_cut_preflight_blocked_no_active_rule_no_safe_cut_keep_607`;
- route planner selected Brain: `true`;
- Brain candidate row found: `true`;
- Brain contract found: `true`;
- XMage class found: `true`;
- XMage signal hits: `5`;
- required runtime slices: `5`;
- active Brain rule rows: `0`;
- same-lane current `607` cuts reviewed: `9`;
- safe same-lane cuts: `0`;
- blocked same-lane cuts: `9`;
- matrix scoring allowed now: `false`;
- candidate deck materialization allowed now: `false`;
- natural battle gate allowed now: `false`;
- PostgreSQL writes allowed now: `false`;
- recommended next action:
  `draft_exact_mana_value_free_cast_runtime_family_before_any_brain_deck_action`.

Blocked same-lane cut set:

- `Scroll Rack`;
- `Sensei's Divining Top`;
- `Library of Leng`;
- `Molecule Man`;
- `The Scarlet Witch`;
- `The Mind Stone`;
- `Land Tax`;
- `Urza's Saga`;
- `Lorehold, the Historian`.

Operational lesson:

- Brain is not a generic two-mana artifact or ramp card in this shell. Its
  value must be measured as a topdeck/miracle-access engine that adds charge
  counters, casts exact mana-value instants or sorceries from hand without
  paying mana cost, and can scry by removing counters.
- Every current same-lane slot is hard-blocked under protected `607` evidence:
  commander, mana base, protected anchor, early-mana support, prior rejection,
  missing cut-safety proof, or measured high exposure.
- The next implementation step is runtime-family work for exact mana-value
  free-cast from hand plus replay fields, then rerun this preflight. It is not
  a deck mutation or natural battle.
- Current conclusion remains unchanged: protected deck `607` is still the
  Lorehold champion.

## Brain in a Jar Exact Runtime Contract - 2026-07-05

The Brain exact-runtime artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_in_a_jar_exact_runtime_contract_20260705_current.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_in_a_jar_exact_runtime_contract_20260705_current.json`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_in_a_jar_runtime_cut_preflight_20260705_after_exact_contract.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_in_a_jar_runtime_cut_preflight_20260705_after_exact_contract.json`

This closes the previous vague action item, `draft_exact_mana_value_free_cast_runtime_family`,
by writing the exact Brain effect-json contract and focused runtime vectors. It
does not create a PostgreSQL package, does not mark Brain battle-ready, and does
not modify protected deck `607`.

Current exact-runtime result:

- decision status:
  `brain_exact_runtime_contract_drafted_adapter_missing_keep_607`;
- XMage signals found: `13`;
- missing XMage signals: `0`;
- existing reusable runtime surfaces: `5`;
- Brain exact adapter present in `battle_analyst_v9.py`: `false`;
- proposed scope:
  `xmage_brain_in_a_jar_charge_counter_free_cast_scry_v1`;
- focused test vectors: `3`;
- natural battle gate allowed now: `false`;
- PostgreSQL writes allowed now: `false`;
- recommended next action:
  `implement_brain_in_a_jar_runtime_adapter_no_deck_action`.

The exact contract requires:

- first activation: `{1}, tap`, add one charge counter, then optionally cast
  one instant or sorcery from hand with mana value equal to the source's charge
  counter count after the counter is added;
- free-cast path: cast without paying mana cost, from hand only, exact mana
  value only, instant/sorcery only;
- second activation: `{3}, tap`, remove X charge counters, then scry X;
- replay fields for counters before/after, eligible spell names, selected
  spell, selected spell mana value, free-cast flag, removed counters, and scry
  result.

Updated Brain preflight result:

- decision status:
  `brain_in_a_jar_runtime_cut_preflight_blocked_adapter_missing_no_active_rule_no_safe_cut_keep_607`;
- exact runtime contract drafted: `true`;
- Brain exact adapter present: `false`;
- active Brain rule rows: `0`;
- safe same-lane cuts in protected `607`: `0`;
- blocked same-lane cuts: `9`;
- matrix scoring allowed now: `false`;
- candidate deck materialization allowed now: `false`;
- natural battle gate allowed now: `false`.

Operational lesson:

- Brain has moved from "runtime family undefined" to "runtime family defined,
  adapter missing." That is real progress, but it still does not make Brain a
  deck card.
- The next code step is a Brain-specific runtime adapter and focused tests.
  PostgreSQL packaging, candidate scoring, natural battle, and deck mutation
  remain closed until the adapter exists and the preflight is rerun.
- Current conclusion remains unchanged: protected deck `607` is still the
  Lorehold champion.

## Brain in a Jar Runtime Adapter - 2026-07-05

The Brain runtime-adapter artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_in_a_jar_exact_runtime_contract_20260705_after_adapter.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_in_a_jar_exact_runtime_contract_20260705_after_adapter.json`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_in_a_jar_runtime_cut_preflight_20260705_after_adapter.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_in_a_jar_runtime_cut_preflight_20260705_after_adapter.json`

This closes the previous code action item,
`implement_brain_in_a_jar_runtime_adapter_no_deck_action`, by adding focused
runtime support for the exact Brain scope:
`xmage_brain_in_a_jar_charge_counter_free_cast_scry_v1`. It does not create a
PostgreSQL package, does not run natural battle, and does not modify protected
deck `607`.

Implemented runtime behavior:

- first activation: pay `{1}`, tap Brain, add one `charge` counter, then cast
  one exact-mana-value instant or sorcery from hand without paying mana if an
  eligible spell exists;
- exact free-cast filter: hand only, instant/sorcery only, mana value equal to
  Brain's charge-counter count after the counter is added;
- second activation: pay `{3}`, tap Brain, remove X charge counters, then scry
  X;
- replay fields include charge counters, eligible spell names, selected spell,
  selected spell mana value, locked zero-cost cast context, removed counters,
  and scry result.

Current exact-runtime result after adapter:

- decision status:
  `brain_exact_runtime_contract_adapter_detected_preflight_required_keep_607`;
- XMage signals found: `13`;
- missing XMage signals: `0`;
- existing reusable runtime surfaces: `8`;
- Brain exact adapter present in `battle_analyst_v9.py`: `true`;
- focused runtime tests: `18` related tests passed;
- natural battle gate allowed now: `false`;
- PostgreSQL writes allowed now: `false`.

Updated Brain preflight result after adapter:

- decision status:
  `brain_in_a_jar_runtime_cut_preflight_blocked_adapter_present_no_active_rule_no_safe_cut_keep_607`;
- exact runtime contract drafted: `true`;
- Brain exact adapter present: `true`;
- active Brain rule rows: `0`;
- safe same-lane cuts in protected `607`: `0`;
- blocked same-lane cuts: `9`;
- matrix scoring allowed now: `false`;
- candidate deck materialization allowed now: `false`;
- natural battle gate allowed now: `false`;
- recommended next action:
  `prepare_brain_in_a_jar_pg_package_precheck_and_mine_seed_safe_cut_no_deck_action`.

Operational lesson:

- Brain has moved from "runtime family defined, adapter missing" to "runtime
  adapter present, product rule and cut evidence missing."
- The next allowed work is a PostgreSQL package precheck/rollback/postcheck
  plan plus renewed seed-safe cut mining. Actual PostgreSQL apply, candidate
  deck materialization, natural battle, and deck mutation remain closed until
  explicitly approved and independently gated.
- Current conclusion remains unchanged: protected deck `607` is still the
  Lorehold champion.

## Brain in a Jar PostgreSQL Package Preflight - 2026-07-05

The Brain PostgreSQL package-preflight artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_in_a_jar_pg_package_preflight_20260705_current.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_in_a_jar_pg_package_preflight_20260705_current.json`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_in_a_jar_pg_package_preflight_20260705_current_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_in_a_jar_pg_package_preflight_20260705_current_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_in_a_jar_pg_package_preflight_20260705_current_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_in_a_jar_pg_package_preflight_20260705_current_rollback.sql`

This closes only the package-preparation step. It does not execute SQL, does
not mutate PostgreSQL, does not sync Hermes SQLite, does not run battle, and
does not modify protected deck `607`.

Current package result:

- decision status: `prepared_read_only_pending_apply_approval`;
- apply ready for manual review: `true`;
- apply executed by this script: `false`;
- Brain exact adapter present: `true`;
- active Brain rule rows before apply: `0`;
- safe same-lane cuts before apply: `0`;
- proposed scope:
  `xmage_brain_in_a_jar_charge_counter_free_cast_scry_v1`;
- proposed logical rule key:
  `battle_rule_v1:aedfa4929249f55c1d607effe109f3f3`;
- Oracle hash:
  `41468898bf6400763de517269fdeb456`;
- PostgreSQL writes allowed now: `false`;
- deck action allowed now: `false`;
- natural battle gate allowed now: `false`;
- recommended next action:
  `review_precheck_then_request_explicit_postgresql_apply_if_approved`.

Package safety notes:

- precheck validates a matching `public.cards` row through
  `md5(coalesce(c.oracle_text, '')) = oracle_hash`;
- apply upserts only the Brain exact rule and preserves existing nonmatching
  Brain rows;
- rollback deletes only the proposed Brain `logical_rule_key` and restores
  the package backup rows;
- the package records current Oracle/source learning, including that Brain's
  first activation counts the newly added charge counter, casts at most one
  matching instant/sorcery from hand, casts during ability resolution, and
  still needs explicit follow-up for nontrivial additional-cost/X edge cases
  before Brain can be used as broad deck-quality proof.

Operational lesson:

- Brain has moved from "runtime adapter present, product rule missing" to
  "product rule package prepared but not applied."
- Actual PostgreSQL apply remains approval-gated. Even after apply, Brain
  still cannot enter Lorehold deck candidate materialization until a named
  safe same-lane cut exists and the Brain preflight is rerun.
- Current conclusion remains unchanged: protected deck `607` is still the
  Lorehold champion.

Validation after package generation:

- `python3 -m pytest -q
  docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_brain_in_a_jar_exact_runtime_contract.py
  docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_brain_in_a_jar_runtime_cut_preflight.py
  docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_brain_in_a_jar_pg_package_preflight.py`
  returned `15 passed`;
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_brain_in_a_jar_runtime.py`
  returned `PASS test_brain_in_a_jar_runtime`;
- `python3 -m pytest -q
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py`
  returned `281 passed, 3 subtests passed`;
- `python3 -m pytest -q
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py`
  returned `15 passed`;
- `deckbuilding_contract_surface_audit_20260705_brain_pg_package_current`,
  `xmage_strategy_consistency_audit_20260705_brain_pg_package_current`,
  `operational_surface_alignment_audit_20260705_brain_pg_package_current`,
  and `legacy_contamination_audit_20260705_brain_pg_package_current` all
  returned `pass`.

## Brain in a Jar Safe-Cut Gap Audit - 2026-07-05

The Brain deckbuilding gap audit artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_safe_cut_gap_audit_20260705_current.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_safe_cut_gap_audit_20260705_current.json`

This audit uses the current Brain runtime/cut preflight, the Brain PostgreSQL
package preflight, protected deck `607` value model, and external deckbuilding
evidence. It keeps the same Commander contract boundary: a runtime package
can make Brain executable later, but it does not make Brain a Lorehold deck
card without a named same-lane seed-safe cut and later equal battle evidence.

Current result:

- decision status:
  `brain_safe_cut_gap_no_active_rule_no_seed_safe_cut_keep_607`;
- Brain PostgreSQL package status:
  `prepared_read_only_pending_apply_approval`;
- apply ready for manual review: `true`;
- apply executed by this script: `false`;
- active Brain rule count: `0`;
- safe same-lane cuts: `0`;
- blocked same-lane cuts: `9`;
- external signal classification:
  `low_context_signal_not_staple`;
- EDHREC Brain global inclusion: `0.03%`;
- EDHREC Brain in Lorehold inclusion: `0.4%`;
- lowest-risk diagnostic cut candidate: `Molecule Man`;
- diagnostic cut allowed now: `false`;
- matrix scoring allowed now: `false`;
- candidate deck materialization allowed now: `false`;
- natural battle gate allowed now: `false`;
- recommended next action:
  `review_pg_package_then_request_explicit_apply_and_continue_cut_mining`.

Same-lane gap categories:

- `protected_core_topdeck_engine`: `3` slots:
  `Library of Leng`, `Scroll Rack`, and `Sensei's Divining Top`;
- `protected_structural_floor`: `2` slots:
  `The Mind Stone` and `The Scarlet Witch`;
- `prior_rejected_protected_slot`: `2` slots:
  `Molecule Man` and `Land Tax`;
- `never_cut_mana_base`: `1` slot:
  `Urza's Saga`;
- `never_cut_commander`: `1` slot:
  `Lorehold, the Historian`.

External deckbuilding lesson:

- EDHREC currently shows Brain as a very low-adoption contextual card, not a
  staple proof path: `0.03%` global and `0.4%` in Lorehold.
- The current Lorehold article names `Sensei's Divining Top`, `Scroll Rack`,
  and `Library of Leng` as key topdeck-manipulation cards; this supports the
  local protected-core classification instead of cutting those anchors for
  Brain.
- The spellslinger planning lesson remains that a deck can add one or two
  extra packages only when they still serve Plan A. Brain may still be a useful
  learning route, but current evidence says it is not yet a deck replacement.

Operational lesson:

- Brain has advanced as a runtime/card-rule candidate, but it has not advanced
  as a 607 deck-quality candidate.
- `Molecule Man` is the lowest-exposure diagnostic row, but it remains blocked
  because it is a prior rejected protected slot and needs new trace evidence
  before it can even become a named cut hypothesis.
- Do not materialize a Brain candidate, do not mutate deck `607`, and do not
  run a natural Brain battle from this audit. The next valid work is explicit
  PostgreSQL apply approval for the prepared Brain package plus continued
  same-lane cut mining.

## Staple Accessibility Freshness Audit - 2026-07-05

The current staple accessibility freshness artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_staple_accessibility_freshness_audit_20260705_current.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_staple_accessibility_freshness_audit_20260705_current.json`

This audit refreshes the `Mana Vault` and `The One Ring` question with current
external rules evidence and current local 607 evidence. It consumes:

- `lorehold_accessibility_layer_matrix_20260705_current`;
- `lorehold_hypothesis_queue_from_value_model_20260705_current_relearn`;
- `game_changer_discovery_gap_audit_20260705_current`;
- `lorehold_card_value_priority_synthesis_20260705_current_relearn`.

External freshness snapshot:

- Commander banned list checked on 2026-07-05:
  `https://mtgcommander.net/index.php/banned-list/`;
- latest Wizards B&R announcement checked:
  `https://magic.wizards.com/en/news/announcements/banned-and-restricted-june-29-2026`;
- Commander Brackets/Game Changers source checked:
  `https://magic.wizards.com/en/news/announcements/introducing-commander-brackets-beta`.

Current result:

- status:
  `staple_accessibility_current_legal_but_not_promotion_ready_keep_607`;
- cards reviewed: `2`;
- external Commander-legal cards: `2`;
- local Commander-legal cards: `2`;
- owned cards: `1`;
- Game Changers reviewed: `2`;
- format-staples gaps: `1`;
- promotion-blocked cards: `2`;
- natural-gate-ready cards: `0`;
- deck action allowed now: `false`;
- natural gate allowed now: `false`;
- recommended next action:
  `surface_accessibility_by_layer_and_require_new_cut_trace_before_retesting_staples`.

Card-level labels:

- `Mana Vault`:
  `rules_accessible_collection_missing_promotion_blocked`.
  It is legal, colorless, bracket-allowed in bracket 4, a Game Changer, and a
  format staple, but it is not owned locally and remains
  `blocked_prior_reject` after the prior replacement route lost. It must not
  be offered as an available protected-607 deck change until both collection
  and a materially new cut/trace hypothesis exist.
- `The One Ring`:
  `rules_collection_accessible_promotion_blocked`.
  It is legal, colorless, bracket-allowed in bracket 4, a Game Changer, and
  owned locally, but it has a local `format_staples` discovery gap and remains
  `blocked_prior_reject` / `blocked_existing_package_rejected`. It should be
  displayed as owned but promotion-blocked, not as a deck-ready upgrade.

App/deckbuilder rule:

- Do not collapse legality, ownership, discovery, bracket, runtime, and
  promotion into one boolean `accessible` flag.
- `legal` means playable under Commander rules. `owned` means collection
  availability. `Game Changer` means power/matchmaking pressure. None of those
  means a protected-`607` replacement without same-lane cut proof, refreshed
  strategy matrix, and later equal battle traces.
- Current conclusion remains unchanged: deck `607` is still the protected
  Lorehold champion.

## Topdeck Forced Access Audit - 2026-07-05

The current topdeck forced-access artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_forced_access_audit_20260705_current.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_forced_access_audit_20260705_current.json`

This audit consumes:

- `lorehold_hypothesis_queue_from_value_model_20260705_current_relearn`;
- `lorehold_miracle_access_first_preflight_20260704_current`;
- `lorehold_miracle_trace_failure_miner_20260704_current`;
- `lorehold_card_value_priority_synthesis_20260705_current_relearn`.

Current result:

- status:
  `topdeck_forced_access_diagnostic_ready_no_natural_gate_keep_607`;
- target cards reviewed: `5`;
- diagnostic-ready cards: `5`;
- natural-gate-ready cards: `0`;
- safe-cut-ready cards: `0`;
- preflight gate-ready count: `0`;
- deck action allowed now: `false`;
- promotion allowed: `false`;
- recommended first diagnostic: `Penance`.

Topdeck learning priority:

1. `Penance`: direct hand-to-top setup signal from the Card Kingdom Lorehold
   synergy review. It is the best first microbenchmark because it tests the
   exact missing skill: turning cards in hand into known first-draw miracle
   access.
2. `Galvanoth`: top-card free-cast engine with current EDHREC Lorehold signal
   (`26%` inclusion and `26%` synergy in the audit snapshot). It tests whether
   more top-card casting actually converts after setup.
3. `Dragon's Rage Channeler`: cheap noncreature-spell selection with current
   EDHREC Lorehold signal (`39%` inclusion and `37%` synergy in the audit
   snapshot). It tests whether surveil improves live miracle windows or only
   churns cards.
4. `Valakut Awakening // Valakut Stoneforge`: modal hand refresh. It tests
   recovery from bad hands, but must prove it does not become tap-land drag or
   reset prepared topdeck anchors.
5. `Wheel of Fortune`: powerful mass redraw and hand-filter lane hypothesis.
   It is high variance because it can refill opponents and undo a prepared top
   card.

Required before any natural gate:

- name the exact current `607` cut slot and functional lane;
- preserve or beat current `607` strategic floors:
  `miracle_cast=4`, `topdeck_manipulation_activated=5`,
  `lorehold_spell_cast=22`, `lorehold_cost_paid=27`, and
  `lorehold_upkeep_rummage=5`;
- preserve or beat current `607` natural access to topdeck anchors:
  `Land Tax=1`, `Scroll Rack=1`, `Sensei's Divining Top=2`,
  `The Mind Stone=2`, `Urza's Saga=1`, `Lorehold, the Historian=3`;
- show the candidate card drawn/cast/activated in focused traces;
- tie or beat `607` in the same opponent and seed window;
- avoid fast-pressure regression before any deck mutation.

Operational lesson:

- These five cards are now valid learning targets, not valid deck swaps.
- Forced access is allowed only as a diagnostic/microbenchmark lane and cannot
  promote a deck by itself.
- The app/deckbuilder must keep showing `607` as the protected Lorehold
  baseline until a candidate has named same-lane cut proof, non-regressed
  miracle/topdeck floors, and equal battle traces.

## Topdeck Forced Access Microbenchmark Plan - 2026-07-05

The current microbenchmark plan artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_forced_access_microbenchmark_plan_20260705_current.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_forced_access_microbenchmark_plan_20260705_current.json`

This plan consumes:

- `lorehold_topdeck_forced_access_audit_20260705_current`;
- `lorehold_607_unprotected_staple_relearn_preflight_20260704_current`.

Current result:

- status:
  `topdeck_microbenchmark_plan_ready_but_no_executable_package_keep_607`;
- target cards reviewed: `5`;
- microbenchmark designs available: `5`;
- runnable-now commands: `0`;
- natural-promotion-allowed rows: `0`;
- primary forced-access mode for all five current targets:
  `opening_hand`;
- deck action allowed now: `false`;
- recommended next action:
  `mine_new_safe_cut_models_before_running_topdeck_forced_access`.

Per-card execution state:

- `Penance`: design is valid, but existing packages are blocked by prior reject
  plus cut safety. Do not reuse `Hexing Squelcher` or `Promise of Loyalty`
  style protected cuts without a new same-lane cut model.
- `Galvanoth`: design is valid, but existing packages are blocked by prior
  reject plus cut safety. Do not reuse `Bender's Waterskin`, `Victory Chimes`,
  `Thor, God of Thunder`, or `Hexing Squelcher` as shortcut cuts.
- `Dragon's Rage Channeler`: design is valid, but the current tested cut
  `The Scarlet Witch` is protected by cut safety. It needs a different
  nonprotected same-lane cut before a forced-access run.
- `Valakut Awakening // Valakut Stoneforge`: design is valid, but the previous
  `Big Score` pair is a prior reject. Do not rerun that exact pair; only retest
  with a new hand-filter hypothesis that explains the prior miracle collapse.
- `Wheel of Fortune`: design is valid, but the previous `Big Score` pair is a
  prior reject. Do not rerun that exact pair; only retest with a new
  hand-filter hypothesis that protects the miracle/topdeck floor.

Runtime contract:

- Use existing forced-focus support: `MANALOOM_FORCE_FOCUS_ACCESS_MODE` and
  `MANALOOM_FOCUS_ACCESS_CARDS`.
- Current targets are enablers or hand filters, so the primary mode is
  `opening_hand`, not `library_top`.
- `library_top` remains useful for future payoff/miracle-card visibility tests,
  but it is not the primary test for these five enablers.
- Any future command must use a copied lab candidate with a declared package
  manifest and safe temporary cut. It must not mutate deck `607`.
- A forced-access result can prove visibility/use, but cannot promote a deck or
  replace `607` without a later natural gate.

## Topdeck Safe Cut Miner - 2026-07-05

The current topdeck safe-cut mining artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_safe_cut_miner_20260705_current.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_safe_cut_miner_20260705_current.json`

This miner consumes:

- `lorehold_topdeck_forced_access_microbenchmark_plan_20260705_current`;
- `lorehold_trace_cut_evidence_expander_20260704_role_tag_repair`.

Current result:

- status:
  `topdeck_safe_cut_miner_no_current_safe_cut_keep_607`;
- target cards reviewed: `5`;
- seed-safe cut candidates: `0`;
- reviewable same-lane gaps: `0`;
- runnable-now commands: `0`;
- natural-promotion-allowed rows: `0`;
- attempted package cuts reviewed: `9`;
- recommended next action:
  `do_not_run_forced_access_until_new_nonanchor_cut_evidence`.

Per-card cut state:

- `Penance`: no current safe cut. Prior attempted cuts:
  `Hexing Squelcher` and `Promise of Loyalty`; both are blocked by prior
  reject plus cut safety.
- `Galvanoth`: no current safe cut. Prior attempted cuts:
  `Bender's Waterskin`, `Hexing Squelcher`, `Victory Chimes`, and
  `Thor, God of Thunder`; all are blocked by prior reject plus cut safety.
- `Dragon's Rage Channeler`: no current safe cut. Prior attempted cut:
  `The Scarlet Witch`; prior evidence is clear, but cut safety blocks it.
- `Valakut Awakening // Valakut Stoneforge`: no current safe cut. Prior
  attempted cut: `Big Score`; prior evidence blocks that exact pair.
- `Wheel of Fortune`: no current safe cut. Prior attempted cut: `Big Score`;
  prior evidence blocks that exact pair.

Operational lesson:

- The correct next move is not to run forced-access battles yet.
- First mine or create new non-anchor cut evidence. The cut must be same-lane
  or explicitly covered by a new package-shell contract.
- Until that exists, all five topdeck targets remain learning hypotheses only,
  and deck `607` remains protected.

## Topdeck Post Safe-Cut Route - 2026-07-05

The current post safe-cut routing artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_post_safe_cut_route_20260705_current.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_post_safe_cut_route_20260705_current.json`

This router consumes:

- `lorehold_topdeck_safe_cut_miner_20260705_current`;
- `lorehold_topdeck_forced_access_microbenchmark_plan_20260705_current`;
- `lorehold_miracle_access_first_shell_contract_20260705_current_relearn`;
- `lorehold_from_scratch_shell_failure_synthesis_20260705_current_relearn`;
- `lorehold_closing_window_next_shell_target_router_20260705_current_relearn`;
- `lorehold_hypothesis_queue_from_value_model_20260705_current_relearn`.

Current result:

- status:
  `topdeck_post_safe_cut_route_sidecar_shell_required_keep_607`;
- selected route:
  `topdeck_access_first_sidecar_shell`;
- one-for-one cut-ready count: `0`;
- reviewable same-lane gaps: `0`;
- forced-access runnable count: `0`;
- structure-matrix contract allowed now: `true`;
- structure-matrix execution allowed now: `false`;
- natural battle gate allowed now: `false`;
- promotion allowed now: `false`;
- deck `607` mutated: `false`;
- recommended next action:
  `write_or_refresh_topdeck_access_first_sidecar_shell_contract_before_materialization`.

External research snapshot used for lane weighting:

- official Commander rules are treated as legality gates only:
  99 cards plus 1 commander, singleton, and color identity;
- EDHREC current Lorehold signals still point first to topdeck/spellslinger,
  with `Library of Leng`, `Sensei's Divining Top`, `Approach of the Second Sun`,
  and `Scroll Rack` as stronger Lorehold-specific anchors than generic staples;
- EDHREC optimized topdeck lists confirm the topdeck lane, but the sample is
  small and cannot override ManaLoom runtime traces.

Operational lesson:

- `Mana Vault` and `The One Ring` are not inaccessible because they are illegal;
  they are inaccessible for a `607` change right now because there is no safe
  same-lane cut, no proved miracle/topdeck floor improvement, and no equal
  battle gate beating `607`.
- The next executable learning step is a copied sidecar shell contract that
  declares topdeck/miracle, mana, draw, cut, and fast-pressure floors before any
  100-card materialization.
- A sidecar shell may learn aggressively, but it cannot mutate or replace
  `607` until it preserves the protected anchors and wins the same-seed gate.

## Topdeck Sidecar Candidate Queue - 2026-07-05

The current sidecar candidate queue artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_sidecar_candidate_queue_20260705_current.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_sidecar_candidate_queue_20260705_current.json`

This queue consumes:

- `lorehold_topdeck_post_safe_cut_route_20260705_current`;
- `lorehold_hypothesis_queue_from_value_model_20260705_current_relearn`;
- `lorehold_miracle_access_structure_matrix_contract_20260705_current_relearn`;
- `lorehold_topdeck_safe_cut_miner_20260705_current`;
- `lorehold_deckbuilding_value_model_20260704_current`.

Current result:

- status:
  `topdeck_sidecar_candidate_queue_blocked_no_matrix_rows_keep_607`;
- queue rows reviewed: `40`;
- matrix-candidate rows eligible now: `0`;
- candidate deck materialization allowed now: `false`;
- forced access allowed now: `false`;
- natural battle gate allowed now: `false`;
- promotion allowed now: `false`;
- readiness counts:
  `31` rows need a safe-cut model and `9` rows are blocked by prior reject;
- tag counts:
  `5` topdeck primary rows, `7` mana-base rows, `5` pressure-window rows,
  `8` spell-chain rows, `3` tutor rows, `2` generic-staple rows, and `10`
  sidecar watchlist rows;
- recommended next action:
  `build_named_same_lane_cut_models_for_topdeck_and_mana_rows_before_matrix_scoring`.

Priority queue learned from the current model:

- mana-base safe-cut lane: `Plateau`, `Clifftop Retreat`,
  `Boseiju, Who Shelters All`, `Rugged Prairie`, `Sundown Pass`,
  `Boros Garrison`, and `Cavern of Souls`;
- topdeck-access primary lane: `Dragon's Rage Channeler`, `Galvanoth`,
  `Penance`, `Valakut Awakening // Valakut Stoneforge`, and
  `Wheel of Fortune`;
- pressure-window lane after topdeck floor:
  `Boros Charm`, `Deflecting Palm`, `Grand Abolisher`, `Perch Protection`,
  and `Silence`;
- generic-staple learning-only lane:
  `Mana Vault` and `The One Ring`.

Operational lesson:

- The app/deckbuilder can show these as learning candidates, but must not label
  them as ready upgrades.
- A candidate row becomes matrix-eligible only after it has a named same-lane
  cut, no prior-reject blocker, and an expected metric lift tied to the
  miracle/topdeck or mana floor.
- The next real work is not battle; it is cut-model mining for topdeck and mana
  rows so the structure matrix can score an actual sidecar row.

## Topdeck Sidecar Cut Model Planner - 2026-07-05

The current cut-model planner artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_sidecar_cut_model_planner_20260705_current.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_sidecar_cut_model_planner_20260705_current.json`

This planner consumes:

- `lorehold_topdeck_sidecar_candidate_queue_20260705_current`;
- `lorehold_deckbuilding_value_model_20260704_current`;
- `lorehold_topdeck_safe_cut_miner_20260705_current`.

Current result:

- status:
  `topdeck_sidecar_cut_model_planner_review_probes_ready_no_safe_cut_keep_607`;
- target rows reviewed: `12`;
- named cut probes produced: `48`;
- safe-cut ready rows: `0`;
- matrix-candidate rows eligible now: `0`;
- candidate deck materialization allowed now: `false`;
- forced access allowed now: `false`;
- natural battle gate allowed now: `false`;
- promotion allowed now: `false`;
- protected near-misses: `25`;
- recommended next action:
  `collect_probe_evidence_for_named_topdeck_and_mana_cuts`.

Topdeck probe set learned:

- for `Dragon's Rage Channeler`, `Galvanoth`, `Penance`,
  `Valakut Awakening // Valakut Stoneforge`, and `Wheel of Fortune`, the named
  review probes are `Artist's Talent`, `Improvisation Capstone`,
  `Pinnacle Monk // Mystic Peak`, and `Reforge the Soul`;
- all topdeck probes are blocked by:
  `safe_cut_miner_zero_current_ready`,
  `requires_exposure_trace_before_safe_cut`, and
  `miracle_topdeck_floor_equivalence_required`;
- protected topdeck near-misses remain protected and are not cut proposals.

Mana-base probe set learned:

- for `Boros Garrison`, `Boseiju, Who Shelters All`, `Cavern of Souls`,
  `Clifftop Retreat`, `Plateau`, `Rugged Prairie`, and `Sundown Pass`, the first
  named review probes are `Mountain // Mountain`, `Plains // Plains`,
  `Ancient Tomb`, and `Battlefield Forge`;
- all mana probes are blocked by:
  `safe_cut_miner_zero_current_ready`,
  `requires_exposure_trace_before_safe_cut`,
  `mana_source_floor_equivalence_required`, and
  `structural_floor_equivalence_required`.

Operational lesson:

- A named probe is not a cut. It is the next evidence target.
- Topdeck rows need exposure traces showing the candidate add matters and the
  probe cut is low-impact or redundant.
- Mana rows need source-count, color, untapped/fetchable role, and same-seed
  no-regression proof before any land swap can be considered.
- `607` still remains the best protected Lorehold baseline because the planner
  found review targets, not a safe deck change.

## Topdeck Sidecar Probe Evidence Miner - 2026-07-05

The current probe-evidence artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_sidecar_probe_evidence_miner_20260705_current.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_sidecar_probe_evidence_miner_20260705_current.json`

This miner consumes:

- `lorehold_topdeck_sidecar_cut_model_planner_20260705_current`;
- `lorehold_card_exposure_profile_20260704_role_tag_repair_deck607`;
- `lorehold_mana_base_safe_cut_model_20260705_current`;
- `lorehold_mana_base_decision_integrator_20260705_after_plateau_turbulent_current`.

Current result:

- status:
  `topdeck_sidecar_probe_evidence_no_safe_cut_keep_607`;
- probe rows reviewed: `48`;
- safe-cut ready rows: `0`;
- matrix-candidate rows eligible now: `0`;
- candidate deck materialization allowed now: `false`;
- forced access allowed now: `false`;
- natural battle gate allowed now: `false`;
- promotion allowed now: `false`;
- exposed topdeck-role probes blocked: `20`;
- generic mana probes blocked: `28`;
- dedicated mana-base model-ready pairs found: `2`;
- dedicated mana-base exact rejected pairs: `2`;
- dedicated mana-base eligible pairs after decision filter: `0`;
- mana route status:
  `mana_route_closed_by_exact_decisions`;
- recommended next action:
  `collect_new_mana_evidence_or_topdeck_floor_traces_before_any_matrix_row`.

Topdeck probe evidence:

- `Artist's Talent` has `535` unique exposure records and is classified as
  `draw_filter_value`;
- `Improvisation Capstone` has `59` unique exposure records and is classified
  as `draw_filter_value`;
- `Pinnacle Monk // Mystic Peak` has `8` unique exposure records and is
  classified as `recursion_engine`;
- `Reforge the Soul` has `23` unique exposure records and is classified as
  `draw_filter_value`;
- therefore none of these topdeck probes is a low-impact cut from current
  evidence.

Mana probe evidence:

- `Mountain // Mountain` has `402` unique exposure records and remains a basic
  land floor probe, not a safe cut;
- `Plains // Plains` has `244` unique exposure records and remains a basic land
  floor probe, not a safe cut;
- `Ancient Tomb` has `39` unique exposure records and remains too risky as a
  fast-mana utility probe;
- `Battlefield Forge` has `15` unique exposure records and needs pair-level
  color-source equivalence proof.

Corrected mana route:

- the generic sidecar mana probes are weaker than the dedicated mana-base
  model;
- the dedicated model has exactly two current diagnostic pairs:
  `+Plateau / -Radiant Summit` and `+Plateau / -Turbulent Steppe`;
- both pairs were already decision-filtered as exact rejected decisions:
  `lorehold_mana_base_plateau_radiant_decision_20260705_current` rejected
  `+Plateau / -Radiant Summit`, and
  `lorehold_mana_base_plateau_turbulent_steppe_decision_20260705_current`
  rejected `+Plateau / -Turbulent Steppe`;
- the current mana-base decision integrator has
  `eligible_model_ready_pair_count=0`, so no Plateau pair remains eligible for
  materialization without new mana-trace evidence.

Operational lesson:

- The next safe movement is not to cut the named probes.
- For topdeck, collect floor-equivalence traces before trying any candidate
  row.
- For mana, do not retest the exact `Plateau` pairs without new evidence; the
  current mana route is closed by decisions.
- Deck `607` remains untouched and protected.

## Topdeck Floor Trace Evidence Collector - 2026-07-05

The current trace-evidence artifacts are:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_floor_trace_evidence_collector_20260705_current.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_floor_trace_evidence_collector_20260705_current.json`

This collector consumes:

- `lorehold_topdeck_floor_trace_target_contract_20260705_current`;
- `lorehold_topdeck_forced_access_audit_20260705_current`;
- `lorehold_topdeck_forced_access_microbenchmark_plan_20260705_current`;
- `lorehold_topdeck_safe_cut_miner_20260705_current`.

Current result:

- status:
  `topdeck_floor_trace_evidence_collected_no_execution_keep_607`;
- target cards reviewed: `5`;
- trace-collection-allowed rows: `5`;
- microbenchmark-runnable rows: `0`;
- seed-safe same-lane cuts: `0`;
- prior-reject target count: `4`;
- cut-safety blocked target count: `5`;
- forced access allowed now: `false`;
- structure matrix allowed now: `false`;
- natural battle gate allowed now: `false`;
- promotion allowed now: `false`;
- recommended next action:
  `mine_new_nonanchor_same_lane_cut_models_before_any_trace_execution`.

Per-card evidence state:

- `Penance`: prior rejects `2`; no current safe cut; still the first learning
  target, but cannot execute without a new same-lane nonanchor cut model.
- `Galvanoth`: prior rejects `4`; no current safe cut; old cuts such as
  `Bender's Waterskin` and `Victory Chimes` remain blocked.
- `Dragon's Rage Channeler`: prior rejects `0`; no current safe cut; this is
  the cleanest topdeck target from prior-result perspective, but the tested
  `The Scarlet Witch` cut is protected and cannot be reused.
- `Valakut Awakening // Valakut Stoneforge`: prior rejects `1`; no current
  safe cut; do not rerun the exact `Big Score` pair without a new hand-filter
  hypothesis that protects the miracle/topdeck floor.
- `Wheel of Fortune`: prior rejects `1`; no current safe cut; do not rerun the
  exact `Big Score` pair, because high draw power still needs floor and
  pressure validation in the current `607` shell.

Operational lesson:

- Trace collection is now structured enough to compare the five targets, but
  it is not execution permission.
- The next useful deckbuilding-learning task is to mine new nonanchor same-lane
  cut models, starting with `Dragon's Rage Channeler` because it lacks a prior
  reject but still needs a legal, nonprotected cut.
- Deck `607` remains untouched and protected.
