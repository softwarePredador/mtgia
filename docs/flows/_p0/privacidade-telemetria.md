# P0 CORE — Privacidade, exportação/exclusão, KPI e observabilidade

Medição contra o código em `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia`
(branch `codex/free-beta-release-candidate-2026-07-17`, HEAD `d15beb05b`), em 2026-09-22.
Somente leitura; nada foi executado. **Critério de PROVADO (endurecido na revisão
adversarial, ver a seção final):** existe um teste que afirma a asserção **inteira** — não uma
parte dela — **e** há registro de execução (um gate que roda hoje ou um receipt cujo código
não mudou depois). Teste de grep no fonte não prova comportamento. Linhas do backlog referem-se
à working tree (arquivo modificado e não commitado; batem com `source_line` do `TASK_REGISTRY.json`).

**Nenhum commit posterior ao backlog de 2026-08-12 resolveu as tarefas deste grupo.** O código
de export, exclusão, métricas e alertas é anterior: `user_data_privacy_service.dart` 58c161bc4
(2026-07-29), `users/me/export/index.dart` 8264ffb27 (2026-08-11), `operational_alerts.dart`
8264ffb27, `commercial_metrics_service.dart` e9f55a1d6 (2026-07-16), `observability.dart`
5dabb08c4 (2026-07-30). *(Correção da revisão: a frase original dizia que "nenhum código do
grupo mudou" depois do backlog, e isso não é exato. Mudou o código de **contenção**:
b2d3fc04f (2026-08-13) mexeu em `manaloom_ops_daemon.py` (gate de capability por job),
`pull_learning_events.py` (quarentena por `source`), `routes/_middleware.dart` e em 1 linha de
`activation-events/index.dart`; 406d7dd53 (2026-08-25) endureceu o middleware e o daemon.
Nada disso fecha PRIV/KPI/OBS.)* A única alteração de código não commitada
(`server/routes/community/marketplace/index.dart`) está fora do grupo. Conclusão: nenhuma das
quatro foi resolvida por outro commit sem atualização de estado. O rótulo `TODO` esconde
**implementação pré-existente considerável** (sobretudo em PRIV-002), não trabalho novo.

**Onde os testes rodam.** `scripts/quality_gate.sh full` roda todo `server/test/*_test.dart`
excluindo tags live (`scripts/quality_gate.sh:65-91`). O `quick` roda só o `paths:` de
`server/dart_test.yaml:1-49`, que inclui `observability_test.dart` e **nenhum** teste de
privacidade, KPI ou alertas. `server/test/privacy_account_live_test.dart` (tags
`live, live_backend, live_db_write`, `:1`) não está no preset `live` (`dart_test.yaml:61-78`)
e começa por `POST /auth/register` (`:35-44`). Com as 29 capabilities OFF
(`server/config/release_capabilities.json`), o teste para em `:44` (espera 201) — e também
dependeria de `catalog_private`, `decks_private` e `collection_private` (`:87-137`). Só roda
com um arquivo de capabilities isolado e descartável (`release_capability_policy.dart:8-13`).
*(Correção da revisão: a versão original dizia "nenhum receipt o cita". Existe um: S1-05 em
`docs/qa/MANALOOM_SPRINT1_DATA_SESSION_EVIDENCE_2026-07-21.md:133-160` registra **1/1 PASS em
PostgreSQL descartável** em 2026-07-21, com SHA-256 do teste `d0894b1c…`, que é exatamente
`git show 776b9e25d:server/test/privacy_account_live_test.dart`. Depois disso o serviço ganhou
+211 linhas (4700fc383, e64800eab, 58c161bc4: 6 relações de Battle no export e 4 DELETEs novos)
e o teste mudou em 8264ffb27. Ou seja: **provado uma vez, sobre código anterior; a prova está
vencida e hoje o teste não roda em lugar nenhum**.)*

---

## Tabela-resumo do grupo

| ID | Declarado | Medido | PeP | PsP | PARCIAL | NAO | Arquivos a tocar | Testes a escrever | Migração | Decisão humana | Serviço externo | Prova viva | ABERTO hoje |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BT-PRIV-001 | TODO | **mal-começada** | 1 | 3 | 6 | 3 | ~20 | 11 | sim | sim | condicional (storage do artefato) | sim | **sim** — `GET /users/me/export` no plano de controle |
| BT-PRIV-002 | TODO | **mal-começada** (era "metade") | 0 | 2 | 5 | 4 | ~22 | 12 | sim | sim | condicional (Sentry, backups) | sim | **sim** — `DELETE /users/me` no plano de controle |
| BT-KPI-001 | TODO | **mal-começada** | 0 | 1 | 6 | 6 | ~18 | 9 | sim | sim | não | sim (baseline) | **sim** — `POST /users/me/activation-events` no plano de controle |
| BT-OBS-001 | TODO | **mal-começada** | 0 | 1 | 6 | 6 | ~19 | 13 | provável (métrica durável para SLO) | sim | sim (canal de alerta; TSDB se não for PG) | sim | parcial — `/health/*` atrás de ops key ou admin |

PeP = PRONTO_E_PROVADO · PsP = PRONTO_SEM_PROVA · NAO = NAO_ENCONTRADO.
*Contagens, arquivos e testes revisados na verificação adversarial (seção final). Antes eram:
PRIV-001 2/2/6/3, ~14 arquivos, 8 testes; PRIV-002 "metade", 1/1/5/4, ~16 e 9; KPI-001 ~12 e 7;
OBS-001 2/0/5/6, ~14 e 8, sem migração.*
Plano de controle = `_exactControlPlaneRequests` em `server/lib/release_capability_policy.dart:590-620`
(linhas `:598-600` health, `:611` DELETE, `:612` export, `:615-616` activation-events),
alcançável com as 29 capabilities OFF.

**Leitura rápida.** PRIV-002 tem o maior ponto de partida: o núcleo no Postgres (transação
única, anonimização, tombstone HMAC, triggers anti-ressurreição) está implementado. Só foi
provado uma vez, em 2026-07-21, sobre código anterior, e hoje nenhum teste que rode o exercita.
Mas esse núcleo é o **substrato** da tarefa, não o objeto dela. O que a tarefa pede — outbox,
consumidores, reconciliação fora do PG, receipt por consumidor e retry idempotente — não existe,
por isso ela é **mal-começada** e não "metade". PRIV-001 tem um export síncrono amplo, mas nenhum
dos quatro requisitos estruturais do aceite (job, allowlist por padrão, expiração, auditoria), e
**vaza `request_fingerprint` de três tabelas** enquanto um teste diz o contrário. KPI-001 faz
**exatamente o que o aceite proíbe**: conta eventos e divide por signups. OBS-001 tem um
avaliador de thresholds testado para API e jobs, mas o sinal HTTP que o alimenta é cumulativo
desde o start do processo, sem janela, e separado por caminho cru — o alerta de API não cumpre
o papel. Não há receiver, SLO, runbook vigente nem teste de alerta.

### Eixo triplo por tarefa

| ID | IMPLEMENTADO | PROVADO | ABERTO |
| --- | --- | --- | --- |
| PRIV-001 | Export **síncrono** de 34 consultas, 8 com allowlist. Não é job, não expira, não audita | Grep no fonte (`user_data_privacy_contract_test.dart:15-76`, roda no `full`). O live passou uma vez (receipt S1-05, 2026-07-21) sobre código anterior; hoje não roda. Só os headers de não-cache seguem cobertos por essa prova | Sim: rota no plano de controle; botão no app (`app/lib/features/profile/profile_screen.dart:1501`) |
| PRIV-002 | Núcleo PG implementado (com lacunas: 7 relações com FK para `users` intocadas); nada fora do PG | Grep no fonte + regressão estática do SQL (rodam no `full`). O live passou uma vez (S1-05) antes de +211 linhas no serviço; nenhum teste executa os triggers | Sim: rota no plano de controle; botão no app (`profile_screen.dart:1520`). O sidecar que retém cópias está contido por `learning_writes: off` |
| KPI-001 | Tabela, rota, allowlist de nomes, serviço no app, painel comercial | Helpers puros e cliente do app; nada sobre semântica de métrica ou UGC | Sim: o coletor aceita `metadata` arbitrário de qualquer conta existente |
| OBS-001 | Avaliador de alertas pull-only (API, IA, Battle, Coach); Sentry sanitizado contra segredos e email | `operational_alerts_test.dart` prova o avaliador com snapshots sintéticos, não o sinal real (HTTP cumulativo, sem janela, chave crua). `observability_test.dart` prova a sanitização e consagra o UUID cru | Painel atrás de `operationalAdminMiddleware` (`server/lib/admin_access_support.dart:100-129`); nenhum alerta sai do servidor |

---

## BT-PRIV-001 — Export de dados como job allowlisted

Backlog: `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md:265`.
Entrega: *"Tornar export de dados um job allowlisted, sem fingerprints/IDs internos indevidos."*
Aceite: *"Export completo e mínimo; isolamento A/B; expiração e download auditados."*
Onda: `docs/execution/waves/01-platform-safety.md:40`, que diz *"isolamento A/B, conteúdo mínimo/completo, expiração e download auditado"*.

**Como está hoje.** `server/routes/users/me/export/index.dart:8-30` chama
`UserDataPrivacyService.exportUserData(userId)` **dentro da requisição** (`:13-15`) e devolve
o JSON inteiro com `Cache-Control: no-store` e `Content-Disposition` (`:16-24`). O serviço
(`server/lib/user_data_privacy_service.dart:23-596`) faz 34 consultas numa transação
`REPEATABLE READ` somente leitura (`:591-594`). Das 34, **8 usam allowlist explícita**
(`jsonb_build_object`): `account` `:28-39`, `battle_simulation_attempts` `:359-384`,
`battle_live_records` `:410-419`, `interactive_battle_sessions` `:432-461`,
`interactive_battle_records` `:472-484`, `battle_replay_annotations` `:498-513`, `trades`
`:265-282` e `notifications` `:340-348`. **Uma** usa denylist: `battle_jobs` `:395-399`.
**As outras 25 exportam a linha inteira com `to_jsonb(...)`**, nas linhas 53, 61, 71, 92, 107, 128,
148, 157, 166, 175, 185, 194, 203, 211, 220, 229, 238, 247, 256, 294, 303, 312, 321, 330 e 524.
Toda coluna nova nessas tabelas entra no export sem ninguém decidir.

