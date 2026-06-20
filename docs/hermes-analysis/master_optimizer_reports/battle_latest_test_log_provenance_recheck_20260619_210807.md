# Battle latest test log provenance recheck 2026-06-19T21:08:07Z

## Escopo

- Validacao somente leitura do latest recorrente:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest`.
- Sem alteracao de PostgreSQL.
- Sem swaps.
- Sem commit ou staging.
- Objetivo: revalidar se o resultado principal prova diretamente quais testes
  rodaram antes dos replays.

## Resultado do latest

- Latest real: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_204826`.
- `timestamp_utc=2026-06-19T20:48:26Z`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `mandatory_gate_divergences=[]`.
- `seeds_with_high_or_critical_action_findings=[]`.
- `seeds_with_strategy_blockers=[]`.
- `seeds_with_high_or_critical_forensic_findings=[]`.

## Evidencia no summary principal

Consulta ao `summary.json`:

- `test_results=null`.
- `test_logs=null`.
- `py_compile=null`.
- `tests=null`.

Isto significa que o resultado principal nao publica matriz de testes, comandos,
exit codes, paths de logs, bytes por stdout/stderr ou duracao.

## Logs encontrados no run real

No diretorio real do run existem `15` arquivos `test_*.log`.

Tamanhos em bytes:

- `0` - `test_battle_effect_coverage_known_cards.log`.
- `15` - `test_battle_decision_trace_taxonomy_audit.log`.
- `15` - `test_battle_effect_coverage_residual_audit.log`.
- `15` - `test_battle_event_contract_static_audit.log`.
- `15` - `test_battle_focused_template_dispatch_audit.log`.
- `53` - `test_battle_runtime_surface_manifest.log`.
- `58` - `test_battle_rule_registry_runtime_safe.log`.
- `112` - `test_battle_decision_research_review.log`.
- `123` - `test_replay_decision_auditor_scope.log`.
- `180` - `test_battle_unknown_template_backlog_audit.log`.
- `370` - `test_battle_replay_v10_3_renderer.log`.
- `609` - `test_battle_forensic_audit_supported_effects.log`.
- `660` - `test_battle_action_critic.log`.
- `983` - `test_battle_decision_strategy_auditor.log`.
- `14929` - `test_battle_analyst_v10_3.log`.

Linhas:

- `0` linhas em `test_battle_effect_coverage_known_cards.log`.
- `1` linha em sete logs curtos.
- `2` linhas em dois logs.
- `3` linhas em `test_battle_unknown_template_backlog_audit.log`.
- `6` linhas em `test_battle_replay_v10_3_renderer.log`.
- `9` linhas em `test_battle_forensic_audit_supported_effects.log`.
- `11` linhas em `test_battle_action_critic.log`.
- `15` linhas em `test_battle_decision_strategy_auditor.log`.
- `240` linhas em `test_battle_analyst_v10_3.log`.

## Wrapper observado

`/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
executa:

- `python3 -m py_compile` para scripts e testes battle antes das seeds.
- `15` comandos `python3 "$SCRIPTS_DIR/test_*.py" > "$run_dir/test_*.log"`.

Como o script usa `set -e`, a existencia do `summary.json` depois dessas linhas
indica que comandos anteriores nao retornaram erro. Porem isto e evidencia
indireta; o `summary.json` nao preserva o exit code individual, nem registra
stderr, nem associa cada teste ao log.

Um detalhe importante: cada teste redireciona somente stdout para o arquivo do
run. Se um teste usa stderr para a saida padrao do runner, ou se um teste passa
sem stdout, o `test_*.log` pode ficar vazio mesmo com exit code `0`. No latest,
`test_battle_effect_coverage_known_cards.log` tem `0` bytes.

## Leitura

`BV-073` permanece aberto.

O latest prova indiretamente que os testes anteriores nao abortaram o wrapper,
mas ainda nao prova diretamente, pelo resultado principal, quais testes rodaram,
quais comandos foram usados, quais exit codes sairam, quanto de stdout/stderr foi
capturado e onde cada log ficou.

Isso importa porque o objetivo de validacao battle exige saber exatamente qual
superficie foi testada antes de declarar um run confiavel.

## Validacoes executadas

- `jq` no latest `summary.json` - PASS.
- `find`/`stat`/`wc` nos logs do run real `20260619_204826` - PASS.
- Leitura somente de trechos do wrapper `manaloom-battle-strategy-audit.sh` -
  PASS.

