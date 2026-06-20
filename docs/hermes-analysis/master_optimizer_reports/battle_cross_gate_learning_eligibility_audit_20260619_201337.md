# Battle Cross-Gate Learning Eligibility Audit - 2026-06-19 20:13Z

## Escopo

Auditoria documental sobre a relacao entre:

- seeds bloqueadas por `action_critic`;
- `strategy_high_confidence_learning_seeds`;
- `strategy_low_confidence_seeds`;
- elegibilidade real de aprendizado quando o status final do replay esta
  `blocked`.

Nao houve alteracao de PostgreSQL, swaps, runtime battle, wrapper ou regras de
carta.

## Fontes

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/strategy_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md`

Latest real usado:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_200324`
- `timestamp_utc=2026-06-19T20:03:24Z`
- `battle_replay_final_status=blocked`
- `mandatory_gate_divergences=["action_critic=blocked","forensic_audit=review_required"]`

## Resultado

O latest atual tem action blocker:

```json
{
  "seeds_with_high_or_critical_action_findings": [
    "63202004",
    "63202005",
    "63202006",
    "63202007",
    "63202008",
    "63202010",
    "63202018"
  ]
}
```

Mas o mesmo summary publica:

```json
{
  "strategy_learning_confidence_counts": {
    "high_confidence_replay": 12,
    "low_confidence_replay": 4
  },
  "strategy_not_learning_eligible_seeds": []
}
```

Intersecoes:

| Categoria | Seeds | Count |
| --- | --- | ---: |
| Action-blocked and strategy high-confidence | `63202005`, `63202007`, `63202008`, `63202010` | 4 |
| Action-blocked and strategy low-confidence | `63202004`, `63202006`, `63202018` | 3 |
| Action-blocked and not-learning-eligible | none | 0 |
| Action-blocked still present in strategy learning lists | `63202004`, `63202005`, `63202006`, `63202007`, `63202008`, `63202010`, `63202018` | 7 |

Per-seed strategy audit summaries:

| Seed | Strategy verdict | Learning confidence | Reason | Strategy findings |
| --- | --- | --- | --- | ---: |
| `63202004` | `low_confidence_replay` | `low_confidence_replay` | `forced_keep_after_bad_mulligan` | 1 |
| `63202005` | `usable_for_strategy_learning` | `high_confidence_replay` | `no_strategy_findings` | 0 |
| `63202006` | `low_confidence_replay` | `low_confidence_replay` | `forced_keep_after_bad_mulligan` | 1 |
| `63202007` | `usable_for_strategy_learning` | `high_confidence_replay` | `no_strategy_findings` | 0 |
| `63202008` | `usable_for_strategy_learning` | `high_confidence_replay` | `no_strategy_findings` | 0 |
| `63202010` | `usable_for_strategy_learning` | `high_confidence_replay` | `no_strategy_findings` | 0 |
| `63202018` | `low_confidence_replay` | `low_confidence_replay` | `forced_keep_after_bad_mulligan` | 1 |

## Causa provavel

The wrapper aggregates `strategy_learning_confidence_*` directly from each
`strategy_audit.json` before or independently of the final mandatory-gate
eligibility.

The strategy auditor can correctly say a decision trace has no strategy
findings, while the same seed is invalid for learning because another mandatory
gate blocks it.

## Risco

A downstream consumer can read `strategy_high_confidence_learning_seeds` and
learn from seeds that are action-blocked by missing target metadata.

That creates a semantic mismatch:

- `high_confidence_replay` currently means "high confidence by strategy audit";
- it does not mean "globally safe for learning across all mandatory gates".

This is especially risky because `strategy_not_learning_eligible_seeds=[]` in a
blocked run can look like all seeds are eligible except the low-confidence
subset.

## Ajustes recomendados

1. Add global learning eligibility fields derived after all mandatory gates,
   for example:
   - `global_learning_eligible_seeds`
   - `global_not_learning_eligible_seeds`
   - `global_learning_ineligible_reasons_by_seed`
2. When `battle_replay_final_status != trusted_for_strategy_learning`, mark all
   seeds as globally not learning eligible unless an explicit per-seed gate
   waiver exists.
3. Exclude action-blocked seeds from any field named `*_learning_seeds`, or
   rename current fields to `strategy_audit_high_confidence_seeds`.
4. Add a wrapper regression where a strategy-clean seed also has a high action
   finding; assert it is not published as globally learning eligible.
5. Require reports/consumers to cite `battle_replay_final_status`,
   `mandatory_gate_divergences`, and action/forensic blockers next to any
   strategy confidence counts.

## Criterio de fechamento

- In blocked or review-required runs, no seed is presented as globally
  learning eligible without explicit waiver.
- Action-blocked seeds are excluded from global learning lists or clearly
  labeled as strategy-audit-only confidence.
- `strategy_not_learning_eligible_seeds` is not the only ineligibility field
  when non-strategy gates fail.
- Tests cover cross-gate learning eligibility.

## Validacoes executadas

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py` - PASS
- `git diff --check -- docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md docs/hermes-analysis/master_optimizer_reports/battle_cross_gate_learning_eligibility_audit_20260619_201337.md` - PASS
- ASCII check do novo relatorio - PASS
