# ManaLoom Worktree Cleanup Proposal - 2026-06-20

Owner: Auditor Central / single operator
Status: executed by Auditor Central
Last audited: 2026-06-20 12:00 -0300

## Scope

This register records generated artifacts that were safe to remove from the
dirty worktree after the current registers retained the latest evidence.

The exact initial `8`-file cleanup list was executed at
`2026-06-20 11:57 -0300` after Rafael authorized cleanup/organization. A second
byte-duplicate `2`-file cleanup was executed at `2026-06-20 12:00 -0300`.
No stash, revert, checkout, stage, commit, push, deck swap, code deploy, or
PostgreSQL write was executed.

## Current Worktree Evidence

- Current `git status --porcelain=v1 | awk '{count[$1]++} END {for (k in count) print k, count[k]}' | sort`
  after all cleanup returned `72 M` and `69 ??`.
- `git diff --shortstat` returned
  `72 files changed, 24631 insertions(+), 2029 deletions(-)`.
- Tracked source/doc changes are mixed across `app/`, `server/`, and `docs/`.
  They are not cleanup candidates.
- Untracked PostgreSQL packages and current validation artifacts are retained
  because they are deploy/audit evidence.
- The exact `8` initial cleanup candidates were rechecked before deletion at
  `2026-06-20 11:57 -0300`; all existed and matched the audited hashes.
- The additional duplicate pair
  `battle_effect_coverage_audit_20260620_132730.*` was rechecked as
  byte-identical to the retained
  `battle_effect_coverage_audit_20260620_102701_post_pg007_sync.*` pair before
  deletion.
- After both cleanup passes, `git ls-files --others --exclude-standard | wc -l`
  dropped from `80` to `70`.

## Exact Cleanup Candidates

Deleted files:

- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_031157.json`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_031157.md`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_033941.json`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_033941.md`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_034324.json`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_034324.md`
- `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_120952.json`
- `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_120952.md`

Rationale:

- These are older coherence-audit snapshots from before the current PG-001
  closure and PG-002 applied/validated state.
- The current retained coherence evidence is
  `learned_deck_coherence_audit_20260620_115918.json` and
  `learned_deck_coherence_audit_20260620_115918.md`.
- The `095253` artifact remains retained as historical pre-PG-002 comparison
  evidence.
- PG-001 deploy history remains covered by the SQL package artifacts, deploy
  register, planner post-fix artifact, and current coherence artifact.
- The `battle_effect_coverage_audit_20260620_120952.*` files are exact
  duplicates of the retained
  `battle_effect_coverage_audit_20260620_120904_post_sqlite_sync.*` files.
- The six learned-deck coherence files are not byte-duplicates; they are cleanup
  candidates because they are untracked, superseded pre-current-state snapshots
  while `095253` remains retained as pre-PG-002 comparison evidence and
  `115918` remains retained as post-PG-002 current evidence.

## Candidate Hashes Audited At 2026-06-20 09:40 -0300

| sha256 | bytes | path |
| --- | ---: | --- |
| `e785fbfce947ea902d3070a1ae6e4742f9a19d0cf6a4acb8e72a97e072573e4e` | `351679` | `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_031157.json` |
| `35ab3d7a2335fccf6ade32b04e0f2cf5e46ae078862da3fa932af513f90830fc` | `10069` | `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_031157.md` |
| `e87dfb6ae5942dcce237f93d45deeac4e573e767b1b9173c3b7e48856631fd28` | `351107` | `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_033941.json` |
| `ea6e080eeb248f2aad591d206e835b7a9a80811712fa89705245d1cbab8a3459` | `10069` | `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_033941.md` |
| `64349c923fbe8ab52783d667d22c52d8b1ae681f37973f80923fb8d733da0a1b` | `339475` | `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_034324.json` |
| `530fa300d336758c85e4a87e63f8b5ab9f09d59809f86bec5b729bd53d0b8c64` | `8030` | `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_034324.md` |
| `1be4534bb0e5b0b5ca3782cde8fe0e2bc4742bdb15f1da7a38a6fcaf6b78efa7` | `201712` | `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_120952.json` |
| `964778a4f01d2caf1c2d58bf1bcca9571a33925cb853e36f85f2fb0339edea8e` | `25372` | `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_120952.md` |

