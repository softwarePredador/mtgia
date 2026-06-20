# BV-075 - Learned Deck Opponent Provenance Closure With Stable Source URL

Data local: `2026-06-19T21:31:59-03:00`

## Fonte

- Latest audit: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_002832/summary.json`
- Summary Markdown: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_002832/summary.md`
- Test results: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_002832/test_results.jsonl`
- SQLite lookup read-only: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`

## Resultado

- `battle_replay_final_status=blocked`
- `mandatory_gate_divergences=["forensic_audit=blocked"]`
- `learned_deck_source_lookup_status=loaded`
- `learned_deck_source_lookup_rows=120`
- `learned_opponent_source_counts={"pg_meta_decks": 48}`
- `opponent_deck_provenance.status=learned_opponent_provenance_present_with_shape_waiver`
- `opponent_deck_provenance.learned_opponent_appearance_count=48`
- `opponent_deck_provenance.learned_opponent_unique_count=12`
- `opponent_deck_provenance.source_url_missing_count=0`
- `opponent_deck_provenance.construction_report_missing_count=48`
- `opponent_deck_provenance.deck_coherence_report_missing_count=48`
- `opponent_deck_provenance.waiver_reason=learned_deck_construction_and_coherence_reports_not_emitted_by_battle_replay_deck_provenance`
- `learned_deck_opponents` publica `12` itens unicos com `source_system`, `source_ref`, `source_url`, `source_row_id`, `name`, `commander`, `deck_name`, `appearances`, `seeds`, `source_card_count`, `battle_card_count`, `metrics_basis`, `cached_metadata_used_for_metrics`, `blocker_domain`, `construction_status`, `deck_coherence_status`, `source_url_status` e `provenance_status`.
- `test_results_total=16`
- `test_results_status_counts={"pass": 16}`
- `test_result_failures=[]`

## Interpretacao

O run atual nao e evidence trusted para aprendizado de estrategia porque o aggregate esta `blocked` por `forensic_audit`. Isso permanece separado do source-deck gate: o resultado principal agora lista os oponentes learned usados no run, inclui a chave estavel `source_url=pg:meta_decks:<uuid>` resolvida do SQLite Hermes local em modo read-only, e declara waiver explicito para reports de construction/coherence nao emitidos pelo `deck_provenance.json` do replay.

## Tratativa

- `battle_decision_strategy_auditor.py` passou a expor `summarize_learned_opponent_provenance(...)` com suporte a `source_url`, `commander`, `deck_name` e `source_url_status`.
- O wrapper `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh` le `knowledge.db` localmente em modo read-only, resolve `learned_deck:<id>` contra `learned_decks.source_url` e publica:
  - `learned_deck_source_lookup_status`
  - `learned_deck_source_lookup_rows`
  - `learned_deck_opponents`
  - `opponent_deck_provenance`
  - `learned_opponent_source_counts`
- `summary.md` tambem mostra lookup, source counts, provenance e lista de opponents.

## Validacoes

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_strategy_auditor.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py` - PASS, incluindo:
  - `test_summarize_learned_opponent_provenance_groups_sources_and_seeds`
  - `test_summarize_learned_opponent_provenance_marks_present_reports`
- `bash -n /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh` - PASS.
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh` - PASS, gerando `20260620_002832`.
- `test_battle_decision_strategy_auditor` no `test_results.jsonl` oficial - PASS, `exit_code=0`, `log_lines=19`.
- Assert read-only contra `latest/summary.json` - PASS: `len(learned_deck_opponents)=12`, `learned_opponent_source_counts={"pg_meta_decks":48}`, appearance count `48`, unique count `12`, `source_url_missing_count=0`, e todos os itens possuem os campos minimos exigidos.

## Conclusao

`BV-075` esta fechado como gap de provenance: o summary principal agora diferencia explicitamente engine gate (`battle_replay_final_status`) de source-deck provenance e publica todos os learned opponents usados no run com chave estavel `source_url`/PG meta id, source ref local, nome e status/waiver minimo.
