-- MUTATING. Requires explicit PostgreSQL approval for this execution.
-- PG874 exact remove-only reconciliation for confirmed ramp false positives.

BEGIN;
CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg874_ramp_target_20260716') IS NOT NULL
     OR to_regclass('manaloom_deploy_audit.pg874_ramp_function_backup_20260716') IS NOT NULL
     OR to_regclass('manaloom_deploy_audit.pg874_ramp_role_backup_20260716') IS NOT NULL
     OR to_regclass('manaloom_deploy_audit.pg874_ramp_semantic_backup_20260716') IS NOT NULL
     OR to_regclass('manaloom_deploy_audit.pg874_ramp_post_semantic_20260716') IS NOT NULL THEN
    RAISE EXCEPTION 'PG874 abort: audit tables already exist';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg874_ramp_target_20260716 AS
WITH card_text AS (
  SELECT c.id card_id,c.name,coalesce(c.type_line,'') type_line,
    lower(coalesce(c.type_line,'')) type_lower,
    lower(coalesce(c.oracle_text,'')) oracle,
    substring(lower(coalesce(c.oracle_text,'')) FROM position('search your library' IN lower(coalesce(c.oracle_text,'')))) after_search
  FROM public.cards c
), classified AS (
  SELECT *,type_lower ~ '(^|[^a-z])land([^a-z]|$)' is_land,
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
  SELECT card_id,name,type_line,
    CASE WHEN is_land THEN 'land_structural_not_generic_ramp'
         WHEN hand_only_land_search THEN 'land_search_without_battlefield_acceleration'
         ELSE 'oracle_face_drift_no_mana_text' END classification
  FROM classified
  WHERE is_land OR hand_only_land_search
     OR name='Ashling, Rekindled // Ashling, Rimebound'
)
SELECT p.*
FROM predicate_cards p
WHERE EXISTS(SELECT 1 FROM public.card_function_tags f WHERE f.card_id=p.card_id AND f.tag='ramp' AND f.source IN('deterministic_heuristic_v1','deterministic_semantic_v2'))
   OR EXISTS(SELECT 1 FROM public.card_role_scores r WHERE r.card_id=p.card_id AND r.role='ramp' AND r.source='deterministic_heuristic_v1')
   OR EXISTS(SELECT 1 FROM public.card_semantic_tags_v2 s WHERE s.card_id=p.card_id AND s.source='deterministic_semantic_v2' AND s.schema_version='semantic_layer_v2_2026_05_18' AND s.tags @> '[{"tag":"ramp"}]'::jsonb);

ALTER TABLE manaloom_deploy_audit.pg874_ramp_target_20260716
  ADD PRIMARY KEY (card_id);

DO $$
DECLARE v_count bigint; v_sha text; v_land bigint; v_search bigint; v_oracle bigint;
BEGIN
  SELECT count(*),encode(digest(string_agg(card_id::text,E'\n' ORDER BY card_id::text),'sha256'),'hex'),
    count(*) FILTER(WHERE classification='land_structural_not_generic_ramp'),
    count(*) FILTER(WHERE classification='land_search_without_battlefield_acceleration'),
    count(*) FILTER(WHERE classification='oracle_face_drift_no_mana_text')
  INTO v_count,v_sha,v_land,v_search,v_oracle
  FROM manaloom_deploy_audit.pg874_ramp_target_20260716;
  IF v_count<>1377 OR v_sha<>'cebc65973dfb91315dae85510be400b2ed6bcad5e8cff765c5a2ed6db5b51123'
     OR v_land<>1159 OR v_search<>217 OR v_oracle<>1 THEN
    RAISE EXCEPTION 'PG874 abort: target manifest drift count=% sha=% split=%/%/%',v_count,v_sha,v_land,v_search,v_oracle;
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg874_ramp_function_backup_20260716 AS
SELECT f.* FROM public.card_function_tags f
JOIN manaloom_deploy_audit.pg874_ramp_target_20260716 t USING(card_id)
WHERE f.tag='ramp'
  AND f.source IN('deterministic_heuristic_v1','deterministic_semantic_v2');

CREATE TABLE manaloom_deploy_audit.pg874_ramp_role_backup_20260716 AS
SELECT r.* FROM public.card_role_scores r
JOIN manaloom_deploy_audit.pg874_ramp_target_20260716 t USING(card_id)
WHERE r.role='ramp' AND r.source='deterministic_heuristic_v1';

