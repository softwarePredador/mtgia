# Ficha de execução — `<TASK-ID>`

> Ledger de execução não autoritativo. ID, prioridade, estado, dependências,
> entrega e aceite são resolvidos no backlog mestre/registry.

## Autoridade

- Task ID: `<TASK-ID>`
- Backlog: `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md`
- Registry schema: `<schema-version>`
- Registry `generated_from.sha256`: `<sha256>`
- Project logic source digest: `<sha256>`
- Linha canônica: `<line>`
- Decisão corrente: `docs/status/CURRENT_PRODUCT_DECISION.md`

## Identidade da execução

- Owner: `<owner>`
- Início UTC: `<timestamp>`
- Fim UTC: `<timestamp | pending>`
- Branch: `<branch>`
- Git SHA inicial: `<sha>`
- Git SHA final: `<sha | pending>`
- Worktree digest inicial: `<sha256>`
- Worktree digest final: `<sha256 | pending>`
- Fonte estável: `<true | false>`
- Classe(s) de fechamento: `<LOCAL_CODE | DISPOSABLE_PG | ...>`
- Autorização máxima: `<local-read-only | disposable-pg | live-read-only | live-mutating-approved>`

## Resultado desta execução

### Dentro do escopo

- `<resultado concreto>`

### Fora do escopo

- `<limite explícito>`

### Capabilities

- Antes: `<capability=state>`
- Depois pretendido: `<capability=state>`
- Evidência default-deny: `<teste/receipt>`

## Critérios de entrada

- Dependências e receipts: `<refs>`
- Baseline reproduzível: `<comando e resultado>`
- Contratos aplicáveis: `<paths>`
- Dados/tabelas/rotas/consumers: `<inventário>`
- Riscos e dados sensíveis: `<riscos>`
- Rollback planejado: `<procedimento>`

## Plano de implementação

1. `<passo atômico>`
2. `<passo atômico>`

### Fontes previstas

- `<path>`

### Gerados derivados esperados

- `<path | nenhum>`

### Migration/DDL

- `<não aplicável | plano preservador, preflight, postcheck e restore>`

## Plano de prova

### Funcional

- Positivo: `<casos>`
- Negativo: `<casos>`
- Concorrência: `<casos | não aplicável com justificativa>`
- Retry/idempotência: `<casos | não aplicável com justificativa>`
- Failure injection: `<casos | não aplicável com justificativa>`

### Integração ponta a ponta

- Producer → storage → API → consumer: `<prova>`
- Isolamento A/B: `<prova>`
- Cleanup/rollback: `<prova>`

### UI/runtime

- `PASS_AUTOMATED`: `<receipt | não aplicável>`
- `PASS_RUNTIME`: `<receipt | não aplicável>`
- `PASS_VISUAL_REVIEWED`: `<receipt | não aplicável>`
- TalkBack/teclado/permissões: `<resultado | separado | não aplicável>`

### Observabilidade

- Eventos/métricas/logs: `<lista>`
- SLO/alerta/runbook: `<lista | não aplicável>`
- Redação/PII: `<prova>`

## Gates executados

| Gate | Comando | Esperado | Real | Exit | SHA | Artefato/hash |
| --- | --- | --- | --- | ---: | --- | --- |
| `<id>` | `<command>` | `<status>` | `<status>` | `<n>` | `<sha>` | `<path · sha256>` |

## Receipts

| Contrato | Producer | Status | Path/hash | Durável | Bindings revisados |
| --- | --- | --- | --- | --- | --- |
| `<receipt-id>` | `<producer>` | `<status>` | `<path · sha256>` | `<yes/no>` | `<yes/no>` |

## Aceite canônico

| Cláusula resolvida do registry | Evidência |
| --- | --- |
| `<cláusula>` | `<teste/receipt/commit>` |

## Fechamento

- Resultado E2E estrito: `<PASS | FAIL | BLOCKED | PARTIAL | n/a>`
- Gate-eligible: `<true | false>`
- Release identity: `<same SHA/digest | server behind | n/a>`
- Bloqueios: `<lista>`
- Riscos residuais: `<lista>`
- Rollback verificado: `<yes/no>`
- Auditor independente: `<GO | NO-GO | pending>`
- Veredito da execução: `<PASS | FAIL | BLOCKED | DEFERRED_BY_SCOPE>`
- Commit que atualiza o estado canônico: `<sha | pending>`
- Próximo ID elegível: `<TASK-ID | nenhum>`
