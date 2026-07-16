# PG875 Lander Rizzi Reconciliation - 2026-07-16

Status: `applied_and_postchecked`.

## Finding

The standalone Magic type boundary and the exact `Search you library` corpus
typo normalization corrected the deterministic interpretation of `Lander
Rizzi` (`1f10f7b7-a895-4a76-9d64-7751eced092e`). The card is a Legendary
Artifact Creature with subtype `Lander`; it is not a `Land`. Its two search
abilities put a basic land onto the battlefield, so it is nonland ramp.

The current executable classifier produces:

- semantic/function tags: `ramp` `0.88`, `token_maker` `0.82`,
  `sacrifice_outlet` `0.80`, `artifact_synergy` `0.74`, and `payoff` `0.72`;
- heuristic aliases: `token` `0.82` and `sacrifice` `0.80` in addition to the
  five semantic/function tags;
- role scores from the current `usage_count=30` and `meta_deck_count=5`:
  `ramp=80` (`bracket_2_4`), `token=76`, `sacrifice=75`,
  `artifact_synergy=70`, and `payoff=69`; all other bracket scopes are `any`
  and every budget tier is `unknown`;
- semantic row: `triggered_engine`, `cheap`, `board_material`, interaction
  `none`, `engine=false`, `payoff=true`, `enabler=true`, confidence `0.88`,
  explanation `mana_acceleration_or_land_search`, and the exact five tags.

`enabler=true` is intentional code truth. `inferSemanticCardAnalysisV2`
derives `enabler` from any `ramp`, `loot`, `tutor`, or explicit `enabler` tag.
Keeping the originally proposed `enabler=false` would recreate drift on the
next deterministic semantic backfill.

## PostgreSQL prestate

The live read-only precheck returned `PG875_PRECHECK_PASS` on 2026-07-16
immediately before the approved transaction.

- target name/type: `Lander Rizzi` / `Legendary Artifact Creature — Lander
  Rogue`;
- Oracle MD5: `6c261900f590f9084d7a8feadc132020`;
- card plus meta-input SHA-256:
  `d507f9cad9c0d2c08a76c07ed183ed2772a72eb71ced7f6018a88233dce4edfe`;
- current deterministic function rows: `11`, SHA-256
  `940bfb92b0dd23af72999cff33de4dfd6de5cbb00581f0edb421c01609e7d2f7`;
- current deterministic role rows: `4`, SHA-256
  `99f4819e273c273bc5dc15ef8db0251a8c376fa13b0c76029b90596350ea3f6d`;
- current semantic-v2 rows: `1`, SHA-256
  `0fc3a335e8d7184782c666fb4a7b1269cf636b244371cd4aceb5fef9547c66c2`.

The stale rows currently describe the creature as `land`, give it a land role,
retain a semantic `engine` tag, and omit the new ramp/payoff outputs.

## Exact expected poststate

PG875 is a one-card full deterministic replacement, not a family-wide
backfill.

- function rows: `12` total (`7` heuristic and `5` semantic), SHA-256
  `6a946bfdfaa01c1a16b5c9638a7504893f6b163832bd3ea0b12a07829460d284`;
- role rows: `5`, SHA-256
  `eb51e1b334b9ff3a37612dca964a7306d2f8e2c46fd6a345ee39f09c1f6ca709`;
- semantic-v2 rows: `1`, SHA-256
  `1f794fb8848be69a228982b31ea2cf58b074252f5243706b71d8628feabb3e34`.

The apply transaction snapshots the card/meta inputs, every existing target
deterministic row, every non-target row for the same card, and the complete
poststate under `manaloom_deploy_audit`. It aborts on any input, count, or hash
drift. Deletes are restricted to the exact UUID and deterministic source names.
Cards, meta insights, legalities, decks, battle rules, commander usage, and
rows from unrelated/user sources are not mutated.

The rollback first requires the exact snapshotted poststate, then restores the
original deterministic rows including their original timestamps. It aborts if
the target or any explicitly preserved non-target row drifted.

## Applied validation

The approved one-card transaction committed on 2026-07-16 and the immediate
read-only postcheck returned `PG875_POSTCHECK_PASS`:

- deterministic function rows: `12`, SHA-256
  `6a946bfdfaa01c1a16b5c9638a7504893f6b163832bd3ea0b12a07829460d284`;
- deterministic role rows: `5`, SHA-256
  `eb51e1b334b9ff3a37612dca964a7306d2f8e2c46fd6a345ee39f09c1f6ca709`;
- semantic-v2 rows: `1`, SHA-256
  `1f794fb8848be69a228982b31ea2cf58b074252f5243706b71d8628feabb3e34`;
- captured-poststate diffs, preserved non-target-source diffs, and immutable
  card/meta input diffs: all `0`.

This package changed PostgreSQL deterministic intelligence for the exact card
only. It did not mutate Hermes, a protected deck snapshot, battle rules, an
application deployment, or any non-target source row.

## Package

- `pg875_lander_rizzi_reconciliation_20260716_precheck.sql`
- `pg875_lander_rizzi_reconciliation_20260716_apply.sql`
- `pg875_lander_rizzi_reconciliation_20260716_postcheck.sql`
- `pg875_lander_rizzi_reconciliation_20260716_rollback.sql`
- source contract:
  `server/test/lander_rizzi_pg875_reconciliation_source_test.dart`

Precheck, apply, and postcheck have been executed successfully. Rollback,
Hermes/cache sync, and application deployment were not required for this card,
which is absent from the protected deck, and remain unexecuted.
