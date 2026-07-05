-- Lorehold external identity cache postcheck.
-- Expected after apply: resolved_cache_rows = 6.
SELECT COUNT(*) AS resolved_cache_rows
FROM card_oracle_cache
WHERE normalized_name IN ('brain in a jar', 'entreat the angels', 'haze of rage', 'late to dinner', 'miraculous recovery', 'strata scythe')
  AND source = 'lorehold_external_identity_resolution_queue_20260705_current';

SELECT coc.normalized_name, coc.name, coc.card_id, coc.color_identity_json, cl.status AS commander_status
FROM card_oracle_cache coc
LEFT JOIN card_legalities cl
  ON lower(cl.card_name) = lower(coc.name)
 AND cl.format = 'commander'
WHERE coc.normalized_name IN ('brain in a jar', 'entreat the angels', 'haze of rage', 'late to dinner', 'miraculous recovery', 'strata scythe')
ORDER BY coc.normalized_name;
