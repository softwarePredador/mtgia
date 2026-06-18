# Codex + Hermes Collaboration Protocol — 2026-06-11

> Objetivo: manter Codex local e Hermes/AWS trabalhando juntos sem conflito de
> branch, docs ou fonte de verdade.

## Modelo de branches

| Branch | Dono operacional | Pode alterar produto? | Papel |
|---|---|---:|---|
| `master` | Codex/local + revisão humana | Sim | Fonte canônica de código, docs curadas e deploy |
| `codex/hermes-analysis-docs` | Hermes crons/agentes | Não | Staging de memória, relatórios e auditorias brutas |

Regra principal:

- Hermes não deve tratar `codex/hermes-analysis-docs` como verdade do produto.
- Codex não deve fazer merge bruto da branch docs para `master`.
- Achados Hermes só viram mudança real após triagem contra o código em
  `master`.

## Fluxo após push do Codex

1. Codex implementa no workspace local e valida.
2. Codex faz commit/push em `master`.
3. Codex chama Hermes report-only contra o SHA pushado.
4. Hermes responde `PASS`, `FINDINGS` ou `BLOCKED`.
5. Codex decide:
   - `PASS`: seguir.
   - `FINDINGS`: abrir triagem se houver evidência concreta.
   - `BLOCKED`: corrigir protocolo, ambiente ou bug real antes de seguir.

Comando esperado no Hermes:

```bash
/opt/data/scripts/manaloom-hermes-report-only.sh <sha>
```

## Fluxo das crons Hermes

As crons podem:

- ler `origin/master`;
- gerar relatórios em `docs/hermes-analysis/**`;
- atualizar memória em `codex/hermes-analysis-docs`;
- sincronizar conhecimento runtime quando o script for explicitamente de sync.

As crons não podem:

- alterar código de produto em `master`;
- criar branches novas sem pedido humano;
- mergear `codex/hermes-analysis-docs` em `master`;
- criar tarefa sem evidência de arquivo/linha ou artefato runtime.

## Como um achado Hermes entra no produto

Um achado precisa ser convertido em item curado com:

1. Evidência: arquivo/linha, script, artefato ou comando.
2. Impacto no produto.
3. Classificação: `real`, `stale`, `needs proof`.
4. Ação recomendada.
5. Validação mínima.

Só depois disso Codex implementa em `master`.

## Guardrail de docs

Docs Hermes grandes ou geradas automaticamente continuam úteis como histórico,
mas não são contrato operacional por si só.

Ordem para leitura:

1. `README.md`
2. `BRANCH_RETENTION_AUDIT_2026-06-11.md`
3. `HERMES_DOCS_TRIAGE_2026-06-11.md`
4. contrato E2E e reports frescos referenciados pelo README

Se houver conflito entre docs:

- `master` + código vivo prevalecem;
- docs antigas devem ser marcadas como histórico ou triadas;
- nunca resolver conflito copiando tudo da branch docs.

## Estado esperado do Hermes

No container Hermes:

```bash
cd /opt/data/workspace/mtgia
git fetch --all --prune
git status --short --branch
git branch -r
```

Resultado esperado:

- checkout limpo ou com artefatos runtime conhecidos;
- `origin/master`;
- `origin/codex/hermes-analysis-docs`;
- nenhuma branch antiga `copilot/*`, `codex/hermes-dev` ou
  `codex/hermes-fixes-f0-f3`.
