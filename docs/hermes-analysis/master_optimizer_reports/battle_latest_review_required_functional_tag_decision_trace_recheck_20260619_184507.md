# Battle latest review-required functional tag and decision trace recheck 2026-06-19

Scope: inspect the current `latest` battle audit artifact after it moved from a
trusted run to a `review_required` run, without changing code, PostgreSQL, swaps
or commits.

Guardrails:

- PostgreSQL was not modified.
- No swaps were applied.
- No code was changed.
- No commit was created.
- Only artifacts, logs, tests and documentation were inspected or written.

## Latest artifact

- Latest path:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_213957`
- Primary summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `timestamp_utc=2026-06-19T21:39:57Z`
- `seeds_requested=16`
- `seeds_completed=16`
- `battle_replay_final_status=review_required`
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`
- `mandatory_gate_divergences=["action_critic=review_required","forensic_audit=review_required"]`
- `action_findings=1`
- `forensic_rule_findings=4`
- `forensic_turn_findings=0`
- `forensic_severity_counts={"low":2,"medium":2}`
- `forensic_lineage_status=incomplete`
- `forensic_card_id_missing_unaccepted=2`
- `forensic_semantic_hash_missing_unaccepted=2`
- `seeds_with_high_or_critical_action_findings=[]`
- `seeds_with_strategy_blockers=[]`
- `seeds_with_high_or_critical_forensic_findings=[]`

No high/critical action finding or strategy blocker was present, but the run is
not learning-trusted because mandatory gates require review.

## Finding A: functional_tags_json returned

The previous latest recheck found zero runtime events with
`functional_tags_json`. The current latest contradicts that clean state.

Observed runtime events:

```text
seed_63202142 cast_announced Faeburrow Elder ramp_permanent heuristic turn=11
seed_63202142 cost_paid      Faeburrow Elder ramp_permanent heuristic turn=11
seed_63202142 spell_cast     Faeburrow Elder ramp_permanent heuristic turn=11
seed_63202150 cast_announced Faeburrow Elder ramp_permanent heuristic turn=7
seed_63202150 cost_paid      Faeburrow Elder ramp_permanent heuristic turn=7
seed_63202150 spell_cast     Faeburrow Elder ramp_permanent heuristic turn=7
```

For all six events:

- `rule_source=functional_tags_json`
- `rule_review_status=heuristic`
- `card_id` missing
- `semantic_hash` missing
- `rule_logical_key` missing
- `decision_trace_id` missing

Forensic findings:

```text
seed_63202142 turn=11 spell_cast Faeburrow Elder ramp_permanent medium
finding=Game event depended on heuristic source functional_tags_json.

seed_63202142 turn=11 spell_cast Faeburrow Elder ramp_permanent low
finding=Runtime effect ramp_permanent differs from registry effect ramp_ritual.

seed_63202150 turn=7 spell_cast Faeburrow Elder ramp_permanent medium
finding=Game event depended on heuristic source functional_tags_json.

seed_63202150 turn=7 spell_cast Faeburrow Elder ramp_permanent low
finding=Runtime effect ramp_permanent differs from registry effect ramp_ritual.
```

The primary summary reports the unaccepted lineage samples as missing `card_id`
and `semantic_hash` for `Faeburrow Elder` in seeds `63202142` and `63202150`.

Source context:

- `battle_analyst_v9.py:2034-2098` has manual runtime waivers for cards such as
  `Veil of Summer`, `Moonsnare Prototype`, `Sacrifice`, `Mardu Devotee`,
  `Orcish Lumberjack`, `Prized Statue`, `Rishkar, Peema Renegade`,
  `Jeweled Amulet`, `Ponder`, `Vivi Ornitier` and `Neoform`.
- `Faeburrow Elder` is not in that waiver set.
- `battle_analyst_v9.py:2746-2829` still allows fallback from
  `card_functional_tags(card)` to `TAG_EFFECTS[tag]` with
  `source=functional_tags_json`, `review_status=heuristic`.
