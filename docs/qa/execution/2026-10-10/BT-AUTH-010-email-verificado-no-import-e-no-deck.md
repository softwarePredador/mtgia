# Receipt — BT-AUTH-010: e-mail verificado no import e na escrita de deck (evidência de código) — 2026-10-10

- **Estado no backlog:** `IMPLEMENTED_LOCAL_PENDING_FULL_GATE`.
- **O que é:** evidência de código, conferida só por leitura no `master` `1f525a1c1`. Nenhum gate rodou nesta sessão, e nada tocou a produção.
- **O que falta para o PASS:** o `full` verde no SHA candidato. A tarefa não tem superfície de UI própria.
- **Por que este receipt existe:** a linha do backlog não tinha receipt próprio (divergência DIV-07 do mapa de 2026-10-10).

## O que o código faz

`/import` e `/import/*` passam pela mesma verificação de e-mail do fichário. Pela D-56, toda escrita de conteúdo de deck também exige e-mail verificado. Ficam livres ler e apagar o próprio deck, os cálculos do servidor sobre a lista atual e os registros privados de partida.

## Commits

Todos são ancestrais do `master` `1f525a1c1`.

| Commit | Data | Assunto |
| --- | --- | --- |
| `166aaed57` | 2026-09-23 | fix(BT-AUTH-010): require a verified e-mail for deck import |
| `bedafe8bf` | 2026-09-23 | fix(BT-AUTH-010): require a verified e-mail to write deck content |

## Testes que cobrem o aceite

- `server/test/import_verified_email_test.dart`: conta não verificada recebe 403 `email_verification_required` em `/import`, `/import/to-deck` e `/import/validate` sem o handler rodar.
- `server/test/email_verification_contract_test.dart`: a lista estrutural das rotas protegidas.
- `server/test/deck_write_verified_email_test.dart`: a tabela de todas as rotas de `server/routes/decks` falha se aparecer rota sem classificação; pela linha, 4 mutações falham.
- `server/test/email_verification_live_test.dart`: teste vivo contra API e PostgreSQL locais.

## Outros arquivos

- `server/lib/deck_write_verification_policy.dart`: a regra.
- `docs/qa/execution/2026-09-23/deploy-seguranca-d19.md`: o import no ar desde 2026-09-23 às 08:08 UTC.
- `docs/qa/execution/2026-09-23/host-xmage-e-reinicio.md`: a escrita de deck no ar desde as 11:01 UTC (`22a7749a7`).

## Gate mais recente

O `full` de 2026-10-09 sobre `1f525a1c1` (log `verifica_master_full.log` da coordenação, fora do repositório) terminou com `full_rc=1`. O `flutter analyze` do app não teve achados, e as etapas do servidor e do app ficaram verdes (no app, `+1787` com 1 teste pulado). O gate caiu no `npm audit` do site público (D-115), e por isso não rodaram `ui-audit`, `custom-lint`, `patrol-smoke`, a auditoria de dependências e o gate de schema. O log não lista cada arquivo de teste, e esta sessão não rodou os testes citados neste receipt. Isso não vale como `PASS`.

## Segue aberto

- O reenvio da verificação nas telas de deck, no PR-C (`BT-UX-BATCH-001`).
