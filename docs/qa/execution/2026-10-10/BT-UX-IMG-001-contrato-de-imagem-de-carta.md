# Receipt — BT-UX-IMG-001: contrato image-led de carta (evidência de código) — 2026-10-10

- **Estado no backlog:** `IMPLEMENTED_LOCAL_PENDING_FULL_GATE`.
- **O que é:** evidência de código, conferida só por leitura no `master` `1f525a1c1`. Nenhum gate rodou nesta sessão, e nada tocou a produção.
- **O que falta para o PASS:** o `full` verde no SHA candidato. O PASS também espera a recaptura da prova de UI: a R1 para o que já está no `master`, ou a R2 para o que entra no PR-C (D-92).
- **Por que este receipt existe:** a linha do backlog não tinha receipt próprio (divergência DIV-07 do mapa de 2026-10-10).

## O que o código faz

Todas as superfícies de carta usam o mesmo widget: proporção 63:88, `contain`, impressão exata primeiro, fallback rotulado, nome sem imagem e sem salto de layout.

## Commits

Todos são ancestrais do `master` `1f525a1c1`.

| Commit | Data | Assunto |
| --- | --- | --- |
| `40e14dda2` | 2026-10-05 | BT-UX-IMG-001: one image-led card contract for every card surface |

## Testes que cobrem o aceite

- `app/test/core/widgets/card_artwork_test.dart`: o contrato do widget.
- `app/test/core/widgets/card_image_source_policy_guard_test.dart`: a guarda de fonte que barra `cover`/`fill` nos widgets de carta.

## Outros arquivos

- `app/lib/core/widgets/card_artwork.dart`: o widget.

## Gate mais recente

O `full` de 2026-10-09 sobre `1f525a1c1` (log `verifica_master_full.log` da coordenação, fora do repositório) terminou com `full_rc=1`. O `flutter analyze` do app não teve achados, e as etapas do servidor e do app ficaram verdes (no app, `+1787` com 1 teste pulado). O gate caiu no `npm audit` do site público (D-115), e por isso não rodaram `ui-audit`, `custom-lint`, `patrol-smoke`, a auditoria de dependências e o gate de schema. O log não lista cada arquivo de teste, e esta sessão não rodou os testes citados neste receipt. Isso não vale como `PASS`.

## Segue aberto

- A prova de UI na R1 e a régua visual da R2.
