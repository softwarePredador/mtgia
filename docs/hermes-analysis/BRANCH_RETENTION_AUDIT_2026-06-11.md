# Branch Retention Audit — 2026-06-11

> Objetivo: reduzir conflito de informação e manter no máximo duas branches
> remotas ativas no repositório ManaLoom.
> Base auditada: `master@5e29508a`.

## Decisão

Manter somente:

| Branch | Papel | Fonte canônica? |
|---|---|---|
| `master` | Código/produto/docs curadas e deploy | Sim |
| `codex/hermes-analysis-docs` | Fila/staging de relatórios Hermes e auditorias brutas | Não |

Regra operacional:

- `master` é a fonte de verdade do projeto.
- `codex/hermes-analysis-docs` pode continuar existindo apenas como branch de
  trabalho do Hermes para gerar relatórios e memória bruta.
- Conteúdo vindo de `codex/hermes-analysis-docs` não deve ser mergeado bruto na
  `master`. Antes, precisa passar por triagem curada, como
  `HERMES_DOCS_TRIAGE_2026-06-11.md`.
- Se o Hermes precisar escrever documentação permanente, a saída deve ser
  convertida em commit pequeno na `master`, com achados revalidados contra o
  código vivo.

## Branches encontradas antes da limpeza

| Branch remota | Ahead de `master` | Status | Decisão |
|---|---:|---|---|
| `origin/master` | 0 | principal | manter |
| `origin/codex/hermes-analysis-docs` | 120 | staging Hermes docs | manter |
| `origin/codex/hermes-fixes-f0-f3` | 0 | já mergeada | apagar |
| `origin/codex/hermes-dev` | 2 | antiga, não canônica | apagar |
| `origin/copilot/add-health-marker-feature` | 0 | já mergeada | apagar |
| `origin/copilot/add-tests-for-put-delete` | 0 | já mergeada | apagar |
| `origin/copilot/analisar-layout-do-aplicativo` | 0 | já mergeada | apagar |
| `origin/copilot/audit-algorithm-logic-form` | 0 | já mergeada | apagar |
| `origin/copilot/audit-and-improve-documentation` | 0 | já mergeada | apagar |
| `origin/copilot/audit-code-quality-consistency` | 0 | já mergeada | apagar |
| `origin/copilot/audit-project-for-quality` | 1 | plano antigo, não canônico | apagar |
| `origin/copilot/delegate-to-cloud-agent` | 1 | plano antigo, não canônico | apagar |
| `origin/copilot/documentar-configuracoes-de-cores` | 0 | já mergeada | apagar |
| `origin/copilot/implement-roadmap-guidelines` | 0 | já mergeada | apagar |
| `origin/copilot/redesign-app-theme` | 0 | já mergeada | apagar |
| `origin/copilot/refactor-theme-for-ui-calmliness` | 3 | UI antiga, não canônica | apagar |
| `origin/copilot/review-app-idea-and-flows` | 0 | já mergeada | apagar |
| `origin/copilot/review-prompts-for-mtg-decks` | 0 | já mergeada | apagar |
| `origin/copilot/test-deck-optimization-validation` | 0 | já mergeada | apagar |
| `origin/copilot/testar-funcoes-app-gasgalos` | 0 | já mergeada | apagar |
| `origin/copilot/update-auditoria-formulario` | 0 | já mergeada | apagar |

## Commits exclusivos preservados por referência

As branches antigas com commits não mergeados foram consideradas obsoletas para
o produto atual. Os hashes ficam registrados aqui para recuperação manual se
necessário:

| Branch apagada | Último commit |
|---|---|
| `origin/codex/hermes-dev` | `f70309a1` |
| `origin/copilot/audit-project-for-quality` | `95a602f0` |
| `origin/copilot/delegate-to-cloud-agent` | `2184d9fb` |
| `origin/copilot/refactor-theme-for-ui-calmliness` | `0120f912` |

## Validação esperada depois da limpeza

```bash
git fetch --all --prune
git branch -r
```

Resultado esperado:

- `origin/master`
- `origin/codex/hermes-analysis-docs`

Branches locais esperadas:

- `master`
- `codex/hermes-analysis-docs`

## Política para evitar conflito de documentação

1. Não usar `codex/hermes-analysis-docs` como fonte de verdade.
2. Não copiar relatórios grandes do Hermes para `master` sem triagem.
3. Todo relatório Hermes acionável deve virar:
   - achado com arquivo/linha;
   - impacto;
   - decisão `real`, `stale` ou `precisa prova`;
   - validação mínima;
   - commit pequeno na `master`.
4. Se a branch docs voltar a acumular relatório contraditório sem triagem, ela
   deve ser substituída por issue/artefato ou apagada.
