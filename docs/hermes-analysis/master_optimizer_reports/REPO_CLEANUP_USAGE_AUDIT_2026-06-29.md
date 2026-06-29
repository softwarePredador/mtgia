# Repo Cleanup Usage Audit - 2026-06-29

## Scope

Goal: reduce ManaLoom workspace noise by removing generated artifacts, historical proof outputs, local build caches, and unreferenced optimizer reports while keeping executable battle/deckbuilder surfaces intact.

No PostgreSQL writes were performed. The active Hermes SQLite database at `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db` was preserved.

## Measurements

Before cleanup:

- Repository working tree: `21G`.
- `app`: `15G`, mostly Flutter/Dart build cache.
- `server`: `1.9G`, mostly local test artifacts/cache and downloaded/generated card data.
- `docs/hermes-analysis/master_optimizer_reports`: `2.7G`, with `8,650` tracked files plus ignored local candidate DBs.

After cleanup:

- Repository working tree: `640M` (`369M` is `.git` history).
- `app`: `71M`.
- `server`: `9.9M`.
- `docs`: `185M`.
- `docs/hermes-analysis/master_optimizer_reports`: `133M`, with `2,394` tracked files.
- Ignored `knowledge_candidate.db` copies under `master_optimizer_reports`: `0`.

## Removed

- Local ignored build/cache surfaces:
  - `app/.dart_tool`, `app/build`, platform ephemeral Flutter/Pods/Gradle caches.
  - `server/.dart_tool`, generated `server/AtomicCards.json`, local server test artifacts.
  - Python `__pycache__` and `.pytest_cache` under the Hermes script surface.
- Tracked historical proof outputs already covered by `.gitignore` policy:
  - `app/doc/runtime_flow_proofs_*`.
  - `server/test/artifacts/*`.
- Tracked optimizer/report artifacts that had no external reference outside `master_optimizer_reports`:
  - `6,256` generated files, about `1.34GB`.
  - Main classes: XMage batch outputs, Lorehold gate/candidate outputs, old battle forensic dumps, generated SQL package fragments, stdout/stderr reports, JSON/JSONL/TSV run payloads.
- Ignored local optimizer candidate databases:
  - `141` `knowledge_candidate.db` files, about `1.3GB`.
- Local ignored historical/scratch cleanup:
  - `.local_artifact_archive`, about `878M`.
  - old `docs/hermes-analysis/manaloom-knowledge/backups/*.bak`, about `70M`.
  - empty accidental SQLite placeholders outside `scripts/knowledge.db`.
  - `.DS_Store`, local logs, Python caches, and the local `.venv`.

## Kept

- Runtime source and tests:
  - `battle_analyst_v9.py`.
  - `battle_replay_v10_3.py`.
  - `battle_runtime_surface_manifest.py`.
  - `battle_rule_registry.py`.
  - `reviewed_battle_card_rules.py` and `reviewed_battle_card_rules.json`.
  - XMage mapper/indexer/pipeline scripts.
  - PostgreSQL/Hermes sync scripts.
  - focused battle, registry, runtime, XMage, Lorehold, and 17lands tests.
- Active data:
  - `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`.
- Durable guidance and reviewed audit docs:
  - `README.md`.
  - uppercase/current contract reports such as `BATTLE_SIMULATOR_RULES_ALIGNMENT_AUDIT_2026-06-29.md`, `XMAGE_ACCELERATION_E2E_2026-06-29.md`, and `XMAGE_DEFINITIVE_FLOW_CRYSTAL_VEIN_PILOT_2026-06-29.md`.

## Script Analysis

The Hermes script directory is not the main size problem: it is `22M`.

Static checks over `348` Python files found:

- `154` test files.
- `105` modules imported by other local Python files.
- `239` files referenced textually by repo docs/scripts or local ManaLoom automation wrappers/prompts.
- `0` deletion-safe Python scripts under the strict rule used here.

Strict delete rule for scripts:

1. not a test;
2. not imported by another local Python module;
3. not referenced by repo docs/scripts or local ManaLoom automation wrappers;
4. not part of the active battle, XMage, PostgreSQL sync, Lorehold registry/gate, 17lands, or source-harvester surfaces;
5. clearly a one-shot/historical helper.

No script met all five conditions. Script cleanup should continue by deprecating flows in code first, then deleting the newly unreferenced script in the same commit.

## Prevention Rule

New exploratory outputs must default to `/tmp` or another ignored scratch path. `master_optimizer_reports` is evidence storage, not a runtime dependency surface.

The root `.gitignore` now ignores generated JSON/JSONL/OUT/ERR/TSV/DB/log payloads and common XMage/Lorehold gate output prefixes under `master_optimizer_reports`. Reviewed evidence can still be force-added intentionally with `git add -f` when it is a real contract or audit deliverable.