- `battle_forensic_audit.py:134-141` classifies `functional_tags_json` as a
  heuristic source.
- `battle_forensic_audit.py:441-447` emits a finding when a non-creature or
  non-land game event depends on a heuristic source.

Operational reading:

- `BV-067` is active again for the current latest run.
- The problem is no longer only a latent fallback contract issue; the recurring
  corpus exercised a new card (`Faeburrow Elder`) that fell into the heuristic
  fallback.
- The forensic gate correctly kept the final status from becoming trusted, but
  the summary still does not publish a direct `functional_tags_json_event_count`
  or affected-card list outside the forensic missing samples.

## Finding B: Silence decision trace correlation gap

The action critic emitted one low finding:

```text
seed=63202150
action_id=action-000154
event_index=399
turn=6
phase=precombat_main
player=Lorehold
event=spell_cast
card=Silence
severity=low
code=missing_decision_trace
detail=Action has no matching decision trace.
recommendation=Emit a decision trace for cast/combat choices.
```

The source event is otherwise well-formed:

```text
event=spell_cast
card=Silence
phase=precombat_main
rule_source=curated
rule_review_status=verified
effect=silence_spell
locked_cost={white=1,generic=0}
source_zone=hand
card_id present
semantic_hash present
rule_logical_key present
decision_trace_id missing
```

A relevant decision trace exists:

```text
decision_id=decision-000070
turn=6
phase=precombat_main
player=Lorehold
decision_type=cast_spell
chosen_option.card=Silence
chosen_option.action=cast_high_threat
actual_outcome=cast_to_stack
rule_source=curated
rule_status=verified
```

However, `action_critic.md` attached `decision-000070` to an earlier
`miracle_cast` of `Silence` at turn 6 `draw_step`:

```text
action-000143 turn=6 phase=draw_step event=miracle_cast card=Silence
evidence=rule=curated/verified; effect=silence_spell; decision=decision-000070
```

Then the later precombat `spell_cast` of `Silence` was left without a matching
decision:

```text
action-000154 turn=6 phase=precombat_main event=spell_cast card=Silence
verdict=low evidence=rule=curated/verified; effect=silence_spell
```

Source context:

- `battle_action_critic.py:852-868` builds the decision match key as
  `(turn, player, card)` for `DECISION_ACTION_EVENTS`.
- If a match exists, it pops the first decision from that key.
- If no match remains for `spell_cast`, `creature_cast` or `commander_cast`, it
  emits `missing_decision_trace`.
- The key does not include phase, event kind, cast pipeline or an explicit
  `decision_trace_id`.

Operational reading:

- This is not a bad card rule for `Silence`; the rule source is curated and
  verified.
- The gap is a correlation/lineage contract issue between event ledger and
  decision trace ledger when the same card appears more than once in the same
  turn.
- The action critic likely consumed the precombat `Silence` decision on the
  earlier draw-step `miracle_cast` because both share the same `(turn, player,
  card)` key.
- The correct closure is to emit and validate explicit decision lineage, or to
  make critic matching phase/event-aware enough that repeated same-card actions
  in one turn cannot steal each other's trace.

## Tests run

```text
PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py
PASS 12 tests
```

```text
PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_forensic_audit_supported_effects.py
PASS 9 tests
```

```text
PYTHONDONTWRITEBYTECODE=1 python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_functional_tags_json.py
Ran 1 test
OK
```

The targeted tests passing is important evidence: current tests do not fully
cover the latest run regression where `Faeburrow Elder` falls through
`functional_tags_json`, nor the repeated-card same-turn decision trace
correlation gap for `Silence`.

## Register impact

- Reopen/escalate `BV-067` from latent P3 wording to active P2 current-latest
  evidence.
- Add a new finding for the same-card same-turn action/decision trace
  correlation gap observed on `Silence`.
- Keep the high/critical notification status clear: no high/critical action,
  strategy or forensic findings are present in this latest summary.
