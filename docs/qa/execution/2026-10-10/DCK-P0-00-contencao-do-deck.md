# Receipt — DCK-P0-00: contenção do ciclo de deck, servidor e app (evidência de código) — 2026-10-10

- **Estado no backlog:** `IMPLEMENTED_LOCAL_PENDING_FULL_GATE`.
- **O que é:** evidência de código, conferida só por leitura no `master` `1f525a1c1`. Nenhum gate rodou nesta sessão, e nada tocou a produção.
- **O que falta para o PASS:** o `full` verde no SHA candidato. O PASS também espera a recaptura da prova de UI: a R1 para o que já está no `master`, ou a R2 para o que entra no PR-C (D-92).
- **Por que este receipt existe:** a linha do backlog não tinha receipt próprio (divergência DIV-07 do mapa de 2026-10-10).

## O que o código faz

No servidor, `PATCH /decks/:id` e `POST /decks/:id/cards/remove` ficam sob `decks_private`. O deck novo nasce privado, publicar exige `gallery_public` e cartas, e o `POST /ai/rebuild` sem `save_mode` vira só prévia. No app, remover carta e editar descrição, estratégia e visibilidade usam essas rotas, a troca de edição se esconde com `deck_replace_all` fechada, e os códigos novos têm frase em português.

## Commits

Todos são ancestrais do `master` `1f525a1c1`.

| Commit | Data | Assunto |
| --- | --- | --- |
| `320cb6e4a` | 2026-09-24 | feat(DCK-P0-00): incremental deck editing, private new decks and advisory AI on the server (D-27) |
| `a6c0859c0` | 2026-10-05 | BT-CAT-02 + DCK-P0-00 (app side): read-only catalog, incremental deck edits |

## Testes que cobrem o aceite

- `server/test/deck_containment_test.dart`: portão na matriz da beta e recusas antes do banco.
- `server/test/deck_incremental_edit_db_live_test.dart`: PostgreSQL descartável.
- `app/test/features/decks/providers/deck_incremental_edit_routes_test.dart`: o app usa as rotas novas.
- `app/test/features/decks/widgets/deck_details_actions_test.dart`: a troca de edição some com `deck_replace_all` fechada.
- `app/test/features/decks/widgets/deck_details_dialogs_test.dart`: a frase do servidor na publicação recusada.

## Gate mais recente

O `full` de 2026-10-09 sobre `1f525a1c1` (log `verifica_master_full.log` da coordenação, fora do repositório) terminou com `full_rc=1`. O `flutter analyze` do app não teve achados, e as etapas do servidor e do app ficaram verdes (no app, `+1787` com 1 teste pulado). O gate caiu no `npm audit` do site público (D-115), e por isso não rodaram `ui-audit`, `custom-lint`, `patrol-smoke`, a auditoria de dependências e o gate de schema. O log não lista cada arquivo de teste, e esta sessão não rodou os testes citados neste receipt. Isso não vale como `PASS`.

## Segue aberto

- A prova de UI na R1, porque o app já está no `master`.
