# Receipt — BT-DB-004: a migration 066 adota os 21 índices só da produção (D-83) — 2026-09-28

- **Tarefa:** a pendência da `BT-DB-004` com os índices que só a produção tinha e que não vinham
  do `database_indexes.sql` aposentado. Eles estavam na lista fechada como "proposta de 066".
- **Decisão do dono em 2026-09-28, D-83:** a 066 com os 21 índices, sem o
  `uq_binder_user_card_cond_foil_list`. É adoção de índice com o nome da produção e
  `IF NOT EXISTS`.
- **Executado por:** Frente C (banco e operação), no worktree da frente, branch
  `banco/rodada1-2026-09-24`, com o código que entra no mesmo commit deste receipt.
- **Limites:** nada tocou a produção. As definições são as da auditoria BT-DB-001, que já estão
  no repositório. O ensaio na estrutura do dump seguiu a autorização da coordenação: só nomes e
  resultados, cluster apagado.

## O que entrou

| Arquivo | Mudança |
| --- | --- |
| `server/bin/migrate.dart` | migration 066, `adopt_remaining_production_only_indexes`, com os 21 `CREATE INDEX IF NOT EXISTS` com o nome e a definição da produção. O down derruba na ordem inversa. Rollback só manual, como a 063 a 065, porque um down automático tiraria da produção índices anteriores à migration |
| `server/database_setup.sql` | os mesmos 21 comandos, com o mesmo texto, na seção dos índices adotados (064 a 066) |
| Readiness, contrato do deploy e contrato de release | a 066 entra nas listas de migrations exigidas (30 na readiness e 27 no deploy). A última continua a 076 |
| `server/config/schema_drift_allowlist.json` | saem as 21 entradas "pendente: BT-DB-004 (066)", e a 066 entra em `reconciliado_pelas_migrations`. O `uq_binder_user_card_cond_foil_list` fica, com a decisão D-83: não é adotado |
| Testes | `schema_adoption_migrations_test.dart` (grupo da 066, o bootstrap com o mesmo texto, rollback manual), `schema_adoption_db_live_test.dart` (os 47 índices da 064 a 066 com a definição da produção), `migration_rehearsal_test.py` e `migration_rehearsal_db_live_test.py` (a 066 na lista fechada), `health_readiness_support_test.dart`, que passa a conferir a contagem do SQL contra a lista, e o teste do gerador (67 migrations) |

Os 21 índices estão em:

- `battle_simulations`: 4;
- `card_legalities`: 3;
- `cards`: 2;
- `deck_cards`: 1;
- `deck_matchups`: 3;
- `decks`: 3;
- `meta_decks`: 2;
- `user_binder_items`: 1;
- `users`: 2.

Na produção, a 066 não muda nada: os índices já existem com esses nomes.

## Provas

| Prova | Resultado |
| --- | --- |
| As 21 definições da 066 contra a auditoria (índices só da produção, fora do arquivo aposentado e sem `UNIQUE`) | iguais, uma a uma |
| Suíte de foco (adoção de schema, readiness, operações de IA, migrations de battle, SQL literal, regra dos gatilhos, 075 e 076, preflight, DDL e regressão de privacidade) | 100 verdes; `migration_rehearsal_test.py` 10 |
| Testes de banco num descartável com a 066 (67 migrations, última 076): os 11 Dart e os 4 Python | todos verdes; o ensaio dos fixtures dá 5 de 5 |
| Ensaio na estrutura do dump de 2026-09-23 com a 066 | **PASS**: 18.624 diferenças, todas na lista fechada, 0 inesperada, 0 entrada sem ocorrência; reaplicação sem mudança; rollback pelo restore idêntico; reforward igual; cluster apagado |
| Mutações (`mutacoes_066.json`, na cópia de trabalho da frente) | 7 de 7 derrubadas |
| Gates, na trava | suíte do servidor: 406 arquivos em 11 lotes, todos com rc=0 (tags live fora); `project_logic --write`, `--check` e `--test` verdes; contrato de release `passed` (34 contratos); comparação de schema do gate tbls num banco novo: PASS (86 tables, 6 views, 100 foreign keys, 67 migrations) |

**Mutações:**

- F01 a F05:
  - um índice a menos;
  - uma definição diferente da produção;
  - o bootstrap sem um índice;
  - o down fora da ordem;
  - o rollback automático.
- F06: a lista fechada ainda com um índice da 066.
- F07: a readiness sem contar a 066. Na primeira rodada ela passou, porque nenhum teste
  conferia a contagem do SQL. O teste da readiness foi apertado para conferir a contagem contra a
  lista, e F07 foi derrubada depois disso.

## O que segue aberto

- **Aplicar a 066 na produção,** no lote de deploy, com a palavra do dono. Lá ela é nula.
- **O `uq_binder_user_card_cond_foil_list` fica na produção e fora do banco novo (D-83).**
  - Ele faz o `POST /binder` devolver 500 para a mesma carta em outro idioma.
  - *Recomendação:* tirá-lo da produção num passo governado (`decisoes-pendentes.md`).
