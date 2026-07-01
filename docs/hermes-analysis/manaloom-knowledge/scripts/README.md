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

Run the v9 regression harness explicitly:

```bash
BATTLE_ANALYST_PATH=docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py \
python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py
```

The default harness also resolves to v9.

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
  --queue docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg308_restricted_target_spell_wave.json \
  --output-prefix docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_$(date -u +%Y%m%d)_next_wave
```

Only proposals marked `safe_for_batch_pg_package=true` may feed
`xmage_batch_pg_package_builder.py`. Generic `xmage_*_review_v1` scopes must
remain blocked until this split produces an exact `battle_model_scope` with
focused runtime tests.

Current applied checkpoint: PG308. PG283 promoted and synced 312 exact one-shot
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
added 13 exact one-shot destroy-target plus controller life-gain spells.
The current splitter supports fixed draw, fixed direct damage, destroy target,
fixed controller life gain, exile target, simple tap mana-source permanents,
counter target spell, return target permanent/creature to hand, graveyard
recursion to hand, graveyard recursion to battlefield, simple board wipes,
fixed damage wipes, and fixed target-creature `+1/+1`/`-1/-1` counters, plus
supported restricted battlefield targets for damage/destroy/exile spells
(attacking/blocking, tapped/untapped, flying, color, power and mana value), plus
fixed target-creature power/toughness modifiers until end of turn, plus exact
static self combat and safe defensive keywords on creatures, plus fixed ETB
life gain on creatures, fixed ETB draw on creatures, creature tap-only
activated fixed damage, creature ETB destroy-target triggers, creature ETB
graveyard recursion-to-hand triggers, fixed creature dies-draw triggers, and
fixed creature enter-the-battlefield damage triggers, plus fixed one-shot
spell token creation with literal creature token classes and safe
`flying`/`haste` token keywords, plus fixed creature ETB token creation with
literal creature token classes and safe token keyword preservation, plus fixed
target-creature boost plus temporary keyword spells with until-end-of-turn
cleanup, plus fixed one-shot damage plus controller life-gain spells, plus fixed
one-shot destroy-target plus controller life-gain spells; PG308 added 38 exact
restricted target fixed damage, destroy and exile spells with runtime legality
for attacking/blocking, tapped/untapped, flying, color, power and mana-value
constraints.
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
- `master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg308_restricted_target_spell_wave.md`
- `master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg308_existing_supported_recheck.md`

After PG308, rerunning the exact splitter on supported units should return
`proposal_count=0` over `7365` considered supported rows; continue by adding a
new exact subpattern/runtime adapter for a remaining high-volume family from
the current authoritative queue. The post-PG308 queue is the current scheduling
source: `target_identity_count=27586`, `xmage_authoritative_source_count=27272`,
`xmage_authoritative_adapter_required_count=27272`, `parser_gap=0`, and
`xmage_missing_source_exception_count=314`.

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
