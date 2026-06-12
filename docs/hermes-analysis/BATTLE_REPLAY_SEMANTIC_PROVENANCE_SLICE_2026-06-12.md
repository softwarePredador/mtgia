# Battle Replay Semantic Provenance Slice 2026-06-12

## Status

`PASS_WITH_SCOPE_LIMITS`

This report tracks replay/forensic provenance only. It does not change
battle execution, deck generation, optimize enforcement, Mox policy, learned
deck scope, or `needs_review` behavior.

## Product Constraints Preserved

- Release stability first.
- No global Mox ban.
- Learned decks remain single-commander until partner/background corpus exists.
- Duplicate Commander singleton identity must still block save/import outside
  this slice.
- Hermes metadata stays hidden from normal users.
- Hermes proposes; backend owns product decisions.
- `needs_review` battle rules do not execute hard behavior.
- `card_battle_rules` can derive deckbuilding tags only when trusted and
  traceable.
- This coding slice is limited to aggregation/provenance snapshot plus tests.

## What Changed

### `battle_rule_registry.py`

- Adds a registry-owned `logical_rule_key(rule)` helper.
- The key is based on equivalent executable semantics:
  - `effect_json`
  - `deck_role_json`
  - `face_name`
  - `face_index`
  - `variant_kind`
  - `ability_kind`
  - `timing_window`
  - `source_zone`
- The key intentionally excludes provenance/review metadata, so different
  review rows with the same actual behavior can be traced as equivalent without
  collapsing distinct card functions.
- `load_active_battle_card_rules()` now loads `oracle_hash` and returns
  `logical_rule_key` for each active rule.

### `battle_analyst_v9.py`

- `load_deck()` now loads optional `card_id` and `semantics_hash` from Hermes
  SQLite `deck_cards` when those columns exist.
- Legacy SQLite decks without those columns remain compatible.
- `with_rule_metadata()` can now carry:
  - `_rule_logical_key`
  - `_rule_oracle_hash`
- `replay_rule_fields()` now emits optional replay fields when available:
  - `card_id`
  - `semantic_hash`
  - `rule_logical_key`
  - `rule_oracle_hash`
  - `variant_kind`
  - `source_zone`
  - `alternative_cost_kind`
- This is telemetry only. It does not alter card selection, effect resolution,
  targeting, priority, combat, or legality.

### `battle_forensic_audit.py`

- Adds forensic coverage counters:
  - `rule_logical_key_present`
  - `rule_logical_key_missing`
  - `card_id_present`
  - `card_id_missing`
  - `semantic_hash_present`
  - `semantic_hash_missing`
  - `by_rule_logical_key`
- Legacy replay JSONL remains compatible. Events without logical keys are
  counted as missing instead of failing.

### Tests

- `battle_card_import_tests.py` now asserts that a verified
  `battle_card_rules` rule carries `_rule_logical_key`, `_rule_oracle_hash`,
  `card_id`, `semantic_hash`, and exposes them in replay fields.
- `battle_card_import_tests.py` also asserts that `load_deck()` preserves
  `card_id` and `semantics_hash` from Hermes SQLite snapshots.

## Validations Run Locally

```bash
cd docs/hermes-analysis/manaloom-knowledge/scripts
python3 -m py_compile battle_rule_registry.py battle_analyst_v9.py battle_forensic_audit.py battle_replay_v10_3.py battle_card_import_tests.py test_battle_analyst_v10_3.py
python3 test_battle_analyst_v10_3.py
```

Result: all listed Python files compile, and `test_battle_analyst_v10_3.py`
passed.

Synthetic forensic replay validation:

```bash
python3 battle_forensic_audit.py \
  --events /tmp/battle_forensic_semantic_provenance_events.jsonl \
  --json-report /tmp/battle_forensic_semantic_provenance.json
```

Result:

```json
{
  "rule_logical_key_present": 1,
  "rule_logical_key_missing": 0,
  "card_id_present": 1,
  "card_id_missing": 0,
  "semantic_hash_present": 1,
  "semantic_hash_missing": 0,
  "by_rule_logical_key": {
    "battle_rule_v1:unit": 1
  }
}
```

Legacy replay compatibility validation:

```bash
python3 battle_forensic_audit.py \
  --events ../../master_optimizer_reports/forensic_replays/battle_forensic_seed_923.jsonl \
  --json-report /tmp/battle_forensic_legacy_compat.json
```

Result:

```json
{
  "card_event_count": 73,
  "rule_logical_key_present": 0,
  "rule_logical_key_missing": 73,
  "card_id_present": 0,
  "card_id_missing": 73,
  "semantic_hash_present": 0,
  "semantic_hash_missing": 73
}
```

## Hermes AWS Validation

After pushing commit `879644d2`, Hermes AWS pulled `origin/master` and ran:

```bash
cd /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts
python3 -m py_compile battle_rule_registry.py battle_analyst_v9.py battle_forensic_audit.py battle_replay_v10_3.py battle_card_import_tests.py test_battle_analyst_v10_3.py
python3 test_battle_analyst_v10_3.py
python3 battle_forensic_audit.py --generate 1 --seed 42 --json-report /tmp/hermes_battle_forensic_semantic_provenance.json
```

Result:

```json
{
  "remote_head": "879644d2",
  "card_event_count": 50,
  "rule_logical_key_present": 49,
  "rule_logical_key_missing": 1,
  "by_rule_logical_key_count": 18
}
```

## Not Implemented In This Slice

- `card_id` in every replay event.
- `semantic_hash` in every replay event.
- Per-card semantic hash. The current `semantic_hash` is propagated from the
  deck snapshot `semantics_hash` when present; per-card hashing requires a
  separate schema/payload decision.
- Any global policy against Mox cards.
- Partner/background learned deck support.
- Any user-facing Hermes metadata.
- Any hard execution behavior for `needs_review` rules.
- Any automatic apply from `card_battle_rules` to `card_function_tags`.

## Next Safe Slice

1. Run the updated `card_id`/`semantic_hash` coverage validation on Hermes AWS
   against the real `knowledge.db`.
2. Decide whether deck-level `semantics_hash` is enough for replay diagnostics
   or whether a new per-card semantic hash field is required.
3. Only after that, evaluate whether replay/forensic has enough provenance to
   support broader battle-rule migration work.
