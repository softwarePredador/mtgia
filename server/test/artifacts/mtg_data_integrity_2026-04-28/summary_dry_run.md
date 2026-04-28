# MTG Data Integrity Dry-run Summary

- Mode: `dry_run`
- Artifact dir: `test/artifacts/mtg_data_integrity_2026-04-28`
- Duplicate `LOWER(sets.code)` groups: 80
- Duplicate set-code variants: 160
- `cards.color_identity IS NULL`: 33138
- Recent/future null color identities: 899
- Future null color identities: 0
- Deterministic backfill candidates: 33138
- Unresolved rows: 0
- DB mutations: `false`
