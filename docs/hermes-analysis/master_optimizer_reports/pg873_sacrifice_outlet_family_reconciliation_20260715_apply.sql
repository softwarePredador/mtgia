-- MUTATING. Requires explicit PostgreSQL approval for this execution.
-- Reconciles only sacrifice_outlet in the two deterministic function lanes and
-- the matching deterministic semantic-v2 JSON member.
\set ON_ERROR_STOP on
BEGIN;
SET LOCAL statement_timeout = '5min';
SET LOCAL lock_timeout = '15s';

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;
LOCK TABLE public.cards IN SHARE MODE;
LOCK TABLE public.card_function_tags IN SHARE ROW EXCLUSIVE MODE;
LOCK TABLE public.card_semantic_tags_v2 IN SHARE ROW EXCLUSIVE MODE;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg873_sac_outlet_expected_20260715') IS NOT NULL
     OR to_regclass('manaloom_deploy_audit.pg873_sac_outlet_function_backup_20260715') IS NOT NULL
     OR to_regclass('manaloom_deploy_audit.pg873_sac_outlet_semantic_backup_20260715') IS NOT NULL
     OR to_regclass('manaloom_deploy_audit.pg873_sac_outlet_deferred_semantic_20260715') IS NOT NULL
     OR to_regclass('manaloom_deploy_audit.pg873_sac_outlet_post_semantic_20260715') IS NOT NULL THEN
    RAISE EXCEPTION 'PG873 abort: an audit table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg873_sac_outlet_expected_20260715 AS
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
expected AS (
  SELECT e.lane, e.card_id
  FROM global_expected e
  WHERE e.lane = 'deterministic_heuristic_v1'
     OR EXISTS (
       SELECT 1
       FROM public.card_semantic_tags_v2 s
       WHERE s.card_id = e.card_id
         AND s.source = 'deterministic_semantic_v2'
         AND s.schema_version = 'semantic_layer_v2_2026_05_18'
     )
)
SELECT e.card_id, e.lane AS source, c.name AS card_name
FROM expected e
JOIN public.cards c ON c.id = e.card_id;

ALTER TABLE manaloom_deploy_audit.pg873_sac_outlet_expected_20260715
  ADD PRIMARY KEY (card_id, source);

DO $$
DECLARE
  v_heuristic_count bigint;
  v_semantic_count bigint;
  v_heuristic_sha text;
  v_semantic_sha text;
BEGIN
  SELECT count(*), encode(digest(string_agg(card_id::text, E'\n' ORDER BY card_id::text), 'sha256'), 'hex')
  INTO v_heuristic_count, v_heuristic_sha
  FROM manaloom_deploy_audit.pg873_sac_outlet_expected_20260715
  WHERE source = 'deterministic_heuristic_v1';

  SELECT count(*), encode(digest(string_agg(card_id::text, E'\n' ORDER BY card_id::text), 'sha256'), 'hex')
  INTO v_semantic_count, v_semantic_sha
  FROM manaloom_deploy_audit.pg873_sac_outlet_expected_20260715
  WHERE source = 'deterministic_semantic_v2';

  IF v_heuristic_count <> 716
     OR v_heuristic_sha <> '51272701cdb5b277a2007de43c418c418fab5380409fc16c08ac527fd1ddacbd'
     OR v_semantic_count <> 684
     OR v_semantic_sha <> '573c94fad8b4ba9d9789daadd506e4ce2b0143dfa0d049eb8687c4c8cd90e8bd' THEN
    RAISE EXCEPTION 'PG873 abort: expected manifest drift h=%/% s=%/%',
      v_heuristic_count, v_heuristic_sha, v_semantic_count, v_semantic_sha;
  END IF;
END $$;

