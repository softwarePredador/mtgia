# Lorehold Entreat X-Token Runtime Preflight

- Generated at: `2026-07-05T02:18:41Z`
- Status: `entreat_x_token_runtime_primitive_ready_rule_still_blocked_keep_607`
- Current baseline: `deck_607`
- Source DB mutated: `False`
- Deck 607 mutated: `False`
- Prior best first runtime contract: `Entreat the Angels`

## Summary

| Metric | Value |
| --- | ---: |
| `runtime_primitive_ready` | `True` |
| `entreat_active_rule_count` | `0` |
| `battle_ready_now_count` | `0` |
| `natural_battle_allowed_now` | `False` |
| `promotion_allowed` | `False` |

## Runtime Checks

| Check | Pass |
| --- | ---: |
| `x_value_helper` | `True` |
| `token_count_uses_x_value` | `True` |
| `token_count_per_x_guard` | `True` |
| `cast_planner_uses_x_token_count` | `True` |
| `tokens_created_replay_source` | `True` |
| `tokens_created_replay_x_value` | `True` |

## Test Checks

| Check | Pass |
| --- | ---: |
| `focused_test_exists` | `True` |
| `entreat_fixture` | `True` |
| `x_value_fixture` | `True` |
| `angel_token_model` | `True` |
| `xx_cost_plan_test` | `True` |
| `replay_assertion` | `True` |

## Decision

- Keep 607 as protected baseline: `True`
- Natural battle allowed now: `False`
- Promotion allowed: `False`
- Recommended next action: `draft_reviewed_entreat_card_rule_package_without_apply_then_gate`
- Reason: The generic X token runtime primitive is now present and covered by a focused Entreat-style fixture, but Entreat still has no reviewed active card rule and has not passed a natural battle gate against protected deck 607.