CREATE TABLE manaloom_deploy_audit.pg874_ramp_semantic_backup_20260716 AS
SELECT s.* FROM public.card_semantic_tags_v2 s
JOIN manaloom_deploy_audit.pg874_ramp_target_20260716 t USING(card_id)
WHERE s.source='deterministic_semantic_v2'
  AND s.schema_version='semantic_layer_v2_2026_05_18'
  AND s.tags @> '[{"tag":"ramp"}]'::jsonb;

DO $$
DECLARE hc bigint; hsha text; rc bigint; rsha text; sc bigint; ssha text; semc bigint; emptyc bigint;
BEGIN
  SELECT count(*),encode(digest(string_agg(card_id::text,E'\n' ORDER BY card_id::text),'sha256'),'hex')
    INTO hc,hsha FROM manaloom_deploy_audit.pg874_ramp_function_backup_20260716 WHERE source='deterministic_heuristic_v1';
  SELECT count(*),encode(digest(string_agg(card_id::text||'|'||format||'|'||subformat||'|'||bracket_scope||'|'||budget_tier,E'\n' ORDER BY card_id::text||'|'||format||'|'||subformat||'|'||bracket_scope||'|'||budget_tier),'sha256'),'hex')
    INTO rc,rsha FROM manaloom_deploy_audit.pg874_ramp_role_backup_20260716;
  SELECT count(*),encode(digest(string_agg(card_id::text,E'\n' ORDER BY card_id::text),'sha256'),'hex')
    INTO sc,ssha FROM manaloom_deploy_audit.pg874_ramp_function_backup_20260716 WHERE source='deterministic_semantic_v2';
  SELECT count(*),count(*) FILTER(WHERE jsonb_array_length(tags)=1)
    INTO semc,emptyc FROM manaloom_deploy_audit.pg874_ramp_semantic_backup_20260716;
  IF hc<>1302 OR hsha<>'c583f582b7b39b47615fc695a79f6da8fce5074ed6b0c171b76a6ce73325d47b'
     OR rc<>1322 OR rsha<>'822706ddc3aa49c081a17106d7ca229f8eba53cbee4342f649e7ee0a84a554c3'
     OR sc<>1350 OR ssha<>'410258d08c2e41da90d8c8b14862c3a6f0986727c193dc6b61f4996615397e6f'
     OR semc<>1350 OR emptyc<>1 THEN
    RAISE EXCEPTION 'PG874 abort: backup drift h=% r=% s=% semantic=% empty=%',hc,rc,sc,semc,emptyc;
  END IF;
END $$;

DELETE FROM public.card_function_tags f
USING manaloom_deploy_audit.pg874_ramp_target_20260716 t
WHERE f.card_id=t.card_id AND f.tag='ramp'
  AND f.source IN('deterministic_heuristic_v1','deterministic_semantic_v2');

DELETE FROM public.card_role_scores r
USING manaloom_deploy_audit.pg874_ramp_target_20260716 t
WHERE r.card_id=t.card_id AND r.role='ramp'
  AND r.source='deterministic_heuristic_v1';

WITH rebuilt AS (
  SELECT b.card_id,
    coalesce(jsonb_agg(e ORDER BY (e->>'confidence')::numeric DESC,e->>'tag') FILTER(WHERE e->>'tag'<>'ramp'),'[]'::jsonb) tags
  FROM manaloom_deploy_audit.pg874_ramp_semantic_backup_20260716 b
  CROSS JOIN LATERAL jsonb_array_elements(b.tags) e
  GROUP BY b.card_id
), derived AS (
  SELECT card_id,tags,
    coalesce((SELECT max((e->>'confidence')::numeric) FROM jsonb_array_elements(tags)e),0) role_confidence,
    tags @> '[{"tag":"enabler"}]'::jsonb OR tags @> '[{"tag":"loot"}]'::jsonb OR tags @> '[{"tag":"tutor"}]'::jsonb AS enabler,
    CASE
      WHEN tags @> '[{"tag":"land"}]'::jsonb THEN 'land_or_mana_source'
      WHEN tags @> '[{"tag":"draw"}]'::jsonb THEN 'adds_cards_or_refills_hand'
      WHEN tags @> '[{"tag":"loot"}]'::jsonb THEN 'filters_hand_quality'
      WHEN tags @> '[{"tag":"tutor"}]'::jsonb THEN 'searches_library_for_nonland_card'
      WHEN tags @> '[{"tag":"removal"}]'::jsonb THEN 'answers_targeted_threats'
      WHEN tags @> '[{"tag":"board_wipe"}]'::jsonb THEN 'answers_multiple_threats'
      WHEN tags @> '[{"tag":"protection"}]'::jsonb THEN 'protects_plan_or_permanents'
      WHEN tags @> '[{"tag":"recursion"}]'::jsonb THEN 'returns_resources_from_graveyard'
      WHEN tags @> '[{"tag":"wincon"}]'::jsonb THEN 'can_close_or_win_the_game'
      WHEN tags @> '[{"tag":"combo_piece"}]'::jsonb THEN 'matches_known_combo_pattern'
      WHEN tags @> '[{"tag":"engine"}]'::jsonb THEN 'creates_repeatable_value'
      WHEN tags @> '[{"tag":"payoff"}]'::jsonb THEN 'rewards_the_deck_plan'
      WHEN tags @> '[{"tag":"enabler"}]'::jsonb THEN 'sets_up_the_deck_plan'
      ELSE 'no_primary_function_detected'
    END explanation_reason
  FROM rebuilt
)
UPDATE public.card_semantic_tags_v2 s
SET tags=d.tags,role_confidence=d.role_confidence,enabler=d.enabler,
    explanation_reason=d.explanation_reason,updated_at=CURRENT_TIMESTAMP
