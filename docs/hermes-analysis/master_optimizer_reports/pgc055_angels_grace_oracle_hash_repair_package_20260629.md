# PGC055 Angel's Grace Oracle Hash Repair

Purpose: restore current PostgreSQL provenance drift for the active
`Angel's Grace` runtime row so the Hermes battle runtime receives the reviewed
Oracle hash and split-second/cannot-lose runtime metadata from the source of
truth.

- Card: `Angel's Grace`
- Rule: `battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227`
- Expected hash source: `md5(cards.oracle_text)`
- Expected hash: `627c4ce7adf5be44b93e2b850159e5d9`
- Scope: metadata/provenance only; no deck composition change.

Files:

- `pgc055_angels_grace_oracle_hash_repair_precheck_20260629.sql`
- `pgc055_angels_grace_oracle_hash_repair_apply_20260629.sql`
- `pgc055_angels_grace_oracle_hash_repair_postcheck_20260629.sql`
- `pgc055_angels_grace_oracle_hash_repair_rollback_20260629.sql`
