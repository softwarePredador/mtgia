# Receipt — linha de base contida em produção (`BT-REL-000`) — 2026-09-23

- **Autorização:** dono do projeto, nesta conversa de coordenação, em 2026-09-22.
  - "o que tiver de subir no servidor pode subir, mas não deve criar bucket no servidor";
  - "Sim, promover com --no-verify", para promover a `master`;
  - "Ler só essa chave do .env", para a âncora do EasyPanel;
  - "o disparo de email você tem total autonomia", para a configuração de e-mail.
  - Nenhuma conta foi criada. A configuração de e-mail foi herdada da spec do próprio serviço em
    produção, sem exibir nem gravar valores.
- **Executado por:** sessão coordenadora (Claude), a partir de um worktree limpo no SHA do deploy.
  A árvore principal, onde outra sessão trabalhava, não foi tocada.
- **SHA implantado:** `87fd5a2e6126371c7e2841a8d2fc25405d453cb6`. É o `origin/master`, promovido
  de `704c2c11c` em avanço direto de 36 commits. Contém a branch de trabalho (`b86df8a20`) e o
  conserto do gate de Battle (`87fd5a2e6`).
- **Ordem:** antecipada em relação ao backlog, que punha o `BT-REL-000` depois do `BT-SCP-001`.
  A decisão foi do dono ("pode subir"). Ele também vetou o bucket, então o backup ficou local e
  sem cifra.

## Linha de base antes (2026-09-22 23:58 UTC, `GET` público)

`/health` com `git_sha a6ee09c8f` (2026-08-03); `/ready` com `latest_migration 057`;
`/capabilities` 404; cadastro sem trava; IA e worker de Battle ligados
(`docs/verdade/FATOS.md` 11.16–11.17).

## Passos

| Hora (UTC) | Passo | Resultado |
| --- | --- | --- |
| até 2026-09-23 00:00 | Suíte determinística do servidor em `b86df8a20` (mesmo perfil do gate: tags live excluídas) | 362 arquivos, **2.376 testes**, 0 falhas, 0 pulados |
| até 00:34 | `scripts/manaloom_battle_product_gate.sh`, que o deploy roda | Falhava desde `f6f791098`: marcador `_simulationMetrics(` renomeado. Consertado em `87fd5a2e6`; gate **pass, 46 checks** |
| — | Promoção a `master` com `git push --no-verify` (autorizado) | `704c2c11c..87fd5a2e6` |
| entre 00:34 e 00:51 | Status das migrations em produção (`with_new_server_pg.sh --read-only … migrate.dart --status`) | 57 executadas; só a **058** pendente |
| 00:51–00:52 | Backup (`scripts/manaloom_easypanel_backup.sh`) | `backups/manaloom-postgres/manaloom-postgres-20260923T005128Z.dump`: 315.645.906 bytes; sha256 `2df51b464f28b9068ba1f492931999fa48f1b5275a18ab4e9a3e69ed2f13f836`. Local, `chmod 600`, fora do git, **sem cifra**; validado por `pg_restore --list` (PG 17) |
| 00:52–00:53 | Ensaio de restauração completo (`scripts/manaloom_full_restore_drill.sh --execute`, PG 17 em container sem rede) | **passed**, 51 s: 99 tabelas, 97 FKs, 1,98 GB; users 1.181, cards 34.331, decks 326, deck_cards 9.396; `remote_writes: false` |
| 00:58–01:01 | Deploy do site público (`scripts/manaloom_deploy_public_web.sh`) | **deployed**: `web-public@sha256:320fca79b569f161d05d8ac3db52b180579c14fc16d28279e11cd2a1a8ae56eb`, `git_sha 87fd5a2e6`, `healthz ok`; home com "Acesso ainda não liberado", sem link para `/app` |
| 02:31:05–02:32:37 | Pré-checagem do deploy do backend com o banco em 057 | Passaram env, âncoras (EasyPanel `b7f90817…606e2c`, SSH `SHA256:sqDS6GaSt…`), Sentry, JWT, topologia do proxy, `auth_runtime_preflight=ready` (inclusive `account_email_delivery=validated`), gate de Battle e contratos 038–057. **Recusa esperada** no contrato 041–058. Antes, uma pré-checagem tinha achado o `.env` local sem a configuração de e-mail |
| 02:32:52–02:33:16 | Migration 058 (`with_new_server_pg.sh --write-approved dart run bin/migrate.dart`) | `058_snapshot_trade_item_identity` **sucesso**; ponto sem volta sem o backup |
| 02:33:22–02:38:50 | Deploy do backend (`scripts/manaloom_deploy_backend_image.sh`), com observação same-SHA embutida | **deployed**: `cartinhas@sha256:d1d2ce7192f96eca032dde253481dead47a43a95072783bd11bcd9cd5abee6c1`, `git_sha 87fd5a2e6`, 29 capabilities `off` |
| 02:39:01 | Observação externa, independente do script | ver tabela abaixo |
| 02:40:27–02:42:59 | Deploy do ops (`scripts/manaloom_deploy_ops_image.sh`) | **deployed**: `ops@sha256:db4a409ad1361ebe78a7b96f70e81ab780c9db0e7e374ca407287c50858f95a1`, `git_sha 87fd5a2e6`, `operational_mode safe_housekeeping_only`, único job ligado `hermes_cron_governor_report` |

Entre a 058 (02:33:16) e o backend novo pronto (02:38:50), o backend antigo exigia 057 e
respondia readiness 503, uma janela de cerca de 5 min 30 s. A produção não tem uso desde
2026-08-03.

## Observação externa (2026-09-23 02:39:01 UTC)

| Chamada | Resposta |
| --- | --- |
| `GET /health` | `healthy`, `git_sha 87fd5a2e6126371c7e2841a8d2fc25405d453cb6` |
| `GET /ready` | `ready`, `latest_migration 058`; `battle_job_worker`, `battle_runtime`, `ai_runtime`, `battle_live_spectator` e `interactive_battle` `disabled`; política `brewtact_free_beta_2026-08-13`, digest `ace782b3969a9ba5a2691f5ca3d97360927919739cd16c796d7b36e8124d754d` |
| `GET /capabilities` | 29 capabilities, **nenhuma ligada** |
| `POST /auth/register` (corpo vazio) | 404 `capability_unavailable`: cadastro fechado |
| `GET /ai/ml-status`, `POST /ai/generate`, `POST /ai/simulate` | 404 `capability_unavailable` |
| `GET /community/marketplace` | 404 `capability_unavailable` |
| `POST /auth/login` (conta inexistente) | 401: plano de controle funcionando |

## O que isto não resolve

- **Os quatro buracos do plano de controle continuam** (D-19): exportação sem reautenticação,
  exclusão sem limite de tentativas, login que denuncia contas e relatório de deck apagado.
  Fecham em `BT-AUTH-003`, `BT-AUTH-004` e `DCK-P0-06`.
- **O `/app` segue na imagem antiga** (`app-web@sha256:f94930bc…`). O deploy do Flutter Web com
  tudo desligado continua bloqueado pela contradição entre o loader e o gate (`BT-REL-001`). O
  site não aponta para ele.
- **Backup sem cifra e sem cópia fora desta máquina.** O único caminho de cifra do repositório
  exige bucket, que o dono vetou. Fica com o `BT-DR-001`.
- **Sidecars de Battle intocados.** O readiness não os sonda com Battle desligado.
- **Observação do host:** o banner do SSH avisa 7 atualizações de segurança e reinício pendente.
  Não foi tocado.