FROM derived d
WHERE s.card_id=d.card_id AND s.source='deterministic_semantic_v2'
  AND s.schema_version='semantic_layer_v2_2026_05_18'
  AND jsonb_array_length(d.tags)>0;

DELETE FROM public.card_semantic_tags_v2 s
USING manaloom_deploy_audit.pg874_ramp_semantic_backup_20260716 b
WHERE s.card_id=b.card_id AND s.source=b.source
  AND NOT EXISTS(
    SELECT 1 FROM jsonb_array_elements(b.tags)e WHERE e->>'tag'<>'ramp'
  );

CREATE TABLE manaloom_deploy_audit.pg874_ramp_post_semantic_20260716 AS
SELECT s.* FROM public.card_semantic_tags_v2 s
JOIN manaloom_deploy_audit.pg874_ramp_semantic_backup_20260716 b
  ON b.card_id=s.card_id AND b.source=s.source;

DO $$
DECLARE hc bigint; hsha text; rc bigint; rsha text; sc bigint; ssha text; jc bigint; jsha text; postc bigint; bad bigint;
BEGIN
  SELECT count(*),encode(digest(string_agg(card_id::text,E'\n' ORDER BY card_id::text),'sha256'),'hex') INTO hc,hsha
  FROM public.card_function_tags WHERE tag='ramp' AND source='deterministic_heuristic_v1';
  SELECT count(*),encode(digest(string_agg(card_id::text||'|'||format||'|'||subformat||'|'||bracket_scope||'|'||budget_tier,E'\n' ORDER BY card_id::text||'|'||format||'|'||subformat||'|'||bracket_scope||'|'||budget_tier),'sha256'),'hex') INTO rc,rsha
  FROM public.card_role_scores WHERE role='ramp' AND source='deterministic_heuristic_v1';
  SELECT count(*),encode(digest(string_agg(card_id::text,E'\n' ORDER BY card_id::text),'sha256'),'hex') INTO sc,ssha
  FROM public.card_function_tags WHERE tag='ramp' AND source='deterministic_semantic_v2';
  SELECT count(*),encode(digest(string_agg(card_id::text,E'\n' ORDER BY card_id::text),'sha256'),'hex') INTO jc,jsha
  FROM public.card_semantic_tags_v2 WHERE source='deterministic_semantic_v2' AND schema_version='semantic_layer_v2_2026_05_18' AND tags @> '[{"tag":"ramp"}]'::jsonb;
  SELECT count(*) INTO postc FROM manaloom_deploy_audit.pg874_ramp_post_semantic_20260716;
  SELECT count(*) INTO bad FROM public.card_semantic_tags_v2 s JOIN manaloom_deploy_audit.pg874_ramp_target_20260716 t USING(card_id)
  WHERE s.source='deterministic_semantic_v2' AND s.tags @> '[{"tag":"ramp"}]'::jsonb;
  IF hc<>1790 OR hsha<>'f6969e2506428916646afdcec3271b4174a65b35130f68a7033249a47aa0e37c'
     OR rc<>1802 OR rsha<>'8f909dfbfb06b6e004419c2cb0ba296631e606653b7d58113d285ffbc9205b4f'
     OR sc<>1896 OR ssha<>'3c0d4addbaf2d961bfc515ac8c81967e1371bca803865d54f6fae5f3bc35bef1'
     OR jc<>1896 OR jsha<>'3c0d4addbaf2d961bfc515ac8c81967e1371bca803865d54f6fae5f3bc35bef1'
     OR postc<>1349 OR bad<>0 THEN
    RAISE EXCEPTION 'PG874 abort: post state drift h=% r=% s=% j=% post=% bad=%',hc,rc,sc,jc,postc,bad;
  END IF;
END $$;

COMMIT;
