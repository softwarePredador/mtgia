# Receipt — leitura read-only do PostgreSQL de produção — 2026-09-22

- Autorização: dono do projeto, em 2026-09-22, nesta conversa de coordenação, com escopo **"só
  estrutura e contagens"** e aprovação explícita da chave do servidor abaixo.
- Executado por: sessão coordenadora (Claude), a partir do checkout `d15beb05b` com a correção
  documental de 2026-09-22 na árvore de trabalho.
- Lido em: `2026-09-22 19:35:43 UTC` (primeira leitura) e logo em seguida (segunda leitura, só
  estrutura).
- Caminho: `server/bin/with_new_server_pg.sh --read-only psql -X -q -f <consultas>` — túnel SSH
  próprio, só as 6 chaves de conexão lidas de `server/.env` (o arquivo não foi aberto), e
  `PGOPTIONS=-c default_transaction_read_only=on -c statement_timeout=120000`.
- Chave do servidor aprovada: `MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256=SHA256:sqDS6GaStLJcm6EhBgNbon3Xc+OFif946pwe9bf+nco`
  (ED25519; a mesma que esta máquina já conhecia em `~/.ssh/known_hosts`). O wrapper conferiu a
  chave apresentada contra ela antes de enviar qualquer credencial.
- Prova de somente leitura, lida da própria sessão: `default_transaction_read_only = on`,
  `transaction_read_only = on`.
- **Nenhum dado pessoal foi lido.** As 20 consultas selecionam só metadados de catálogo do
  PostgreSQL (`information_schema`, `pg_catalog`) e agregados (`count`, `min`/`max` de datas,
  valores categóricos como formato e nome de evento). Nenhuma seleciona e-mail, nome, hash, token,
  notas, metadados, mensagens de erro ou payloads. Nada foi escrito, nem migrado, nem apagado.
- Saídas brutas (CSV) ficaram fora do repositório, no scratchpad da sessão.

## Identidade

`halder` · PostgreSQL `17.10 (Debian 17.10-1.pgdg13+1)` · não é réplica.

## Ledger de migrations

**57 aplicadas; a última é `057 expand_battle_job_async_timeout` (2026-08-03 14:19 UTC).** O
repositório declara 58: **`058 snapshot_trade_item_identity` não foi aplicada.** O código atual
exige `latest_migration = '058'` em `/health/ready` (`server/lib/health_readiness_support.dart`).

## Estrutura (diff contra `project_logic_manifest.json > database`)

| Item | Produção | Repositório | Diferença |
| --- | ---: | ---: | --- |
| Tabelas em `public` | 99 | 79 | as 79 existem; **20 só na produção** |
| Views em `public` | 6 | 6 | iguais |
| Chaves estrangeiras | 97 | 98 | faltam `ml_prompt_feedback.deck_id → decks.id` e `ml_prompt_feedback.user_id → users.id`; sobra `card_deck_profiles.deck_id → decks.id` |
| Schema `manaloom_deploy_audit` | 1.033 tabelas, 150 MB | não declarado | backups de operações manuais de junho–julho (`pg007_…`, `pg013_…`, `validation_identity_cleanup_20260714_…`, deck swaps, regras de batalha) |
| Banco inteiro | 2,2 GB (`price_history` 1,0 GB) | — | — |

**As 20 tabelas só da produção**, classificadas pelo uso no código de produto
(`server/lib`, `server/routes`, `server/bin`, `app/lib`, excluindo testes):

- **Usadas pelo código, sem migration que as crie (7):** `optimization_analysis_logs` (5
  arquivos), `synergy_packages` (3), `archetype_patterns` (3), `theme_contextual_rules` (2),
  `ml_learning_state` (2), `card_rulings_legacy` (1), `analysis_sources` (1). Um ambiente criado
  do zero a partir das migrations não as teria.
- **Backups de operação manual (9):** `card_battle_rules_backup_pg780b_hash_new_server`,
  `card_battle_rules_backup_pg814_hash_new_server`, `pg252_…_backup` a `pg257_…_backup`,
  `pg596b_oracle_hash_backfill_backup`.
- **Sem uso no código de produto (4):** `card_deck_profiles` (124 MB), `card_extended`, `posts`,
  `search_subjects`.

**Colunas divergentes em 4 tabelas comuns:** `trade_items` sem as 4 colunas de snapshot (é a
058); `cards` com `edhrec_rank` que o repositório não declara; `ml_prompt_feedback` com
`user_rating` que o repositório não declara; `card_meta_insights` com `id` e sem `created_at`.

## Contagens

| Pergunta | Resposta |
| --- | --- |
| Contas | 1.181 (1.144 não apagadas); **7 com e-mail verificado**; primeira 2025-11-22, **última 2026-08-03** |
| Decks | 326; validação: 15 `validated`, 310 `unknown`, 1 `draft`; 2 públicos |
| `DCK-P1-04`: decks validados que seriam rebaixados se legalidade ausente bloqueasse | **0 de 15** |
| Formato do deck | 12 decks com formato em maiúscula (`Commander` 6, `Modern` 5, `Standard` 1); `card_legalities` só usa minúscula. O código normaliza desde `776b9e25d` (2026-07-23), inclusive a versão em produção; os 12 são linhas antigas sem backfill |
| `SCOPE-P0-TRD-00`: listagens de venda/troca | **0** (fichário: 192 `have`, 22 `want`, `for_sale` e `for_trade` todos falsos) |
| Catálogo | 34.331 cartas, 951 sets, 393.767 legalidades; **cartas e legalidades sincronizadas pela última vez em 2026-06-06** (as 3 últimas execuções de `cards` falharam nesse dia); preços em 2026-06-27; regras em 2026-07-16 |
| Jobs de IA (`ai_generate_jobs`, `ai_optimize_jobs`) | **0 linhas**, embora o funil registre gerações em 2026-08-02 — compatível com a limpeza de 30 minutos (`BT-AI-032`) |
| Funil de ativação | 10 eventos distintos, **último em 2026-08-03**; nenhum dos 4 eventos de onboarding que o servidor rejeita (`onboarding_goal_selected`, `onboarding_experience_selected`, `onboarding_build_mode_selected`, `onboarding_task_started`) aparece |
| Notas de pós-jogo | **0** |

## O que isto não prova

Não prova qual SHA está implantado (só o endpoint público de release diria), não prova o estado
dos containers nem de outros bancos, e não substitui o receipt do `BT-DB-001`, que exige
ferramenta reproduzível. Os números de contas e decks não distinguem usuário real de conta de teste.

## Adendo — observação pública do mesmo dia (2026-09-22 19:49 UTC)

Leitura por `GET` público, sem credencial, no host de API do runbook
(`evolution-cartinhas.2ta7qx.easypanel.host`):

| Chamada | Resposta |
| --- | --- |
| `GET /health` | 200; `status healthy`; `git_sha a6ee09c8f16cf17c2867de4b089e5e65b3527254` |
| `GET /ready` | 200; `latest_migration 057`; `battle_job_worker` e `ai_runtime` (`explain = gpt-4o-mini`) saudáveis; os demais checks também |
| `GET /capabilities` | 404 `Route not found` |

Isso responde o que a seção anterior não provava: o SHA implantado é `a6ee09c8f` (2026-08-03),
39 commits atrás da branch de trabalho e sem a política de capabilities. O que o código dessa
versão expõe está em `docs/verdade/FATOS.md` 11.17.
