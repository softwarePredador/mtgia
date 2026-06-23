# Lorehold Variant 03 / Deck 608 Intake

Generated at: `2026-06-23T01:45:00+00:00`

## Scope

- Input list:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_input_20260623_012923_deck03.txt`.
- Variant name: `Lorehold Variant 03 - Rafael Paste 2026-06-23`.
- Materialized isolated Hermes deck: `deck_id=608`.
- No official deck `6` swap was applied.
- No PostgreSQL `deck_cards` mutation was applied.

## PostgreSQL Deploy

- Logical deploy id: `PG055`.
- Physical artifact prefix: `pg054_lorehold_variant03...`.
- Reason for logical/physical mismatch: the package was generated before the
  concurrent `PG054 Deck 6 L6 Silence-Lock Batch` register entry was reconciled.
- PostgreSQL mutation scope: `cards` metadata only.
- Target cards:
  `Naktamun Lorespinner // Wheel of Fortune` and `Tablet of Discovery`.
- Precheck output:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant03_card_metadata_pg054_precheck_20260623_013138.out`.
- Apply output:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant03_card_metadata_pg054_apply_20260623_013138.out`.
- Postcheck output:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant03_card_metadata_pg054_postcheck_20260623_013138.out`.
- Rollback SQL:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant03_card_metadata_pg054_rollback_20260623_013138.sql`.

Postcheck:

- `target_rows=2`.
- `bad_cmc_rows=0`.
- `naktamun_missing_faces_rows=0`.
- `backup_rows=2`.

## Hermes Sync

- Oracle cache sync report:
  `docs/hermes-analysis/master_optimizer_reports/card_oracle_cache_from_pg_pg054_lorehold_variant03_20260623_013138.json`.
- Sync result: `cache_rows_written=3`, `pg_card_count=2`,
  `cache_count_before=4103`, `cache_count_after=4105`.

## Staging And Deck Proof

- Initial invalid dry-run:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_staging_20260623_013022.json`.
- Final valid dry-run:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_staging_20260623_013402.json`.
- Applied staging:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_staging_20260623_013409.json`.
- Final result: `variants=1 valid=1 invalid=0`.
- Variant hash:
  `4b733dfd11e6b0f892b1242458b4fa6522fb3fb13699ff1c612b1e1d6b0bddc0`.
- Materialized target deck id: `608`.
- Materialization backup id:
  `variant_target_608_20260623T013409Z_b92f17c3e87a`.
- Direct SQLite proof: `deck_cards.deck_id=608` has `68` rows, `100`
  total quantity, `99` main, and `1` commander.

## Battle-Rule Readiness

- Deck 608 auditor JSON:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck608_20260623_014500.json`.
- Deck 608 auditor Markdown:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck608_20260623_014500.md`.
- Counts: `high=43`, `medium=11`, `pass=14`.
- This is not a battle-ready pass. It is a queue for card-by-card battle-rule
  validation before using deck `608` as trusted simulation evidence.

## Deck 607 Refreshed Readiness

- Deck 607 auditor JSON:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck607_20260623_014500.json`.
- Deck 607 auditor Markdown:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck607_20260623_014500.md`.
- Counts: `high=55`, `medium=16`, `pass=23`.

## Opponent Deck Inclusion

- Exact latest battle opponent inventory:
  `docs/hermes-analysis/master_optimizer_reports/latest_battle_opponent_learned_decks_inventory_20260623_013710.json`.
- Human report:
  `docs/hermes-analysis/master_optimizer_reports/latest_battle_opponent_learned_decks_inventory_20260623_013710.md`.
- Source artifact:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`.
- Unique learned opponent decks: `12`.
- Learned deck ids:
  `25`, `31`, `42`, `54`, `58`, `62`, `74`, `83`, `84`, `104`, `105`,
  `116`.
- Identity coverage across opponent card instances:
  `card_instances=1200`, `resolved_instances=1151`,
  `oracle_resolved_instances=49`, `unresolved_instances=0`,
  `ambiguous_instances=0`, `semantic_identity_coverage=1.0`.
- No opponent PostgreSQL mutation was applied because the identity audit found
  no unresolved or ambiguous blocker.

## Current Gate

- Deck `608` can be compared only after resolving or explicitly waiving its
  high-priority battle-rule queue.
- Deck `607` remains in the same queue state, with more high-severity findings
  than deck `608`.
- Opponent learned decks are now inventoried for the latest battle pool; their
  executable battle-rule quality still needs a dedicated card-by-card gate
  before claiming full battle fidelity.
