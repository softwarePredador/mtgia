# PG873 — sacrifice_outlet family reconciliation

Status: applied to PostgreSQL and postchecked successfully on 2026-07-16.

## Definitive outlet result

The old rule treated self-sacrifice, reminder text, and broad `{T}, sacrifice ...`
costs as reusable outlets. The replacement recognizes only an activated cost
that can sacrifice an external object. It strips nested parenthetical text,
rejects self pronouns and card-name aliases (including Alchemy and legendary
short names), and keeps arbitrary external objects such as land, Food, Clue,
creature types, multi-types, and `up to N permanents`.

| Lane | Current | In-scope expected | Retained | Add | Remove | Expected UUID SHA-256 |
|---|---:|---:|---:|---:|---:|---|
| `deterministic_heuristic_v1` function tag | 1,357 | 716 | 491 | 225 | 866 | `51272701cdb5b277a2007de43c418c418fab5380409fc16c08ac527fd1ddacbd` |
| `deterministic_semantic_v2` function tag | 1,380 | 684 | 507 | 177 | 873 | `573c94fad8b4ba9d9789daadd506e4ce2b0143dfa0d049eb8687c4c8cd90e8bd` |
| `deterministic_semantic_v2` JSON tag | 1,380 | 684 | 507 | 177 | 873 | `573c94fad8b4ba9d9789daadd506e4ce2b0143dfa0d049eb8687c4c8cd90e8bd` |

The global semantic classifier still recognizes 736 cards with SHA-256
`512cb67eca26b4c86d4555fcf14cae19e6e9f0a9bd24239db0d4cc6caa49418c`.
Of those, 684 already own a complete `deterministic_semantic_v2` snapshot and
are in PG873 scope. The expected global and in-scope sets are identical between
the Dart audit and the independently encoded SQL precheck. The SQL precheck
returned `guard=ok` over 33,841 heuristic-owner cards and 33,972 semantic-owner
cards.

Validation was rerun on 2026-07-16 before the guarded PostgreSQL mutation:

- SQL precheck: `/tmp/pg873_precheck_20260716.log`, `guard=ok`;
- independent Dart family audit:
  `/tmp/manaloom_sacrifice_outlet_family_audit_pg873_final/summary.json`,
  `db_mutations=false` and the same counts/hashes;
- focused classifier/package tests: 14 passed; focused Dart analysis: no issues.

The guarded apply then completed with `ON_ERROR_STOP=1` and an explicit
PostgreSQL write confirmation. It backed up 2,737 function rows and 1,557
semantic rows in `manaloom_deploy_audit`, materialized the 1,400-row expected
function manifest, updated the existing semantic snapshots in scope, and
committed without a guard failure. Apply log:
`/tmp/pg873_apply_20260716.log`.

The independent postcheck returned `guard=ok` and verified:

- 716 heuristic outlet rows, UUID SHA-256
  `51272701cdb5b277a2007de43c418c418fab5380409fc16c08ac527fd1ddacbd`;
- 736 global semantic candidates, UUID SHA-256
  `512cb67eca26b4c86d4555fcf14cae19e6e9f0a9bd24239db0d4cc6caa49418c`;
- 684 in-scope semantic rows, UUID SHA-256
  `573c94fad8b4ba9d9789daadd506e4ce2b0143dfa0d049eb8687c4c8cd90e8bd`;
- the unchanged 52-card deferred backlog, UUID SHA-256
  `4f29cbcbbdaa9a10bf285ff808c40ab8f3026367a2b3bc873fd51424cad5b199`;
- zero manifest differences, cross-source conflicts, wrong semantic payloads,
  resurrected false positives, stale role confidence values, or tag-order
  violations.

Postcheck log: `/tmp/pg873_postcheck_20260716.log`.

There are 52 globally expected cards with no current semantic-v2 row, exact
UUID SHA-256
`4f29cbcbbdaa9a10bf285ff808c40ab8f3026367a2b3bc873fd51424cad5b199`.
PG873 records these cards in the audit schema as a deferred backlog and does
not create partial outlet-only semantic snapshots. They require the complete
semantic-v2 backfill contract in a separate package. Thirty-three existing
semantic rows contain only a false outlet tag and are deleted because their
reconciled tag array would be empty.

## Final PG873 dry-run stale decomposition

Source: read-only dry-run
`/tmp/manaloom_candidate_quality_pg873_deferred_final`, run from
`2026-07-16T01:45:55.542343` through `2026-07-16T01:47:11.719910`;
`db_mutations=false`.

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
- existing semantic-v2 snapshots; no missing or partial semantic row is
  inserted;
- audit snapshots under `manaloom_deploy_audit`.

It does not mutate the generic `sacrifice` alias, role scores, commander
synergies, rejection penalties, battle runners, corpus, goldfish, or validator.
The audit schema records the 52-card deferred backlog independently from the
1,400-row expected function manifest (716 heuristic plus 684 semantic). The
rollback snapshots all 2,737 current function rows and 1,557 current semantic
target rows, records the exact 1,524-row post state, and aborts if the post state
or deferred backlog drifts before rollback.
