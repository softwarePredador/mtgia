# Receipt — BT-PRIV-003: inventário de retenção legível por máquina (evidência de código) — 2026-10-10

- **Estado no backlog:** `IMPLEMENTED_LOCAL_PENDING_FULL_GATE`.
- **O que é:** evidência de código, conferida só por leitura no `master` `1f525a1c1`. Nenhum gate rodou nesta sessão, e nada tocou a produção.
- **O que falta para o PASS:** o `full` verde no SHA candidato. A tarefa não tem superfície de UI própria.
- **Por que este receipt existe:** a linha do backlog não tinha receipt próprio (divergência DIV-07 do mapa de 2026-10-10).

## O que o código faz

O inventário cobre as 79 tabelas do schema versionado. Cada uma tem finalidade, dono, prazo, quem apaga, exportação, exclusão e exceção legal. Também entram as views, as tabelas que só existem na produção e 13 artefatos fora do banco.

## Commits

Todos são ancestrais do `master` `1f525a1c1`.

| Commit | Data | Assunto |
| --- | --- | --- |
| `c952b375f` | 2026-09-23 | feat(BT-PRIV-003): add a machine-readable retention inventory checked against the schema |

## Testes que cobrem o aceite

- `server/test/privacy_data_inventory_test.dart`: contra o schema do manifesto, os prazos decididos e o serviço de exclusão.
- `server/test/privacy_data_inventory_db_live_test.dart`: contra PostgreSQL descartável; tabela ou coluna nova no banco faz o teste falhar.

## Outros arquivos

- `docs/privacy/data_retention_inventory.json`: o inventário.
- `docs/privacy/INVENTARIO_DE_RETENCAO.md`: o resumo.

## Gate mais recente

O `full` de 2026-10-09 sobre `1f525a1c1` (log `verifica_master_full.log` da coordenação, fora do repositório) terminou com `full_rc=1`. O `flutter analyze` do app não teve achados, e as etapas do servidor e do app ficaram verdes (no app, `+1787` com 1 teste pulado). O gate caiu no `npm audit` do site público (D-115), e por isso não rodaram `ui-audit`, `custom-lint`, `patrol-smoke`, a auditoria de dependências e o gate de schema. O log não lista cada arquivo de teste, e esta sessão não rodou os testes citados neste receipt. Isso não vale como `PASS`.

## Segue aberto

- Os prazos da D-69 com o advogado. Pela D-107, o parecer é pedido já; sem ele a tempo, a coorte entra com a telemetria do app desligada.
