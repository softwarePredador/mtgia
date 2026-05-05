# MTG Data Integrity Dry-run Summary

- Mode: `dry_run`
- Artifact dir: `test/artifacts/mtg_data_integrity_2026-05-05_acqv2`
- Duplicate `LOWER(sets.code)` groups: 82
- Duplicate set-code variants: 164
- `cards.color_identity IS NULL`: 0
- Recent/future null color identities: 0
- Future null color identities: 0
- Deterministic backfill candidates: 0
- Unresolved rows: 0
- Updated rows: 0
- Null color identities after apply: 0
- DB mutations: `false`
