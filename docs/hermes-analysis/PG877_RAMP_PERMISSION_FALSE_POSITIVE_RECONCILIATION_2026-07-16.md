# PG877 Ramp Permission False-Positive Reconciliation - 2026-07-16

Status: `applied_postchecked` — apply committed and exact postcheck passed.

## Decision

The post-PG876 read-only audit identified `115` cards whose live ramp rows are
false under the executable production-versus-permission contract. Every target
has an exact UUID and one unambiguous cause; no `other_review_required` card is
allowed in the package.

- `71`: `payment_permission_as_though_any` — the card changes how existing
  mana may be spent, usually for a stolen or conjured spell;
- `32`: `payment_permission_any_type_can_be_spent` — the Oracle text says mana
  of any type can be spent, but creates no mana;
- `2`: `payment_permission_spend_any_type` — `Royal Booster` and `Vizier of
  the Menagerie` grant payment permission only;
- `10`: `commander_color_identity_phrase_collision` — role-only false
  positives caused by color-identity prose, with no mana production or other
  acceleration signal.

Target card-id SHA-256 is
`b8e4fa337a747efadfd6cb1ab57ed5796e75de7387f3c85fd39cb3f4e742cc98`.
The exact 115-card list, names, type lines, classifications, and all lane hashes
are retained in
`PG877_RAMP_PERMISSION_FALSE_POSITIVE_MANIFEST_2026-07-16.json`.

## Six real accelerators preserved

The first audit reported `121` candidates. Manual Oracle review found six
cards with real acceleration in a different sentence. They are excluded from
the remove manifest, recognized by the executable classifier, covered across
all Dart lanes and the Python replica, and snapshotted by PG877 so apply or
rollback aborts if any preserved row changes.

- `00461ce4-a65e-4da2-8a33-7785711b344c` — `Fallaji Wayfarer`: grants convoke
  to multicolored spells;
- `37a71d19-965e-4cba-949d-5b64d2200f57` — `Gonti, Canny Acquisitor`: spells
  cast but not owned cost `{1}` less;
- `59098116-a749-4c42-887e-73e89a7ced1a` — `The Paradise Bird`: creates a
  Birds of Paradise mana-dork token;
- `7fd85cb4-4026-4130-bc23-25024ea7b653` — `Gonti, Night Minister`: produces a
  Treasure token when a player casts a spell they do not own;
- `a7ae6e85-3821-468b-8873-68cd8147d5dd` — `The Snapstone Wielder`: mana
  counters provide spendable virtual mana each turn;
- `cff0f184-02d7-4c9d-8499-6ba6889b9002` — `Manascape Refractor`: copies all
  activated abilities of lands, including mana abilities.

Preserved card-id SHA-256 is
`02338acac46be3814fcbbb2e33de82b25ee078f6eea56daa3c0bd87376030e6e`.
Live preserved rows are `4` heuristic functions, `4` semantic functions, `6`
heuristic roles, and `4` semantic JSON snapshots.

## Exact live prestate

The approval-gated precheck was executed read-only after PG876 and returned
`PG877_PRECHECK_PASS`.

- target input count/hash: `115` /
  `ffda83a778b6668059fa1fd983d56e591e5f3c2a1daa044216b8c08d379838a2`;
- heuristic ramp function rows: `105`, card-id SHA-256
  `57d6d74ea3cdf21ed4b3190ef3309616a885d377e85935a7b5f779adba3e446c`;
- semantic ramp function rows: `105`, with the same exact card-id SHA-256;
- heuristic ramp role rows: `115`, row-key SHA-256
  `2457d7e9893b1bb942b3f8aa152e9ae601695e89af354cb0a7bfdfe82853767d`;
- semantic snapshots containing ramp: `105`, with the same exact card-id
  SHA-256 as the function lanes;
- semantic snapshots containing only ramp: `22`.

The two function lanes and semantic JSON lane contain the same `105` UUIDs.
The additional ten targets are role-only color-identity collisions. Cross-lane
semantic function-versus-JSON drift is `0`.

## Persisted deck and usage impact

The exact 115-card scope appears in `28` PostgreSQL `deck_cards` rows across
`24` decks and `11` target cards. It also appears in `8`
`commander_card_usage` rows, covering `8` target names and `54` accumulated
uses. Those two tables store membership/quantity or name/count data only; they
have no functional-role or semantic-tag columns, so no sync mutation is
required. PG877 snapshots both complete reference sets, locks them during
apply/rollback, and requires byte-for-byte equality in apply, postcheck, and
rollback. Their exact hashes are retained in the manifest.

