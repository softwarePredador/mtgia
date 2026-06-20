# Battle Runtime Surface Trusted Scope Audit - 2026-06-19T19:00Z

## Scope

Read-only audit of what the current trusted recurring battle run does and does
not prove about the broader battle runtime surface. This refreshes the earlier
outside-recurring report against the current `latest` state.

No PostgreSQL changes, swaps, runtime-code edits, automation edits, or commits
were made.

## Sources

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/runtime_surface_manifest.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/runtime_surface_manifest.md`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- `docs/hermes-analysis/master_optimizer_reports/battle_runtime_surface_outside_recurring_audit_20260619_175415.md`

## Latest Status

| Metric | Value |
| --- | ---: |
| `timestamp_utc` | `2026-06-19T18:47:21Z` |
| `battle_replay_final_status` | `trusted_for_strategy_learning` |
| `battle_replay_final_status_reason` | `all_mandatory_gates_pass` |
| `mandatory_gate_divergences` | `[]` |
| `seeds_completed` | `16` |
| `events` | `14679` |
| `decisions` | `2265` |
| `seeds_with_high_or_critical_action_findings` | `[]` |
| `seeds_with_strategy_blockers` | `[]` |

There is no current high/critical action or strategy-blocker notification
condition.

## Runtime Surface Counts

The latest manifest classifies `108` related Python files with `0`
unclassified files.

| Automation coverage | Files |
| --- | ---: |
| `covered_by_recurring_run` | `29` |
| `imported_by_core_runtime` | `6` |
| `outside_recurring_run` | `73` |

| Gate expectation | Files |
| --- | ---: |
| `recurring_audit_required` | `29` |
| `core_runtime_import_regression` | `6` |
| `targeted_manual_gate_required_before_change` | `31` |
| `targeted_test_required_before_change` | `42` |

Outside-recurring files by category:

| Category | Files |
| --- | ---: |
| `core runtime` | `23` |
| `optimizer/scorecard` | `15` |
| `rule registry/sync` | `14` |
| `learned-deck source` | `14` |
| `focused evidence/promotion` | `4` |
| `renderer` | `2` |
| `review queue` | `1` |

## Current Directed Test Sample

The following targeted tests were sampled in this audit and passed:

| Category | Command | Result |
| --- | --- | --- |
| `core runtime` | `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_mana_tests.py` | exit `0` |
| `core runtime` | `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py` | exit `0` |
| `rule registry/sync` | `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py` | `18` tests, OK |
| `optimizer/scorecard` | `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_master_optimizer_hashes.py` | `5` tests, OK |
| `learned-deck source` | `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_learned_deck_completeness.py` | `4` tests, OK |
| `renderer` | `python3 server/bin/test_battle_runtime_cli_paths.py` | `5` CLI help checks, PASS |

These tests are useful evidence across several outside-recurring categories.
They do not equal full coverage of all `73` outside-recurring files.

## Interpretation

It is correct to say:

- the recurring battle replay is trusted under the current mandatory gates;
- the runtime surface manifest is classified with no unclassified files;
- a targeted sample across core runtime, registry, optimizer, learned-deck
  source, and renderer passed in this audit.

It is not correct to say:

- the trusted recurring wrapper proves all `108` Python battle-related files;
- the `73` outside-recurring files are safe after any future change without
  their targeted gate;
- optimizer, learned-deck source, rule sync, focused promotion, review queue,
  and renderer surfaces are fully validated just because the battle replay
  wrapper is trusted.

`BV-053` can remain closed because the register and gate matrix already document
this distinction. The distinction still needs to be carried forward in future
readiness claims.

## Required Future Reading

Before accepting a broad battle readiness claim, identify:

1. the surface category touched;
2. whether it is `covered_by_recurring_run`, `imported_by_core_runtime`, or
   `outside_recurring_run`;
3. the specific `gate_expected` value in `runtime_surface_manifest.json`;
4. the current targeted evidence for that category.
