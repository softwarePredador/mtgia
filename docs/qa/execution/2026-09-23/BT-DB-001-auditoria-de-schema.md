# Receipt — BT-DB-001: auditoria de schema reproduzível — 2026-09-23

- Tarefa: `BT-DB-001`, tarefa 5 do pacote da frente de servidor de 2026-09-23, na branch
  `servidor/raia-2026-09-23`.
- Autorização: a coordenação, no pacote das tarefas 3 a 5 (o dono mandou seguir). O alvo tinha
  de ser montado sem dado pessoal a partir do backup de 2026-09-23, num PostgreSQL 17 isolado e
  sem rede, com o banco e os arquivos restaurados apagados no fim. Nada tocou a produção: sem
  SSH, sem túnel, sem banco remoto, sem migração.
- Executado por: frente de servidor (Claude), no worktree da frente, sobre `06e9d2bbe`, com a
  ferramenta que entra no mesmo commit deste receipt.
- Rodado em: 2026-09-23, das `11:32:37` às `11:32:54 UTC`. O script levou 15 s.
- Ferramenta:
  - `server/lib/schema_audit/schema_audit.dart` faz a comparação e a classificação;
  - `server/bin/schema_audit.dart` lê o catálogo dos dois bancos, cada um numa transação
    `READ ONLY`, e grava as saídas em JSON e Markdown;
  - `scripts/manaloom_schema_audit.sh` faz o procedimento inteiro.
- Comando:

  ```sh
  MANALOOM_APPROVE_DISPOSABLE_POSTGRES=I_APPROVE_DISPOSABLE_LOCAL_POSTGRES \
    scripts/manaloom_schema_audit.sh \
    --target-dump <checkout principal>/backups/manaloom-postgres/manaloom-postgres-20260923T005128Z.dump \
    --out-dir <scratchpad da sessão> --target-label dump-20260923T005128Z
  ```

- Base: banco criado do zero no mesmo cluster por `server/database_setup.sql` e
  `server/bin/migrate.dart`. São 58 migrations, a última é a `058`.
- Alvo: o backup `backups/manaloom-postgres/manaloom-postgres-20260923T005128Z.dump` do checkout
  principal, fora do git.
  - Tamanho 315.645.906 bytes; sha256
    `2df51b464f28b9068ba1f492931999fa48f1b5275a18ab4e9a3e69ed2f13f836`. É o mesmo arquivo do
    receipt `BT-REL-000`.
  - Tirado da produção às 00:51 UTC de 2026-09-23, antes da `058`, que entrou às 02:33 UTC.
- **Sem dado pessoal no alvo.** O alvo recebeu só a estrutura (`pg_restore --schema-only`) e as
  linhas de `public.schema_migrations` (`pg_restore --data-only -n public -t
  schema_migrations`).
  - Antes da auditoria, o script contou as linhas de todas as tabelas do alvo com `count(*)`
    exato. Ele só seguiria se a única tabela com linhas fosse `public.schema_migrations`.
  - Resultado da contagem: `alvo_tabelas_com_linhas=public.schema_migrations`.
  - Logs do `pg_restore`: vazios nas duas restaurações
    (`pg_restore_log_linhas=estrutura:0,ledger:0`).
- Isolamento:
  - PostgreSQL 17.9 local, criado com `initdb` num diretório temporário.
  - Escuta só em `127.0.0.1`, numa porta livre, sem socket unix.
  - Servidor, `pg_restore`, `psql`, `migrate.dart` e o auditor rodaram dentro de
    `sandbox-exec`, que nega rede fora do localhost.
  - O Dart rodou sem `dart run`, para não disparar `pub get` implícito no cache compartilhado.
- Descarte: no fim, o script parou o PostgreSQL e apagou o diretório temporário, com o cluster,
  os bancos base e alvo e os logs (`descartado=$TMPDIR/manaloom_schema_audit.x9AyXZ`).
  - Conferido depois: o diretório não existe e nenhum `postgres` desse diretório ficou de pé.
  - O dump não foi alterado (sha256 igual antes e depois).
- Saídas da ferramenta, sem edição, nesta pasta:
  - `BT-DB-001-auditoria-de-schema.saida.json`: completa, legível por máquina;
  - `BT-DB-001-auditoria-de-schema.saida.md`: a mesma lista em Markdown.

## Resultado

