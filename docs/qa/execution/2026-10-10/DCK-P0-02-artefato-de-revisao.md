# Receipt — DCK-P0-02: DeckReviewArtifact v1 (evidência de código) — 2026-10-10

- **Estado no backlog:** `IMPLEMENTED_LOCAL_PENDING_FULL_GATE`.
- **O que é:** evidência de código, conferida só por leitura no `master` `1f525a1c1`. Nenhum gate rodou nesta sessão, e nada tocou a produção.
- **O que falta para o PASS:** o `full` verde no SHA candidato. A tarefa não tem superfície de UI própria.
- **Por que este receipt existe:** a linha do backlog não tinha receipt próprio (divergência DIV-07 do mapa de 2026-10-10).

## O que o código faz

O token `drv1` liga dono, deck, revisão, assinatura do conteúdo, `input_hash`, `constraints_hash` e o tipo do fluxo, com HMAC-SHA256 e 24 h de validade (D-29). A autorização de apply do Optimize passou a ser esse artefato, verificado antes de qualquer escrita.

## Commits

Todos são ancestrais do `master` `1f525a1c1`.

| Commit | Data | Assunto |
| --- | --- | --- |
| `d30744b3f` | 2026-09-24 | feat(DCK-P0-02): DeckReviewArtifact v1 for the Optimize preview and commit (D-29) |

## Testes que cobrem o aceite

- `server/test/deck_review_artifact_test.dart`: cada recusa com o seu código.
- `server/test/optimize_apply_authorization_test.dart`: dono e estado velho.
- `server/test/deck_review_artifact_db_live_test.dart`: PostgreSQL descartável: nenhuma escrita com artefato adulterado, expirado, de outro usuário, de outro deck ou de estado velho.

## Outros arquivos

- `server/lib/decks/deck_review_artifact.dart`: o artefato.

## Gate mais recente

O `full` de 2026-10-09 sobre `1f525a1c1` (log `verifica_master_full.log` da coordenação, fora do repositório) terminou com `full_rc=1`. O `flutter analyze` do app não teve achados, e as etapas do servidor e do app ficaram verdes (no app, `+1787` com 1 teste pulado). O gate caiu no `npm audit` do site público (D-115), e por isso não rodaram `ui-audit`, `custom-lint`, `patrol-smoke`, a auditoria de dependências e o gate de schema. O log não lista cada arquivo de teste, e esta sessão não rodou os testes citados neste receipt. Isso não vale como `PASS`.

## Segue aberto

- Nada no app da primeira coorte: o Optimize fica desligado (D-07).
