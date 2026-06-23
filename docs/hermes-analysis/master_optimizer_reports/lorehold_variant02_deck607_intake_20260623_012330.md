# Lorehold Variant 02 Deck 607 Intake - 2026-06-23 01:23 UTC

Scope:

- Input decklist from Rafael was registered as
  `Lorehold Variant 02 - Rafael Paste 2026-06-23`.
- The variant was staged and materialized into isolated Hermes SQLite
  `deck_id=607`.
- Official Lorehold deck `6` was not changed.
- Prior Variant 01 deck `606` was not overwritten.
- No PostgreSQL `deck_cards` mutation or deck swap was applied.

Input:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_input_20260623_011430_deck02.txt`.

PostgreSQL card metadata deploy:

- Package:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant02_card_oracle_metadata_pg052_package_20260623_011834.md`.
- Canonical register id: `PG053`.
- Physical executed artifact prefix: `pg052_lorehold_variant02...`, retained
  after detecting a concurrent `PG052` Valakut package.
- Precheck output:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant02_card_oracle_metadata_pg052_precheck_20260623_011834.out`.
- Apply output:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant02_card_oracle_metadata_pg052_apply_20260623_011834.out`.
- Postcheck output:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant02_card_oracle_metadata_pg052_postcheck_20260623_011834.out`.
- Rollback SQL:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant02_card_oracle_metadata_pg052_rollback_20260623_011834.sql`.

PG053 result:

- `Molecule Man` inserted into PostgreSQL `cards` from Scryfall oracle data.
- `The Mind Stone` CMC corrected from `0` to `2`.
- `The Scarlet Witch` CMC corrected from `0` to `3`.
- `Thor, God of Thunder` CMC corrected from `0` to `5`.
- Postcheck passed with `target_rows=4`, `bad_cmc_rows=0`,
  `missing_oracle_rows=0`, `off_lorehold_color_identity_rows=0`, and
  `backup_rows=3`.

Hermes cache sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/card_oracle_cache_from_pg_pg052_lorehold_variant02_20260623_011834.json`.
- Synced `6` cache rows/aliases from PostgreSQL into local `knowledge.db`,
  including the `Emeria's Call` front-face alias.

Variant staging:

- First dry-run before PG052:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_staging_20260623_011455.json`.
- First status: invalid, because local oracle cache lacked
  `Emeria's Call`, `Molecule Man`, `The Mind Stone`,
  `The Scarlet Witch`, and `Thor, God of Thunder`.
- Final dry-run after PG052/Hermes sync:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_staging_20260623_012245.json`.
- Applied staging/materialization:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_staging_20260623_012310.json`.
- Variant hash:
  `a9234fbf61d175e03a731bdb234a0187d7845a58242cd7eebd85003c7f88c306`.

Direct SQLite proof:

- `deck_cards.deck_id=607`: `94` rows, `100` total quantity, `99` main,
  `1` commander.
- Staged variant row: `valid|100|99|1|0|19|a9234fbf61d175e0`.
- Staged oracle status: `matched|94`.
- Materialization backup id:
  `variant_target_607_20260623T012310Z_f5b9951f1f4b`.

Battle-rule audit:

- JSON:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck607_20260623_012330.json`.
- Markdown:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck607_20260623_012330.md`.
- Counts: `high=55`, `medium=16`, `pass=23`.

Current reading:

- Variant 02 is structurally valid and registered as deck `607`.
- Variant 02 is not ready for trusted battle comparison yet because
  `19` staged cards have no verified executable battle rule and the broader
  deck-card audit still shows `55` high-priority rule/coherence findings.
- The next work item is card-by-card battle-rule validation for `deck_id=607`,
  starting from the high-priority queue in
  `deck_card_battle_rule_coherence_audit_deck607_20260623_012330.md`.