| Inventário | Base (migrations) | Alvo (produção às 00:51 UTC) |
| --- | ---: | ---: |
| Schemas | 1 (`public`) | 2 (`public`, `manaloom_deploy_audit`) |
| Tabelas | 79 | 1.132 (99 em `public`, 1.033 em `manaloom_deploy_audit`) |
| Views | 6 | 6 |
| Colunas de tabela | 905 | 18.431 (1.190 em `public`, 17.241 em `manaloom_deploy_audit`) |
| Chaves estrangeiras | 98 | 97 |
| Índices | 291 | 425 (375 em `public`, 50 em `manaloom_deploy_audit`) |
| Ledger `schema_migrations` | 58, última `058` | 57, última `057` |

Classificação usada pela ferramenta:

- **faltando**: existe na base criada pelas migrations e não existe no alvo;
- **sobrando**: existe no alvo e não existe na base;
- **divergente**: existe nos dois, com definição diferente.

Nada foi apagado. Os extras aparecem só no relatório.

| Categoria | Faltando | Sobrando | Divergente |
| --- | ---: | ---: | ---: |
| Schemas | 0 | 1 | 0 |
| Tabelas | 0 | 20 | 0 |
| Views | 0 | 0 | 3 |
| Colunas | 5 | 3 | 32 |
| Chaves estrangeiras | 2 | 1 | 4 |
| Índices | 3 | 87 | 4 |
| Ledger | 1 | 0 | 0 |

A ferramenta resume o schema `manaloom_deploy_audit` em contagens: 1.033 tabelas, 17.241
colunas, 50 índices, nenhuma view e nenhuma chave estrangeira. Seus objetos não entram nas
outras categorias.

As colunas de tabelas que faltam ou sobram inteiras também não são listadas de novo. Já
chaves estrangeiras e índices dessas tabelas são listados.

## As diferenças

### 1. Ledger e `trade_items`, esperadas

O dump foi tirado antes da `058`, por isso:

- a `058` falta no ledger;
- as 4 colunas que ela cria em `trade_items` faltam: `snapshot_schema_version`,
  `snapshot_status`, `item_snapshot` e `snapshot_captured_at`.

A produção recebeu a `058` às 02:33 UTC do mesmo dia (receipt `BT-REL-000`).

### 2. Vinte tabelas sobrando em `public`

São as mesmas 20 da leitura de 2026-09-22, com a mesma classificação de uso:

- **7 usadas pelo código sem migration que as crie:** `optimization_analysis_logs`,
  `synergy_packages`, `archetype_patterns`, `theme_contextual_rules`, `ml_learning_state`,
  `card_rulings_legacy`, `analysis_sources`. Isso é o `BT-DB-005`; a D-48 manda a `059`
  criá-las.
- **9 backups de operação manual:** `card_battle_rules_backup_pg780b_hash_new_server`,
  `card_battle_rules_backup_pg814_hash_new_server`, `pg252_…` a `pg257_…_backup`,
  `pg596b_oracle_hash_backfill_backup`.
- **4 sem uso no código de produto:** `card_deck_profiles`, `card_extended`, `posts`,
  `search_subjects`.

### 3. Colunas: 5 faltando, 3 sobrando, 32 divergentes

- **Faltando (5):** as 4 de `trade_items` do item 1, mais `card_meta_insights.created_at`.
- **Sobrando (3):** `cards.edhrec_rank`, `ml_prompt_feedback.user_rating` e
  `card_meta_insights.id`.
