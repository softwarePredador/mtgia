# Receipt — DCK-P0-03: import em deck existente em duas fases (evidência de código) — 2026-10-10

- **Estado no backlog:** `IMPLEMENTED_LOCAL_PENDING_FULL_GATE`.
- **O que é:** evidência de código, conferida só por leitura no `master` `1f525a1c1`. Nenhum gate rodou nesta sessão, e nada tocou a produção.
- **O que falta para o PASS:** o `full` verde no SHA candidato. A tarefa não tem superfície de UI própria.
- **Por que este receipt existe:** a linha do backlog não tinha receipt próprio (divergência DIV-07 do mapa de 2026-10-10).

## O que o código faz

`POST /import/to-deck/preview`, sob `decks_private`, calcula a lista final e a diferença completa sem gravar e emite o artefato `import_to_deck`. `POST /import/to-deck`, sob `deck_replace_all`, só aplica com esse artefato. Ele recusa prévia velha, adulterada ou expirada sem escrever e grava no ledger o que o desfazer volta.

## Commits

Todos são ancestrais do `master` `1f525a1c1`.

| Commit | Data | Assunto |
| --- | --- | --- |
| `687c3336e` | 2026-09-24 | feat(DCK-P0-03): two-phase import into an existing deck with full diff and undo (D-29) |

## Testes que cobrem o aceite

- `server/test/import_to_deck_two_phase_db_live_test.dart`: PostgreSQL descartável: prévia sem escrita, commit exato, stale, adulterado, expirado, de outro deck, sem artefato e desfazer exato.
- `server/test/import_to_deck_merge_support_test.dart`: a lista final.

## Gate mais recente

O `full` de 2026-10-09 sobre `1f525a1c1` (log `verifica_master_full.log` da coordenação, fora do repositório) terminou com `full_rc=1`. O `flutter analyze` do app não teve achados, e as etapas do servidor e do app ficaram verdes (no app, `+1787` com 1 teste pulado). O gate caiu no `npm audit` do site público (D-115), e por isso não rodaram `ui-audit`, `custom-lint`, `patrol-smoke`, a auditoria de dependências e o gate de schema. O log não lista cada arquivo de teste, e esta sessão não rodou os testes citados neste receipt. Isso não vale como `PASS`.

## Segue aberto

- Pela D-96, vira `PASS` com o servidor e a superfície escondida. O PR-C (`BT-UX-BATCH-001`) prova que nenhum caminho do app leva ao commit.
