# Receipt — BT-GOV-002: fila com duas raias (evidência de código) — 2026-10-10

- **Estado no backlog:** `IMPLEMENTED_LOCAL_PENDING_FULL_GATE`.
- **O que é:** evidência de código, conferida só por leitura no `master` `1f525a1c1`. Nenhum gate rodou nesta sessão, e nada tocou a produção.
- **O que falta para o PASS:** o `full` verde no SHA candidato. A tarefa não tem superfície de UI própria.
- **Por que este receipt existe:** a linha do backlog não tinha receipt próprio (divergência DIV-07 do mapa de 2026-10-10).

## O que o código faz

O gerador do project logic lê a coluna `Raia` da tabela "Slot atual" de `docs/execution/CURRENT_QUEUE.md` e aceita até dois slots `NOW`, um por raia, cada um com ficha e linha de contenção próprias. O registry publica `active_slots` e mantém `active_slot`, e o formato antigo, de um slot só, continua aceito.

## Commits

Todos são ancestrais do `master` `1f525a1c1`.

| Commit | Data | Assunto |
| --- | --- | --- |
| `06e9d2bbe` | 2026-09-23 | feat(BT-GOV-002): allow one NOW slot per lane in the execution queue |

## Testes que cobrem o aceite

- `tools/project_logic/test/project_logic_generator_test.dart`: um e dois slots; recusa três slots, raia repetida, raia desconhecida, o mesmo ID nas duas raias, raia sem contenção, contenção sem slot, contenção repetida, ficha ausente e a coluna fora do lugar. Pela linha do backlog, a mutação que aceita raia repetida falha.

## Outros arquivos

- `tools/project_logic/lib/project_logic_generator.dart`: `_nowSlots` e `_nowSlotLedger`.

## Gate mais recente

O `full` de 2026-10-09 sobre `1f525a1c1` (log `verifica_master_full.log` da coordenação, fora do repositório) terminou com `full_rc=1`. O `flutter analyze` do app não teve achados, e as etapas do servidor e do app ficaram verdes (no app, `+1787` com 1 teste pulado). O gate caiu no `npm audit` do site público (D-115), e por isso não rodaram `ui-audit`, `custom-lint`, `patrol-smoke`, a auditoria de dependências e o gate de schema. O log não lista cada arquivo de teste, e esta sessão não rodou os testes citados neste receipt. Isso não vale como `PASS`.

## Segue aberto

- Abrir a raia do app na fila, que é da coordenação quando o `BT-UIEV-001` fechar.
