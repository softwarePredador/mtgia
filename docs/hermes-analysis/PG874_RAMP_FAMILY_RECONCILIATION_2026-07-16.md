# PG874 Ramp Family Reconciliation - 2026-07-16

Status: `applied_and_postchecked`.

## Finding

The post-PG873 candidate-quality dry-run initially exposed `930` stale
`deterministic_heuristic_v1` ramp rows. The full family audit found two coupled
classifier defects:

- lands were already excluded from direct ramp, but land mana text could still
  enter through the `ritual -> ramp` candidate alias;
- any library search mentioning a land was treated as ramp, even when the land
  only went to hand and created no additional mana source.

The corrected contract keeps every land in the structural `land`/fixing lane;
land-search is ramp only when the searched land enters the battlefield.
Nonland rocks, dorks, rituals, treasure, extra-land effects, land untap and
cost reduction remain ramp.

## Read-only evidence

Artifact: `/tmp/manaloom_pg874_ramp_family_audit_land_boundary_20260716/summary.json`.

- heuristic ramp: current `3,092`, expected `1,989`, retained `1,790`, exact
  false positives `1,302`, legitimate missing drift `199`;
- semantic ramp function/JSON: current `3,246`, expected-in-existing-snapshots
  `1,998`, retained `1,896`, exact false positives `1,350`, missing drift `102`;
- exact remove-only PG874 target: `1,377` cards, SHA-256
  `cebc65973dfb91315dae85510be400b2ed6bcad5e8cff765c5a2ed6db5b51123`;
- target split: `1,159` lands, `217` land-search-to-hand cards, and the current
  Oracle-face drift row for `Ashling, Rekindled // Ashling, Rimebound`;
- rows guarded by the package: function heuristic `1,302`, role score `1,322`,
  function semantic `1,350`, semantic JSON `1,350`;
- one semantic snapshot contains only the stale ramp tag; rollback snapshots
  preserve it exactly and apply removes it consistently with the existing
  PG873 empty-tag policy;
- the `201` union of legitimate nonland additions is intentionally deferred;
  PG874 does not bulk-upsert unrelated candidate-quality drift.

The final live read-only precheck returned `PG874_PRECHECK_PASS` after the
standalone `Land` type-boundary regression was added; the exact target count
and every guarded hash remained unchanged.

## Applied evidence

PG874 was applied to PostgreSQL on 2026-07-16 under the explicit mutation
approval gate. The transaction snapshotted every affected source row before
mutation and committed only after its internal count/hash assertions passed.

- apply log: `/tmp/pg874_apply_20260716.log`;
- postcheck log: `/tmp/pg874_postcheck_20260716.log`;
- postcheck: `PG874_POSTCHECK_PASS`;
- residual target function/role/semantic rows: `0 / 0 / 0`;
- remaining heuristic function/role ramp rows: `1,790 / 1,802`;
- remaining semantic function/JSON ramp cards: `1,896 / 1,896`;
- semantic function-vs-JSON diff: `0`;
- recomputed derived semantic fields with mismatch: `0`.

## Package

- `pg874_ramp_family_reconciliation_20260716_precheck.sql`
- `pg874_ramp_family_reconciliation_20260716_apply.sql`
- `pg874_ramp_family_reconciliation_20260716_postcheck.sql`
- `pg874_ramp_family_reconciliation_20260716_rollback.sql`

The apply is exact remove-only, snapshots every changed table in
`manaloom_deploy_audit`, recomputes semantic `role_confidence`, `enabler` and
`explanation_reason`, and does not touch cards, legalities, decks, battle rules,
or the deferred legitimate ramp additions.
