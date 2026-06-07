# Hermes Replay Decision Audit

- deck_id: 6
- baseline_id: 4
- status: turn_by_turn_clean
- structured_events: 1303
- turn_findings: 0
- critical: 0
- high: 0
- medium: 0
- low: 0

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
| info | all | - | all | all | No turn-by-turn red flags found. |

## Aggregate Baseline Findings

| Severity | Opponent | Finding |
| --- | --- | --- |
| medium | Aggro (Krenko) | 6 stalls; inspect missed wincon or game-end conditions. |
| medium | Aggro (Krenko) | Slow average turn 19.3; inspect sequencing and finisher timing. |
| medium | Control (Atraxa) | 4 stalls; inspect missed wincon or game-end conditions. |
| medium | Control (Atraxa) | Slow average turn 16.0; inspect sequencing and finisher timing. |
| medium | Combo (Kinnan) | 6 stalls; inspect missed wincon or game-end conditions. |
| medium | Combo (Kinnan) | Slow average turn 17.4; inspect sequencing and finisher timing. |
| medium | Midrange (Korvold) | 3 stalls; inspect missed wincon or game-end conditions. |
| medium | Midrange (Korvold) | Slow average turn 18.9; inspect sequencing and finisher timing. |
| medium | Spellslinger (Niv) | 3 stalls; inspect missed wincon or game-end conditions. |
| medium | Spellslinger (Niv) | Slow average turn 16.4; inspect sequencing and finisher timing. |
| medium | Stax (Winota) | 4 stalls; inspect missed wincon or game-end conditions. |
| medium | Stax (Winota) | Slow average turn 20.6; inspect sequencing and finisher timing. |

## Gate Interpretation

- `critical` or `high` turn findings block optimizer trust until battle logic is fixed.
- `medium` findings require review before product-facing deck mutation.
- `low` findings are polish/heuristic notes and do not block a Hermes-local experiment.
