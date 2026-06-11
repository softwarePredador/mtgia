# Battle/AI Semantic Sync - Slice 1 Report

Status: implemented locally, validated with tests, temporary SQLite apply and
consumer smoke.

Date: 2026-06-11

Scope approved by owner:

- release stability first;
- no global Mox ban;
- learned decks only for single commander until partner corpus exists;
- duplicate Commander singleton identity blocks save/import;
- Hermes metadata hidden from normal users;
- Hermes proposes, backend owns;
- `needs_review` battle rules do not execute hard behavior;
- `card_battle_rules` can derive tags only when trusted and traceable;
- first coding slice limited to aggregation + Hermes snapshot + tests.

## What changed

### `sync_pg_target_deck_to_hermes.py`

The Hermes target deck sync now:

- fetches one row per `deck_cards.card_id`;
- requires `card_id` before writing the Hermes snapshot;
- aggregates `card_function_tags` into `functional_tags_json`;
- aggregates `card_semantic_tags_v2` into `semantic_tags_v2_json`;
- aggregates all non-rejected/non-deprecated `card_battle_rules` into
  `battle_rules_json`;
- preserves legacy `functional_tag` for old consumers;
- writes `deck_hash`, `semantics_hash` and `sync_run_id` into the SQLite
  snapshot;
- refuses duplicate `card_id` rows before SQLite write;
- refuses duplicate card names with distinct `card_id` values instead of
  silently collapsing singleton identity conflicts;
- no longer uses `LEFT JOIN LATERAL (...) LIMIT 1` for battle rules.

### SQLite snapshot shape

`deck_cards` now supports these additional fields:

- `card_id`
- `functional_tags_json`
- `semantic_tags_v2_json`
- `battle_rules_json`
- `deck_hash`
- `semantics_hash`
- `sync_run_id`

Existing consumers can continue using:

- `card_name`
- `quantity`
- `functional_tag`
- `tag_confidence`
- `is_commander`
- `cmc`
- `type_line`
- `oracle_text`

### Optimizer consumer bridge

`master_optimizer_common.py`, `slot_optimizer.py`, `_mana_validator.py`,
`_run_validation.py` and `_update_cron_status.py` were updated to consume the
new snapshot safely:

- `deck_hash` now represents only deck structure: `card_id`, `card_name`,
  `quantity` and commander marker;
- `semantics_hash` represents semantic payload: `functional_tags_json` and
  `battle_rules_json`;
- role checks use set membership from `functional_tags_json` with fallback to
  legacy `functional_tag`;
- quality gate evaluates every protected role on a removed card instead of
  collapsing it to one primary role;
- temporary swap inserts preserve `functional_tags_json` when the snapshot
  schema has that column;
- slot scan fills missing real roles from multi-tag snapshots without
  overwriting detailed `card_deck_analysis`;
- mana validators/report-only cron summaries count role membership from
  `functional_tags_json` with fallback to legacy `functional_tag`;
- validators keep `SUM(deck_cards.quantity)` as cardinality and treat role
  bucket sums as overlays that can exceed deck size.

## What did not change yet

This slice intentionally did not change:

- `battle_analyst_v9.py` execution behavior;
- mana validator role counting;
- learned deck promotion rules;
- backend `/decks/:id/simulate`;
- app UX;
- production Hermes SQLite database.

The temporary SQLite apply validated shape and cardinality only.

## Lorehold report-only evidence

Command class:

```bash
set -a
. server/.env
set +a
python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_target_deck_to_hermes.py \
  --sqlite-db <temporary>/knowledge.db \
  --report <temporary>/report.json
```

Observed sanitized result:

| Metric | Result |
|---|---|
| apply | `false` |
| selected commander | `Lorehold, the Historian` |
| selected format | `commander` |
| selected deck total quantity | `100` |
| selected deck rows | `100` |
| fetched cards | `100` |
| fetched quantity | `100` |
| commanders | `1` |
| duplicate rows collapsed | `0` |
| deck hash length | `64` |
| semantics hash length | `64` |

Representative role memberships were present for the target Lorehold deck,
including `draw`, `ramp`, `removal`, `protection`, `tutor`, `wincon`,
`engine`, `payoff`, `enabler`, `land` and `board_wipe`.

## Temporary SQLite apply evidence

Command class:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_target_deck_to_hermes.py \
  --sqlite-db <temporary>/knowledge.db \
  --apply \
  --report <temporary>/report.json
