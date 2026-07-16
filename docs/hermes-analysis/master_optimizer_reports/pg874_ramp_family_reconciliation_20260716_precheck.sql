-- READ ONLY. PG874 exact ramp false-positive reconciliation precheck.
-- Scope: lands, land-search-to-hand without independent acceleration, and one
-- current Oracle-face drift row. No missing legitimate ramp rows are inserted.

BEGIN TRANSACTION READ ONLY;

WITH card_text AS (
  SELECT
    c.id AS card_id,
    c.name,
    lower(coalesce(c.type_line, '')) AS type_line,
    lower(coalesce(c.oracle_text, '')) AS oracle,
    substring(
      lower(coalesce(c.oracle_text, ''))
      FROM position(
        'search your library' IN lower(coalesce(c.oracle_text, ''))
      )
    ) AS after_search
  FROM public.cards c
), classified AS (
  SELECT
    *,
    type_line ~ '(^|[^a-z])land([^a-z]|$)' AS is_land,
    position('search your library' IN oracle) > 0
      AND (
        oracle LIKE '%land card%' OR oracle LIKE '%basic land%'
        OR oracle LIKE '%forest card%' OR oracle LIKE '%plains card%'
        OR oracle LIKE '%island card%' OR oracle LIKE '%swamp card%'
        OR oracle LIKE '%mountain card%'
      )
      AND position(
        'onto the battlefield' IN split_part(after_search, E'\n', 1)
      ) = 0
      AND oracle NOT LIKE '%add {%'
      AND oracle NOT LIKE '%mana of any%'
      AND oracle NOT LIKE '%additional land this turn%'
      AND oracle NOT LIKE '%additional land on each of your turns%'
      AND NOT (
        oracle LIKE '%spells you cast cost%' AND oracle LIKE '%less to cast%'
      )
      AND NOT (oracle LIKE '%untap up to%' AND oracle LIKE '%lands%')
      AND NOT (
        oracle LIKE '%taps an island for mana%'
        AND oracle LIKE '%adds an additional%'
      )
      AND oracle NOT LIKE '%put a land card from your hand onto the battlefield%'
      AND NOT (oracle LIKE '%put up to%' AND oracle LIKE '%land cards%')
      AND oracle NOT LIKE '%create a treasure token%'
      AND oracle NOT LIKE '%create two treasure tokens%'
      AND oracle NOT LIKE '%create three treasure tokens%'
      AND lower(trim(name)) NOT LIKE '%signet%'
      AND lower(trim(name)) NOT LIKE '%talisman%'
      AND lower(trim(name)) NOT IN ('sol ring', 'arcane signet')
      AS hand_only_land_search
  FROM card_text
), predicate_cards AS (
  SELECT
    card_id,
    name,
    type_line,
    CASE
      WHEN is_land THEN 'land_structural_not_generic_ramp'
      WHEN hand_only_land_search THEN 'land_search_without_battlefield_acceleration'
      ELSE 'oracle_face_drift_no_mana_text'
    END AS classification
  FROM classified
  WHERE is_land
     OR hand_only_land_search
     OR name = 'Ashling, Rekindled // Ashling, Rimebound'
), target_cards AS (
  SELECT p.*
  FROM predicate_cards p
  WHERE EXISTS (
    SELECT 1 FROM public.card_function_tags f
    WHERE f.card_id=p.card_id AND f.tag='ramp'
      AND f.source IN ('deterministic_heuristic_v1','deterministic_semantic_v2')
  ) OR EXISTS (
    SELECT 1 FROM public.card_role_scores r
    WHERE r.card_id=p.card_id AND r.role='ramp'
      AND r.source='deterministic_heuristic_v1'
  ) OR EXISTS (
    SELECT 1 FROM public.card_semantic_tags_v2 s
    WHERE s.card_id=p.card_id AND s.source='deterministic_semantic_v2'
      AND s.schema_version='semantic_layer_v2_2026_05_18'
      AND s.tags @> '[{"tag":"ramp"}]'::jsonb
  )
), heuristic_rows AS (
  SELECT f.card_id FROM public.card_function_tags f
  JOIN target_cards t USING (card_id)
  WHERE f.tag='ramp' AND f.source='deterministic_heuristic_v1'
), semantic_rows AS (
  SELECT f.card_id FROM public.card_function_tags f
  JOIN target_cards t USING (card_id)
  WHERE f.tag='ramp' AND f.source='deterministic_semantic_v2'
), role_rows AS (
  SELECT r.card_id,r.format,r.subformat,r.bracket_scope,r.budget_tier
  FROM public.card_role_scores r JOIN target_cards t USING (card_id)
  WHERE r.role='ramp' AND r.source='deterministic_heuristic_v1'
), json_rows AS (
  SELECT s.card_id,s.tags FROM public.card_semantic_tags_v2 s
  JOIN target_cards t USING (card_id)
  WHERE s.source='deterministic_semantic_v2'
    AND s.schema_version='semantic_layer_v2_2026_05_18'
    AND s.tags @> '[{"tag":"ramp"}]'::jsonb
)
SELECT
  (SELECT count(*) FROM target_cards) AS target_card_count,
  (SELECT encode(digest(string_agg(card_id::text,E'\n' ORDER BY card_id::text),'sha256'),'hex') FROM target_cards) AS target_card_sha256,
  (SELECT count(*) FROM heuristic_rows) AS heuristic_function_rows,
  (SELECT encode(digest(string_agg(card_id::text,E'\n' ORDER BY card_id::text),'sha256'),'hex') FROM heuristic_rows) AS heuristic_function_sha256,
  (SELECT count(*) FROM role_rows) AS heuristic_role_rows,
  (SELECT encode(digest(string_agg(card_id::text||'|'||format||'|'||subformat||'|'||bracket_scope||'|'||budget_tier,E'\n' ORDER BY card_id::text||'|'||format||'|'||subformat||'|'||bracket_scope||'|'||budget_tier),'sha256'),'hex') FROM role_rows) AS heuristic_role_sha256,
  (SELECT count(*) FROM semantic_rows) AS semantic_function_rows,
  (SELECT encode(digest(string_agg(card_id::text,E'\n' ORDER BY card_id::text),'sha256'),'hex') FROM semantic_rows) AS semantic_function_sha256,
  (SELECT count(*) FROM json_rows) AS semantic_json_rows,
  (SELECT encode(digest(string_agg(card_id::text,E'\n' ORDER BY card_id::text),'sha256'),'hex') FROM json_rows) AS semantic_json_sha256,
  (SELECT count(*) FROM json_rows WHERE jsonb_array_length(tags)=1) AS semantic_rows_becoming_empty,
  (SELECT count(*) FROM target_cards WHERE classification='land_structural_not_generic_ramp') AS land_target_cards,
  (SELECT count(*) FROM target_cards WHERE classification='land_search_without_battlefield_acceleration') AS land_search_to_hand_target_cards,
  (SELECT count(*) FROM target_cards WHERE classification='oracle_face_drift_no_mana_text') AS oracle_drift_target_cards;

