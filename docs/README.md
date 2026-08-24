# BrewTact/ManaLoom — índice documental

Lifecycle: `CURRENT_CONTEXT · ROUTER_ONLY · NO_PRIORITY_AUTHORITY`

Este índice separa decisão, execução, estrutura, contratos, evidência e
histórico. Em caso de divergência, use a precedência abaixo; quantidade de
documentos ou data mais recente não cria autoridade.

## 1. Decisão e trabalho corrente

- [Decisão corrente](status/CURRENT_PRODUCT_DECISION.md)
- [Backlog mestre](BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md)
- [Fila operacional WIP 1](execution/CURRENT_QUEUE.md)
- [Contrato de execução](execution/README.md)

Somente a decisão corrente e o backlog podem definir escopo, prioridade,
dependências, estado e aceite. A fila e as fichas são coordenação/ledger.

## 2. Estrutura gerada

- [Sistema atual](generated/CURRENT_SYSTEM.md)
- [Arquitetura](generated/ARCHITECTURE.md)
- [Matriz de rastreabilidade](generated/TRACEABILITY_MATRIX.md)
- `../project_logic_manifest.json`
- [Contrato do gerador](adr/0001-generated-project-logic.md)

Arquivos em `docs/generated/` nunca são editados manualmente. Eles registram
estrutura e lineage, não intenção arquitetural nem conclusão de release.

## 3. Contratos transversais

- [E2E e release](MANALOOM_E2E_RELEASE_CONTRACT.md)
- [Prova viva de UI](MANALOOM_UI_LIVE_EVIDENCE_CONTRACT.md)
- [Arte, cache e direitos](MANALOOM_CARD_ART_SOURCE_CACHE_AND_RIGHTS_CONTRACT.md)
- [Ingestão da coleção](MANALOOM_COLLECTION_INGESTION_CONTRACT.md)
- [Agenda read-only de deltas externos](MANALOOM_EXTERNAL_ENGINE_DELTA_SCHEDULE.md)
- [API e dados](../server/doc/API_CONTRACTS_AND_DATA_MAP.md)

## 4. Deck, IA, Battle e dados MTG

- [Fluxo corrente Deck/IA](BREWTACT_DECKBUILDER_AI_CURRENT_FLOW_2026-08-12.md)
- [Contrato Commander](hermes-analysis/COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md)
- [Execução Battle externa](hermes-analysis/EXTERNAL_BATTLE_EXECUTION_CONTRACT.md)
- [Fechamento global Battle/regras/learning](hermes-analysis/GLOBAL_BATTLE_RULES_AND_LEARNING_CLOSURE_2026-07-15.md)
- [Aliases de dados](hermes-analysis/DATA_FIELD_ALIAS_CONTRACT_2026-06-30.md)
- [Capabilities XMage/Forge](hermes-analysis/EXTERNAL_ENGINE_CAPABILITY_CONTRACT.json)
- [Transição de pin XMage](hermes-analysis/EXTERNAL_ENGINE_PIN_TRANSITION_CONTRACT.json)
- [Patch governado XMage](hermes-analysis/XMAGE_GOVERNED_RUNTIME_PATCH_CONTRACT.json)

PostgreSQL/backend é a verdade de produto. Hermes/SQLite é cache, laboratório
ou evidência. Execução XMage/Forge não promove automaticamente regra nativa,
deck ou aprendizado.

## 5. ADRs

O [índice de ADRs](adr/README.md) registra decisões e relações de supersessão.
ADRs não são reescritos retroativamente; uma decisão posterior cria novo ADR.

## 6. Testes, gates e evidências

- `app/test/README.md` e `server/test/README.md` — organização das suítes;
- `execution/TASK_PACKET_TEMPLATE.md` — plano de prova por task;
- `qa/execution/` — receipts duráveis e task-scoped;
- `qa/ui-live/latest.json` — aggregate da prova visual corrente;
- `../scripts/quality_gate.sh` e `../scripts/manaloom_local_ci.sh` — runners.

Arquivos em `docs/qa/` são evidência, não prioridade. Um receipt prova somente
o SHA/digest e o escopo que declara.

## 7. Histórico e arquivo

- `archive/` — documentos explicitamente arquivados;
- `qa/` — evidências datadas;
- `hermes-analysis/archive/` e relatórios Hermes — material histórico,
  diagnóstico ou laboratório;
- planos e trackers superseded permanecem consultáveis, sem autoridade atual.

Comando presente em documento histórico é exemplo não autoritativo. Para agir,
retorne à decisão, ao backlog, à task `NOW` e ao contrato vigente da área.

## Lifecycle mínimo

| Estado | Uso |
| --- | --- |
| `current_decision` | decisão atual de produto/release |
| `current_task_index` | prioridade, dependências, estado e aceite |
| `current_contract` | regra normativa vigente |
| `current_context` | roteador ou contexto corrente sem prioridade |
| `generated_snapshot` | projeção produzida por ferramenta |
| `historical_evidence` | evidência ou plano superseded |
| `supporting_reference_non_authoritative` | apoio sem autoridade operacional |

O registry de lifecycle é gerado a partir de
`docs/project_logic_contracts.json`; alterações exigem regeneração e check do
project logic.
