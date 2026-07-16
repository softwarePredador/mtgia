# PG878 Lorehold challenger runtime completion — 2026-07-16

Status: **applied, postchecked, synchronized to Hermes, and contract-audited**.

PG878 is the PostgreSQL promotion package for the three native runtime gaps
that materially affected the Lorehold `607` versus `615` comparison:

- Birgi's executable front face plus the Harnfel modal back face;
- Underworld Breach escape plus its beginning-of-end-step sacrifice;
- Mana Vault's exact untap, draw-step damage, and mana ability contract.

PostgreSQL remains product truth. The pinned local XMage 1.4.60 sources are the
primary executable source, and `battle_analyst_v9.py` plus its focused tests are
the native adapter evidence. The SQL package writes PostgreSQL only; after its
guarded apply and passing postcheck, the three-card rule slice was synchronized
PostgreSQL-to-Hermes.

## Executed result

On 2026-07-16, the guarded operator sequence completed successfully:

- `PG878_PRECHECK_PASS`: 3 target cards, 11 prior rules, 5 live competitors,
  6 disabled historical rows, and all three frozen hashes matched;
- `PG878_APPLY_COMMITTED`: exactly 5 competing rows were disabled and exactly
  3 verified/automatic exact rows were inserted in one transaction;
- `PG878_POSTCHECK_PASS`: the 14-row target poststate matched its persisted
  snapshot, with 3 exact live rows and 11 disabled historical/superseded rows;
- targeted PostgreSQL-to-Hermes sync loaded 12 PG rows and made 14 SQLite
  insert/update/prune changes; local SQLite integrity remained `ok`;
- the resulting Hermes DB SHA-256 is
  `433d0c906a838d569d8fc19b4a4c1d83e0b45de1dba7850a3d54bd11627ab6db`;
- the PostgreSQL/Hermes/SQLite contract audit passed all `55/55` checks;
- the complete battle regression passed under the live PostgreSQL tunnel.

The exact rollback SQL remains preserved and refuses any target-state drift.
The sync and audit evidence is stored in
`master_optimizer_reports/pg878_lorehold_runtime_sqlite_sync_20260716.json`
and `master_optimizer_reports/pg878_lorehold_pg_hermes_contract_audit_20260716.{json,md}`.

## Live lineage frozen for the package

Read-only inspection used `server/bin/with_new_server_pg.sh` against the live
new-server target at `127.0.0.1:15432/halder`. The final capture was taken on
2026-07-16 UTC and produced these guards:

| Surface | Frozen result |
| --- | --- |
| `cards` schema | 28 columns; signature `03ef6ea64392bacd6db316eefe8c3896` |
| `card_battle_rules` schema | 18 columns; signature `22b9db71b43ac3cecf079dc716272d24` |
| target card rows | 3; hash `d047e689c2f3bea43ff9a0179114f12b` |
| target battle-rule rows | 11; full-row hash `6edced874860dcadd35256813d3160a1` |
| executable/active competitors | 5 |
| already disabled historical rows | 6 |
| exact proposal | 3 rows; hash `3ff2fb6259e01b96bbb8a932931f9c8a` |

The three card identities and raw PostgreSQL Oracle hashes are:

| Card | `cards.id` | Raw `md5(oracle_text)` |
| --- | --- | --- |
| Birgi, God of Storytelling // Harnfel, Horn of Bounty | `e715bdfc-8bc4-4da8-b7bf-1d6f48d5fc85` | `5f1ed696a63cd668fd46a2fe9971a54e` |
| Underworld Breach | `1ecaad2c-0ab0-4d9d-9115-31a8078e09b0` | `a98ca5777789e48c44daff97999f2beb` |
| Mana Vault | `d2f38c20-79e2-4330-b6ae-ded990a465e4` | `35e3fd94c8453c0e326033af49ae18c8` |

## Exact proposal

| Card | Exact native scope | Logical rule key |
| --- | --- | --- |
| Birgi // Harnfel | `birgi_harnfel_modal_faces_exact_v1` | `battle_rule_v1:e27d00eff7b686d7c8aab1426c621635` |
| Underworld Breach | `underworld_breach_escape_and_end_step_sacrifice_exact_v1` | `battle_rule_v1:a38468ecbf8f6ff1512b3b52674a3d0c` |
| Mana Vault | `mana_vault_exact_untap_draw_damage_mana_v1` | `battle_rule_v1:d43496777c4b1e36b1c9a5111133acf4` |

The keys were generated with the canonical
`battle_rule_registry.logical_rule_key` stable-JSON/SHA-256 contract. All three
rows use `source=curated`, `confidence=0.98`, `review_status=verified`,
`execution_status=auto`, and `rule_version=3`.

