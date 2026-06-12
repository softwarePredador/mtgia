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

After pushing commit `74850947`, Hermes AWS pulled `origin/master` and ran the
same compile/test/forensic flow with the real `knowledge.db`.

Result:

```json
{
  "remote_head": "74850947",
  "card_event_count": 45,
  "rule_logical_key_present": 45,
  "rule_logical_key_missing": 0,
  "card_id_present": 24,
  "card_id_missing": 21,
  "semantic_hash_present": 24,
  "semantic_hash_missing": 21
}
```

Interpretation: rule-level provenance is complete for this seed; card identity
provenance is now wired but still partial because some replay paths generate or
copy card/event payloads without preserving the original snapshot identity.
This is a concrete follow-up gap, not a blocker for this telemetry-only slice.

Follow-up inspection grouped the `21` missing identity events:

```json
{
  "by_player": {
    "Ral, Monsoon Mage #48 (real)": 5,
    "Rograkh, Son of Rohgahh #119 (real)": 11,
    "Rograkh, Son of Rohgahh #95 (real)": 5
  },
  "by_event": {
    "end_step_instant": 2,
    "land_played": 12,
    "spell_cast": 5,
    "spell_resolved": 2
  },
  "by_effect": {
    "counter": 4,
    "land": 12,
    "ramp_permanent": 4,
    "ramp_engine": 1
  }
}
```

Those missing identities came from learned real-opponent decks, not the synced
Lorehold target deck. The safe rule is: do not synthesize fake `card_id` values
for these cards. Identity should be attached only when the card came from a
trusted snapshot or a PG-backed resolver. Until learned-opponent cardlists carry
stable IDs, forensic should report the gap instead of masking it.

## Not Implemented In This Slice

- `card_id` in every replay event.
- `semantic_hash` in every replay event.
- Per-card semantic hash. The current `semantic_hash` is propagated from the
  deck snapshot `semantics_hash` when present; per-card hashing requires a
  separate schema/payload decision.
- Learned real-opponent deck cardlists without stable PG-backed `card_id`
  values. These must stay visible as missing identity instead of receiving fake
  IDs.
- Any global policy against Mox cards.
- Partner/background learned deck support.
- Any user-facing Hermes metadata.
- Any hard execution behavior for `needs_review` rules.
- Any automatic apply from `card_battle_rules` to `card_function_tags`.

## Next Safe Slice

1. Add stable IDs to learned-opponent cardlists only through a PG-backed
   resolver/sync. Do not synthesize IDs inside battle replay.
2. Decide whether deck-level `semantics_hash` is enough for replay diagnostics
   or whether a new per-card semantic hash field is required.
3. Only after that, evaluate whether replay/forensic has enough provenance to
   support broader battle-rule migration work.

## Follow-Up Tooling

`audit_learned_opponent_card_identity.py` was added as the report-only first
step for the learned-opponent gap. It reads Hermes SQLite `learned_decks`,
resolves card names against PostgreSQL `cards`, and reports:

- deck count inspected;
- card instances inspected;
- resolved instances;
- unresolved instances;
- ambiguous instances;
- bounded unresolved samples;
- `apply=false`.

The script does not write SQLite or PostgreSQL. Any future sync that persists
resolved IDs must be a separate reviewed step with tests and a rollback path.