- **Divergentes (32, em 12 tabelas comuns).** Uma coluna pode divergir em mais de um aspecto:
  - **Nulidade, 28 colunas.**
    - 26 são `NOT NULL` na migration e aceitam nulo na produção:
      - `user_binder_items`, 7 colunas: `is_foil`, `for_trade`, `for_sale`, `currency`,
        `language`, `created_at`, `updated_at`;
      - `card_meta_insights`, 7 colunas;
      - `ml_prompt_feedback`, 4 colunas;
      - `trade_offers`, 3 colunas;
      - `created_at` de `conversations`, `direct_messages`, `notifications`,
        `trade_messages` e `trade_status_history`.
    - 2 são o contrário, `NOT NULL` só na produção: `created_at` e `updated_at` de
      `commander_learned_decks`.
  - **Tipo, 4 colunas:**
    - `users.location_city`: `text` na migration, `varchar(100)` na produção;
    - `users.location_state`: `text` na migration, `varchar(2)` na produção;
    - `user_binder_items.list_type`: `text` na migration, `varchar(4)` na produção;
    - `card_meta_insights.versatility_score`: `numeric(6,3)` na migration, `double precision`
      na produção.
  - **Default, 6 colunas.** Só 2 mudam comportamento: `battle_simulations.simulation_type`
    (`'legacy'`) e `ml_prompt_feedback.prompt_version` (`'v1.1-hybrid'`) têm default só na
    migration. As outras 4 escrevem a mesma coisa de outro jeito: `now()` e
    `CURRENT_TIMESTAMP`, o cast de `varchar`, `0` e `0.0`.

  O padrão é de tabelas criadas na produção antes da migration que hoje as declara, que o
  `CREATE TABLE IF NOT EXISTS` das migrations não altera. Um caso está verificado no
  histórico:
  - as 7 colunas nulas de `user_binder_items` são exatamente as que o script avulso
    `server/bin/migrate_binder.dart` criou sem `NOT NULL`;
  - esse script é de `8f3810aac`, de 2026-02-09, e foi removido em `8cab6400b`;
  - a migration que declara a tabela com `NOT NULL` só veio em `776b9e25d`, em 2026-07-23.

  Os outros casos não foram rastreados um a um.

### 4. Views: 3 divergentes, uma delas com lógica diferente

- **`binder_item_availability` e `collection_availability_snapshot`:** a única diferença é o
  cast `bi.list_type::text` na produção. É consequência de `list_type` ser `varchar(4)` lá, e
  a lógica é a mesma.
- **`commander_learning_snapshot`:** a lógica difere. Na produção faltam os filtros
  `card_count = 100` e `card_list ILIKE '%' || commander_name || '%'`, então a view conta todo
  deck aprendido ativo.
  - O SQL da view mora numa constante Dart, `commanderLearningSnapshotViewStatement`, em
    `server/lib/ai/commander_learning_snapshot_support.dart`.
  - As migrations `023` e `024` interpolam essa constante.
  - Os filtros entraram na constante em `b70c3edd8`, de 2026-06-20, depois de a `024`
    (`807e20c46`, de 2026-06-15) existir.
  - O banco criado do zero pega o texto novo; a produção ficou com o antigo.
  - Isso quer dizer que uma migration aplicada não é imutável quando interpola código que
    muda. A regra do `BT-DB-004` precisa cobrir esse caso.

### 5. Chaves estrangeiras: 2 faltando, 1 sobrando, 4 divergentes

- **Faltando:** `ml_prompt_feedback.deck_id → decks.id` e `ml_prompt_feedback.user_id →
  users.id`, as duas com `ON DELETE SET NULL` na migration.
- **Sobrando:** `card_deck_profiles.deck_id → decks.id`.
- **Divergentes, só na ação de `ON DELETE`:** a migration declara uma ação e a produção não
  declara nenhuma (`NO ACTION`).
  - `ON DELETE RESTRICT` na migration: `direct_messages.sender_id`,
    `trade_messages.sender_id` e `trade_status_history.changed_by`. Na prática, `RESTRICT` e
    `NO ACTION` bloqueiam do mesmo jeito.
  - `ON DELETE CASCADE` na migration: `trade_items.owner_id → users.id`. Aqui o
    comportamento muda. Um `DELETE` numa conta que tem itens de troca apaga esses itens no
    banco criado do zero e falha na produção.

### 6. Índices: 3 faltando, 87 sobrando, 4 divergentes

- **Faltando:** os 3 índices compostos de `ml_prompt_feedback`, por arquétipo, deck e conta
  com `created_at DESC`.
- **Divergentes:**
  - `card_meta_insights_pkey` está em `id` na produção e em `card_name` na migration.
  - `card_rulings_pkey` está na tabela `card_rulings_legacy` na produção. A tabela antiga foi
    renomeada e levou o nome do índice; a `card_rulings` atual usa `card_rulings_pkey1`.
  - `idx_trade_history_offer` e `idx_trade_messages_offer` não têm `created_at DESC` na
    produção.
