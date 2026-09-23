# Receipt: ativação do job de catálogo em produção (`BT-CAT-01`), 2026-09-23

- **Autorização.** O dono deu duas respostas na conversa de coordenação de 2026-09-23:
  - "Dry-run e depois ativar": ativar o job só se o receipt do dry-run viesse coerente.
  - "Sim, quando passar": promover o ajuste do formato da Scryfall com `--no-verify` e refazer o deploy do ops depois dos testes.
- **Contrato.** Vale o contrato de apply da D-33 e da D-34, `catalog_reference_apply_v1`. O job só grava dado de referência (cartas, sets, legalidades e preços) e as próprias `sync_log` e `sync_state`. Faz upsert idempotente, numa transação com advisory lock. Nunca toca tabela de usuário.
- **Executado por** sessão coordenadora (Claude). Nenhum bucket nem conta foi criado.

## Por que houve uma segunda promoção

O primeiro dry-run, às 14:53:41 UTC em `c0f907108`, parou antes de baixar qualquer coisa. A Scryfall passou a publicar o bulk em JSON Lines, em `jsonl_download_uri` (FATOS 11.25). A frente de catálogo ajustou o job em `96bb03aca`:
- prefere o JSONL e mantém a lista antiga como alternativa;
- aceita as duas URIs só em `data.scryfall.io`;
- dá um erro próprio quando falta URI;
- confere `compressed_size` no orçamento;
- reconhece gzip pelo conteúdo.

A mudança veio com 21 testes novos e 8 mutações derrubadas.

Antes da promoção, o código integrado em `f52fdc970` passou em tudo:
- Python, 101 de 101;
- contrato de ops, 32;
- teste de banco do catálogo nos dois formatos, contra PostgreSQL novo;
- hook do merge.

## Passos

| Hora (UTC) | Passo | Resultado |
| --- | --- | --- |
| 15:28:32 | Promoção do `master` com `git push --no-verify` (autorizado) | `c0f907108..f52fdc970`: o registro dos documentos (`0f34a703d`) e o ajuste (`96bb03aca`) |
| 15:28:39 a ~15:30 | Deploy só do ops | **deployed**: `ops@sha256:da121d48d855e02240de9c26da357018300c9126464c618b32c3b634e415ea0c`, `git_sha f52fdc970`, com os mesmos dois jobs. O backend segue em `c0f907108`, porque o ajuste não o altera |
| 15:30:33 a 15:31:12 | Dry-run no contêiner de ops | **rc 0**, `status dry_run`, `database_writes false`. Arquivo `default-cards-20260923090535.jsonl.gz`: 78.591.937 bytes compactados e 632.809.496 abertos, sha256 `98891c7b…6ce9`. 2 requisições, as duas 200 |
| 15:32:24 a 15:34:07 | Ativação (`--mode activate`, com `MANALOOM_CONFIRM_POSTGRES_WRITES`) | **rc 0**, `status activated`, sem erro. O catálogo passou a ter 0,27 dia, com a fonte de 09:05 UTC, e o alerta de frescor apagou |
| ~15:36 | Conferência direta no banco, só leitura (`server/bin/with_new_server_pg.sh --read-only psql`) | Ver a tabela abaixo |

## O que o dry-run planejou e a ativação gravou

| Item | Planejado | Gravado |
| --- | ---: | ---: |
| Objetos no bulk | 118.389 | — |
| Cartas novas (2.016 inéditas e 2.601 impressões de sets desde 2026-05-30) | 4.617 | 4.617 inseridas |
| Impressões exatas atualizadas | 254 | 254 |
| Sets novos | 20 | 20 |
| Legalidades (35.358 cartas Oracle, 813.234 linhas enviadas) | — | 501.977 inseridas, 2.875 atualizadas |
| Impressões antigas de cartas que já existem (fase 2 da D-35) | 97.723 puladas | — |
| Objetos que não são carta de papel | 15.795 pulados | — |

## Conferência no banco (só leitura)

| Tabela | Agora | Conta |
| --- | ---: | --- |
| `cards` | 38.948 | 34.331 + 4.617 |
| `sets` | 971 linhas, 887 códigos distintos sem diferença de caixa | 951 + 20 e 867 + 20 |
| `card_legalities` | 895.744 | legal 406.836, not_legal 486.870, banned 1.849, restricted 189 |
| `users` e `decks` | 1.181 e 326 | Iguais ao ensaio de restauração de 00:52 UTC: nada fora do contrato foi tocado |
| último `sync_log` | `catalog_reference:cards success`, 15:32:24 UTC | — |

**Ponto de restauração:** o backup das 00:51 UTC, com ensaio aprovado (`BT-REL-000`), guarda o estado anterior dessas tabelas. Elas não mudavam desde 2026-06-06.

## O que continua aberto

- **Preço dos decks.** As 34.074 linhas-alias Oracle, que são para onde os decks apontam, ainda não têm o preço atualizado. A regra está decidida desde a D-62 (impressão em papel mais barata), mas falta implementar. Junto vem a troca de `POST /decks/:id/pricing`, que ainda chama a Scryfall a pedido do usuário.
- **Códigos de set duplicados.** 84 códigos se repetem só por maiúscula ou minúscula: são 971 linhas para 887 códigos. O defeito já existia antes; o job compara sem caixa e não duplica mais.
- **Legalidades agora completas.** Antes, a tabela tinha lacunas: carta sem linha num formato era tratada como legal por consultas como a do otimizador (`OR cl.status IS NULL`). Com as linhas `not_legal` explícitas, essas consultas passam a excluir o que não é legal.
- **Job diário.** Às 06:20 UTC ele aplica sozinho, sob o mesmo contrato. Se o catálogo passar de 7 dias, ele alerta.
