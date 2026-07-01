# PG295 XMage Batch PostgreSQL Package

Status: `applied_synced_e2e_passed`.

This package was generated from XMage batch proposals, applied to PostgreSQL,
synced to Hermes SQLite, exported to the canonical snapshot, and validated
end-to-end.

- Generated at: `2026-07-01T10:13:17+00:00`
- Selected cards: `["Baleful Strix", "Carven Caryatid", "Cloudkin Seer", "Council of Advisors", "Elvish Visionary", "Gallant Citizen", "Generous Stray", "Gryff Vanguard", "Helpful Hunter", "Joraga Visionary", "Jungle Barrier", "Kavu Climber", "Kindly Customer", "Merchant of Secrets", "Messenger Falcons", "Muse Drake", "Nimble Innovator", "Owlbear", "Pond Prophet", "Rhox Oracle", "Roving Harper", "Shaman of Spring", "Skyscanner", "Spirited Companion", "Striped Bears", "Tome Raider", "Wall of Blossoms", "Wistful Selkie"]`
- Families: `{"xmage_creature_etb_draw_cards": 28}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg295_xmage_creature_etb_draw_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg295_xmage_creature_etb_draw_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg295_xmage_creature_etb_draw_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg295_xmage_creature_etb_draw_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg295_xmage_creature_etb_draw_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg295_xmage_creature_etb_draw_wave_package.md`

Apply gate:

- PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg295_xmage_creature_etb_draw_wave_pg_apply_evidence.md`
- Precheck: `28/28` target rows found, `0` expected rows already present,
  `10` stale shadow rows scheduled for deprecation.
- Postcheck: `28/28` promoted rows, `28/28` verified/auto,
  `28/28` matching Oracle hash, `10` shadow rows backed up, `0` failed cards.
- PG -> Hermes/SQLite sync loaded `28` PostgreSQL rows, inserted/updated `38`
  SQLite rows including deprecated shadow rows, and exported `4280` canonical
  snapshot rows.
- E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg295_xmage_creature_etb_draw_wave_e2e_validation.md`
- E2E result: PostgreSQL `28/28`, SQLite `28/28`, canonical snapshot `28/28`,
  runtime `get_card_effect` `28/28`.