- **Sobrando: 87.** 39 estão nas 20 tabelas que sobram e 48 em 19 tabelas comuns. Seis dos 48
  são `UNIQUE` e mudam comportamento, porque a produção recusa duplicatas que um banco criado
  do zero aceita:
  - `uq_binder_user_card_cond_foil_list` (`user_binder_items`);
  - `uq_conversation` e `uq_conversation_pair` (`conversations`);
  - `idx_card_battle_rules_name_rule_key` (`card_battle_rules`);
  - `unique_card_insight` (`card_meta_insights`);
  - `card_rulings_pkey1` (`card_rulings`).

  A D-48 aposenta `database_indexes.sql` e manda os índices que a produção tiver virarem
  migration. A lista dos 48 é a entrada dessa decisão.

## Comparação com a leitura de 2026-09-22

A leitura de 2026-09-22 (`docs/qa/execution/2026-09-22/prod-readonly-estrutura-e-contagens.md`)
foi feita na produção viva, às 19:35 UTC. Ela comparou **nomes** de tabelas, colunas e
chaves com o `project_logic_manifest.json`. Este auditor compara **definições**: tipo,
nulidade, default, ação da chave, desenho do índice e texto da view. A base dele é um banco
criado pelas migrations.

| Item | 2026-09-22 | Auditor, 2026-09-23 | Explicação |
| --- | --- | --- | --- |
| Tabelas em `public` | 99 = 79 + 20 | 99; 20 sobrando, os mesmos nomes | Igual |
| Views | 6, "iguais" | 6 com os mesmos nomes; 3 definições divergentes | A leitura comparou nomes; o texto das 3 difere (item 4) |
| Chaves estrangeiras | 97 contra 98; faltam 2, sobra 1 | As mesmas 2 e 1; mais 4 divergentes | A leitura comparou pares coluna → tabela; a ação de `ON DELETE` difere em 4 (item 5) |
| Colunas | 4 tabelas com colunas a mais ou a menos | As mesmas 5 faltando e 3 sobrando; mais 32 divergentes em 12 tabelas | A leitura comparou nomes; tipo, nulidade e default são novos (item 3) |
| Índices | Não lidos | 3 faltando, 87 sobrando, 4 divergentes | Novo (item 6) |
| `manaloom_deploy_audit` | 1.033 tabelas, 150 MB | 1.033 tabelas, 17.241 colunas, 50 índices | Igual; o tamanho não se mede num alvo sem dados |
| Ledger | 57, última `057` | 57, última `057`; `058` faltando | Igual; o dump é anterior à `058` |
| Contagens de linhas | Lidas | Fora do escopo | O alvo não tem dados, de propósito |

Nada do que as duas leituras medem em comum mudou entre as 19:35 UTC de 2026-09-22 e as 00:51
UTC de 2026-09-23. As diferenças novas vêm do método, não do momento.

## Limites

- **O auditor não cobre** constraints `CHECK`, triggers (por exemplo, o da `058`), funções,
  sequências, extensões, donos e grants, comentários nem RLS. A restauração usou
  `--no-owner --no-acl`. `PRIMARY KEY` e `UNIQUE` aparecem pelos índices.
- **O alvo é o dump das 00:51 UTC, não a produção de agora.** Desde o dump, a `058` entrou; no
  receipt `BT-REL-000`, é a única migration aplicada depois dele. Uma mudança fora de migration
  feita depois não apareceria aqui. Para a produção atual, é rodar de novo contra um dump novo.
  - A CLI também lê um banco remoto com `--allow-remote`, sempre com TLS e em transação
    `READ ONLY`.
  - Isso exige autorização própria e não foi feito.
- **Versões do PostgreSQL:** a produção roda 17.10. O dump foi restaurado no PostgreSQL 17.9
  local, o mesmo que criou a base. O texto das definições (`pg_get_viewdef`,
  `pg_get_constraintdef`, `pg_get_indexdef`) sai do mesmo servidor para os dois lados, então
  a comparação não depende da versão da produção.
- **`server/bin/verify_schema.dart` não substitui este auditor:** ele confere uma lista fixa
  de colunas escrita no próprio arquivo.

## Reproduzir

O mesmo comando, com o mesmo dump, dá o mesmo resultado; só muda `gerado_em`. Isso foi
conferido: um ensaio geral às 11:17 UTC, numa cópia mínima do repositório no scratchpad, e a
rodada oficial das 11:32 UTC deram o mesmo JSON, fora esse campo. A ferramenta
tem teste em `server/test/schema_audit_test.dart`, sobre inventários sintéticos. Três
mutações foram provadas contra ele: ignorar a nulidade, abrir a transação em leitura e
escrita, e não reconhecer índice renomeado. As três fazem o teste falhar.