-- These cards have no existing deterministic semantic snapshot. PG873 records
-- them for a later full semantic backfill and never creates an outlet-only row.
CREATE TABLE manaloom_deploy_audit.pg873_sac_outlet_deferred_semantic_20260715 AS
WITH RECURSIVE
semantic_owner AS (
  SELECT c.id AS card_id, c.name, lower(c.oracle_text) AS oracle_text
  FROM public.cards c
  WHERE coalesce(c.type_line, '') <> ''
    AND coalesce(c.oracle_text, '') <> ''
),
stripped_parenthetical(card_id, name, oracle_text, depth) AS (
  SELECT card_id, name, oracle_text, 0 FROM semantic_owner
  UNION ALL
  SELECT card_id, name, regexp_replace(oracle_text, '\([^()]*\)', '', 'g'), depth + 1
  FROM stripped_parenthetical
  WHERE depth < 20 AND oracle_text ~ '\([^()]*\)'
),
clean_cards AS (
  SELECT DISTINCT ON (card_id)
    card_id, name, regexp_replace(oracle_text, '\([^)]*$', '', 'g') AS oracle_text
  FROM stripped_parenthetical
  ORDER BY card_id, depth DESC
),
name_faces AS (
  SELECT
    c.card_id,
    regexp_replace(
      replace(replace(lower(trim(face)), '‘', ''''), '’', ''''),
      '\s+', ' ', 'g'
    ) AS face
  FROM clean_cards c
  CROSS JOIN LATERAL regexp_split_to_table(c.name, '\s*//\s*') AS face
),
name_aliases AS (
  SELECT card_id, face AS self_name FROM name_faces WHERE face <> ''
  UNION
  SELECT card_id, CASE WHEN face LIKE 'a-%' THEN trim(substr(face, 3)) ELSE face END
  FROM name_faces WHERE face <> ''
  UNION
  SELECT card_id, trim(split_part(
    CASE WHEN face LIKE 'a-%' THEN trim(substr(face, 3)) ELSE face END, ',', 1
  ))
  FROM name_faces
  WHERE strpos(CASE WHEN face LIKE 'a-%' THEN trim(substr(face, 3)) ELSE face END, ',') > 0
    AND length(trim(split_part(
      CASE WHEN face LIKE 'a-%' THEN trim(substr(face, 3)) ELSE face END, ',', 1
    ))) >= 3
),
oracle_lines AS (
  SELECT c.card_id, line_no, line
  FROM clean_cards c
  CROSS JOIN LATERAL regexp_split_to_table(c.oracle_text, E'[\\r\\n]+')
    WITH ORDINALITY AS lines(line, line_no)
),
colon_segments AS (
  SELECT
    l.card_id,
    segment_no,
    regexp_replace(trim(segment), '\s+', ' ', 'g') AS cost_segment,
    count(*) OVER (PARTITION BY l.card_id, l.line_no) AS segment_count
  FROM oracle_lines l
  CROSS JOIN LATERAL regexp_split_to_table(l.line, ':')
    WITH ORDINALITY AS segments(segment, segment_no)
),
sacrifice_objects AS (
  SELECT s.card_id, trim(matches[1]) AS object_phrase
  FROM colon_segments s
  CROSS JOIN LATERAL regexp_matches(s.cost_segment, '\msacrifice\s+(.+)$', 'g') AS matches
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
          SELECT 1 FROM name_aliases a
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
)
SELECT o.card_id, o.name AS card_name
FROM semantic_owner o
JOIN expected_cards e USING (card_id)
LEFT JOIN public.card_semantic_tags_v2 s
  ON s.card_id = o.card_id
 AND s.source = 'deterministic_semantic_v2'
 AND s.schema_version = 'semantic_layer_v2_2026_05_18'
WHERE s.card_id IS NULL;

ALTER TABLE manaloom_deploy_audit.pg873_sac_outlet_deferred_semantic_20260715
  ADD PRIMARY KEY (card_id);

DO $$
DECLARE
  v_count bigint;
  v_sha text;
BEGIN
  SELECT count(*), encode(digest(string_agg(card_id::text, E'\n' ORDER BY card_id::text), 'sha256'), 'hex')
  INTO v_count, v_sha
  FROM manaloom_deploy_audit.pg873_sac_outlet_deferred_semantic_20260715;

  IF v_count <> 52
     OR v_sha <> '4f29cbcbbdaa9a10bf285ff808c40ab8f3026367a2b3bc873fd51424cad5b199' THEN
    RAISE EXCEPTION 'PG873 abort: deferred semantic backlog drift count=% sha=%', v_count, v_sha;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM manaloom_deploy_audit.pg873_sac_outlet_deferred_semantic_20260715 m
    LEFT JOIN public.cards c ON c.id = m.card_id
    WHERE c.id IS NULL
       OR c.name IS DISTINCT FROM m.card_name
  ) THEN
    RAISE EXCEPTION 'PG873 abort: invalid deferred semantic backlog payload';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM manaloom_deploy_audit.pg873_sac_outlet_deferred_semantic_20260715 m
    JOIN public.card_semantic_tags_v2 s
      ON s.card_id = m.card_id
     AND s.source = 'deterministic_semantic_v2'
  ) THEN
    RAISE EXCEPTION 'PG873 abort: a deferred semantic card already has a source row';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg873_sac_outlet_function_backup_20260715 AS
SELECT f.*
FROM public.card_function_tags f
WHERE f.tag = 'sacrifice_outlet'
  AND f.source IN ('deterministic_heuristic_v1', 'deterministic_semantic_v2');

