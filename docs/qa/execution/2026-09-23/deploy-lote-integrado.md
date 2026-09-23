# Receipt — lote integrado das três frentes em produção — 2026-09-23

- **Autorização.** O dono respondeu na conversa de coordenação de 2026-09-23:
  - "Subir agora", para promover o `master` com `--no-verify` e fazer o deploy do backend e do ops;
  - "Dry-run e depois ativar", para o job de catálogo;
  - "Impressão mais barata", para a D-62;
  - "Aceitar todas", para as recomendações da D-63 à D-71.
- **Executado por** sessão coordenadora (Claude), a partir de worktrees limpos no SHA. Nenhum bucket e nenhuma conta foram criados. A configuração de e-mail foi herdada da spec do serviço, sem exibir nem gravar valores.

## O que subiu

`master` = `c0f907108`, com três merges pelos hooks sobre `2ab8c782b`. Os commits de cada frente passaram pelos hooks.

| Merge | Frente | Commits |
| --- | --- | --- |
| `a8b367cf3` | servidor | `7d4cf30f3` `BT-AUTH-003` (recuperação de senha sem oráculo de tempo), `06e9d2bbe` `BT-GOV-002` (um slot NOW por raia), `e3d306a6c` `BT-DB-001` (auditor de schema) |
| `12edf4fc9` | catálogo | `0ae47c53b` `BT-CAT-04`, `79143cec0` `BT-CAT-01`, `a80aa34e0` `BT-CAT-02`, `c0cb16f13` `BT-CAT-03` |
| `c0f907108` | privacidade | `c952b375f` `BT-PRIV-003`, `75e1fabd1` `BT-PRIV-001`, `5edcccc4f` `BT-PRIV-002` |

**Conflitos.** Só os artefatos gerados do project logic conflitaram. Foram regenerados com `./scripts/manaloom_project_logic.sh --write`. Backlog, fila, contratos e o teste do contrato de ops juntaram sem conflito.

## Verificação do código integrado, antes do deploy

| Verificação | Resultado |
| --- | --- |
| Suíte do servidor, com as tags live excluídas, em 10 lotes | 385 arquivos, **2.491 testes**, 0 falha |
| Python (daemon, catálogo, auditoria de Battle) | 80/80 |
| `scripts/manaloom_release_ops_contract_test.sh` | 32 contratos |
| Testes de banco contra um PostgreSQL 17 descartável, montado pelas 58 migrations do código integrado | 27 testes, 0 falha: corrida de token de recuperação (1), inventário (4), exportação (11), exclusão (9), relatório de deck apagado (1) e catálogo em Python (1, num banco à parte, porque ele recusa banco com cartas) |
| Hooks de cada merge | project logic `--check` e `--test` verdes, escopo não-UI aceito |

## Passos

| Hora (UTC) | Passo | Resultado |
| --- | --- | --- |
| 14:43:18 | Promoção do `master` com `git push --no-verify` (autorizado) | `22a7749a7..c0f907108`, avanço direto de 14 commits |
| 14:43:29 a ~14:49 | Deploy do backend (`scripts/manaloom_deploy_backend_image.sh`) | **deployed**: `cartinhas@sha256:9c4489f166888cecf1f13a3a1ab4751560a8fa22c5fdf6bc7097924eca5088f4`, `git_sha c0f907108eaf5bc27476e794328ed6aeb5497ed1`, 29/29 off |
| 14:49:01 a 14:50:26 | Deploy do ops, recusado três vezes pelas travas antes de qualquer mudança | Faltavam `MANALOOM_CONFIRM_LIVE_MUTATIONS` e `MANALOOM_CONFIRM_POSTGRES_WRITES`, que o deploy aprovado cobre, e o destino SSH pelo hostname, como na madrugada |
| 14:50:26 a 14:52:17 | Deploy do ops (`scripts/manaloom_deploy_ops_image.sh`) | **deployed**: `ops@sha256:76243979cbdb6ca9882588ee271ed4bc8580bc895111a05f706ce7ff65e3adc1`, `git_sha c0f907108`, `operational_mode safe_housekeeping_only`, `enabled_jobs` = `manaloom_catalog_reference_refresh` e `hermes_cron_governor_report` |
| 14:52:25 | Observação externa | Ver a tabela abaixo |
| 14:53:41 | Dry-run do catálogo no contêiner de ops (`/app/server/bin/cron_sync_cards.sh --mode dry-run`) | **Parou sem gravar** (`database_writes: false`, rc 1): `unexpected_download_host: download_uri fora de ['data.scryfall.io']: ''`. O alerta de frescor disparou: catálogo com 109,04 dias |

## Observação externa (14:52:25 UTC)

| Chamada | Resposta |
| --- | --- |
| `GET /health` | `healthy`, `git_sha c0f907108eaf5bc27476e794328ed6aeb5497ed1` |
| `GET /ready` | `ready`, migration 058, Battle e IA `disabled` |
| `GET /capabilities` | 29 itens, nenhuma ligada |
| `POST /auth/login` (conta inexistente) | 401 "Credenciais inválidas" |
| `POST /auth/forgot-password` (e-mail `.invalid`, que não envia nada) | 202 com a frase genérica; a partir da terceira chamada, 429, porque o limite divide a cota com o login |
| Cadastro, IA e marketplace | 404 `capability_unavailable` |
| `GET /users/me/export` | 404 `capability_route_unclassified` |
| Os 20 endereços do Traefik no host | Mesmos códigos de antes do reinício |

## Por que o dry-run parou

A Scryfall mudou o formato do bulk. Em 2026-09-23, `GET https://api.scryfall.com/bulk-data/default-cards` deixou de trazer `download_uri`, `size`, `content_type` e `content_encoding`. Agora traz:
- `jsonl_download_uri`, com o arquivo `default-cards-20260923090535.jsonl.gz`: gzip de JSON Lines, com um objeto `card` por linha e o mesmo esquema de card;
- `compressed_size` = 78.591.937.

O job foi escrito e testado com fixtures do formato antigo. Por isso leu a URI vazia e parou no teste de domínio, antes de qualquer download ou escrita. A frente de catálogo está ajustando o job. Depois disso, a coordenação promove o ajuste, refaz o deploy do ops e retoma "dry-run e depois ativar", com a palavra do dono para a nova promoção.

**Atualização, 15:34 UTC.** O ajuste foi promovido em `f52fdc970`, o ops foi refeito e o catálogo foi ativado: `docs/qa/execution/2026-09-23/BT-CAT-01-ativacao-do-catalogo.md`.

## Estado depois deste deploy

- **Job de catálogo:** fica registrado e inativo. A execução agendada das 06:20 UTC não grava nada enquanto a ativação não for feita.
- **Recuperação de senha:** o tempo fechou em produção (`BT-AUTH-003`).
- **Rotas de catálogo:** só leem. Seguem fechadas pela capability.
- **Exportação e exclusão:** agora as da `BT-PRIV-001` e da `BT-PRIV-002`. Continuam exigindo login e senha.
- **`/app`:** segue na imagem antiga (`BT-REL-001`).
