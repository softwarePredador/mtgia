# Battle Runtime Surface Manifest Test Contract Audit - 2026-06-19 20:06Z

## Escopo

Auditoria documental sobre o contrato de teste do
`battle_runtime_surface_manifest.py`, que e usado para manter consciencia sobre
a superficie Python relacionada ao battle.

Nao houve alteracao de PostgreSQL, swaps, runtime battle, testes ou regras de
carta.

## Fontes

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/runtime_surface_manifest.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/runtime_surface_manifest.md`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_runtime_surface_manifest.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py`

Latest real usado:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_193733`
- `timestamp_utc=2026-06-19T19:37:33Z`
- `battle_replay_final_status=review_required`
- `mandatory_gate_divergences=["forensic_audit=review_required"]`

## Resultado

O manifest atual classifica:

| Campo | Valor |
| --- | ---: |
| `total_files` | 108 |
| `unclassified_files` | 0 |
| `covered_by_recurring_run` | 29 |
| `imported_by_core_runtime` | 6 |
| `outside_recurring_run` | 73 |

Contagens por `gate_expected`:

| Gate expected | Files |
| --- | ---: |
| `core_runtime_import_regression` | 6 |
| `recurring_audit_required` | 29 |
| `targeted_manual_gate_required_before_change` | 31 |
| `targeted_test_required_before_change` | 42 |

O teste atual passa:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py` - PASS

Mas o contrato principal do teste usa um limite historico amplo:

```python
assert summary["total_files"] >= 98
```

O latest atual ja tem `108` arquivos. Portanto, uma queda de ate `10` arquivos
do inventario ainda poderia passar por esse assert, desde que as categorias
minimas continuassem presentes e nao houvesse arquivo unclassified.

## Risco

O runtime surface manifest e o mapa usado para argumentar "o que o battle
cobre" e "o que esta fora do recorrente". Um teste com denominador antigo
protege contra colapso grosseiro, mas nao protege bem contra drift de inventario.

Exemplos de drift que poderiam ficar fracos:

- perda de alguns arquivos battle-related enquanto `total_files >= 98` continua
  verdadeiro;
- mudanca silenciosa nas contagens por categoria/gate;
- perda de um arquivo high-signal fora do recorrente sem fixture nominal;
- leitura futura de que o manifest esta completamente protegido porque o teste
  passou.

## Leitura operacional

O manifest atual em si esta util e sem unclassified files. A falha esta no
contrato do teste que deveria proteger o denominador atual da superficie.

Para afirmar 100% de consciencia de battle, o teste deve fixar pelo menos:

- total atual esperado ou snapshot controlado;
- contagens por categoria;
- contagens por `automation_coverage`;
- contagens por `gate_expected`;
- presenca nominal de arquivos high-signal.

## Ajustes recomendados

1. Atualizar `test_battle_runtime_surface_manifest.py` para validar o
   denominador atual (`108`) ou um snapshot versionado da superficie.
2. Validar exatamente as contagens atuais por categoria e gate esperado.
3. Validar presenca nominal de arquivos criticos, por exemplo:
   `battle_replacement_support.py`, `battle_sba_support.py`,
   `battle_stack_casting_tests.py`, `battle_targeting_tests.py`,
   `manaloom_battle_rule_focused_evidence.py`,
   `manaloom_battle_rule_review_queue.py`, `learned_deck_coherence_audit.py` e
   `sync_battle_card_rules_pg.py`.
4. Se o total puder variar legitimamente, exigir manifest snapshot regenerado e
   changelog de superficie em vez de limite `>=`.
5. Quando um arquivo sair do manifest, exigir razao documentada
   (`historical/deprecated`, rename, removed, moved) antes de aceitar o teste.

## Criterio de fechamento

- O teste falha se o manifest perder arquivos atuais sem snapshot/waiver.
- O teste valida contagens por categoria, automation coverage e gate esperado.
- O teste valida arquivos high-signal nominalmente.
- O register deixa de depender de um limite historico `>=98` para sustentar
  consciencia da superficie battle.

## Validacoes executadas

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py` - PASS
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_runtime_surface_manifest.py --repo-root /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia --output /tmp/battle_runtime_surface_manifest_current.md --json-output /tmp/battle_runtime_surface_manifest_current.json --fail-on-unclassified` - PASS
- `git diff --check -- docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md docs/hermes-analysis/master_optimizer_reports/battle_runtime_surface_manifest_test_contract_audit_20260619_200606.md` - PASS
- ASCII check do novo relatorio - PASS
