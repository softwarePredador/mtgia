-- PG780B trusted oracle_hash backfill apply.
-- Target: new-server PostgreSQL via server/bin/with_new_server_pg.sh.

BEGIN;

CREATE TABLE IF NOT EXISTS public.card_battle_rules_backup_pg780b_hash_new_server
(LIKE public.card_battle_rules INCLUDING ALL);

WITH target AS (
  SELECT br.*
  FROM public.card_battle_rules br
  JOIN public.cards c ON c.id = br.card_id
  WHERE br.source = 'curated'
    AND br.review_status IN ('verified', 'active')
    AND br.execution_status = 'auto'
    AND COALESCE(br.oracle_hash, '') = ''
    AND COALESCE(c.oracle_text, '') <> ''
),
backed AS (
  INSERT INTO public.card_battle_rules_backup_pg780b_hash_new_server
  SELECT * FROM target
  ON CONFLICT DO NOTHING
  RETURNING 1
),
updated AS (
  UPDATE public.card_battle_rules br
  SET oracle_hash = md5(c.oracle_text),
      notes = concat_ws(
        E'\n',
        NULLIF(br.notes, ''),
        'PG780B trusted oracle_hash backfill from cards.oracle_text on 2026-07-11.'
      ),
      updated_at = NOW()
  FROM public.cards c
  WHERE c.id = br.card_id
    AND br.source = 'curated'
    AND br.review_status IN ('verified', 'active')
    AND br.execution_status = 'auto'
    AND COALESCE(br.oracle_hash, '') = ''
    AND COALESCE(c.oracle_text, '') <> ''
  RETURNING 1
)
SELECT
  (SELECT COUNT(*) FROM target) AS target_rows,
  (SELECT COUNT(*) FROM backed) AS backed_rows,
  (SELECT COUNT(*) FROM updated) AS updated_rows;

COMMIT;
