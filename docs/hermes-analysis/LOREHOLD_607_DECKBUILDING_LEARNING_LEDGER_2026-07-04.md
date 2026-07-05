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
