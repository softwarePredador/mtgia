# Hermes AWS Battle Runtime Alignment - 2026-06-09

## Objective

Prevent v8/v9 divergence between the local repository, the Hermes AWS workspace,
and operational cron wrappers.

## Current Contract

- Active battle engine: `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`.
- Legacy engines (`battle_analyst.py`, `battle_analyst_v6.py`, `battle_analyst_v7.py`,
  `battle_analyst_v8.py`) are historical comparison targets only.
- Operational scripts must either default to v9 or honor `MANALOOM_BATTLE_SCRIPT`.
- One-shot patch/build scripts that target v8 are archived under
  `server/bin/legacy/hermes_battle_patchers/` and must not be used by crons.

## AWS Findings

Hermes AWS workspace at `/opt/data/workspace/mtgia` was on
`codex/hermes-analysis-docs` with local dirty artifacts and older v8 defaults.
Because that workspace intentionally accumulates Hermes reports and generated
knowledge files, it must not be force-cleaned during product work.

Runtime wrappers in `/opt/data/scripts` were updated in-place with backups named
`*.bak_v9_alignment_20260609`.

Updated AWS wrappers:

- `/opt/data/scripts/universal_optimizer.py`
- `/opt/data/scripts/slot_optimizer.py`
- `/opt/data/scripts/card_impact_analyzer.py`
- `/opt/data/scripts/generate_card_replays.py`
- `/opt/data/scripts/generate_known_cards.py`
- `/opt/data/scripts/manaloom-master-optimizer-preflight.sh`
- `/opt/data/scripts/manaloom-master-optimizer-slot-scan.sh`
- `/opt/data/scripts/manaloom-master-optimizer-end-to-end.sh`
- `/opt/data/scripts/manaloom-master-optimizer-auto-cycle.sh`
- `/opt/data/scripts/known_cards_generator_cron.sh`
- `/opt/data/scripts/known_cards_validator_cron.sh`

## Validation

Local:

```bash
python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py
python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py
BATTLE_ANALYST_PATH=docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py \
  python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py
git diff --check
```

AWS:

```bash
python3 -m py_compile \
  /opt/data/scripts/universal_optimizer.py \
  /opt/data/scripts/slot_optimizer.py \
  /opt/data/scripts/card_impact_analyzer.py \
  /opt/data/scripts/generate_card_replays.py \
  /opt/data/scripts/generate_known_cards.py
```

## Operating Notes

- Do not run old patchers from `server/bin/legacy/hermes_battle_patchers/`.
- Do not treat remaining `battle_analyst_v8.py` mentions in old reports as
  operational instructions.
- If a cron needs a custom engine, set `MANALOOM_BATTLE_SCRIPT` explicitly.
- If the AWS Hermes workspace is dirty, do not `git reset --hard`; preserve
  generated reports and align runtime wrappers or use a separate clean worktree.
