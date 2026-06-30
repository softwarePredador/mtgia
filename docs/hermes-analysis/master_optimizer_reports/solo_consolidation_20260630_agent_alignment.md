# Solo Consolidation Agent Alignment

- Generated at: `2026-06-30T14:09:54Z`
- Branch: `codex/solo-consolidation-20260630`
- Base: `origin/master` at `074a0c387`
- Scope: consolidate completed session-agent work into one solo continuation branch and reject conflicting mapper work until it is reconciled manually.

## Integrated

| Source | Commit | Decision | Reason |
| --- | --- | --- | --- |
| Agent 1 Runtime Artifact/Topdeck | `6944e9d83` | integrated | Adds focused guardrail tests and evidence for already modeled artifact/topdeck cases without changing broad runtime semantics. |
| Agent Deck Gates | `3c5045bfa` | integrated | Fixes Lorehold candidate gates to load candidate deck `607` instead of historical deck `6`, and updates contract audit to current matrix artifact. |
| Agent 3 Finisher/Draw/Recursion | `78f8ec8dd` | integrated | Adds focused runtime support/tests for `Ancient Gold Dragon` and `Leyline Dowser`; no PostgreSQL promotion is claimed. |

## Not Integrated

| Source | State | Decision | Reason |
| --- | --- | --- | --- |
| Agent 2 Mapper Static/Wipe/Tutor | uncommitted local diff in `bd25` | hold | It changes exact scopes for `Blood Moon`, `Chandra's Ignition`, and `Deathbellow War Cry`, but overlaps with the duplicate mapper branch and needs one reconciled implementation. |
| Duplicate mapper branch | `4deadeb0d` on `codex/session-agent-xmage-mapper-20260630` | hold | It adds the safer generic `xmage_*_review_v1` downgrade guard and Deathbellow mapper work, but conflicts conceptually with Agent 2's broader exact-scope changes. |
| Agent Integration/Validation | `078e25ed5` | not integrated | Report-only branch with stale environment observations; this consolidation report supersedes it for the solo path. |

## Validation

| Command | Status | Result |
| --- | --- | --- |
| `python3 -m unittest test_lorehold_607_research_candidate.py test_lorehold_variant_battle_gate.py test_lorehold_focus_access_package_generator.py test_lorehold_registry_candidate_runner.py test_operational_surface_alignment_audit.py` | pass | `47 tests OK` |
| `python3 test_artifact_topdeck_runtime.py` | pass | `PASS test_artifact_topdeck_runtime` |
| `python3 test_session_agent3_finisher_draw_recursion_runtime.py` | pass | `PASS test_session_agent3_finisher_draw_recursion_runtime` |
| `python3 xmage_strategy_consistency_audit.py --output-prefix /tmp/solo_consolidation_xmage_strategy` | pass | `26 checks pass` |
| `python3 operational_surface_alignment_audit.py --out-prefix /tmp/solo_consolidation_operational_surface` | pass | status `pass` |
| `python3 deckbuilding_contract_surface_audit.py --out-prefix /tmp/solo_consolidation_deckbuilding_contract` | pass | status `pass` |
| `python3 pg_hermes_sqlite_contract_audit.py --skip-pg --sqlite-db /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db --out-prefix /tmp/solo_consolidation_pg_hermes_sqlite_main_sqlite_skip_pg` | pass with warnings | `29 pass`, `3 warn`; PostgreSQL skipped by explicit flag. |
| `python3 pg_hermes_sqlite_contract_audit.py --out-prefix /tmp/solo_consolidation_pg_hermes_sqlite` | blocked | `DATABASE_URL`/PG env absent in this shell. |

## Current Solo Path

1. Continue from `codex/solo-consolidation-20260630`, not from the polluted checkout branch.
2. Keep Agents 2/mapper work frozen until a single mapper patch is chosen.
3. Prefer the duplicate mapper branch's guardrail that downgrades generic `xmage_*_review_v1` proposals, then manually re-add only exact scopes that can prove batch safety.
4. Do not promote `Blood Moon` or `Chandra's Ignition` to PostgreSQL from mapper metadata alone until runtime execution/tests exist or the exact static/wipe family contract is implemented.
5. Treat `Ancient Gold Dragon` and `Leyline Dowser` as runtime-local evidence only until PG package/hash/precheck/postcheck is completed.

