# BV-072 - Global Learning Eligibility Recheck

Data local: `2026-06-19T21:10:55-03:00`

## Fonte

- Latest audit: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_000720/summary.json`
- Summary Markdown: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_000720/summary.md`
- Test results: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_000720/test_results.jsonl`

## Resultado

- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `strategy_learning_confidence_counts={"high_confidence_replay": 12, "low_confidence_replay": 4}`
- `global_learning_eligibility_policy=requires_high_confidence_strategy_seed_and_all_mandatory_gates_pass`
- `global_learning_eligible_seeds=["63210007","63210009","63210010","63210011","63210012","63210013","63210014","63210015","63210016","63210018","63210019","63210022"]`
- `global_not_learning_eligible_seeds=["63210008","63210017","63210020","63210021"]`
- `global_learning_eligibility_reasons` publica todas as 16 seeds; as 4 seeds low-confidence tem `["strategy_audit:low_confidence_replay"]` e as 12 seeds elegiveis tem lista vazia.
- `test_results_total=16`
- `test_results_status_counts={"pass": 16}`
- `test_result_failures=[]`

## Validacoes

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_strategy_auditor.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py` - PASS, incluindo:
  - `test_global_learning_eligibility_blocks_high_strategy_seed_when_other_gates_review_required`
  - `test_global_learning_eligibility_allows_clean_high_seed_and_excludes_low_confidence_seed`
- `bash -n /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh` - PASS.
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh` - PASS, gerando `20260620_000720`.
- `test_battle_decision_strategy_auditor` no `test_results.jsonl` oficial - PASS, `exit_code=0`, `log_lines=17`.

## Conclusao

`BV-072` esta fechado: o resultado principal agora separa `strategy_*` de elegibilidade global, publica `global_learning_eligible_seeds`, `global_not_learning_eligible_seeds` e reasons por seed, e a regra global depende do status final agregado apos todos os mandatory gates.
