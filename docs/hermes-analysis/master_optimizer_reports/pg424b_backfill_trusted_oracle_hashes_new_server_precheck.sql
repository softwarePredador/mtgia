SELECT
  count(*) FILTER (
    WHERE c.id IS NOT NULL
      AND coalesce(c.oracle_text, '') <> ''
  ) AS backfillable_rows,
  count(*) AS missing_oracle_hash_rows
FROM public.card_battle_rules r
LEFT JOIN public.cards c
  ON c.id = r.card_id
WHERE r.source = 'curated'
  AND r.review_status IN ('verified', 'active')
  AND r.execution_status = 'auto'
  AND coalesce(r.oracle_hash, '') = '';
