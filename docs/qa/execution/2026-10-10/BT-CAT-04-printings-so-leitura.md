# Receipt — BT-CAT-04: `GET /cards/printings` só lê (evidência de código) — 2026-10-10

- **Estado no backlog:** `IMPLEMENTED_LOCAL_PENDING_FULL_GATE`.
- **O que é:** evidência de código, conferida só por leitura no `master` `1f525a1c1`. Nenhum gate rodou nesta sessão, e nada tocou a produção.
- **O que falta para o PASS:** o `full` verde no SHA candidato. A tarefa não tem superfície de UI própria.
- **Por que este receipt existe:** a linha do backlog não tinha receipt próprio (divergência DIV-07 do mapa de 2026-10-10).

## O que o código faz

A rota de edições não chama a Scryfall nem escreve em `cards` e `sets`, nem com `sync=true`. O app deixou de mandar o parâmetro, e um guarda de fonte falha se ele voltar.

## Commits

Todos são ancestrais do `master` `1f525a1c1`.

| Commit | Data | Assunto |
| --- | --- | --- |
| `0ae47c53b` | 2026-09-23 | fix(BT-CAT-04): make GET /cards/printings read-only |
| `a80aa34e0` | 2026-09-23 | fix(BT-CAT-02): catalog reads never write or call Scryfall |
| `a6c0859c0` | 2026-10-05 | BT-CAT-02 + DCK-P0-00 (app side): read-only catalog, incremental deck edits |

## Testes que cobrem o aceite

- `server/test/cards_printings_read_only_test.dart`: 0 chamada externa e só leituras, com `sync=true` e em 5 repetições.
- `server/test/catalog_routes_read_only_guard_test.dart`: as 7 rotas de catálogo sem cliente HTTP nem DML.
- `server/test/cards_route_test.dart`: a guarda de fonte invertida.
- `app/test/features/cards/catalog_read_only_app_guard_test.dart`: o app não manda parâmetro de sync.

## Outros arquivos

- `docs/qa/execution/2026-09-23/deploy-lote-integrado.md`: a rota no ar desde 2026-09-23 às 14:49 UTC (`c0f907108`).

## Gate mais recente

O `full` de 2026-10-09 sobre `1f525a1c1` (log `verifica_master_full.log` da coordenação, fora do repositório) terminou com `full_rc=1`. O `flutter analyze` do app não teve achados, e as etapas do servidor e do app ficaram verdes (no app, `+1787` com 1 teste pulado). O gate caiu no `npm audit` do site público (D-115), e por isso não rodaram `ui-audit`, `custom-lint`, `patrol-smoke`, a auditoria de dependências e o gate de schema. O log não lista cada arquivo de teste, e esta sessão não rodou os testes citados neste receipt. Isso não vale como `PASS`.

## Segue aberto

- Nada além do `full` verde.
