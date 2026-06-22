# Replay Final HandCards Renderer - 2026-06-22 10:21 -0300

## Scope

Complementar o `replay.txt` para que o fechamento `GAME OVER` mostre tambem
as cartas que ainda estao na mao de cada jogador, nao apenas a contagem.

## Code Change

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py`
  agora usa `write_final_player_summary(...)` no fechamento do jogo.
- A linha final por jogador passa a incluir:
  `HandCards=[...]`.
- A lista usa `battle.replay_card_snapshot(...)`, o mesmo snapshot estruturado
  usado nos eventos `turn_start`/`turn_end`.

## Test Evidence

Comandos executados:

```bash
python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py
PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py
```

Resultado:

- `py_compile`: pass.
- `test_battle_replay_v10_3_renderer.py`: 10 testes pass.
- Novo teste: `test_final_player_summary_includes_hand_card_names`.

## Runtime Evidence

Replay real gerado:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/manual-replay-handcards-check/20260622_102100/replay.txt`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/manual-replay-handcards-check/20260622_102100/replay.events.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/manual-replay-handcards-check/20260622_102100/replay.decision_trace.jsonl`

Trecho validado do `replay.txt`:

```text
Winner: Thrasios, Triton Hero #115 (real) (elimination)
Lorehold: DEAD Life=0 Hand=5 HandCards=[Recruiter of the Guard, Valakut Awakening // Valakut Stoneforge, Wheel of Misfortune, Reiterate, Swords to Plowshares]
Thrasios, Triton Hero #115 (real): ALIVE Life=40 Hand=4 HandCards=[Commandeer, Mindbreak Trap, Force of Negation, Fierce Guardianship]
Thrasios, Triton Hero #54 (real): ALIVE Life=40 Hand=8 HandCards=[Voice of Victory, Ranger-Captain of Eos, Tainted Pact, Tropical Island, Marsh Flats, Flooded Strand, Rhystic Study, Faerie Mastermind]
Rograkh, Son of Rohgahh #62 (real): ALIVE Life=33 Hand=5 HandCards=[Force of Negation, Deflecting Swat, Enduring Vitality, Gilded Drake, Displacer Kitten]
```

## Status

Fechado para renderer humano: o `replay.txt` agora expõe as cartas remanescentes
na mao de cada jogador no `GAME OVER`.
