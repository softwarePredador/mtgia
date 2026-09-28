# Receipt — BT-PRIV-002: consumidores da exclusão, expurgo do Hermes e reconciliação do outbox — 2026-09-28

- **Tarefa:** `BT-PRIV-002` (P0 CORE, `IN_PROGRESS_CONTAINED`), Frente A (servidor), branch
  `servidor/rodada2-2026-09-24`.
- **Aceite do backlog:**
  - nenhum runtime ativo recria dado;
  - o retry é idempotente;
  - cada consumidor tem receipt.
- **Decisões do dono que valem aqui:**
  - D-23: exclusão por outbox, caches com TTL de até 24 h, Sentry sem o ID do usuário e
    retenção do provedor documentada, backups não reescritos;
  - D-68: o outbox, com a lista fechada de consumidores;
  - D-69: backups em 30 dias, como ponto de partida;
  - D-77: o sidecar dado como limpo pelo tempo máximo da sessão.
- **Base:** esta rodada parte do que a frente de privacidade entregou.
  - Rodada 1, `c0f907108`, no ar desde 2026-09-23. A exclusão confere as relações. O
    `EndpointCache` ganhou teto de 24 h. O Sentry do servidor deixou de receber o usuário.
  - Rodada 2, `81841e234`, com as migrations 059 e 060. Trouxe o outbox com lease, o intervalo
    crescente até 24 h, o teto de 20 tentativas e o recibo por execução.
  - Rodada 3, `08642b97e`. Trouxe a D-77 e a D-78. Ela entrou nesta branch pelo merge da
    branch `privacidade/rodada3-2026-09-24` (`24553dd62`), num commit próprio.
- **Sem migration.** A 070 e a 071 não foram usadas: o consumidor do Hermes já estava no CHECK da
  060, e a reconciliação só insere no outbox.
- **Nada tocou a produção.** Os testes rodaram num PostgreSQL 17 descartável, com SQLite
  temporários.

## Consumidores: estado e o que falta

### Os cinco do outbox (lista fechada da D-68)

| Consumidor | Antes desta rodada | Agora | O que falta |
| --- | --- | --- | --- |
| `hermes_learning_sqlite` (knowledge.db na imagem de ops) | bloqueado (`blocked_hermes_purge_not_implemented`); decklists de conta excluída ficavam no SQLite | **apaga.** O job varre o arquivo, acha pelo HMAC dos tombstones os decks apagados, apaga os eventos e as cópias sob o lock de escrita do SQLite e conclui (`purged_by_tombstone_sweep`) | nada no escopo do consumidor. O resíduo está no fim desta seção |
| `interactive_battle_sidecar` | conclui 2 h 10 min depois da exclusão (D-77) | igual | nada. O Battle está desligado na produção (D-57) |
| `endpoint_cache` | conclui 24 h 5 min depois (teto do `EndpointCache`) | igual. Também cobre a cópia em memória dos jobs de Optimize (30 min, artefato novo `optimize_job_memory`) | nada |
| `sentry` | conclui na hora: o servidor não manda o usuário | igual | o Sentry do app ainda manda o ID (raia do app); a retenção do plano é conferida pelo dono |
| `backups` | bloqueado (`blocked_backup_rotation_not_applied`) | **segue bloqueado** | a rotação não está aplicada. A D-69 diz 30 dias, o BT-DR-001 recomenda 14, e apagar dump pede o sim do dono. Decisão pendente |

**Resíduo do Hermes.** O `sync_pg_target_deck_to_hermes.py` não confere se o deck ainda existe
sob o lock.
- Rodado à mão, em paralelo com o outbox, ele pode regravar a cópia de um deck apagado. A cópia
  fica até a varredura seguinte.
- No agendador, o `master_optimizer_preflight`, que chama esse script, roda em sequência com o
  outbox e está desligado por capability.

### Jobs do daemon de ops (`manaloom_ops_daemon.py`)

O daemon roda os jobs comuns em sequência, e cada um tem um `flock` próprio.

