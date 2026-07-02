# PG351 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-02T04:21:24+00:00`
- Selected cards: `["Kraul Swarm", "Summoned Dromedary"]`
- Families: `{"xmage_graveyard_simple_activated_self_return_to_hand": 2}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg351_xmage_graveyard_self_return_hand_discard_creature_sorcery_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg351_xmage_graveyard_self_return_hand_discard_creature_sorcery_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg351_xmage_graveyard_self_return_hand_discard_creature_sorcery_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg351_xmage_graveyard_self_return_hand_discard_creature_sorcery_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg351_xmage_graveyard_self_return_hand_discard_creature_sorcery_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg351_xmage_graveyard_self_return_hand_discard_creature_sorcery_wave_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
