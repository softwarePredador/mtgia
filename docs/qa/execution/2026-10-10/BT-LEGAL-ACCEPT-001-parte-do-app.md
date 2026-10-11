# Receipt — BT-LEGAL-ACCEPT-001: reaceite legal, parte do app (evidência de código) — 2026-10-10

- **Estado no backlog:** `IMPLEMENTED_LOCAL_PENDING_FULL_GATE`.
- **O que é:** evidência de código, conferida só por leitura no `master` `1f525a1c1`. Nenhum gate rodou nesta sessão, e nada tocou a produção.
- **O que falta para o PASS:** o `full` verde no SHA candidato. O PASS também espera a recaptura da prova de UI: a R1 para o que já está no `master`, ou a R2 para o que entra no PR-C (D-92).
- **Por que este receipt existe:** a linha do backlog não tinha receipt próprio (divergência DIV-07 do mapa de 2026-10-10).

## O que o código faz

O app mostra o diálogo de reaceite quando o servidor responde `legal_acceptance_required`. A tela só aceita a versão de Termos e Privacidade que o próprio app traz para leitura (D-97, item 25 da coordenação). O servidor já tem receipt próprio em `docs/qa/execution/2026-09-28/BT-LEGAL-ACCEPT-001-servidor.md`.

## Commits

Todos são ancestrais do `master` `1f525a1c1`.

| Commit | Data | Assunto |
| --- | --- | --- |
| `24f4e4c9f` | 2026-10-05 | BT-LEGAL-ACCEPT-001 (app side): re-acceptance prompt and 403 handling |

## Testes que cobrem o aceite

- `app/test/features/auth/providers/legal_acceptance_provider_test.dart`: o provider do reaceite.
- `app/test/features/auth/widgets/legal_reacceptance_dialog_test.dart`: o diálogo.

## Gate mais recente

O `full` de 2026-10-09 sobre `1f525a1c1` (log `verifica_master_full.log` da coordenação, fora do repositório) terminou com `full_rc=1`. O `flutter analyze` do app não teve achados, e as etapas do servidor e do app ficaram verdes (no app, `+1787` com 1 teste pulado). O gate caiu no `npm audit` do site público (D-115), e por isso não rodaram `ui-audit`, `custom-lint`, `patrol-smoke`, a auditoria de dependências e o gate de schema. O log não lista cada arquivo de teste, e esta sessão não rodou os testes citados neste receipt. Isso não vale como `PASS`.

## Segue aberto

- O ponto de captura do diálogo, no PR-C (`BT-UX-BATCH-001`), e a prova de UI na R2 (D-92).
- Ligar `MANALOOM_LEGAL_REACCEPTANCE=enforce` depois do app publicado, com a palavra do dono.
