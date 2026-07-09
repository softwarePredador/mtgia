# PG688 Artifact-Only Tokens Evidence - 2026-07-09

Status: `applied_and_validated`.

Database target:

- `server/bin/with_new_server_pg.sh`
- `127.0.0.1:15432/halder`

## Scope

PG688 promoted the artifact-only token subpattern for XMage creature ETB/dies
token creation. The runtime now preserves noncreature artifact tokens as
artifact tokens instead of coercing them into creature tokens or rejecting them.

Promoted cards:

- `Argothian Opportunist`
- `Beamsaw Prospector`
- `Blood Servitor`
- `Cartographer's Companion`
- `Crustacean Commando`
- `Falkenrath Celebrants`
- `Fierce Witchstalker`
- `Forecasting Fortune Teller`
- `Galactic Wayfarer`
- `Koilos Roc`
- `Mintstrosity`
- `Powerstone Engineer`
- `Slithering Cryptid`
- `Spyglass Siren`
- `Stone Retrieval Unit`
- `Waterwind Scout`

Runtime scopes:

- `xmage_creature_etb_create_tokens_v1`: `13`
- `xmage_creature_dies_create_tokens_v1`: `3`

## Implementation

- `xmage_authoritative_exact_scope_split.py` now accepts artifact-only token
  classes where `CardType.ARTIFACT` is present, `CardType.CREATURE` is absent,
  no power/toughness is defined, and the description is a token.
- Known artifact-only token metadata is carried for Food, Clue, Powerstone,
  Blood, Map, Lander, and generic artifact-only tokens.
- `battle_analyst_v9.py` creates `Artifact Token - {Subtype}` permanents with
  `artifact_token=true`, no power/toughness, and no creature type line.
- `xmage_batch_pg_package_builder.py` and
  `battle_package_end_to_end_validation.py` now require artifact-only token
  expectations to remain noncreature through PG, SQLite, snapshot, runtime, and
  replay execution.

## PostgreSQL Evidence

PG688 package:

- Candidate split:
  `xmage_authoritative_exact_scope_split_20260709_pg688_artifact_only_tokens_candidate.*`
  found `16` proposals and `16` batch-safe candidates.
- Precheck:
  `16` target rows, `0` existing rule rows, `0` shadow rows to deprecate.
- Apply:
  `16` upserted rows, `0` deprecated shadow rows.
- Postcheck:
  `16/16` promoted rows, `16/16` `verified/auto`, `16/16` with
  `oracle_hash`.

PG688b metadata repair:

- Precheck:
  `44` old trusted executable rules were missing `oracle_hash`; all `44` had
  safe `cards.oracle_text`; `0` unsafe missing-hash rows.
- Apply:
  `44` metadata-only `oracle_hash` updates from `md5(cards.oracle_text)`.
- Postcheck:
  `0` trusted executable rules still missing `oracle_hash`; `44/44`
  backfilled rows match the computed Oracle hash.

## Sync And E2E

PG -> SQLite/snapshot sync after PG688b:

- `pg_rows_loaded=6104`
- `sqlite_inserted_or_updated=6089`
- `canonical_snapshot_rows_exported=6066`

End-to-end package validation after PG688b:

- `status=pass`
- PostgreSQL source rows validated: `16`
- SQLite Hermes rows validated: `16`
- Snapshot cards validated: `16`
- Runtime lookup cards validated: `16`
- Battle execution: `16` scenarios, `36` events.

Validated artifact-only token behavior includes:

- Food, Clue, Powerstone, Blood, Map, Lander, and Mutagen token creation.
- Powerstone Engineer creates a tapped Powerstone token on dies.
- Falkenrath Celebrants creates two Blood artifact tokens and preserves menace.
- Koilos Roc preserves flash/flying and creates a Powerstone artifact token.
- Spyglass Siren and Waterwind Scout preserve flying and create Map artifact
  tokens.

## Tests And Audits

Focused tests:

- `1522 passed, 230 subtests passed`

Audits:

- `quality_gate.sh server-target`: pass.
- `xmage_strategy_consistency_audit`: `26/26` pass.
- `operational_surface_alignment_audit`: pass.
- `legacy_contamination_audit`: pass.
- `pg_hermes_sqlite_contract_audit` after PG688b: `51/51` pass.

## Current Global State

Strict product-aligned count after PG688b:

- All card rows: `34331`
- Function-classified cards: `25380`
- Trusted executable battle cards with `oracle_hash`: `6059`
- Cards with both function classification and trusted executable battle rule
  with `oracle_hash`: `4644`

Readiness after PG688b:

- `battle_and_oracle_ready`: `6164`
- `battle_family_mapper_required`: `27712`
- `generic_runtime_or_no_card_rule`: `359`
- `commander_illegal_block`: `2997`

Commander-legal XMage queue after PG688b:

- Target pending identities: `24789`
- XMage authoritative source resolved: `24476`
- Missing local XMage source exceptions: `313`
- Parser gaps: `0`
- Adapter-required identities: `24476`
- Adapter work units: `11311`

Post-PG688b exact-scope recheck:

- `proposal_count=0`
- `safe_for_batch_pg_package_count=0`

Interpretation: PG688 is drained. The next progress unit must implement a new
adapter/runtime subpattern before another PostgreSQL package can be generated.

Lorehold 607 side effect after PG688b hash repair:

- Fully aligned unique cards: `91/94`
- Fully aligned by deck quantity: `97/100`

Remaining Lorehold 607 strict gaps are battle-rule gaps, not function-tag gaps:

- `Command Tower`
- `Lorehold, the Historian`
- `Sol Ring`
