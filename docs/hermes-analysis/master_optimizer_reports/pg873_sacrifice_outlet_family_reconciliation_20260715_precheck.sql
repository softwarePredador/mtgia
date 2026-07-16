-- READ ONLY. PG873 sacrifice_outlet family reconciliation precheck.
\set ON_ERROR_STOP on
BEGIN TRANSACTION READ ONLY;
SET LOCAL statement_timeout = '3min';

WITH RECURSIVE
heuristic_owner AS (
  SELECT DISTINCT ON (lower(c.name))
    'deterministic_heuristic_v1'::text AS lane,
    c.id AS card_id,
    c.name,
    coalesce(c.oracle_text, '') AS oracle_text
  FROM public.cards c
  WHERE c.name IS NOT NULL
    AND c.name NOT LIKE 'A-%'
    AND c.name NOT LIKE '\_%' ESCAPE '\'
    AND c.name NOT LIKE '%World Champion%'
    AND c.name NOT LIKE '%Heroes of the Realm%'
  ORDER BY lower(c.name), c.set_code ASC NULLS LAST, c.id ASC
),
semantic_owner AS (
  SELECT
    'deterministic_semantic_v2'::text AS lane,
    c.id AS card_id,
    c.name,
    coalesce(c.oracle_text, '') AS oracle_text
  FROM public.cards c
  WHERE coalesce(c.type_line, '') <> ''
    AND coalesce(c.oracle_text, '') <> ''
),
owner_cards AS (
  SELECT * FROM heuristic_owner
  UNION ALL
  SELECT * FROM semantic_owner
),
unique_cards AS (
  SELECT DISTINCT ON (card_id) card_id, name, oracle_text
  FROM owner_cards
  ORDER BY card_id, lane
),
stripped_parenthetical(card_id, name, oracle_text, depth) AS (
  SELECT card_id, name, lower(oracle_text), 0
  FROM unique_cards
  UNION ALL
  SELECT
    card_id,
    name,
    regexp_replace(oracle_text, '\([^()]*\)', '', 'g'),
    depth + 1
  FROM stripped_parenthetical
  WHERE depth < 20
    AND oracle_text ~ '\([^()]*\)'
),
clean_cards AS (
  SELECT DISTINCT ON (card_id)
    card_id,
    name,
    regexp_replace(oracle_text, '\([^)]*$', '', 'g') AS oracle_text
  FROM stripped_parenthetical
  ORDER BY card_id, depth DESC
),
name_faces AS (
  SELECT
    c.card_id,
    regexp_replace(
      replace(replace(lower(trim(face)), '‘', ''''), '’', ''''),
      '\s+',
      ' ',
      'g'
    ) AS face
  FROM clean_cards c
  CROSS JOIN LATERAL regexp_split_to_table(c.name, '\s*//\s*') AS face
),
name_aliases AS (
  SELECT card_id, face AS self_name
  FROM name_faces
  WHERE face <> ''
  UNION
  SELECT
    card_id,
    CASE WHEN face LIKE 'a-%' THEN trim(substr(face, 3)) ELSE face END
  FROM name_faces
  WHERE face <> ''
  UNION
  SELECT
    card_id,
    trim(split_part(
      CASE WHEN face LIKE 'a-%' THEN trim(substr(face, 3)) ELSE face END,
      ',',
      1
    ))
  FROM name_faces
  WHERE strpos(CASE WHEN face LIKE 'a-%' THEN trim(substr(face, 3)) ELSE face END, ',') > 0
    AND length(trim(split_part(
      CASE WHEN face LIKE 'a-%' THEN trim(substr(face, 3)) ELSE face END,
      ',',
      1
    ))) >= 3
),
oracle_lines AS (
  SELECT
    c.card_id,
    line_no,
    line
  FROM clean_cards c
  CROSS JOIN LATERAL regexp_split_to_table(c.oracle_text, E'[\\r\\n]+')
    WITH ORDINALITY AS lines(line, line_no)
),
colon_segments AS (
  SELECT
    l.card_id,
    l.line_no,
    segment_no,
    regexp_replace(trim(segment), '\s+', ' ', 'g') AS cost_segment,
    count(*) OVER (PARTITION BY l.card_id, l.line_no) AS segment_count
  FROM oracle_lines l
  CROSS JOIN LATERAL regexp_split_to_table(l.line, ':')
    WITH ORDINALITY AS segments(segment, segment_no)
),
sacrifice_objects AS (
  SELECT
    s.card_id,
    trim(matches[1]) AS object_phrase
  FROM colon_segments s
  CROSS JOIN LATERAL regexp_matches(
    s.cost_segment,
    '\msacrifice\s+(.+)$',
    'g'
  ) AS matches
  WHERE s.segment_no < s.segment_count
),
expected_cards AS (
  SELECT DISTINCT o.card_id
  FROM sacrifice_objects o
  WHERE o.object_phrase ~ '^[a-z0-9~]'
    AND (
      o.object_phrase ~ '\mor\s+(another|other|an?|one|two|three|four|five|six|seven|eight|nine|ten|x|any|up to|all|half|[0-9]+)\M'
      OR (
        o.object_phrase !~ '^(this|it|that|itself|the source|~)(\M|$)'
        AND NOT EXISTS (
          SELECT 1
          FROM name_aliases a
          WHERE a.card_id = o.card_id
            AND (
              o.object_phrase = a.self_name
              OR left(o.object_phrase, length(a.self_name) + 1) = a.self_name || ','
              OR left(o.object_phrase, length(a.self_name) + 5) = a.self_name || ' and '
              OR left(o.object_phrase, length(a.self_name) + 4) = a.self_name || ' or '
            )
        )
      )
    )
),
expected AS (
  SELECT o.lane, o.card_id
  FROM owner_cards o
  JOIN expected_cards e USING (card_id)
),
current_function AS (
  SELECT source AS lane, card_id, evidence, confidence
  FROM public.card_function_tags
  WHERE tag = 'sacrifice_outlet'
    AND source IN ('deterministic_heuristic_v1', 'deterministic_semantic_v2')
),
current_json AS (
  SELECT
    s.card_id,
    count(*) FILTER (WHERE element->>'tag' = 'sacrifice_outlet') AS outlet_elements,
    max(element->>'evidence') FILTER (WHERE element->>'tag' = 'sacrifice_outlet') AS outlet_evidence
  FROM public.card_semantic_tags_v2 s
  CROSS JOIN LATERAL jsonb_array_elements(s.tags) AS element
  WHERE s.source = 'deterministic_semantic_v2'
    AND s.schema_version = 'semantic_layer_v2_2026_05_18'
  GROUP BY s.card_id
  HAVING count(*) FILTER (WHERE element->>'tag' = 'sacrifice_outlet') > 0
),
semantic_targets AS (
  SELECT card_id FROM expected WHERE lane = 'deterministic_semantic_v2'
  UNION
  SELECT card_id FROM current_json
),
missing_semantic AS (
  SELECT e.card_id
  FROM expected e
  LEFT JOIN public.card_semantic_tags_v2 s
    ON s.card_id = e.card_id
   AND s.source = 'deterministic_semantic_v2'
   AND s.schema_version = 'semantic_layer_v2_2026_05_18'
  WHERE e.lane = 'deterministic_semantic_v2'
    AND s.card_id IS NULL
),
metrics AS (
  SELECT
    (SELECT count(*) FROM heuristic_owner) AS heuristic_cards_scanned,
    (SELECT count(*) FROM semantic_owner) AS semantic_cards_scanned,
    (SELECT count(*) FROM expected WHERE lane = 'deterministic_heuristic_v1') AS heuristic_expected_count,
    (SELECT encode(digest(string_agg(card_id::text, E'\n' ORDER BY card_id::text), 'sha256'), 'hex') FROM expected WHERE lane = 'deterministic_heuristic_v1') AS heuristic_expected_sha256,
    (SELECT count(*) FROM expected WHERE lane = 'deterministic_semantic_v2') AS semantic_expected_count,
    (SELECT encode(digest(string_agg(card_id::text, E'\n' ORDER BY card_id::text), 'sha256'), 'hex') FROM expected WHERE lane = 'deterministic_semantic_v2') AS semantic_expected_sha256,
    (SELECT count(*) FROM current_function WHERE lane = 'deterministic_heuristic_v1') AS heuristic_current_count,
    (SELECT encode(digest(string_agg(card_id::text, E'\n' ORDER BY card_id::text), 'sha256'), 'hex') FROM current_function WHERE lane = 'deterministic_heuristic_v1') AS heuristic_current_sha256,
    (SELECT count(*) FROM current_function WHERE lane = 'deterministic_semantic_v2') AS semantic_function_current_count,
    (SELECT encode(digest(string_agg(card_id::text, E'\n' ORDER BY card_id::text), 'sha256'), 'hex') FROM current_function WHERE lane = 'deterministic_semantic_v2') AS semantic_function_current_sha256,
    (SELECT count(*) FROM current_json) AS semantic_json_current_count,
    (SELECT encode(digest(string_agg(card_id::text, E'\n' ORDER BY card_id::text), 'sha256'), 'hex') FROM current_json) AS semantic_json_current_sha256,
    (SELECT count(*) FROM semantic_targets) AS semantic_target_count,
    (SELECT count(*) FROM public.card_semantic_tags_v2 s JOIN semantic_targets t USING (card_id) WHERE s.source='deterministic_semantic_v2' AND s.schema_version='semantic_layer_v2_2026_05_18') AS semantic_snapshot_count,
    (SELECT count(*) FROM missing_semantic) AS expected_semantic_rows_missing,
    (SELECT encode(digest(string_agg(card_id::text, E'\n' ORDER BY card_id::text), 'sha256'), 'hex') FROM missing_semantic) AS missing_semantic_sha256,
    (SELECT count(*) FROM missing_semantic m JOIN public.card_semantic_tags_v2 s ON s.card_id=m.card_id AND s.source='deterministic_semantic_v2') AS semantic_source_conflicts,
    (SELECT count(*) FROM current_json WHERE outlet_elements <> 1) AS semantic_json_duplicate_rows,
    (SELECT count(*) FROM current_function f JOIN expected e USING (lane,card_id) WHERE f.evidence IS DISTINCT FROM 'external_activated_sacrifice_outlet_cost' OR f.confidence <> 0.8) AS retained_function_rows_wrong_payload,
    (SELECT count(*) FROM current_json j JOIN expected e ON e.lane='deterministic_semantic_v2' AND e.card_id=j.card_id WHERE j.outlet_evidence IS DISTINCT FROM 'external_activated_sacrifice_outlet_cost') AS retained_json_rows_wrong_evidence,
    (SELECT count(*) FROM public.card_semantic_tags_v2 s JOIN semantic_targets t USING (card_id) WHERE s.source='deterministic_semantic_v2' AND s.schema_version='semantic_layer_v2_2026_05_18' AND NOT EXISTS (SELECT 1 FROM expected e WHERE e.lane='deterministic_semantic_v2' AND e.card_id=s.card_id) AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(s.tags) x WHERE x->>'tag' <> 'sacrifice_outlet')) AS semantic_rows_deleted_if_not_expected,
    (SELECT count(*) FROM pg_extension WHERE extname = 'pgcrypto') AS pgcrypto_present
)
SELECT
  m.*,
  CASE
    WHEN heuristic_cards_scanned = 33841
     AND semantic_cards_scanned = 33972
     AND heuristic_expected_count = 716
     AND heuristic_expected_sha256 = '51272701cdb5b277a2007de43c418c418fab5380409fc16c08ac527fd1ddacbd'
     AND semantic_expected_count = 736
     AND semantic_expected_sha256 = '512cb67eca26b4c86d4555fcf14cae19e6e9f0a9bd24239db0d4cc6caa49418c'
     AND heuristic_current_count = 1357
     AND heuristic_current_sha256 = '5986c9df6c911b8c8aa24744ccc57c2e93e9d3421b716b7c302f95192f17d046'
     AND semantic_function_current_count = 1380
     AND semantic_function_current_sha256 = 'cdc90bbc3d1b55b42050081cb6c1352937a3df4a2187ea0e34434270a3695d7e'
     AND semantic_json_current_count = 1380
     AND semantic_json_current_sha256 = 'cdc90bbc3d1b55b42050081cb6c1352937a3df4a2187ea0e34434270a3695d7e'
     AND semantic_target_count = 1609
     AND semantic_snapshot_count = 1557
     AND expected_semantic_rows_missing = 52
     AND missing_semantic_sha256 = '4f29cbcbbdaa9a10bf285ff808c40ab8f3026367a2b3bc873fd51424cad5b199'
     AND semantic_source_conflicts = 0
     AND semantic_json_duplicate_rows = 0
     AND retained_function_rows_wrong_payload = 998
     AND retained_json_rows_wrong_evidence = 507
     AND semantic_rows_deleted_if_not_expected = 33
     AND pgcrypto_present = 1
     AND to_regclass('manaloom_deploy_audit.pg873_sac_outlet_expected_20260715') IS NULL
     AND to_regclass('manaloom_deploy_audit.pg873_sac_outlet_function_backup_20260715') IS NULL
     AND to_regclass('manaloom_deploy_audit.pg873_sac_outlet_semantic_backup_20260715') IS NULL
     AND to_regclass('manaloom_deploy_audit.pg873_sac_outlet_missing_semantic_20260715') IS NULL
     AND to_regclass('manaloom_deploy_audit.pg873_sac_outlet_post_semantic_20260715') IS NULL
    THEN 'ok'
    ELSE ('PG873_PRECHECK_ABORT_' || heuristic_expected_count::text)::integer::text
  END AS guard
FROM metrics m;

ROLLBACK;
