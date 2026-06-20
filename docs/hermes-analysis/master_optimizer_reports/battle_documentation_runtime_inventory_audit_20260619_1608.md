# Battle Documentation And Runtime Inventory Audit - 2026-06-19T16:08Z

## Scope

This audit maps the current battle knowledge surface:

- current battle documentation;
- historical battle documentation that can be mistaken for current truth;
- local battle runtime scripts;
- current recurring audit flow;
- lightweight validation commands run in this pass.

No PostgreSQL changes, swaps, commits, or product-code edits were made.

## Current Source Candidates

These files are the strongest current sources for battle validation work:

| Source | Role | Current observation |
| --- | --- | --- |
| `docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md` | Live issue register | Primary place for open/closed battle validation findings. |
| `docs/hermes-analysis/BATTLE_SYSTEM_LOGIC.md` | Broad system documentation | Large current document (`1271` lines, mtime `2026-06-19`) covering engine, replay, decision trace, provenance and automation context. |
| `docs/hermes-analysis/BATTLE_GENERATOR_LOREHOLD_TASK_MATRIX_2026-06-17.md` | Prioritized work matrix | Updated on `2026-06-19`; includes the replay-text-vs-JSONL concern and current battle priorities. |
| `docs/hermes-analysis/ALL_CARD_CANDIDATE_REVIEW_2026-06-19.md` | Rule queue/template pipeline | Current all-card review and battle/deckbuilding queue context. |
| `docs/hermes-analysis/LOREHOLD_DECK6_STRATEGY_COHERENCE_AUDIT_2026-06-19.md` | Learned deck/source coherence | Current Lorehold deck source and metadata coherence audit. |
| `docs/hermes-analysis/master_optimizer_reports/battle_flow_inventory_audit_20260619_154320.md` | Automated flow inventory | Current flow/gates inventory from earlier 2026-06-19 audit. |
| `docs/hermes-analysis/master_optimizer_reports/battle_template_gap_audit_20260619_155005.md` | Template gap inventory | Focused evidence/templates vs latest unknown backlog. |
| `docs/hermes-analysis/master_optimizer_reports/battle_event_contract_audit_20260619_155726.md` | Event contract inventory | Event types, consumers and uncovered event classes. |
| `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260619_153722_runtime_safe.md` | Runtime-safe coverage snapshot | Current runtime-safe/review-only/unknown coverage snapshot. |

## Historical Docs That Need Freshness Guard

The following important battle docs do not mention `2026-06-19` and do not point
to the live register. They may still contain useful background, but should not
be used as current truth without rerun or cross-check against the register:

| Source | Why guard is needed |
| --- | --- |
| `BATTLE_AUDIT_COVERAGE_STATUS_2026-06-16.md` | Concludes `PASS_WITH_RISKS` for an older gate/corpus. Current register has newer coverage/event-contract findings. |
| `BATTLE_DECISION_STRATEGY_AUDIT_2026-06-15.md` | Decision trace/status semantics changed; latest automation now exposes `human_replay_complete=not_evaluated_by_replay_decision_auditor`. |
| `DECISION_TRACE_V1_SLICE_2026-06-15.md` | Old slice doc, useful for schema history but not complete current gate coverage. |
| `BATTLE_GENERATOR_IMPLEMENTATION_SLICE_SPEC_2026-06-17.md` | Implementation spec before several 2026-06-19 closures and new event-contract findings. |
| `BATTLE_GENERATOR_TRUTH_STUDY_2026-06-17.md` | Truth study before current automation summary/gate changes. |
| `BATTLE_GENERATOR_LOREHOLD_TRUTH_STUDY_2026-06-16.md` | Large older truth study; must be treated as background. |
| `BATTLE_MULTI_RULE_RUNTIME_READINESS_2026-06-17.md` | Multi-rule readiness snapshot before current coverage and register state. |
| `BATTLE_PHASE_RULES_DEEP_AUDIT_2026-06-16.md` | Phase/rules audit before newer replay/action/forensic instrumentation. |
| `CARD_BATTLE_RULES_CANONICALIZATION_AUDIT_2026-06-16.md` | Canonicalization audit before current rule queue/template findings. |
| `LOREHOLD_BATTLE_MODEL_COVERAGE_MATRIX_2026-06-16.md` | Lorehold model coverage matrix before runtime-safe coverage and learned-deck coherence audits. |
| `LOREHOLD_MIRACLE_TOPDECK_READINESS_AUDIT_2026-06-17.md` | Topdeck readiness before current Pyroblast/Birgi closures and event contract audit. |

Operational reading: these docs should get either a short "superseded/current
status" pointer or be listed in a documentation index with their status.

## Runtime Surface Inventory

Current battle-related local scripts/tests found by filename scan:

- `96` Python files across `docs/hermes-analysis/manaloom-knowledge/scripts`,
  `server/bin`, and `server/test`.
- Core battle engine: `battle_analyst_v9.py` (`13838` lines, `290` top-level
  functions, `8` classes).
- Current replay renderer: `battle_replay_v10_3.py`.
- Current audit/gate scripts:
  - `battle_action_critic.py`
  - `battle_decision_strategy_auditor.py`
  - `replay_decision_auditor.py`
  - `battle_forensic_audit.py`
  - `battle_decision_research_review.py`
  - `battle_effect_coverage_audit.py`
