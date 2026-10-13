# Receipt — BT-NAV-03: a primeira tela autenticada tem saída (evidência de código) — 2026-10-10

- **Estado no backlog:** `IMPLEMENTED_LOCAL_PENDING_FULL_GATE`.
- **O que é:** evidência de código, conferida só por leitura no `master` `1f525a1c1`. Nenhum gate rodou nesta sessão, e nada tocou a produção.
- **O que falta para o PASS:** o `full` verde no SHA candidato. O PASS também espera a recaptura da prova de UI: a R1 para o que já está no `master`, ou a R2 para o que entra no PR-C (D-92).
- **Por que este receipt existe:** a linha do backlog não tinha receipt próprio (divergência DIV-07 do mapa de 2026-10-10).

## O que o código faz

Sem meta de onboarding aberta, `/onboarding/core-flow` manda para `/home` quando o `/capabilities` responde. A tela mostra "Nenhum caminho aberto nesta fase da beta" com "Ir para o início". A primeira coorte mantém as quatro metas e o atalho para a Home.

## Commits

Todos são ancestrais do `master` `1f525a1c1`.

| Commit | Data | Assunto |
| --- | --- | --- |
| `f3f6f1a95` | 2026-10-05 | BT-NAV-03: the first authenticated screen is never a dead end |

## Testes que cobrem o aceite

- `app/test/features/home/onboarding_goal_policy_test.dart`: a regra das metas.
- `app/test/features/home/onboarding_core_flow_screen_test.dart`: o fluxo da tela.

## Outros arquivos

- `app/lib/features/home/onboarding_goal_policy.dart`: a regra compartilhada pela rota e pela tela.

## Gate mais recente

O `full` de 2026-10-09 sobre `1f525a1c1` (log `verifica_master_full.log` da coordenação, fora do repositório) terminou com `full_rc=1`. O `flutter analyze` do app não teve achados, e as etapas do servidor e do app ficaram verdes (no app, `+1787` com 1 teste pulado). O gate caiu no `npm audit` do site público (D-115), e por isso não rodaram `ui-audit`, `custom-lint`, `patrol-smoke`, a auditoria de dependências e o gate de schema. O log não lista cada arquivo de teste, e esta sessão não rodou os testes citados neste receipt. Isso não vale como `PASS`.

## Segue aberto

- A prova de UI na R1.
