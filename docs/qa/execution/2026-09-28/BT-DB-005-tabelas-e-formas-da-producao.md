# Receipt — BT-DB-005: tabelas e formas da produção nas migrations 075 e 076 — 2026-09-28

- **Tarefa:** `BT-DB-005`, as relações que o código usa e que o baseline não cria. Decisões do
  dono:
  - **D-48:** a migration cria as tabelas que o código usa sem migration e reconcilia as colunas
    divergentes, sem perfil de live-drift;
  - **D-83 (2026-09-28):** aceita a regra da 075 e a 076 com `RESTRICT`.

  As faixas 075 e 076 são da Frente C.
- **Executado por:** Frente C (banco e operação), no worktree da frente, branch
  `banco/rodada1-2026-09-24`, com o código que entra no mesmo commit deste receipt.
- **Limites:**
  - nada tocou a produção: sem SSH, sem banco remoto, sem deploy, e as migrations foram aplicadas
    só em bancos descartáveis;
  - o dump de 2026-09-23 foi usado de dois jeitos, os dois autorizados pela coordenação, em
    PostgreSQL 17 descartável (loopback, `sandbox-exec`, só estrutura e ledger, nenhuma linha de
    dado, cluster apagado):
    - o ensaio na estrutura, cuja saída tem só nomes e resultados;
    - a leitura só da definição de `theme_contextual_rules`, `analysis_sources`,
      `archetype_patterns.last_analyzed_at`, `optimization_analysis_logs.test_run_id` e
      `user_binder_items.chk_list_type` (item 5 da seção da `BT-DB-005`).
  - Nada mais do dump foi lido ou copiado. As outras definições vieram do repositório:
    - o script que criou `optimization_analysis_logs` (`ffb9a583e`);
    - o que criou `synergy_packages`, `archetype_patterns` e `ml_learning_state` (`35ecb6e8e`);
    - a saída da auditoria BT-DB-001.

## A regra de direção

- **Onde a produção é mais estrita, o banco novo adota:** tipo, NOT NULL, chave primária e nome e
  texto de CHECK. Na produção, esses comandos são nulos ou só conferem.
- **Onde o código tem algo que a produção não tem e é só metadado ou aditivo, a produção recebe:**
  dois defaults e três índices.
- **O que pede olhar dado fica para o lote, com a contagem e o sim do dono (D-85):**
  - apertar NOT NULL (D-67);
  - criar as chaves da D-50;
  - validar os três CHECK que a produção não tem.

  Nenhum NOT NULL do banco novo foi afrouxado.

## Migration 075, `adopt_production_ml_tables_and_shapes`

**Tabelas que o código usa e só a produção tinha** (`CREATE TABLE IF NOT EXISTS`, nulo na
produção):

- `optimization_analysis_logs`, com os 7 índices da produção e `test_run_id` `text`;
- `synergy_packages`, `archetype_patterns` (`last_analyzed_at` sem fuso) e `ml_learning_state`,
  com a chave primária e o `UNIQUE` de cada uma;
- `theme_contextual_rules` e `analysis_sources`, criadas pelo laboratório Hermes, com a definição
  da produção: colunas, defaults, o CHECK de `priority`, o `UNIQUE` e os índices.

O ensaio na estrutura mostrou que a produção não tem 35 colunas nem o CHECK de
`synergy_packages.package_type` dos scripts antigos. As tabelas nascem sem eles.

**Colunas:**

- no banco novo: `card_meta_insights.id`, que vira chave primária no lugar de `card_name` (o
  `UNIQUE` de `card_name` fica, da 064), e `cards.edhrec_rank`;
- tipos da produção: `users.location_city` `varchar(100)`, `users.location_state` `varchar(2)`
  (as mesmas regras que a rota `PATCH /users/me` já aplica),
  `card_meta_insights.versatility_score` `double precision` e `user_binder_items.list_type`
  `varchar(4)`, com as duas views do fichário recriadas com o texto da 045;
- `commander_learned_decks.created_at` e `updated_at`: `NOT NULL` e `now()`, como na produção;
- para a produção, só metadado: os defaults de `battle_simulations.simulation_type` (`legacy`) e
  de `ml_prompt_feedback.prompt_version` (`v1.1-hybrid`).

As trocas de tipo, de chave primária, de índice e de CHECK só rodam onde a forma ainda é a antiga
(um `DO` com guarda). Assim a produção não refaz view, índice nem CHECK.

**Índices:**

- para a produção, os três `idx_ml_prompt_feedback_*` da migration, que ela não tinha;
- no banco novo, `idx_trade_history_offer` e `idx_trade_messages_offer` com a definição da produção.

**CHECK:**

- `chk_account_deletion_mode` com o nome da produção;
- `chk_list_type` com o nome e o texto da produção, refeito sobre o `varchar(4)` só onde o texto
  ainda é outro;
- sai `post_game_notes_revision_check`, que repetia a `chk_post_game_notes_revision` (038).

**Rollback:** só manual. O down é neutro, porque a 075 adota o que a produção já tem.

## Migration 076, `align_message_and_trade_history_user_fks`

`direct_messages.sender_id`, `trade_messages.sender_id` e `trade_status_history.changed_by`
estavam sem ação na produção e com `RESTRICT` nas migrations. Ficam `RESTRICT` nos dois bancos,
como a 059 fez com `trade_items` (D-66 e D-83).

Como funciona:

