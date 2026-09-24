-- BT-CAP-001 (D-14): capacidade do PostgreSQL de produção, SÓ LEITURA.
--
-- Roda dentro de scripts/manaloom_capacity_snapshot.sh, pelo wrapper em modo
-- leitura. Cada linha sai como "item<TAB>valor". A transação é READ ONLY e
-- termina em ROLLBACK. Das sessões só sai a contagem por estado: nenhum texto
-- de consulta, usuário ou endereço.

BEGIN TRANSACTION READ ONLY;

SELECT 'transaction_read_only', current_setting('transaction_read_only');

SELECT 'server_version', current_setting('server_version');

SELECT 'max_connections', current_setting('max_connections');

SELECT 'shared_buffers', current_setting('shared_buffers');

SELECT 'effective_cache_size', current_setting('effective_cache_size');

SELECT 'work_mem', current_setting('work_mem');

SELECT 'database_size_bytes', pg_database_size(current_database())::text;

SELECT 'connections_total', count(*)::text
FROM pg_stat_activity
WHERE datname = current_database();

SELECT 'connections_state:' || COALESCE(state, 'sem_estado'), count(*)::text
FROM pg_stat_activity
WHERE datname = current_database()
GROUP BY state
ORDER BY 1;

SELECT 'schema_bytes:' || namespace.nspname,
       sum(pg_total_relation_size(relation.oid))::text
FROM pg_class relation
JOIN pg_namespace namespace ON namespace.oid = relation.relnamespace
WHERE relation.relkind IN ('r', 'm', 'p')
  AND namespace.nspname NOT IN ('pg_catalog', 'information_schema')
  AND namespace.nspname NOT LIKE 'pg_toast%'
GROUP BY namespace.nspname
ORDER BY 1;

SELECT 'relation_bytes:' || namespace.nspname || '.' || relation.relname,
       pg_total_relation_size(relation.oid)::text
FROM pg_class relation
JOIN pg_namespace namespace ON namespace.oid = relation.relnamespace
WHERE relation.relkind IN ('r', 'm', 'p')
  AND namespace.nspname NOT IN ('pg_catalog', 'information_schema')
  AND namespace.nspname NOT LIKE 'pg_toast%'
ORDER BY pg_total_relation_size(relation.oid) DESC, 1
LIMIT 15;

ROLLBACK;
