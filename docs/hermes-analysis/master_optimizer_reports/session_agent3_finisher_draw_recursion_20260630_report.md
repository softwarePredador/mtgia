# Session Agent 3 Finisher/Draw/Recursion Runtime Report

- Generated at: `2026-06-30T14:05:00Z`
- Branch/worktree: `codex/session-agent3-finisher-draw-recursion-20260630` in `/Users/desenvolvimentomobile/.codex/worktrees/7a8b/mtgia`
- PostgreSQL writes: `false`
- SQLite source mutated: `false`
- XMage root used: `/Users/desenvolvimentomobile/Downloads/mage-master`
- Scope: runtime/deck-relevant finisher, draw/selection, recursion/recovery from current Lorehold + opponent queue.

## Closed Runtime Cases

| Card | Family/lane | XMage source | ManaLoom runtime scope | Runtime evidence | PG status |
| --- | --- | --- | --- | --- | --- |
| `Ancient Gold Dragon` | `finisher_or_big_spell` / `token_maker` | `Mage.Sets/src/mage/cards/a/AncientGoldDragon.java` | `source_combat_damage_player_roll_d20_create_faerie_dragon_tokens_equal_result_v1` | `test_session_agent3_finisher_draw_recursion_runtime.py` proves lookup plus combat damage to player rolls d20 and creates that many 1/1 blue flying Faerie Dragon tokens. `test_ancient_copper_dragon_runtime.py` proves the existing Treasure d20 path still passes. | Runtime waiver only. Needs Oracle hash, PG precheck, package, apply approval, sync, and postcheck before durable truth. |
| `Leyline Dowser` | `recursion` / recovery | `Mage.Sets/src/mage/cards/l/LeylineDowser.java` | `pay_one_tap_mill_one_instant_sorcery_to_hand_tap_legendary_creature_to_untap_v1` | `test_session_agent3_finisher_draw_recursion_runtime.py` proves lookup plus pay-one/tap/mill-one and milled instant/sorcery-to-hand. `test_artifact_topdeck_runtime.py` still passes against the existing injected-effect scenario. | Runtime waiver only. Needs Oracle hash, PG precheck, package, apply approval, sync, and postcheck before durable truth. |

Runtime logical keys observed from `get_card_effect`:

- `Ancient Gold Dragon`: `battle_rule_v1:f54c9323dfb56e0d3d180cfbb3b360c6`
- `Leyline Dowser`: `battle_rule_v1:8000d738167f82f55b94e678f8a327c7`

## Manual/Blocked Cases

| Card | Family | XMage source | Reason not closed in this pass |
| --- | --- | --- | --- |
| `Naktamun Lorespinner // Wheel of Fortune` | `draw_engine` | `Mage.Sets/src/mage/cards/n/NaktamunLorespinner.java` | Requires `PrepareCard` state, upkeep condition across all players with hand size <= 1, and alternate prepared spell face resolution for Wheel of Fortune. This is broader than a safe exact draw-engine patch. |
| `Charmbreaker Devils` | `recursion` | `Mage.Sets/src/mage/cards/c/CharmbreakerDevils.java` | Requires random instant/sorcery graveyard selection at upkeep plus spell-cast pump until end of turn on the source creature. The current safe recursion support does not model both random upkeep return and temporary self-pump together. |

## Tests And Gates

Passed:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_session_agent3_finisher_draw_recursion_runtime.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_ancient_copper_dragon_runtime.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_artifact_topdeck_runtime.py`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_strategy_consistency_audit.py --output-prefix docs/hermes-analysis/master_optimizer_reports/session_agent3_finisher_draw_recursion_20260630_xmage_strategy` -> `status=pass`, `26/26` checks.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/operational_surface_alignment_audit.py --out-prefix docs/hermes-analysis/master_optimizer_reports/session_agent3_finisher_draw_recursion_20260630_operational_surface` -> `status=pass`, `29/29` checks.

Read-only queue:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_runtime_gap_family_queue.py --xmage-root /Users/desenvolvimentomobile/Downloads/mage-master --output-prefix docs/hermes-analysis/master_optimizer_reports/session_agent3_finisher_draw_recursion_20260630_queue_after_runtime`
- Output: `blocked_runtime_rule_gap_count=61`, `family_count=16`, `mutations_performed=[]`.
- Interpretation: the queue reads current PG/SQLite rule state; these runtime waivers are intentionally not counted as durable PG/SQLite closure.

## Impact

- `Ancient Gold Dragon` now has an executable combat-damage finisher model: source combat damage to a player rolls d20 and creates capped runtime tokens with the XMage token shape relevant to battle pressure.
- `Leyline Dowser` now resolves from lookup instead of injected test data, so deck/battle runtime can execute its exact mill-to-hand recursion path when present.
- No deck gates, mapper static/tutor surfaces, integration reports, PostgreSQL rows, or SQLite source data were changed.

## Remaining PG Work

Before promotion to durable truth:

1. Compute and verify Oracle hash for `Ancient Gold Dragon` and `Leyline Dowser`.
2. Build PG package with precheck/apply/rollback/postcheck SQL.
3. Request explicit user approval before any PostgreSQL apply.
4. Sync PG to Hermes/SQLite and rerun the queue/gates so the current-rule filter removes these cards from the durable blocked set.