| # | Asserção | Estado | Onde está | Teste | O que falta |
| --- | --- | --- | --- | --- | --- |
| 1 | O export roda como **job** assíncrono, fora da requisição | NAO_ENCONTRADO | `export/index.dart:12-24` monta o dump inline. `grep -i "export_job\|data_export\|export_request\|export_audit\|download_token\|signed_url"` em `server/` e `app/lib` = 0; nenhuma tabela de export em `server/bin/migrate.dart` nem em `server/database_setup.sql` | — | Tabela de job, worker, estados, rota de criação (202) e de status. O app hoje espera o JSON síncrono (`app/lib/features/profile/account_privacy_service.dart:35-48`) e o compartilha pelo share sheet (`profile_screen.dart:361-397`) |
| 2 | Conteúdo por **allowlist** explícita, que falha fechada quando surge coluna nova | PARCIAL | 8/34 relações com allowlist (lista acima); 25 com `to_jsonb` da linha inteira; `battle_jobs` por denylist de 3 chaves (`:396-399`) | `user_data_privacy_contract_test.dart:15-76` só faz grep por substrings do fonte (por exemplo `:34-35` exige `- 'request_payload'` e `- 'lease_token'`). Nenhum teste compara colunas reais com uma classificação | Allowlist declarativa por coluna para as 26 relações restantes e um teste que leia o schema e falhe se houver coluna sem classificação |
| 3 | **Sem fingerprints** internos | PARCIAL — **vaza hoje** | `request_fingerprint` e `request_key` saem por `to_jsonb(j)` em `ai_generate_jobs` (`:247`) e `ai_optimize_jobs` (`:256`); as colunas vêm da migração 048 (`server/bin/migrate.dart:2379-2390`). `battle_jobs` (`:396-399`) remove só `request_payload`, `lease_owner` e `lease_token`, e **exporta** `request_fingerprint`, `idempotency_key` (migração 054, `migrate.dart:3113-3114`), `request_hash` e `engine_request_hash`. `ai_optimize_cache` (`:238`) exporta `cache_key` e `deck_signature`. Hashes de deck entram por allowlist (`:369-370`, `:438-439`, `:505`), e `post_game_notes.deck_snapshot_hash` por `to_jsonb` (`:148`) | **Falsa garantia:** `user_data_privacy_contract_test.dart:60` afirma `isNot(contains("'request_fingerprint'"))` sobre o **fonte**. Passa porque `to_jsonb` exporta a coluna sem nomeá-la. O envelope diz omitir `interactive_battle_request_fingerprints` (`:586`) e se cala sobre os três jobs | Remover as colunas, decidir se hashes de deck são "devidos", e trocar o teste de grep por um que varra as chaves do JSON exportado (`*_fingerprint`, `*_hash`, `request_key`, `cache_key`, `idempotency_key`, `lease_*`) |
| 4 | **Sem IDs internos indevidos** | PARCIAL | UUIDs internos **de outros usuários**: `conversations.user_a_id/user_b_id` (`:330`), `user_follows.follower_id/following_id` (`:175`), `trades.sender_id/receiver_id` (`:267-268`) e `content_reports.reviewed_by`, o UUID do **moderador** (`:524`; coluna em `database_setup.sql`, `content_reports`). `deck_cards.card_id` e `binder_items.card_id` são UUIDs internos do catálogo (`:71`, `:128`), embora `scryfall_id` já venha junto. `deck_learning_events.synced_to_hermes/synced_at` é estado interno do sidecar (`:92`). O nome do arquivo leva o UUID do usuário (`export/index.dart:22`); o app sobrescreve o nome (`profile_screen.dart:395`), o navegador não | Nenhum | Política de IDs: próprios sim, de terceiros não (usar handle público ou pseudônimo), catálogo por `scryfall_id` |
| 5 | Segredos omitidos (hash de senha, JWT, token FCM, mensagens de terceiros, corpo de notificação) | **PRONTO_SEM_PROVA** (rebaixada de PeP) | Conta por allowlist (`:28-39`); corpo de notificação `NULL` (`:345`); mensagem de trade só do remetente (`:271-274`); DM só as enviadas (`:317-325`); `battle_jobs` sem `lease_token` (`:396-399`); tokens de reset/verificação nunca consultados; manifesto `omitted_secrets` (`:575-587`) | `privacy_account_live_test.dart:168-178` afirma **menos** do que a asserção. Ausência das chaves `password_hash` e `fcm_token`: sim. JWT: o teste procura a string `'bearer '` (`:174`), não o token que tem em mãos (`:85`) — checagem vazia, porque nada grava JWT. Mensagens de terceiros e corpo de notificação: **não exercitados** — a conta do teste não tem trade, DM, conversa nem notificação (`:80-137`). O manifesto é uma lista literal. Além disso a prova é de 2026-07-21 (S1-05), anterior às 6 relações de Battle hoje exportadas, e o teste não roda | Fixture com segunda conta que troca DM, mensagem de trade e notificação; asserção pelo token real; rodar num gate com conta semeada que não passe por `/auth/register` |
| 6 | Export **completo** | PARCIAL | Faltam relações com FK para `users` que o serviço nunca cita (`grep` = 0 em `user_data_privacy_service.dart`): `user_blocks` (com `reason` em texto livre), `user_block_events` e `content_report_appeals` (recursos do próprio usuário, com `reason`). *(Revisão: faltam também duas relações ligadas **ao deck** do titular, não a `users`: `deck_matchups` (`database_setup.sql:473-481`, gravada por `routes/ai/simulate-matchup/index.dart:490`) e `deck_weakness_reports` (`:1651-1661`, gravada por `routes/ai/weakness-analysis/index.dart:654`). As rotas estão OFF, mas linhas históricas podem existir.)* Faltam colunas da conta: 6 de visibilidade, `terms_version/terms_accepted_at/privacy_version/privacy_accepted_at` (o **registro de consentimento**), `email_verified_at` e `password_changed_at` (`database_setup.sql:7-33`; export em `:28-39`). *(Revisão: e `_optionalJsonRows` devolve seção vazia **em silêncio** quando a relação não existe (`:995-1007`). `deck_optimization_events` só existe via `migrate.dart:1026`, fora do baseline, e num banco criado pelo baseline some do export sem aviso.)* | O live afirma só 4 seções (`:164-167`) | Adicionar 5 relações e as colunas de consentimento e visibilidade; relação obrigatória ausente deve falhar fechado. Definir "completo" contra o inventário de PRIV-003 |
| 7 | Export **mínimo** | PARCIAL | Saem blobs e estado operacional: `result`/`error` inteiros dos jobs de IA (`:247`, `:256`), `payload` do cache de otimização (`:238`), `model`/`error_message`/`endpoint` de `ai_logs` (`:211`), e em `battle_jobs` `engine_process_id`, `quota_user_limit`, `quota_global_limit`, `lease_expires_at`, `heartbeat_at` e `claimed_at` (`:396-399`) | Nenhum | Critério de minimização por classe, derivado da mesma allowlist do item 2 |
| 8 | Isolamento A/B **estrutural** (A não consegue pedir o export de B) | PRONTO_SEM_PROVA | `userId` vem só do token (`export/index.dart:11` → `getUserId`); não há parâmetro de alvo; toda consulta filtra por `@userId` | Nenhum teste com dois usuários. O live usa uma conta (`:76-85`) | Teste live com A e B: nada de B no export de A e 401/404 em qualquer tentativa de alvo |
| 9 | Isolamento A/B de **conteúdo** (dados de B não aparecem no export de A) | PARCIAL | `battle_simulations` não tem `user_id` e é exportada quando **qualquer** deck do usuário é A, B ou vencedor (`:103-122`). `/ai/simulate` aceita deck **público de outro usuário** como oponente (`server/routes/ai/simulate/index.dart:84-89`, `allowPublic: true`; predicado em `:490-493`) e persiste o replay sanitizado em `game_log` (`server/lib/battle/battle_simulation_persistence_service.dart:41`). Consequência: o export de B carrega as simulações que **A** rodou contra o deck público de B, com `deck_a_id` de A (deck possivelmente privado) e o replay da partida de A (`game_log` e `metrics` inteiros via `to_jsonb`; colunas em `database_setup.sql`, `battle_simulations`). Hoje contido por Battle OFF; linhas históricas podem existir | Nenhum | Exportar só simulações iniciadas pelo próprio usuário (via `battle_simulation_attempts.user_id`) ou redigir o lado do terceiro. *(Revisão: é o lado "export" do mesmo problema de posse que o backlog já registra como bug P0 em `BT-BAT-002`, linha 463 — "Matriz A/B preserva ownership".)* |
| 10 | Snapshot consistente | PRONTO_SEM_PROVA | `REPEATABLE READ` + `readOnly` (`:591-594`) | Só grep (`user_data_privacy_contract_test.dart:68-69`) | — (baixo risco) |
| 11 | Resposta não cacheável | PRONTO_E_PROVADO (mantida; prova de 2026-07-21) | `export/index.dart:18-22` | `privacy_account_live_test.dart:150-158` afirma `no-store`, `no-cache` e o prefixo do arquivo. Executado com PASS no receipt S1-05 (hash do teste = 776b9e25d); desde então a rota só trocou o prefixo `manaloom-`→`brewtact-` (8264ffb27), então a prova ainda cobre os headers. O teste não roda hoje (capabilities OFF) | Reexecutar num gate; o download do futuro artefato precisará do mesmo cuidado |
| 12 | **Expiração** do artefato | NAO_ENCONTRADO | Não há artefato persistido, logo não há o que expirar | — | TTL, limpeza e 410 para link expirado |
| 13 | **Download auditado** | NAO_ENCONTRADO | A rota não grava nada (`export/index.dart:8-30`) e o `catch (_)` de `:27-29` descarta a exceção. *(Correção da revisão: a falha não fica "sem log nem Sentry". Como `/users/*` conta como endpoint social, o middleware raiz registra todo status ≥ 400 e todo pedido ≥ 1 s (`_middleware.dart:20,273-287`): uma linha de log com `user_id` cru (`:300`) e uma mensagem ao Sentry (`:310`), sem a exceção.)* **Um export bem-sucedido e rápido não deixa rastro**, e o rastro de um lento é ruído de observabilidade, não auditoria | — | Linhas de auditoria em pedido, conclusão, download e expiração, com `request_id` e sem conteúdo |

