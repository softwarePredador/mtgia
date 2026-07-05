-- Lorehold external identity cache precheck.
-- Expected before apply: existing_cache_rows = 0 for this package.
SELECT COUNT(*) AS existing_cache_rows
FROM card_oracle_cache
WHERE normalized_name IN ('brain in a jar', 'entreat the angels', 'haze of rage', 'late to dinner', 'miraculous recovery', 'strata scythe');

SELECT normalized_name, name, source, updated_at
FROM card_oracle_cache
WHERE normalized_name IN ('brain in a jar', 'entreat the angels', 'haze of rage', 'late to dinner', 'miraculous recovery', 'strata scythe')
ORDER BY normalized_name;
