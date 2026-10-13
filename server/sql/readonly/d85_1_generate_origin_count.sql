-- D-118 (correção 1 da D-85), só leitura: conta os decks que vieram do Generate pela
-- marca de origem que o banco tiver, para o dono decidir com o número na sessão de
-- leitura do lote. A correção 1 (`server/sql/lote/d85_1_deck_description_generate_prompt.sql`)
-- só limpa a descrição igual a um prompt ainda salvo, e na produção o esperado é que
-- ela ache 0: o prompt do app antigo só ficava em `ai_generate_jobs`, que o backend
-- apaga 30 minutos depois.
--
-- Marcas de origem que o schema tem (procuradas no catálogo, porque a produção pode
-- não ter alguma):
--   - `ai_generate_requests.materialized_deck_id` (069): o deck que o Generate novo
--     materializou no servidor;
--   - `activation_funnel_events.deck_id` num evento `deck_generated`: o coletor antigo
--     gravava o que o app mandava, e o evento podia levar o deck;
--   - uma coluna de origem em `decks` (origin, source, created_via, creation_source,
--     generated_by, generation_source, created_from ou origem): nenhuma existe no
--     schema nem na auditoria BT-DB-001 da produção; se aparecer, o script avisa e
--     não interpreta os valores.
-- O ledger da 067 (`deck_change_events`) não marca origem: ele só registra mudança de
-- um deck que já existe, e nenhuma operação dele é de criação.
-- O deck que o app antigo gerava e salvava pelo `POST /decks` não tem marca nenhuma.
--
-- Uso (sessão de leitura, depois da promoção):
--   server/bin/with_new_server_pg.sh --read-only psql -X -v ON_ERROR_STOP=1 \
--     -f server/sql/readonly/d85_1_generate_origin_count.sql
-- Saída: linhas `fase<TAB>objeto<TAB>quantidade` (fases marca, contagem e resultado).
-- O resultado diz qual é o caso:
--   - `sem_marca`: nenhuma marca no banco; a correção 1 é um no-op documentado;
--   - `com_marca_sem_deck`: há marca, mas nenhum deck veio do Generate por ela; também
--     no-op documentado;
--   - `com_marca`: N decks vieram do Generate (M com descrição); o dono decide com o
--     número;
--   - `coluna_de_origem_em_decks`: há coluna de origem em decks; conferir os valores
--     antes de decidir.

\set ON_ERROR_STOP on
\set QUIET on
\pset format unaligned
\pset tuples_only on
\pset footer off
\pset fieldsep '\t'

BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ READ ONLY;

SELECT
  EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'ai_generate_requests'
      AND column_name = 'materialized_deck_id'
  ) AS d118_tem_materializado,
  EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'activation_funnel_events'
      AND column_name = 'deck_id'
  ) AS d118_tem_evento,
  COALESCE(
    (
      SELECT string_agg(column_name::text, ',' ORDER BY column_name)
      FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'decks'
        AND column_name IN (
          'origin', 'source', 'created_via', 'creation_source', 'generated_by',
          'generation_source', 'created_from', 'origem'
        )
    ),
    ''
  ) AS d118_colunas_de_origem
\gset

-- Os IDs de deck de cada marca presente; sem marca, nenhum.
\set d118_fontes 'SELECT NULL::uuid WHERE FALSE'
\if :d118_tem_materializado
\set d118_fontes :d118_fontes ' UNION SELECT request.materialized_deck_id FROM public.ai_generate_requests request WHERE request.materialized_deck_id IS NOT NULL'
\endif
\if :d118_tem_evento
\set d118_fontes :d118_fontes ' UNION SELECT evento.deck_id FROM public.activation_funnel_events evento WHERE evento.event_name = ''deck_generated'' AND evento.deck_id IS NOT NULL'
\endif

SELECT 'marca' AS fase, 'ai_generate_requests.materialized_deck_id' AS objeto,
       CASE WHEN :'d118_tem_materializado' = 't' THEN 'presente' ELSE 'ausente' END
         AS quantidade;
SELECT 'marca' AS fase, 'activation_funnel_events.deck_id:deck_generated' AS objeto,
       CASE WHEN :'d118_tem_evento' = 't' THEN 'presente' ELSE 'ausente' END
         AS quantidade;
SELECT 'marca' AS fase, 'decks.coluna_de_origem' AS objeto,
       COALESCE(NULLIF(:'d118_colunas_de_origem', ''), 'ausente') AS quantidade;
SELECT 'marca' AS fase, 'deck_change_events' AS objeto,
       'sem_marca: o ledger da 067 só registra mudança de deck que já existe'
         AS quantidade;
SELECT 'marca' AS fase, 'deck_do_app_antigo' AS objeto,
       'sem_marca: o app antigo salvava pelo POST /decks, sem origem' AS quantidade;

\if :d118_tem_materializado
SELECT 'contagem' AS fase, 'decks_por_materialized_deck_id' AS objeto,
       COUNT(*)::text AS quantidade
FROM public.decks deck
WHERE deck.id IN (
  SELECT request.materialized_deck_id FROM public.ai_generate_requests request
);
\endif
\if :d118_tem_evento
SELECT 'contagem' AS fase, 'decks_por_evento_deck_generated' AS objeto,
       COUNT(*)::text AS quantidade
FROM public.decks deck
WHERE deck.id IN (
  SELECT evento.deck_id FROM public.activation_funnel_events evento
  WHERE evento.event_name = 'deck_generated'
);
\endif

SELECT 'contagem' AS fase, 'decks' AS objeto, COUNT(*)::text AS quantidade
FROM public.decks;
SELECT 'contagem' AS fase, 'decks_do_generate' AS objeto, COUNT(*)::text AS quantidade
FROM public.decks deck
WHERE deck.id IN (:d118_fontes);
SELECT 'contagem' AS fase, 'decks_do_generate_com_descricao' AS objeto,
       COUNT(*)::text AS quantidade
FROM public.decks deck
WHERE deck.id IN (:d118_fontes)
  AND NULLIF(btrim(deck.description), '') IS NOT NULL;
SELECT 'contagem' AS fase, 'decks_com_descricao_sem_marca' AS objeto,
       COUNT(*)::text AS quantidade
FROM public.decks deck
WHERE deck.id NOT IN (:d118_fontes)
  AND NULLIF(btrim(deck.description), '') IS NOT NULL;

SELECT 'resultado' AS fase, 'd85_1' AS objeto,
       CASE
         WHEN :'d118_colunas_de_origem' <> '' THEN
           'coluna_de_origem_em_decks: ' || :'d118_colunas_de_origem'
           || '; conferir os valores antes de decidir (D-118)'
         WHEN :'d118_tem_materializado' <> 't' AND :'d118_tem_evento' <> 't' THEN
           'sem_marca: nenhum deck do Generate é identificável; a correção 1 é um no-op documentado (D-118)'
         WHEN contagem.do_generate = 0 THEN
           'com_marca_sem_deck: nenhum deck veio do Generate pela marca; a correção 1 é um no-op documentado (D-118)'
         ELSE
           'com_marca: ' || contagem.do_generate || ' deck(s) vieram do Generate ('
           || contagem.com_descricao || ' com descrição); o dono decide com o número (D-118)'
       END AS quantidade
FROM (
  SELECT COUNT(*) AS do_generate,
         COUNT(*) FILTER (
           WHERE NULLIF(btrim(deck.description), '') IS NOT NULL
         ) AS com_descricao
  FROM public.decks deck
  WHERE deck.id IN (:d118_fontes)
) contagem;

ROLLBACK;
