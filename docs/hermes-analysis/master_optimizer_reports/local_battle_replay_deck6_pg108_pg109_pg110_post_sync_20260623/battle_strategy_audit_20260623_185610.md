# Battle Decision Strategy Auditor

This report flags strategically weak or insufficiently explained decisions. It is not a judge-engine legality report.

## Summary

- Verdict: `low_confidence_replay`
- Learning confidence: `low_confidence_replay`
- High-confidence learning eligible: `False`
- High-confidence learning weight: `0.0`
- Learning confidence reason: `forced_keep_after_bad_mulligan`
- Decisions: `138`
- Events: `879`
- Findings: `1`
- Highest severity: `medium`
- Severity counts: `{"medium": 1}`
- Decision types: `{"cast_spell": 36, "combat_attack": 14, "lorehold_upkeep_rummage": 2, "mulligan_decision": 10, "pass_no_action": 65, "response": 1, "tutor": 3, "utility_artifact_activation": 6, "utility_land_activation": 1}`

## Findings

| Severity | Code | Decision/Event | Detail | Recommendation |
|---|---|---|---|---|
| medium | forced_keep_after_bad_mulligan | decision-000010 | Mulligan cap forced a risky keep: mana_screw, negative_keep_score, too_few_lands. | Track this replay separately; do not treat resulting WR as high-confidence deck quality. |
