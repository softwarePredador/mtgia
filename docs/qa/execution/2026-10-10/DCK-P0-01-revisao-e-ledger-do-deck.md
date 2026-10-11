# Receipt — DCK-P0-01: revisão otimista, ledger e desfazer no servidor (evidência de código) — 2026-10-10

- **Estado no backlog:** `IMPLEMENTED_LOCAL_PENDING_FULL_GATE`.
- **O que é:** evidência de código, conferida só por leitura no `master` `1f525a1c1`. Nenhum gate rodou nesta sessão, e nada tocou a produção.
- **O que falta para o PASS:** o `full` verde no SHA candidato. A tarefa não tem superfície de UI própria.
- **Por que este receipt existe:** a linha do backlog não tinha receipt próprio (divergência DIV-07 do mapa de 2026-10-10).

## O que o código faz

Todo mutator de deck existente trava o deck e confere o `If-Match`. Ele sobe a revisão e grava o que mudou no ledger `deck_change_events`, que só aceita INSERT, e devolve o recibo com o `ETag`. Retry com a mesma `Idempotency-Key` devolve o recibo gravado, e o desfazer universal recusa HEAD novo. Vale a transição da D-29: sem o cabeçalho, a mudança passa com `revision_warning`.

## Commits

Todos são ancestrais do `master` `1f525a1c1`.

| Commit | Data | Assunto |
| --- | --- | --- |
| `7855590b6` | 2026-09-24 | feat(DCK-P0-01): deck revision, immutable change ledger and universal undo on the server (D-29) |
| `ab1be787e` | 2026-09-28 | test(BT-AUTH-001): align the public error contract with the deck revision lock |

## Testes que cobrem o aceite

- `server/test/deck_revision_support_test.dart`: regras de revisão e recibo.
- `server/test/deck_revision_ledger_db_live_test.dart`: PostgreSQL descartável: todo mutator, duas mudanças concorrentes com um vencedor e um 409, retry, transição, desfazer, histórico e ledger só de acréscimo.
- `server/test/deck_review_artifact_db_live_test.dart`: o artefato do Optimize ligado à revisão.

## Outros arquivos

- `server/lib/decks/deck_revision_support.dart`: o contrato.

## Gate mais recente

O `full` de 2026-10-09 sobre `1f525a1c1` (log `verifica_master_full.log` da coordenação, fora do repositório) terminou com `full_rc=1`. O `flutter analyze` do app não teve achados, e as etapas do servidor e do app ficaram verdes (no app, `+1787` com 1 teste pulado). O gate caiu no `npm audit` do site público (D-115), e por isso não rodaram `ui-audit`, `custom-lint`, `patrol-smoke`, a auditoria de dependências e o gate de schema. O log não lista cada arquivo de teste, e esta sessão não rodou os testes citados neste receipt. Isso não vale como `PASS`.

## Segue aberto

- O app mandar `If-Match` e a `Idempotency-Key`, no PR-C (`BT-UX-BATCH-001`). O histórico e o desfazer na UI ficam fora da primeira coorte. A migration 067 vai para a produção no lote, com a palavra do dono.
