# Receipt — BT-NAV-02: o refresh de capabilities não expulsa o usuário (evidência de código) — 2026-10-10

- **Estado no backlog:** `IMPLEMENTED_LOCAL_PENDING_FULL_GATE`.
- **O que é:** evidência de código, conferida só por leitura no `master` `1f525a1c1`. Nenhum gate rodou nesta sessão, e nada tocou a produção.
- **O que falta para o PASS:** o `full` verde no SHA candidato. O PASS também espera a recaptura da prova de UI: a R1 para o que já está no `master`, ou a R2 para o que entra no PR-C (D-92).
- **Por que este receipt existe:** a linha do backlog não tinha receipt próprio (divergência DIV-07 do mapa de 2026-10-10).

## O que o código faz

Enquanto um refresh de `/capabilities` está em voo, o provider mantém a matriz já carregada. Retomar o app não expulsa o usuário de `/notifications`, `/decks` nem `/collection`.

## Commits

Todos são ancestrais do `master` `1f525a1c1`.

| Commit | Data | Assunto |
| --- | --- | --- |
| `fba7c090e` | 2026-10-05 | BT-NAV-02: keep the loaded capability matrix while a refresh is in flight |
| `063e1c4e3` | 2026-10-08 | port(BT-NAV-02): cover the play-vs-ai table in the capability refresh tests |

## Testes que cobrem o aceite

- `app/test/core/config/release_capabilities_test.dart`: rota com refresh em andamento, inclusive a mesa do Jogar contra IA.

## Gate mais recente

O `full` de 2026-10-09 sobre `1f525a1c1` (log `verifica_master_full.log` da coordenação, fora do repositório) terminou com `full_rc=1`. O `flutter analyze` do app não teve achados, e as etapas do servidor e do app ficaram verdes (no app, `+1787` com 1 teste pulado). O gate caiu no `npm audit` do site público (D-115), e por isso não rodaram `ui-audit`, `custom-lint`, `patrol-smoke`, a auditoria de dependências e o gate de schema. O log não lista cada arquivo de teste, e esta sessão não rodou os testes citados neste receipt. Isso não vale como `PASS`.

## Segue aberto

- No boot, o router decide pela foto da matriz, que começa negando tudo (`app/lib/main.dart:446-450`). É uma inferência do código, sem prova em runtime, e o conserto vai no PR-C (`BT-UX-BATCH-001`).
- A prova de UI na R1.
