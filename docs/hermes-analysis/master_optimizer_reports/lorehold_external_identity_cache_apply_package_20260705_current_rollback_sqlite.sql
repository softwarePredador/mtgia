-- Lorehold external identity cache rollback.
-- Deletes only rows inserted/updated by this package source marker.
DELETE FROM card_oracle_cache
WHERE normalized_name IN ('brain in a jar', 'entreat the angels', 'haze of rage', 'late to dinner', 'miraculous recovery', 'strata scythe')
  AND source = 'lorehold_external_identity_resolution_queue_20260705_current';

SELECT COUNT(*) AS remaining_package_cache_rows
FROM card_oracle_cache
WHERE normalized_name IN ('brain in a jar', 'entreat the angels', 'haze of rage', 'late to dinner', 'miraculous recovery', 'strata scythe')
  AND source = 'lorehold_external_identity_resolution_queue_20260705_current';
