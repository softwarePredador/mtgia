# Receipt — BT-OFFER-001: oferta pública única da beta gratuita (evidência de código) — 2026-10-10

- **Estado no backlog:** `IMPLEMENTED_LOCAL_PENDING_FULL_GATE`.
- **O que é:** evidência de código, conferida só por leitura no `master` `1f525a1c1`. Nenhum gate rodou nesta sessão, e nada tocou a produção.
- **O que falta para o PASS:** o `full` verde no SHA candidato. A tarefa não tem superfície de UI própria.
- **Por que este receipt existe:** a linha do backlog não tinha receipt próprio (divergência DIV-07 do mapa de 2026-10-10).

## O que o código faz

A oferta única é a beta gratuita (`offer_mode: free_beta_no_commerce` em `server/config/release_capabilities.json`). Checkout, assinatura e paywall ficam inacessíveis. O commit de implementação é o mesmo do `BT-GOV-001`, e até aqui a linha só citava o receipt dele.

## Commits

Todos são ancestrais do `master` `1f525a1c1`.

| Commit | Data | Assunto |
| --- | --- | --- |
| `fd0397a5a` | 2026-08-24 | fix(release): enforce controlled free beta surfaces |

## Testes que cobrem o aceite

- `server/test/release_capability_policy_test.dart`: a política carrega `free_beta_no_commerce` e o `/capabilities` responde com ela.
- `app/test/core/config/release_capabilities_test.dart`: o app só aceita a matriz do servidor com `offer_mode` igual a `free_beta_no_commerce` (`_hasValidEnvelope` em `app/lib/core/config/release_capabilities.dart`), e o teste usa essa matriz.
- `web-public/tests/free-beta-offer-contract.mjs`: o contrato da oferta no site público.

## Outros arquivos

- `docs/qa/execution/2026-08-14/BT-GOV-001.md`: o receipt da decisão corrente que a linha citava.

## Gate mais recente

O `full` de 2026-10-09 sobre `1f525a1c1` (log `verifica_master_full.log` da coordenação, fora do repositório) terminou com `full_rc=1`. O `flutter analyze` do app não teve achados, e as etapas do servidor e do app ficaram verdes (no app, `+1787` com 1 teste pulado). O gate caiu no `npm audit` do site público (D-115), e por isso não rodaram `ui-audit`, `custom-lint`, `patrol-smoke`, a auditoria de dependências e o gate de schema. O log não lista cada arquivo de teste, e esta sessão não rodou os testes citados neste receipt. Isso não vale como `PASS`.

## Segue aberto

- Prova same-SHA do site, que depende do `BT-WEB-001` e do `npm audit` do `BT-WEB-003` (D-115).
