# Hermes Docs Validation Matrix

> Status atual: canonico.
> Esta matriz classifica todos os Markdown da raiz de `docs/hermes-analysis/`.

Updated: 2026-06-07

## Objetivo

Esta matriz valida e classifica todos os Markdown da raiz de
`docs/hermes-analysis/`. Ela existe para limpar a leitura dos agentes sem apagar
historico auditavel.

Regra de leitura:

- `canonico`: pode guiar execucao atual.
- `operacional de apoio`: util, mas deve ser cruzado com o contrato canonico.
- `historico`: memoria/auditoria; nao deve guiar execucao atual sozinho.
- `produto/backlog`: tarefas e auditorias do app/backend; nao e contrato Hermes runtime.

## Fonte de verdade

| Prioridade | Arquivo | Status | Uso correto |
| ---: | --- | --- | --- |
| 1 | `README.md` | canonico | Porta de entrada da pasta. |
| 2 | `HERMES_E2E_SYSTEM_CONTRACT_2026-06-07.md` | canonico | Contrato de scripts, bancos, tabelas, parametros, retornos e guardrails. |
| 3 | `HERMES_MASTER_OPTIMIZER_LOOP_2026-06-06.md` | operacional de apoio | Diario tecnico e evidencias recentes; nao autoriza apply sem SQLite vivo. |
| 4 | `HERMES_CRON_PIPELINE_ORDER_2026-06-07.md` | operacional de apoio | Snapshot de crons; validar contra `/opt/data/cron/jobs.json`. |
| 5 | `HERMES_DOCS_VALIDATION_MATRIX_2026-06-07.md` | canonico | Classificacao dos docs raiz. |
| 6 | `master_optimizer_reports/**` | evidencia | Reports de rodadas; usar apenas se `baseline_id`/`baseline_hash` baterem com o SQLite vivo. |

## Matriz dos docs raiz

| Arquivo | Classe | Validade atual | Acao aplicada/recomendada |
| --- | --- | --- | --- |
| `README.md` | canonico | valido | Manter como entrada principal. |
| `HERMES_DOCS_VALIDATION_MATRIX_2026-06-07.md` | canonico | valido | Manter como matriz de validade documental. |
| `HERMES_E2E_SYSTEM_CONTRACT_2026-06-07.md` | canonico | valido | Manter como contrato operacional. |
| `HERMES_MASTER_OPTIMIZER_LOOP_2026-06-06.md` | operacional de apoio | valido com aviso | Manter; ja recebeu aviso de diario/evidencia. |
| `HERMES_CRON_PIPELINE_ORDER_2026-06-07.md` | operacional de apoio | valido com aviso | Manter; ja recebeu aviso de snapshot. |
| `HERMES_CRON_GOVERNANCE_REPORT.md` | historico | antigo | Manter com aviso; nao usar como cron atual. |
| `HERMES_KNOWLEDGE_PIPELINE_GOVERNANCE.md` | historico | antigo | Manter com aviso; politica antiga foi superada pelo contrato E2E. |
| `AUDIT_REPORT_2026-05-27.md` | historico | antigo | Marcar como snapshot historico. |
| `AUDIT_REPORT_2026-05-30.md` | historico | antigo | Marcar como snapshot historico. |
| `AUDIT_REPORT_2026-05-31.md` | historico | antigo | Marcar como snapshot historico. |
| `COMMIT_DIGEST.md` | historico | antigo/volumoso | Marcar como digest historico. |
| `PROJECT_MEMORY.md` | historico | parcialmente antigo | Marcar como memoria antiga; README prevalece. |
| `PRODUCT_DIRECTION.md` | produto/backlog | estrategia historica | Marcar como direcao de produto, nao contrato runtime. |
| `BACKEND_ACTIONABLE_TASKS.md` | produto/backlog | backlog | Marcar como backlog backend. |
| `UI_ACTIONABLE_TASKS.md` | produto/backlog | backlog | Marcar como backlog UI. |
| `FLUTTER_UI_AUDIT.md` | produto/backlog | auditoria de UI | Marcar como auditoria UI, nao Hermes runtime. |
| `LOGIC_COHERENCE_REPORT_2026-05-29.md` | produto/backlog | auditoria antiga | Marcar como snapshot de coerencia antiga. |
| `LOGIC_COHERENCE_REPORT_2026-05-29_E2E.md` | produto/backlog | auditoria antiga | Marcar como snapshot de coerencia antiga. |
| `modules_coherence.md` | produto/backlog | auditoria antiga | Marcar como snapshot de coerencia de modulos. |
| `OPEN_RISKS.md` | produto/backlog | risco historico | Marcar como registro historico; validar antes de agir. |
| `IMPLEMENTATION_TASKS.md` | produto/backlog | backlog grande | Manter; nao usar como prova atual sem revalidacao. |
| `PLANO_CORRECAO.md` | produto/backlog | plano estrutural | Manter; escopo app/backend, nao Hermes runtime. |
| `STRUCTURE_AUDIT.md` | produto/backlog | auditoria enorme | Manter, mas usar apenas em auditoria estrutural. |
| `TECHNICAL_MAP.md` | produto/backlog | mapa tecnico | Manter como mapa app/backend; nao substitui contrato Hermes. |

