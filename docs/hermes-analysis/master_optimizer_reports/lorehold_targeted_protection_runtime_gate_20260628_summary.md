# Lorehold targeted protection runtime gate - 2026-06-28

## Runtime change

- Added stack-response support for targeted color protection:
  - `Gods Willing` / `Sejiri Shelter` style effects now protect the declared creature target from the source color on the stack.
  - `Mother of Runes` / `Giver of Runes` style tap abilities now respond to targeted removal when the permanent is untapped and not summoning sick.
  - `protection_from: colorless` is now respected by targeting legality for Giver-style cases.
- The response protects the live battlefield object, not a copied target from `effect_data` after `apply_effect_immediate` deep-copy.

## Seed 7 diagnosis

- Reproduced the existing seed 7 Sisay game with event and decision tracing.
- `Into the Flood Maw` targeted `Lorehold, the Historian` on turn 4.
- Lorehold passed priority with:
  - available mana: `1`
  - battlefield: `Plains // Plains`, `Sol Ring`, `Marsh Flats`, `Urza's Saga`, `Mountain // Mountain`, `Lorehold, the Historian`
  - hand: `Improvisation Capstone`, `Prismari Pianist`, `Mizzix's Mastery`, `The Scarlet Witch`, `Prismatic Vista`, `Victory Chimes`
- Conclusion: that loss was not a Top/Saga executor bug and not a missed protection response. The deck had no protection/counter response available in that exact window.

## Validation

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_targeted_protection_response.py`
- `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_targeted_protection_response.py -q` -> `2 passed`
- Lorehold focused pytest group:
  - `test_lorehold_variant_battle_gate.py`
  - `test_lorehold_failure_targeted_synergy_hypotheses.py`
  - `test_lorehold_next_action_planner.py`
  - `test_lorehold_targeted_protection_response.py`
  - result: `20 passed`
- Lorehold queue/package pytest group:
  - `test_lorehold_failure_targeted_trace_audit.py`
  - `test_lorehold_next_hypothesis_queue.py`
  - `test_lorehold_synergy_package_gate.py`
  - result: `24 passed, 8 subtests passed`
- Full `test_battle_analyst_v10_3.py` script progressed through local battle/runtime regression tests and then stopped only at the promoted PostgreSQL hotfix test because the remote PostgreSQL server returned: `database system is in recovery mode`.

## Battle gates

Source DB:
`docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`

| seed | result | notes |
| --- | ---: | --- |
| `7` | `0-3-0` | Still fails; Sisay loss has no available protection in hand, so this is strategic/curve vulnerability. |
| `20260625` | `1-2-0` | Preserves previous middle result; protection/activation events observed. |
| `42` | `3-0-0` | Preserves previous strong result with `13` miracle casts and `12` topdeck activations. |

## Next action

The runtime now understands the relevant targeted-protection family. The remaining problem is deck construction: Lorehold needs better early access to protection/recast/tempo without cutting the cards that make seed 42 work.
