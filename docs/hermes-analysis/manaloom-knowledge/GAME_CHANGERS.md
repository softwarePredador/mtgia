# Commander Game Changers

Status: `current_reference`.

The canonical reviewed list is
`server/config/commander_game_changers.json`. It records the official source,
review date, schema, and all 53 names. The generated runtime set is
`officialGameChangerNamesForBracketPolicy` in
`server/lib/edh_bracket_policy.dart`.

Do not use the optional Hermes `game_changers` table as runtime truth. That
table may be absent from a current cache and previously contained research
fields that drifted from the actual Dart classifier.

## Operating Contract

- Game Changer membership is a power-intent signal, not card quality, deck
  synergy, legality, or an automatic add/cut decision.
- Brackets 1 and 2 allow no Game Changers, bracket 3 allows at most three, and
  brackets 4 and 5 do not impose a Game Changer count limit.
- A Game Changer can also consume another functional budget such as fast mana,
  tutor, free interaction, stax, protection, board wipe, card advantage, or
  value engine.
- The Commander update checked on 2026-07-14 retains five brackets, adds
  `Biorhythm` and `Farewell` to the list, and does not change hybrid color
  identity to an OR rule.
- `Lutri, the Spellchaser` is legal as a card but remains prohibited as a
  companion. This is a legality rule, not Game Changer membership.

## Drift Gate

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_game_changers_to_dart.py --check
cd server && dart test test/edh_bracket_policy_test.dart test/optimize_runtime_support_test.dart
```

The sync gate fails when the JSON source is not official-source attributed,
does not contain exactly 53 unique names, or differs from the generated Dart
set. Update the reviewed JSON first, then regenerate Dart without `--check`.

Historical May/June research reports remain evidence of prior classifier gaps,
not instructions for the current runtime.