WITH card_text AS (
  SELECT c.id card_id,c.name,lower(coalesce(c.type_line,'')) type_line,
    lower(coalesce(c.oracle_text,'')) oracle,
    substring(lower(coalesce(c.oracle_text,'')) FROM position('search your library' IN lower(coalesce(c.oracle_text,'')))) after_search
  FROM public.cards c
), classified AS (
  SELECT *,type_line ~ '(^|[^a-z])land([^a-z]|$)' is_land,
    position('search your library' IN oracle)>0
    AND (oracle LIKE '%land card%' OR oracle LIKE '%basic land%' OR oracle LIKE '%forest card%' OR oracle LIKE '%plains card%' OR oracle LIKE '%island card%' OR oracle LIKE '%swamp card%' OR oracle LIKE '%mountain card%')
    AND position('onto the battlefield' IN split_part(after_search,E'\n',1))=0
    AND oracle NOT LIKE '%add {%' AND oracle NOT LIKE '%mana of any%'
    AND oracle NOT LIKE '%additional land this turn%' AND oracle NOT LIKE '%additional land on each of your turns%'
    AND NOT(oracle LIKE '%spells you cast cost%' AND oracle LIKE '%less to cast%')
    AND NOT(oracle LIKE '%untap up to%' AND oracle LIKE '%lands%')
    AND NOT(oracle LIKE '%taps an island for mana%' AND oracle LIKE '%adds an additional%')
    AND oracle NOT LIKE '%put a land card from your hand onto the battlefield%'
    AND NOT(oracle LIKE '%put up to%' AND oracle LIKE '%land cards%')
    AND oracle NOT LIKE '%create a treasure token%' AND oracle NOT LIKE '%create two treasure tokens%' AND oracle NOT LIKE '%create three treasure tokens%'
    AND lower(trim(name)) NOT LIKE '%signet%' AND lower(trim(name)) NOT LIKE '%talisman%' AND lower(trim(name)) NOT IN('sol ring','arcane signet') hand_only_land_search
  FROM card_text
), predicate_cards AS (
  SELECT card_id,name,type_line,CASE WHEN is_land THEN 'land_structural_not_generic_ramp' WHEN hand_only_land_search THEN 'land_search_without_battlefield_acceleration' ELSE 'oracle_face_drift_no_mana_text' END classification
  FROM classified WHERE is_land OR hand_only_land_search OR name='Ashling, Rekindled // Ashling, Rimebound'
), target_cards AS (
  SELECT p.* FROM predicate_cards p WHERE
    EXISTS(SELECT 1 FROM public.card_function_tags f WHERE f.card_id=p.card_id AND f.tag='ramp' AND f.source IN('deterministic_heuristic_v1','deterministic_semantic_v2'))
    OR EXISTS(SELECT 1 FROM public.card_role_scores r WHERE r.card_id=p.card_id AND r.role='ramp' AND r.source='deterministic_heuristic_v1')
    OR EXISTS(SELECT 1 FROM public.card_semantic_tags_v2 s WHERE s.card_id=p.card_id AND s.source='deterministic_semantic_v2' AND s.schema_version='semantic_layer_v2_2026_05_18' AND s.tags @> '[{"tag":"ramp"}]'::jsonb)
), h AS (SELECT f.card_id FROM public.card_function_tags f JOIN target_cards t USING(card_id) WHERE f.tag='ramp' AND f.source='deterministic_heuristic_v1'),
s AS (SELECT f.card_id FROM public.card_function_tags f JOIN target_cards t USING(card_id) WHERE f.tag='ramp' AND f.source='deterministic_semantic_v2'),
r AS (SELECT x.card_id,x.format,x.subformat,x.bracket_scope,x.budget_tier FROM public.card_role_scores x JOIN target_cards t USING(card_id) WHERE x.role='ramp' AND x.source='deterministic_heuristic_v1'),
j AS (SELECT x.card_id,x.tags FROM public.card_semantic_tags_v2 x JOIN target_cards t USING(card_id) WHERE x.source='deterministic_semantic_v2' AND x.schema_version='semantic_layer_v2_2026_05_18' AND x.tags @> '[{"tag":"ramp"}]'::jsonb),
metrics AS (
  SELECT
    (SELECT count(*) FROM target_cards) tc,
    (SELECT encode(digest(string_agg(card_id::text,E'\n' ORDER BY card_id::text),'sha256'),'hex') FROM target_cards) tsha,
    (SELECT count(*) FROM h) hc,
    (SELECT encode(digest(string_agg(card_id::text,E'\n' ORDER BY card_id::text),'sha256'),'hex') FROM h) hsha,
    (SELECT count(*) FROM r) rc,
    (SELECT encode(digest(string_agg(card_id::text||'|'||format||'|'||subformat||'|'||bracket_scope||'|'||budget_tier,E'\n' ORDER BY card_id::text||'|'||format||'|'||subformat||'|'||bracket_scope||'|'||budget_tier),'sha256'),'hex') FROM r) rsha,
    (SELECT count(*) FROM s) sc,
    (SELECT encode(digest(string_agg(card_id::text,E'\n' ORDER BY card_id::text),'sha256'),'hex') FROM s) ssha,
    (SELECT count(*) FROM j) jc,
    (SELECT encode(digest(string_agg(card_id::text,E'\n' ORDER BY card_id::text),'sha256'),'hex') FROM j) jsha,
    (SELECT count(*) FROM j WHERE jsonb_array_length(tags)=1) emptyc
)
SELECT CASE WHEN
  tc=1377 AND tsha='cebc65973dfb91315dae85510be400b2ed6bcad5e8cff765c5a2ed6db5b51123'
  AND hc=1302 AND hsha='c583f582b7b39b47615fc695a79f6da8fce5074ed6b0c171b76a6ce73325d47b'
  AND rc=1322 AND rsha='822706ddc3aa49c081a17106d7ca229f8eba53cbee4342f649e7ee0a84a554c3'
  AND sc=1350 AND ssha='410258d08c2e41da90d8c8b14862c3a6f0986727c193dc6b61f4996615397e6f'
  AND jc=1350 AND jsha='410258d08c2e41da90d8c8b14862c3a6f0986727c193dc6b61f4996615397e6f'
  AND emptyc=1
  AND to_regclass('manaloom_deploy_audit.pg874_ramp_target_20260716') IS NULL
  AND to_regclass('manaloom_deploy_audit.pg874_ramp_function_backup_20260716') IS NULL
  AND to_regclass('manaloom_deploy_audit.pg874_ramp_role_backup_20260716') IS NULL
  AND to_regclass('manaloom_deploy_audit.pg874_ramp_semantic_backup_20260716') IS NULL
  AND to_regclass('manaloom_deploy_audit.pg874_ramp_post_semantic_20260716') IS NULL
THEN 'PG874_PRECHECK_PASS'
ELSE ('PG874_PRECHECK_ABORT_'||tc::text)::integer::text END AS status
FROM metrics;

WITH sample AS (
  SELECT c.name,c.type_line
  FROM public.cards c
  WHERE c.id IN (
    SELECT f.card_id FROM public.card_function_tags f
    WHERE f.tag='ramp' AND f.source='deterministic_heuristic_v1'
  )
  AND (
    lower(coalesce(c.type_line,'')) ~ '(^|[^a-z])land([^a-z]|$)'
    OR c.name IN ('Armillary Sphere','Environmental Scientist','Ashling, Rekindled // Ashling, Rimebound')
  )
  ORDER BY c.name LIMIT 30
)
SELECT * FROM sample;

ROLLBACK;
