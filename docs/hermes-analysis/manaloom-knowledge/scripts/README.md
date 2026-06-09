# Hermes Battle Scripts

## Active Engine

`battle_analyst_v9.py` is the active battle engine for ManaLoom/Hermes.

Operational scripts should use:

```bash
export MANALOOM_BATTLE_SCRIPT="/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py"
```

Local fallbacks in optimizer, replay, sync and audit scripts now point to v9.

## Legacy Engines

`battle_analyst.py`, `battle_analyst_v6.py`, `battle_analyst_v7.py` and
`battle_analyst_v8.py` are retained only for historical comparison and forensic
diffing. Do not use them as cron defaults, optimizer defaults or source of truth
for new rule fixes.

## Validation

Run the v9 regression harness explicitly:

```bash
BATTLE_ANALYST_PATH=docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py \
python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py
```

The default harness also resolves to v9.
