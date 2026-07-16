-- MUTATING. Requires explicit PostgreSQL approval for this execution.
BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;
LOCK TABLE public.card_semantic_tags_v2 IN SHARE ROW EXCLUSIVE MODE;
LOCK TABLE public.card_function_tags IN SHARE ROW EXCLUSIVE MODE;

DO $$
BEGIN
  IF to_regclass(
    'manaloom_deploy_audit.pg872_semantic_tag_false_positive_repair_20260715'
  ) IS NOT NULL OR to_regclass(
    'manaloom_deploy_audit.pg872_function_tag_false_positive_repair_20260715'
  ) IS NOT NULL THEN
    RAISE EXCEPTION 'PG872 abort: audit snapshot already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg872_semantic_tag_false_positive_repair_20260715 AS
SELECT s.*
FROM public.cards c
JOIN public.card_semantic_tags_v2 s ON s.card_id = c.id
WHERE lower(c.name) IN ('bloodstained mire', 'lotus petal')
  AND s.source = 'deterministic_semantic_v2'
  AND s.schema_version = 'semantic_layer_v2_2026_05_18'
  AND (
    (lower(c.name) = 'bloodstained mire'
     AND md5(coalesce(c.oracle_text, '')) = 'c2b1d722530ed12d78dbc0993c3392fe')
    OR
    (lower(c.name) = 'lotus petal'
     AND md5(coalesce(c.oracle_text, '')) = 'a5b9069217908acfd75c5704b414b035')
  );

CREATE TABLE manaloom_deploy_audit.pg872_function_tag_false_positive_repair_20260715 AS
SELECT f.*
FROM public.cards c
JOIN public.card_function_tags f ON f.card_id = c.id
WHERE lower(c.name) = 'bloodstained mire'
  AND md5(coalesce(c.oracle_text, '')) = 'c2b1d722530ed12d78dbc0993c3392fe'
  AND f.tag = 'enabler'
  AND f.source = 'deterministic_semantic_v2';

DO $$
DECLARE
  v_semantic bigint;
  v_function bigint;
BEGIN
  SELECT count(*) INTO v_semantic
  FROM manaloom_deploy_audit.pg872_semantic_tag_false_positive_repair_20260715;
  SELECT count(*) INTO v_function
  FROM manaloom_deploy_audit.pg872_function_tag_false_positive_repair_20260715;
  IF v_semantic <> 2 OR v_function <> 1 THEN
    RAISE EXCEPTION 'PG872 abort: semantic snapshot=% function snapshot=%',
      v_semantic, v_function;
  END IF;
END $$;

DELETE FROM public.card_function_tags current
USING manaloom_deploy_audit.pg872_function_tag_false_positive_repair_20260715 snapshot
WHERE current.card_id = snapshot.card_id
  AND current.tag = snapshot.tag
  AND current.source = snapshot.source;

UPDATE public.card_semantic_tags_v2 s
SET
  speed = CASE lower(c.name)
    WHEN 'bloodstained mire' THEN 'land_drop'
    ELSE 'board_speed'
  END,
  mana_efficiency = 'free_or_land',
  card_advantage_type = 'none',
  interaction_scope = 'none',
  combo_piece = FALSE,
  wincon = FALSE,
  engine = FALSE,
  payoff = FALSE,
  enabler = CASE lower(c.name)
    WHEN 'lotus petal' THEN TRUE
    ELSE FALSE
  END,
  protection_type = 'none',
  recursion_type = 'none',
  role_confidence = CASE lower(c.name)
    WHEN 'bloodstained mire' THEN 1.0
    ELSE 0.88
  END,
  explanation_reason = CASE lower(c.name)
    WHEN 'bloodstained mire' THEN 'land_or_mana_source'
    ELSE 'mana_acceleration_or_land_search'
  END,
  tags = CASE lower(c.name)
    WHEN 'bloodstained mire' THEN
      '[{"tag":"land","confidence":1.0,"evidence":"type_line_land"}]'::jsonb
    ELSE
      '[{"tag":"ramp","confidence":0.88,"evidence":"mana_or_land_ramp_text"}]'::jsonb
  END,
  updated_at = now()
FROM public.cards c
WHERE s.card_id = c.id
  AND lower(c.name) IN ('bloodstained mire', 'lotus petal')
  AND s.source = 'deterministic_semantic_v2'
  AND s.schema_version = 'semantic_layer_v2_2026_05_18';

DO $$
DECLARE
  v_bad bigint;
BEGIN
  SELECT count(*)
  INTO v_bad
  FROM public.cards c
  JOIN public.card_semantic_tags_v2 s ON s.card_id = c.id
  WHERE s.source = 'deterministic_semantic_v2'
    AND lower(c.name) IN ('bloodstained mire', 'lotus petal')
    AND (
      (lower(c.name) = 'bloodstained mire' AND (
        s.tags <> '[{"tag":"land","confidence":1.0,"evidence":"type_line_land"}]'::jsonb
        OR s.enabler
        OR s.explanation_reason <> 'land_or_mana_source'
      ))
      OR
      (lower(c.name) = 'lotus petal' AND (
        s.tags <> '[{"tag":"ramp","confidence":0.88,"evidence":"mana_or_land_ramp_text"}]'::jsonb
        OR NOT s.enabler
        OR s.explanation_reason <> 'mana_acceleration_or_land_search'
      ))
    );
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'PG872 abort: % semantic rows diverged after update', v_bad;
  END IF;
END $$;

COMMIT;
