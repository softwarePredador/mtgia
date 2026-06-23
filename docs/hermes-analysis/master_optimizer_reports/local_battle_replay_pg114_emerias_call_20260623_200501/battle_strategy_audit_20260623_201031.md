# Battle Decision Strategy Auditor

This report flags strategically weak or insufficiently explained decisions. It is not a judge-engine legality report.

## Summary

- Verdict: `low_confidence_replay`
- Learning confidence: `low_confidence_replay`
- High-confidence learning eligible: `False`
- High-confidence learning weight: `0.0`
- Learning confidence reason: `forced_keep_after_bad_mulligan`
- Decisions: `159`
- Events: `971`
- Findings: `1`
- Highest severity: `medium`
- Severity counts: `{"medium": 1}`
- Decision types: `{"cast_spell": 39, "combat_attack": 20, "lorehold_upkeep_rummage": 3, "mulligan_decision": 10, "pass_no_action": 73, "response": 3, "tutor": 2, "utility_artifact_activation": 8, "utility_land_activation": 1}`

## Findings

| Severity | Code | Decision/Event | Detail | Recommendation |
|---|---|---|---|---|
| medium | forced_keep_after_bad_mulligan | decision-000010 | Mulligan cap forced a risky keep: mana_screw, negative_keep_score, too_few_lands. | Track this replay separately; do not treat resulting WR as high-confidence deck quality. |