```

Observed sanitized result:

| SQLite check | Result |
|---|---|
| rows in `deck_cards` for target deck | `100` |
| summed `quantity` | `100` |
| commanders | `1` |
| rows missing `card_id` | `0` |
| rows missing `functional_tags_json` | `0` |
| rows missing `battle_rules_json` | `0` |
| distinct `deck_hash` values | `1` |
| distinct `semantics_hash` values | `1` |

Sample cards showed:

- `Lorehold, the Historian` with `card_id`, `functional_tags_json` and empty
  `battle_rules_json`;
- `Aetherflux Reservoir` with `card_id`, multi-role `functional_tags_json` and
  non-empty `battle_rules_json`.

This proves that a card can carry multiple semantic roles/rules without
creating extra deck rows.

## Consumer smoke evidence

Command class:

```bash
python3 sync_pg_target_deck_to_hermes.py --sqlite-db <temporary>/knowledge.db --apply
MANALOOM_KNOWLEDGE_DB=<temporary>/knowledge.db python3 - <<'PY'
import master_optimizer_common as m
...
PY
```

Observed sanitized result:

| Check | Result |
|---|---|
| cards | `100` |
| tagged rows | `100` |
| deck hash length | `64` |
| semantics hash length | `64` |
| derived roles from arrays | `draw`, `ramp`, `removal`, `wipe` |

This proves the optimizer common layer can read the new array snapshot and keep
the structural hash separated from semantic changes.

## Validator smoke evidence

Command class:

```bash
python3 sync_pg_target_deck_to_hermes.py --sqlite-db <temporary>/knowledge.db --apply
MANALOOM_KNOWLEDGE_DB=<temporary>/knowledge.db python3 _mana_validator.py
MANALOOM_KNOWLEDGE_DB=<temporary>/knowledge.db \
  MANALOOM_MANA_REPORT_PATH=<temporary>/MANA_BASE_VALIDATION_REPORT.md \
  python3 _run_validation.py
MANALOOM_KNOWLEDGE_DB=<temporary>/knowledge.db \
  MANALOOM_CRON_STATUS_PATH=<temporary>/CRON_STATUS.md \
  python3 _update_cron_status.py
```

Observed sanitized result:

| Check | Result |
|---|---|
| sync cards seen/written | `100 / 100` |
| sync quantity seen/written | `100 / 100` |
| SQLite rows | `100` |
| SQLite quantity | `100` |
| Commanders | `1` |
| semantic columns missing | `0` |
| distinct `deck_hash` values | `1` |
| distinct `semantics_hash` values | `1` |
| mana validator decks reported | `1` |
| role sum | `155` |
| total cards | `100` |
| temporary mana report written | `true` |
| temporary CRON_STATUS updated | `true` |

`role_sum > total_cards` is expected and confirms the new overlay model: one
card can contribute to more than one role, while deck cardinality remains 100.
`_update_cron_status.py` is now idempotent for isolated smoke runs: when the
target `CRON_STATUS.md` path does not exist yet, it creates a minimal file with
the expected markers before replacing the mana validation section.

## Test evidence

### Python compile

Passed:

```bash
cd docs/hermes-analysis/manaloom-knowledge/scripts
python3 -m py_compile \
  sync_pg_target_deck_to_hermes.py \
  test_sync_pg_target_deck_to_hermes.py \
  master_optimizer_common.py \
  slot_optimizer.py \
  master_optimizer_quality_gate.py \
  master_optimizer_baseline.py \
  master_optimizer_confirmation.py \
  battle_analyst_v9.py \
  battle_forensic_audit.py \
  master_optimizer_apply.py \
  semantic_role_metrics.py \
  test_battle_functional_tags_json.py \
  test_semantic_role_metrics.py \
  _mana_validator.py \
  _run_validation.py \
  _update_cron_status.py