### O que realmente falta

A rota existe, está aberta e entrega quase tudo — **esse é o problema**. Falta transformar o
dump síncrono em job: tabela de job/auditoria (migração), worker, artefato com TTL, download
auditado e rotas de criar, consultar e baixar, com o app passando a pedir, aguardar e baixar.
Falta também reescrever 26 das 34 consultas para allowlist por coluna, com um teste que leia o
schema e falhe fechado. No meio do caminho há três correções que valem já, independentes do
job: **tirar `request_fingerprint`, `request_key`, `idempotency_key` e `cache_key` do export**
(`:238`, `:247`, `:256`, `:396-399`), **não exportar UUIDs de terceiros** (moderador,
contrapartes, seguidores) e **fechar o vazamento A/B de `battle_simulations`**. Por fim,
acrescentar `user_blocks`, `user_block_events`, `content_report_appeals`, `deck_matchups`,
`deck_weakness_reports` e o registro de consentimento.

Unidades (revisadas): **~20 arquivos**. A lista original tinha ~14: `migrate.dart`,
`database_setup.sql`, `bin/verify_schema.dart`, `user_data_privacy_service.dart` (ou divisão
em allowlist + montador), um novo serviço de job, 2–3 rotas novas,
`release_capability_policy.dart` (novas entradas de plano de controle) e seu teste, job de
limpeza no daemon (`manaloom_ops_daemon.py` + `JOB_REQUIRED_CAPABILITIES`),
`account_privacy_service.dart`, `profile_screen.dart`,
`server/doc/API_CONTRACTS_AND_DATA_MAP.md:87` e `docs/project_logic_contracts.json`. A revisão
somou: o worker que monta o artefato; o adaptador de armazenamento do artefato (tabela ou
object storage); o arquivo declarativo de classificação por coluna; `privacy_account_live_test.dart`
reescrito com semente de conta e o preset em `dart_test.yaml`; e os testes do app
(`account_privacy_service` e `profile_screen`). **11 testes** (eram 8): allowlist × schema;
varredura de fingerprints e IDs no JSON; A/B live com dois usuários (incluindo simulação contra
deck público); expiração → 410; auditoria gravada em pedido e download; idempotência do pedido
de job; reescrita de `privacy_account_live_test.dart:145-178` (hoje afirma 200 com bearer
simples); UI assíncrona no app. Acrescentados: **autorização do download** (A não baixa o
artefato de B por ID ou link — superfície que o modelo de job **cria**); completude (as 5
relações e as colunas de consentimento presentes); falha do worker sem artefato parcial.
**Migração: sim.** **Decisão humana:** onde fica o artefato e por quanto tempo; canal de entrega
(download no app ou link); quais hashes e IDs são "devidos"; como tratar dados de terceiros.
**Serviço externo:** só se o artefato for para object storage com URL expirável.
**Prova viva:** sim (fluxo novo no app, com captura e receipt).

**Dependência declarada (`BT-AUTH-004`):** real só para **fechar** (o job precisa nascer atrás
de step-up e rate limit). Allowlist, fingerprints, A/B, job, TTL e auditoria podem começar
hoje. **Não declaradas:** `BT-SEC-001` (limiter distribuído fail-closed — o export é a leitura
mais cara da API, e a sessão irmã mostrou que o comportamento sob falha é indefinido) e
`BT-PRIV-003`. *(Revisão: SEC-001 já está implícita. O aceite de `BT-AUTH-004`, que é a
dependência declarada, exige "rate limit distribuído" (backlog `:261`); o que falta é AUTH-004
depender formalmente de SEC-001, não PRIV-001.)* O registry põe PRIV-003 **depois** de PRIV-001, mas "completo e mínimo" só
se define com a classificação por coluna que PRIV-003 produziria: a dependência está invertida.
**Sobreposição:** BT-AUTH-004 (mesma rota), PRIV-003 (mesma classificação), SEC-AI-002
(mesma allowlist de campos), `BT-BAT-002` (posse A/B das simulações — item 9).

---

## BT-PRIV-002 — Exclusão com outbox e reconciliação

Backlog: `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md:266`.
Entrega: *"Orquestrar exclusão com outbox/reconciliação de sidecars, jobs, caches e arquivos."*
Aceite: *"Nenhum runtime ativo recria dado; retry idempotente; receipt por consumidor."*
Onda: `01-platform-safety.md:41`, que diz *"retries idempotentes, sidecars/jobs/caches/arquivos e receipt por consumer"*.

**Como está hoje (a parte boa é grande).** `DELETE /users/me` (`server/routes/users/me/index.dart:310-373`)
exige a frase literal e a senha (`:322-339`, chamada em `:341-344`) e chama `deleteAndAnonymizeAccount`
(`user_data_privacy_service.dart:598-993`). Numa **única transação** com `FOR UPDATE` no
usuário (`:603-613`), o serviço apaga ou anonimiza cerca de 30 relações (`:636-933`) e grava
tombstones HMAC dos decks sob chave interna versionada, abortando se a chave ativa faltar
(`:812-856`). Depois pseudonimiza a conta (`:935-961`) e grava um receipt sem identificador
do titular (`:963-984`). No banco, a migração 038 instala `manaloom_require_active_user`
(`server/bin/migrate.dart:1316-1340`) como trigger `BEFORE INSERT OR UPDATE` em **toda FK de
coluna única para `users`** (`:1342-1379`), reinstalado nas migrações 041, 053, 054 e 056
(`:2079`, `:3024`, `:3335`, `:3823`). Nenhuma tabela com FK para `users` foi criada depois da
056 (conferi 057 e 058). Há ainda guards de dono de deck para `deck_learning_events` (com
consulta ao tombstone) e para `battle_simulations` (`:1489-1605`).