Hermes SQLite contains `12` matching `deck_cards` rows across `9` decks and
`6` target cards. All already contain zero ramp tags. The Lorehold variant
snapshot contains one matching row (`Commander's Plate`), also with zero ramp
tags. Protected deck `6` contains none of the 115 targets and retains deck hash
`a83b580d42e20ef7fdf285e6498fb3972ce07b54fa6b7359abac8717476014b4`.
Therefore no Hermes write or Battle sync is needed. The read-only
`pg877_ramp_permission_surface_guard.py` fail-closes on membership, tag-surface,
variant, or protected-deck drift and currently returns
`PG877_HERMES_SURFACE_GUARD_PASS`.

## Applied remove-only transaction

PG877 never inserts a missing ramp row and never performs a full deterministic
backfill. It removes only:

- target `ramp` rows from `card_function_tags` owned by
  `deterministic_heuristic_v1` or `deterministic_semantic_v2`;
- target `ramp` rows from `card_role_scores` owned by
  `deterministic_heuristic_v1`;
- the `ramp` element from the exact existing semantic-v2 snapshots.

For semantic JSON, `83` rows retain other tags and are rebuilt with derived
confidence, enabler, and explanation fields. Their expected content SHA-256 is
`d06f7f53ec19b866e6b9e9160af69ca6b977ef623bf72eaf7d0c4926c236d4fa`.
The expected projection explicitly casts all `83` rebuilt
`role_confidence` values to the table typmod `numeric(4,3)` before hashing, so
the precheck representation (`0.72`) and stored representation (`0.720`) do
not create a false poststate mismatch.
The `22` snapshots whose only tag is ramp are deleted instead of leaving an
invalid empty partial snapshot.

Apply snapshots the exact target inputs, selected prestate, all untouched rows
for target cards, the six-card preserved lanes, and the complete semantic
poststate under `manaloom_deploy_audit`, plus the exact `deck_cards` and
`commander_card_usage` references. It locks all affected PostgreSQL tables and
aborts on any count, ID, content hash, untouched-row, input, preserved-row, or
reference drift. It does not modify cards, legalities, decks, commander usage,
battle rules, meta inputs, or any unrelated source row.

Rollback first requires the exact captured poststate, unchanged target inputs,
unchanged untouched rows, and unchanged preserved rows. It then restores the
original function, role, and semantic rows with their original timestamps and
verifies byte-for-byte equality plus the original hashes.

The first apply attempt aborted and rolled back in full because the expected
hash used an untyped numeric representation (`0.72`) while PostgreSQL persists
`role_confidence` as `numeric(4,3)` (`0.720`). After an independent read-only
proof across all `83` rebuilt rows, the expected projection was corrected to
the table typmod and the source contract was strengthened against regression.

The corrected apply committed on 2026-07-16. It deleted `210` ramp function
rows, `115` ramp role rows, rebuilt `83` semantic snapshots, and deleted the
`22` ramp-only snapshots. The immediate read-only postcheck returned
`PG877_POSTCHECK_PASS`: all remaining target ramp counts are `0`, every input,
untouched, preserved, deck-reference, usage-reference, and semantic-post diff
is `0`, and the semantic post hash is the expected `d06f7f53...` value.
The rollback remains available and guarded by the exact captured poststate.

## Package and validation

- `PG877_RAMP_PERMISSION_FALSE_POSITIVE_MANIFEST_2026-07-16.json`
- `pg877_ramp_permission_false_positive_reconciliation_20260716_precheck.sql`
- `pg877_ramp_permission_false_positive_reconciliation_20260716_apply.sql`
- `pg877_ramp_permission_false_positive_reconciliation_20260716_postcheck.sql`
- `pg877_ramp_permission_false_positive_reconciliation_20260716_rollback.sql`
- source contract:
  `server/test/ramp_permission_pg877_reconciliation_source_test.dart`
- classifier contract: `server/test/ramp_family_classifier_test.dart`
- read-only audit: `server/bin/ramp_family_audit.dart`
- read-only Hermes/protected guard:
  `manaloom-knowledge/scripts/pg877_ramp_permission_surface_guard.py`

Precheck, corrected apply, postcheck, the fresh family audit, the Hermes surface
guard, and the protected Battle deck identity guard were executed. The fresh
family audit reports zero persisted ramp rows to remove; the Hermes guard
returns `PG877_HERMES_SURFACE_GUARD_PASS`; protected deck `6` remains unchanged.
