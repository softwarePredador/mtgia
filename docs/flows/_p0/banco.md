# Banco — inventário de schema, migração segura e contenção de DDL

Grupo: `BT-DB-001`, `BT-DB-002`, `BT-DB-003`, `BT-DB-004` (Épico J do backlog mestre,
`docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md:601-604`).

Medido em 2026-09-22 contra `HEAD d15beb05b` (branch
`codex/free-beta-release-candidate-2026-07-17`). A árvore de trabalho não tem mudança em
nenhuma fonte de schema, e a seção `database` do `project_logic_manifest.json` é idêntica
em HEAD e na árvore (79 tabelas, 6 views, 98 FKs, 58 migrations). Nada foi executado:
nenhum PostgreSQL, `dart test`, build nem gate. Todo "provado" abaixo cita o teste ou o
receipt que de fato exercita a asserção, e o texto diz o que esse teste realmente afirma.

**Revisão adversarial (2026-09-22).** Este documento foi reexaminado asserção por
asserção e corrigido no lugar. As mudanças estão marcadas com **[rev.]** e resumidas na
seção "Verificação adversarial", no fim.

Legenda: **P** = PRONTO_E_PROVADO · **S** = PRONTO_SEM_PROVA · **Pa** = PARCIAL ·
**N** = NAO_ENCONTRADO.

## Resumo do grupo

| ID | Declarado | Medido | P/S/Pa/N | Arquivos a tocar | Testes a escrever | Migração | Prova viva | Decisão humana | Dependência declarada é real? |
| --- | --- | --- | --- | ---: | ---: | --- | --- | --- | --- |
| `BT-DB-001` | TODO | **mal-começada** [rev.: era metade] | 5/0/4/2 (11) | ~10 + regeneração [rev.: era ~7] | ~8 [rev.: era ~6] | não | **sim** | autorizar leitura read-only do PG de produção (ou o uso do dump local); fornecer o fingerprint SSH aprovado; confirmar se "schema real" inclui produção | nenhuma declarada; ocultas: acesso ao banco real e fingerprint SSH |
| `BT-DB-002` | BLOCKED_BY_P0 | **mal-começada** | 0/1/3/4 (8) | ~18 + regeneração [rev.: era ~8] | ~10 novos + 8 a atualizar [rev.: era ~8] | **sim** (é a própria) | **sim** | o que a 059 muda; quem aplica a **058 ainda pendente em produção** e sob qual disciplina; ordem frente às outras tasks com migration | sim; faltam `BT-DB-004`, imutabilidade das migrations e a 058 live |
| `BT-DB-003` | BLOCKED_BY_P0 | **mal-começada** | 0/0/2/4 (6) | ~9 [rev.: era ~7] | ~6 [rev.: era ~5] | não | **sim** | lista fechada do perfil live-drift | parcial: o harness genérico pode andar antes, e 057→058 é o upgrade real pendente |
| `BT-DB-004` | IN_PROGRESS_CONTAINED | **mal-começada** [rev.: era metade] | 0/3/3/4 (10) [rev.: era 2/1/3/4] | ~29 (+2 docs) [rev.: era ~24] | ~11 [rev.: era ~9] | não (opcional) | não (receipt de gate local) | destino de `setup_database.dart`, `extract_meta_insights --full`, `database_indexes.sql`, dos 4 builders e dos 47 pacotes `*_apply.sql`; DDL canônico de `sync_state` | formal para escrever o código; real para operar os CLIs convertidos contra produção |

Total revisado: **~66 arquivos** (mais a regeneração do project logic e 2 docs), **~35
testes novos** e **8 testes existentes a atualizar**. A versão anterior dizia ~46
arquivos e ~28 testes.

Em uma linha: o **baseline fresh 058 é reproduzível** (gate tbls, receipt de 2026-08-24,
com as entradas de schema idênticas em HEAD), mas a prova é **só de nomes** e o gate
**não roda em HEAD** desde então. **Nada compara esse baseline com o banco real.** Não
existe 059 nem mecanismo de perfis, preflight ou postcheck. **[rev.]** Além disso, a
**não há evidência de que a 058 esteja aplicada em produção** (último ledger vivo conhecido: 057, em 2026-08-14), e deploy e
readiness a exigem. A primeira migration a cruzar a produção sob essa disciplina é a
058, não a 059. O harness de upgrade/restore existe só para 038–040. Na contenção de
DDL, os caminhos de request estão limpos, mas **nenhuma proibição é executável**: os dois
testes que "provam" isso são textuais. **11 CLIs**, `setup_database.dart`,
`database_indexes.sql`, um script Hermes e **47 pacotes SQL versionados** ainda alteram
schema fora de migration. `sync_state` tem **3 DDLs divergentes** e não há auditor.

## Achados que valem para o grupo inteiro

1. **"Baseline 058" é `database_setup.sql` mais o replay de 001–058, não uma cadeia só de
   migrations.** A migration 001 já referencia `users(id)` e `decks(id)`
   (`server/bin/migrate.dart:36-37`), então nenhum banco vazio sobe só com migrations. O
   gate aplica `database_setup.sql` (2.749 linhas) e depois `migrate.dart`
   (`scripts/manaloom_tbls_local_gate.sh:95-111`). Na prática, o fresh é definido pelo
   `setup.sql`, e as migrations rodam como no-op idempotente. Drift entre os dois só
   aparece em banco antigo (o real).
2. **Migrations não são imutáveis e o ledger não tem checksum.** Oito migrations
   interpolam constantes mutáveis de `server/lib` (conferido: cada linha pertence à
   migration indicada):
   - 022: `migrate.dart:629-641`
   - 023: `:714`
   - 024: `:727`
   - 025: `:737`
   - 028: `:828-829`
   - 029: `:888-889`
   - 032: `:1016`
   - 045: `:2198`

   `schema_migrations` guarda só `version, name, executed_at` (`migrate.dart:4295-4299`).
   Assim, o mesmo ledger pode corresponder a schemas diferentes. "Perfil canonical
   fechado" (`BT-DB-002`/`003`) exige antes congelar o SQL ou registrar um checksum.
3. **O gate de schema é bom mas raso.** Compara:
   - nomes de tabelas (`manaloom_tbls_local_gate.sh:182-201`);
   - nomes de views (`:187-207`);
   - **nomes** de colunas (`:209-219`);
   - FKs (`:221-250`);
   - **contagem** do ledger (`:163-167`, `:252-256`).

   Não compara tipo, nulabilidade, default, índice, constraint, trigger, função,
   definição de view nem versão/nome do ledger. Caso real que passa despercebido: o
   manifesto registra `sync_state.value` como NOT NULL, herdado de
   `server/bin/sync_rules.dart:683`, enquanto o fresh cria a coluna nullable
   (`server/database_setup.sql:1578-1582`). A causa é que o gerador trata SQL literal de
   `server/bin` e `server/lib` como fonte de schema
   (`tools/project_logic/lib/project_logic_generator.dart:3155-3165`). Os atributos de
   coluna do manifesto, portanto, **não servem de baseline** para uma comparação de
   tipos. O comparador do `BT-DB-001` precisa extrair o catálogo do cluster fresh, não
   ler o manifesto.
