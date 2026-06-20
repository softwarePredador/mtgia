# Battle Runtime Surface Outside Recurring Audit - 2026-06-19 17:54Z

## Scope

This report records what the recurring local battle audit does and does not
cover for the current runtime surface. It is documentation-only: no PostgreSQL
changes, no swaps, no code changes and no commit.

Primary source:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175415/runtime_surface_manifest.json`

Related latest summary:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175415/summary.json`

## Latest Context

The latest checked run is:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175415/`

Summary state:

- `battle_replay_final_status=review_required`
- `mandatory_gate_divergences=["focused_template_dispatch=review_required"]`
- `action_findings=0`
- `strategy_findings=0`
- `forensic_rule_findings=0`
- `seeds_with_high_or_critical_action_findings=[]`
- `seeds_with_strategy_blockers=[]`
- `seeds_with_high_or_critical_forensic_findings=[]`

The active current gate gap remains `focused_template_dispatch`: 29 focused
template cards are still unsupported by focused evidence dispatch.

## Runtime Surface Counts

| Metric | Value |
| --- | ---: |
| Total related Python files | 108 |
| Unclassified files | 0 |
| Covered by recurring run | 29 |
| Imported by core runtime | 6 |
| Outside recurring run | 73 |

Category counts:

| Category | Files |
| --- | ---: |
| `core runtime` | 31 |
| `focused evidence/promotion` | 4 |
| `learned-deck source` | 14 |
| `optimizer/scorecard` | 15 |
| `recurring audit gate` | 24 |
| `renderer` | 4 |
| `review queue` | 1 |
| `rule registry/sync` | 15 |

Gate expectation counts:

| Gate expectation | Files |
| --- | ---: |
| `recurring_audit_required` | 29 |
| `core_runtime_import_regression` | 6 |
| `targeted_manual_gate_required_before_change` | 31 |
| `targeted_test_required_before_change` | 42 |

## Outside Recurring Surface

The 73 files outside the recurring run split as:

| Category | Outside recurring files |
| --- | ---: |
| `core runtime` | 23 |
| `focused evidence/promotion` | 4 |
| `learned-deck source` | 14 |
| `optimizer/scorecard` | 15 |
| `renderer` | 2 |
| `review queue` | 1 |
| `rule registry/sync` | 14 |

Operational reading: a clean recurring `summary.json` does not prove these
surfaces are safe after changes. Any change touching these areas needs the
targeted gate from `runtime_surface_manifest.json`.

High-signal outside recurring examples:

| Area | Examples | Required reading |
| --- | --- | --- |
| `core runtime` | `battle_mana_tests.py`, `battle_stack_casting_tests.py`, `battle_replacement_tests.py`, `battle_zone_transition_tests.py`, `battle_targeting_tests.py`, `battle_permanents_complex_tests.py` | Targeted test required before changing mechanics. |
| `focused evidence/promotion` | `server/bin/manaloom_battle_rule_focused_evidence.py`, `server/bin/manaloom_battle_rule_promotion_gate.py`, `server/bin/auto_promote_battle_rules.py` | Targeted manual gate and focused evidence tests required before promotion logic changes. |
| `review queue` | `server/bin/manaloom_battle_rule_review_queue.py` | Targeted manual gate required before changing template inference/review families. |
| `rule registry/sync` | `battle_rule_registry.py`, `sync_battle_card_rules.py`, `sync_battle_card_rules_pg.py`, `reviewed_battle_card_rules.py` | Targeted sync/registry tests required before changing rule source or runtime-safe logic. |
| `learned-deck source` | `learned_deck_completeness.py`, `materialize_learned_deck_to_deck_cards.py`, `auto_sync_learned_decks.py`, `learned_deck_coherence_audit.py` | Targeted learned-deck tests required before trusting battle metrics from learned decks. |
| `optimizer/scorecard` | `master_optimizer_*`, `slot_optimizer.py`, `universal_optimizer.py` | Targeted optimizer tests required before trusting swap or scorecard decisions. |
| `renderer` | `server/bin/generate_card_replays.py`, `server/bin/test_battle_runtime_cli_paths.py` | Targeted CLI/renderer checks required before relying on generated replay surfaces. |

## Targeted Tests Sampled

The following outside-recurring tests were executed in this audit cycle and
returned exit code 0:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_mana_tests.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_replacement_tests.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_tests.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_targeting_tests.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_combat_tests.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_permanents_complex_tests.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py`
- `python3 server/bin/test_auto_promote_battle_rules.py`
- `python3 server/bin/test_battle_runtime_cli_paths.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_sync_battle_card_rules_pg_selection.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_audit_multi_rule_runtime_readiness.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_learned_deck_completeness.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_materialize_learned_deck_to_deck_cards.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_master_optimizer_hashes.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_universal_optimizer_known_cards.py`

These passes are useful local evidence, but they are not the same as full
coverage of the 73 outside-recurring files.

## Required Adjustment

The register should treat recurring audit success as a mandatory gate result,
not as complete project-wide battle readiness. Before accepting any future
claim that battle is fully known or safe, the validation flow needs to identify:

1. which runtime surface category changed;
2. whether it is covered by the recurring run, imported by core runtime, or
   outside recurring;
3. which targeted manual gate or targeted test is required;
4. whether that targeted evidence exists for the current commit/worktree state.

## Register Update

Open finding added in
`docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md`:

- `BV-053`: recurring automation surface does not prove all battle-related
  runtime, learned-deck, optimizer, registry, promotion, review queue and
  renderer surfaces.
