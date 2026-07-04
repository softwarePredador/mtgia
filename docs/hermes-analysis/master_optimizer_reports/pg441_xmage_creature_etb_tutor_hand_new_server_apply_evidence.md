# PG441 XMage Creature ETB Tutor To Hand Apply Evidence

- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- Family: `xmage_creature_etb_library_search_to_hand`
- Battle model scope: `xmage_creature_etb_library_search_to_hand_v1`
- Selected cards: `19`
- Precheck: `19` targets, `0` missing, `0` existing expected rows, `6` shadow rows to deprecate.
- Apply: backup rows `6`, deprecated shadow rows `6`, upserted rows `19`, transaction `COMMIT`.
- Postcheck: `19/19` cards promoted as `verified`/`auto` with Oracle hash; `failed_cards=[]`.
- Sync: metadata matched `5388` PostgreSQL cards and `5298` SQLite aliases; deck card backfill remained `2699/2699`; full sync loaded `4223` PG rows, updated `4215` SQLite rows, and exported `4190` canonical snapshot rows.
- Validation: focused tests passed `718`; E2E package status `pass`; XMage strategy `26/26`; operational surface `pass`; legacy contamination `pass`; PG/Hermes/SQLite contract `51/51`.
- Queue after PG441: `target_identity_count=26663`, `xmage_authoritative_source_count=26349`, `xmage_missing_source_exception_count=314`, `parser_gap=0`, `xmage_authoritative_adapter_required_count=26349`.
- Split after PG441: `proposal_count=324`, `safe_for_batch_pg_package_count=324`; next largest family is `xmage_static_flying_can_block_only_flying_creature` with `18` cards.

Cards:

- Borderland Ranger
- Civic Wayfinder
- Daru Cavalier
- Deadeye Quartermaster
- Environmental Scientist
- Farfinder
- Gatecreeper Vine
- Goblin Matron
- Heliod's Pilgrim
- Howling Wolf
- Nesting Wurm
- Ranger of Eos
- Rune-Scarred Demon
- Screaming Seahawk
- Squadron Hawk
- Sylvan Ranger
- Totem-Guide Hartebeest
- Transit Mage
- Tribute Mage
