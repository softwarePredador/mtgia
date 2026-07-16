# PG879 — Flashback exact runtime and CMC

Status: `applied_postchecked_synced_and_contract_audited`
Prepared, live-prechecked, applied, postchecked, synchronized, and contract-audited: 2026-07-16
PostgreSQL mutation authorization: granted by the user's instruction to perform all necessary work
Scope: one `cards.cmc` correction and one exact `card_battle_rules` promotion

## Outcome

PG879 was executed as a guarded database package for the card **Flashback**
(`d96a06bc-aa90-4837-b8ab-ad2be804641a`). It records the exact native runtime
semantics already implemented in the battle surface and corrects the source
card's mana value from `0.0` to `1.0`.

The package is deliberately not a Lorehold deck promotion and does not decide
between decks 607 and 615. It changes neither runtime code, XMage mapper/splitter,
optimizer gate, nor any deck row. A later deck comparison must use fresh
PostgreSQL-to-Hermes metadata and rule syncs; those syncs have now completed.

## Execution evidence

The first guarded apply attempt aborted before commit because the projected
PostgreSQL `numeric(4,1)` card-row hash was represented incorrectly in the
package expectation. The transaction rolled back completely and created no
audit tables. The read-only precheck was corrected to project the stored
`1.0::numeric(4,1)` representation and independently reproduced the sealed
poststate hash `5b3d349754c594360b6315db018b0f96`.

The corrected apply then emitted `PG879_APPLY_COMMITTED`; the guarded postcheck
emitted `PG879_POSTCHECK_PASS`. PostgreSQL now has CMC `1.0`, one live exact
rule, and both superseded broad rules disabled. Metadata and rule sync reports
were written to
`master_optimizer_reports/pg879_flashback_metadata_sqlite_sync_20260716.json`
and
`master_optimizer_reports/pg879_flashback_rules_sqlite_sync_20260716.json`.
The synchronized Hermes SQLite SHA-256 is
`c34151e368cfbe4a2145b49c0c0aca05eb08e327b9ccde35f342a85e045c6e13`.
The post-sync PostgreSQL/Hermes contract audit passed all `55/55` checks with
no mutation and is recorded at
`master_optimizer_reports/pg879_lorehold_pg_hermes_contract_audit_20260716.json`.

## Authoritative behavior

The pinned XMage revision is
`34d81ea4995ce15d7e1a788dc6d2a3595d35bcec`. The card is a `{R}` instant that
targets exactly one instant or sorcery card in its controller's graveyard. On
resolution, the target gains flashback until end of turn with a flashback cost
equal to its printed mana cost. Casting through flashback still uses normal
timing and the normal casting/payment pipeline. If that spell would leave the
stack for any reason, including resolution or being countered, it is exiled.

Pinned source file digests:

| XMage file | SHA-256 |
|---|---|
| `Mage.Sets/src/mage/cards/f/Flashback.java` | `1fee8059282891aca6424a704e5f2c6bffaeecd97f440253c04a2ae8b504e12d` |
| `Mage/src/main/java/mage/abilities/effects/common/continuous/GainFlashbackTargetEffect.java` | `a31c4c77af35bdd83e3e259a3d4546236e5017d4a9b037f92c309e2e8927beed` |
| `Mage/src/main/java/mage/abilities/keyword/FlashbackAbility.java` | `6a3cea9f6a49b61f425bf267cc280a991d4d1315322b11059cd0604e0dd76e87` |
| `Mage/src/main/java/mage/abilities/keyword/CastFromGraveyardAbility.java` | `d960ebf54f87db2baf2a23785c181bdfea863a60d493eb66707ba64becc77be9` |
| `Mage/src/main/java/mage/target/common/TargetCardInYourGraveyard.java` | `374eeaa08611b6b2db2fa3693325c8b50dad9b3b71dcbefd18e059c4403258f4` |

## Exact proposal contract

Logical key:
`battle_rule_v1:f5b21163180f3254fa6b288d5ab0a95b`.

