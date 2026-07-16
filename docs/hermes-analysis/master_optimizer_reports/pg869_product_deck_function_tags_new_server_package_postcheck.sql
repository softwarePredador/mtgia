-- READ-ONLY.
WITH target AS (
  SELECT *
  FROM public.card_function_tags
  WHERE source = 'curated_product_deck_families_20260715'
)
SELECT
  count(*) AS persisted_tag_rows,
  count(DISTINCT card_id) AS tagged_card_rows,
  count(DISTINCT lower(card_name)) AS tagged_names,
  count(*) FILTER (WHERE confidence <> 0.95) AS confidence_mismatches,
  count(*) FILTER (WHERE tag NOT IN (
    'board_wipe','enabler','engine','etb','protection','ramp','removal','stax','wincon'
  )) AS unexpected_tags
FROM target;

SELECT lower(card_name) AS normalized_name, array_agg(DISTINCT tag ORDER BY tag) AS tags
FROM public.card_function_tags
WHERE source = 'curated_product_deck_families_20260715'
GROUP BY lower(card_name)
ORDER BY normalized_name;
