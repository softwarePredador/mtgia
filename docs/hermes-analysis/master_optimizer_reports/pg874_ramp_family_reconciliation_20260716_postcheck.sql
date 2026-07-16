-- READ ONLY. Run only after an approved PG874 apply.
BEGIN TRANSACTION READ ONLY;

WITH metrics AS (
  SELECT
    (SELECT count(*) FROM manaloom_deploy_audit.pg874_ramp_target_20260716) tc,
    (SELECT encode(digest(string_agg(card_id::text,E'\n' ORDER BY card_id::text),'sha256'),'hex') FROM manaloom_deploy_audit.pg874_ramp_target_20260716) tsha,
    (SELECT count(*) FROM manaloom_deploy_audit.pg874_ramp_function_backup_20260716 WHERE source='deterministic_heuristic_v1') hbc,
    (SELECT count(*) FROM manaloom_deploy_audit.pg874_ramp_role_backup_20260716) rbc,
    (SELECT count(*) FROM manaloom_deploy_audit.pg874_ramp_function_backup_20260716 WHERE source='deterministic_semantic_v2') sbc,
    (SELECT count(*) FROM manaloom_deploy_audit.pg874_ramp_semantic_backup_20260716) sembc,
    (SELECT count(*) FROM manaloom_deploy_audit.pg874_ramp_post_semantic_20260716) postc,
    (SELECT count(*) FROM public.card_function_tags f JOIN manaloom_deploy_audit.pg874_ramp_target_20260716 t USING(card_id) WHERE f.tag='ramp' AND f.source IN('deterministic_heuristic_v1','deterministic_semantic_v2')) target_function_rows,
    (SELECT count(*) FROM public.card_role_scores r JOIN manaloom_deploy_audit.pg874_ramp_target_20260716 t USING(card_id) WHERE r.role='ramp' AND r.source='deterministic_heuristic_v1') target_role_rows,
    (SELECT count(*) FROM public.card_semantic_tags_v2 s JOIN manaloom_deploy_audit.pg874_ramp_target_20260716 t USING(card_id) WHERE s.source='deterministic_semantic_v2' AND s.tags @> '[{"tag":"ramp"}]'::jsonb) target_json_rows,
    (SELECT count(*) FROM public.card_function_tags WHERE tag='ramp' AND source='deterministic_heuristic_v1') hc,
    (SELECT encode(digest(string_agg(card_id::text,E'\n' ORDER BY card_id::text),'sha256'),'hex') FROM public.card_function_tags WHERE tag='ramp' AND source='deterministic_heuristic_v1') hsha,
    (SELECT count(*) FROM public.card_role_scores WHERE role='ramp' AND source='deterministic_heuristic_v1') rc,
    (SELECT encode(digest(string_agg(card_id::text||'|'||format||'|'||subformat||'|'||bracket_scope||'|'||budget_tier,E'\n' ORDER BY card_id::text||'|'||format||'|'||subformat||'|'||bracket_scope||'|'||budget_tier),'sha256'),'hex') FROM public.card_role_scores WHERE role='ramp' AND source='deterministic_heuristic_v1') rsha,
    (SELECT count(*) FROM public.card_function_tags WHERE tag='ramp' AND source='deterministic_semantic_v2') sc,
    (SELECT encode(digest(string_agg(card_id::text,E'\n' ORDER BY card_id::text),'sha256'),'hex') FROM public.card_function_tags WHERE tag='ramp' AND source='deterministic_semantic_v2') ssha,
    (SELECT count(*) FROM public.card_semantic_tags_v2 WHERE source='deterministic_semantic_v2' AND schema_version='semantic_layer_v2_2026_05_18' AND tags @> '[{"tag":"ramp"}]'::jsonb) jc,
    (SELECT encode(digest(string_agg(card_id::text,E'\n' ORDER BY card_id::text),'sha256'),'hex') FROM public.card_semantic_tags_v2 WHERE source='deterministic_semantic_v2' AND schema_version='semantic_layer_v2_2026_05_18' AND tags @> '[{"tag":"ramp"}]'::jsonb) jsha,
    (SELECT count(*) FROM (
      (SELECT s.* FROM public.card_semantic_tags_v2 s JOIN manaloom_deploy_audit.pg874_ramp_post_semantic_20260716 p ON p.card_id=s.card_id AND p.source=s.source EXCEPT SELECT p.* FROM manaloom_deploy_audit.pg874_ramp_post_semantic_20260716 p)
      UNION ALL
      (SELECT p.* FROM manaloom_deploy_audit.pg874_ramp_post_semantic_20260716 p EXCEPT SELECT s.* FROM public.card_semantic_tags_v2 s JOIN manaloom_deploy_audit.pg874_ramp_post_semantic_20260716 x ON x.card_id=s.card_id AND x.source=s.source)
    ) d) post_semantic_diff,
    (SELECT count(*) FROM public.card_semantic_tags_v2 s JOIN manaloom_deploy_audit.pg874_ramp_post_semantic_20260716 p ON p.card_id=s.card_id AND p.source=s.source
      WHERE s.role_confidence IS DISTINCT FROM coalesce((SELECT max((e->>'confidence')::numeric) FROM jsonb_array_elements(s.tags)e),0)
         OR s.enabler IS DISTINCT FROM (s.tags @> '[{"tag":"enabler"}]'::jsonb OR s.tags @> '[{"tag":"loot"}]'::jsonb OR s.tags @> '[{"tag":"tutor"}]'::jsonb)
         OR jsonb_array_length(s.tags)=0) derived_bad
)
SELECT *,CASE WHEN
  tc=1377 AND tsha='cebc65973dfb91315dae85510be400b2ed6bcad5e8cff765c5a2ed6db5b51123'
  AND hbc=1302 AND rbc=1322 AND sbc=1350 AND sembc=1350 AND postc=1349
  AND target_function_rows=0 AND target_role_rows=0 AND target_json_rows=0
  AND hc=1790 AND hsha='f6969e2506428916646afdcec3271b4174a65b35130f68a7033249a47aa0e37c'
  AND rc=1802 AND rsha='8f909dfbfb06b6e004419c2cb0ba296631e606653b7d58113d285ffbc9205b4f'
  AND sc=1896 AND ssha='3c0d4addbaf2d961bfc515ac8c81967e1371bca803865d54f6fae5f3bc35bef1'
  AND jc=1896 AND jsha='3c0d4addbaf2d961bfc515ac8c81967e1371bca803865d54f6fae5f3bc35bef1'
  AND post_semantic_diff=0 AND derived_bad=0
THEN 'PG874_POSTCHECK_PASS'
ELSE ('PG874_POSTCHECK_ABORT_'||tc::text)::integer::text END status
FROM metrics;

SELECT classification,count(*) FROM manaloom_deploy_audit.pg874_ramp_target_20260716 GROUP BY classification ORDER BY classification;
ROLLBACK;