| # | Asserção | Estado | Onde está | Teste | O que falta |
| --- | --- | --- | --- | --- | --- |
| 1 | Exclusão orquestrada por **outbox** | NAO_ENCONTRADO | `grep -i outbox` em `server`, `app` e `scripts` = 0. Tudo acontece dentro de uma transação síncrona; nada é enfileirado para consumidores | — | Tabela de outbox por consumidor, gravada **na mesma transação**, e worker com retry e backoff |
| 2 | Núcleo PG atômico: apaga/anonimiza, revoga sessão e some das superfícies públicas | **PRONTO_SEM_PROVA** (rebaixada de PeP) | `user_data_privacy_service.dart:602-992`; revogação porque `authMiddleware` usa `getUserFromToken`, que exige `deleted_at IS NULL` (`server/lib/auth_middleware.dart:43-53`; `auth_service.dart:324-339`); filtros `deleted_at IS NULL` nas rotas públicas (só grep: `deleted_account_visibility_contract_test.dart:9-25`) | `privacy_account_live_test.dart:214-256` afirma **menos** do que a asserção. Afirma: 200 com `account_deleted`/`deletion_mode`/`deleted_at`/`retention`; sessão antiga 401 (`:237`); login 401 (`:240`); export 401 (`:246`); um deck público 404 (`:252-256`). **Não afirma** que alguma linha foi apagada ou anonimizada no banco — nem os decks, binder e nota que ele criou, nem o pseudônimo em `users` —, e não verifica o item de binder `for_trade` que criou (`:114-120`) no marketplace. **Não exercita a atomicidade:** as falhas de `:180-212` são validações anteriores a qualquer escrita (frase e senha vazia em `routes/users/me/index.dart:322-339`; senha errada no serviço em `:615-623`, antes do primeiro DELETE em `:636`). Prova de 2026-07-21, antes de +211 linhas no serviço; o teste não roda hoje | Asserções no banco após a exclusão (linhas por relação, pseudônimo), falha injetada no meio da transação e live num gate |
| 3 | **Nenhum runtime ativo recria dado no Postgres** | PRONTO_SEM_PROVA | Triggers de FK (`migrate.dart:1316-1379` + reinstalações), guards de deck/Battle (`:1489-1605`), tombstone HMAC (`:1478-1487`), lock `FOR UPDATE` dos dois lados (`migrate.dart:1333`; serviço `:609`); escritas em `users` guardadas por `deleted_at IS NULL` (`routes/users/me/index.dart:248-252`, `routes/users/me/fcm-token/index.dart:54-56`); tokens de reset/verificação travam `users` e exigem conta ativa (`auth_service.dart:410-414,520-524`). Revisão: conferi o desenho e ele fecha a corrida — o guard espera o `FOR UPDATE` da exclusão e reavalia `deleted_at`. **Guarda que falta:** o bloco `DO` instala o trigger só para as FKs que existem quando a migração roda (`:1342-1379`), e nada detecta uma FK nova para `users` sem trigger. `verify_schema`, readiness e os testes só procuram o nome da função (`data_model_migration_test.dart:413-453`, `ai_operations_contract_test.dart:173`) | **Só estático:** `deleted_account_visibility_contract_test.dart:47-70` faz grep dos nomes das funções em `migrate.dart`; `privacy_migration_sql_regression_test.dart:14-99` verifica forma e equivalência migração/baseline do SQL; o harness 038–040 só checa existência de tabelas (`server/bin/migration_038_040_isolated_support.dart:186-199`). `grep` por `inactive_user_reference`, `deleted_deck_learning_event_rejected` ou `inactive_battle_deck_owner_reference` em testes = só o grep do nome | Teste em PG descartável: excluir a conta e tentar `INSERT` em `ai_logs`, `decks`, `deck_learning_events` e `battle_simulations` → erro `23503` com a mensagem certa; corrida exclusão × escrita concorrente; checagem de schema "toda FK de coluna única para `users` tem trigger `manaloom_active_user_*`" |
| 4 | **Jobs** em voo não recriam dado nem continuam trabalhando | PARCIAL | As linhas de `ai_generate_jobs`, `ai_optimize_jobs`, `battle_jobs` e `interactive_battle_sessions` são apagadas na transação (`:655-679`) e escritas posteriores batem no trigger. Mas não há sinal de cancelamento para o worker em processo nem para o **sidecar interativo**, que segue com a sessão na memória até o TTL. *(Revisão: a exclusão de conta **não usa** o lock de ciclo de vida que a exclusão de um deck usa. `deleteDeckAfterBattleGuard` toma o advisory lock global e **recusa** apagar deck referenciado por sessão interativa ativa (`server/lib/battle/interactive_battle_deck_lifecycle.dart:13-66`), e a admissão toma o mesmo lock (`interactive_battle_store.dart:195,229`). A exclusão de conta apaga os decks direto (`user_data_privacy_service.dart:905-910`). Se A joga contra o deck público de B e B exclui a conta, a sessão de A perde `deck_b_id` no meio da partida (FK `ON DELETE SET NULL`, `database_setup.sql:1103`) e o runtime segue com a lista de B.)* | Nenhum | Cancelamento explícito (pelo outbox), o mesmo lock na exclusão de conta e teste com job e sessão em voo durante a exclusão |
| 5 | Reconciliação de **sidecars** | NAO_ENCONTRADO | `server/bin/pull_learning_events.py:94-101` copia `deck_learning_events` para o SQLite Hermes (`knowledge.db`, `:17-27`) na tabela `user_learning_events`, com **`deck_id` cru** e `event_data` com até **200 cartas** — a decklist (`:147-180`, `:375-389`) — e imprime `event` e `commander` no log do job (`:132-136`). Nada apaga essas cópias na exclusão e nada fora do PG consulta os tombstones (`git grep privacy_deleted_deck_tombstones` fora da migração, do serviço, do baseline e do deploy = 0). **Contido hoje:** o job exige `learning_writes` (`server/bin/manaloom_ops_daemon.py:713`), que está OFF. O arquivo existe localmente (27 MB, ignorado pelo git em `docs/hermes-analysis/manaloom-knowledge/scripts/.gitignore:2`; não abri) | Nenhum | Consumidor "hermes_sqlite" no outbox: purgar por deck (o SQLite guarda UUID cru, então basta a lista de decks, que precisa trafegar no outbox — decisão de privacidade) e pular eventos de deck tombstonado no pull |
| 6 | Reconciliação de **caches** | PARCIAL | PG: `ai_optimize_cache` apagado (`:649-654`). Memória: `EndpointCache` é por réplica e sem invalidação (`server/lib/endpoint_cache.dart:8-36`); guarda análise de arquétipo por deck com TTL de 10 min (`server/routes/ai/archetypes/index.dart:169,208,380,413`) e payload de generate com TTL configurável, padrão 600 s (`server/routes/ai/generate/index.dart:289-293`). *(Revisão: o TTL só controla **o que é servido**, não quanto tempo o dado fica em memória. A entrada vencida só sai quando a mesma chave é lida de novo (`endpoint_cache.dart:15-21`), e `clearExpired` (`:32-35`) **não tem nenhum chamador** (`git grep` em `server/lib`, `routes` e `bin`). A análise do deck de uma conta excluída fica na memória da réplica até o restart.)* | Nenhum | Chamar a limpeza periódica e só então decidir se o TTL basta (registrando-o como receipt "expira em ≤ N min"), ou invalidar entre réplicas |
| 7 | Reconciliação de **arquivos** | NAO_ENCONTRADO | O servidor não recebe upload (`attachment_url` e `avatar_url` são URLs do cliente, anuladas em `:786` e `:942`). Mas nenhum armazenamento em arquivo é reconciliado: SQLite Hermes (item 5), logs do daemon (`manaloom_ops_daemon.py:939-943`), backups de DR e o dispositivo — `logout()` limpa só credenciais (`app/lib/features/auth/providers/auth_provider.dart:418-434`), ficando notas pós-jogo, rascunhos e fila local | Nenhum | Lista de consumidores de arquivo, cada um com ação e receipt; limpeza local no app após exclusão |
| 8 | Todas as tabelas vinculadas ao titular são tratadas | PARCIAL | Não tocadas (`grep` = 0 no serviço): `user_blocks` (com `reason`), `user_block_events` (com `reason` e `request_id`), `content_report_appeals` (com `reason` e `appellant_user_id` mantido), `password_reset_tokens` e `email_verification_tokens`. Os fluxos de token checam `deleted_at IS NULL` (`server/lib/auth_service.dart:413`, `:523`), então não reativam a conta, mas as linhas ficam. **O receipt diz `moderation_records: anonymized`** (`:965`), mas só `content_reports` é anonimizado (`:766-777`); os recursos não são. *(Revisão — faltavam mais quatro lacunas: (a) `content_reports.evidence`, JSON enviado pelo próprio denunciante (`social_safety_service.dart:346,410-430`), não é limpo — o UPDATE zera só `reporter_user_id` e `details` (`:767-769`); (b) `trade_items` (`owner_id` + `item_snapshot`, `database_setup.sql:1968-1980`) e (c) `moderation_actions.moderator_user_id` (`:2526-2538`) ficam intactos e fora do `retention_summary`; (d) a limpeza de `rate_limit_events` casa `identifier IN (@userId, @email)` (`:928-929`), mas o limiter grava `'user:<uuid>'` (`rate_limit_middleware.dart:129,494`; `social_safety_service.dart:375`), então essas linhas ficam até a janela ou o cleanup.)* | Nenhum | Tratar as 7 relações, limpar `evidence`, corrigir o identificador do rate limit e fazer o `retention_summary` dizer a verdade |
| 9 | **Retry idempotente** | PARCIAL | Retry após **falha** é seguro **por construção**: uma única `runTx` (`:602`). *(Correção da revisão: a versão original dizia "provado no live `:191-212`", mas aquele trecho só testa senha errada, que é rejeitada antes de qualquer escrita (`:615-623`). Nenhum teste injeta falha no meio da transação.)* Retry após **sucesso** não é idempotente: a segunda chamada recebe 401 do `authMiddleware` (`auth_middleware.dart:45-53`), porque o token caiu com a conta. O app mostra a `message` do servidor ("Faça login novamente…", `account_privacy_service.dart:86-96`) e o `ApiClient` derruba a sessão por substring (`app/lib/core/api/api_client.dart:97-117`). Se a primeira resposta se perdeu, o usuário nunca vê "conta excluída". Não há chave de idempotência nem rota de status | Nenhum | Identificador de pedido de exclusão devolvido ao cliente, consultável sem sessão, e tratamento no app |
| 10 | **Receipt por consumidor** | PARCIAL | Um receipt central por exclusão (`migrate.dart:1442-1451`; gravação em `:970-984`), sem dimensão de consumidor e sem ID de correlação | Só grep (`user_data_privacy_contract_test.dart:119`); o live afirma o **corpo da resposta** (`:227-231`), não a linha do receipt | Receipt por consumidor (PG, sidecar, cache, arquivos, backups, Sentry), ligado por um ID pseudônimo do pedido |
| 11 | Relação esperada ausente **não** vira sucesso silencioso | NAO_ENCONTRADO | `_deleteIfPresent`, `_executeIfPresent` e `_executeIfAllPresent` retornam em silêncio quando `to_regclass` é nulo (`:1009-1048`). Se uma tabela for renomeada ou faltar num baseline, a exclusão reporta sucesso e grava receipt | Nenhum | Lista de relações obrigatórias que falha fechado |

~~Observação de desenho (decisão humana, não bug)~~ **Correção da revisão — é bug já
registrado.** A exclusão de B apaga simulações e tentativas **de A** que usaram o deck público
de B (`:875-904`), e por cascata também os `deck_matchups` de A contra o deck de B
(`database_setup.sql:476`, `ON DELETE CASCADE`). O backlog já decidiu que isso é defeito:
`BT-BAT-002` (P0 BATTLE, linha 463), *"Exclusão de conta não apaga tentativa/replay de outro
owner por possuir oponente"*, depende desta tarefa. Não é decisão aberta; é trabalho que cai
no mesmo `DELETE`.

### O que realmente falta

A parte Postgres está implementada e bem desenhada — falta **provar** (um teste em PG
descartável para os triggers e o live num gate) e fechar as lacunas (7 relações com FK para
`users`, `evidence`, identificador do rate limit, o lock de ciclo de vida). *(Revisão: essa
parte é o **substrato** da tarefa, não o objeto dela, por isso não vale "metade".)* O objeto da
tarefa não começou: não existe outbox, não existe noção de consumidor e nada fora do Postgres
fica sabendo da exclusão. O caso mais concreto é o **sidecar de aprendizado**: guarda `deck_id`
cru e a decklist de contas excluídas, sem purga; hoje só está contido porque `learning_writes`
está OFF. *(Correção da revisão: a versão original dizia que promover `learning_writes`
"precisa depender desta tarefa" e que isso não estava declarado. Está declarado: a classe
`P0 LEARNING` bloqueia qualquer escrita de learning (backlog `:157`); `BT-AI-030` (P0 LEARNING,
`:451`), "purge e reconciliação de learning por sujeito em PG e Hermes", depende de
`BT-PRIV-002`; e `DCK-P0-05` (`:283`) exige "revoke/delete subtrai PG e Hermes".)* Somam-se as
7 relações vinculadas não tratadas, um `retention_summary` que afirma anonimizar o que não
anonimiza, retry-após-sucesso que o app apresenta como sessão expirada, e o silêncio de
`_executeIfPresent`.

