# PG033 Land Tax Focused Replay Summary

- Scenario: controller has Land Tax and 1 land; live opponent has 3 lands.
- Source rule: `battle_rule_v1:e3f5f35c6a9ee4fd8c7b9972c4152bef`.
- Oracle hash: `83b074e38da3e6c4eb6ec3e7568c914b`.
- Upkeep result: moved 3 basic lands from library to hand.
- Found cards: Island, Mountain, Plains.
- Nonbasic Command Tower remained in library.
- Event proof: `docs/hermes-analysis/master_optimizer_reports/land_tax_pg033_focused_events_20260622_201417.jsonl`.
- Decision trace proof: `docs/hermes-analysis/master_optimizer_reports/land_tax_pg033_focused_decision_trace_20260622_201417.jsonl`.
- Caveat: reveal and shuffle are represented as event metadata; this deterministic focused replay does not randomize library order after the search.