```

### Focused sync tests

Passed:

```bash
cd docs/hermes-analysis/manaloom-knowledge/scripts
python3 test_sync_pg_target_deck_to_hermes.py -v
```

Covered:

- JSON arrays and hashes are persisted;
- duplicate `card_id` rows are rejected;
- missing `card_id` is rejected;
- semantic SQL aggregates with `jsonb_agg`;
- semantic SQL does not use `LEFT JOIN LATERAL` or `LIMIT 1`.

### Semantic role metric tests

Passed:

```bash
cd docs/hermes-analysis/manaloom-knowledge/scripts
python3 test_semantic_role_metrics.py -v
```

Covered:

- multi-tag membership does not inflate deck cardinality;
- legacy `functional_tag` fallback still works;
- type fallback tags do not hide unclassified cards;
- extended tags such as `mana_fixing` and generic `payoff` do not become core
  validator roles by themselves.

### Battle functional tag bridge tests

Passed:

```bash
cd docs/hermes-analysis/manaloom-knowledge/scripts
python3 test_battle_functional_tags_json.py -v
```

Covered:

- `battle_analyst_v9.py` loads `functional_tags_json` when the column exists;
- one multi-role card remains one deck row;
- heuristic battle effects can use role membership from the array;
- legacy `functional_tag` remains fallback-compatible.

### Learned deck completeness tests

Passed:

```bash
cd docs/hermes-analysis/manaloom-knowledge/scripts
python3 test_learned_deck_completeness.py -v
```

### Hermes battle conformance

Passed:

```bash
cd docs/hermes-analysis/manaloom-knowledge/scripts
python3 test_battle_analyst_v10_3.py
```

The suite reported all battle conformance scenarios as `PASS`, including
Commander damage, stack/priority, replacement/prevention, modern 2026 rules,
multi-defender combat, targeting, ward/protection/hexproof and Lorehold
card-specific regressions.

### Backend analyze

Passed:

```bash
cd server
dart analyze bin lib routes test
```

### Diff hygiene

Passed:

```bash
git diff --check
```

The standard changed-lines secret scan was also run locally; no new
secret-like lines were found.

## Hermes runtime apply evidence

Hermes AWS pulled `master` at `bd7eb558` after stashing generated cron
artifacts. The previous runtime SQLite was backed up before apply:

`docs/hermes-analysis/manaloom-knowledge/backups/knowledge.db.pre-semantic-bd7eb558.20260611T192016Z`

Report-only gate before apply:

| Check | Result |
|---|---|
| apply | `false` |
| deck | `Runtime Lorehold Learned 19e93de3cca` |
| commander | `Lorehold, the Historian` |
| rows | `100` |
| total quantity | `100` |
| commanders | `1` |
| `deck_hash` length | `64` |
| `semantics_hash` length | `64` |

Apply gate after writing the real Hermes SQLite runtime:

| Check | Result |
|---|---|
| apply | `true` |
| cards seen/written | `100 / 100` |
| quantity seen/written | `100 / 100` |
| commanders written | `1` |
| SQLite rows | `100` |
| SQLite quantity | `100` |
| SQLite commanders | `1` |
| distinct `deck_hash` values | `1` |
| distinct `semantics_hash` values | `1` |
| missing semantic columns | `[]` |
| mana validator total cards | `100` |
| mana validator role sum | `155` |

Lorehold report-only baseline and slot scan after apply:

| Check | Result |
|---|---|
| preflight | `approved` |
| baseline games | `10` per opponent, `120` total |
| baseline WR | `95.0%` |
| baseline hash | `dbe24f7d5b17fbc8663afcd187d6381ccfb840f8a3b6486c4bdfad504c9d53fa` |
| slot scan phase | `semantic_snapshot_smoke` |
| candidates tested | `14` |
| blocked candidates | `2` |
| deck restored after scan | `100` rows, `100` quantity, `1` commander |
| premium Mox policy for Lorehold | no Chrome Mox, Mox Diamond or Mox Opal present |

## Remaining work

Slice 1 is not the final semantic migration. Remaining tasks:

1. Decide whether trusted `card_battle_rules` should derive missing
   `card_function_tags` through `sync_battle_card_rules_pg.py`.
2. Formalize card semantic identity (`oracle_id`, `layout`, faces) before
   implementing split/MDFC/DFC/adventure hard behavior.
3. Keep learned decks single-commander until partner/background corpus exists.
4. Review Lorehold positive report-only candidates before any apply:
   `Loran's Escape`, `Chain Lightning`, `Erode`, `Steelshaper's Gift`,
   `Furygale Flocking`, and `The Battle of Bywater`.

Consumer classification is now documented in
`HERMES_FUNCTIONAL_TAG_CONSUMER_CLASSIFICATION_2026-06-11.md`. Active
consumers are migrated/compatible; manual importers and historical scripts are
kept out of cron/apply until they receive a dedicated migration.

## Slice 2 ruleset hash validation

Local Slice 2 smoke passed before remote apply:

| Check | Result |
|---|---|
| `ruleset_hash` length in sync stats | `64` |
| distinct `ruleset_hash` values in SQLite smoke | `1` |
| semantic-only test | invalidates `semantics_hash`, not `deck_hash` |
| rules-only test | invalidates `ruleset_hash`, not `deck_hash` |

Hermes AWS then pulled `master` at `76d828d2`, created a real SQLite backup and
applied the `ruleset_hash` migration/snapshot:

`docs/hermes-analysis/manaloom-knowledge/backups/knowledge.db.pre-ruleset-76d828d2.20260611T194820Z`

Remote apply gate:

| Check | Result |
|---|---|
| apply | `true` |
| cards written | `100` |
| total quantity | `100` |
| commanders | `1` |
| distinct `deck_hash` values | `1` |
| distinct `semantics_hash` values | `1` |
| distinct `ruleset_hash` values | `1` |
| mana validator total cards | `100` |

Remote baseline/slot smoke after apply:

| Check | Result |
|---|---|
| latest baseline id | `2` |
| baseline games | `60` |
| baseline `deck_hash` length | `64` |
| baseline `semantics_hash` length | `64` |
| baseline `ruleset_hash` length | `64` |
| slot phase | `ruleset_hash_smoke` |
| slot rows with semantic hash | `7` |
| slot rows with ruleset hash | `7` |
| deck restored after smoke | `100` rows, `100` quantity, `1` commander |
| premium Mox policy for Lorehold | no Chrome Mox, Mox Diamond or Mox Opal present |
| remote git status after artifact stash | clean on `master...origin/master` |

The generated runtime artifacts were stashed on Hermes as
`post-ruleset-smoke-artifacts-20260611T195539Z`; the SQLite state remained
persisted after stash.

## Next recommended step

Proceed to the next controlled slice:

1. keep all Lorehold swaps report-only until owner review confirms candidate
   quality;
2. run a larger sample before applying any candidate;
3. define `logical_rule_key` and trusted derivation policy before letting
   `card_battle_rules` create `card_function_tags`;
4. keep backend/product as source of truth; Hermes proposes and reports only.
