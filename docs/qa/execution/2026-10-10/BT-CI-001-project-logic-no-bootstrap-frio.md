# Receipt — BT-CI-001: project logic no bootstrap frio (evidência de código) — 2026-10-10

- **Estado no backlog:** `IMPLEMENTED_LOCAL_PENDING_FULL_GATE`.
- **O que é:** evidência de código, conferida só por leitura no `master` `1f525a1c1`. Nenhum gate rodou nesta sessão, e nada tocou a produção.
- **O que falta para o PASS:** o `full` verde no SHA candidato. A tarefa não tem superfície de UI própria.
- **Por que este receipt existe:** a linha do backlog não tinha receipt próprio (divergência DIV-07 do mapa de 2026-10-10).

## O que o código faz

A suíte do project logic roda dentro do bootstrap frio, e o bootstrap e a validação usam a mesma lista de pacotes. Desde `387d462a3`, o `--test` também passa num checkout novo, sem `.dart_tool` em `tools/project_logic`: antes, o primeiro `--test` falhava com "Diretório .dart_tool residual".

## Commits

Todos são ancestrais do `master` `1f525a1c1`.

| Commit | Data | Assunto |
| --- | --- | --- |
| `d83e9b1e1` | 2026-09-18 | fix(BT-SCP-001): let the project logic suite run inside the cold bootstrap |
| `07014b431` | 2026-09-21 | fix(BT-SCP-001): take the broad gate to zero test failures |
| `387d462a3` | 2026-10-09 | fix(project-logic): let --test pass in a fresh checkout |
| `3617d62cd` | 2026-10-09 | test(project-logic): cover a dangling .dart_tool symlink left by a run |

## Testes que cobrem o aceite

- `tools/project_logic/test/project_logic_generator_test.dart`: a suíte do gerador.
- `tools/project_logic/test/project_logic_cold_repro_contract_test.dart`: o caso frio e o link simbólico residual, contra um `ROOT_DIR` descartável.

## Outros arquivos

- `scripts/manaloom_project_logic.sh`: o lançador.

## Gate mais recente

O `full` de 2026-10-09 sobre `1f525a1c1` (log `verifica_master_full.log` da coordenação, fora do repositório) terminou com `full_rc=1`. O `flutter analyze` do app não teve achados, e as etapas do servidor e do app ficaram verdes (no app, `+1787` com 1 teste pulado). O gate caiu no `npm audit` do site público (D-115), e por isso não rodaram `ui-audit`, `custom-lint`, `patrol-smoke`, a auditoria de dependências e o gate de schema. O log não lista cada arquivo de teste, e esta sessão não rodou os testes citados neste receipt. Isso não vale como `PASS`.

## Segue aberto

- Deixar de depender do `active_roots` do cache Pub global de outros worktrees. Hoje a coordenação contorna isso com a trava FIFO, fora do repositório.
