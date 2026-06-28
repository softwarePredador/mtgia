# XMage Batch Validity Audit

Generated at: `2026-06-28T06:54:24+00:00`

Read-only artifact. `mutations_performed=[]`.

- Summary: `{"audited_card_count": 1, "exact_xmage_found_count": 1, "focused_test_scenario_ready_count": 1, "missing_xmage_class_count": 0, "ready_for_structured_pull_count": 1, "severity_counts": {"high": 1}, "status_counts": {"ready_for_structured_xmage_pull_review_required": 1}, "valid_xmage_source_count": 1}`

| Card | Severity | Status | XMage class | Mana | Types | Primary effect | Test scenarios |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `Hidden Retreat` | `high` | `ready_for_structured_xmage_pull_review_required` | `HiddenRetreat` | `{2}{W} / expected {2}{W} / match True` | `ENCHANTMENT / expected ENCHANTMENT / match True` | `damage_prevention_shield` | `1` |

## Decisions

### Hidden Retreat

- Status: `ready_for_structured_xmage_pull_review_required`
- Valid XMage source: `True`
- Ready for structured pull: `True`
- Reason: Exact XMage class, compatible metadata, a specific structured effect candidate, and focused test scenarios were found; still requires implemented ManaLoom tests/review before PG promotion.
- Coherence findings: `["no_trusted_executable_rule", "review_only_or_needs_review_rule", "local_generated_rule_effect_mismatch_indestructible"]`
- Focused test scenarios: `1`