Effect JSON:

```json
{"ability_kind":"one_shot_targeted_continuous_permission","battle_model_scope":"target_instant_sorcery_graveyard_gains_mana_cost_flashback_until_eot_v1","cmc":1.0,"duration":"until_end_of_turn","effect":"graveyard_flashback_grant","flashback_cast_status":"runtime_executor_v1","flashback_cost_source":"target_printed_mana_cost","flashback_exile_on_leave_stack":true,"flashback_exile_status":"runtime_executor_v1","flashback_grant_status":"runtime_executor_v1","flashback_uses_normal_cast_pipeline":true,"grants_flashback_to":"target_instant_or_sorcery","instant":true,"oracle_runtime_scope":"target_one_own_graveyard_instant_sorcery_grant_printed_cost_flashback_until_eot_exile_after_stack_exact_v1","sorcery":false,"source_mana_cost":"{R}","source_type_line":"Instant","target":"instant_or_sorcery_card_in_your_graveyard","target_constraints":{"card_types":["instant","sorcery"],"controller_scope":"self","zone":"graveyard"},"target_controller":"self","target_count":1,"target_count_max":1,"target_count_min":1,"target_declared_on_cast":true,"target_legality_rechecked_on_resolution":true,"target_zone":"graveyard","targeted_flashback_grant":true,"xmage_ability_classes":[],"xmage_condition_classes":[],"xmage_cost_classes":[],"xmage_duration":"EndOfTurn","xmage_effect_classes":["GainFlashbackTargetEffect"],"xmage_filter_classes":[],"xmage_filter_constants":["StaticFilters.FILTER_CARD_INSTANT_OR_SORCERY"],"xmage_granted_ability_class":"FlashbackAbility","xmage_granted_ability_cost_source":"card.getManaCost()","xmage_target_classes":["TargetCardInYourGraveyard"]}
```

Deck-role JSON:

```json
{"category":"engine","effect":"graveyard_flashback_grant","functions":["targeted_graveyard_cast_permission","flashback_alternative_cost","flashback_stack_exile_replacement"],"subtype":"targeted_flashback_grant","target":"instant_or_sorcery_card_in_your_graveyard","timing":"instant"}
```

The row is `source=curated`, `confidence=0.98`,
`review_status=verified`, `execution_status=auto`, `rule_version=3`, and
`reviewed_by=codex-pg879-flashback-exact-runtime-cmc`. Its deterministic
proposal hash is `1a7fac705bdac60ec3c062960daecff6`.

## Live prestate sealed by the precheck

| Guard | Expected value |
|---|---|
| `public.cards` schema | 28 columns, `03ef6ea64392bacd6db316eefe8c3896` |
| `public.card_battle_rules` schema | 18 columns, `22b9db71b43ac3cecf079dc716272d24` |
| target card lineage | 1 row, `a5ac34f8c716be13f6ea72aea4ef39a2` |
| target card identity | UUID above, `Flashback`, `{R}`, `Instant`, CMC `0.0`, oracle MD5 `552a1f4ae21306af7e3e4db346a6c3c4` |
| target rule prestate | 2 rows, both live, none disabled, `368225ebe6470d5da54dbfbb31d733b2` |
| exact logical key | absent |
| projected card lineage after only CMC correction | `5b3d349754c594360b6315db018b0f96` |

The two live prestate keys are
`battle_rule_v1:10c0370e742d4bc12334362b28e152c1` and
`battle_rule_v1:90fe9d4c0a3fda3e98eff00432392fe6`. Both describe broader recursion
behavior and must be disabled before the exact row becomes the only live rule.

## Mutating scope and reversibility

The apply performs exactly these mutations in one transaction while holding
`SHARE ROW EXCLUSIVE` locks on both target tables:

1. Updates only `public.cards.cmc` for the sealed UUID from `0.0` to `1.0`.
2. Changes exactly the two sealed live rules to
   `review_status=deprecated` and `execution_status=disabled`, appending one
   fixed audit note. Every other column is required to remain identical.