Unidades (revisadas): **~22 arquivos**. A lista original tinha ~16: `migrate.dart`,
`database_setup.sql`, `verify_schema.dart`, `user_data_privacy_service.dart`, um novo serviço
de outbox, um novo worker/consumidor Python no daemon, `manaloom_ops_daemon.py` (job de controle
sem capability; atualizar o fluxo `ops_scheduler` de BT-DOC-006), `pull_learning_events.py`,
cliente/armazenamento do sidecar interativo, `endpoint_cache.dart`, `routes/users/me/index.dart`,
`account_privacy_service.dart`, `profile_screen.dart`, `auth_provider.dart` (limpeza local),
`docs/project_logic_contracts.json` e o doc de contratos da API. A revisão somou: a rota nova de
status do pedido de exclusão, consultável sem sessão, com sua entrada em
`release_capability_policy.dart` e o teste da política; `interactive_battle_deck_lifecycle.dart`
(o lock na exclusão de conta); o cliente de exclusão do Sentry, se ele entrar como consumidor;
`privacy_account_live_test.dart` com semente e preset; e os testes do app. **12 testes** (eram
9): triggers em PG descartável; corrida exclusão × escrita; outbox com falha e retomada (receipt
uma vez); receipt por consumidor; purga do SQLite (Python); pulo de deck tombstonado no pull;
tabelas tratadas; retry após sucesso; limpeza local no app. Acrescentados: relação obrigatória
ausente → falha fechada; exclusão de conta × sessão interativa ativa (lock); verificação no
banco de que o `retention_summary` bate com as linhas.
**Migração: sim.** **Decisão humana:** lista de consumidores e prazo de cada um; se cache por
réplica fica coberto por TTL; se Sentry e backups entram; se o outbox pode carregar IDs de deck
em claro. **Serviço externo:** API de exclusão do Sentry e storage de backup, se entrarem.
**Prova viva:** sim (receipt de exclusão ponta a ponta em ambiente descartável com sidecar).

**Dependência declarada (`BT-AUTH-004`):** não bloqueia — a exclusão já exige senha, e outbox e
reconciliação independem de step-up. Pode começar hoje. **Não declaradas:** BT-DB-005 (relações
ML suplementares — por exemplo, `optimization_analysis_logs` guarda listas de cartas
removidas e adicionadas sem `user_id`, em `server/lib/ai/optimize_analysis_support.dart:206-228`,
e fica fora do export e da exclusão), BT-DR-001 (backups são consumidor) e BT-SEC-AI-002 (Sentry
e logs são consumidor). *(A "promoção de `learning_writes`" saiu desta lista na revisão: já
está coberta por `BT-AI-030` → `BT-PRIV-002` e pela regra da classe P0 LEARNING.)*
**Sobreposição:** PRIV-003 (mesmo inventário), PRIV-001 (mesmas rotas, mesma lista de relações
— 3 tabelas faltam nos dois), **`BT-AI-030`** (o consumidor Hermes deste outbox *é* o purge
de learning daquela tarefa: se o trabalho for contado nas duas, o plano conta duas vezes) e
**`BT-BAT-002`** (o mesmo `DELETE` de `:875-904`).

---

## BT-KPI-001 — Eventos, coortes, ativação, guardrails e política de telemetria

Backlog: `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md:233`.
Entrega: *"Definir eventos, coortes, métricas de ativação, guardrails e política de privacidade de telemetria."*
Aceite: *"Métricas contam usuários/loops de valor, não apenas eventos; nenhum decklist/UGC em analytics."*
Onda: `01-platform-safety.md:15` (a versão original dizia `:17`), que diz *"esquema de eventos sem decklist/UGC/PII; dedupe e coorte por usuário; baseline antes de meta"*.

**Como está hoje.** Coletor em `server/routes/users/me/activation-events/index.dart`, com
allowlist de 11 nomes (`:10-22`) e grava em `activation_funnel_events`
(`server/database_setup.sql:1585-1599`). O app envia por
`app/lib/core/services/activation_funnel_service.dart`. As métricas agregadas saem de
`server/lib/commercial_metrics_service.dart` para `/health/commercial` e `/health/dashboard`.

| # | Asserção | Estado | Onde está | Teste | O que falta |
| --- | --- | --- | --- | --- | --- |
| 1 | Catálogo **único** de eventos, com app e servidor de acordo | PARCIAL — **quebrado hoje** | O app emite **4 eventos que o servidor rejeita com 400**: `onboarding_goal_selected`, `onboarding_experience_selected`, `onboarding_build_mode_selected` (`app/lib/features/home/onboarding_core_flow_screen.dart:146,155,170`) e `onboarding_task_started` (`:284`). O tracker padrão é o serviço real (`:63`) e a falha é engolida (`activation_funnel_service.dart:137-141`); como o receipt não é gravado, cada nova tentativa gera outro 400. O servidor aceita 3 nomes que ninguém emite (`base_choice_generate`, `base_choice_import`, `deck_optimized`). O doc de contratos lista 10 nomes; o código tem 11 (`server/doc/API_CONTRACTS_AND_DATA_MAP.md:91`) | `server/test/activation_events_contract_test.dart:7-35` chama-se *"backend accepts all activation events emitted by app deck flows"*, mas confere uma lista escolhida à mão e **não** pega os 4 rejeitados. `app/test/features/home/onboarding_core_flow_screen_test.dart:351-358` afirma que o app emite `onboarding_task_started`, com tracker falso. Cada lado está "testado"; o contrato entre eles, não | Um catálogo versionado (JSON sob `server/config` ou `docs/contracts`) lido pelos dois lados, e um teste de paridade que enumere todo emissor do app |
| 2 | Servidor rejeita evento fora do catálogo | PRONTO_SEM_PROVA | `activation-events/index.dart:46-52` | Só grep (`activation_events_contract_test.dart:37-46`) | Teste de rota: nome desconhecido → 400 sem linha gravada |
| 3 | Métricas de ativação contam **usuários distintos**, não eventos | NAO_ENCONTRADO — **o código faz o contrário** | `_activationFunnel` faz `COUNT(*)` por `event_name` (`commercial_metrics_service.dart:193-208`). `deck_created_per_signup` = eventos ÷ signups; `ai_used_per_signup` = soma de 3 contagens de eventos ÷ signups (`:210-224`, com `countAiActivationEvents` em `:58-61`). Um usuário com 10 decks vale 10; a razão passa de 1 | `server/test/commercial_metrics_service_test.dart:8-18` **consagra** a soma de eventos (3+2+1 = 6) | Reescrever com `COUNT(DISTINCT user_id)` por passo e fixture em PG que prove a semântica |
| 4 | **Coortes** | NAO_ENCONTRADO | `grep -i "cohort\|coorte"` no servidor = 0 (a única ocorrência no app é de comparação de replays de Battle). O funil mistura janelas: signups da janela (`:401-418`) contra eventos da janela de qualquer usuário (`:196-199`) | — | Coorte por semana de cadastro e funil por coorte |
| 5 | **Loops de valor** definidos e medidos | PARCIAL | O único número por usuário é `active_users` = usuários distintos com nota pós-jogo na janela (`:379-399`). Nenhum loop (por exemplo gerar → salvar → jogar → anotar → otimizar) está definido | — | Definição de produto e consulta por loop |
| 6 | **Dedupe** | PARCIAL | Cliente: `trackOnce` com receipt em `SharedPreferences` (`activation_funnel_service.dart:51-118`), usado só no onboarding. Os eventos de deck usam `track`, **sem dedupe** (`app/lib/features/decks/providers/deck_provider.dart:114`). Servidor: nenhum índice único (`database_setup.sql:1596-1599`) e `INSERT` sempre (`activation-events/index.dart:64-81`); o `idempotency_key` vai para `metadata` (`activation_funnel_service.dart:108`) e ninguém o lê | `app/test/core/services/activation_funnel_service_test.dart:53-97` prova a coalescência no cliente (1 requisição para 3 chamadas) | Índice único por `(user_id, idempotency_key)` ou `event_id`, e `trackOnce` (ou chave) nos eventos de deck |
| 7 | **Nenhum decklist/UGC em analytics**, garantido no servidor | PARCIAL | Hoje o app só manda enums, flags e tamanhos: `prompt_length` em vez do prompt e `commander_selected` booleano em vez do nome (`deck_provider.dart:1004-1016`); `recommendation_context` só com flags (`app/lib/features/decks/widgets/deck_optimize_flow_support.dart:12-30`). **O servidor aceita qualquer `metadata`** — mapa livre, sem chaves permitidas, sem tamanho (`activation-events/index.dart:58-62,79`) — e `source`/`format` em texto livre (`:54-55,76-78`). Qualquer conta existente pode gravar decklist ou texto livre, e a rota está aberta | Nenhum teste afirma o conteúdo de `metadata`, nem no app nem no servidor | Schema de `metadata` por evento (chaves, tipos, limites), `source`/`format` enumerados e rejeição do resto |
| 8 | Sem PII ou IDs internos em analytics | PARCIAL | O `idempotency_key` carrega o UUID do usuário (`app/lib/features/home/home_screen.dart:333`, `app/lib/main.dart:250`); `source_deck_id` (`deck_provider.dart:807`) e `post_game_note_id` (`deck_optimize_flow_support.dart:27-28`) vão em `metadata`. *(Revisão: o servidor aceita `deck_id` sem conferir o dono (`activation-events/index.dart:56,77`); a FK só exige que o deck exista (`database_setup.sql:1590`). Uma conta pode gravar eventos ligados ao deck de outra, e um `deck_id` que não é UUID vira 500 com `details: e`.)* | Nenhum | Tirar ou pseudonimizar; validar posse de `deck_id` |
| 9 | **Guardrails** definidos | PARCIAL | Existem alertas operacionais (ver OBS-001), o proxy de custo de IA no painel e um teto de custo aplicado no servidor — 120 ações de IA por mês na beta (`server/lib/plan_service.dart:94`; `CURRENT_PRODUCT_DECISION.md`, "Oferta única"). Mas nada está definido como guardrail **de KPI** (custo por usuário ativo, taxa de erro por loop, exclusões) | — | Lista de guardrails ligada às métricas de ativação |
| 10 | **Política de privacidade de telemetria** publicada | NAO_ENCONTRADO | A política pública tem 4 frases e não menciona telemetria, Sentry, retenção nem direitos (`web-public/src/app/legal/privacy/page.tsx:11-30`). O app tem um parágrafo (`app/lib/features/commercial/screens/legal_screen.dart:180`), também sem telemetria | — | Texto jurídico: o que coleta, finalidade, base legal, retenção, opt-out |
| 11 | **Retenção** dos eventos de analytics | NAO_ENCONTRADO | O job de limpeza faz 6 `DELETE`s em 5 tabelas e **não** toca `activation_funnel_events` (`server/bin/cleanup_optimize_telemetry.dart:230-272`) — crescimento sem limite | — | Prazo e inclusão no job |
| 12 | Métricas históricas sobrevivem à exclusão sem reter o indivíduo | NAO_ENCONTRADO | A exclusão apaga os eventos do titular (`user_data_privacy_service.dart:686-692`), o que reescreve o funil passado. Não há agregado desidentificado | — | Snapshot agregado periódico, desidentificado |
| 13 | **Baseline** medida antes de meta | NAO_ENCONTRADO | Sem tráfego (tudo OFF); nenhum documento de baseline | — | Prova viva após a coorte |

