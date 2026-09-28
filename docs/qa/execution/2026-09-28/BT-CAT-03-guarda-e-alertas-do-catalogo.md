# Receipt — BT-CAT-03: guarda de leitura, alertas, frescor e teto do cache do catálogo — 2026-09-28

- **Tarefa:** `BT-CAT-03`, rate limit, cache, frescor e observabilidade do catálogo. O aceite
  pede o limitador fora do ar em fail-closed quando a leitura é cara, e alerta de DML ou de
  chamada a terceiro numa leitura (acima de zero).
- **Executado por:** Frente C (banco e operação), no worktree da frente, branch
  `banco/rodada1-2026-09-24`, com o código que entra no mesmo commit deste receipt.
- **Já feito antes, pela frente de catálogo (2026-09-23, no ar):**
  - o limite por IP da busca textual sem filtro, com fail-closed (D-36);
  - o alerta de frescor no job de catálogo.
- **Limites desta rodada:** nada tocou a produção. O job de refresh do catálogo, ativo na
  produção, não mudou: nem o script nem o agendamento. As regras novas só leem o que ele já
  grava.

## O que faltava e o que entrou

| Faltava (linha do backlog) | O que entrou |
| --- | --- |
| Alerta de chamada a terceiro numa leitura, que era só guarda de teste | `server/lib/catalog_read_guard.dart`, no middleware de `/cards`, `/sets` e `/rules`. Abrir um cliente HTTP numa leitura, inclusive pelo `package:http`, conta em `catalog_read_guard.upstream_blocked` e falha antes de conectar. O log leva o template da rota, sem identificador. `/health/metrics` publica a contagem, e o avaliador de SLO alerta com uma só tentativa (`catalog_read_upstream`, crítico) |
| Alerta de DML numa leitura | Vigiado no PostgreSQL, qualquer que seja a origem. O avaliador lê em `pg_stat_user_tables` as linhas inseridas, atualizadas e apagadas em `cards`, `sets` e `card_legalities`, e compara com a avaliação anterior. Se elas mudaram sem execução do job de catálogo no intervalo (`sync_log` com `catalog_reference`), abre `catalog_written_outside_job` (crítico), com o número de linhas. Estatística zerada por reinício não alerta |
| Teto de entradas do `EndpointCache` | Teto de 10.000 por réplica. No teto saem primeiro as vencidas, depois as gravadas há mais tempo. Regravar uma chave a leva para o fim. `/health/metrics` publica o teto e `endpoint_cache_evictions`. O alerta `endpoint_cache_large` continua em 5.000 |
| O `return await` de `server/lib/rate_limit_middleware.dart` | `distributedAllowedOrNull` põe o `await` dentro do `try`. A falha assíncrona do contador distribuído agora vira `null`, e o chamador usa o contador em memória, como o código já pretendia; antes, ela escapava como 500. A busca cara do catálogo segue com o fail-closed próprio |

## Achado: o `catalog_stale` do avaliador de SLO (BT-OBS-001) alertaria sempre

- **O problema:** o avaliador lia o último sync com sucesso de `cards` e `card_legalities` em
  `sync_log`, os tipos do sync antigo. O job de catálogo ativo grava `catalog_reference`,
  `catalog_reference:cards` e as demais.
- **O efeito:** com o ops configurado, o alerta de catálogo velho abriria mesmo com o catálogo
  em dia. Ele ainda não está ligado na produção.
- **A correção:** o avaliador passa a ler o frescor pela mesma regra do job. Vale a data da
  fonte aplicada (`catalog_reference_source_updated_at` em `sync_state`) e, sem ela,
  `cards_last_sync_at`.
  - O alerta passa a ter um código só, `catalog_stale`.
  - A política vai para a versão `2026-09-28.1`, com 14 regras.
  - O runbook `docs/runbooks/SLO_E_ALERTAS.md` ganhou as seções novas.

## Provas

| Prova | Resultado |
| --- | --- |
| `server/test/catalog_read_guard_test.dart` | 5 verdes |
| `server/test/endpoint_cache_cap_test.dart` | 4 verdes |
| `server/test/rate_limit_middleware_test.dart`, `request_metrics_service_test.dart`, `catalog_routes_read_only_guard_test.dart`, `catalog_search_rate_limit_test.dart`, `endpoint_cache_ttl_test.dart` e `operational_alerts_test.dart` | 58 verdes no conjunto |
| `server/test/slo_alerts_test.py` | 24 verdes |
| `server/test/slo_alerts_db_live_test.py` (`RUN_SCHEMA_DB_TESTS=1`): o frescor pelo `sync_state`, a última execução do job e a contagem de escrita com inserção e atualização | 2 verdes |
| Os outros testes de banco da frente, no descartável com a `BT-DB-003` (64 migrations, última 074): 10 `*_db_live_test.dart` e 3 `*_db_live_test.py` | todos verdes |
| Mutações (`mutacoes_bt_cat_03.json`), refeitas sobre a 074 e a `BT-DB-003` | 16 de 16 derrubadas |
| Suíte do servidor, testes de banco e gates | suíte do servidor: 404 arquivos em 11 lotes, todos com rc=0 (tags live fora); `project_logic --write`, `--check` e `--test` verdes; contrato de release `passed` (34 contratos); comparação de schema do gate tbls num banco novo: PASS (80 tables, 6 views, 100 foreign keys, 64 migrations) |

**Mutações:**

- C01: frescor ignorado.
- C02: execução do job no intervalo tratada como escrita de fora.
- C03: escrita de fora nunca alerta.
- C04: estatística zerada tratada como escrita.
- C05: só inserções contam; só o teste de banco pega.
- C06: tentativa de chamada a terceiro não alerta.
- C07: as métricas perdem o guarda.
- C08: a política sem a regra nova.
- C09: `/sets` sem o guarda.
- C10: o guarda não conta.
- C11: o log com o identificador.
- C12: `/health/metrics` sem o guarda.
- C13: o cache sem teto.
- C14: regravar não renova a ordem.
- C15: o teto tira uma entrada viva antes da vencida.
- C16: o contador distribuído sem o `await` dentro do `try`.

## O que segue aberto

- As regras novas só valem na produção depois de configurar o serviço de ops, que é
  coordenação e dono (BT-OBS-001). São elas:
  - `catalog_read_upstream`;
  - `catalog_written_outside_job`;
  - o `catalog_stale` corrigido.
- O app ainda envia `sync=true` ao `GET /cards/printings`, e o servidor ignora. Tirar o
  parâmetro é da raia do app (`BT-CAT-02`).
- Os limites novos (teto do cache e as duas regras) entram na proposta de limites pendente do
  dono, com o resto da política de SLO.
