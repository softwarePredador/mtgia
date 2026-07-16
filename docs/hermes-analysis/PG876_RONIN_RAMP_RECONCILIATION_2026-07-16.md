# PG876 Ronin Ramp Reconciliation - 2026-07-16

Status: `applied_and_postchecked`.

## Finding

The ramp classifier previously treated every occurrence of `mana of any` as
mana production. That wording also appears in casting and payment permissions,
which do not produce mana. The executable contract now requires an explicit
`add`/`adds` verb before worded `mana of any ...` production.

This boundary rejects the exact Oracle text of `Nita, Forum Conciliator` and
generic forms such as `mana of any type can be spent` or `spend mana as though
it were mana of any color`. It preserves real producers, including `Arcane
Signet` and `Ronin, Shadow Stalker`.

The same boundary is enforced in the direct ramp predicate, deterministic
function inference, candidate-quality inference, semantic inference, role
scores, and the maintained Python classifier replicas. Candidate
`mana_fixing` inference now uses the same explicit-production proof, preventing
permission wording from reintroducing a ramp role through a second lane.

## Exact Ronin code truth

`Ronin, Shadow Stalker`
(`115df6db-5280-4223-921b-dc4f591841f2`) says:

> Pay 2 life: Add two mana of any one color.

That is real, restricted mana acceleration. With the complete Oracle text and
current zero popularity inputs, executable deterministic truth is:

- function rows: `ramp=0.880`, `removal=0.830`, `sacrifice=0.800`, and
  `sacrifice_outlet=0.800`;
- role rows: `ramp=63`, `removal=60`, and `sacrifice=58`; each uses Commander
  format, `any` subformat/bracket scope, and `unknown` budget tier;
- semantic-v2 rows: `0`.

PG876 intentionally performs a full replacement of Ronin's
`deterministic_heuristic_v1` function and role rows. It does not manufacture a
partial `card_semantic_tags_v2` snapshot for a card that has no semantic
snapshot today.

## PostgreSQL prestate

The live read-only precheck returned `PG876_PRECHECK_PASS` on 2026-07-16.

- target name/type: `Ronin, Shadow Stalker` / `Legendary Creature — Human
  Rogue Hero`;
- Oracle MD5: `1c426ab026cf7ecac7f33b5e21775a6b`;
- immutable card plus scoring-input SHA-256:
  `853b46a8324082709733e85a6486098aaf786cc73924cd7e85d6035b0105b3c8`;
- current deterministic function rows: `1`, SHA-256
  `83d684394dda226d06f4afb55fbb32b150b2d3780aa3856cc339c45abbf03381`;
- current deterministic role rows: `0`, SHA-256 `NULL`;
- semantic-v2 rows: `0`;
- function and role rows from non-target sources: `0`;
- product `deck_cards` references: `0`;
- normalized `commander_card_usage` references: `0`.

The sole live function row is the existing `sacrifice_outlet=0.800` row.

## Prepared exact poststate

The approval-gated transaction is restricted to Ronin's exact UUID and source
`deterministic_heuristic_v1`.

- function rows: `4`, SHA-256
  `9fe4dcd49d1940beb9d517c7f970814a98197f6fd8548a5d2e28a577cc1f3b01`;
- role rows: `3`, SHA-256
  `cb9a07b13db7249c50d9fb03769668d8f200531694390d81a7d32c507fbb558a`;
- semantic-v2 rows: `0`.

Apply snapshots the target/scoring inputs, exact function/role prestate,
non-target-source rows, and exact poststate under `manaloom_deploy_audit`. It
aborts on any count, content hash, input, preserved-row, or semantic-presence
drift. Rollback first requires the captured poststate and unchanged inputs,
then restores the exact original row and timestamp.

The explicitly authorized apply committed on 2026-07-16 and the independent
read-only postcheck returned `PG876_POSTCHECK_PASS`. Execution evidence is in
`/tmp/pg876_precheck_root_20260716.log`,
`/tmp/pg876_apply_root_20260716.log`, and
`/tmp/pg876_postcheck_root_20260716.log`. Rollback remains unexecuted.
Hermes/cache synchronization is unnecessary for this package because Ronin is
absent from PostgreSQL product decks, normalized commander usage, and the
repository's protected deck artifacts.

## Fresh family audit and deferred scope

The fresh read-only family audit after the classifier correction found:

- legitimate nonland ramp additions reduced from `201` to `199`; Nita is no
  longer proposed as ramp, while Ronin remains a legitimate addition;
- `109` existing heuristic function rows and matching semantic rows now fail
  the corrected permission-versus-production contract;
- `121` cards have stale heuristic ramp role rows, including `12` role-only
  cases; SHA-256 of the complete card-id scope is
  `3f4bafec985140df892536ec1bf6141ace6f5f0af0da979a26b4d16d53a93570`.

Those `121` cards are deliberately deferred to a separate exact, reviewed
remove-only package. Folding them into PG876 would violate its one-card Ronin
scope. The audit itself made no database mutations.

## Package and validation

- `pg876_ronin_ramp_reconciliation_20260716_precheck.sql`
- `pg876_ronin_ramp_reconciliation_20260716_apply.sql`
- `pg876_ronin_ramp_reconciliation_20260716_postcheck.sql`
- `pg876_ronin_ramp_reconciliation_20260716_rollback.sql`
- source contract:
  `server/test/ronin_pg876_reconciliation_source_test.dart`
- classifier contract:
  `server/test/ramp_family_classifier_test.dart`
- Python replica contract:
  `docs/hermes-analysis/manaloom-knowledge/scripts/test_scryfall_classifier_multi_tags.py`

The precheck, explicitly authorized apply, and read-only postcheck were run
against PostgreSQL. The rollback was validated as source but was not executed.
