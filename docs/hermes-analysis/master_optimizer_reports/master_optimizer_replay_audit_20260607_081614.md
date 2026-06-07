# Hermes Replay Decision Audit

- deck_id: 6
- baseline_id: 3
- status: turn_by_turn_clean
- structured_events: 895
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
| medium | Kinnan, Bonder Prodigy (real) | Slow average turn 15.7; inspect sequencing and finisher timing. |
| medium | Winota, Joiner of Forces (real) | Slow average turn 15.6; inspect sequencing and finisher timing. |
| medium | Tayam, Luminous Enigma (real) | Slow average turn 17.0; inspect sequencing and finisher timing. |
| high | Winota, Joiner of Forces (real) | Low matchup WR 10.0%; needs replay review before optimizer trusts cuts. |
| medium | Winota, Joiner of Forces (real) | Slow average turn 21.0; inspect sequencing and finisher timing. |
| medium | Veyran, Voice of Duality (real) | Slow average turn 16.0; inspect sequencing and finisher timing. |
| medium | Niv-Mizzet, Parun (real) | Slow average turn 15.8; inspect sequencing and finisher timing. |
| high | Tivit, Seller of Secrets (real) | Low matchup WR 30.0%; needs replay review before optimizer trusts cuts. |
| medium | Grand Arbiter Augustin IV (real) | Slow average turn 19.5; inspect sequencing and finisher timing. |
| medium | Urza, Lord High Artificer (real) | Slow average turn 15.3; inspect sequencing and finisher timing. |

## Gate Interpretation

- `critical` or `high` turn findings block optimizer trust until battle logic is fixed.
- `medium` findings require review before product-facing deck mutation.
- `low` findings are polish/heuristic notes and do not block a Hermes-local experiment.