Duplicate proof for the last two files:

- `cmp -s battle_effect_coverage_audit_20260620_120904_post_sqlite_sync.json battle_effect_coverage_audit_20260620_120952.json` returned `0`.
- `cmp -s battle_effect_coverage_audit_20260620_120904_post_sqlite_sync.md battle_effect_coverage_audit_20260620_120952.md` returned `0`.

## Revalidation At 2026-06-20 11:26 -0300

No deletion was executed. The proposal remains a pending approval artifact.

Presence check:

- All `8` listed cleanup candidates still exist.
- Sizes still match the audited values:
  `351679`, `10069`, `351107`, `10069`, `339475`, `8030`,
  `201712`, and `25372` bytes in proposal order.

Hash recheck:

- `learned_deck_coherence_audit_20260620_031157.json`:
  `e785fbfce947ea902d3070a1ae6e4742f9a19d0cf6a4acb8e72a97e072573e4e`
- `learned_deck_coherence_audit_20260620_031157.md`:
  `35ab3d7a2335fccf6ade32b04e0f2cf5e46ae078862da3fa932af513f90830fc`
- `learned_deck_coherence_audit_20260620_033941.json`:
  `e87dfb6ae5942dcce237f93d45deeac4e573e767b1b9173c3b7e48856631fd28`
- `learned_deck_coherence_audit_20260620_033941.md`:
  `ea6e080eeb248f2aad591d206e835b7a9a80811712fa89705245d1cbab8a3459`
- `learned_deck_coherence_audit_20260620_034324.json`:
  `64349c923fbe8ab52783d667d22c52d8b1ae681f37973f80923fb8d733da0a1b`
- `learned_deck_coherence_audit_20260620_034324.md`:
  `530fa300d336758c85e4a87e63f8b5ab9f09d59809f86bec5b729bd53d0b8c64`
- `battle_effect_coverage_audit_20260620_120952.json`:
  `1be4534bb0e5b0b5ca3782cde8fe0e2bc4742bdb15f1da7a38a6fcaf6b78efa7`
- `battle_effect_coverage_audit_20260620_120952.md`:
  `964778a4f01d2caf1c2d58bf1bcca9571a33925cb853e36f85f2fb0339edea8e`

Duplicate recheck:

- `cmp -s ...120952.json ...120904_post_sqlite_sync.json` returned `0`.
- `cmp -s ...120952.md ...120904_post_sqlite_sync.md` returned `0`.

Learned-deck supersession evidence:

- Candidate `031157`: generated `2026-06-20T03:11:54Z`,
  `severity_counts={"high":169,"medium":21}`,
  `metadata_total_lands_mismatch=58`, `metadata_zero_lands=54`,
  `partner_identity_not_modeled=9`.
- Candidate `033941`: generated `2026-06-20T03:39:38Z`,
  `severity_counts={"high":168,"medium":21}`,
  `metadata_total_lands_mismatch=57`, `metadata_zero_lands=54`,
  `partner_identity_not_modeled=9`.
- Candidate `034324`: generated `2026-06-20T03:43:22Z`,
  `severity_counts={"high":167,"medium":22}`,
  `metadata_total_lands_mismatch=57`, `metadata_zero_lands=54`,
  `partner_identity_not_modeled=10`.
- Retained pre-PG-002 comparison `095253`: generated
  `2026-06-20T09:52:51Z`, `severity_counts={"high":167,"medium":12}`,
  `metadata_total_lands_mismatch=57`, `metadata_zero_lands=54`.
- Retained post-PG-002 current evidence `115918`: generated
  `2026-06-20T11:59:16Z`, `severity_counts={"high":2,"medium":13}`;
  the aggregate summary no longer reports `metadata_total_lands_mismatch`,
  `metadata_zero_lands`, `all_core_metadata_zero`, or
  `partner_identity_not_modeled`.

## Cleanup Execution - 2026-06-20 11:57 -0300

Authorization:

- Rafael authorized cleanup/organization in this Auditor Central thread:
  "estou dando autorizacao total, para voce organizar tudo oque for necessario,
  limpar oque for necessario a valido".

Pre-delete evidence:

- All `8` listed cleanup candidates existed.
- `shasum -a 256` matched all audited hashes in this register.
- Duplicate proof for `battle_effect_coverage_audit_20260620_120952.*`
  still returned `0` against retained
  `battle_effect_coverage_audit_20260620_120904_post_sqlite_sync.*`.