CREATE TABLE manaloom_deploy_audit.pg873_sac_outlet_semantic_backup_20260715 AS
SELECT s.*
FROM public.card_semantic_tags_v2 s
WHERE s.source = 'deterministic_semantic_v2'
  AND s.schema_version = 'semantic_layer_v2_2026_05_18'
  AND (
    s.tags @> '[{"tag":"sacrifice_outlet"}]'::jsonb
    OR EXISTS (
      SELECT 1
      FROM manaloom_deploy_audit.pg873_sac_outlet_expected_20260715 e
      WHERE e.source = 'deterministic_semantic_v2'
        AND e.card_id = s.card_id
    )
  );

DO $$
DECLARE
  v_function_count bigint;
  v_semantic_count bigint;
  v_h_sha text;
  v_s_sha text;
BEGIN
  SELECT count(*) INTO v_function_count
  FROM manaloom_deploy_audit.pg873_sac_outlet_function_backup_20260715;
  SELECT count(*) INTO v_semantic_count
  FROM manaloom_deploy_audit.pg873_sac_outlet_semantic_backup_20260715;
  SELECT encode(digest(string_agg(card_id::text, E'\n' ORDER BY card_id::text), 'sha256'), 'hex')
  INTO v_h_sha
  FROM manaloom_deploy_audit.pg873_sac_outlet_function_backup_20260715
  WHERE source = 'deterministic_heuristic_v1';
  SELECT encode(digest(string_agg(card_id::text, E'\n' ORDER BY card_id::text), 'sha256'), 'hex')
  INTO v_s_sha
  FROM manaloom_deploy_audit.pg873_sac_outlet_function_backup_20260715
  WHERE source = 'deterministic_semantic_v2';

  IF v_function_count <> 2737 OR v_semantic_count <> 1557
     OR v_h_sha <> '5986c9df6c911b8c8aa24744ccc57c2e93e9d3421b716b7c302f95192f17d046'
     OR v_s_sha <> 'cdc90bbc3d1b55b42050081cb6c1352937a3df4a2187ea0e34434270a3695d7e' THEN
    RAISE EXCEPTION 'PG873 abort: backup drift function=% semantic=% h=% s=%',
      v_function_count, v_semantic_count, v_h_sha, v_s_sha;
  END IF;
END $$;

DELETE FROM public.card_function_tags f
WHERE f.tag = 'sacrifice_outlet'
  AND f.source IN ('deterministic_heuristic_v1', 'deterministic_semantic_v2');

INSERT INTO public.card_function_tags (
  card_id, card_name, tag, confidence, source, evidence, updated_at
)
SELECT
  e.card_id,
  e.card_name,
  'sacrifice_outlet',
  0.8,
  e.source,
  'external_activated_sacrifice_outlet_cost',
  CURRENT_TIMESTAMP
FROM manaloom_deploy_audit.pg873_sac_outlet_expected_20260715 e;

WITH rebuilt AS (
  SELECT
    b.card_id,
    coalesce(
      jsonb_agg(
        item
        ORDER BY (item->>'confidence')::numeric DESC, item->>'tag' ASC
      ) FILTER (WHERE item IS NOT NULL),
      '[]'::jsonb
    ) AS tags,
    coalesce(max((item->>'confidence')::numeric), 0) AS role_confidence
  FROM manaloom_deploy_audit.pg873_sac_outlet_semantic_backup_20260715 b
  LEFT JOIN LATERAL (
    SELECT element AS item
    FROM jsonb_array_elements(b.tags) AS element
    WHERE element->>'tag' <> 'sacrifice_outlet'
    UNION ALL
    SELECT jsonb_build_object(
      'tag', 'sacrifice_outlet',
      'confidence', 0.8,
      'evidence', 'external_activated_sacrifice_outlet_cost'
    )
    WHERE EXISTS (
      SELECT 1
      FROM manaloom_deploy_audit.pg873_sac_outlet_expected_20260715 e
      WHERE e.source = 'deterministic_semantic_v2'
        AND e.card_id = b.card_id
    )
  ) rebuilt_items ON true
  GROUP BY b.card_id
)
UPDATE public.card_semantic_tags_v2 s
SET tags = rebuilt.tags,
    role_confidence = rebuilt.role_confidence,
    updated_at = CURRENT_TIMESTAMP
FROM rebuilt
WHERE s.card_id = rebuilt.card_id
  AND s.source = 'deterministic_semantic_v2'
  AND s.schema_version = 'semantic_layer_v2_2026_05_18'
  AND jsonb_array_length(rebuilt.tags) > 0;

DELETE FROM public.card_semantic_tags_v2 s
USING manaloom_deploy_audit.pg873_sac_outlet_semantic_backup_20260715 b
WHERE s.card_id = b.card_id
  AND s.source = 'deterministic_semantic_v2'
  AND s.schema_version = 'semantic_layer_v2_2026_05_18'
  AND NOT EXISTS (
    SELECT 1
    FROM manaloom_deploy_audit.pg873_sac_outlet_expected_20260715 e
    WHERE e.source = 'deterministic_semantic_v2'
      AND e.card_id = b.card_id
  )
  AND NOT EXISTS (
    SELECT 1 FROM jsonb_array_elements(b.tags) element
    WHERE element->>'tag' <> 'sacrifice_outlet'
  );

