# Receipt — BT-REL-002: identidade de release, parte do app (evidência de código) — 2026-10-10

- **Estado no backlog:** `IMPLEMENTED_LOCAL_PENDING_FULL_GATE`.
- **O que é:** evidência de código, conferida só por leitura no `master` `1f525a1c1`. Nenhum gate rodou nesta sessão, e nada tocou a produção.
- **O que falta para o PASS:** o `full` verde no SHA candidato. O PASS também espera a recaptura da prova de UI: a R1 para o que já está no `master`, ou a R2 para o que entra no PR-C (D-92).
- **Por que este receipt existe:** a linha do backlog não tinha receipt próprio (divergência DIV-07 do mapa de 2026-10-10).

## O que o código faz

O `/app` e o Android comparam a identidade compilada com a que o servidor publica. Liberam só o que o backend e o artefato liberam, e negam o que o código não conhece. Com o digest divergente, mostram a faixa "Nova versão disponível" (D-13, D-97). O lado do servidor tem receipt próprio em `docs/qa/execution/2026-09-28/BT-REL-002-identidade-e-same-sha.md`.

## Commits

Todos são ancestrais do `master` `1f525a1c1`.

| Commit | Data | Assunto |
| --- | --- | --- |
| `e8feb30c7` | 2026-10-05 | BT-REL-002 (app side): compiled release identity and update strip |

## Testes que cobrem o aceite

- `app/test/core/config/release_identity_gate_test.dart`: o portão de identidade do app.

## Outros arquivos

- `app/lib/core/config/release_identity_gate.dart`: o portão.
- `app/lib/core/widgets/release_update_banner.dart`: a faixa.

## Gate mais recente

O `full` de 2026-10-09 sobre `1f525a1c1` (log `verifica_master_full.log` da coordenação, fora do repositório) terminou com `full_rc=1`. O `flutter analyze` do app não teve achados, e as etapas do servidor e do app ficaram verdes (no app, `+1787` com 1 teste pulado). O gate caiu no `npm audit` do site público (D-115), e por isso não rodaram `ui-audit`, `custom-lint`, `patrol-smoke`, a auditoria de dependências e o gate de schema. O log não lista cada arquivo de teste, e esta sessão não rodou os testes citados neste receipt. Isso não vale como `PASS`.

## Segue aberto

- O ponto de captura da faixa, no PR-C (`BT-UX-BATCH-001`), e a prova de UI na R2 (D-92).
- A primeira promoção real grava as identidades novas (lote).