4. **A última execução verde do gate de schema é de 2026-08-24**, no SHA `fd0397a5`
   (`docs/qa/execution/2026-08-14/BT-GOV-001.md:62`: 79/6/98/58, cluster removido).
   Conferido nesta revisão: `database_setup.sql`, `migrate.dart`, os 6 arquivos de `lib`
   que ele importa, o gate, o `.tbls.yml` e a seção `database` do manifesto são
   byte-idênticos entre `fd0397a5` e HEAD. O receipt, portanto, vale para o conteúdo de
   schema de HEAD. Em 2026-09-21 o `full` morreu antes, no `npm audit`
   (`docs/qa/execution/2026-09-21/btscp001-gate-amplo.md:242-300`).

   **[rev.] Reexecutar em HEAD não é trivial.** O documento anterior dizia que
   `./scripts/manaloom_local_ci.sh schema` "roda o gate isolado". Não roda:
   - o modo `schema` executa antes os contratos de shell, a checagem de game changers e o
     `project_logic --check` e `--test` (`scripts/manaloom_local_ci.sh:240-245`, `:105-112`);
   - o próprio gate roda 5 testes Battle live contra o PG descartável **antes** do tbls
     (`manaloom_tbls_local_gate.sh:113-135`). Um deles, `interactive_battle_store_live_test.dart`,
     ganhou +828/−95 linhas em `f6f791098` (2026-09-18), depois do último verde, e não há
     registro de execução dele desde então. Se falhar, a comparação de schema nem roda;
   - o gate usa `initdb`/`pg_ctl` do PATH (`:12`, `:68-78`), que nesta máquina é **PG
     14.18** (`initdb --version`). Os dumps de produção são "dump PostgreSQL 17" e foram
     restaurados em PG 17 (`docs/qa/MANALOOM_BATTLE_FLOW_RELEASE_EVIDENCE_2026-08-02.md:32`,
     `docs/qa/MANALOOM_BATTLE_DECKBUILDER_LIFE_COUNTER_RELEASE_2026-07-17.md:191-192`). Para
     a comparação de nomes isso é indiferente. Para a comparação profunda que o
     `BT-DB-001` exige (`pg_get_viewdef`, `pg_get_indexdef`, defaults), major diferente gera
     ruído, então o gate precisa fixar o mesmo major da produção;
   - nesta máquina, `pg_ctl` com `LANG` vazio falha com "postmaster became multithreaded"
     (`docs/qa/execution/2026-09-21/btuiev001-chromedriver-e-recaptura.md:274-276`).
5. **O único auditor que já leu o banco real executa DDL nele.**
   `server/bin/audit_data_model_links.dart:395-429` roda `CREATE TABLE/INDEX/VIEW` dentro
   de `BEGIN/ROLLBACK` no alvo, sempre que há variáveis de banco e não se passa
   `--skip-db` (`:283`), e só olha o schema `public` (`:253-260`).
6. **O read-only do wrapper não vale para ferramentas Dart**, mas o risco é menor do que
   parecia. **[rev.]** `server/bin/with_new_server_pg.sh:277-279` injeta
   `PGOPTIONS=-c default_transaction_read_only=on`, e o driver Dart travado
   (`postgres 3.5.9`, `server/pubspec.lock:596-603`) não lê `PGOPTIONS` (zero ocorrências
   no pacote). Porém o modo `--read-only` do wrapper **só aceita** `psql`, 5 auditores
   Python de uma allowlist (`:50-56`) e `dart run migrate.dart --status` (`:92-117`);
   qualquer outro comando é recusado (`:118-121`). O `audit_data_model_links.dart`,
   portanto, não roda pelo caminho governado. Duas ressalvas:
   - o usuário é fixado em `postgres` (`:179`), um superusuário, então o `PGOPTIONS` é só
     um default de sessão;
   - já existe o padrão seguro, usado pelos contratos do deploy: `with_new_server_pg.sh
     --read-only psql` com `BEGIN TRANSACTION READ ONLY` e checagem de
     `transaction_read_only = on` (`scripts/manaloom_deploy_backend_image.sh:459-466`).
7. **Existem dumps reais locais.** `backups/manaloom-postgres/` (ignorado pelo git,
   `.gitignore:23`) tem três dumps: 2026-07-17 (dois) e 2026-08-03. **[rev.]** O de
   2026-08-03 deve estar em **056**, não "pré-058": a produção reportava 56 migrations em
   2026-08-02 (`MANALOOM_BATTLE_FLOW_RELEASE_EVIDENCE_2026-08-02.md:34`) e 057 em 2026-08-14
   (`BT-GOV-001.md:121`). Contêm PII, mas **[rev.]** já existe como evitá-la:
   `scripts/manaloom_validate_restore.sh` restaura por padrão **só o schema**
   (`MANALOOM_RESTORE_MODE=schema`, `:14`, `:50-54`) num container descartável, sem ler
   linhas. Esse script só conta tabelas (`:57-58`). Um restore de schema de um dump de
   2026-07-17 já contou **87 tabelas**, contra 79 no baseline (`...LIFE_COUNTER_RELEASE_2026-07-17.md:191-192`).
   Não os li.
8. **O registry não amarra as tasks que vão criar migration à disciplina de migration.**
   `DCK-P0-01`, `DCK-P0-06`, `BT-AI-021` e `BT-AI-023` dependem só de `BT-DB-001`, e
   nenhuma delas de `BT-DB-002`/`003`/`004`. `BT-DB-003` não tem **nenhum** dependente no
   registry, e `BT-DB-002` só tem `BT-AI-014` e `BT-DB-003`. Resultado provável: a "059"
   nasce numa dessas, sem perfis nem preflight, e com DDL paralelo ainda vivo nos CLIs.
9. **Governança.** O slot NOW é `BT-SCP-001`, e nem auditoria read-only de outro ID pode
   começar (`docs/execution/CURRENT_QUEUE.md:41-42`). `BT-DB-001` e `BT-DB-004` estão nas
   posições 6 e 7 do horizonte (`:59-60`, na árvore de trabalho). Nenhuma das quatro tem
   ficha em `docs/execution/tasks/` nem receipt. Nenhum commit cita `BT-DB-002`, `003` ou
   `004`; o único que cita `BT-DB-001` é a proposta de reordenação da fila (`a98f188c8`). O
   tombstone veio em `b2d3fc04f` (2026-08-13).
10. **[rev., novo] Não há evidência de que a 058 esteja aplicada em produção, e nenhum ID é dono disso.** O
    último ledger vivo conhecido é 057 (`BT-GOV-001.md:121-122`, 2026-08-14), e não achei
    receipt posterior de apply em `docs/qa`, `docs/execution` nem `docs/status`. Três
    peças exigem 058:
    - o deploy recusa sem ela, porque `require_migrations_041_058_contract` exige a 058
      no ledger e `MAX(version) = '058'` (`scripts/manaloom_deploy_backend_image.sh:931-1000`,
      chamado em `:1169`);
    - o `/health/ready` de HEAD exige `latest_migration = '058'`
      (`server/lib/health_readiness_support.dart:173`);
    - o contrato de release exige "nenhuma migração pendente"
      (`docs/MANALOOM_E2E_RELEASE_CONTRACT.md:194`).

    A auditoria de 2026-08-11 lista isso como P0: "produção deixa de estar em 057 e aplica
    058 somente pelo fluxo aprovado"
    (`docs/qa/MANALOOM_DECK_AI_BATTLE_READINESS_AUDIT_2026-08-11.md:207`, `:245`). Nenhum
    ID do registry tem isso na entrega ou no aceite. Consequência para este grupo: a
    **primeira** migration preservadora a cruzar a produção é a 058, que faz `UPDATE` de
    payload em `trade_items`, constraints e trigger (`migrate.dart:3865-3990`), e ela já
    está escrita **sem** perfil, preflight de forma ou checksum. Aplicá-la live exige
    autorização própria (`docs/status/CURRENT_PRODUCT_DECISION.md:83`).
11. **[rev., novo] Há 47 pacotes SQL versionados que alteram schema fora de migration.**
    São `docs/hermes-analysis/master_optimizer_reports/*_apply.sql`, gerados pelos
    builders do apêndice A e aplicados à mão via psql; nenhum script os executa. Somam 45
    `CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit`, 89 `CREATE TABLE` nesse schema, 6
    `ALTER TABLE` e 3 `DROP TABLE`. Um deles cria uma tabela de backup em **`public`**:
    `pg596b_oracle_hash_backfill_backup` (`pg596b_oracle_hash_backfill_new_server_apply.sql:3`).
    Isso reforça que o inventário real precisa incluir schemas não-`public` e que o
    auditor do `BT-DB-004` precisa de uma allowlist explícita para esses artefatos.

---

## BT-DB-001 — auditar o schema real fresh contra o baseline 058

**Aceite** (`backlog:601`): "Inventário de tabelas/views/colunas/FKs/ledger; diferenças
classificadas, sem deletar 'extras'". A onda 01 detalha: "cluster PG loopback novo,
migrations, tabelas/views/colunas/FKs/ledger, diferenças classificadas, cleanup; zero DDL
live" (`docs/execution/waves/01-platform-safety.md:10`).

