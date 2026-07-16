-- READ ONLY. PG872 postcheck.
BEGIN TRANSACTION READ ONLY;

DO $$
DECLARE
  v_semantic_bad bigint;
  v_function_bad bigint;
  v_snapshot_semantic bigint;
  v_snapshot_function bigint;
BEGIN
  SELECT count(*)
  INTO v_semantic_bad
  FROM public.cards c
  JOIN public.card_semantic_tags_v2 s ON s.card_id = c.id
  WHERE s.source = 'deterministic_semantic_v2'
    AND lower(c.name) IN ('bloodstained mire', 'lotus petal')
    AND (
      (lower(c.name) = 'bloodstained mire' AND (
        s.tags <> '[{"tag":"land","confidence":1.0,"evidence":"type_line_land"}]'::jsonb
        OR s.enabler
        OR s.role_confidence <> 1.0
        OR s.explanation_reason <> 'land_or_mana_source'
      ))
      OR
      (lower(c.name) = 'lotus petal' AND (
        s.tags <> '[{"tag":"ramp","confidence":0.88,"evidence":"mana_or_land_ramp_text"}]'::jsonb
        OR NOT s.enabler
        OR s.role_confidence <> 0.88
        OR s.explanation_reason <> 'mana_acceleration_or_land_search'
      ))
    );

  SELECT count(*)
  INTO v_function_bad
  FROM public.cards c
  JOIN public.card_function_tags f ON f.card_id = c.id
  WHERE (lower(c.name) = 'bloodstained mire'
         AND f.tag IN ('ramp', 'enabler')
         AND f.source IN ('deterministic_heuristic_v1', 'deterministic_semantic_v2'))
     OR (lower(c.name) = 'lotus petal'
         AND f.tag IN ('sacrifice', 'sacrifice_outlet')
         AND f.source IN ('deterministic_heuristic_v1', 'deterministic_semantic_v2'));

  SELECT count(*) INTO v_snapshot_semantic
  FROM manaloom_deploy_audit.pg872_semantic_tag_false_positive_repair_20260715;
  SELECT count(*) INTO v_snapshot_function
  FROM manaloom_deploy_audit.pg872_function_tag_false_positive_repair_20260715;

  IF v_semantic_bad <> 0 OR v_function_bad <> 0
     OR v_snapshot_semantic <> 2 OR v_snapshot_function <> 1 THEN
    RAISE EXCEPTION
      'PG872 postcheck abort: semantic_bad=% function_bad=% snapshots=%/%',
      v_semantic_bad, v_function_bad, v_snapshot_semantic, v_snapshot_function;
  END IF;
END $$;

SELECT c.name, s.tags, s.enabler, s.role_confidence, s.explanation_reason
FROM public.cards c
JOIN public.card_semantic_tags_v2 s ON s.card_id = c.id
WHERE lower(c.name) IN ('bloodstained mire', 'lotus petal')
  AND s.source = 'deterministic_semantic_v2'
ORDER BY c.name;

ROLLBACK;
