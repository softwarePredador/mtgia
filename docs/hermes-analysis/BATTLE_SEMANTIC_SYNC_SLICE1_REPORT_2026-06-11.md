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

## Remaining work

Slice 1 is not the final semantic migration. Remaining tasks:

1. Apply the new snapshot to the real Hermes SQLite runtime only after a
   controlled backup/report-only handoff.
2. Add `semantics_hash`/`ruleset_hash` awareness to optimizer baseline and
   quality gate.
3. Decide whether trusted `card_battle_rules` should derive missing
   `card_function_tags` through `sync_battle_card_rules_pg.py`.
4. Formalize card semantic identity (`oracle_id`, `layout`, faces) before
   implementing split/MDFC/DFC/adventure hard behavior.
5. Keep learned decks single-commander until partner/background corpus exists.

Consumer classification is now documented in
`HERMES_FUNCTIONAL_TAG_CONSUMER_CLASSIFICATION_2026-06-11.md`. Active
consumers are migrated/compatible; manual importers and historical scripts are
kept out of cron/apply until they receive a dedicated migration.

## Next recommended step

Proceed to Slice 2 only after this report is committed:

1. run a controlled Hermes runtime backup + apply;
2. add `semantics_hash` checks to optimizer baseline/quality-gate reports;
3. then run Lorehold baseline/slot scan in report-only mode against the real
   Hermes DB.
