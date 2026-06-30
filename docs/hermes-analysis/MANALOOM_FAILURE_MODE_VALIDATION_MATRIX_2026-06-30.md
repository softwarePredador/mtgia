# ManaLoom Failure Mode Validation Matrix

Status: `current_guardrail`
Updated: 2026-06-30

Use this matrix before claiming ManaLoom battle, card-rule, deckbuilding, or
Hermes/PostgreSQL work is aligned. The purpose is to catch classes of failure,
not only the last bug reported by the user.

## Required Gate Sequence

1. Worktree and evidence hygiene
   - Run `git status --short --branch --untracked-files=all`.
   - Confirm the branch name before committing or merging.
   - Treat untracked `master_optimizer_reports/*` files as evidence that must
     either be staged intentionally, discarded intentionally, or attributed to a
     parallel agent.

2. PostgreSQL, Hermes, SQLite, and field aliases
   - Run `pg_hermes_sqlite_contract_audit.py`.
   - Required pass conditions:
     - `deck_cards.card_id` has no drift from `card_oracle_cache.card_id`.
     - `card_intelligence_snapshot.id` matches `card_intelligence_snapshot.card_id`.
     - `card_intelligence_snapshot.name` matches `card_intelligence_snapshot.card_name`.
     - Name aliases are accepted only when `card_id` matches.
   - Known warning allowed until touched: old trusted executable battle rules
     missing `oracle_hash`.

3. Workspace static drift
   - Run `workspace_contract_drift_audit.py`.
   - Required pass conditions:
     - Active scripts point to the active SQLite path.
     - No stale zero-byte sibling `knowledge.db` remains.
     - Cron scripts include PG -> Hermes -> SQLite sync before local generation.
     - No direct one-to-many card joins without aggregate/group boundary.
     - `card_intelligence_snapshot` joins are anchored on card identity fields,
       not names.

4. Operational surface
   - Run `operational_surface_alignment_audit.py`.
   - Required pass conditions:
     - Current docs point to the definitive XMage and Commander contracts.
     - Historical builders remain blocked or marked as historical.
     - Active handoff paths reference current reports and contracts.

5. XMage/card-rule flow
   - Run `xmage_strategy_consistency_audit.py`.
   - Required pass conditions:
     - XMage broad extraction remains review/family routing only.
     - Generic `xmage_*_review_v1` scopes do not become executable PG truth.
     - Pattern registry rows remain shadow-only and non-autopromotable.
     - Card-level proof requires drawn/used evidence or focused runtime tests.

6. Commander deckbuilding flow
   - Run `deckbuilding_contract_surface_audit.py`.
   - Required pass conditions:
     - `/ai/generate` exposes `deckbuilding_contract`.
     - Current builder uses commander intent, reference lanes, learned deck,
       deterministic shell, validation, strategy matrix, and battle gate as
       separate evidence gates.
     - Runtime card rules are not used as proof that a card belongs in a deck.

7. Lorehold-specific evidence gates
   - Run `lorehold_artifact_contract_audit.py`.
   - Run `lorehold_promotion_gate_decision_audit.py`.
   - Required pass conditions:
     - Current matrix schema is `decks[] + ranked_deck_keys`.
     - `ranked_decks` is legacy and must be normalized before use.
     - Deck `607` remains protected baseline until equal battle gate plus
       decision trace proves replacement.

8. Test gate
   - Run focused pytest for all modified auditors and their dependent gates.
   - If an audit script has no unit test, report that as a validation gap.

## Failure Classes To Actively Search

| Class | Example | Required Response |
| --- | --- | --- |
| Alias drift | `id` vs `card_id`, `name` vs `card_name`, `oracle_id` vs `scryfall_id` | Add or run parity check; prefer canonical field in new code |
| Name identity leakage | Joining by `card_name` or `normalized_name` when `card_id` is available | Treat as fail unless it is only a resolver/cache lookup |
| One-to-many fanout | Direct deck join to `card_function_tags`, `card_semantic_tags_v2`, or `card_battle_rules` | Aggregate by `card_id` or use `card_intelligence_snapshot` |
| Runtime overclaim | Battle aggregate used as card-level proof | Require drawn/used trace or focused runtime test |
| Source-boundary drift | Hermes overwrites PostgreSQL truth | Stop and reroute through PG-backed sync/apply workflow |
| Historical artifact reuse | Old matrix/report consumed without schema normalization | Run artifact contract audit before using it |
| Parallel-agent evidence loss | Reports remain untracked or branch unknown | Attribute, stage, or discard intentionally before merge |
| External data misuse | 17Lands or Reddit treated as executable battle truth | Keep as strategy/methodology evidence only |

## Current Meta-Validation Evidence

- Workspace drift after cleanup:
  `master_optimizer_reports/workspace_contract_drift_audit_20260630_meta_validation_guardrail.md`
- PG/Hermes/SQLite field contract:
  `master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260630_meta_validation_guardrail.md`
- Operational surface:
  `master_optimizer_reports/operational_surface_alignment_audit_20260630_meta_validation.md`
- Deckbuilding surface:
  `master_optimizer_reports/deckbuilding_contract_surface_audit_20260630_meta_validation.md`
- XMage strategy:
  `master_optimizer_reports/xmage_strategy_consistency_audit_20260630_meta_validation.md`
- Lorehold artifact contract:
  `master_optimizer_reports/lorehold_artifact_contract_audit_20260630_meta_validation.md`
- Lorehold promotion decision:
  `master_optimizer_reports/lorehold_promotion_gate_decision_audit_20260630_meta_validation.md`

## Current Residual Risks

- `deckbuilding_contract_surface_audit.py` passes as a script but does not have
  a dedicated unit test file yet.
- Old trusted executable battle rules without `oracle_hash` remain a warning
  until those rules are touched or repromoted with exact Oracle fingerprint.
- Parallel agent reports must be reconciled before merge; do not assume an
  untracked report was reviewed.