### O que realmente falta

A infraestrutura existe (tabela, coletor, cliente, painel); a **definição** não. As métricas
atuais contam eventos e dividem por signups — exatamente o que o aceite proíbe — e o teste
consagra isso. App e servidor divergem em 7 nomes de evento sem que nenhum teste perceba, e o
coletor, aberto no plano de controle, aceita `metadata` arbitrário: a garantia "nenhum
decklist/UGC" hoje depende só da disciplina do app. Não há coorte, loop, retenção, agregado
estável nem política publicada.

Unidades (revisadas): **~18 arquivos**. A lista original tinha ~12: `activation-events/index.dart`,
`commercial_metrics_service.dart`, `migrate.dart` + `database_setup.sql` (índice de dedupe,
talvez `schema_version`), `cleanup_optimize_telemetry.dart`, `activation_funnel_service.dart`,
`onboarding_core_flow_screen.dart`, `deck_provider.dart`, um novo catálogo de eventos, a
política pública, `legal_screen.dart` e o doc de contratos da API. A revisão somou os emissores
de ID cru que o próprio item 8 aponta — `home_screen.dart`, `main.dart`,
`deck_optimize_flow_support.dart` —, `verify_schema.dart`, `server/lib/legal_policy.dart:2` (a
versão de Privacidade que a política de telemetria obriga a subir), `user_data_privacy_service.dart`
(preservar o agregado antes de apagar eventos, item 12) e o job/tabela do snapshot agregado.
**9 testes** (eram 7): paridade de catálogo app↔servidor; rejeição de `metadata` fora do schema
(chave desconhecida, texto livre, tamanho); dedupe no servidor; funil por usuário distinto em
PG; coorte; retenção no job; reescrita de `commercial_metrics_service_test.dart:8-18`.
Acrescentados: `deck_id` de outro dono rejeitado; agregado histórico sobrevive à exclusão.
**Migração: sim** (índice único). **Decisão humana: sim, e é o grosso** — o que é ativação,
quais loops, coortes, guardrails, retenção, texto jurídico. **Prova viva:** sim (baseline).

**Dependência declarada (`BT-GOV-001`):** `PASS` → pode andar hoje. **Não declarada, e
importante:** publicar uma política de telemetria muda a versão de Privacidade, o que exige o
reaceite de `BT-LEGAL-ACCEPT-001` — mecanismo que a sessão irmã mediu como inexistente. Também
`BT-AUTH-001/002`: a mesma rota devolve `details: e` no 500 (`:84-88`, `:119-123`) e não limita
o body. **Sobreposição:** PRIV-001/002 (os eventos são exportados em `:181-189` e apagados em
`:686-692`), OBS-001 (guardrails = mesmos sinais de SLO), SEC-AI-002 (allowlist de campos).

---

## BT-OBS-001 — SLOs e alertas de API, PG, jobs, cache, catálogo e releases

Backlog: `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md:608`.
Entrega: *"SLOs e alertas de API, PG, jobs, cache, catálogo e releases."*
Aceite: *"Receiver humano, thresholds, alert test e runbook; PII excluída."*
Onda: `01-platform-safety.md:16` (a versão original dizia `:18`), que diz *"API/PG/jobs/cache/catalog/release com receiver humano, test alert e redaction"*.

**Como está hoje.** `server/lib/operational_alerts.dart` avalia thresholds versionados
(`:28-47`) sobre snapshots de requisição, jobs de IA, provider, Battle e Coach (`:49-85`).
A avaliação só acontece quando alguém chama `GET /health/dashboard`
(`server/routes/health/dashboard/index.dart:34-40`), atrás de ops key ou admin
(`server/routes/health/_middleware.dart:5-13`). O único script que lê os endpoints `/health`
é um gate manual que exige aprovação de mutação live (`scripts/manaloom_commercial_quality_gate.sh:9-10,144-146`).

| # | Asserção | Estado | Onde está | Teste | O que falta |
| --- | --- | --- | --- | --- | --- |
| 1 | **SLOs** definidos (objetivo, janela, orçamento) | NAO_ENCONTRADO | `grep -i -w "slo\|slos\|error_budget"` em `server`, `app/lib` e `scripts` = 0 | — | Arquivo versionado de SLO por superfície |
| 2 | Alertas de **API** (taxa de 5xx, p95 por endpoint) com thresholds | **PARCIAL** (rebaixada de PeP) | Avaliador em `operational_alerts.dart:87-125`. **O sinal que o alimenta não serve para alerta:** `RequestMetricsService` soma `request_count`/`error_count` **desde o start do processo, sem janela de tempo** (`request_metrics_service.dart:36-37,81-103`), e `_requestAlerts` lê essa taxa vitalícia (`operational_alerts.dart:90-92`). Um processo com uma semana no ar e 1 M de requisições a 0,1% de erro passa a ~1,1% durante um apagão que gere 10 mil 5xx em 10 min: abaixo do aviso de 5% (`:32`), **sem alerta**. O p95 por endpoint exige ≥ 10 amostras por chave (`:30,111`), e a chave é o caminho cru (`_middleware.dart:60-61`), então rotas com ID (`/decks/<uuid>`) se fragmentam e quase nunca chegam ao piso | `operational_alerts_test.dart:30-51` e `:82-102` provam só o avaliador sobre **snapshots sintéticos** com chave sem ID (`'GET /decks'`, `:35`); nada exercita o sinal real. Roda no `full` | Janela de tempo (anel por minuto ou contagem em PG), chave pelo template da rota e teste do sinal real |
| 3 | Alertas de **PG** (pool, latência, conexões, disco) | NAO_ENCONTRADO | Só sinais adjacentes: falha de persistência de Battle e Coach (`:237-249`, `:325-335`). O readiness checa schema e conectividade (`server/lib/health_readiness_support.dart:635-669`) sem threshold | — | Instrumentar `server/lib/database.dart`; thresholds dependem de BT-CAP-001 |
| 4 | Alertas de **jobs** | PARCIAL | IA, Battle e Coach: `:127-354`. Os 16 jobs de cron do daemon não têm alerta: o daemon só grava estado (`server/bin/manaloom_ops_daemon.py:565-708`) e o relatório "governor" só escreve arquivo e imprime (`server/bin/hermes_cron_governor_report.py:230-248`) | IA/Battle/Coach provados em `operational_alerts_test.dart:53-80,104-137,139-182` | Alerta de falha e atraso por job de cron |
| 5 | Alertas de **cache** | NAO_ENCONTRADO | `EndpointCache` não tem contador (`server/lib/endpoint_cache.dart:8-36`) | — | Hit/miss/tamanho e threshold |
| 6 | Alertas de **catálogo** (frescor, sync) | NAO_ENCONTRADO | `sync_state` só é lido por `/rules?meta` (`server/routes/rules/index.dart:89`); nenhum sinal de frescor no readiness nem nos alertas. *(Revisão — há medição do custo da falta, registrada num documento de proposta sem autoridade (`PROPOSAL · NO_AUTHORITY`): em 2026-09-18 o catálogo tinha 104 dias e o EDHREC 108 sem nenhum alerta, e os 8 scripts de sync nunca foram registrados no daemon (`docs/execution/PROPOSED_TASKS_DECK_QUALITY_2026-09-18.md:41-46`). O alerta nasceria disparado e depende de agendar o sync, que é outra tarefa.)* | — | Idade do último sync de catálogo e legalidades |
| 7 | Alertas de **release** | PARCIAL | Existem sinais sem regra: prova de startup do app no Sentry com SHA e digest (`app/lib/core/observability/app_observability.dart:150-230`), readiness do schema de release (`health_readiness_support.dart:635-669`) e `git_sha` no `/health` lido pelo gate manual (`manaloom_commercial_quality_gate.sh:183`) | — | Regra: SHA divergente, prova de startup ausente, deploy falho |
| 8 | Thresholds **versionados** e testados | **PRONTO_SEM_PROVA** (rebaixada de PeP) | `operationalAlertThresholdsVersion = 2` (`:28`) ecoado no payload (`:81`); valores em `:29-47` | `operational_alerts_test.dart:27` é **tautológico**: compara o campo do payload com a própria constante. Nada liga os valores à versão — mudar `_criticalErrorRate` (`:33`) sem subir a versão passa em todos os testes. O "testado" vale para o comportamento (`:30-51`, `:53-80`, `:82-102`, `:104-182` disparam acima do limiar), não para o versionamento; e os valores não vêm de SLO nenhum (item 1) | Teste de snapshot que fixe valores e versão juntos (1 teste) |
| 9 | **Receiver humano** | NAO_ENCONTRADO | Nada agenda a avaliação nem entrega alerta: `grep` por `telegram`, `slack`, `pagerduty`, `opsgenie`, `discord`, `ALERT_WEBHOOK` e `ntfy` em `server/lib`, `server/bin` e `scripts` = 0; os únicos webhooks são os de email de reset e verificação (`server/lib/auth_runtime_policy.dart:16-19`). Nenhum check-in de cron do Sentry | — | Avaliador agendado (job do daemon) + canal + dedupe + ack; dono nomeado |
| 10 | **Alert test** (sintético ponta a ponta, reconhecido) | NAO_ENCONTRADO | — | Os testes são unitários de função pura | Disparo sintético entregue a um humano, com receipt de ack |
| 11 | **Runbook** | PARCIAL | Cada alerta traz uma linha de `action` (por exemplo `:101-102`, `:122`, `:142`). Os runbooks em `docs/` são **históricos**: `docs/EASYPANEL_RUNBOOK_MTGIA_2026-03-24.md:3`, `docs/SENTRY_SETUP_MTGIA_2026-03-24.md:3`, `docs/MANALOOM_PRODUCT_READINESS_RUNBOOK_2026-07-06.md:3` | — | Runbook vigente por alerta, com lifecycle ativo |
| 12 | **PII excluída** | PARCIAL | Bom: `sendDefaultPii = false` + `beforeSend` sanitizando (`server/lib/observability.dart:318-327`); log mascara email e segredos (`server/lib/log_sanitizer.dart:1-58`); app idem (`app_observability.dart:126-129`). Ruim: **UUID cru do usuário** vai ao Sentry (`observability.dart:371` e `:427`, via `server/routes/_middleware.dart:289,309`) e ao log (`user_id=` em `_middleware.dart:300`). **A chave de métrica é o caminho cru** (`_middleware.dart:60-61`, gravado em `:201-205`), então IDs de deck e usuário entram nos códigos de alerta (`endpoint_p95_*:GET /decks/<uuid>`, `operational_alerts.dart:117`) e a cardinalidade não tem limite (vetor de memória). O doc de contratos afirma "no user/deck/request/replay/process identity" no painel (`server/doc/API_CONTRACTS_AND_DATA_MAP.md:472`) — falso para a seção de requisições. *(Revisão: o caminho cru também vai ao Sentry como tag `http_path` (`observability.dart:361,417`) e no título da mensagem `'HTTP $classification: $endpoint'` (`_middleware.dart:310`) — IDs de deck e usuário em tag e título, o que ainda quebra o agrupamento de eventos.)* | `server/test/observability_test.dart:9-117` prova a sanitização e **consagra** o ID cru: `:88` afirma `sanitized.user!.id == 'user-1'` | Normalizar a chave, a tag e o título para o template da rota; pseudonimizar ou remover `user_id` (overlap total com SEC-AI-002) |
| 13 | Métricas de requisição sobrevivem a restart, somam réplicas e têm **janela** (pré-requisito de SLO) | PARCIAL | `RequestMetricsService` é mapa em memória por processo (`server/lib/request_metrics_service.dart:62-67`); com mais de uma réplica o painel mostra só a que respondeu, e zera no restart. *(Revisão: e não tem janela — os contadores acumulam desde o start (`:36-37`), e o mapa cresce sem limite, uma chave por caminho cru (`:66,74`).)* As métricas de IA vêm do PG, são globais e têm janela de 24 h (`routes/health/dashboard/index.dart:100-104`) | — | Persistir com janela (PG ou TSDB) ou raspar por réplica. SLO com orçamento de erro de 28–30 dias **não se calcula** sobre contador em memória que zera no deploy |

