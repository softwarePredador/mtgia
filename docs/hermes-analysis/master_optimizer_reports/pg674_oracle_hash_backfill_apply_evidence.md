# PG674 Oracle Hash Backfill Evidence

- Generated UTC: `2026-07-08T22:17:46Z`
- Database target: `127.0.0.1:15432/halder`
- Operation: `trusted_battle_rule_oracle_hash_backfill`
- Candidate rows: `44`
- Updated rows: `44`
- Rule fields changed: `oracle_hash`, `updated_at`
- Rule behavior fields changed: `0`
- Hash source: `md5(cards.oracle_text)` joined by `card_battle_rules.card_id`
- Follow-up sync: `pg674_oracle_hash_backfill_pg_to_sqlite_sync.json`
- Contract recheck: `/tmp/pg_hermes_sqlite_contract_audit_20260708_post_pg674_hash_backfill.json`
- Contract status: `pass`, `51/51`

Sample updated rows:

| Card | Logical Rule Key | Oracle Hash |
| --- | --- | --- |
| Akroma's Will | `battle_rule_v1:1134718ef1509d04fbc1291dbdbdf23e` | `006e2b72eae264e2aaba82d99d07f593` |
| Ancient Den | `battle_rule_v1:ea7e00f2d90b2ceead4036ab10cd0200` | `c7264c311c98ff99b293a96ad9ab2daf` |
| Ancient Tomb | `battle_rule_v1:c364544e9bd651211acf851db2313ccd` | `5f61966c5bfc67508502d929ca891af3` |
| Angel's Grace | `battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227` | `627c4ce7adf5be44b93e2b850159e5d9` |
| Fellwar Stone | `battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba` | `d63befc8ac40d9a38732f9b5c1a7414a` |