| Job | Toca dado de conta? | Pode recriar dado? |
| --- | --- | --- |
| `manaloom_account_deletion_outbox` | é o executor dos consumidores | não: só apaga e fecha linhas |
| `manaloom_ai_runtime_cleanup` | apaga por prazo | não |
| `pull_learning_events` (`learning_writes`, OFF) | copia `deck_learning_events` para o SQLite | **não, desde esta rodada.** Só grava evento que ainda existe no PostgreSQL, conferido depois de pegar o lock de escrita do SQLite |
| `auto_sync_learned_decks`, `auto_promote_learned_decks` (`learning_writes`, OFF) | leem os learned decks do Hermes, que são dado do laboratório | não: só simulam (`--apply` bloqueado, DCK-P0-05) |
| `manaloom_knowledge_import` (`learning_writes`, OFF) | auditoria do corpus em Markdown | não: só relatório (BT-AI-014) |
| `master_optimizer_preflight` (`ai_analyze_optimize_advisory` e `battle_batch`, OFF) | copia um deck-alvo do PostgreSQL (o canônico por padrão) para o SQLite | a cópia de deck apagado sai na varredura do Hermes; o resíduo está acima |
| `hermes_mana_base_validator` (`ai_analyze_optimize_advisory`, OFF) | lê os decks do Hermes e grava um relatório | não recria no banco; o relatório é artefato de ops |
| Regras e estratégia de Battle, cinco jobs (`battle_batch`, OFF) | cartas, regras e decks do Hermes | não |
| Catálogo, quatro jobs | dado de referência | não |
| `hermes_cron_governor_report` | estado do agendador | não |
| Sidecar e worker nativos de Battle (Battle OFF) | `battle_jobs` | não: a exclusão apaga os jobs da conta, e as escritas são por id |

### O que roda dentro da API

- **Autenticação.** Todo pedido confere `users.deleted_at` (`AuthService.getUserFromToken`).
  O token de uma conta excluída é recusado no primeiro pedido.
- **Toda escrita que aponte para conta excluída é recusada no banco.** O gatilho de conta ativa
  (`manaloom_require_active_user`, em toda chave para `users`) responde 23503
  `inactive_user_reference`.
- **Jobs assíncronos de Optimize e Generate.**
  - A exclusão apaga as linhas deles.
  - O job em andamento escreve com `UPDATE ... WHERE id AND status`, então não recria a linha.
  - A leitura do job sempre vai ao PostgreSQL.
- **Battle e Jogar contra IA** estão desligados na produção. A exclusão apaga os jobs e as
  sessões da conta, e o sidecar esquece a partida pelo tempo (D-77).

### Caches em memória

| Onde | Guarda | Prazo | Situação |
| --- | --- | --- | --- |
| `EndpointCache` | análise de arquétipo, Generate e catálogo | teto de 24 h; sai na varredura | fechado pelo outbox (`endpoint_cache`) |
| `OptimizeJobStore` (memória) | id, deck, usuário e resultado do job | 30 min; sai na chamada seguinte | não é servido depois da exclusão; entrou no inventário (`optimize_job_memory`) |
| `RequestMetricsService` | caminho cru com UUID | até reiniciar | lacuna nesta branch; o BT-OBS-001 (`2d1f2cc52`, na integração) troca a chave pelo template da rota |
| `RateLimiter` em memória (busca de catálogo) | horários por IP | janela de 1 min | sem ID de conta; o limite por conta fica no PostgreSQL (`rate_limit_events`), que a exclusão apaga |
| Cache do `EdhrecService` | dado por comandante | processo | sem dado pessoal |
| Memória do sidecar de Battle | partida viva | 7200 s + 10 min | fechado pelo outbox (D-77) |

### Arquivos, artefatos e provedores