### O que realmente falta

O avaliador é bom e está testado — mas é **pull-only**: um alerta só "acontece" se alguém abrir
`/health/dashboard` com a chave de ops. Não há SLO, não há quem receba, não há teste de alerta
e não há runbook vigente. Das seis áreas da entrega, jobs de IA/Battle têm threshold sobre
sinal com janela; a API tem threshold sobre um sinal **cumulativo, sem janela e fragmentado
por caminho cru** (revisão: não serve de alerta sem refazer a métrica); release tem sinais sem
regra; e PG, cache e catálogo não têm nada. A exclusão de PII é boa contra segredos e email,
mas não contra IDs: o UUID do usuário vai cru ao Sentry e ao log (e um teste exige isso), e o
caminho cru vira chave de métrica, código de alerta, tag e título no Sentry.

Unidades (revisadas): **~19 arquivos**. A lista original tinha ~14: `operational_alerts.dart`,
`request_metrics_service.dart`, `routes/_middleware.dart`, `observability.dart`,
`endpoint_cache.dart`, `database.dart`, `health_readiness_support.dart`, um novo arquivo de SLO
+ carregador, um novo despachante de alertas, `manaloom_ops_daemon.py` (agendamento; atualizar o
fluxo `ops_scheduler`), `routes/health/dashboard/index.dart`, runbook novo,
`docs/project_logic_contracts.json` e o doc de contratos da API. A revisão somou: persistência
com janela das métricas de requisição (`migrate.dart`, `database_setup.sql`, `verify_schema.dart`,
se for PG); a fonte do alerta de cron (estado do daemon / `hermes_cron_governor_report.py`); e
a fonte do alerta de release (prova de startup/identidade por superfície). **13 testes** (eram
8): parse e validação do SLO; thresholds de PG, de cache, de catálogo e de release (4 fontes
diferentes, 4 testes; a lista original os contava como um só); normalização da chave (sem
UUID); `user_id` fora do Sentry e do log (reescrevendo `observability_test.dart:88`); dedupe e
ack do despachante; alerta sintético ponta a ponta; avaliação agendada. Acrescentados: taxa de
5xx com janela (um apagão após longo uptime **dispara**); alerta de falha/atraso de job de cron;
snapshot que trava valores de threshold e versão juntos.
**Migração: provável** (revisão; a versão original dizia "não obrigatória"). SLO com orçamento
de erro exige série durável e com janela, e o contador atual é em memória, cumulativo e por
réplica. Ou é tabela em PG (migração), ou TSDB externo (serviço externo). O estado de ack pode
viver no daemon.
**Decisão humana:** alvos de SLO, quem é o receiver e on-call, canal, thresholds de PG e catálogo.
**Serviço externo: sim** — canal de alerta (o envio de email via Resend já integrado,
`5dabb08c4`, é candidato natural; ou Telegram/PagerDuty). **Prova viva:** sim (alerta entregue e
reconhecido, com captura).

**Dependência declarada (`BT-KPI-001`):** fraca. SLO e alerta de API, PG e jobs não dependem de
métrica de produto; o único elo é a política de PII. Pode começar hoje. *(Revisão: o alerta de
catálogo depende, na prática, de o sync de catálogo ser agendado — os 8 scripts não estão no
daemon —, senão só confirma o óbvio.)* **Não declaradas:**
`BT-CAP-001` (thresholds de PG e host precisam de capacidade medida), `BT-SEC-AI-002` (a parte
"PII excluída" é esse trabalho), `BT-REL-002` (alerta de release precisa da identidade por
superfície). **Sobreposição:** `BT-OBS-002` (receiver idempotente com ack — mesmo mecanismo,
declarado como filho), `BT-BAT-008` ("alerta sintético reconhecido" para Battle — mesmo receiver),
`BT-SEC-AI-002`.

---

## Achados transversais do grupo

