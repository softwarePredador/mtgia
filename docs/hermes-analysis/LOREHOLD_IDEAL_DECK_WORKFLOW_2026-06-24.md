# Lorehold Ideal Deck Workflow

Status: current canonical workflow for Lorehold deck improvement.

## Decision

Do not try to pick the ideal Lorehold deck directly from XMage, raw WR, or the
old hardcoded builder.

Use a two-stage flow:

1. Close rule confidence for every card that touches Lorehold.
2. Benchmark only the rule-ready candidates through the safe master optimizer
   flow.

XMage is the rules/reference corpus. It tells ManaLoom how a card can be
modeled and tested. It is not the strategic deck oracle by itself.

## Active Tooling

Primary matrix generator:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_ideal_deck_candidate_matrix.py \
  --output-prefix docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260624_v1
```

Current generated evidence:

- initial matrix:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260624_v1.json`
- current post-PG187 expanded matrix:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260624_pg187_caldera_pyremaw_postsync_v1.json`
- current post-PG187 strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260624_pg187_caldera_pyremaw_postsync_v1.json`
- current post-PG187 effective queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_effective_queue_20260624_pg187_caldera_pyremaw_postsync_v1.json`

The script reads:

- active Lorehold deck `6`;
- prior Lorehold variants `606` and `607`;
- new Lorehold variants `608` through `616`;
- expanded opponent/non-Lorehold comparison decks `58`, `74`, `105`, and
  `617` through `619`;
- current XMage proposal report
  `xmage_current_replay_batch_pipeline_20260624_pg187_caldera_pyremaw_postsync_v1_proposals.json`;
- Hermes SQLite battle-rule cache for rule readiness.

It does not mutate deck rows, SQLite, or PostgreSQL.

## Current Matrix Result

Initial matrix generated on 2026-06-24:

- total Lorehold-touching cards in matrix: `395`;
- `core_keep`: `87`;
- `priority_benchmark_candidate`: `35`;
- `watchlist_candidate`: `88`;
- `needs_rule_before_strategy`: `127`;
- `active_low_confidence_review`: `13`;
- `low_priority`: `43`;
- `policy_blocked`: `2`.

Rule-readiness split:

- `battle_ready`: `268`;
- `mapper_manual`: `88`;
- `split_scope`: `26`;
- `runtime_needed`: `11`;
- `no_rule_signal`: `2`.

Post-PG185 matrix generated on 2026-06-24 after closing `Fury Storm`:

- total Lorehold-touching cards in matrix: `395`;
- `core_keep`: `87`;
- `priority_benchmark_candidate`: `36`;
- `watchlist_candidate`: `88`;
- `needs_rule_before_strategy`: `126`;
- `active_low_confidence_review`: `13`;
- `low_priority`: `43`;
- `policy_blocked`: `2`.

Post-PG185 rule-readiness split:

- `battle_ready`: `269`;
- `mapper_manual`: `88`;
- `split_scope`: `25`;
- `runtime_needed`: `11`;
- `blocked_missing_xmage_source`: `2`.

PG185 closure evidence:

- PostgreSQL package:
  `docs/hermes-analysis/master_optimizer_reports/pg185_fury_storm_copy_spell_package.md`;
- PG -> Hermes sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg185_fury_storm_20260624.json`;
- affected deck audit:
  `docs/hermes-analysis/master_optimizer_reports/deck612_battle_rule_coherence_pg185_postsync_20260624.json`;
- final pipeline:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_lorehold_copy_spell_postsync_v3_manifest.json`;
- strategy consistency:
  `18/18` pass.

Post-PG186 expanded matrix generated on 2026-06-24 after closing
`Lightning Helix` and including decks `6`, `58`, `74`, `105`, and `606` through
`619`:

- total scoped cards in matrix: `709`;
- `core_keep`: `91`;
- `priority_benchmark_candidate`: `65`;
- `watchlist_candidate`: `180`;
- `needs_rule_before_strategy`: `252`;
- `active_low_confidence_review`: `9`;
- `low_priority`: `109`;
- `policy_blocked`: `3`.

Post-PG186 rule-readiness split:

- `battle_ready`: `457`;
- `mapper_manual`: `163`;
- `split_scope`: `61`;
- `runtime_needed`: `21`;
- `blocked_missing_xmage_source`: `4`;
- `no_rule_signal`: `3`.

PG186 closure evidence:

- PostgreSQL package:
  `docs/hermes-analysis/master_optimizer_reports/pg186_lightning_helix_damage_lifegain_package.md`;
- PG -> Hermes sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg186_lightning_helix_20260624.json`;
- affected deck audit:
  `docs/hermes-analysis/master_optimizer_reports/deck616_battle_rule_coherence_pg186_postsync_20260624.json`;
- final pipeline:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg186_lightning_helix_postsync_v2_manifest.json`;
- strategy consistency:
  `18/18` pass.

Post-PG187 expanded matrix generated on 2026-06-24 after closing
`Caldera Pyremaw`:

- total scoped cards in matrix: `709`;
- `core_keep`: `91`;
- `priority_benchmark_candidate`: `65`;
- `watchlist_candidate`: `181`;
- `needs_rule_before_strategy`: `251`;
- `active_low_confidence_review`: `9`;
- `low_priority`: `109`;
- `policy_blocked`: `3`.

Post-PG187 rule-readiness split:

- `battle_ready`: `458`;
- `mapper_manual`: `163`;
- `split_scope`: `60`;
- `runtime_needed`: `21`;
- `blocked_missing_xmage_source`: `4`;
- `no_rule_signal`: `3`.

PG187 closure evidence:

- PostgreSQL package:
  `docs/hermes-analysis/master_optimizer_reports/pg187_caldera_pyremaw_spellcast_damage_package.md`;
- PG -> Hermes sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg187_caldera_pyremaw_20260624.json`;
- affected deck audit:
  `docs/hermes-analysis/master_optimizer_reports/deck614_battle_rule_coherence_pg187_postsync_20260624.json`;