The Birgi row is deliberately precise about its residual boundary: the
spell-cast red-mana engine, modal back-face cast, repeatable discard-one /
exile-two activation, normal-cost play permission through end of turn, and
front-face restoration on zone changes are executable. Birgi's separate
boast-twice permission remains `annotation_only`; PG878 does not falsely claim
an unimplemented boast executor.

Underworld Breach promotes only the implemented exact behavior: nonland cards
with a printed mana cost can be cast repeatedly from the graveyard through the
normal cast pipeline by paying that printed cost and exiling exactly three
other graveyard cards; its beginning-of-end-step self-sacrifice is a real
zone-identity-aware trigger.

Mana Vault replaces the old partial row and its incorrect
`tapped_upkeep_damage` field with the exact split: no normal untap, optional
upkeep `{4}` untap, intervening-if tapped draw-step damage, and `{T}: Add
`{C}{C}{C}`. Its payload is aligned with the exact mapper/splitter contract,
including `static_triggered_and_activated_mana`, explicit tap activation,
`produced_mana_symbols`, the untap restriction status, and the exact XMage
ability/effect/condition/cost/target/filter class sets.

## XMage source evidence

The prepared rows record the pinned source version and file digests in their
notes:

| XMage source | SHA-256 |
| --- | --- |
| `BirgiGodOfStorytelling.java` | `9cb100723cd36ca66a89724ead11e57c423e987688cde10479ebfda65d430e37` |
| `UnderworldBreach.java` | `99de025b840d7fb4f2875e4ba76a7fbfb6a8c0ab34d19f00251ff6b578fe36c1` |
| `ManaVault.java` | `139e81625a2a030bcf80e613ede72b7bde7693c22c72b9900798aa4ab939e571` |

The focused native test surface is
`docs/hermes-analysis/manaloom-knowledge/scripts/test_priority_lorehold_card_runtime.py`.
The durable package/source contract is
`server/test/lorehold_challenger_pg878_runtime_completion_source_test.dart`.

## Mutation and exact rollback contract

The apply is intentionally limited to `public.card_battle_rules`:

1. refuse schema, identity, Oracle, rule-prestate, or audit-table drift;
2. lock `cards` read-only and `card_battle_rules` against concurrent writes;
3. snapshot all 3 target card rows and all 11 target battle-rule rows;
4. persist the exact 3-row proposal in `manaloom_deploy_audit`;
5. deprecate/disable exactly the 5 currently live competing rows;
6. leave all 6 already-disabled historical rows byte-identical;
7. insert exactly 3 verified executable rows;
8. assert the 14-row poststate and persist its full snapshot.

Rollback refuses to run unless the entire current 14-row target state is
identical to the captured PG878 poststate. It then deletes those 14 rows,
restores the original 11 rows positionally under the guarded 18-column schema,
and requires the original full-row hash, live/disabled counts, and set equality.
The audit tables remain intact after rollback.

## Known metadata debt kept out of scope

The live Birgi card row has `layout IS NULL`, `card_faces_json IS NULL`, and a
`scryfall_id` equal to its `oracle_id`. That is incomplete MDFC printing
metadata. PG878 does not silently rewrite `cards`: the Harnfel runtime
characteristics are carried by the Oracle-hashed exact battle rule and pinned
XMage source. Correcting the Scryfall printing/layout/faces fields should be a
separate card-metadata package with its own source snapshot and rollback; it is
not required for this native rule promotion.

## Executed operator sequence

```bash
server/bin/with_new_server_pg.sh psql -X -v ON_ERROR_STOP=1 \
  -f docs/hermes-analysis/master_optimizer_reports/pg878_lorehold_challenger_runtime_completion_20260716_precheck.sql

server/bin/with_new_server_pg.sh psql -X -v ON_ERROR_STOP=1 \
  -f docs/hermes-analysis/master_optimizer_reports/pg878_lorehold_challenger_runtime_completion_20260716_apply.sql

server/bin/with_new_server_pg.sh psql -X -v ON_ERROR_STOP=1 \
  -f docs/hermes-analysis/master_optimizer_reports/pg878_lorehold_challenger_runtime_completion_20260716_postcheck.sql
```

After `PG878_POSTCHECK_PASS`, PostgreSQL rules/card data were synchronized into
the frozen Hermes battle cache and the PostgreSQL/Hermes contract audits plus
focused native tests were rerun. PG878 itself does not promote a deck and does
not establish that `615` beats the protected `607` baseline; that comparison
still requires its own strict same-seed battle gate.
