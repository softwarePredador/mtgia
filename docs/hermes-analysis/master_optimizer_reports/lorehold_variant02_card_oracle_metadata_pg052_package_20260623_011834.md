# PG053 Lorehold Variant 02 Card Oracle Metadata Package

Canonical register id:

- `PG053`.
- The executed SQL/output artifact filenames retain the physical prefix
  `pg052_lorehold_variant02...` because the package was applied before the
  concurrent `PG052 Valakut Awakening Hash-Only Repair` was observed and
  reconciled.

Purpose:

- Unblock Lorehold Variant 02 structural validation.
- Fix PostgreSQL `cards.cmc` for three Marvel cards already present with real
  oracle/mana cost but stale `cmc=0`.
- Insert missing PostgreSQL `cards` row for `Molecule Man` from Scryfall oracle
  data.
- No deck swap, no `deck_cards` PostgreSQL mutation, and no battle-rule
  mutation.

Target rows:

- `Molecule Man`: insert, CMC `6`, color identity `[]`.
- `The Mind Stone`: update CMC from `0` to `2`.
- `The Scarlet Witch`: update CMC from `0` to `3`.
- `Thor, God of Thunder`: update CMC from `0` to `5`.

Source:

- Scryfall named-card API lookup performed locally on 2026-06-23 UTC.

Files:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant02_card_oracle_metadata_pg052_precheck_20260623_011834.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant02_card_oracle_metadata_pg052_apply_20260623_011834.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant02_card_oracle_metadata_pg052_postcheck_20260623_011834.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant02_card_oracle_metadata_pg052_rollback_20260623_011834.sql`.

Expected postcheck:

- `target_rows=4`.
- `bad_cmc_rows=0`.
- `missing_oracle_rows=0`.
- `off_lorehold_color_identity_rows=0`.
- `backup_rows=3` when `Molecule Man` did not exist before apply.
