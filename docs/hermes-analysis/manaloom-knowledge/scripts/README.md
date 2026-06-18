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

Run the v9 regression harness explicitly:

```bash
BATTLE_ANALYST_PATH=docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py \
python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py
```

The default harness also resolves to v9.
