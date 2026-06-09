Legacy Hermes Battle Patchers
=============================

These scripts are historical one-shot patch/build utilities used while
`battle_analyst_v9.py` was being assembled from earlier battle engines.

Do not run them in normal development, cron jobs, or Hermes automation.
They may target `battle_analyst_v8.py`, rebuild `battle_analyst_v9.py`, or
overwrite manually curated logic. The active operational engine is:

`docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`

Active entrypoints must use either:

`MANALOOM_BATTLE_SCRIPT=/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`

or their built-in v9 fallback.

If a future migration needs one of these patchers, copy it into a scratch
branch, review its target path, and add a focused regression test before use.
