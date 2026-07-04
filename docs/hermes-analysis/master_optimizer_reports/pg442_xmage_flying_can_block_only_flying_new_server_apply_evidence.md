# PG442 XMage Flying Can Block Only Flying Apply Evidence

- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- Family: `xmage_static_flying_can_block_only_flying_creature`
- Battle model scope: `xmage_static_flying_can_block_only_flying_creature_v1`
- Selected cards: `18`
- Precheck: `18` targets, `0` missing, `0` existing expected rows, `0` shadow rows to deprecate.
- Apply: backup rows `0`, deprecated shadow rows `0`, upserted rows `18`, transaction `COMMIT`.
- Postcheck: `18/18` cards promoted as `verified`/`auto` with Oracle hash; `failed_cards=[]`.
- Sync: metadata matched `5405` PostgreSQL cards and `5315` SQLite aliases; deck card backfill remained `2699/2699`; full sync loaded `4241` PG rows, updated `4233` SQLite rows, and exported `4208` canonical snapshot rows.
- Validation: focused tests passed `718`; E2E package status `pass`; XMage strategy `26/26`; operational surface `pass`; legacy contamination `pass`; PG/Hermes/SQLite contract `51/51`.
- Queue after PG442: `target_identity_count=26645`, `xmage_authoritative_source_count=26331`, `xmage_missing_source_exception_count=314`, `parser_gap=0`, `xmage_authoritative_adapter_required_count=26331`.
- Split after PG442: `proposal_count=306`, `safe_for_batch_pg_package_count=306`; next largest family is `xmage_simple_mana_source_with_activated_draw` with `17` cards.

Cards:

- Belbe's Percher
- Cloud Djinn
- Cloud Dragon
- Cloud Elemental
- Cloud Pirates
- Cloud Spirit
- Cloud Sprite
- Hoverguard Observer
- Long-Finned Skywhale
- Rishadan Airship
- Scrapskin Drake
- Skywinder Drake
- Stratozeppelid
- Stronghold Zeppelin
- Tattered Haunter
- Vaporkin
- Wanderlight Spirit
- Welkin Tern
