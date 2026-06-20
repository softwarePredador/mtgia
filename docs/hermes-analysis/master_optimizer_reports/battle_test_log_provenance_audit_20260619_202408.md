# Battle Test Log Provenance Audit - 2026-06-19 20:24Z

## Escopo

Auditoria documental da rastreabilidade dos testes executados pela automacao
local `manaloom-battle-strategy-audit.sh`. Nao houve alteracao de PostgreSQL,
swaps, runtime battle, wrapper, testes ou commit.

## Fontes

- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_200324/test_*.log`
- `/Users/desenvolvimentomobile/.manaloom-agents/logs/battle-strategy-audit.log`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_known_cards.py`

## Latest usado

- Latest completo no momento da rechecagem:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_202217`
- `timestamp_utc=2026-06-19T20:22:17Z`
- `battle_replay_final_status=blocked`
- `mandatory_gate_divergences=["forensic_audit=blocked"]`

Observacao: a lacuna foi observada primeiro no run `20260619_200324` e
reproduzida nos runs completos `20260619_202217` e `20260619_202628`.

## Resultado

O wrapper executa os testes antes de gerar os replays e antes de montar
`summary.json`:

- `test_battle_analyst_v10_3.py`
- `test_battle_action_critic.py`
- `test_battle_decision_strategy_auditor.py`
- `test_battle_decision_trace_taxonomy_audit.py`
- `test_battle_decision_research_review.py`
- `test_battle_event_contract_static_audit.py`
- `test_battle_replay_v10_3_renderer.py`
- `test_battle_effect_coverage_known_cards.py`
- `test_battle_effect_coverage_residual_audit.py`
- `test_battle_focused_template_dispatch_audit.py`
- `test_battle_rule_registry_runtime_safe.py`
- `test_battle_forensic_audit_supported_effects.py`
- `test_replay_decision_auditor_scope.py`
- `test_battle_runtime_surface_manifest.py`
- `test_battle_unknown_template_backlog_audit.py`

Todos os 15 arquivos `test_*.log` esperados existem no run completo
`20260619_202217` e no latest `20260619_202628`, mas um deles esta vazio:

| Log | Bytes | Linhas | Ultima linha |
| --- | ---: | ---: | --- |
| `test_battle_effect_coverage_known_cards.log` | 0 | 0 | `<EMPTY>` |

Os demais logs trazem `PASS ...` ou `N tests passed`.

## Causa observada

O wrapper redireciona apenas stdout para cada arquivo `test_*.log`:

```bash
python3 "$SCRIPTS_DIR/test_battle_effect_coverage_known_cards.py" > "$run_dir/test_battle_effect_coverage_known_cards.log"
```

O teste `test_battle_effect_coverage_known_cards.py` usa `unittest.main()`. O
runner padrao de `unittest` escreve o resumo em stderr. Reexecucao isolada
confirmou:

```text
exit=0
stdout_bytes=0
stderr_bytes=103
```

O stderr aparece no log global da automacao:

```text
Ran 5 tests in 0.001s
OK
```

mas nao no artefato de run
`test_battle_effect_coverage_known_cards.log`.

## Lacuna no summary

`summary.json`, que e o resultado principal da automacao, nao publica:

- lista de testes executados;
- status/exit code por teste;
- caminho dos `test_*.log`;
- hash ou mtime dos scripts de teste;
- distincao entre teste com log vazio por stdout/stderr e teste nao executado.

Como o wrapper usa `set -e`, a existencia de `summary.json` implica que esses
testes anteriores nao falharam no shell. Mesmo assim, o artefato principal nao
permite auditar diretamente a matriz de testes sem abrir o wrapper, o log global
e cada arquivo `test_*.log`.

## Risco

Um consumidor que olhe somente o `summary.json`, como definido para a automacao
local, pode dizer que o run esta "testado" sem conseguir provar quais testes
foram executados e onde esta a evidencia. Um consumidor que olhe somente os
artefatos de run tambem pode interpretar o log vazio de
`test_battle_effect_coverage_known_cards.log` como teste sem saida ou teste nao
executado, quando o resultado real ficou no log global.

Isso nao muda o blocker atual do battle, mas enfraquece a rastreabilidade de
"validado e testado" para futuros handoffs.

## Ajustes recomendados

1. Redirecionar stdout e stderr de cada teste para o respectivo artefato de run,
   ou padronizar os testes para emitirem no stdout.
2. Publicar em `summary.json` uma matriz `test_results` com:
   - nome do teste;
   - comando;
   - exit code;
   - status;
   - log path;
   - stdout/stderr bytes;
   - duracao aproximada.
3. Incluir o passo `py_compile` na matriz de testes/verificacoes.
4. Considerar falhar ou marcar `review_required` quando um `test_*.log` esperado
   estiver vazio sem `exit_code=0` registrado no summary.

## Criterio de fechamento

- `summary.json` lista todos os testes/verificacoes executados, com status e log
  path.
- Todo `test_*.log` esperado contem a saida relevante ou o summary registra que a
  saida foi capturada em outro canal.
- Nao e mais necessario abrir o log global para provar o resultado de um teste do
  run.

## Validacoes executadas

- Inventario dos `test_*.log` dos runs `20260619_200324`, `20260619_202217` e
  `20260619_202628`.
- Parse de `summary.json` para confirmar ausencia de campos `test_results`,
  `test_logs`, `test_exit_codes` ou equivalente.
- Inspecao estatica do wrapper `manaloom-battle-strategy-audit.sh`.
- Reexecucao isolada de `test_battle_effect_coverage_known_cards.py` redirecionando
  stdout/stderr para arquivos temporarios, confirmando stdout vazio e stderr com
  o resumo do `unittest`.
