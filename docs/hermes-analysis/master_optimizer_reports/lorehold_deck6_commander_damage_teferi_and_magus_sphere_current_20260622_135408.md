# Lorehold Deck 6 Commander Damage Response And Current Candidate Review - 2026-06-22

## Scope

This audit reconciles the current Lorehold Deck 6 battle evidence after the
PG024 Mental Misstep closure. It covers:

- the `replay.txt` final hand-card renderer requirement;
- a real battle-runtime bug in combat survival responses against commander
  damage lethal;
- the post-fix official-deck baseline;
- two local-only candidate deck simulations against the current seed window.

No PostgreSQL deck swap, PostgreSQL rule deploy, commit, push, or permanent
deck change was performed in this cycle.

## Replay Final Hand Cards

The human replay renderer now writes final hand contents for every player in
the `GAME OVER` block.

Evidence:

- Code: `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py`.
- Test: `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py`.
- Test commands passed:
  - `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py`
  - `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py`
- Real replay:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/manual-replay-handcards-check/20260622_102100/replay.txt`.
- Validated lines: the final player rows include `HandCards=[...]` for
  Lorehold and all three opponents.

Status: closed for the human replay renderer.

## Commander Damage Survival Bug

Baseline seed `63231325` showed a runtime defect, not a deck-only failure:
Lorehold held `Teferi's Protection` and enough mana, but the defensive response
window did not fire because it evaluated lethal player life damage and missed
commander damage reaching 21.

Fix:

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
  now computes projected combat damage details, including
  `commander_lethal` and `commander_lethal_sources`.
- `combat_defensive_response_window(...)` now fires when projected commander
  damage is lethal, even if player life damage alone is not lethal.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py`
  adds `test_combat_response_handles_commander_damage_lethal`.

Test evidence:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py`
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`

Focused battle evidence:

- Summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_134349/summary.json`.
- `run_profile=focus_commander_damage_teferi_fix_seed_63231325`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `mandatory_gate_divergences=[]`.
- `test_results_status_counts={"pass":18}`.
- Replay proof:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_134349/seed_63231325/replay.txt`.
- Replay lines show `CAST Lorehold: Teferi's Protection` during
  `combat_damage`, then `DAMAGE Kraum ... -> Lorehold: 0 player damage`.
- Decision trace:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_134349/seed_63231325/replay.decision_trace.jsonl`.
  Decision `decision-000164` has
  `actual_outcome=combat_survival_response_cast`,
  `commander_lethal=true`, and source damage `20 + 4 = 24`.

Reading:

- The runtime bug is closed.
- The same seed still loses the next turn to Thrasios combat damage, so the
  remaining failure is real survival/board-state weakness after the fixed
  response, not the original commander-damage bug.

## Official Deck Baseline After Fix

Full post-fix official-deck run:

- Summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_134502/summary.json`.
- `run_profile=full_after_commander_damage_teferi_fix_16_seed`.
- `seeds_completed=16`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `mandatory_gate_divergences=[]`.
- `test_results_status_counts={"pass":18}`.
- Lorehold wins: `1`.
- Opponent wins: `14`.
- Opponent combat to Lorehold: `328`.
- Opponent combat to other players: `5`.
- Strategy residue:
  `strategy_code_counts={"forced_keep_after_bad_mulligan":2}` with low
  confidence seeds `63231318` and `63231327`.

Decision:

- This is the current trusted same-window official-deck baseline.
- It confirms the deck is still weak under focused multiplayer pressure.

## Candidate Scan

### Ensnaring Bridge Over Electroduplicate

Local-only SQLite candidate:

- `Ensnaring Bridge` temporarily replaced `Electroduplicate`.
- Summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_133008/summary.json`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- Lorehold wins: `1`.
- Opponent wins: `13`.
- Opponent combat to Lorehold: `329`.
- Opponent combat to other players: `3`.
- Strategy residue:
  `strategy_code_counts={"forced_keep_after_bad_mulligan":3}`.

Decision: rejected. It did not improve wins and slightly worsened pressure to
Lorehold. No PostgreSQL deploy.

### Magus Of The Moat And Sphere Of Safety Over Electroduplicate And Victory Chimes

Local-only SQLite candidate:

- `Magus of the Moat` and `Sphere of Safety` temporarily replaced
  `Electroduplicate` and `Victory Chimes`.
- Pre-swap SQLite restore point used during the temporary candidate test:
  `docs/hermes-analysis/master_optimizer_reports/knowledge_db_backup_candidate_magus_sphere_over_electroduplicate_victory_current_20260622_105408.sqlite`.
- Summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_135408/summary.json`.
- `run_profile=candidate_magus_sphere_current_over_electroduplicate_victory_16_seed`.
- `battle_replay_final_status=review_required`.
- `mandatory_gate_divergences=["strategy_audit=review_required"]`.
- Lorehold wins: `2`.
- Opponent wins: `14`.
- Opponent combat to Lorehold: `267`.
- Opponent combat to other players: `3`.
- Strategy residue:
  `strategy_code_counts={"board_wipe_without_timing_justification":1,"forced_keep_after_bad_mulligan":1}`.
- Low-confidence seed: `63231318`.
- Lorehold win seeds: `63231314` and `63231324`.
- Review-required finding:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_135408/seed_63231314/strategy_audit.md`
  reports `board_wipe_without_timing_justification` on
  `decision-000299`.

Important latest note:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest`
  currently points to `20260622_135408`.
- That run is a candidate and is `review_required`; it must not be treated as
  the trusted official baseline.

Decision:

- The candidate has the best current positive signal: Lorehold wins improve
  from `1/16` to `2/16`, and opponent combat pressure to Lorehold drops from
  `328` to `267`.
- It is not promotion-ready because the mandatory strategy gate returns
  `review_required`, and the win rate remains too low.
- No PostgreSQL deploy or permanent deck swap should be made from this
  candidate yet.

## Current Deck State

Local runtime SQLite after restoration:

- Source:
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`.
- Query confirmed:
  `Electroduplicate=1`, `Victory Chimes=1`, deck rows `100`, deck quantity
  `100`.
- `Magus of the Moat`, `Sphere of Safety`, and `Ensnaring Bridge` are not
  present in the restored official runtime deck.

## Next Work

1. Inspect seed `63231314` candidate board-wipe trace to decide whether
   `board_wipe_without_timing_justification` is a real strategic error or an
   auditor false positive around miracle/upkeep/Teferi sequencing.
2. If the finding is valid, fix strategy sequencing before retesting the
   Magus+Sphere concept.
3. If the finding is an auditor false positive, correct the auditor rule and
   rerun the same candidate before considering any PostgreSQL deck package.
4. Continue deck search around early combat denial and post-survival
   conversion. The evidence does not support a PostgreSQL deck deploy yet.
