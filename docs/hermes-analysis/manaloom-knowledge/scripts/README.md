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
  --out-prefix docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_commander_gap
```

This queue separates source truth from runtime execution: resolved XMage cards
need ManaLoom adapter work by effect/signature; only missing XMage sources stay
in the residual manual/external-source queue.

Before building a PostgreSQL package from the global queue, split broad work
units into exact runtime-backed scopes:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py \
  --queue docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg283_fixed_spell_wave.json \
  --output-prefix docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_$(date -u +%Y%m%d)_next_wave
```

Only proposals marked `safe_for_batch_pg_package=true` may feed
`xmage_batch_pg_package_builder.py`. Generic `xmage_*_review_v1` scopes must
remain blocked until this split produces an exact `battle_model_scope` with
focused runtime tests.

Current applied checkpoint: PG283 promoted and synced 312 exact one-shot
instant/sorcery rules for fixed draw, fixed direct damage, and destroy target
spells. Evidence:

- `master_optimizer_reports/pg283_xmage_fixed_spell_wave_package.md`
- `master_optimizer_reports/pg283_xmage_fixed_spell_wave_e2e_validation.md`
- `master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg283_fixed_spell_wave.md`

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
