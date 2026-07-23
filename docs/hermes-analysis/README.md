# Hermes Analysis Docs — leitura canonica

> Status atual: canonico.
> Este índice contém somente normas e rotas vigentes. Diários detalhados de
> pacotes e decisões ficam no arquivo histórico de S9-03.

Updated: 2026-07-23

## Fonte de verdade e ordem de leitura

1. PostgreSQL/backend é a verdade de produto.
2. Hermes/SQLite é cache, laboratório e evidência de runtime.
3. XMage pinado é o executor primário de regras; Forge pinado cobre somente
   gaps estruturados; adapters nativos são o residual explícito.
4. Contratos atuais vencem relatórios datados.
5. Relatórios e arquivos históricos nunca promovem regra, deck ou dado.

Antes de executar trabalho Hermes/XMage/Commander, consulte:

- `MANALOOM_OPERATIONAL_LOOKUP_GUIDE_2026-06-30.md`
  (`current_lookup_index`);
- `MANALOOM_FAILURE_MODE_VALIDATION_MATRIX_2026-06-30.md`
  (`current_failure_mode_gate`);
- `DATA_FIELD_ALIAS_CONTRACT_2026-06-30.md`;
- `APP_AI_KNOWLEDGE_BRIDGE_CONTRACT_2026-07-06.md`;
- `NEW_SERVER_POSTGRES_WORKFLOW_2026-07-06.md`.

## Contratos de Battle e XMage

- `GLOBAL_BATTLE_RULES_AND_LEARNING_CLOSURE_2026-07-15.md`
  - runbook operacional único;
  - entrada: `scripts/manaloom_global_battle_closure.sh`;
  - cobertura e batalhas externas não promovem PostgreSQL ou deck.
- `EXTERNAL_BATTLE_EXECUTION_CONTRACT.md`
  - XMage pinado como executor primario;
  - Forge secundario apenas para gap estruturado;
  - auditor: `manaloom-knowledge/scripts/xmage_execution_contract_audit.py`.
- `BATTLE_RULES_FAMILY_PIPELINE_CONTRACT_2026-06-29.md`
  - `frozen_operating_contract` do residual nativo;
  - checkpoint curto antes de qualquer family mapping.
- `XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md`
  - `historical_native-adaptation_evidence`;
  - nao e handoff atual;
  - mantém o caminho antigo estável para ferramentas e aponta ao runbook
    vigente;
  - auditor: `manaloom-knowledge/scripts/xmage_strategy_consistency_audit.py`.

Os planos XMage anteriores são evidência.
Nao devem ser usados como contrato operacional.

Manifesto histórico de replay retido:
`xmage_current_replay_batch_pipeline_20260630_post_pg276_assemble_the_players_manifest.md`.

## Contrato Commander

- `COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md`
  - `frozen_operating_contract`;
  - legalidade, identidade, intenção do comandante, corpus, uso aprendido,
    shell determinístico, validação, matriz e Battle;
  - deck `607` é benchmark/regressão protegido de Lorehold, não template
    universal;
  - auditor principal:
    `manaloom-knowledge/scripts/deckbuilding_contract_surface_audit.py`;
  - auditor de artefato:
    `manaloom-knowledge/scripts/lorehold_artifact_contract_audit.py`;
  - decisão de promoção:
    `manaloom-knowledge/scripts/lorehold_promotion_gate_decision_audit.py`;
  - inventário global:
    `manaloom-knowledge/scripts/global_commander_deck_contract_audit.py`;
  - matriz global:
    `manaloom-knowledge/scripts/global_commander_strategy_matrix.py`.

Evidências globais de referência:

- `master_optimizer_reports/global_commander_deck_contract_audit_20260701_post_scope_legalities.md`;
- `master_optimizer_reports/global_commander_strategy_matrix_20260701_current.md`.

Nenhuma lista, carta ou regra é promovida automaticamente. `607` permanece
protegido; sinais de estrutura, forced access e agregados sem exposição
natural são diagnósticos.

## Ponte de produto e dados

- O produto consome PostgreSQL/backend e payloads sanitizados, não
  `master_optimizer_reports`.
- A ponte app/IA é auditada por
  `manaloom-knowledge/scripts/app_ai_knowledge_bridge_audit.py`.
- Aliases e joins são auditados por
  `manaloom-knowledge/scripts/pg_hermes_sqlite_contract_audit.py`.
- Para validar o contrato read-only:

```bash
./scripts/quality_gate.sh pg-contract
```

- O alvo antigo fica em quarentena e é bloqueado por
  `manaloom-knowledge/scripts/old_server_reference_audit.py`.

## Retenção e drift

- `manaloom-knowledge/scripts/report_retention_audit.py` é o guard de retenção.
- `manaloom-knowledge/scripts/workspace_contract_drift_audit.py` verifica
  paths, contratos e superfícies.
- `manaloom-knowledge/scripts/legacy_contamination_audit.py` bloqueia
  crescimento de padrões legados.
- Outputs de execução ficam em `/tmp` por padrão.
- Dados brutos retidos precisam de consumidor ativo ou manifesto explícito.

Comandos:

```bash
./scripts/quality_gate.sh report-retention
./scripts/quality_gate.sh ai-bridge
./scripts/quality_gate.sh server-target
./scripts/manaloom_project_logic.sh --check
```

## Arquivo histórico

O índice e os dois contratos gigantes anteriores foram preservados byte a byte
em `archive/README.md`. Esse material serve para auditoria, recuperação e
linhagem; não é fonte executável nem handoff atual.

`build_optimized_deck.py` e `universal_optimizer.py` ficam como historicos e
bloqueados fora dos wrappers governados. Não os use para mutar deck real.

## Política de alteração

- Não editar `project_logic_manifest.json` ou `docs/generated/*` manualmente.
- Não aplicar PostgreSQL, migration, sync, deploy ou promoção sem autorização
  específica do contrato.
- Não apagar registro histórico citado sem hash, substituto e recuperação.
- Depois de alterar contrato, código, rota, migration, script ou gate, rodar
  `./scripts/manaloom_project_logic.sh --write` e `--check`.