| Artefato | Situação | O que falta |
| --- | --- | --- |
| knowledge.db do Hermes | limpo pelo outbox | nada |
| Artefatos de ops (`/data/manaloom-ops`: saída dos jobs e relatórios) | entrou no inventário (`ops_artifacts`) | prazo de rotação (decisão do dono) |
| Logs do servidor | `user_id` cru em erros e pedidos lentos | pseudonimizar (`BT-SEC-AI-002`); prazo da rotação do host |
| Log dos pedidos de exportação | 90 dias (D-78) | aplicar a rotação no host (dono) |
| Arquivo da exportação | não é guardado (D-22) | nada |
| Backups | não são reescritos (D-23) | rotação (acima) |
| Aparelho e Sentry do app | raia do app | limpar o aparelho e tirar o ID do Sentry do app |
| Provedores: OpenAI, Resend e Firebase | sem exclusão por titular; o `fcm_token` sai da conta | conferir a retenção nos contratos (dono, D-69) |
| Laboratório Hermes (imagem `hermes-lab`) | pesquisa e corpus; não puxa evento de conta | nada |

## O que mudou

1. **`server/lib/privacy/hermes_learning_purge.dart` (novo), o consumidor do Hermes.**
   - Na primeira linha vencida de cada execução, o job faz a varredura:
     - `hermes_learning_purge.py list` lê os ids de deck que o arquivo guarda;
     - o PostgreSQL diz quais são de deck apagado. O HMAC do id, com cada chave da
       `privacy_keyring`, precisa bater com um tombstone, e a chave não sai do banco;
     - `hermes_learning_purge.py purge` apaga sob o lock de escrita do SQLite e lista de novo, ainda
       sob o lock;
     - se sobrou deck apagado, repete, até 3 rodadas.
   - O `purge` roda mesmo sem nada a apagar, porque só a lista feita sob o lock prova o estado do
     arquivo.
   - Cada linha confere que nenhum dos decks dela ficou e conclui.
   - As contagens do que foi apagado vão uma vez por execução.
   - **Falhas:**
     - sem caminho configurado: `hermes_knowledge_db_not_configured`;
     - pasta ausente, ou seja, volume não montado: `hermes_knowledge_db_dir_missing`;
     - arquivo ocupado: `hermes_knowledge_db_busy`;
     - erro do auxiliar: `hermes_purge_helper_error`;
     - deck apagado que não sai: `hermes_purge_incomplete`.

     Cada falha volta pelo intervalo do outbox.
   - Arquivo ausente numa pasta que existe conclui com `hermes_knowledge_db_absent`: o Hermes
     nunca guardou nada ali.
2. **`server/bin/hermes_learning_purge.py` (novo).** É o único código que abre o SQLite.
   - `list` abre só para leitura e não cria o arquivo.
   - `purge` faz `BEGIN IMMEDIATE`, apaga os eventos e as cópias (`decks` e `deck_cards` com o
     `pg_deck_id` no `notes`) e lista o que ficou.
   - Códigos de saída: 3 para ausente e 4 para ocupado.
   - O stderr não leva id.
3. **`server/lib/privacy/account_deletion_outbox.dart`.**
   - O `hermes_learning_sqlite` passa a `purgesByTombstoneSweep`.
   - **Reconciliação:** cada execução cria, para todo recibo, a linha que falta de cada consumidor.
     - `created_at` é a hora da exclusão, então o prazo conta dela.
     - Os tokens vêm dos tombstones da mesma exclusão.
     - Com `ON CONFLICT DO NOTHING`, a reconciliação é idempotente.
   - **O recibo da execução ganhou, por consumidor:**
     - `reconciled`;
     - `done_by` e `failed_by`, a contagem por código;
     - `purged`, o que o consumidor apagou.

     Continua sem identificador.
   - A linha reservada leva o `runId`, para a varredura recomeçar a cada execução.
4. **`server/bin/pull_learning_events.py`.**
   - A gravação no SQLite pega o lock de escrita (`BEGIN IMMEDIATE`) antes de conferir no
     PostgreSQL quais eventos ainda existem, e grava só esses.
   - O resumo mostra `skipped_deleted`.
   - O `synced_to_hermes` marca só os que existem.
5. **Documentação:**
   - o inventário de retenção: o artefato do Hermes, os artefatos novos `optimize_job_memory` e
     `ops_artifacts`, a nota do BT-OBS-001 nas métricas e a reconciliação na linha do outbox;
   - o resumo do inventário;
   - a linha do `DELETE /users/me` no API_CONTRACTS;
   - o comentário do `cron_account_deletion_outbox.sh`.