1. **Testes que dão falsa garantia.** Cinco testes afirmam o oposto da realidade ou consagram o
   defeito: `user_data_privacy_contract_test.dart:60` ("sem `request_fingerprint`", enquanto três
   tabelas o exportam por `to_jsonb`); `activation_events_contract_test.dart:7-35` ("aceita todos
   os eventos do app", enquanto 4 são rejeitados); `commercial_metrics_service_test.dart:8-18`
   (consagra a soma de eventos); `observability_test.dart:88` (consagra o UUID cru no Sentry);
   `privacy_account_live_test.dart:145-149` (consagra export com bearer simples — achado da
   sessão irmã, reconfirmado). Os de grep no fonte rodam no `full`. O live passou uma vez
   (receipt S1-05, 2026-07-21) sobre código anterior e hoje não roda em lugar nenhum.
   *(Revisão — mais dois que afirmam menos do que parecem: `operational_alerts_test.dart:27`
   compara a constante de versão com ela mesma; e `operational_alerts_test.dart:30-51` prova o
   avaliador com um snapshot sintético sem ID, enquanto o sinal real é cumulativo e fragmentado.)*

2. **Eixo ABERTO: os quatro tocam rotas do plano de controle alcançáveis com tudo OFF**
   (`release_capability_policy.dart:598-600,611-612,615-616`). O vazamento de fingerprint e a
   ausência de auditoria (PRIV-001), as tabelas não tratadas (PRIV-002) e o coletor de `metadata`
   sem schema (KPI-001) são alcançáveis **hoje** por qualquer conta existente.

3. **Uma classificação por coluna resolve cinco tarefas.** Allowlist de export (PRIV-001), plano
   de exclusão e consumidores (PRIV-002), inventário de retenção (PRIV-003), schema de analytics
   (KPI-001) e allowlist de sinks (SEC-AI-002) são a mesma tabela lida de cinco jeitos. O registry
   põe PRIV-003 depois de PRIV-001/002; na prática, é o insumo das duas.

4. **O sidecar de aprendizado é o vazamento mais concreto do grupo:** `deck_id` cru e até 200
   cartas por evento no SQLite Hermes (`pull_learning_events.py:94-101,381,388`), sem purga na
   exclusão. Só está contido porque `learning_writes` está OFF. ~~Promover `learning_writes`
   deve depender de BT-PRIV-002 — não está declarado.~~ *(Correção da revisão: está declarado.
   `BT-AI-030` (P0 LEARNING, backlog `:451`) é exatamente esse purge e depende de `BT-PRIV-002`,
   e a classe P0 LEARNING bloqueia qualquer escrita de learning (`:157`). O risco real é outro:
   contar o consumidor Hermes duas vezes, em PRIV-002 e em AI-030.)*

5. **IDs crus na observabilidade:** a chave de métrica é o caminho cru (IDs em códigos de alerta,
   cardinalidade sem limite, vetor de memória) e o `user_id` vai cru ao Sentry e ao log. O doc de
   contratos diz o contrário para o painel. É o mesmo trabalho de SEC-AI-002.

6. **As dependências declaradas quase não bloqueiam.** PRIV-001 e PRIV-002 podem começar sem
   AUTH-004 (só o fechamento de PRIV-001 depende dela); GOV-001 já é `PASS`; OBS-001 não depende de
   verdade de KPI-001. **As reais e não declaradas:** CAP-001 (OBS), LEGAL-ACCEPT-001 (publicar
   política de telemetria muda a versão de Privacidade — `server/lib/legal_policy.dart:2` — e o
   aceite só é lido no cadastro, sem reaceite), DR-001 e DB-005 (consumidores da exclusão).
   *(Revisão: SEC-001 saiu desta lista — o aceite de AUTH-004, dependência declarada de PRIV-001,
   já exige "rate limit distribuído". Entraram as sobreposições declaradas e não citadas:
   `BT-BAT-002` (posse A/B das simulações, no export e na exclusão) e `BT-AI-030` (purge Hermes).)*

7. **O gargalo é decisão humana, não código.** Definição de ativação e loops, alvos de SLO e
   receiver, onde guardar o artefato de export e por quanto tempo, lista de consumidores e prazos
   da exclusão, texto jurídico. Sem isso, a engenharia só consegue fazer a metade mecânica: os
   consertos de fingerprint e IDs, as 7 relações da exclusão, a chave de métrica (com janela), a
   paridade de eventos e o schema de `metadata` — e vale fazê-la já, porque é a parte aberta hoje.

8. **Nenhuma tarefa foi resolvida às escondidas.** Todo o código que as quatro tarefas medem é
   anterior ao backlog; depois dele só mudou código de contenção (b2d3fc04f, 406d7dd53), que não
   fecha nenhuma. Os `TODO` estão corretos quanto ao fechamento, mas escondem uma diferença grande
   de ponto de partida: PRIV-002 tem o substrato Postgres implementado (sem prova vigente);
   KPI-001 tem o oposto implementado.

---

## Verificação adversarial (revisor cético, 2026-09-22, mesmo HEAD `d15beb05b`)

Somente leitura; nada foi executado. Abri cada teste citado como prova e cada `arquivo:linha`
das asserções PRONTO_SEM_PROVA. Reexaminei 36 das 50 asserções contra o código. As correções
foram feitas no corpo do documento, marcadas com *"Revisão"* ou *"Correção da revisão"*.

### Critério aplicado

PRONTO_E_PROVADO passou a exigir duas coisas: (a) um teste que afirme a asserção **inteira**, e
(b) registro de execução — gate que roda hoje ou receipt cujo código não mudou depois. O
documento original usava um critério mais fraco ("existe um teste e eu o abri") e mesmo assim
contou como PeP três asserções cujo único teste é um live que **não roda** com as capabilities
OFF. Essa diferença de critério explica a maior parte do que caiu.

### O que caiu

| Tarefa | Asserção | De → Para | Por quê |
| --- | --- | --- | --- |
| BT-PRIV-001 | #5 Segredos omitidos | PeP → **PsP** | `privacy_account_live_test.dart:168-178` não exercita mensagens de terceiros nem corpo de notificação (a conta do teste não tem nenhum, `:80-137`). A checagem de JWT procura `'bearer '` (`:174`), não o token. A prova S1-05 é anterior às 6 relações de Battle hoje exportadas |
| BT-PRIV-002 | #2 Núcleo PG atômico | PeP → **PsP** | O live não consulta o banco depois da exclusão: nenhuma linha apagada ou pseudônimo é verificado. As "falhas preservam a conta" (`:180-212`) são validações anteriores a qualquer escrita (serviço `:615-623` × primeiro DELETE `:636`), então a atomicidade não é exercitada. A prova é anterior a +211 linhas do serviço |
| BT-OBS-001 | #2 Alertas de API (5xx, p95) | PeP → **PARCIAL** | O teste prova o avaliador com snapshot sintético. O sinal real é cumulativo desde o start do processo, sem janela (`request_metrics_service.dart:36-37,81-103`): depois de uma semana no ar, um apagão de 10 mil 5xx fica em ~1,1% e não alerta (limiar de 5%, `operational_alerts.dart:32`). O p95 por chave crua raramente atinge o piso de 10 amostras (`:30,111`) |
| BT-OBS-001 | #8 Thresholds versionados e testados | PeP → **PsP** | `operational_alerts_test.dart:27` compara a constante com ela mesma. Nada trava os valores (`:29-47`) na versão (`:28`) |
| BT-PRIV-002 | status medido | metade → **mal-começada** | Sem o PeP, sobram 0 PeP, 2 PsP, 5 PARCIAL e 4 NAO. O núcleo PG é o substrato; o objeto da tarefa (outbox, consumidores, receipt por consumidor, retry idempotente, reconciliação fora do PG) está em 0% |

### O que resistiu ao ataque

- **PRIV-001 #11 (não cacheável), mantida em PeP.** O live afirma exatamente os headers e passou
  em S1-05. Desde então a rota só trocou o prefixo do nome do arquivo (8264ffb27).
- **PRIV-001 #8 (A/B estrutural), PsP confirmada.** `users/_middleware.dart:4-6` aplica
  `authMiddleware` a `/users/*`, e `exportUserData` tem um único chamador
  (`export/index.dart:15`), sem parâmetro de alvo.
- **PRIV-001 #10 (snapshot), PsP confirmada.** As 34 consultas e as 34 checagens de
  `to_regclass` usam a mesma `session` da `runTx` `REPEATABLE READ`/`readOnly` (`:24`,
  `:591-594`, `:995-1007`).
- **PRIV-002 #3 (nada recria no PG), PsP confirmada.** O desenho fecha a corrida: o guard espera
  o `FOR UPDATE` da exclusão e reavalia `deleted_at`; as escritas em `users` e os fluxos de
  token também exigem conta ativa. Falta uma guarda de regressão para FKs novas.
- **KPI-001 #2 (rejeita nome fora do catálogo), PsP confirmada** (`activation-events/index.dart:50-52`).
- Todas as NAO_ENCONTRADO que reabri se mantêm: job de export, expiração, auditoria, outbox,
  sidecar, arquivos, falha fechada, coorte, política, retenção, agregado, baseline, SLO, PG,
  cache, catálogo, receiver e alert test. Não achei implementação que o autor tenha perdido.

### O que subiu (justiça no outro sentido)

Nenhuma asserção subiu de estado. Mas quatro afirmações do documento eram **mais duras** do que o
código e o backlog justificam, e foram corrigidas:

1. "Nenhum receipt cita o live": **existe** — S1-05 (`docs/qa/MANALOOM_SPRINT1_DATA_SESSION_EVIDENCE_2026-07-21.md:133-160`),
   1/1 PASS em PG descartável, com hash que bate com `776b9e25d`. A prova existe; está vencida.
2. "Promover `learning_writes` não depende de PRIV-002": **depende**, via `BT-AI-030` (`:451`) e
   a classe P0 LEARNING (`:157`).
3. "SEC-001 é dependência não declarada de PRIV-001": o aceite de `BT-AUTH-004` (`:261`) já
   exige rate limit distribuído.
4. "Falha do export sem log nem Sentry": o middleware registra o 500 (`_middleware.dart:273-310`).
   Não é auditoria, mas há rastro.

E uma afirmação estava errada no sentido otimista: a "observação de desenho" sobre apagar
simulações de terceiros é **bug já registrado** (`BT-BAT-002`, linha 463), não decisão em aberto.

### Lacunas novas que a medição original não contou

- **Export incompleto além do citado:** `deck_matchups` e `deck_weakness_reports` (deck-derivadas,
  fora do export). `_optionalJsonRows` omite em silêncio relação ausente (`:995-1007`), o que
  afeta `deck_optimization_events` em banco criado pelo baseline.
- **Exclusão:** `content_reports.evidence` não é limpo (`:767-769`); `trade_items` e
  `moderation_actions` ficam intactos e fora do `retention_summary`; a limpeza de
  `rate_limit_events` usa o formato de identificador errado (`:928-929` × `'user:<uuid>'`); a
  exclusão de conta ignora o lock de ciclo de vida da Battle interativa
  (`interactive_battle_deck_lifecycle.dart:13-66`); `EndpointCache.clearExpired` não tem
  chamador, então o TTL não tira nada da memória.
- **KPI:** `deck_id` de outro dono é aceito no coletor (`activation-events/index.dart:56,77`).
- **OBS:** taxa de 5xx sem janela; caminho cru também na tag `http_path` e no título do Sentry
  (`observability.dart:361,417`; `_middleware.dart:310`).
- **Linhas erradas:** onda de KPI é `:15` (não `:17`) e de OBS é `:16` (não `:18`); o cleanup faz
  6 `DELETE`s em 5 tabelas.

### Números revisados

| Tarefa | Status | PeP/PsP/PARCIAL/NAO | Arquivos | Testes | Migração |
| --- | --- | --- | --- | --- | --- |
| BT-PRIV-001 | mal-começada (=) | 2/2/6/3 → **1/3/6/3** | 14 → **~20** | 8 → **11** | sim (=) |
| BT-PRIV-002 | metade → **mal-começada** | 1/1/5/4 → **0/2/5/4** | 16 → **~22** | 9 → **12** | sim (=) |
| BT-KPI-001 | mal-começada (=) | 0/1/6/6 (=) | 12 → **~18** | 7 → **9** | sim (=) |
| BT-OBS-001 | mal-começada (=) | 2/0/5/6 → **0/1/6/6** | 14 → **~19** | 8 → **13** | não → **provável** |
| **Grupo** | | 5/4/22/19 → **1/7/23/19** | 56 → **~79 (+41%)** | 32 → **45 (+41%)** | |

### Veredito de otimismo: **otimista demais** — nos números que o dono vai usar para planejar

Os vereditos qualitativos estavam quase todos certos: três das quatro tarefas eram de fato
"mal-começadas", e o documento achou os defeitos mais graves (vazamento de fingerprint, A/B de
`battle_simulations`, métrica que conta eventos, UUID cru no Sentry). O otimismo está onde o
plano se apoia:

- **4 dos 5 "PRONTO_E_PROVADO" caíram.** O grupo inteiro tem **1** asserção provada, e mesmo
  essa por um receipt de julho.
- **PRIV-002 foi vendida como "metade"** quando o objeto da tarefa está em zero.
- **Arquivos e testes estavam ~40% abaixo**, e OBS-001 omitia a migração que o SLO exige.
- **A prova comportamental do grupo inteiro é um único teste live**, que passou uma vez antes de
  +211 linhas de código e hoje não consegue rodar. Até alguém reescrevê-lo com conta semeada e
  colocá-lo num gate, nenhuma das quatro tarefas tem prova vigente.