3. Inserts exactly one `verified/auto` rule with the proposal above.

Before mutation it snapshots the complete 28-column card row and both complete
18-column rule rows. After mutation it snapshots the complete card row and all
three complete rule rows. The apply compares live rows with those snapshots in
both directions before commit. Any row-count, schema, hash, identity, transform,
or proposal drift aborts the entire transaction.

Rollback is equally guarded. It will run only if the current card and all three
current target rules are byte-for-row equal to the complete PG879 poststate
snapshots. It then restores CMC `1.0 -> 0.0`, replaces the three poststate rules
with the exact two-row prestate snapshot, and verifies both restored row sets
and their prestate hashes before commit.

## Operator sequence

The package was executed in this guarded sequence, beginning with the read-only
precheck:

```bash
server/bin/with_new_server_pg.sh psql -X -v ON_ERROR_STOP=1 \
  -f docs/hermes-analysis/master_optimizer_reports/pg879_flashback_exact_runtime_and_cmc_20260716_precheck.sql
```

After authorization, the apply and postcheck were run:

```bash
server/bin/with_new_server_pg.sh psql -X -v ON_ERROR_STOP=1 \
  -f docs/hermes-analysis/master_optimizer_reports/pg879_flashback_exact_runtime_and_cmc_20260716_apply.sql

server/bin/with_new_server_pg.sh psql -X -v ON_ERROR_STOP=1 \
  -f docs/hermes-analysis/master_optimizer_reports/pg879_flashback_exact_runtime_and_cmc_20260716_postcheck.sql
```

The completed apply was not considered operationally closed until **both**
metadata and rule surfaces were synchronized from PostgreSQL to Hermes:

```bash
server/bin/with_new_server_pg.sh python3 \
  docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_card_metadata_to_hermes.py \
  --report /tmp/pg879_flashback_metadata_sync.json

server/bin/with_new_server_pg.sh python3 \
  docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py \
  --apply-sqlite-from-pg --include-needs-review --only-card "Flashback" \
  --export-canonical-fallback-json \
  docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json \
  --report /tmp/pg879_flashback_rules_sync.json
```

The guarded rollback command, if separately approved, is:

```bash
server/bin/with_new_server_pg.sh psql -X -v ON_ERROR_STOP=1 \
  -f docs/hermes-analysis/master_optimizer_reports/pg879_flashback_exact_runtime_and_cmc_20260716_rollback.sql
```

After rollback, the same two Hermes sync commands are required so the cache no
longer advertises the reverted PostgreSQL poststate.

## Validation contract

Package checks:

```bash
cd server && dart test test/flashback_pg879_exact_runtime_and_cmc_source_test.dart
python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_flashback_exact_runtime.py
git diff --check -- \
  docs/hermes-analysis/PG879_FLASHBACK_EXACT_RUNTIME_AND_CMC_2026-07-16.md \
  docs/hermes-analysis/master_optimizer_reports/pg879_flashback_exact_runtime_and_cmc_20260716_precheck.sql \
  docs/hermes-analysis/master_optimizer_reports/pg879_flashback_exact_runtime_and_cmc_20260716_apply.sql \
  docs/hermes-analysis/master_optimizer_reports/pg879_flashback_exact_runtime_and_cmc_20260716_postcheck.sql \
  docs/hermes-analysis/master_optimizer_reports/pg879_flashback_exact_runtime_and_cmc_20260716_rollback.sql \
  server/test/flashback_pg879_exact_runtime_and_cmc_source_test.dart
```

The apply, postcheck, both syncs, and the `55/55` contract audit are complete.
PostgreSQL/Hermes consumers must treat PG879 as
`applied_postchecked_synced_and_contract_audited`. Deck coherence also has no
high or critical findings for 607, 614, or 615; the remaining 614 medium finding
is the already-known generic Helm of Awakening model scope.
