-- READ ONLY. Run after the approved PG873 apply.
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
global_expected AS (
  SELECT o.lane, o.card_id
  FROM owner_cards o
  JOIN expected_cards e USING (card_id)
),
semantic_snapshot_owners AS (
  SELECT s.card_id
  FROM public.card_semantic_tags_v2 s
  WHERE s.source = 'deterministic_semantic_v2'
    AND s.schema_version = 'semantic_layer_v2_2026_05_18'
),
expected AS (
  SELECT e.lane, e.card_id
  FROM global_expected e
  WHERE e.lane = 'deterministic_heuristic_v1'
     OR EXISTS (
       SELECT 1 FROM semantic_snapshot_owners s WHERE s.card_id = e.card_id
     )
),
deferred_missing_semantic AS (
  SELECT e.card_id
  FROM global_expected e
  LEFT JOIN semantic_snapshot_owners s ON s.card_id = e.card_id
  WHERE e.lane = 'deterministic_semantic_v2'
    AND s.card_id IS NULL
),
current_function AS (
  SELECT source AS lane, card_id, confidence, evidence
  FROM public.card_function_tags
  WHERE tag = 'sacrifice_outlet'
    AND source IN ('deterministic_heuristic_v1', 'deterministic_semantic_v2')
),
current_json AS (
  SELECT
    s.card_id,
    count(*) FILTER (WHERE element->>'tag' = 'sacrifice_outlet') AS outlet_elements,
    max((element->>'confidence')::numeric) FILTER (WHERE element->>'tag' = 'sacrifice_outlet') AS outlet_confidence,
    max(element->>'evidence') FILTER (WHERE element->>'tag' = 'sacrifice_outlet') AS outlet_evidence
  FROM public.card_semantic_tags_v2 s
  CROSS JOIN LATERAL jsonb_array_elements(s.tags) element
  WHERE s.source = 'deterministic_semantic_v2'
    AND s.schema_version = 'semantic_layer_v2_2026_05_18'
  GROUP BY s.card_id
  HAVING count(*) FILTER (WHERE element->>'tag' = 'sacrifice_outlet') > 0
),
post_diff AS (
  SELECT * FROM (
    SELECT s.*
    FROM public.card_semantic_tags_v2 s
    JOIN manaloom_deploy_audit.pg873_sac_outlet_post_semantic_20260715 p
      ON p.card_id = s.card_id AND p.source = s.source
    EXCEPT
    SELECT p.*
    FROM manaloom_deploy_audit.pg873_sac_outlet_post_semantic_20260715 p
  ) current_minus_snapshot
  UNION ALL
  SELECT * FROM (
    SELECT p.*
    FROM manaloom_deploy_audit.pg873_sac_outlet_post_semantic_20260715 p
    EXCEPT
    SELECT s.*
    FROM public.card_semantic_tags_v2 s
    JOIN manaloom_deploy_audit.pg873_sac_outlet_post_semantic_20260715 p
      ON p.card_id = s.card_id AND p.source = s.source
  ) snapshot_minus_current
),
ordered_tags AS (
  SELECT
    p.card_id,
    ordinality,
    (element->>'confidence')::numeric AS confidence,
    element->>'tag' AS tag,
    lag((element->>'confidence')::numeric) OVER (
      PARTITION BY p.card_id ORDER BY ordinality
    ) AS previous_confidence,
    lag(element->>'tag') OVER (
      PARTITION BY p.card_id ORDER BY ordinality
    ) AS previous_tag
  FROM manaloom_deploy_audit.pg873_sac_outlet_post_semantic_20260715 p
  CROSS JOIN LATERAL jsonb_array_elements(p.tags)
    WITH ORDINALITY AS elements(element, ordinality)
),
metrics AS (
  SELECT
    (SELECT count(*) FROM expected WHERE lane='deterministic_heuristic_v1') AS live_heuristic_expected_count,
    (SELECT encode(digest(string_agg(card_id::text, E'\n' ORDER BY card_id::text), 'sha256'), 'hex') FROM expected WHERE lane='deterministic_heuristic_v1') AS live_heuristic_expected_sha256,
    (SELECT count(*) FROM global_expected WHERE lane='deterministic_semantic_v2') AS live_semantic_global_expected_count,
    (SELECT encode(digest(string_agg(card_id::text, E'\n' ORDER BY card_id::text), 'sha256'), 'hex') FROM global_expected WHERE lane='deterministic_semantic_v2') AS live_semantic_global_expected_sha256,
    (SELECT count(*) FROM expected WHERE lane='deterministic_semantic_v2') AS live_semantic_expected_count,
    (SELECT encode(digest(string_agg(card_id::text, E'\n' ORDER BY card_id::text), 'sha256'), 'hex') FROM expected WHERE lane='deterministic_semantic_v2') AS live_semantic_expected_sha256,
    (SELECT count(*) FROM manaloom_deploy_audit.pg873_sac_outlet_expected_20260715 WHERE source='deterministic_heuristic_v1') AS manifest_heuristic_count,
    (SELECT count(*) FROM manaloom_deploy_audit.pg873_sac_outlet_expected_20260715 WHERE source='deterministic_semantic_v2') AS manifest_semantic_count,
    (SELECT count(*) FROM manaloom_deploy_audit.pg873_sac_outlet_function_backup_20260715) AS function_backup_count,
    (SELECT count(*) FROM manaloom_deploy_audit.pg873_sac_outlet_semantic_backup_20260715) AS semantic_backup_count,
    (SELECT count(*) FROM manaloom_deploy_audit.pg873_sac_outlet_deferred_semantic_20260715) AS deferred_manifest_count,
    (SELECT encode(digest(string_agg(card_id::text, E'\n' ORDER BY card_id::text), 'sha256'), 'hex') FROM manaloom_deploy_audit.pg873_sac_outlet_deferred_semantic_20260715) AS deferred_manifest_sha256,
    (SELECT count(*) FROM deferred_missing_semantic) AS live_deferred_count,
    (SELECT encode(digest(string_agg(card_id::text, E'\n' ORDER BY card_id::text), 'sha256'), 'hex') FROM deferred_missing_semantic) AS live_deferred_sha256,
    (SELECT count(*) FROM (
       (SELECT card_id FROM deferred_missing_semantic EXCEPT SELECT card_id FROM manaloom_deploy_audit.pg873_sac_outlet_deferred_semantic_20260715)
       UNION ALL
       (SELECT card_id FROM manaloom_deploy_audit.pg873_sac_outlet_deferred_semantic_20260715 EXCEPT SELECT card_id FROM deferred_missing_semantic)
     ) d) AS deferred_manifest_diff_rows,
    (SELECT count(*) FROM manaloom_deploy_audit.pg873_sac_outlet_deferred_semantic_20260715 d JOIN public.card_semantic_tags_v2 s ON s.card_id=d.card_id AND s.source='deterministic_semantic_v2') AS deferred_semantic_source_conflicts,
    (SELECT count(*) FROM manaloom_deploy_audit.pg873_sac_outlet_post_semantic_20260715) AS post_semantic_count,
    (SELECT count(*) FROM current_function WHERE lane='deterministic_heuristic_v1') AS heuristic_function_count,
    (SELECT encode(digest(string_agg(card_id::text, E'\n' ORDER BY card_id::text), 'sha256'), 'hex') FROM current_function WHERE lane='deterministic_heuristic_v1') AS heuristic_function_sha256,
    (SELECT count(*) FROM current_function WHERE lane='deterministic_semantic_v2') AS semantic_function_count,
    (SELECT encode(digest(string_agg(card_id::text, E'\n' ORDER BY card_id::text), 'sha256'), 'hex') FROM current_function WHERE lane='deterministic_semantic_v2') AS semantic_function_sha256,
    (SELECT count(*) FROM current_function WHERE confidence<>0.8 OR evidence IS DISTINCT FROM 'external_activated_sacrifice_outlet_cost') AS function_wrong_payload,
    (SELECT count(*) FROM current_json) AS semantic_json_count,
    (SELECT encode(digest(string_agg(card_id::text, E'\n' ORDER BY card_id::text), 'sha256'), 'hex') FROM current_json) AS semantic_json_sha256,
    (SELECT count(*) FROM current_json WHERE outlet_elements<>1 OR outlet_confidence<>0.8 OR outlet_evidence IS DISTINCT FROM 'external_activated_sacrifice_outlet_cost') AS semantic_json_wrong_payload,
    (SELECT count(*) FROM post_diff) AS post_semantic_diff_rows,
    (SELECT count(*) FROM manaloom_deploy_audit.pg873_sac_outlet_semantic_backup_20260715 b WHERE NOT EXISTS (SELECT 1 FROM manaloom_deploy_audit.pg873_sac_outlet_post_semantic_20260715 p WHERE p.card_id=b.card_id) AND EXISTS (SELECT 1 FROM public.card_semantic_tags_v2 s WHERE s.card_id=b.card_id AND s.source='deterministic_semantic_v2')) AS deleted_semantic_rows_resurrected,
    (SELECT count(*) FROM manaloom_deploy_audit.pg873_sac_outlet_post_semantic_20260715 p WHERE p.role_confidence <> (SELECT max((element->>'confidence')::numeric) FROM jsonb_array_elements(p.tags) element)) AS stale_role_confidence_rows,
    (SELECT count(*) FROM ordered_tags WHERE previous_confidence < confidence OR (previous_confidence = confidence AND previous_tag > tag)) AS tag_order_violations,
    (SELECT count(*) FROM (
       (SELECT lane,card_id FROM expected EXCEPT SELECT source,card_id FROM manaloom_deploy_audit.pg873_sac_outlet_expected_20260715)
       UNION ALL
       (SELECT source,card_id FROM manaloom_deploy_audit.pg873_sac_outlet_expected_20260715 EXCEPT SELECT lane,card_id FROM expected)
     ) d) AS live_manifest_diff_rows
)
SELECT
  m.*,
  CASE
    WHEN live_heuristic_expected_count=716
     AND live_heuristic_expected_sha256='51272701cdb5b277a2007de43c418c418fab5380409fc16c08ac527fd1ddacbd'
     AND live_semantic_global_expected_count=736
     AND live_semantic_global_expected_sha256='512cb67eca26b4c86d4555fcf14cae19e6e9f0a9bd24239db0d4cc6caa49418c'
     AND live_semantic_expected_count=684
     AND live_semantic_expected_sha256='573c94fad8b4ba9d9789daadd506e4ce2b0143dfa0d049eb8687c4c8cd90e8bd'
     AND manifest_heuristic_count=716
     AND manifest_semantic_count=684
     AND function_backup_count=2737
     AND semantic_backup_count=1557
     AND deferred_manifest_count=52
     AND deferred_manifest_sha256='4f29cbcbbdaa9a10bf285ff808c40ab8f3026367a2b3bc873fd51424cad5b199'
     AND live_deferred_count=52
     AND live_deferred_sha256='4f29cbcbbdaa9a10bf285ff808c40ab8f3026367a2b3bc873fd51424cad5b199'
     AND deferred_manifest_diff_rows=0
     AND deferred_semantic_source_conflicts=0
     AND post_semantic_count=1524
     AND heuristic_function_count=716
     AND heuristic_function_sha256='51272701cdb5b277a2007de43c418c418fab5380409fc16c08ac527fd1ddacbd'
     AND semantic_function_count=684
     AND semantic_function_sha256='573c94fad8b4ba9d9789daadd506e4ce2b0143dfa0d049eb8687c4c8cd90e8bd'
     AND function_wrong_payload=0
     AND semantic_json_count=684
     AND semantic_json_sha256='573c94fad8b4ba9d9789daadd506e4ce2b0143dfa0d049eb8687c4c8cd90e8bd'
     AND semantic_json_wrong_payload=0
     AND post_semantic_diff_rows=0
     AND deleted_semantic_rows_resurrected=0
     AND stale_role_confidence_rows=0
     AND tag_order_violations=0
     AND live_manifest_diff_rows=0
    THEN 'ok'
    ELSE ('PG873_POSTCHECK_ABORT_' || semantic_json_count::text)::integer::text
  END AS guard
FROM metrics m;

ROLLBACK;
