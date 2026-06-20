# Battle latest functional tag lineage recheck 2026-06-19

Scope: recheck `BV-067` against the current `latest` battle audit artifact,
the active `functional_tags_json` fallback path, forensic behavior and targeted
tests.

Guardrails:

- PostgreSQL was not modified.
- No swaps were applied.
- No code was changed.
- No commit was created.
- Only artifacts, logs and documentation were inspected or written.

## Latest artifact

- Latest path:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_204826`
- Primary summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `timestamp_utc=2026-06-19T20:48:26Z`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `seeds_requested=16`
- `seeds_completed=16`
- `mandatory_gate_divergences=[]`
- `action_findings=0`
- `forensic_lineage_status=complete`
- `forensic_rule_findings=0`
- `forensic_turn_findings=0`
- `forensic_severity_counts={}`
- `seeds_with_high_or_critical_action_findings=[]`
- `seeds_with_strategy_blockers=[]`
- `seeds_with_high_or_critical_forensic_findings=[]`
- `forensic_lineage_unaccepted_missing_samples=[]`

No high/critical action finding or strategy blocker was present in the latest
summary.

## Latest runtime result

The old `functional_tags_json` blocker is not present in latest
`20260619_204826`.

Search result:

```text
functional_tags_json appears only in runtime_surface_manifest.md/json as the
test file name test_battle_functional_tags_json.py.
```

Event scan:

```text
0 replay.events.jsonl events with rule_source=functional_tags_json
0 replay.events.jsonl events with source=functional_tags_json
0 replay.events.jsonl events with lineage_source=functional_tags_json
```

Forensic aggregate by source across the latest seed artifacts:

```text
curated 1367
manual_runtime_waiver 4
type_line_creature 18
```

The manual runtime waiver rows observed in replay events are for:

```text
Moonsnare Prototype ramp_permanent
Neoform tutor
Orcish Lumberjack creature
```

This means the earlier affected cards now resolve through verified
`manual_runtime_waiver` or other non-functional-tag sources in the latest run.

## Source evidence

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py:2018-2099`:
  current manual runtime waivers explicitly replace stale or heuristic
  `functional_tags_json` behavior for cards including `Mardu Devotee`,
  `Orcish Lumberjack`, `Neoform`, `Moonsnare Prototype`, `Sacrifice`,
  `Prized Statue`, `Rishkar`, `Jeweled Amulet`, `Ponder`, `Vivi Ornitier` and
  related cards.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py:2746-2829`:
  `get_card_effect(...)` still has an executable fallback from
  `card_functional_tags(card)` into `TAG_EFFECTS[tag]` with
  `source=functional_tags_json`, `review_status=heuristic` and
  `confidence=0.35`.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py:134-141`:
  `functional_tags_json` is classified as a heuristic source.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py:441-447`:
  forensic audit reports a high finding when a non-creature/non-land game event
  depends on a heuristic source.
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_functional_tags_json.py:15-99`:
  the existing functional-tags test covers deck-row loading and multi-tag
  behavior, and still expects `get_card_effect(...)` to derive effects from
  functional tags for synthetic rows.
- `runtime_surface_manifest.json`: `test_battle_functional_tags_json.py` is
  `outside_recurring_run` with `gate_expected=targeted_test_required_before_change`.

## Synthetic forensic proof

I ran a read-only synthetic event through `battle_forensic_audit.py`:

```json
{
  "event": "spell_resolved",
  "turn": 1,
  "player": "Tester",
  "card": "Synthetic Functional Fallback",
  "effect": "draw_cards",
  "rule_source": "functional_tags_json",
  "rule_review_status": "heuristic"
}
```

Forensic result:

```text
by_source.functional_tags_json=1
rule_findings=1
severity=high
finding=Game event depended on heuristic source `functional_tags_json`.
lineage_missing_unaccepted: rule_logical_key, card_id, semantic_hash
```

This proves the current forensic gate still rejects a learning-grade action
event if `functional_tags_json` reappears.

## Tests run

```text
PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_functional_tags_json.py
Ran 1 test
OK
```

```text
PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_forensic_audit_supported_effects.py
PASS test_supported_effects_cover_live_engine_handlers
PASS test_rise_of_the_eldrazi_uses_composite_oracle_runtime
PASS test_manual_runtime_waiver_cards_do_not_use_functional_tags
PASS test_sacrifice_waiver_uses_sacrificed_creature_mana_value
PASS test_forensic_accepts_manual_runtime_waiver_over_stale_registry_rule
PASS test_forensic_accepts_type_line_creature_fact_without_rule_identity
PASS test_forensic_accepts_curated_land_played_runtime_rule_without_pg_card_identity
PASS test_forensic_accepts_composite_runtime_over_primary_registry_effect
PASS test_forensic_keeps_unaccepted_lineage_missing_visible
```

```text
PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py
PASS test_load_deck_preserves_semantic_snapshot_identity_fields
PASS test_functional_tag_gate_cards_resolve_from_manual_waivers
```

## Operational reading

- The old `BV-067` blocker is not present in latest `20260619_204826`.
- The final gate would block a new non-creature/non-land action event sourced
  from `functional_tags_json`; a synthetic proof confirms this.
- The fallback path still exists in runtime, and the dedicated functional-tags
  test is outside the recurring run. Therefore this should remain tracked as a
  narrower latent-coverage issue rather than as an active latest blocker.
- The best next contract improvement is to publish
  `functional_tags_json_event_count` and affected cards in the summary, and to
  add an explicit recurring/synthetic fixture showing that such events make a
  run non-learning-grade unless they are promoted to verified rules or covered by
  a formal waiver.

Recommended `BV-067` scope: keep open as P3 until the fallback path is either
removed from action execution, or the recurring gates publish and test an
explicit zero/blocked contract for `functional_tags_json`.
