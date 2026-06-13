# Hermes Replay Decision Audit

- deck_id: 6
- baseline_id: 4
- status: turn_by_turn_clean
- structured_events: 2695
- turn_findings: 1
- critical: 0
- high: 0
- medium: 0
- low: 1

## Replay Files

- text: `/opt/data/workspace/mtgia/docs/hermes-analysis/master_optimizer_reports/replays/battle_replay_seed_42.txt`
- events: `/opt/data/workspace/mtgia/docs/hermes-analysis/master_optimizer_reports/replays/battle_replay_seed_42.jsonl`
- text: `/opt/data/workspace/mtgia/docs/hermes-analysis/master_optimizer_reports/replays/battle_replay_seed_43.txt`
- events: `/opt/data/workspace/mtgia/docs/hermes-analysis/master_optimizer_reports/replays/battle_replay_seed_43.jsonl`
- text: `/opt/data/workspace/mtgia/docs/hermes-analysis/master_optimizer_reports/replays/battle_replay_seed_44.txt`
- events: `/opt/data/workspace/mtgia/docs/hermes-analysis/master_optimizer_reports/replays/battle_replay_seed_44.jsonl`

## Turn-By-Turn Findings

| Severity | Replay | Turn | Player | Event | Finding |
| --- | --- | ---: | --- | --- | --- |
| low | seed_44 | 8 | Lorehold | removal_resolved | Removal hit a low-power target while multiple targets were available. |

## Aggregate Baseline Findings

| Severity | Opponent | Finding |
| --- | --- | --- |
| medium | Kraum, Ludevic's Opus #98 (real) | Slow average turn 16.2; inspect sequencing and finisher timing. |
| medium | Winota, Joiner of Forces #73 (real) | Slow average turn 16.7; inspect sequencing and finisher timing. |
| high | Rograkh, Son of Rohgahh #95 (real) | Low matchup WR 25.0%; needs replay review before optimizer trusts cuts. |
| medium | Y'shtola, Night's Blessed #70 (real) | Slow average turn 16.0; inspect sequencing and finisher timing. |
| medium | Marneus Calgar #64 (real) | Slow average turn 16.0; inspect sequencing and finisher timing. |
| medium | Kinnan, Bonder Prodigy #27 (real) | Slow average turn 15.8; inspect sequencing and finisher timing. |
| medium | Thrasios, Triton Hero #101 (real) | Slow average turn 17.5; inspect sequencing and finisher timing. |

## Gate Interpretation

- `critical` or `high` turn findings block optimizer trust until battle logic is fixed.
- `medium` findings require review before product-facing deck mutation.
- `low` findings are polish/heuristic notes and do not block a Hermes-local experiment.
