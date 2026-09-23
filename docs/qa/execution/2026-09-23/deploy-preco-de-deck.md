# Receipt: preço de deck pelo catálogo (D-62, D-73) em produção, 2026-09-23

- **Autorização:** o dono, na conversa de coordenação de 2026-09-23.
  - "Sim, antes de subir", para a D-73.
  - "Sim, mas aplicar às 06:20", para promover o `master` com `--no-verify`, fazer o deploy do backend e do ops, rodar o dry-run e deixar a execução diária aplicar os preços.
- **Executado por:** sessão coordenadora (Claude). Nenhum bucket e nenhuma conta foram criados.
- **Registro:** o primeiro rascunho deste receipt se perdeu num reinício da sessão, antes do commit. Esta versão foi refeita às 19:15 UTC a partir dos logs de deploy da própria sessão.

## O que subiu

`master` = `41bab49c9`, em avanço direto de `f52fdc970`. Os commits da frente de catálogo passaram pelos hooks:

| Commit | O que faz |
| --- | --- |
| `a73411dd1` | A linha-alias Oracle recebe o menor preço em papel, não foil, em USD, entre todas as impressões do bulk (D-62) |
| `dc2cedc80` | `POST /decks/:id/pricing` lê o preço do catálogo. Não chama a Scryfall e não escreve em `cards`. O total do deck continua gravado (D-72) |
| `168be9c70` | User-Agent `BrewTact/1.0 (+https://brewtact.com)` (D-64) |
| `fe49b976f` | O menor preço ignora impressões oversized e de borda dourada (D-73) |
| `b9428ea14` | Cada 404 `card_not_in_catalog` gera uma linha `MANALOOM_CATALOG_CARD_DEMAND`, sem dado do usuário (D-63) |

Também entraram dois registros da coordenação: `5366a4182`, da ativação do catálogo, e `41bab49c9`, das decisões D-72 a D-75.

## Verificação antes do deploy, na ponta `41bab49c9`

| Verificação | Resultado |
| --- | --- |
| Suíte do servidor, sem as tags live | 387 arquivos, **2.501 testes**, 0 falha |
| Python (daemon, catálogo, auditoria de Battle) | 109 |
| Contrato de ops | 32 |
| Testes de banco em PostgreSQL descartável | Dart: 26 (recuperação de senha, inventário, exportação, exclusão, relatório). Catálogo: JSON Lines e lista, 2 + 2 |

## Passos

| Hora (UTC) | Passo | Resultado |
| --- | --- | --- |
| 18:48:01 | Promoção com `git push --no-verify` (autorizado) | `f52fdc970..41bab49c9` |
| 18:48:08 a 18:53 | Deploy do backend | **deployed**: `cartinhas@sha256:d2a92de70a6870d137349d2b11ee1a42e00024a8185610422056964be6e0c55f`, `git_sha 41bab49c9` |
| 18:53:15 a 18:55 | Deploy do ops | **deployed**: `ops@sha256:208cb7f9393b8008c199c895cec53d5e967673e00462b80bb6abf00599f91fca`, com os dois jobs |
| 18:55:11 a 18:55:47 | Dry-run do catálogo | **rc 0**, `database_writes false`, catálogo com 0,41 dia |
| 18:56:07 | Observação externa | `/health` em `41bab49c9`, migration 058, 29/29 off. Login 401, relatório 404, export por GET 404. Os 20 endereços do Traefik iguais. Repetida às 19:10:09, igual |

## O que o dry-run planejou

A execução das 06:20 UTC aplica isto sozinha, sob o mesmo contrato de apply.

| Item | Valor |
| --- | ---: |
| Linhas-alias Oracle (para onde os decks apontam) | 34.074 |
| Recebem o menor preço em papel | 32.131 |
| Mantêm o valor atual: sem preço não foil em USD | 1.727 |
| Mantêm o valor atual: fora do bulk | 216 |
| Impressões tiradas pelo refino: oversized / borda dourada | 416 / 1.190 |
| Linhas-alias cujo preço mudaria sem o refino | 432 |
| Impressões exatas atualizadas | 4.871 |
| Cartas e sets novos | 0 / 0 |

As três categorias de linhas-alias somam 34.074: 32.131 + 1.727 + 216.

## O que continua aberto

- **Conferir a execução das 06:20 UTC de 2026-09-24:** a linha `catalog_reference:alias_prices` no `sync_log` e as contagens no receipt.
- **Memorabilia de borda preta** (Collectors' Edition, 30th Anniversary Edition): ainda entra no menor preço. Costuma ser cara, então não deve baratear, mas o dono pode medir e decidir.
- **Batch sem linha de demanda:** `POST /cards/resolve/batch` responde 200 com `unresolved` e não gera a linha de demanda.
- **D-74 e D-75:** a D-74 (códigos de set duplicados) e a D-75 (`price_history`) aguardam execução.