## Evidência

Tudo no worktree, sobre `5debdf30d`, com o PostgreSQL 17 descartável da frente (`LC_ALL=C`, 62
migrações, última 062) e SQLite temporários.

- **Banco:** `server/test/privacy_deletion_outbox_db_live_test.dart` tem 17 testes verdes. São os
  12 da privacidade, ajustados para o Hermes que agora apaga, e 5 novos:
  - **Só os decks da conta excluída saem.** O knowledge.db tem eventos dos dois decks de A, de um
    deck de B e de um deck que o PostgreSQL não conhece, mais cópias do deck A1 e do deck B1.
    Depois da exclusão de A, saem os três eventos de A e a cópia de A1 com a carta dela. Ficam o
    evento de B, o do deck estranho e a cópia de B1. A linha fecha com
    `purged_by_tombstone_sweep`, e o recibo diz `events_deleted` 3, `decks_deleted` 1 e
    `deck_cards_deleted` 1.
  - **Retry idempotente:**
    - a mesma exclusão de novo dá `UserDataNotFoundException`, e o outbox continua com 5 linhas;
    - a execução seguinte não reserva a linha concluída nem reconcilia nada;
    - a entrega repetida, com o lease vencido antes de fechar, roda o handler de novo e fecha com
      tudo zerado. O evento de B continua lá.
  - **Falha reconciliada:**
    - com a pasta do knowledge.db ausente (volume não montado), a linha falha com
      `hermes_knowledge_db_dir_missing`, a 1ª tentativa, os tokens mantidos e a nova tentativa
      em `retryDelay(1)`;
    - antes do intervalo, o job não tenta de novo;
    - com o volume de volta e o intervalo passado, a linha conclui na 2ª tentativa e apaga o
      evento de A.
  - **Reconciliação:**
    - um recibo sem linhas, de três dias atrás, ganha as 5 linhas (`reconciled` 1 em cada), com
      `created_at` igual à hora da exclusão, o prazo de cada consumidor e os tokens dos
      tombstones da exclusão;
    - na execução seguinte, tudo fecha na hora (os prazos já passaram), menos os backups;
    - a terceira execução não reconcilia nada.
  - **Varredura do que sobrou:** um evento e uma cópia de um deck apagado antes, cuja linha já
    tinha fechado, reaparecem no arquivo. A exclusão seguinte, de outra conta, apaga os dois.
- **Os 13 testes de banco da frente:** 84 verdes e 2 pulados. Os pulados são a rodada com chave
  da D-82, que tem roteiro próprio.
- **Unitário:** `hermes_learning_purge_test.dart` e `account_deletion_outbox_test.dart` somam 24
  testes. Cobrem:
  - a varredura com auxiliar e casamento falsos (ordem, rodadas, códigos, uma varredura por
    execução, contagens uma vez só);
  - os códigos de saída do auxiliar de verdade;
  - `HERMES_KNOWLEDGE_DB`;
  - os dois contratos Python, que o teste Dart roda para que entrem na suíte do servidor.
- **Python:**
  - `hermes_learning_purge_test.py`, 7 testes: a lista não cria o arquivo; o purge apaga só os
    decks pedidos, é idempotente e espera o lock (responde ocupado); o stderr sai sem id;
  - `pull_learning_events_deletion_test.py`, 3 testes: um evento que sumiu do PostgreSQL não
    entra; a conferência roda com o lock do SQLite tomado; nada é gravado quando a conferência
    falha;
  - `pull_learning_events_schema_test.py`, 1, e `manaloom_ops_daemon_test`, 25.
- **Foco sem os `*_live_test`:** 18 arquivos e 151 testes (privacidade, retenção, outbox, Hermes,
  observabilidade e contratos).
- **Na trava, com o commit:** `dart analyze` e a suíte completa.

## Receipt por consumidor

