# PG577 ETB Library Tutor Creatures E2E

Status: `pass`

## Scope

PG577 promotes 11 XMage-backed creature ETB library tutor rules:

- `xmage_creature_etb_library_search_to_top_v1`: 10 cards
- `xmage_creature_etb_library_search_to_battlefield_v1`: 1 card

Cards:

- Boggart Harbinger
- Campus Guide
- Compass Gnome
- Faerie Harbinger
- Flamekin Harbinger
- Giant Harbinger
- Giant Ladybug
- Kithkin Harbinger
- Loam Larva
- Scampering Surveyor
- Spider-Bot

## Runtime Contract Fixed

The parser no longer emits composite subtype strings for "basic land card or
Cave card". It now emits the canonical tutor target:

- `basic_land_or_cave_to_top`
- `basic_land_or_cave_to_battlefield`

The battle runtime resolves `basic_land_or_cave` by accepting effective lands
whose type line contains either `basic` or `cave`.

## Validation

Commands run:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile \
  docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_tests.py

PYTHONDONTWRITEBYTECODE=1 python3 \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py

PYTHONDONTWRITEBYTECODE=1 server/bin/with_new_server_pg.sh python3 \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_tests.py
```

Results:

- `py_compile`: pass
- exact-scope splitter tests: `Ran 675 tests ... OK`
- battle runtime suite: pass

Focused runtime coverage added:

- `test_compass_gnome_etb_puts_basic_land_or_cave_on_library_top`
- `test_scampering_surveyor_etb_puts_basic_land_or_cave_on_battlefield_tapped`

## PostgreSQL Apply

Apply evidence:

- precheck `row_count=11`
- precheck `missing_targets=[]`
- precheck `existing_expected_rows_before=0`
- postcheck `promoted_rule_rows=11`
- postcheck `promoted_verified_auto_rows=11`
- postcheck `promoted_oracle_hash_rows=11`
- postcheck `failed_cards=[]`

Direct PG spot check:

```text
campus guide|verified|auto|curated|xmage_creature_etb_library_search_to_top_v1|basic_land_to_top|library_top|
compass gnome|verified|auto|curated|xmage_creature_etb_library_search_to_top_v1|basic_land_or_cave_to_top|library_top|
faerie harbinger|verified|auto|curated|xmage_creature_etb_library_search_to_top_v1|any_to_top|library_top|
scampering surveyor|verified|auto|curated|xmage_creature_etb_library_search_to_battlefield_v1|basic_land_or_cave_to_battlefield|battlefield|true
```

## Hermes/SQLite Sync

Sync report:

- `pg_rows_loaded=11`
- `sqlite_inserted_or_updated=11`
- `canonical_snapshot_rows_exported=6647`

Direct SQLite spot check matched the PostgreSQL scopes and targets for Campus
Guide, Compass Gnome, Faerie Harbinger, and Scampering Surveyor.

## Queue Impact

Post-sync queue:

- `target_identity_count=25343`
- `xmage_authoritative_source_count=25029`
- `manual_semantic_decision_units_remaining=314`
- `tutor::xmage_library_search_variant_review_v1=567`

Compared with post-PG576, this removed 11 target identities and reduced the
tutor work unit from 578 to 567.

Post-PG577 exact-scope recheck:

- `proposal_count=0`
- `safe_for_batch_pg_package_count=0`

This means the ETB tutor subpattern currently has no remaining immediately
safe package after PG577.