- final pipeline:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg187_caldera_pyremaw_postsync_v1_manifest.json`;
- strategy consistency:
  `18/18` pass.

Operational interpretation:

- The `251` `needs_rule_before_strategy` cards in the expanded scope must not
  drive deck swaps yet. They first need mapper/runtime/split-scope closure.
- The `65` `priority_benchmark_candidate` cards are the first practical swap
  candidates after baseline hash guard and battle gate review.
- `Chrome Mox` and `Mox Opal` are policy-blocked for the current no-premium-Mox
  Lorehold lane even if they have rule evidence.

## Current Rule-First Priority

The first deck-improvement work is not a swap. It is closing the highest-impact
Lorehold card rules from the matrix.

Start with:

- split-scope cards that are strategically relevant, such as
  `Pyromancer Ascension`, `Cool but Rude`, `Profound Journey`,
  `Sun Titan`, `Glint-Horn Buccaneer`,
  `Taii Wakeen, Perfect Shot`, `Primal Amulet // Primal Wellspring`,
  `Starfield Shepherd`, `Erode`, `Kederekt Parasite`, and `Rakdos Charm`;
- runtime-needed token or damage families only when the exact scope is
  reusable and has focused test coverage;
- manual mapper cards last unless they are blocking a top Lorehold role gap.

`Fury Storm` is the first completed proof of the flow:

1. XMage local source matched exact stack-copy signature.
2. The hint/classifier promoted only the safe exact scope.
3. PG185 precheck/apply/postcheck promoted one verified auto rule.
4. PG -> Hermes sync inserted/updated one local battle rule.
5. Matrix moved the card to `battle_ready` and
   `priority_benchmark_candidate`.

`Lightning Helix` is the second completed proof and the first direct-damage
lifegain subpattern:

1. XMage local source matched `DamageTargetEffect(3)` +
   `GainLifeEffect(3)` + `TargetAnyTarget`.
2. The hint/classifier promoted only the exact
   `damage_any_target_and_gain_life_v1` scope.
3. Battle runtime now executes `direct_damage` with explicit controller
   `gain_life` and replay provenance.
4. PG186 precheck/apply/postcheck promoted one verified auto rule and
   deprecated two stale generated `remove_creature` shadows.
5. PG -> Hermes sync made deck `616` report `Lightning Helix` as `pass`.

`Caldera Pyremaw` is the third completed proof and the first creature
spell-cast trigger that combines source counters with source-power damage:

1. XMage local source matched `SpellCastControllerTriggeredAbility` +
   `AddCountersSourceEffect` + `DamageTargetEffect` + `TargetOpponent`.
2. The validity/classifier pipeline now preserves `target_classes`, so exact
   target structure can drive batch-safe decisions.
3. Battle runtime resolves `instant_sorcery_cast` by adding the +1/+1 counter
   first, then dealing damage equal to the post-counter source power.
4. PG187 precheck/apply/postcheck promoted one verified auto rule and
   deprecated two stale generated `finisher` shadows.
5. PG -> Hermes sync made deck `614` report `Caldera Pyremaw` as `pass`, and
   the matrix moved it to `battle_ready` / `watchlist_candidate`.

## Current Benchmark Candidate Lane

After rules are ready, the first battle-benchmark candidates are the top
rule-ready matrix rows, not every possible card.

Current top candidates include:

- `Library of Leng`;
- `Restoration Seminar`;
- `Reforge the Soul`;
- `Increasing Vengeance`;
- `Flare of Duplication`;
- `Volcanic Vision`;
- `Big Score`;
- `Flashback`;
- `Improvisation Capstone`;
- `Pinnacle Monk // Mystic Peak`;
- `Fury Storm`;
- `Return the Favor`;
- `Monument to Endurance`;
- `Dawn's Truce`;
- `Arcane Bombardment`;
- `Creative Technique`.

These are candidate rows only. They still require baseline hash guard,
category-safe cut target, temporary battle benchmark, quality gate,
confirmation, handoff, and explicit apply approval.

## Historical Tools Removed From Active Path

The following are retained only as history/compatibility and must not guide new
Lorehold deck decisions:

- `build_optimized_deck.py`
  - now exits as `historical_disabled`;
  - reason: hardcoded collection/priority heuristic without rule readiness,
    baseline hashes, or battle evidence gates.
- `universal_optimizer.py`
  - now blocks execution unless explicitly overridden with
    `MANALOOM_ALLOW_LEGACY_UNIVERSAL_OPTIMIZER=1` or `--allow-legacy`;
  - reason: legacy quick/full auto-apply path is not authorized for current
    handoff.

Use `lorehold_ideal_deck_candidate_matrix.py` plus the safe master optimizer
pipeline instead.

## Required Gates Before Any Deck Change

Any actual deck change must pass:

1. current PostgreSQL/backend source-of-truth check when the claim depends on
   promoted data;
2. Hermes SQLite freshness check for the local battle cache;
3. approved baseline hash guard;
4. candidate matrix row in `priority_benchmark_candidate` or explicitly
   documented override;
5. temporary `slot_optimizer.py` benchmark;
6. `master_optimizer_quality_gate.py`;
7. confirmation/handoff artifact;
8. explicit apply approval;
9. post-apply battle gate and strategy-coherence review.

No matrix row is an automatic swap.
