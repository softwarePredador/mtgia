-- BT-DB-005: contagem, SÓ LEITURA, das linhas que três CHECK do banco novo
-- recusariam na produção, que não tem essas travas (ensaio na estrutura do dump
-- de 2026-09-23: docs/qa/execution/2026-09-28/BT-DB-003-ensaio-na-estrutura-da-producao.md).
--
-- A coordenação roda na produção, pelo wrapper em modo leitura:
--   server/bin/with_new_server_pg.sh --read-only psql -X -v ON_ERROR_STOP=1 \
--     -A -F $'\t' -f server/sql/readonly/bt_db_005_check_violations.sql
-- Só contagens, nenhuma linha. A transação é READ ONLY e termina em ROLLBACK.
-- Com zero, a trava entra como NOT VALID e é validada, com a palavra do dono
-- (como a D-50); com mais de zero, o dado é tratado antes.

BEGIN TRANSACTION READ ONLY;

SELECT 'transaction_read_only' AS restricao,
       current_setting('transaction_read_only') AS violacoes,
       NULL::bigint AS linhas;

SELECT 'ml_prompt_feedback.chk_ml_prompt_feedback_effectiveness_score' AS restricao,
       COUNT(*) FILTER (
         WHERE (
           effectiveness_score IS NULL
           OR (effectiveness_score >= 1 AND effectiveness_score <= 10)
         ) IS FALSE
       )::text AS violacoes,
       COUNT(*) AS linhas
FROM public.ml_prompt_feedback;

SELECT 'notifications.notifications_type_check' AS restricao,
       COUNT(*) FILTER (
         WHERE (type IN (
           'new_follower', 'trade_offer_received', 'trade_accepted',
           'trade_declined', 'trade_shipped', 'trade_delivered',
           'trade_completed', 'trade_message', 'direct_message'
         )) IS FALSE
       )::text AS violacoes,
       COUNT(*) AS linhas
FROM public.notifications;

SELECT 'user_binder_items.user_binder_items_currency_check' AS restricao,
       COUNT(*) FILTER (WHERE (currency IN ('BRL', 'USD')) IS FALSE)::text AS violacoes,
       COUNT(*) AS linhas
FROM public.user_binder_items;

ROLLBACK;
