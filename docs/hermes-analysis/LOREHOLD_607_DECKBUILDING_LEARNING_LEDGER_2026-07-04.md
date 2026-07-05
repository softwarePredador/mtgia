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
