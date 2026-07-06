# Commander AI Prompt Eval Suite - 2026-07-06

Status: `active_quality_gate`.

This suite validates whether ManaLoom AI deckbuilder/optimizer responses stay
coherent with the Commander deckbuilding contract, battle feedback boundaries,
collection/budget constraints, and product explanation requirements.

It is deterministic and offline by default. It does not call the model. It
scores fixed candidate responses and can also score a live/model response JSON
against one selected case.

## Command

```bash
./scripts/quality_gate.sh ai-eval
```

Direct runner:

```bash
cd server
dart run bin/commander_ai_prompt_eval.dart \
  --fixtures test/fixtures/commander_ai_prompt_eval_cases.json \
  --out-prefix ../docs/hermes-analysis/master_optimizer_reports/commander_ai_prompt_eval_manual
```

To score a model output against one case:

```bash
cd server
dart run bin/commander_ai_prompt_eval.dart \
  --case kaalia_collection_budget_bracket3 \
  --response /path/to/model_response.json
```

## Current Cases

- `kaalia_collection_budget_bracket3`: validates collection preference, BRL
  budget, bracket 3 guardrails, protected anchors, and battle-feedback blocked
  pairs such as `+Feed the Swarm / -Birgi` and `+Feed the Swarm /
  -Archaeomancer's Map`.
- `lorehold_protected_anchor_bracket2`: validates Lorehold anchor protection,
  bracket 2 power discipline, and low-curve ramp upgrades without cutting
  protected engines.
- `atraxa_budget_curve_no_cedh`: validates four-color identity, budgeted
  upgrades, collection match, curve improvement, and avoiding cEDH assumptions.

## Scoring Criteria

The evaluator checks:

- response has summary and swap list;
- removed cards are in the original deck;
- additions are not already in the deck;
- protected anchors are not cut;
- every referenced card is fixture-catalog backed;
- addition color identity fits the commander;
- addition min bracket fits the requested bracket;
- each swap preserves a functional lane;
- exact blocked add/cut pairs from battle feedback are rejected;
- explanation covers function, risk, curve, price, and bracket;
- response does not claim battle/win-rate proof without explicit evidence;
- purchase total stays inside budget;
- collection preference reaches the expected owned-card count;
- before/after role counts meet the expected floor or delta.

## Boundary

This gate proves prompt/output coherence for fixed regression cases. It does
not replace:

- live OpenAI/model regression testing;
- legal/card resolver validation;
- PostgreSQL migration state;
- equal-seed battle gates;
- replay traces proving that key cards were drawn, cast, or used.

The expected use is to run this gate whenever prompt text, optimizer context,
recommendation explanation, collection/budget logic, or battle-feedback
surfacing changes.
