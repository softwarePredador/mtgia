# Hermes Replay Decision Audit

- deck_id: 6
- baseline_id: 1
- status: turn_by_turn_clean
- structured_events: 816
- turn_findings: 0
- critical: 0
- high: 0
- medium: 0
- low: 0

## Replay Files

- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\replays\battle_replay_seed_1100.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\replays\battle_replay_seed_1100.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\replays\battle_replay_seed_1101.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\replays\battle_replay_seed_1101.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\replays\battle_replay_seed_1102.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\replays\battle_replay_seed_1102.jsonl`

## Turn-By-Turn Findings

| Severity | Replay | Turn | Player | Event | Finding |
| --- | --- | ---: | --- | --- | --- |
| info | all | - | all | all | No turn-by-turn red flags found. |

## Aggregate Baseline Findings

| Severity | Opponent | Finding |
| --- | --- | --- |
| high | Thrasios, Triton Hero #101 (real) | Low matchup WR 0.0%; needs replay review before optimizer trusts cuts. |
| medium | Thrasios, Triton Hero #101 (real) | Missing win/loss reason detail in aggregate output. |
| high | Zirda, the Dawnwaker #69 (real) | Low matchup WR 0.0%; needs replay review before optimizer trusts cuts. |
| medium | Zirda, the Dawnwaker #69 (real) | Missing win/loss reason detail in aggregate output. |
| high | Kraum, Ludevic's Opus #86 (real) | Low matchup WR 0.0%; needs replay review before optimizer trusts cuts. |
| medium | Kraum, Ludevic's Opus #86 (real) | Missing win/loss reason detail in aggregate output. |
| high | Thrasios, Triton Hero #59 (real) | Low matchup WR 0.0%; needs replay review before optimizer trusts cuts. |
| medium | Thrasios, Triton Hero #59 (real) | Missing win/loss reason detail in aggregate output. |
| high | Rograkh, Son of Rohgahh #119 (real) | Low matchup WR 0.0%; needs replay review before optimizer trusts cuts. |
| medium | Rograkh, Son of Rohgahh #119 (real) | Missing win/loss reason detail in aggregate output. |
| high | Grist, the Hunger Tide #66 (real) | Low matchup WR 0.0%; needs replay review before optimizer trusts cuts. |
| medium | Grist, the Hunger Tide #66 (real) | Missing win/loss reason detail in aggregate output. |
| high | Magda, Brazen Outlaw #90 (real) | Low matchup WR 0.0%; needs replay review before optimizer trusts cuts. |
| medium | Magda, Brazen Outlaw #90 (real) | Missing win/loss reason detail in aggregate output. |
| high | Marneus Calgar #64 (real) | Low matchup WR 0.0%; needs replay review before optimizer trusts cuts. |
| medium | Marneus Calgar #64 (real) | Missing win/loss reason detail in aggregate output. |
| high | Tannuk, Memorial Ensign #40 (real) | Low matchup WR 0.0%; needs replay review before optimizer trusts cuts. |
| medium | Tannuk, Memorial Ensign #40 (real) | Missing win/loss reason detail in aggregate output. |

## Gate Interpretation

- `critical` or `high` turn findings block optimizer trust until battle logic is fixed.
- `medium` findings require review before product-facing deck mutation.
- `low` findings are polish/heuristic notes and do not block a Hermes-local experiment.
