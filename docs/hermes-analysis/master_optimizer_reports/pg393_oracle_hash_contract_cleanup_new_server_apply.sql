BEGIN;

CREATE TABLE IF NOT EXISTS public.card_battle_rules_pg393_oracle_hash_backfill_backup AS
SELECT *
FROM public.card_battle_rules
WHERE false;

WITH target(normalized_name, logical_rule_key) AS (
  VALUES
    ('angel''s grace', 'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227'),
    ('seething song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7')
)
INSERT INTO public.card_battle_rules_pg393_oracle_hash_backfill_backup
SELECT r.*
FROM public.card_battle_rules r
JOIN target t
  ON t.normalized_name = r.normalized_name
 AND t.logical_rule_key = r.logical_rule_key
WHERE NOT EXISTS (
  SELECT 1
  FROM public.card_battle_rules_pg393_oracle_hash_backfill_backup b
  WHERE b.normalized_name = r.normalized_name
    AND b.logical_rule_key = r.logical_rule_key
);

WITH target(normalized_name, logical_rule_key) AS (
  VALUES
    ('angel''s grace', 'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227'),
    ('seething song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7')
),
card_hash AS (
  SELECT lower(name) AS normalized_name, md5(coalesce(oracle_text, '')) AS oracle_hash
  FROM public.cards
  WHERE lower(name) IN (SELECT normalized_name FROM target)
),
updated AS (
  UPDATE public.card_battle_rules r
     SET oracle_hash = ch.oracle_hash,
         notes = concat_ws(E'\n', nullif(r.notes, ''), 'PG393 contract cleanup: oracle_hash backfilled from public.cards.oracle_text md5 on new server.'),
         updated_at = now()
  FROM target t
  JOIN card_hash ch
    ON ch.normalized_name = t.normalized_name
  WHERE r.normalized_name = t.normalized_name
    AND r.logical_rule_key = t.logical_rule_key
    AND r.review_status = 'verified'
    AND r.execution_status = 'auto'
    AND r.source = 'curated'
    AND coalesce(r.oracle_hash, '') = ''
  RETURNING r.card_name, r.normalized_name, r.logical_rule_key, r.oracle_hash
)
SELECT count(*) AS backfilled_oracle_hash_rows
FROM updated;

COMMIT;