Command executed:

```bash
rm -- \
  docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_031157.json \
  docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_031157.md \
  docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_033941.json \
  docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_033941.md \
  docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_034324.json \
  docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_034324.md \
  docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_120952.json \
  docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_120952.md
```

Post-delete evidence:

- All `8` deleted paths now return `REMOVED`.
- Retained evidence still exists:
  `learned_deck_coherence_audit_20260620_095253.*`,
  `learned_deck_coherence_audit_20260620_115918.*`, and
  `battle_effect_coverage_audit_20260620_120904_post_sqlite_sync.*`.
- `git status --short --branch`: still on `master...origin/master`, with
  `72` tracked modified files and broad untracked evidence.
- `git ls-files --others --exclude-standard | wc -l`: `72`.
- `git diff --check`: clean.

No PostgreSQL write, deck swap, code deploy, stash, revert, stage, commit, or
push was performed.

## Additional Duplicate Cleanup - 2026-06-20 12:00 -0300

Deleted files:

- `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_132730.json`
- `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_132730.md`

Rationale:

- SHA duplicate scan found the `.json` file byte-identical to retained
  `battle_effect_coverage_audit_20260620_102701_post_pg007_sync.json` with hash
  `4028be1a8255215fb117512c13a36998a695140add380cf5b98541f1c293acc6`.
- SHA duplicate scan found the `.md` file byte-identical to retained
  `battle_effect_coverage_audit_20260620_102701_post_pg007_sync.md` with hash
  `859acb1938f3dfef568560b45192acce8148fec84d22633930832414ce832fd2`.
- `cmp -s` returned `0` for both duplicate pairs.
- `rg` found no filename reference to `battle_effect_coverage_audit_20260620_132730`
  outside this cleanup/ownership documentation. The other `132730` occurrence is
  a battle logical key inside `known_cards_canonical_snapshot.json`, not an
  artifact filename.

Command executed:

```bash
rm -- \
  docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_132730.json \
  docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_132730.md
```

Post-delete evidence:

- Both `132730.*` paths are absent.
- Retained PG-007 evidence still exists:
  `battle_effect_coverage_audit_20260620_102701_post_pg007_sync.*`.
- Duplicate hash scan over current untracked files returned
  `NO_DUPLICATE_UNTRACKED_HASHES`.
- `git ls-files --others --exclude-standard | wc -l`: `70`.
- Untracked prefix split: `docs=42`, `server=28`.

No PostgreSQL write, deck swap, code deploy, stash, revert, stage, commit, or
push was performed.

## Retain Explicitly

Do not delete these categories in this cleanup pass:

- `docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_*`
- `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_*`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_pg001_*`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_plan_20260620_095139_post_pg001_audit_fix.json`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_095253.*`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_115918.*`
- `docs/hermes-analysis/master_optimizer_reports/battle_latest_090636_action_event_denominator_bv083_closure_20260620_0612.md`
- `docs/hermes-analysis/master_optimizer_reports/battle_runtime_execution_status_sqlite_refresh_20260620_120904.json`
- `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_120904_post_sqlite_sync.*`
- `docs/hermes-analysis/master_optimizer_reports/battle_runtime_execution_status_sqlite_refresh_20260620_102701_post_pg007.json`
- `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_102701_post_pg007_sync.*`
- `docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_*_20260620_1018.*`
- `docs/hermes-analysis/manaloom-knowledge/backups/knowledge.db.pre-pg006-runtime-sync.20260620_120904.bak`
- `docs/hermes-analysis/manaloom-knowledge/backups/knowledge.db.pre-pg007-runtime-sync.20260620_102701.bak`
- any tracked file under `app/`, `server/`, or `docs/`
- any untracked source/test file under `server/bin`, `server/lib`, or
  `server/test`

## Exact Command Executed

```bash
rm -- \
  docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_031157.json \
  docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_031157.md \
  docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_033941.json \
  docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_033941.md \
  docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_034324.json \
  docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_034324.md \
  docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_120952.json \
  docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_120952.md
```

Post-clean validation:

```bash
git status --short --branch
git diff --shortstat
```
