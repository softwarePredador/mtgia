# Receipt — BT-DOC-006: terceiro portão de capability no mapa operacional (evidência de código) — 2026-10-10

- **Estado no backlog:** `IMPLEMENTED_LOCAL_PENDING_FULL_GATE`.
- **O que é:** evidência de código, conferida só por leitura no `master` `1f525a1c1`. Nenhum gate rodou nesta sessão, e nada tocou a produção.
- **O que falta para o PASS:** o `full` verde no SHA candidato. A tarefa não tem superfície de UI própria.
- **Por que este receipt existe:** a linha do backlog não tinha receipt próprio (divergência DIV-07 do mapa de 2026-10-10).

## O que o código faz

O mapa operacional nomeia os três portões fail-closed: a API, o app e o daemon de ops. O contrato do project logic declara o fluxo `ops_scheduler`, com o daemon, os jobs e as tabelas em que ele escreve. A linha dizia "commit pendente", mas o conteúdo entrou em `f973f81c5`.

## Commits

Todos são ancestrais do `master` `1f525a1c1`.

| Commit | Data | Assunto |
| --- | --- | --- |
| `f973f81c5` | 2026-09-22 | docs: record the owner's 2026-09-22 decisions and the documentation correction |

## Outros arquivos

- `docs/MAPA_OPERACIONAL_DO_PROJETO.md`: seção "Os três portões, todos fail-closed".
- `docs/project_logic_contracts.json`: `flows[ops_scheduler]`.
- `docs/generated/CURRENT_SYSTEM.md`: o fluxo "Scheduler operacional (manaloom-ops)", gerado do contrato; hoje fala em 19 jobs, e a entrega da linha ainda diz 16.

## Gate mais recente

O `full` de 2026-10-09 sobre `1f525a1c1` (log `verifica_master_full.log` da coordenação, fora do repositório) terminou com `full_rc=1`. O `flutter analyze` do app não teve achados, e as etapas do servidor e do app ficaram verdes (no app, `+1787` com 1 teste pulado). O gate caiu no `npm audit` do site público (D-115), e por isso não rodaram `ui-audit`, `custom-lint`, `patrol-smoke`, a auditoria de dependências e o gate de schema. O log não lista cada arquivo de teste, e esta sessão não rodou os testes citados neste receipt. Isso não vale como `PASS`.

## Segue aberto

- Nada além do `full` verde: é documentação, e o `--check` já a sincroniza.
