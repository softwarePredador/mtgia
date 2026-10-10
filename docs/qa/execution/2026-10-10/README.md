# Receipts de evidência de código — 2026-10-10

Estes receipts fecham a divergência DIV-07 do mapa de 2026-10-10. Cobrem tarefas em `IMPLEMENTED_LOCAL_PENDING_FULL_GATE` que não tinham receipt próprio no backlog.

- **Como foram feitos:** só por leitura no `master` `1f525a1c1`. Cada commit citado é ancestral dele, e cada arquivo citado existe nele.
- **O que não houve:** nenhum gate rodou, e nada tocou a produção.
- **O que muda:** nenhuma tarefa muda para `PASS`. O `PASS` espera o `full` verde e, nas tarefas de UI, a recaptura da prova de UI (D-92).

| Tarefa | Receipt | Assunto |
| --- | --- | --- |
| BT-GOV-002 | [BT-GOV-002-fila-com-duas-raias.md](BT-GOV-002-fila-com-duas-raias.md) | fila com duas raias |
| BT-OFFER-001 | [BT-OFFER-001-oferta-unica.md](BT-OFFER-001-oferta-unica.md) | oferta pública única da beta gratuita |
| BT-DOC-006 | [BT-DOC-006-terceiro-portao.md](BT-DOC-006-terceiro-portao.md) | terceiro portão de capability no mapa operacional |
| BT-AUTH-010 | [BT-AUTH-010-email-verificado-no-import-e-no-deck.md](BT-AUTH-010-email-verificado-no-import-e-no-deck.md) | e-mail verificado no import e na escrita de deck |
| BT-PRIV-003 | [BT-PRIV-003-inventario-de-retencao.md](BT-PRIV-003-inventario-de-retencao.md) | inventário de retenção legível por máquina |
| DCK-P0-00 | [DCK-P0-00-contencao-do-deck.md](DCK-P0-00-contencao-do-deck.md) | contenção do ciclo de deck, servidor e app |
| DCK-P0-01 | [DCK-P0-01-revisao-e-ledger-do-deck.md](DCK-P0-01-revisao-e-ledger-do-deck.md) | revisão otimista, ledger e desfazer no servidor |
| DCK-P0-02 | [DCK-P0-02-artefato-de-revisao.md](DCK-P0-02-artefato-de-revisao.md) | DeckReviewArtifact v1 |
| DCK-P0-03 | [DCK-P0-03-import-em-duas-fases.md](DCK-P0-03-import-em-duas-fases.md) | import em deck existente em duas fases |
| DCK-P0-07 | [DCK-P0-07-sessao-isolada-no-deck.md](DCK-P0-07-sessao-isolada-no-deck.md) | estado de deck isolado por sessão |
| BT-UX-IMG-001 | [BT-UX-IMG-001-contrato-de-imagem-de-carta.md](BT-UX-IMG-001-contrato-de-imagem-de-carta.md) | contrato image-led de carta |
| BT-UX-ERR-001 | [BT-UX-ERR-001-frase-do-servidor.md](BT-UX-ERR-001-frase-do-servidor.md) | frase do servidor em vez de código cru |
| BT-ART-01 | [BT-ART-01-arte-e-scryfall.md](BT-ART-01-arte-e-scryfall.md) | contrato de arte e o portão da Scryfall |
| BT-NAV-02 | [BT-NAV-02-refresh-de-capabilities.md](BT-NAV-02-refresh-de-capabilities.md) | o refresh de capabilities não expulsa o usuário |
| BT-NAV-03 | [BT-NAV-03-onboarding-com-saida.md](BT-NAV-03-onboarding-com-saida.md) | a primeira tela autenticada tem saída |
| BT-CAT-04 | [BT-CAT-04-printings-so-leitura.md](BT-CAT-04-printings-so-leitura.md) | `GET /cards/printings` só lê |
| BT-OBS-001 | [BT-OBS-001-slos-e-alertas.md](BT-OBS-001-slos-e-alertas.md) | SLOs e alertas de API, banco, jobs, cache e catálogo |
| BT-DB-002 | [BT-DB-002-preflight-de-migration.md](BT-DB-002-preflight-de-migration.md) | disciplina de migration: preflight, payload e pós-checagem |
| BT-CI-001 | [BT-CI-001-project-logic-no-bootstrap-frio.md](BT-CI-001-project-logic-no-bootstrap-frio.md) | project logic no bootstrap frio |
| BT-LEGAL-ACCEPT-001 | [BT-LEGAL-ACCEPT-001-parte-do-app.md](BT-LEGAL-ACCEPT-001-parte-do-app.md) | reaceite legal, parte do app |
| BT-REL-002 | [BT-REL-002-parte-do-app.md](BT-REL-002-parte-do-app.md) | identidade de release, parte do app |
| BT-AUTH-007 | [BT-AUTH-007-teste-de-app.md](BT-AUTH-007-teste-de-app.md) | o teste de app da troca de senha (com o teste novo; não é só evidência de código) |

**Ficaram de fora, e por quê:**
- **`BT-AUTH-004` e `BT-PRIV-001`:** as linhas são do PR-B, que muda a exportação no app (B8).
- **`BT-WEB-003`:** a frente do site faz o bump da D-115 e o receipt same-SHA.
- **`BT-UX-KIT-001`:** a tarefa está em `TODO`, e a linha é do PR-B.
- **`BT-CAT-02` e `BT-SCN-00`:** estão em `IN_PROGRESS_CONTAINED`.
