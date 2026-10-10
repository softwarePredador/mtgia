-- Fichário: tira da produção o índice único `uq_binder_user_card_cond_foil_list`
-- (decisão do dono de 2026-10-10, item 9). A D-83 deixou o índice fora do banco
-- novo (066): sem `language`, ele contradiz a identidade física da 049 (ADR 0008).
-- Na produção, o `POST /binder` da mesma carta em outro idioma bate nele com um
-- 23505 que o `ON CONFLICT` da rota (o da 049) não trata, e a rota responde 500.
--
-- Falha fechado, sem remover nada, se:
--   - a identidade física da 049 (`uq_user_binder_items_physical_identity`) não
--     estiver no banco como único em
--     (user_id, card_id, condition, is_foil, language, list_type): sem ela o
--     fichário ficaria sem índice único;
--   - o índice com esse nome não for o da auditoria BT-DB-001: único, de
--     `user_binder_items`, em (user_id, card_id, condition, is_foil, list_type), sem
--     expressão nem predicado.
-- A contagem antes e depois traz os dois índices, os itens do fichário e os grupos
-- da mesma cópia em mais de um idioma (zero enquanto o índice existir).
--
-- Roda no lote de deploy, depois da promoção (decisão do dono de 2026-10-10, item 11),
-- com a palavra do dono na hora, pelo wrapper de escrita e com as duas aprovações
-- canônicas no processo chamador:
--   server/bin/with_new_server_pg.sh --write-approved psql -X -v ON_ERROR_STOP=1 \
--     -At -F $'\t' -f server/sql/lote/binder_drop_uq_binder_user_card_cond_foil_list.sql
-- Saída: linhas `fase<TAB>objeto<TAB>quantidade` (fases antes, acao e depois).
-- Uma transação só. Idempotente: sem o índice, não faz nada.

\set ON_ERROR_STOP on

BEGIN;
SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '120s';

CREATE TEMP VIEW binder_indices AS
SELECT index_class.relname::text AS nome,
       index_row.indisunique AS unico,
       index_row.indrelid = 'public.user_binder_items'::regclass AS da_tabela,
       index_row.indpred IS NULL AND index_row.indexprs IS NULL AS simples,
       ARRAY(
         SELECT attribute_row.attname::text
         FROM unnest(index_row.indkey::int2[]) WITH ORDINALITY AS chave(attnum, ordem)
         JOIN pg_attribute attribute_row
           ON attribute_row.attrelid = index_row.indrelid
          AND attribute_row.attnum = chave.attnum
         ORDER BY chave.ordem
       ) AS colunas
FROM pg_index index_row
JOIN pg_class index_class ON index_class.oid = index_row.indexrelid
WHERE index_row.indexrelid IN (
  to_regclass('public.uq_binder_user_card_cond_foil_list'),
  to_regclass('public.uq_user_binder_items_physical_identity')
);

CREATE TEMP VIEW binder_contagem AS
SELECT 1 AS ordem, 'uq_binder_user_card_cond_foil_list' AS objeto,
       (SELECT COUNT(*) FROM binder_indices
        WHERE nome = 'uq_binder_user_card_cond_foil_list') AS quantidade
UNION ALL
SELECT 2, 'uq_user_binder_items_physical_identity',
       (SELECT COUNT(*) FROM binder_indices
        WHERE nome = 'uq_user_binder_items_physical_identity')
UNION ALL
SELECT 3, 'itens_do_fichario', (SELECT COUNT(*) FROM public.user_binder_items)
UNION ALL
SELECT 4, 'copias_em_mais_de_um_idioma',
       (
         SELECT COUNT(*)
         FROM (
           SELECT 1
           FROM public.user_binder_items
           GROUP BY user_id, card_id, condition, is_foil, list_type
           HAVING COUNT(DISTINCT language) > 1
         ) grupos
       );

SELECT 'antes' AS fase, objeto, quantidade::text FROM binder_contagem ORDER BY ordem;

DO $binder_drop$
DECLARE
  identidade RECORD;
  alvo RECORD;
BEGIN
  SELECT * INTO identidade
  FROM binder_indices
  WHERE nome = 'uq_user_binder_items_physical_identity';
  IF NOT FOUND
     OR NOT identidade.unico
     OR NOT identidade.da_tabela
     OR NOT identidade.simples
     OR identidade.colunas IS DISTINCT FROM ARRAY[
       'user_id', 'card_id', 'condition', 'is_foil', 'language', 'list_type'
     ] THEN
    RAISE EXCEPTION
      'binder_drop recusado: a identidade física da 049 (uq_user_binder_items_physical_identity) não está no banco como esperado; nada foi removido';
  END IF;

  SELECT * INTO alvo
  FROM binder_indices
  WHERE nome = 'uq_binder_user_card_cond_foil_list';
  IF NOT FOUND THEN
    PERFORM set_config('manaloom.binder_drop_removidos', '0', true);
    RETURN;
  END IF;
  IF NOT alvo.unico
     OR NOT alvo.da_tabela
     OR NOT alvo.simples
     OR alvo.colunas IS DISTINCT FROM ARRAY[
       'user_id', 'card_id', 'condition', 'is_foil', 'list_type'
     ] THEN
    RAISE EXCEPTION
      'binder_drop recusado: uq_binder_user_card_cond_foil_list não é o índice da auditoria (colunas %); nada foi removido',
      alvo.colunas;
  END IF;

  DROP INDEX public.uq_binder_user_card_cond_foil_list;
  PERFORM set_config('manaloom.binder_drop_removidos', '1', true);
END;
$binder_drop$;

SELECT 'acao' AS fase, 'indices_removidos' AS objeto,
       current_setting('manaloom.binder_drop_removidos') AS quantidade;

SELECT 'depois' AS fase, objeto, quantidade::text FROM binder_contagem ORDER BY ordem;

DO $binder_drop_pos$
BEGIN
  IF to_regclass('public.uq_binder_user_card_cond_foil_list') IS NOT NULL THEN
    RAISE EXCEPTION 'binder_drop: uq_binder_user_card_cond_foil_list continua no banco';
  END IF;
  IF to_regclass('public.uq_user_binder_items_physical_identity') IS NULL THEN
    RAISE EXCEPTION 'binder_drop: a identidade física da 049 sumiu';
  END IF;
END;
$binder_drop_pos$;

DROP VIEW binder_contagem;
DROP VIEW binder_indices;

COMMIT;