- Current rule/data support:
  - `battle_rule_registry.py`
  - `sync_battle_card_rules.py`
  - `sync_battle_card_rules_pg.py`
  - `derive_functional_tags_from_battle_rules.py`
  - `reviewed_battle_card_rules.py/json`
- Server-side review/promotion pipeline:
  - `server/bin/manaloom_battle_rule_review_queue.py`
  - `server/bin/manaloom_battle_rule_focused_evidence.py`
  - `server/bin/manaloom_battle_rule_promotion_gate.py`
  - `server/bin/auto_promote_battle_rules.py`
  - `server/bin/generate_card_replays.py`
  - `server/bin/learned_deck_coherence_audit.py`

Risk: the automated battle-strategy audit has a curated required-file list, but
the total battle surface is broader. A green recurring audit proves the current
core gates, not exhaustive coverage of all battle-related helper scripts,
server-side queue tools, or historical optimizer paths.

## Current Recurring Audit Flow

`/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
currently does:

1. validates required files exist;
2. compiles core scripts/tests;
3. runs focused tests:
   - `test_battle_analyst_v10_3.py`
   - `test_battle_action_critic.py`
   - `test_battle_decision_strategy_auditor.py`
   - `test_battle_decision_research_review.py`
   - `test_battle_replay_v10_3_renderer.py`
   - `test_battle_effect_coverage_known_cards.py`
   - `test_battle_rule_registry_runtime_safe.py`
   - `test_battle_forensic_audit_supported_effects.py`
   - `test_replay_decision_auditor_scope.py`
4. for each seed, generates:
   - `replay.txt`
   - `replay.events.jsonl`
   - `replay.decision_trace.jsonl`
   - `action_critic.json/md`
   - `strategy_audit.json/md`
   - `replay_decision_audit.json/md`
   - `forensic_audit.json/md`
5. runs aggregate:
   - `battle_decision_research_review.py`
   - `battle_effect_coverage_audit.py`
6. writes `summary.json` and `summary.md`;
7. alerts when:
   - action high/critical exists;
   - strategy blockers exist;
   - replay decision high/critical exists;
   - forensic high/critical exists;
   - `effect_coverage_unknowns` exceeds
     `MANALOOM_BATTLE_EFFECT_COVERAGE_UNKNOWN_ALERT_THRESHOLD` when that env var
     is set.

## Latest Summary Checked

Latest summary at inspection time:

- path:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `timestamp_utc`: `2026-06-19T16:10:12Z`
- `run_dir`:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_161012`
- `start_seed`: `786135854`
- `seeds_completed`: `1`
- `events`: `1071`
- `decisions`: `152`
- `action_findings`: `0`
- `strategy_findings`: `0`
- `decision_audit_turn_findings`: `0`
- `decision_audit_decision_findings`: `0`
- `forensic_rule_findings`: `0`
- `forensic_turn_findings`: `0`
- `decision_audit_status_scope`: `turn_and_decision_trace_invariants`
- `decision_audit_human_replay_complete`:
  `not_evaluated_by_replay_decision_auditor`
- `decision_audit_rules_interaction_trusted`:
  `not_evaluated_by_replay_decision_auditor`
- `effect_coverage_unknowns`: `33`
- `heuristic_effects`: `120`
- `trigger_not_explicit`: `147`
- `cast_permission_not_explicit`: `89`
- `runtime_safe_rule_names`: `1702`
- `active_or_review_rule_names`: `3159`
- `review_only_rule_names`: `1457`
- `review_only_rule_instances`: `34`
- high/critical/blocker seed lists: all empty.

No high/critical notification condition was present.

## Validation Commands Run

- `python3 -m py_compile` for core battle/replay/critic/forensic/coverage/rule
  scripts plus server rule queue/promotion/coherence scripts: PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_replay_decision_auditor_scope.py`: PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_rule_registry_runtime_safe.py`: PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py`: PASS.

## Findings

### Documentation source-of-truth gap

There is no single current documentation index marking each battle document as
`current`, `historical`, `superseded`, or `background`. Several important docs
from 2026-06-15 to 2026-06-17 are still easy to find and do not point to the
2026-06-19 validation register.

Impact: a future agent may pick an older `PASS_WITH_RISKS`, truth study, or
slice spec as the current state and miss newer event-contract, runtime-safe, or
coverage findings.

### Runtime surface manifest gap

The recurring automation is strong for the curated core suite, but the battle
surface contains `96` related Python files. There is no explicit manifest that
maps every battle script/helper/test to one of:

- core runtime;
- replay renderer;
- recurring audit gate;
- rule registry/sync;
- server review queue;
- focused evidence/promotion;
- learned-deck source/coherence;
- optimizer/card scorecard;
- historical/deprecated.

Impact: "all battle is green" can be overread. The current automation proves the
core recurring audit path, not necessarily the full battle-related repository
surface.

## Recommended Register Updates

- Add a P2 documentation finding for a source-of-truth/status index.
- Add a P2/P1 runtime-surface finding for an explicit script/test manifest.
- Keep `BATTLE_VALIDATION_REGISTER_2026-06-19.md` as the live source until such
  an index exists.
