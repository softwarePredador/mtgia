# BrewTact

Lifecycle: `CURRENT_CONTEXT · ROUTER_ONLY · NO_PRIORITY_AUTHORITY`

BrewTact é a marca pública. `ManaLoom` e `manaloom` continuam como nomes
técnicos internos enquanto a migração de identificadores não for autorizada.

Este README é apenas a entrada do repositório. Ele não descreve estado de
release, não define prioridade e não autoriza mutações.

## Comece por aqui

1. [AGENTS.md](AGENTS.md) — contrato obrigatório para qualquer agente;
2. [decisão corrente](docs/status/CURRENT_PRODUCT_DECISION.md) — produto,
   oferta, plataformas e estado de release;
3. [backlog mestre](docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md) —
   Task IDs, prioridade, dependências, estado e aceite;
4. [fila WIP 1](docs/execution/CURRENT_QUEUE.md) e
   [contrato de execução](docs/execution/README.md);
5. [sistema atual gerado](docs/generated/CURRENT_SYSTEM.md) e
   `project_logic_manifest.json` para estrutura, semantic analysis e lineage;
6. [índice documental](docs/README.md) para contratos, evidências e histórico.

## Fontes de verdade

| Assunto | Autoridade |
| --- | --- |
| Produto e release | `docs/status/CURRENT_PRODUCT_DECISION.md` |
| Trabalho e prioridade | backlog mestre e registry gerado |
| Estrutura do sistema | `project_logic_manifest.json` e `docs/generated/*` |
| Dados de produto | backend, PostgreSQL e migrations versionadas |
| Cache/laboratório | Hermes/SQLite, nunca verdade final |
| Motivos e exceções | ADRs e contratos correntes |
| Evidência | receipts ligados a SHA/digest |

## Desenvolvimento local

O projeto não usa GitHub Actions. Os gates ficam nos hooks versionados:

```bash
./scripts/manaloom_install_local_hooks.sh --install
./scripts/manaloom_local_ci.sh quick
./scripts/manaloom_local_ci.sh full
```

Depois de alterar código, rota, migration, script, gate ou contrato:

```bash
./scripts/manaloom_project_logic.sh --write
./scripts/manaloom_project_logic.sh --check
```

Use os modos `schema`, `e2e` e `release` somente conforme os contratos. Um gate
local verde não autoriza deploy, escrita live, abertura de capability ou
promoção de deck/regra.