**[rev.] Ambiguidade que muda o tamanho da task.** A onda 01 (`:10`, "auditoria fresh do
baseline 058") e a fila ("produz o baseline PostgreSQL fresco", `CURRENT_QUEUE.md:59` na
árvore de trabalho) leem o `BT-DB-001` como auditoria do cluster **fresh**. O aceite ("sem
deletar extras") e o `BT-DB-005`, que depende desta task para classificar relações ML que
só existem no banco real, pedem o **real**. Este documento mede pela leitura "real contra
fresh". Se o dono confirmar a leitura só-fresh, a task volta a "metade" e dispensa acesso
à produção.

**Estado declarado:** TODO · **medido:** mal-começada **[rev.: era metade]**. As cinco
asserções P vêm de uma única execução do gate e cobrem só **nomes** do lado baseline.
Nada existe do lado real nem da classificação, que é a parte que dá nome à task.

| # | Asserção | Estado | Onde está | Teste / prova | O que falta |
| --- | --- | --- | --- | --- | --- |
| 1 | O baseline 058 fresh é reproduzível num cluster PG loopback descartável (`setup.sql` + 001–058) | **P** | `scripts/manaloom_tbls_local_gate.sh:36-56` (tmp e cleanup), `:60-111` (initdb, `pg_ctl -h 127.0.0.1`, `setup.sql`, `migrate.dart`) | `server/test/local_ci_contract_test.dart:31-47` é **textual** e não prova nada: afirma que o script contém `mktemp`, `-h 127.0.0.1`, stop, `rm -rf`, `database_setup.sql`, `run bin/migrate.dart`, `tbls out/doc/lint`, as strings de drift e a ausência de `TBLS_DSN`. A prova é a execução real no receipt `BT-GOV-001.md:62` (PASS no SHA `fd0397a5`). **[rev.]** As entradas de schema são byte-idênticas em HEAD (conferido), então a prova vale para o conteúdo. Mas não há log hasheado (o gate apaga o `RUN_DIR`), e o próprio projeto não aceitaria esse receipt como forte (`BT-GATE-002`, `backlog:617`) | Reexecutar em HEAD, com os bloqueios do achado 4 (teste Battle alterado, PG 14 no PATH, `project_logic --check` antes, `LC_ALL`), e guardar o artefato |
| 2 | Inventário de tabelas do baseline | **P** (nomes) | O manifesto guarda 79 tabelas, geradas por `tools/project_logic/lib/project_logic_generator.dart:3137-3246`; o gate compara em `:182-201` | Mesmo receipt | — |
| 3 | Inventário de views do baseline | **P** (só nomes) | Gate `:187-207` | Mesmo receipt | Comparar a **definição** das views, que mudam por constantes interpoladas (achado 2) |
| 4 | Inventário de colunas | **Pa** | Gate `:209-219` compara só nomes | Mesmo receipt (só nomes) | Tipo, nulabilidade e default. `sync_state.value` diverge sem alarme (achado 3); e o manifesto não serve de referência para isso |
| 5 | Inventário de FKs | **P** | Gate `:221-250` | Mesmo receipt | — |
| 6 | Ledger (`schema_migrations`) | **Pa** | Gate `:163-167`, `:252-256` (só COUNT). A readiness checa 038–058 por versão e nome em runtime (`server/lib/health_readiness_support.dart:113-175`), e o deploy faz o mesmo read-only (`manaloom_deploy_backend_image.sh:931-1000`) | Nenhum teste compara as versões do ledger no inventário | Comparar versão, nome e `executed_at`, e registrar checksum. Hoje o ledger não distingue bancos migrados com constantes diferentes |
| 7 | Inventário do schema **real** (tabelas, views, colunas, FKs, ledger) | **Pa** (obsoleto) | Há só listas de **nomes** de relações `public` de 2026-06-15 e 2026-07-01 (`docs/hermes-analysis/data_model_final_validation_2026-06-15.json`, `docs/qa/MANALOOM_DATA_MODEL_AUDIT_2026-07-01.json`), feitas por `audit_data_model_links.dart:253-260` em conexão direta a `143.x.x.247:5433/halder`. O caminho governado de hoje é túnel SSH para `127.0.0.1:15432` (`with_new_server_pg.sh:175-179`); não dá para saber sem acesso se é o mesmo banco, e a nota do "novo servidor" é de 2026-07-06 (`docs/EASYPANEL_RUNBOOK_MTGIA_2026-03-24.md:119-121`). **[rev.]** Somam-se uma contagem de 87 tabelas (restore de schema de 2026-07-17, só contagem) e o ledger 057 via `/ready` (`BT-GOV-001.md:121`) | Nenhum | Captura read-only nova do catálogo completo, incluindo schemas não-`public`. **[rev.]** O caminho pronto é `with_new_server_pg.sh --read-only psql -f <captura.sql>` com `BEGIN TRANSACTION READ ONLY`, como no deploy. `scripts/manaloom_tbls_readonly.sh` exige `TBLS_DSN` e **não** passa pelo wrapper, cujo modo read-only recusa `tbls` (`:118-121`) |
| 8 | Diferenças **classificadas** | **N** | O gate aborta em qualquer diferença, sem classificar (`:258-259`). `_classifyTable` (`audit_data_model_links.dart:644-660`) classifica pela origem do DDL, não pelo diff entre real e baseline | Nenhum | Um comparador que rotule cada diferença (ver "conteúdo mínimo" abaixo) |
| 9 | Sem deletar extras, zero DDL live | **Pa** | O gate é só loopback, sem `TBLS_DSN` (teste textual `local_ci_contract_test.dart:47`). O wrapper read-only existe (`with_new_server_pg.sh:277-279`) e recusa ferramentas Dart (`:92-117`) | Contrato textual do gate | O auditor atual faz DDL em rollback no alvo (`audit_data_model_links.dart:395-429`). O inventário real precisa rodar via psql com `BEGIN TRANSACTION READ ONLY` e checagem de `transaction_read_only`, padrão já usado em `manaloom_deploy_backend_image.sh:459-466` |
| 10 | Cleanup do cluster | **P** | Gate `:44-56` | `BT-GOV-001.md:62` ("cluster loopback removido") | — |
| 11 | Artefato durável do inventário e receipt `BT-DB-001` | **N** | O gate apaga o `RUN_DIR` por padrão (`:50-54`) | — | Inventário e diff commitados, mais o receipt (`BT-GATE-002` diz que `/tmp` não é prova) |

**Conteúdo mínimo que a classificação terá de cobrir.** Tudo isto já é visível sem
conectar ao banco:

- **17 relações que só existiam no banco real em 2026-07-01** (recontado nesta revisão:
  78 relações `public` no JSON, 17 fora do baseline):
  - 5 de ML: `archetype_patterns`, `ml_learning_state`, `optimization_analysis_logs`,
    `synergy_packages`, `theme_contextual_rules` (escopo `BT-DB-005`);
  - 6 tabelas de backup `pg252…pg257_*_backup` no schema `public`;
  - `posts`, `search_subjects`, `card_extended`, `card_rulings_legacy`,
    `analysis_sources`, `card_deck_profiles`.
- **[rev.]** Uma 7ª tabela de backup em `public` prevista por pacote:
  `pg596b_oracle_hash_backfill_backup` (achado 11).
- **29 dos 36 índices de `server/database_indexes.sql`** não existem em `setup.sql`,
  migrations ou lib (recontado). O arquivo manda aplicar via `psql` manual
  (`database_indexes.sql:8-9`).
- **O schema `manaloom_deploy_audit`**, com até 89 `CREATE TABLE` nos 47 pacotes
  versionados (achado 11).
- **Ledger 057 no real contra 058 no código** (achado 10).
- **Um GIN duplicado dentro do próprio baseline:** `idx_cards_color_identity`
  (`database_setup.sql:178`) e `idx_cards_color_identity_gin` (`migrate.dart:64`).

**O que realmente falta.** A metade "fresh" existe e foi provada **em nomes** (gate tbls);
a reexecução em HEAD tem os bloqueios do achado 4. A metade que dá nome à task não
existe:

- uma captura read-only, fresca, do catálogo real: colunas com tipo, nulabilidade e
  default; constraints; índices; triggers e funções; definição das views; schemas
  não-`public`; ledger com versão e nome; `SHOW server_version`;
- o mesmo catálogo extraído do fresh 058, **no mesmo major de PG da produção**;
- um comparador que classifique cada diferença;
- o artefato durável e o receipt.

Unidades de trabalho:

- **~10 arquivos [rev.: era ~7], mais a regeneração do project logic:**
  - consulta de catálogo (`.sql`) e script que a roda pelo wrapper read-only;
  - extensão do gate para exportar e manter o catálogo e fixar o major do PG;
  - comparador/classificador e seu arquivo de testes;
  - `local_ci_contract_test.dart` (o contrato textual do gate muda junto);
  - inventário real e diff classificado commitados (2 arquivos);
  - receipt;
  - linha do backlog.

  Se o `audit_data_model_links.dart` for reutilizado, entra mais um arquivo para
  corrigir o DDL em rollback.
- **~8 testes [rev.: era ~6]:** sete casos do comparador (relação só no real, só no
  baseline, tipo, nulabilidade/default, índice/constraint/trigger, schema não-`public`,
  versão/nome do ledger) e um contrato read-only (captura dentro de `READ ONLY`).
- **Sem migração.**
- **Prova viva obrigatória** (gate em PG descartável e captura real).
- **Serviço externo:** o PG de produção via túnel SSH read-only, ou um dump fresco.
- **Decisão humana:**
  - autorizar essa leitura, ou aceitar o dump de 2026-08-03 (em 056, com PII, mas
    restaurável só com schema);
  - **[rev.]** fornecer o fingerprint SSH aprovado: o wrapper recusa sem
    `MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256` (`with_new_server_pg.sh:202-223`), item 6 da
    auditoria de 2026-08-11 (`...READINESS_AUDIT_2026-08-11.md:208`);
  - **[rev.]** confirmar a leitura da task (fresh-only ou real contra fresh).

**Dependências.** Nenhuma declarada, e isso é correto no código. As dependências ocultas
são o acesso ao banco real e o fingerprint SSH. `BT-DR-001` (backup fresco) está a
jusante de `BT-DB-001` no registry; se a leitura de produção for negada, a única fonte
fresca vira um ciclo.

**Sobreposição:**
- `BT-DB-005` usa o mesmo inventário: aqui se classifica, lá se decide migrar ou remover
  o consumer.
- `BT-DR-001` pode reutilizar o comparador para "schema validado" após o restore; hoje
  `manaloom_validate_restore.sh` só conta tabelas.
- `BT-GATE-002` (receipt durável).

---

## BT-DB-002 — próxima migration preservadora (059 só se ainda for o próximo número)

**Aceite** (`backlog:602`): "Perfis de origem fechados, preflight antes de DDL, payload
preservado, postcheck exato".

**Estado declarado:** BLOCKED_BY_P0 · **medido:** mal-começada. Nada foi feito sob este
ID; o que conta a favor é infraestrutura anterior.

| # | Asserção | Estado | Onde está | Teste / prova | O que falta |
| --- | --- | --- | --- | --- | --- |
| 1 | Existe a próxima migration preservadora, com escopo definido | **N** | `migrate.dart` termina na 058 (`:3865`). Nenhuma branch local ou remota tem 059 (conferidas as 18 refs) | — | Definir **o que** a 059 muda. O backlog só lista propriedades; a onda 05 diz "somente se necessária" (`docs/execution/waves/05-learning.md:11`). **[rev.]** Antes dela, a 058 precisa cruzar a produção (achado 10) |
| 2 | Perfis de origem fechados (enumeração explícita de formas aceitas) | **N** | `Migration` só tem `version/name/up/down` (`migrate.dart:4007-4021`). `live-drift`/"perfil" só aparecem no backlog (`:602-603`) e na onda 05 | — | Um detector de perfil (canonical, live-drift) que recuse o desconhecido. Depende do inventário do `BT-DB-001` |
| 3 | Preflight antes de DDL | **Pa** | Guardas **pré-conexão**: aprovação textual (`:4161-4172`) e âncoras de destino (`:4038-4069`, `:4177-4189`). Preflight **de rollback**: `_assertRollbackSafe` (`:4104-4141`) com política (`:4071-4102`) | `server/test/data_model_migration_test.dart:9-30` (frase exata), `:32-73` (âncoras), `:75-116` (mapa de política). Todos chamam funções puras | Não há preflight da forma do banco antes do `up`: o loop executa o SQL direto (`:4320-4327`). **Bug concreto:** o apply só testa se a versão está presente (`:4311-4315`) e ignora versões desconhecidas no ledger. Só o rollback as recusa (`:4258-4261`). **[rev.]** E o **primeiro** passo do apply já é DDL: `CREATE TABLE IF NOT EXISTS schema_migrations` (`:4294-4300`), antes de ler o ledger (`:4302-4305`). O preflight tem de vir antes disso |
| 4 | Payload preservado | **Pa** (precedentes) | A 058 reconstrói o payload de `trade_items` (`migrate.dart:3865-3990`). A 038–040 foi provada com fixture (`server/bin/migration_038_040_isolated_support.dart:179-262`) | `data_model_migration_test.dart:947-980` é textual (strings em `up` e em `setup.sql`). Evidência única de 038–040: `docs/qa/MANALOOM_SPRINT1_DATA_SESSION_EVIDENCE_2026-07-21.md:65-90` | Um mecanismo genérico de contagem e hash do payload antes e depois, aplicado à 059 **[rev.]** e à 058 pendente |
| 5 | Postcheck exato | **Pa** | Só por versão fixa: `assert-post` de 038–040. Contratos read-only de 038–058 no deploy (`scripts/manaloom_deploy_backend_image.sh:456-1000`, chamados em `:1166-1169`). Readiness (`health_readiness_support.dart:113-175`) | Nenhum teste executa esses postchecks | Postcheck exato genérico: catálogo completo esperado, ledger e payload |
| 6 | Apply e ledger atômicos por migration | **S** | `runTx` com statements e `INSERT` no ledger (`migrate.dart:4320-4337`). **[rev.]** Conferido que nenhuma migration usa `CONCURRENTLY`, `ADD VALUE`, `VACUUM` nem `BEGIN/COMMIT` próprios, então todas cabem na transação | O caminho feliz roda no gate e no harness 038–040. Nenhum teste injeta falha no meio | Um teste de falha injetada que prove que nada parcial fica |
| 7 | Política de rollback declarada para a nova migration (manualOnly, rollback por restore) | **N** para 059 | O padrão existe (`:4078-4100`, `:4104-4112`) | `:75-116` (só o mapeamento) | Entrada da 059 mais o teste |
| 8 | Identidade imutável da migration (pré-requisito oculto dos "perfis fechados") | **N** | Ledger sem checksum (`:4295-4299`). Oito migrations interpolam constantes mutáveis (achado 2) | — | Checksum no ledger ou SQL congelado |

**O que realmente falta.** A migration não existe e o backlog não diz o que ela muda:
isso é decisão antes de código. O runner não tem o conceito de perfil nem hooks de
preflight e postcheck. Também precisa recusar ledger com versão desconhecida, não
executar DDL antes do preflight e ganhar checksum. Só então a 059 pode ser escrita com
payload preservado e postcheck exato, repetindo o padrão da 058 (bootstrap e migration
sincronizados).

**[rev.] Custo escondido da "próxima migration".** "058" está fixado em 15 arquivos além
de `migrate.dart`:
- **7 de código ou configuração:** `database_setup.sql`, `health_readiness_support.dart:173`,
  `manaloom_deploy_backend_image.sh:931-1000` e `:1743-1744`,
  `manaloom_deck_ai_learning_release_receipt.sh:24` e `:133`,
  `manaloom_deck_ai_learning_receipt_validator.py:492`,
  `server/config/deck_ai_learning_gate_policy.json:13-15`;
- **8 testes ou contratos:** `health_readiness_support_test.dart:91-93`,
  `ai_operations_contract_test.dart:61-91`, `battle_live_migration_test.dart:68`,
  `interactive_battle_migration_test.dart:85`, `data_model_migration_test.dart`,
  `deck_ai_learning_receipt_validator_test.py:51-103`,
  `project_logic_generator_test.dart:997`, `manaloom_release_ops_contract_test.sh:566-571`.

Unidades de trabalho:

- **~18 arquivos [rev.: era ~8], mais a regeneração do project logic:**
  - `migrate.dart` (runner e a 059);
  - um `server/lib/...schema_profile...` novo;
  - os 7 arquivos de código ou configuração que fixam 058;
  - os 8 testes ou contratos que fixam 058;
  - teste novo do preflight;
  - receipt.
- **~10 testes novos [rev.: era ~8], mais 8 existentes a atualizar:**
  - perfil desconhecido recusado;
  - canonical aceito;
  - live-drift aceito;
  - versão desconhecida no ledger recusada;
  - nenhum DDL antes do preflight;
  - payload preservado;
  - postcheck exato;
  - política de rollback;
  - checksum;
  - falha injetada sem estado parcial.
- **Com migração.** Prova viva em PG descartável.
- **Decisão humana:**
  - o conteúdo da 059 e se ela é necessária;
  - a ordem frente às outras tasks que precisarão de migration;
  - o que fazer com cada drift (reconciliar ou aceitar como perfil);
  - **[rev.]** quem aplica a 058 em produção, e se ela passa pela mesma disciplina.

**Dependências.** `BT-DB-001` é real: o conjunto fechado de perfis *é* a classificação
do `BT-DB-001`. Há três dependências não declaradas:
- `BT-DB-004`: com CLIs ainda executando DDL, nenhum conjunto de perfis fica fechado.
- A imutabilidade e o checksum das migrations.
- **[rev.]** A 058 live (achado 10): enquanto não houver prova de que a produção saiu de 057,
  "a próxima migration" da produção é a 058.

**Sobreposição:**
- `BT-DB-003`: mesmo mecanismo de perfil; a 002 implementa, a 003 prova.
- `DCK-P0-01`, `DCK-P0-06`, `BT-AI-021`, `BT-AI-023`, `DCK-P0-05` e `BT-AI-014` disputam
  o número da próxima migration (achado 8).
- **[rev.]** A pendência órfã "aplicar 058 pelo fluxo aprovado" (achado 10).

---

## BT-DB-003 — upgrade/rollback por restore do mesmo dump e perfil misto

**Aceite** (`backlog:603`): "Canonical e live-drift suportados explicitamente; perfil
misto falha antes de DDL".

**Estado declarado:** BLOCKED_BY_P0 · **medido:** mal-começada

| # | Asserção | Estado | Onde está | Teste / prova | O que falta |
| --- | --- | --- | --- | --- | --- |
| 1 | Upgrade a partir do estado anterior em PG descartável, com reapply idempotente | **Pa** | Só para 038–040: fresh em `scripts/manaloom_migrations_038_040_isolated.sh:102-107`, upgrade em `:109-117`. O helper tem as versões hardcoded (`migration_038_040_isolated_support.dart:68` desfaz 040→038; `:86` fixa o ledger ≤ 037). **[rev.]** O estado "anterior" é **sintético**: `setup.sql` atual mais o `down` de 040→038 (`:66-95`), não um banco 037 real | `server/test/migration_038_040_isolated_harness_contract_test.dart:14-33` é **textual** (strings de log e de versões; não executa). Execução única em 2026-07-21, **[rev.]** com 46 migrations (`...SESSION_EVIDENCE_2026-07-21.md:72-73`): nunca rodou com 047–058 | Parametrizar para N→N+1 e ligar a um gate. Hoje nenhum script chama o harness; só o contract test lê o arquivo |
| 2 | Rollback por restore do mesmo dump (dump antes, restore em outro banco, assert-prior, forward) | **Pa** | Mesmo harness: dump em `:112`, restore, assert-prior e forward em `:119-125`. O runner já exige restore para 034–058 (`migrate.dart:4104-4112`) | Idem (textual) mais a evidência de 2026-07-21 | Generalizar e produzir receipt por migration |
| 3 | Perfil **canonical** suportado explicitamente | **N** | O gate aplica o fresh completo (`tbls_local_gate.sh:95-111`), mas não há "upgrade a partir de 058 canonical" nem declaração de perfil | — | Fixture canonical (gerável pelo gate) mais o caso de teste. **[rev.]** Para N→N+1 com bootstrap sincronizado, o "anterior" exige o `setup.sql` da SHA anterior ou o `down` de N+1 |
| 4 | Perfil **live-drift** suportado explicitamente | **N** | — | — | Fixture schema-only sanitizada da forma real, que depende do `BT-DB-001`, mais o caso de teste. **[rev.]** `manaloom_validate_restore.sh` já restaura só o schema de um dump (`:14`, `:50-54`) |
| 5 | Perfil **misto** falha antes de DDL | **N** | Hoje o apply aceita ledger com versões desconhecidas em silêncio (`migrate.dart:4311-4315`) e **[rev.]** executa `CREATE TABLE IF NOT EXISTS schema_migrations` antes de qualquer checagem (`:4294-4300`) | — | Fixture mista, a asserção de que nenhum DDL rodou (ledger e catálogo intactos) e o teste |
| 6 | O harness roda num gate e gera receipt | **N** | `manaloom_local_ci.sh:192-195` roda só o gate tbls | — | Ligar ao modo `schema`/`full` e emitir o receipt |

**O que realmente falta.** O padrão "dump, upgrade, restore do mesmo dump, forward" já
foi provado uma vez, para 038–040, com 46 migrations. Falta:
- torná-lo genérico;
- dar a ele fixtures dos três perfis (canonical, live-drift, misto);
- afirmar que o misto aborta **antes** de qualquer DDL;
- rodá-lo em gate.

Unidades de trabalho:

- **~9 arquivos [rev.: era ~7]:**
  - harness shell genérico e helper Dart genérico;
  - gerador da fixture canonical, fixture live-drift e fixture mista;
  - contract test;
  - ligação no `local_ci` e atualização do `local_ci_contract_test.dart`;
  - receipt.
- **~6 testes [rev.: era ~5]:** canonical com upgrade e restore; live-drift com upgrade e
  restore; misto falha; nenhum DDL executado no misto; reapply idempotente por perfil;
  contrato.
- **Sem migração própria.** Prova viva em PG descartável.
- **Decisão humana:** aprovar a lista fechada do que é live-drift aceito.

**Dependências.** `BT-DB-002` é real para a prova final da 059. Mas o harness genérico e
os perfis podem ser construídos e validados já contra 057→058, desde que o `BT-DB-001`
exista (dependência só transitiva no registry). **[rev.]** E 057→058 não é ensaio: é o
upgrade de produção que está pendente (achado 10).

**Sobreposição:**
- `BT-DB-002`: o mesmo mecanismo de perfil.
- `BT-DR-001`: ferramentas de restore em `scripts/manaloom_full_restore_drill.sh`, que
  conta tabelas e FKs (`:172-180`), e `scripts/manaloom_validate_restore.sh`, que só conta
  tabelas (`:57-58`).

---

## BT-DB-004 — proibir DDL runtime ou fora de migrations e tombstonar resets destrutivos

**Aceite** (`backlog:604`): "`update_schema.dart` já falha fechado; sync/backfill/Commander
CLIs não executam CREATE/ALTER/DROP; `sync_state` tem um único DDL; schema só muda por
migration+gate; auditor cobre todos os entrypoints".

**Estado declarado:** IN_PROGRESS_CONTAINED · **medido:** mal-começada **[rev.: era
metade]**. Das 5 cláusulas do aceite, 1 está implementada (e provada só por teste
textual); as outras 4 estão abertas. O DDL de request foi **removido**, mas não está
**proibido**: nada executável falharia se uma rota nova ganhasse um `CREATE UNIQUE INDEX`
(ver #3a). A entrega pede "proibir".

| # | Asserção | Estado | Onde está | Teste / prova | O que falta |
| --- | --- | --- | --- | --- | --- |
| 1 | `update_schema.dart` falha fechado | **S** [rev.: era P] | `server/bin/update_schema.dart:9-15` (commit `b2d3fc04f`). O arquivo tem 15 linhas, só importa `dart:io` (`:1`) e não abre conexão | `server/test/sql_statement_splitter_test.dart:57-69` é **só textual**: afirma que o fonte contém `BLOCKED:`, `exitCode = 2` e `bin/migrate.dart`, e que não contém `Database()`, `DROP TABLE`, `database_setup.sql` nem `execute(`. Não executa o binário, então pela regra não prova. Risco residual quase nulo | Um teste que execute e exija rc=2, como o do `optimizer_loop` |
| 2 | Outros resets destrutivos tombstonados | **Pa** | Pronto e **provado**: `server/bin/optimizer_loop.sh:1-9`. Pendentes: `setup_database.dart:7-31` aplica o `database_setup.sql` inteiro no banco do `.env`, sem aprovação nem restrição a loopback (`Database()` não tem guarda, `server/lib/database.dart:43-108`). O `setup.sql` contém 33 DROP (CONSTRAINT/INDEX/TRIGGER) e UPDATE de dados (ex. `:166`, `:1901-1919`). **[rev.]** E falha aberto: o `catch` só imprime (`setup_database.dart:26-27`), então um apply parcial sai com rc=0. `extract_meta_insights.dart:88-95` roda `--full`, que faz `TRUNCATE … CASCADE` em 3 tabelas sem aprovação (0 referências a aprovação no arquivo). `database_indexes.sql:8-9` manda aplicar via psql manual | `server/test/optimizer_loop_tombstone_contract_test.py:13-41` **executa** o script e exige rc=2 e stdout vazio (roda em `manaloom_deck_ai_learning_gate.sh:608`) | Tombstone ou restrição a loopback para `setup_database.dart`; gate ou tombstone para `--full`; aposentar `database_indexes.sql` (ou movê-lo para migration) |
| 3a | Os 5 caminhos de request que tinham DDL não o executam mais | **S** [rev.: era P] | Os DDLs viraram migrations 014/023/031/034. **[rev.]** Implementação confirmada por varredura própria: zero DDL em `server/routes` (regex multilinha que cobre UNIQUE, VIEW, DROP, TRIGGER, FUNCTION, EXTENSION e SCHEMA) | `server/test/runtime_schema_migration_contract_test.dart:9-61` é **textual e estreito**: lê 5 arquivos fixos, aplica lowercase e procura só as substrings `create table`, `create index` e `alter table` (`:22-39`), mais 5 nomes de `ensure*`. Passariam sem alarme `CREATE UNIQUE INDEX`, `CREATE OR REPLACE VIEW`, `DROP …`, `CREATE TRIGGER`, palavras separadas por quebra de linha ou DDL chamado por um helper com outro nome. `:63-94` só confere que o `up` das migrations 014/023/031/034 contém o `CREATE TABLE` | O auditor (#9) |
| 3b | Nenhum outro arquivo de `server/routes`/`server/lib` executa DDL em request ou startup | **S** | Zero DDL em `server/routes`; zero `ensure*` de schema em `main.dart`/`_middleware.dart`. Os 4 helpers DDL de lib só são chamados de `server/bin` (conferido: `ensureCardLocalizedNamesTable` ← `sync_localized_card_names.dart:80`; `ensureCommanderReference*` ← os 3 CLIs Commander). As constantes DDL de lib só são usadas por `migrate.dart`, pelos CLIs e pelo `audit_data_model_links.dart` | Nenhum teste varre o diretório inteiro | Parte do auditor (#9) |
| 4 | Os CLIs de **sync** não executam CREATE/ALTER/DROP | **Pa** (2 de 6 com DDL ou verificação) | Conformes: `sync_combos.dart:659-681` e `sync_rulings.dart:315-338` só verificam e falham fechado; TEMP `ON COMMIT DROP` em `sync_combos.dart:476-478` e `sync_rulings.dart:212-219`; `sync_prices_mtgjson_fast.dart:188-194` só usa TEMP. **Não conformes:** `sync_cards.dart:80-83` → `:226-287` (em toda execução, sem aprovação nem `--apply`); `sync_cards_full_fast.py:231-245` (chamado em `:346`); `sync_rules.dart:144-145` → `:667-688` (com aprovação); `sync_localized_card_names.dart:80` → `import_card_lookup_service.dart:136-142` (inclui `CREATE OR REPLACE VIEW card_identity_bridge`; **[rev.]** só com `--apply`, dry-run é o padrão, `:42-43`, `:69-72`) | Nenhum | Converter os 4 para verificação que falha fechado, como sync_combos |
| 5 | Os CLIs de **backfill** não executam DDL | **N** (0 de 4) | `backfill_card_combat_metadata.py:146-154` (chamado em `:215-218` fora de `--dry-run`); `candidate_quality_data_foundation.dart:257` → `:1171-1180`; `candidate_quality_meta_signals.dart:50` → `:1279-1288`; `semantic_layer_v2_backfill.dart:167` → `:633-641`. Os três últimos fazem 5 CREATE TABLE, 8 índices e 2 `CREATE OR REPLACE VIEW`, o que **redefine views sem migration nem ledger**. Dois exigem aprovação textual (`candidate_quality_data_foundation.dart:61-68`, `semantic_layer_v2_backfill.dart:35-42`); o `meta_signals` só exige `--apply` (`:23-24`). Aprovação não é proibição | Nenhum | Converter para verificação |
| 6 | Os CLIs **Commander** não executam DDL | **N** (0 de 3) | `commander_reference_profile.dart:74-75`, `commander_reference_profile_lorehold.dart:70-71`, `commander_reference_deck_corpus.dart:54`, via `commander_reference_card_stats_support.dart:471-512`, `commander_reference_deck_corpus_support.dart:1193-1254` e `commander_reference_profile_support.dart:606-616`. **[rev.]** Sem aprovação textual, mas o DDL só roda com `--apply` (dry-run é o padrão: `commander_reference_profile.dart:22-23`, `_lorehold.dart:44-45`, `deck_corpus.dart:21-22`). As tabelas já pertencem à migration 034 (`runtime_schema_migration_contract_test.dart:72-78`), então o ensure é redundante | Nenhum | Trocar os 3 `ensure*` de lib por verificação |
| 7 | `sync_state` tem um único DDL | **N** | 3 DDLs divergentes (recontado em todo o repo): `database_setup.sql:1578-1582` (`value` nullable), `sync_cards.dart:226-236` (nullable), `sync_rules.dart:678-688` (NOT NULL). Nenhuma migration é dona. O manifesto guarda NOT NULL e o fresh cria nullable | Nenhum | Manter um DDL e remover os dois dos CLIs. Escolher nullable ou NOT NULL exige saber a forma real (`BT-DB-001`) |
| 8 | Schema só muda por migration e gate | **Pa** | O runner está protegido (`migrate.dart:4161-4172`, `:4038-4069`). Caminhos paralelos: #2, #4, #5, #6; o Hermes `sync_battle_card_rules_pg.py:290-390` (ALTER, DROP CONSTRAINT e CREATE UNIQUE INDEX em `card_battle_rules`, exige só aprovação em `:198-206`); **[rev.]** os **47 pacotes `*_apply.sql` versionados** e os 4 builders que os geram (achado 11). Nenhuma barreira no próprio banco: zero `REVOKE`/`GRANT`/event trigger no repo, e o wrapper conecta como superusuário `postgres` (`with_new_server_pg.sh:179`) | `data_model_migration_test.dart:9-73` cobre o runner. `test_sync_battle_card_rules_pg_selection.py:56-63` afirma só que **sem** aprovação falha, ou seja, com aprovação o DDL roda | Fechar os caminhos paralelos. (Opcional) um role de runtime sem CREATE |
| 9 | O auditor cobre todos os entrypoints | **N** | O único teste cobre 5 arquivos fixos (`runtime_schema_migration_contract_test.dart:10-20`). O gerador de project logic **absorve** o DDL de `server/bin` e `server/lib` como fonte legítima de schema (`project_logic_generator.dart:3155-3165`), e seu regex de `mutation_class` ignora CREATE/ALTER/DROP (`:3526-3529`). Por isso `setup_database.dart` e os 3 CLIs Commander saem como `read_only_or_unknown` no manifesto (conferido em `scripts_and_jobs`). `audit_data_model_links.dart` é relatório: não falha, e executa DDL | — | Um scanner com allowlist (migrations, `setup.sql`, TEMP `ON COMMIT DROP`, SQLite Hermes, pacotes `*_apply.sql` históricos) sobre `server/bin`, `server/lib`, `server/routes`, `scripts` e os scripts Hermes que tocam PG, falhando em DDL persistente |

**O que realmente falta.** O trabalho é mecânico, mas largo. Os objetos que os CLIs
"garantem" já existem no fresh:
- colunas de `cards` em `database_setup.sql:120-168`;
- índices em `:178-179`;
- `sets` em `:206`;
- candidate-quality e nomes localizados na migration 022 (`migrate.dart:606-649`);
- Commander na 034.

Então basta trocar DDL por verificação que falha fechado em 11 CLIs (e em 4 helpers de
lib). Depois:
- tombstonar ou restringir `setup_database.dart`, e fazê-lo falhar com rc≠0;
- gatear `extract_meta_insights --full`;
- aposentar `database_indexes.sql`;
- decidir sobre o DDL do Hermes, os 4 builders e os 47 pacotes `manaloom_deploy_audit`;
- deixar `sync_state` com um único DDL;
- escrever o auditor de todos os entrypoints e ensinar o gerador a tratar DDL como
  mutação.

Unidades de trabalho:

- **~29 arquivos de código [rev.: era ~24], mais 2 docs:**
  - 11 CLIs;
  - 4 lib;
  - 3 resets;
  - Hermes `sync_battle_card_rules_pg.py` e seu teste (2);
  - **[rev.]** 4 builders de pacote SQL (0 se a decisão for só allowlist);
  - auditor (1);
  - gerador e teste (2);
  - `audit_data_model_links.dart` (1);
  - **[rev.]** `runtime_schema_migration_contract_test.dart`, estendido ou substituído
    pelo auditor (1).
- **~11 testes [rev.: era ~9]:**
  - auditor genérico e allowlist de exceções (2);
  - `sync_state` com DDL único;
  - tombstone executável de `setup_database`, com rc≠0;
  - guarda do `--full`;
  - verificação que falha fechado para sync, Commander e candidate-quality/backfill (3,
    ou parametrizado);
  - classificação do gerador;
  - `ensure_pg_table` só verifica;
  - `audit_data_model_links.dart` sem DDL no alvo.
- **Migração:** não é obrigatória para o aceite. Reconciliar `sync_state` real×fresh, se
  divergir, vira item do `BT-DB-002`.
- **Prova:** receipt de gate local; não precisa de captura viva.
- **Decisão humana:**
  - destino de `setup_database.dart`, de `--full`, de `database_indexes.sql`, dos 4
    builders e dos 47 pacotes `manaloom_deploy_audit`;
  - DDL canônico de `sync_state`.

**Dependências.** `BT-DB-001` é **formal para escrever o código**. Os itens #2, #4, #5,
#6, #8 e #9 podem andar já, porque tudo o que é removido existe no baseline fresh. Só a
escolha do DDL único de `sync_state` (#7) precisa da forma real. **[rev.]** Mas para
**operar** os CLIs convertidos contra produção, a dependência é real: um CLI que passa a
só verificar falha fechado se a produção não tiver algum objeto que ele antes criava, e só
o inventário do `BT-DB-001` diz se falta algum. Cada falta vira item de migration do
`BT-DB-002`. Os CLIs não estão no daemon de ops, então o impacto fica restrito a
execuções manuais.

**Sobreposição:**
- `BT-DB-005`: `extract_meta_insights` trunca e escreve em tabelas ML fora do baseline, e
  a mesma decisão resolve os dois.
- `BT-AI-017`: a ingestão Commander depende de `BT-DB-004`, com os mesmos 3 CLIs.
- `BT-DB-001`: `database_indexes.sql`, os índices manuais e as tabelas dos pacotes SQL
  aparecem como live-drift.
- `BT-AI-027`: o consumer `ml-status`.

---

## Apêndice A — entrypoints com DDL persistente em PostgreSQL fora de migration

Varredura estática de todos os arquivos versionados `.dart/.py/.sh/.sql` fora de testes e
de `app/`. Ficam de fora: DDL em SQLite (scripts Hermes com `sqlite3`, inclusive os 5
`manaloom_*_review/evidence/gate.py` e o `pull_learning_events.py` de `server/bin`) e TEMP
`ON COMMIT DROP`. **[rev.]** A varredura foi refeita nesta revisão com regex multilinha e
confere com a lista abaixo, salvo os pacotes `*_apply.sql`, que faltavam.

| Entrypoint | DDL | Gate de aprovação | Onde |
| --- | --- | --- | --- |
| `server/bin/setup_database.dart` | o `database_setup.sql` inteiro (CREATE, ALTER, 33 DROP de CONSTRAINT/INDEX/TRIGGER e UPDATE); **[rev.]** falha aberto (rc=0 em erro) | não | `:7-31`, `:26-27` |
| `server/database_indexes.sql` (psql manual) | 36 CREATE INDEX, 29 deles fora do baseline | não | `:8-9` |
| `server/bin/sync_cards.dart` | CREATE TABLE `sync_state`/`sets`, 5 ALTER em `cards`, 2 CREATE INDEX | não (roda sempre) | `:80-83`, `:226-287` |
| `server/bin/sync_cards_full_fast.py` | 7 ALTER em `cards`, 2 CREATE INDEX | não | `:231-245`, `:346` |
| `server/bin/sync_rules.dart` | CREATE TABLE `sync_state` (NOT NULL), 2 CREATE INDEX | sim | `:144-145`, `:667-688` |
| `server/bin/sync_localized_card_names.dart` | CREATE TABLE, 3 índices, CREATE OR REPLACE VIEW | **[rev.]** só `--apply` (dry-run padrão) | `:42-43`, `:80`; lib `:136-142` |
| `server/bin/backfill_card_combat_metadata.py` | 3 ALTER, 1 CREATE INDEX | não (só `--dry-run` evita) | `:146-154`, `:215-218` |
| `server/bin/candidate_quality_data_foundation.dart` | 5 CREATE TABLE, 8 índices, 2 CREATE OR REPLACE VIEW | sim | `:61-68`, `:257`, `:1171-1180` |
| `server/bin/candidate_quality_meta_signals.dart` | idem | **[rev.]** só `--apply` | `:23-24`, `:50`, `:1279-1288` |
| `server/bin/semantic_layer_v2_backfill.dart` | idem | sim | `:35-42`, `:167`, `:633-641` |
| `server/bin/commander_reference_profile.dart` | CREATE TABLE e índices (2 tabelas) | **[rev.]** só `--apply` | `:22-23`, `:74-75` |
| `server/bin/commander_reference_profile_lorehold.dart` | idem | **[rev.]** só `--apply` | `:44-45`, `:70-71` |
| `server/bin/commander_reference_deck_corpus.dart` | 3 CREATE TABLE, 2 índices | **[rev.]** só `--apply` | `:21-22`, `:54` |
| `server/bin/audit_data_model_links.dart` | CREATE TABLE/INDEX/VIEW em BEGIN/ROLLBACK no alvo | não (roda sem `--skip-db`) | `:283`, `:395-429` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py` | ALTER, DROP CONSTRAINT, CREATE UNIQUE INDEX em `card_battle_rules` | sim | `:198-206`, `:290-390` |
| builders de pacote SQL (`xmage_batch_pg_package_builder.py`, `lorehold_entreat_rule_package_preapply.py`, `lorehold_brain_in_a_jar_pg_package_preflight.py`, `global_commander_fixture_cleanup_audit.py`) | CREATE SCHEMA e tabelas em `manaloom_deploy_audit` | fluxo de pacote aprovado | `:1133-1135`, `:202-204`, `:279`, `:939`/`:985-1000` |
| **[rev.]** 47 pacotes versionados `docs/hermes-analysis/master_optimizer_reports/*_apply.sql` (psql manual) | 45 CREATE SCHEMA, 89 CREATE TABLE em `manaloom_deploy_audit`, 6 ALTER, 3 DROP; 1 CREATE TABLE em `public` (`pg596b_…_apply.sql:3`) | fluxo de pacote aprovado | — |
| `server/bin/extract_meta_insights.dart` (reset, não DDL) | 3 TRUNCATE … CASCADE em `--full` | não | `:88-95` |

Conformes (só verificam ou usam TEMP): `sync_combos.dart`, `sync_rulings.dart`,
`sync_prices_mtgjson_fast.dart`, `run_three_commander_resolution_validation.dart:1476`,
e os `scripts/manaloom_*` de cleanup (`CREATE TEMP TABLE … ON COMMIT DROP`).
`xmage_pattern_registry_builder.py:402-440` só **gera** uma proposta de DDL em texto
("Do not apply without explicit PostgreSQL approval"), não executa.

Nenhum destes está no job list do daemon de ops
(`server/bin/manaloom_ops_daemon.py:711-733`, `JOB_REQUIRED_CAPABILITIES`), e a imagem da
API só leva o servidor compilado (`server/Dockerfile:25-31`); por isso
`server/bin/cron_sync_cards.sh`, que roda `dart run bin/sync_cards.dart` no container da
API, falharia por falta de fonte. Mas a imagem de ops copia o repo inteiro
(`server/Dockerfile.manaloom-ops:21`), então todos são alcançáveis por `docker exec`.

## Apêndice B — comandos de leitura usados

`git grep`, `git log`, `git show`, `git diff --stat`, `sed -n`, `awk`, `grep`, `wc`,
leitura do `docs/generated/TASK_REGISTRY.json` e do `project_logic_manifest.json` com
`python3`, uma varredura estática em Python dos DDLs (só leitura) e a comparação dos
índices de `database_indexes.sql`. Nada escreveu no repo, nada abriu conexão com banco e
nada rodou `flutter`, `dart test` ou gate. Na revisão adversarial foram usados também
`initdb --version`/`pg_ctl --version` (só versão) e `ls` dos dumps (só metadados, sem
abrir conteúdo).

---

## Verificação adversarial

Revisor cético, 2026-09-22, mesma HEAD `d15beb05b`, somente leitura. Foram reexaminadas
as **35 asserções** do documento: todas as P, todas as S e as Pa/N contra o código. Os
testes citados foram abertos e os números, recontados.

### O que caiu

| Tarefa | Asserção | De | Para | Por quê |
| --- | --- | --- | --- | --- |
| `BT-DB-004` | #1 `update_schema.dart` falha fechado | P | S | O único teste (`sql_statement_splitter_test.dart:57-69`) só verifica strings do fonte e não executa o binário. A implementação está certa (15 linhas, só `dart:io`), e o risco residual é quase nulo |
| `BT-DB-004` | #3a os 5 caminhos de request não executam DDL | P | S | O teste (`runtime_schema_migration_contract_test.dart:22-39`) procura só 3 substrings em 5 arquivos fixos. Não pegaria `CREATE UNIQUE INDEX`, `CREATE OR REPLACE VIEW`, `DROP`, quebra de linha nem helper indireto. A implementação foi confirmada por varredura própria, mas não há proibição executável |
| `BT-DB-001` | estado medido | metade | mal-começada | As 5 P vêm de uma única execução do gate e cobrem só nomes do lado baseline. Lado real, classificação e artefato: nada. A comparação profunda exige re-extrair o próprio fresh |
| `BT-DB-004` | estado medido | metade | mal-começada | 1 das 5 cláusulas do aceite está implementada, e só com prova textual. As outras 4 estão abertas (2 de 13 CLIs convertidos, auditor inexistente, `sync_state` com 3 DDLs). A remoção do DDL de request não é "proibir" |
| grupo | contagem de arquivos e testes | ~46 arquivos e ~28 testes | ~66 arquivos, ~35 testes novos e 8 a atualizar | A 059 precisa tocar 15 arquivos que fixam "058" (8 deles testes). O BT-DB-004 esqueceu os 4 builders de pacote SQL e o contract test que será substituído. O BT-DB-001 esqueceu o contrato textual do gate e os casos do comparador |

### O que o documento não tinha e foi acrescentado

- **Não há evidência de que a 058 esteja em produção, e nenhum ID é dono disso** (achado 10). Deploy, readiness e
  contrato de release exigem 058, e o último ledger vivo conhecido é 057. A primeira
  migration a cruzar produção sob a disciplina do BT-DB-002/003 é a 058, e ela não tem
  perfil, preflight de forma nem checksum.
- **47 pacotes `*_apply.sql` versionados** criam schema e tabelas fora de migration,
  inclusive uma tabela de backup em `public` (achado 11).
- **O primeiro passo do apply já é DDL** (`CREATE TABLE IF NOT EXISTS schema_migrations`,
  `migrate.dart:4294-4300`), antes de ler o ledger. O preflight do BT-DB-002 e o "misto
  falha antes de DDL" do BT-DB-003 têm de vir antes dele.
- **Reexecutar o gate em HEAD não é trivial** (achado 4). Antes da comparação tbls vêm um
  teste Battle live com +828 linhas desde o último verde e o `project_logic --check`. O
  PG do PATH é 14.18 contra dumps de produção em 17, e há o problema de `LC_ALL`.
- **`setup_database.dart` falha aberto** (rc=0 em apply parcial).
- **Fingerprint SSH** é mais uma decisão humana para a leitura live do BT-DB-001.
- **Ambiguidade da leitura do BT-DB-001** (fresh-only na onda 01 e na fila; real contra
  fresh no aceite e no BT-DB-005). Ela muda o tamanho da task e precisa do dono.

### O que subiu (justiça no outro sentido)

Nenhuma asserção foi promovida. Três pontos estavam mais duros do que o código justifica,
e foram corrigidos no texto sem mudar estado:
- **Achado 6.** O modo read-only do wrapper não deixa rodar nenhuma ferramenta Dart além
  de `migrate --status`, e o padrão seguro (psql com `BEGIN TRANSACTION READ ONLY`) já é
  usado pelo deploy. O risco de DDL live pelo caminho governado é menor do que o descrito.
- **PII dos dumps.** `manaloom_validate_restore.sh` restaura só o schema por padrão, o
  que dá a forma real sem ler linhas.
- **CLIs Commander, `sync_localized_card_names` e `candidate_quality_meta_signals`.** Não
  têm aprovação textual, mas o DDL só roda com `--apply`; o dry-run é o padrão.

Também foi confirmado, e mantido como P, que a prova do fresh (receipt de 2026-08-24) vale
para HEAD no conteúdo. `setup.sql`, `migrate.dart`, os 6 arquivos de lib interpolados, o
gate, o `.tbls.yml` e a seção `database` do manifesto são byte-idênticos entre `fd0397a5`
e HEAD. Mas é prova de nomes, sem log hasheado.

### Linhas conferidas e corretas

Batem com o código as linhas de interpolação (022–045), o runner (`:4007-4021`,
`:4161-4172`, `:4258-4261`, `:4311-4337`), os 3 DDLs de `sync_state`, os 29 de 36 índices,
as 17 relações só no real, o GIN duplicado, o driver sem `PGOPTIONS` e as dependências do
registry. Imprecisões menores foram corrigidas:
- a política de rollback está em `:4071-4102`, não `:4079-4098`;
- o dump de 2026-08-03 está em 056, não apenas "pré-058";
- `PGOPTIONS` está em `:277-279`;
- os requisitos de aprovação de `candidate_quality_data_foundation` e
  `semantic_layer_v2_backfill` estão em `:61-68` e `:35-42`;
- `sync_cards.dart` faz 5 ALTER em `cards` (`color_identity`, `power`, `toughness`,
  `keywords`, `is_reserved`), não 4;
- os 33 DROP do `setup.sql` são 25 `DROP CONSTRAINT`, 7 `DROP TRIGGER` e 1 `DROP INDEX`,
  sem `DROP TABLE` nem `DROP COLUMN`.

### Veredito de otimismo

**Otimista demais.** O documento é cuidadoso e quase todas as referências conferem. Mas:
- deu P a duas asserções provadas só por teste textual;
- chamou de "metade" duas tarefas com o núcleo do aceite ausente;
- subcontou os arquivos da próxima migration em cerca de 10;
- tratou a reexecução do gate como um comando;
- **não viu que o último ledger vivo conhecido é 057**. Para o plano do dono, esse é o ponto
  mais caro: nenhuma HEAD de backend sobe sem aplicar a 058 live, e isso não tem dono no
  registry.
