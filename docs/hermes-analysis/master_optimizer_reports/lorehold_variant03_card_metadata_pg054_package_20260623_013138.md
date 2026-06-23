# PG054 Lorehold Variant 03 Card Metadata Package

Purpose:

- Unblock Lorehold Variant 03 structural validation.
- Correct stale PostgreSQL `cards.cmc` metadata for
  `Naktamun Lorespinner // Wheel of Fortune` and `Tablet of Discovery`.
- Add `layout=prepare` and `card_faces_json` for Naktamun so the prepared
  `Wheel of Fortune` face is not lost for future card-rule modeling.
- No deck swap, no PostgreSQL `deck_cards` mutation, and no battle-rule
  mutation.

Source:

- PostgreSQL precheck plus Scryfall named-card API lookup performed locally on
  2026-06-23 UTC.

Files:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant03_card_metadata_pg054_precheck_20260623_013138.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant03_card_metadata_pg054_apply_20260623_013138.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant03_card_metadata_pg054_postcheck_20260623_013138.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant03_card_metadata_pg054_rollback_20260623_013138.sql`.

Expected postcheck:

- `target_rows=2`.
- `bad_cmc_rows=0`.
- `naktamun_missing_faces_rows=0`.
- `backup_rows=2`.
