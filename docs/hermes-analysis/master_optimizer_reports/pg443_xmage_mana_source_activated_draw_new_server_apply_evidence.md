# PG443 XMage Mana Source With Activated Draw Apply Evidence

- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- Family: `xmage_simple_mana_source_with_activated_draw`
- Battle model scope: `xmage_simple_tap_mana_source_with_activated_draw_v1`
- Selected cards: `17`
- Precheck: `17` targets, `0` missing, `0` existing expected rows, `2` shadow rows to deprecate.
- Apply: backup rows `2`, deprecated shadow rows `2`, upserted rows `17`, transaction `COMMIT`.
- Postcheck: `17/17` cards promoted as `verified`/`auto` with Oracle hash; `failed_cards=[]`.
- Sync: metadata matched `5423` PostgreSQL cards and `5333` SQLite aliases; deck card backfill remained `2699/2699`; full sync loaded `4258` PG rows, updated `4250` SQLite rows, and exported `4225` canonical snapshot rows.
- Validation: focused tests passed `718`; E2E package status `pass`; XMage strategy `26/26`; operational surface `pass`; legacy contamination `pass`; PG/Hermes/SQLite contract `51/51`.
- Queue after PG443: `target_identity_count=26628`, `xmage_authoritative_source_count=26314`, `xmage_missing_source_exception_count=314`, `parser_gap=0`, `xmage_authoritative_adapter_required_count=26314`.
- Split after PG443: `proposal_count=289`, `safe_for_batch_pg_package_count=289`; next largest family is `xmage_permanent_simple_activated_draw_discard` with `15` cards.

Cards:

- Abzan Banner
- Azorius Cluestone
- Boros Cluestone
- Dimir Cluestone
- Golgari Cluestone
- Gruul Cluestone
- Heart Warden
- Izzet Cluestone
- Jeskai Banner
- Letter of Acceptance
- Mardu Banner
- Orzhov Cluestone
- Rakdos Cluestone
- Selesnya Cluestone
- Simic Cluestone
- Sultai Banner
- Temur Banner
