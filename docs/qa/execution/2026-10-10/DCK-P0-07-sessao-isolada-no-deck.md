# Receipt — DCK-P0-07: estado de deck isolado por sessão (evidência de código) — 2026-10-10

- **Estado no backlog:** `IMPLEMENTED_LOCAL_PENDING_FULL_GATE`.
- **O que é:** evidência de código, conferida só por leitura no `master` `1f525a1c1`. Nenhum gate rodou nesta sessão, e nada tocou a produção.
- **O que falta para o PASS:** o `full` verde no SHA candidato. O PASS também espera a recaptura da prova de UI: a R1 para o que já está no `master`, ou a R2 para o que entra no PR-C (D-92).
- **Por que este receipt existe:** a linha do backlog não tinha receipt próprio (divergência DIV-07 do mapa de 2026-10-10).

## O que o código faz

O `DeckProvider` ganhou uma época de sessão que o logout e a troca de conta avançam. Resposta, polling e recarga começados na conta anterior são descartados. Detalhe e lista do deck levam sequência de pedido, e o logout limpa o job ativo do Optimize, o histórico e os caches de análise.

## Commits

Todos são ancestrais do `master` `1f525a1c1`.

| Commit | Data | Assunto |
| --- | --- | --- |
| `f9403c67c` | 2026-10-05 | DCK-P0-07: isolate deck state per session and order async responses |

## Testes que cobrem o aceite

- `app/test/features/decks/providers/deck_provider_session_isolation_test.dart`: resposta e erro tardios do deck A não caem no deck B aberto depois; lista mais velha não substitui a mais nova; login A, logout e login B sem resposta de A chegando a B; o logout derruba o job ativo do Optimize e os caches.

## Gate mais recente

O `full` de 2026-10-09 sobre `1f525a1c1` (log `verifica_master_full.log` da coordenação, fora do repositório) terminou com `full_rc=1`. O `flutter analyze` do app não teve achados, e as etapas do servidor e do app ficaram verdes (no app, `+1787` com 1 teste pulado). O gate caiu no `npm audit` do site público (D-115), e por isso não rodaram `ui-audit`, `custom-lint`, `patrol-smoke`, a auditoria de dependências e o gate de schema. O log não lista cada arquivo de teste, e esta sessão não rodou os testes citados neste receipt. Isso não vale como `PASS`.

## Segue aberto

- A prova de UI na R1.