CREATE TABLE manaloom_deploy_audit.pg873_sac_outlet_post_semantic_20260715 AS
SELECT s.*
FROM public.card_semantic_tags_v2 s
WHERE s.source = 'deterministic_semantic_v2'
  AND (
    EXISTS (
      SELECT 1
      FROM manaloom_deploy_audit.pg873_sac_outlet_semantic_backup_20260715 b
      WHERE b.card_id = s.card_id
    )
  );

DO $$
DECLARE
  v_h_count bigint;
  v_s_count bigint;
  v_h_sha text;
  v_s_sha text;
  v_json_count bigint;
  v_json_sha text;
  v_bad bigint;
BEGIN
  SELECT count(*), encode(digest(string_agg(card_id::text, E'\n' ORDER BY card_id::text), 'sha256'), 'hex')
  INTO v_h_count, v_h_sha
  FROM public.card_function_tags
  WHERE tag = 'sacrifice_outlet' AND source = 'deterministic_heuristic_v1';
  SELECT count(*), encode(digest(string_agg(card_id::text, E'\n' ORDER BY card_id::text), 'sha256'), 'hex')
  INTO v_s_count, v_s_sha
  FROM public.card_function_tags
  WHERE tag = 'sacrifice_outlet' AND source = 'deterministic_semantic_v2';

  IF v_h_count <> 716
     OR v_h_sha <> '51272701cdb5b277a2007de43c418c418fab5380409fc16c08ac527fd1ddacbd'
     OR v_s_count <> 684
     OR v_s_sha <> '573c94fad8b4ba9d9789daadd506e4ce2b0143dfa0d049eb8687c4c8cd90e8bd' THEN
    RAISE EXCEPTION 'PG873 abort: post function sets diverged h=%/% s=%/%',
      v_h_count, v_h_sha, v_s_count, v_s_sha;
  END IF;

  SELECT count(*), encode(digest(string_agg(card_id::text, E'\n' ORDER BY card_id::text), 'sha256'), 'hex')
  INTO v_json_count, v_json_sha
  FROM public.card_semantic_tags_v2 s
  WHERE s.source = 'deterministic_semantic_v2'
    AND s.schema_version = 'semantic_layer_v2_2026_05_18'
    AND s.tags @> '[{"tag":"sacrifice_outlet"}]'::jsonb;

  IF v_json_count <> 684
     OR v_json_sha <> '573c94fad8b4ba9d9789daadd506e4ce2b0143dfa0d049eb8687c4c8cd90e8bd'
     OR (SELECT count(*) FROM manaloom_deploy_audit.pg873_sac_outlet_post_semantic_20260715) <> 1524 THEN
    RAISE EXCEPTION 'PG873 abort: post semantic set diverged count=% sha=% post_snapshot=%',
      v_json_count, v_json_sha,
      (SELECT count(*) FROM manaloom_deploy_audit.pg873_sac_outlet_post_semantic_20260715);
  END IF;

  SELECT count(*) INTO v_bad
  FROM public.card_function_tags f
  WHERE f.tag = 'sacrifice_outlet'
    AND f.source IN ('deterministic_heuristic_v1', 'deterministic_semantic_v2')
    AND (f.confidence <> 0.8 OR f.evidence IS DISTINCT FROM 'external_activated_sacrifice_outlet_cost');
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'PG873 abort: % function outlet rows have wrong payload', v_bad;
  END IF;

  SELECT count(*) INTO v_bad
  FROM public.card_semantic_tags_v2 s
  CROSS JOIN LATERAL jsonb_array_elements(s.tags) element
  WHERE s.source = 'deterministic_semantic_v2'
    AND s.schema_version = 'semantic_layer_v2_2026_05_18'
    AND element->>'tag' = 'sacrifice_outlet'
    AND ((element->>'confidence')::numeric <> 0.8
         OR element->>'evidence' IS DISTINCT FROM 'external_activated_sacrifice_outlet_cost');
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'PG873 abort: % semantic outlet elements have wrong payload', v_bad;
  END IF;

  SELECT count(*) INTO v_bad
  FROM manaloom_deploy_audit.pg873_sac_outlet_post_semantic_20260715 p
  WHERE p.role_confidence <> (
    SELECT max((element->>'confidence')::numeric)
    FROM jsonb_array_elements(p.tags) element
  );
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'PG873 abort: % target semantic rows have stale role_confidence', v_bad;
  END IF;
END $$;

COMMIT;