## Diretorios aninhados

| Diretorio | Classe | Acao |
| --- | --- | --- |
| `master_optimizer_reports/` | evidencia | Nao limpar automaticamente. Reports podem provar baseline/hash/apply/rollback. |
| `kc_validator_reports/` | evidencia | Nao limpar automaticamente; usar report mais fresco. |
| `manaloom-knowledge/` | dados/scripts/logs | Nao limpar em massa; contem SQLite, scripts, seeds e historico de decks. |
| `ops-audits/` | auditoria | Sem MD no snapshot atual; manter. |
| `scripts/` | suporte | Sem MD no snapshot atual; manter. |

## O que pode ser arquivado depois

Pode ser movido para uma pasta `archive/` em uma PR separada, se e somente se
ninguem depender do caminho atual:

- `AUDIT_REPORT_2026-05-27.md`
- `AUDIT_REPORT_2026-05-30.md`
- `AUDIT_REPORT_2026-05-31.md`
- `HERMES_CRON_GOVERNANCE_REPORT.md`
- `HERMES_KNOWLEDGE_PIPELINE_GOVERNANCE.md`
- `LOGIC_COHERENCE_REPORT_2026-05-29.md`
- `LOGIC_COHERENCE_REPORT_2026-05-29_E2E.md`
- `modules_coherence.md`

Nao recomendo deletar nesta rodada porque eles preservam contexto historico e
evidencias de auditorias antigas.

## Furos adicionais encontrados

1. `PROJECT_MEMORY.md` ainda tinha uma propria ordem de fontes canonicas. Isso
   pode conflitar com `README.md`; o README agora deve prevalecer.
2. `IMPLEMENTATION_TASKS.md` e `STRUCTURE_AUDIT.md` sao grandes demais para
   agentes lerem por padrao; usar so quando a tarefa exigir backlog ou auditoria
   estrutural.
3. Varios docs de produto usam achados antigos como linguagem de risco atual.
   Qualquer P0/P1 desses arquivos precisa ser revalidado contra codigo vivo
   antes de virar trabalho.
4. Reports antigos em `master_optimizer_reports/` podem contradizer revalidacoes
   novas. A regra correta e sempre preferir o report mais fresco que bate com
   `baseline_id`, `baseline_hash` e SQLite vivo.

## Resultado da limpeza segura

- Nenhum arquivo foi deletado.
- A autoridade documental foi centralizada em `README.md` e no contrato E2E.
- Docs historicos/backlogs foram classificados.
- Docs perigosos receberam aviso no topo.
- O proximo nivel de limpeza, se desejado, e mover snapshots antigos para
  `docs/hermes-analysis/archive/` em uma mudanca separada.
