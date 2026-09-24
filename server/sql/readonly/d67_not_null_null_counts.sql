-- D-67 (BT-DB-004): contagem de nulos, SÓ LEITURA, nas 26 colunas que são NOT NULL
-- na migration e aceitam nulo na produção (auditoria BT-DB-001,
-- docs/qa/execution/2026-09-23/BT-DB-001-auditoria-de-schema.saida.json).
--
-- A coordenação roda na produção, pelo wrapper em modo leitura:
--   server/bin/with_new_server_pg.sh --read-only psql -X -v ON_ERROR_STOP=1 \
--     -A -F $'\t' -f server/sql/readonly/d67_not_null_null_counts.sql
-- A transação é READ ONLY e termina em ROLLBACK. Onde houver nulo, o dado é
-- corrigido antes de apertar a coluna, com a palavra do dono (D-67).

BEGIN TRANSACTION READ ONLY;

SELECT 'transaction_read_only' AS tabela,
       current_setting('transaction_read_only') AS coluna,
       NULL::bigint AS nulos,
       NULL::bigint AS linhas;

SELECT 'card_meta_insights' AS tabela, v.coluna, v.nulos, s.linhas
FROM (
  SELECT COUNT(*) AS linhas,
         COUNT(*) FILTER (WHERE common_archetypes IS NULL) AS common_archetypes,
         COUNT(*) FILTER (WHERE common_formats IS NULL) AS common_formats,
         COUNT(*) FILTER (WHERE last_updated_at IS NULL) AS last_updated_at,
         COUNT(*) FILTER (WHERE meta_deck_count IS NULL) AS meta_deck_count,
         COUNT(*) FILTER (WHERE top_pairs IS NULL) AS top_pairs,
         COUNT(*) FILTER (WHERE usage_count IS NULL) AS usage_count,
         COUNT(*) FILTER (WHERE versatility_score IS NULL) AS versatility_score
  FROM public.card_meta_insights
) s
CROSS JOIN LATERAL (VALUES
  ('common_archetypes', s.common_archetypes),
  ('common_formats', s.common_formats),
  ('last_updated_at', s.last_updated_at),
  ('meta_deck_count', s.meta_deck_count),
  ('top_pairs', s.top_pairs),
  ('usage_count', s.usage_count),
  ('versatility_score', s.versatility_score)
) AS v(coluna, nulos)
ORDER BY v.coluna;

SELECT 'conversations' AS tabela, v.coluna, v.nulos, s.linhas
FROM (
  SELECT COUNT(*) AS linhas,
         COUNT(*) FILTER (WHERE created_at IS NULL) AS created_at
  FROM public.conversations
) s
CROSS JOIN LATERAL (VALUES
  ('created_at', s.created_at)
) AS v(coluna, nulos)
ORDER BY v.coluna;

SELECT 'direct_messages' AS tabela, v.coluna, v.nulos, s.linhas
FROM (
  SELECT COUNT(*) AS linhas,
         COUNT(*) FILTER (WHERE created_at IS NULL) AS created_at
  FROM public.direct_messages
) s
CROSS JOIN LATERAL (VALUES
  ('created_at', s.created_at)
) AS v(coluna, nulos)
ORDER BY v.coluna;

SELECT 'ml_prompt_feedback' AS tabela, v.coluna, v.nulos, s.linhas
FROM (
  SELECT COUNT(*) AS linhas,
         COUNT(*) FILTER (WHERE archetype IS NULL) AS archetype,
         COUNT(*) FILTER (WHERE cards_accepted IS NULL) AS cards_accepted,
         COUNT(*) FILTER (WHERE cards_rejected IS NULL) AS cards_rejected,
         COUNT(*) FILTER (WHERE prompt_version IS NULL) AS prompt_version
  FROM public.ml_prompt_feedback
) s
CROSS JOIN LATERAL (VALUES
  ('archetype', s.archetype),
  ('cards_accepted', s.cards_accepted),
  ('cards_rejected', s.cards_rejected),
  ('prompt_version', s.prompt_version)
) AS v(coluna, nulos)
ORDER BY v.coluna;

SELECT 'notifications' AS tabela, v.coluna, v.nulos, s.linhas
FROM (
  SELECT COUNT(*) AS linhas,
         COUNT(*) FILTER (WHERE created_at IS NULL) AS created_at
  FROM public.notifications
) s
CROSS JOIN LATERAL (VALUES
  ('created_at', s.created_at)
) AS v(coluna, nulos)
ORDER BY v.coluna;

SELECT 'trade_messages' AS tabela, v.coluna, v.nulos, s.linhas
FROM (
  SELECT COUNT(*) AS linhas,
         COUNT(*) FILTER (WHERE created_at IS NULL) AS created_at
  FROM public.trade_messages
) s
CROSS JOIN LATERAL (VALUES
  ('created_at', s.created_at)
) AS v(coluna, nulos)
ORDER BY v.coluna;

SELECT 'trade_offers' AS tabela, v.coluna, v.nulos, s.linhas
FROM (
  SELECT COUNT(*) AS linhas,
         COUNT(*) FILTER (WHERE created_at IS NULL) AS created_at,
         COUNT(*) FILTER (WHERE payment_currency IS NULL) AS payment_currency,
         COUNT(*) FILTER (WHERE updated_at IS NULL) AS updated_at
  FROM public.trade_offers
) s
CROSS JOIN LATERAL (VALUES
  ('created_at', s.created_at),
  ('payment_currency', s.payment_currency),
  ('updated_at', s.updated_at)
) AS v(coluna, nulos)
ORDER BY v.coluna;

SELECT 'trade_status_history' AS tabela, v.coluna, v.nulos, s.linhas
FROM (
  SELECT COUNT(*) AS linhas,
         COUNT(*) FILTER (WHERE created_at IS NULL) AS created_at
  FROM public.trade_status_history
) s
CROSS JOIN LATERAL (VALUES
  ('created_at', s.created_at)
) AS v(coluna, nulos)
ORDER BY v.coluna;

SELECT 'user_binder_items' AS tabela, v.coluna, v.nulos, s.linhas
FROM (
  SELECT COUNT(*) AS linhas,
         COUNT(*) FILTER (WHERE created_at IS NULL) AS created_at,
         COUNT(*) FILTER (WHERE currency IS NULL) AS currency,
         COUNT(*) FILTER (WHERE for_sale IS NULL) AS for_sale,
         COUNT(*) FILTER (WHERE for_trade IS NULL) AS for_trade,
         COUNT(*) FILTER (WHERE is_foil IS NULL) AS is_foil,
         COUNT(*) FILTER (WHERE language IS NULL) AS language,
         COUNT(*) FILTER (WHERE updated_at IS NULL) AS updated_at
  FROM public.user_binder_items
) s
CROSS JOIN LATERAL (VALUES
  ('created_at', s.created_at),
  ('currency', s.currency),
  ('for_sale', s.for_sale),
  ('for_trade', s.for_trade),
  ('is_foil', s.is_foil),
  ('language', s.language),
  ('updated_at', s.updated_at)
) AS v(coluna, nulos)
ORDER BY v.coluna;

ROLLBACK;
