# PG873 — sacrifice_outlet family reconciliation

Status: prepared and validated read-only; PostgreSQL apply not executed.

## Definitive outlet result

The old rule treated self-sacrifice, reminder text, and broad `{T}, sacrifice ...`
costs as reusable outlets. The replacement recognizes only an activated cost
that can sacrifice an external object. It strips nested parenthetical text,
rejects self pronouns and card-name aliases (including Alchemy and legendary
short names), and keeps arbitrary external objects such as land, Food, Clue,
creature types, multi-types, and `up to N permanents`.

| Lane | Current | Expected | Retained | Add | Remove | Expected UUID SHA-256 |
|---|---:|---:|---:|---:|---:|---|
| `deterministic_heuristic_v1` function tag | 1,357 | 716 | 491 | 225 | 866 | `51272701cdb5b277a2007de43c418c418fab5380409fc16c08ac527fd1ddacbd` |
| `deterministic_semantic_v2` function tag | 1,380 | 736 | 507 | 229 | 873 | `512cb67eca26b4c86d4555fcf14cae19e6e9f0a9bd24239db0d4cc6caa49418c` |
| `deterministic_semantic_v2` JSON tag | 1,380 | 736 | 507 | 229 | 873 | `512cb67eca26b4c86d4555fcf14cae19e6e9f0a9bd24239db0d4cc6caa49418c` |

The expected set is identical between the Dart audit and the independently
encoded SQL precheck. The SQL precheck returned `guard=ok` over 33,841
heuristic-owner cards and 33,972 semantic-owner cards.

There are 52 expected semantic cards with no current semantic-v2 row. PG873
materializes an outlet-only semantic row for them. It deliberately does not
persist unrelated tags suggested by the current broad classifier; those remain
algorithm drift requiring a separate family review. Thirty-three existing
semantic rows contain only a false outlet tag and are deleted because their
reconciled tag array would be empty.

## Final PG873 dry-run stale decomposition

Source: read-only dry-run `/tmp/manaloom_candidate_quality_pg873_final`, run
from `2026-07-15T21:33:24.270073` through
`2026-07-15T21:34:25.227511`; `db_mutations=false`.

| Table | Stale rows | Classification for PG873 |
|---|---:|---|
| `card_function_tags` | 1,862 | 866 confirmed outlet false positives; remaining rows are algorithm drift and are not globally pruned |
| `card_role_scores` | 3,657 | derived-score algorithm drift; no row is treated as a confirmed false positive by PG873 |
| `commander_card_synergy` | 304 | co-occurrence/window drift; no row is treated as a confirmed false positive by PG873 |
| `optimize_rejection_penalties` | 0 | no action |

The earlier PG872 dry-run labeled 897 heuristic `sacrifice_outlet` rows stale. The
robust external-object parser recovers 31 of them as valid outlets, leaving 866
confirmed false positives. It also finds 225 previously missing heuristic
outlets. Therefore the raw stale preview is evidence of drift, not authority to
delete every previewed row.

### Function tags by tag/source

All rows below use source `deterministic_heuristic_v1`.

| Tag | Rows | PG873 disposition |
|---|---:|---|
| `ramp` | 930 | algorithm drift; retain pending land/ramp family validation |
| `sacrifice_outlet` | 866 | confirmed false after the robust external-object parser; PG873 reconciles the full family |
| `graveyard` | 9 | algorithm drift; retain |
| `graveyard_synergy` | 9 | algorithm drift; retain |
| `sacrifice` | 7 | separate alias/family; retain |
| `big_spell` | 6 | algorithm drift; retain |
| `etb` | 5 | algorithm drift; retain |
| `token` | 5 | algorithm drift; retain |
| `token_maker` | 5 | algorithm drift; retain |
| `draw` | 3 | algorithm drift; retain |
| `loot` | 3 | algorithm drift; retain |
| `protection` | 3 | algorithm drift; retain |
| `spellslinger` | 3 | algorithm drift; retain |
| `removal` | 2 | algorithm drift; retain |
| `aristocrats` | 1 | algorithm drift; retain |
| `drain` | 1 | algorithm drift; retain |
| `enchantment_synergy` | 1 | algorithm drift; retain |
| `exile_value` | 1 | algorithm drift; retain |
| `tutor` | 1 | algorithm drift; retain |
| `wincon` | 1 | algorithm drift; retain |

### Role scores by role/source

All 3,657 rows use source `deterministic_heuristic_v1` and remain untouched.

| Role | Rows | Role | Rows |
|---|---:|---|---:|
| `draw` | 658 | `ramp` | 563 |
| `token` | 411 | `protection` | 314 |
| `sacrifice` | 328 | `removal` | 313 |
| `graveyard` | 170 | `recursion` | 159 |
| `aristocrats` | 121 | `wincon` | 81 |
| `spellslinger` | 77 | `artifact_synergy` | 76 |
| `big_spell` | 69 | `land` | 61 |
| `loot` | 59 | `enchantment_synergy` | 58 |
| `tutor` | 58 | `combo_piece` | 51 |
| `wipe` | 16 | `stax` | 9 |
| `etb` | 5 |  |  |

### Commander synergies by role/source

All 304 rows use source `meta_decks_cooccurrence_v1` and remain untouched.

| Role/type | Rows | Role/type | Rows |
|---|---:|---|---:|
| `utility` | 145 | `land` | 113 |
| `removal` | 22 | `draw` | 9 |
| `sacrifice` | 8 | `big_spell` | 1 |
| `protection` | 2 | `enchantment_synergy` | 1 |
| `recursion` | 1 | `token` | 1 |
| `wincon` | 1 |  |  |

## Exact package scope

PG873 mutates only:

- `card_function_tags.tag='sacrifice_outlet'` for sources
  `deterministic_heuristic_v1` and `deterministic_semantic_v2`;
- the `sacrifice_outlet` JSON element and aggregate `role_confidence` in
  `card_semantic_tags_v2` for source `deterministic_semantic_v2`;
- 52 missing semantic rows containing only the validated outlet tag;
- audit snapshots under `manaloom_deploy_audit`.

It does not mutate the generic `sacrifice` alias, role scores, commander
synergies, rejection penalties, battle runners, corpus, goldfish, or validator.
The rollback snapshots all 2,737 current function rows and 1,557 current
semantic target rows, records the exact 1,576-row post state, and aborts if the
post state drifts before rollback.
