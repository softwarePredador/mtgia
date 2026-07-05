# PG490 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-05T07:37:32+00:00`
- Selected cards: `["Aether Adept", "Angler Drake", "Aven Fogbringer", "Bigfin Bouncer", "Dispersal Technician", "Exclusion Mage", "Glowing Anemone", "Iceridge Serpent", "Man-o'-War", "Mist Raven", "Peerless Ropemaster", "Riddlemaster Sphinx", "Separatist Voidmage", "Spider-Byte, Web Warden", "Stern Proctor", "Surrakar Banisher", "Voidwielder"]`
- Families: `{"xmage_creature_etb_return_target_to_hand": 17}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg490_creature_etb_bounce_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/xmage_pg490_creature_etb_bounce_new_server_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/xmage_pg490_creature_etb_bounce_new_server_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg490_creature_etb_bounce_new_server_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/xmage_pg490_creature_etb_bounce_new_server_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/xmage_pg490_creature_etb_bounce_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