- a chave só é refeita onde ainda não é `RESTRICT`;
- refazer a chave troca o OID dela, então sai o gatilho de conta ativa com o OID antigo;
- o laço canônico da 074 fecha o `up`, pela regra da 070 em diante.

**Rollback:** só manual. O down volta a "sem ação", com o mesmo cuidado com os gatilhos.

## Lista fechada da deriva: de 94 para 73 itens

- **Saíram 26,** reconciliados:
  - 23 pela 075: as 6 tabelas, 8 colunas, 2 views, 1 CHECK e 6 índices;
  - 3 pela 076: as chaves.

  Os achados do ensaio e da leitura autorizada que a 075 resolve também estão listados como
  reconciliados.
- **Mudaram de decisão:**
  - `card_meta_insights.versatility_score` e `ml_prompt_feedback.prompt_version` foram para a
    D-67, porque só o NOT NULL ainda difere;
  - `ml_prompt_feedback.user_rating` (dado pessoal) ficou só da produção e passou para a
    exportação da `BT-PRIV-001`;
  - `card_meta_insights.created_at` ficou pendente do dono.
- **Entraram 5 pendentes, com a origem no receipt do ensaio na estrutura:**
  - os três CHECK que a produção não tem, que a D-85 valida no lote depois de contar zero
    violações;
  - o gatilho de conta ativa de `ml_prompt_feedback.user_id`, que vem com a chave da D-50;
  - o enum `poststatus` (D-49 e D-85).
- **Payload:** uma mudança de linha declarada. A troca de tipo de `versatility_score` muda o
  texto da linha num banco novo com dados; na produção, nada muda.

Também entraram:

- `server/sql/readonly/bt_db_005_check_violations.sql`: conta, só leitura, as linhas que os três
  CHECK recusariam na produção. É a contagem de antes da D-85;
- o inventário de retenção (`BT-PRIV-003`): as 6 tabelas entram em `tables`, sem dado pessoal, e
  `cards.edhrec_rank` e `card_meta_insights.id` saem das colunas só da produção.

## Provas

| Prova | Resultado |
| --- | --- |
| `server/test/production_shape_adoption_test.dart` (tabelas e índices contra a auditoria, só o CHECK que a produção tem, formas de coluna, direção das trocas, views da 045, CHECK, 076, consulta só de leitura) | 12 verdes |
| `server/test/migration_rehearsal_test.py` (a lista fechada casa com a auditoria, com a 064, a 065, a 075 e a 076, e todo achado do ensaio na estrutura tem destino) | 10 verdes |
| `server/test/active_user_trigger_rule_test.dart` (a 076 fecha com o laço; o teste "sem a 074" passa a olhar a lista até ela) | 12 verdes |
| `server/test/production_shape_adoption_db_live_test.dart` (`RUN_SCHEMA_DB_TESTS=1`): índices, tipos e o texto do `chk_list_type` iguais aos da produção; chaves RESTRICT com um gatilho cada; reaplicação sem mudança; a 076 na forma da produção | 5 verdes |
| Testes de banco no descartável (66 migrations, última 076): os 11 Dart e os 4 Python | todos verdes; o ensaio dos fixtures dá 5 de 5 |
| Ensaio na estrutura do dump de 2026-09-23, com o código deste commit | **PASS**: 18.645 diferenças, todas na lista fechada, 0 inesperada, 0 entrada sem ocorrência; upgrade até a 076; reaplicação sem mudança; rollback pelo restore idêntico; reforward igual; cluster apagado |
| Mutações (`mutacoes_bt_db_005.json`, na cópia de trabalho da frente, refeitas no código final) | 17 de 17 derrubadas |
| Gates, na trava | suíte do servidor: 406 arquivos em 11 lotes, todos com rc=0 (tags live fora); `project_logic --write`, `--check` e `--test` verdes; contrato de release `passed` (34 contratos); comparação de schema do gate tbls num banco novo: PASS (86 tables, 6 views, 100 foreign keys, 66 migrations) |

**Mutações:**

- **E01 a E09, na 075:**
  - índice a menos;
  - o CHECK do script antigo;
  - a troca de `list_type` sem guarda;
  - NOT NULL afrouxado;
  - o default tirado em vez de levado;
  - o nome do CHECK de exclusão errado;
  - o CHECK repetido mantido;
  - sem `edhrec_rank`;
  - o tipo de `location_state` errado.
- **E10 a E13, na 076:** o gatilho do OID antigo mantido, a chave sem ação, a chave refeita
  sempre e a 076 sem o laço.
- **E14 a E17, no resto:** a lista sem o `poststatus`, o fixture modelando a tabela adotada, o
  inventário sem a tabela e a consulta sem `READ ONLY`.
- **E06 passou na primeira rodada.** O teste conferia o nome novo como trecho, e foi apertado
  para conferir o comando inteiro; depois disso, E06 foi derrubada.

## O que segue aberto

- **No lote de deploy, com a contagem e o sim do dono (D-85):**
  - validar os três CHECK depois de contar zero violações;
  - `card_rulings_legacy` e `poststatus`: arquivo cifrado e depois apagar;
  - as chaves da D-50 e os NOT NULL da D-67;
  - aplicar a 075 e a 076.
- **`card_meta_insights.created_at`:** pendente do dono.
- **`ml_prompt_feedback.user_rating`:** é da `BT-PRIV-001`.
- **`deck_weakness_reports` e `deck_matchups`:** o `BT-AI-029` recomenda descartar, e o dono ainda
  não decidiu. Esta tarefa não mexeu nelas.