Cada exclusão tem uma linha por consumidor no `account_deletion_outbox`. Essa linha é o recibo
daquele consumidor para aquela exclusão: estado, tentativas, `completed_at` e, se falhou,
`last_error_code`. O recibo de cada execução (`MANALOOM_ACCOUNT_DELETION_OUTBOX`, sem
identificador) diz quantas linhas fecharam, por qual código e o que foi apagado.

- **`hermes_learning_sqlite`**
  - Fecha com `purged_by_tombstone_sweep`, ou `hermes_knowledge_db_absent` se nunca houve arquivo.
  - O recibo da execução leva `purged.events_deleted`, `decks_deleted` e `deck_cards_deleted`.
  - Prova: os testes de banco que apagam só os decks da conta excluída, repetem sem apagar nada a
    mais, falham e reconciliam, e varrem o que sobrou de exclusões antigas. Também os testes
    Python do auxiliar e do alimentador.
- **`interactive_battle_sidecar`**
  - Fecha com `expired_by_max_session_lifetime`, 7200 s + 10 min depois da exclusão (D-77).
  - Prova: o teste de banco de 2 h 9 min e 2 h 11 min (rodada 3), e a reconciliação de uma
    exclusão de três dias atrás, que fecha na hora.
- **`endpoint_cache`**
  - Fecha com `expired_by_24h_cache_cap`, 24 h 5 min depois.
  - Prova: o teste de banco do teto de 24 h e a reconciliação.
- **`sentry`**
  - Fecha com `server_events_carry_no_user_id` na primeira execução.
  - Prova: `observability_test.dart` (rodada 1) e os testes de banco do job.
- **`backups`**
  - Não fecha. A linha fica `pending`, com `blocked_backup_rotation_not_applied`, sem gastar
    tentativa, até a rotação existir.

## Mutações

Cada mutação foi aplicada no worktree e rodou nos alvos dela: unitário Dart, banco ou Python. Depois, o arquivo
foi restaurado e conferido byte a byte. As 17 falham como esperado. O roteiro está no apoio da frente:
`mutations_priv002.py` e `run_mutation_priv002.sh`.

| Mutação | O que muda | Falha em |
| --- | --- | --- |
| M107 | a varredura não chama o purge | unitário 18/24; banco 12/17 |
| M108 | sem nada a apagar, não confere sob o lock | unitário 23/24 |
| M109 | uma rodada só: o evento gravado entre a lista e o lock fica | unitário 22/24 |
| M110 | pasta ausente (volume não montado) conta como concluída | unitário 23/24; banco 16/17 |
| M111 | arquivo ausente numa pasta que existe vira falha | unitário 23/24 |
| M112 | a linha não confere os próprios decks | unitário 23/24 |
| M113 | as contagens vão em toda linha da execução | unitário 23/24 |
| M114 | a varredura não recomeça na execução seguinte | unitário 23/24 |
| M115 | sem reconciliação por padrão | banco 16/17 |
| M116 | a reconciliação conta o prazo de agora, não da exclusão | banco 16/17 |
| M117 | a reconciliação não leva os tokens dos tombstones | banco 16/17 |
| M118 | o Hermes volta a ficar bloqueado | unitário 22/24; banco 11/17 |
| M119 | o purge não pega o lock de escrita antes de ler | Python do auxiliar, 1 falha |
| M120 | a lista cria o knowledge.db quando ele não existe | Python do auxiliar, 1 falha |
| M121 | o purge deixa as cópias de deck | Python do auxiliar, 2 falhas; banco 15/17 |
| M122 | o alimentador confere no PostgreSQL antes de pegar o lock | Python do alimentador, 1 falha |
| M123 | o alimentador grava evento que já saiu do PostgreSQL | Python do alimentador, 1 falha |

## Decisões pendentes (em `decisoes-pendentes.md`, com a recomendação)

1. Prazo e aplicação da rotação dos backups. Com a rotação aplicada, o consumidor `backups`
   passa a fechar pelo tempo (o prazo mais 1 dia).
2. Prazo de rotação dos artefatos de ops.
3. Conferir a existência do deck sob o lock também no `sync_pg_target_deck_to_hermes.py`,
   antes de ligar o `master_optimizer_preflight`.
