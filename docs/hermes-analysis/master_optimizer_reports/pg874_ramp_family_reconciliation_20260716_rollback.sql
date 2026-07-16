-- MUTATING ROLLBACK. Restores the exact PG874 snapshots.
BEGIN;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg874_ramp_target_20260716') IS NULL
     OR to_regclass('manaloom_deploy_audit.pg874_ramp_function_backup_20260716') IS NULL
     OR to_regclass('manaloom_deploy_audit.pg874_ramp_role_backup_20260716') IS NULL
     OR to_regclass('manaloom_deploy_audit.pg874_ramp_semantic_backup_20260716') IS NULL
     OR to_regclass('manaloom_deploy_audit.pg874_ramp_post_semantic_20260716') IS NULL THEN
    RAISE EXCEPTION 'PG874 rollback abort: required audit tables are missing';
  END IF;
  IF EXISTS(
    SELECT 1 FROM public.card_function_tags f JOIN manaloom_deploy_audit.pg874_ramp_target_20260716 t USING(card_id)
    WHERE f.tag='ramp' AND f.source IN('deterministic_heuristic_v1','deterministic_semantic_v2')
  ) OR EXISTS(
    SELECT 1 FROM public.card_role_scores r JOIN manaloom_deploy_audit.pg874_ramp_target_20260716 t USING(card_id)
    WHERE r.role='ramp' AND r.source='deterministic_heuristic_v1'
  ) OR EXISTS(
    SELECT 1 FROM public.card_semantic_tags_v2 s JOIN manaloom_deploy_audit.pg874_ramp_target_20260716 t USING(card_id)
    WHERE s.source='deterministic_semantic_v2' AND s.tags @> '[{"tag":"ramp"}]'::jsonb
  ) THEN
    RAISE EXCEPTION 'PG874 rollback abort: target ramp rows changed after apply';
  END IF;
  IF EXISTS(
    (SELECT s.* FROM public.card_semantic_tags_v2 s JOIN manaloom_deploy_audit.pg874_ramp_post_semantic_20260716 p ON p.card_id=s.card_id AND p.source=s.source EXCEPT SELECT p.* FROM manaloom_deploy_audit.pg874_ramp_post_semantic_20260716 p)
    UNION ALL
    (SELECT p.* FROM manaloom_deploy_audit.pg874_ramp_post_semantic_20260716 p EXCEPT SELECT s.* FROM public.card_semantic_tags_v2 s JOIN manaloom_deploy_audit.pg874_ramp_post_semantic_20260716 x ON x.card_id=s.card_id AND x.source=s.source)
  ) THEN
    RAISE EXCEPTION 'PG874 rollback abort: post semantic snapshot changed';
  END IF;
END $$;

DELETE FROM public.card_function_tags f
USING manaloom_deploy_audit.pg874_ramp_target_20260716 t
WHERE f.card_id=t.card_id AND f.tag='ramp'
  AND f.source IN('deterministic_heuristic_v1','deterministic_semantic_v2');
INSERT INTO public.card_function_tags
SELECT * FROM manaloom_deploy_audit.pg874_ramp_function_backup_20260716;

DELETE FROM public.card_role_scores r
USING manaloom_deploy_audit.pg874_ramp_target_20260716 t
WHERE r.card_id=t.card_id AND r.role='ramp' AND r.source='deterministic_heuristic_v1';
INSERT INTO public.card_role_scores
SELECT * FROM manaloom_deploy_audit.pg874_ramp_role_backup_20260716;

DELETE FROM public.card_semantic_tags_v2 s
USING manaloom_deploy_audit.pg874_ramp_semantic_backup_20260716 b
WHERE s.card_id=b.card_id AND s.source=b.source;
INSERT INTO public.card_semantic_tags_v2
SELECT * FROM manaloom_deploy_audit.pg874_ramp_semantic_backup_20260716;

DO $$
DECLARE hc bigint; hsha text; rc bigint; rsha text; sc bigint; ssha text; jc bigint; jsha text;
BEGIN
  IF EXISTS(
    (SELECT f.* FROM public.card_function_tags f JOIN manaloom_deploy_audit.pg874_ramp_function_backup_20260716 b ON b.card_id=f.card_id AND b.tag=f.tag AND b.source=f.source EXCEPT SELECT b.* FROM manaloom_deploy_audit.pg874_ramp_function_backup_20260716 b)
    UNION ALL
    (SELECT b.* FROM manaloom_deploy_audit.pg874_ramp_function_backup_20260716 b EXCEPT SELECT f.* FROM public.card_function_tags f JOIN manaloom_deploy_audit.pg874_ramp_function_backup_20260716 x ON x.card_id=f.card_id AND x.tag=f.tag AND x.source=f.source)
  ) THEN RAISE EXCEPTION 'PG874 rollback abort: function restore differs from snapshot'; END IF;
  IF EXISTS(
    (SELECT r.* FROM public.card_role_scores r JOIN manaloom_deploy_audit.pg874_ramp_role_backup_20260716 b ON b.card_id=r.card_id AND b.role=r.role AND b.source=r.source AND b.format=r.format AND b.subformat=r.subformat AND b.bracket_scope=r.bracket_scope EXCEPT SELECT b.* FROM manaloom_deploy_audit.pg874_ramp_role_backup_20260716 b)
    UNION ALL
    (SELECT b.* FROM manaloom_deploy_audit.pg874_ramp_role_backup_20260716 b EXCEPT SELECT r.* FROM public.card_role_scores r JOIN manaloom_deploy_audit.pg874_ramp_role_backup_20260716 x ON x.card_id=r.card_id AND x.role=r.role AND x.source=r.source AND x.format=r.format AND x.subformat=r.subformat AND x.bracket_scope=r.bracket_scope)
  ) THEN RAISE EXCEPTION 'PG874 rollback abort: role restore differs from snapshot'; END IF;
  IF EXISTS(
    (SELECT s.* FROM public.card_semantic_tags_v2 s JOIN manaloom_deploy_audit.pg874_ramp_semantic_backup_20260716 b ON b.card_id=s.card_id AND b.source=s.source EXCEPT SELECT b.* FROM manaloom_deploy_audit.pg874_ramp_semantic_backup_20260716 b)
    UNION ALL
    (SELECT b.* FROM manaloom_deploy_audit.pg874_ramp_semantic_backup_20260716 b EXCEPT SELECT s.* FROM public.card_semantic_tags_v2 s JOIN manaloom_deploy_audit.pg874_ramp_semantic_backup_20260716 x ON x.card_id=s.card_id AND x.source=s.source)
  ) THEN RAISE EXCEPTION 'PG874 rollback abort: semantic restore differs from snapshot'; END IF;
  SELECT count(*),encode(digest(string_agg(card_id::text,E'\n' ORDER BY card_id::text),'sha256'),'hex') INTO hc,hsha FROM public.card_function_tags WHERE tag='ramp' AND source='deterministic_heuristic_v1';
  SELECT count(*),encode(digest(string_agg(card_id::text||'|'||format||'|'||subformat||'|'||bracket_scope||'|'||budget_tier,E'\n' ORDER BY card_id::text||'|'||format||'|'||subformat||'|'||bracket_scope||'|'||budget_tier),'sha256'),'hex') INTO rc,rsha FROM public.card_role_scores WHERE role='ramp' AND source='deterministic_heuristic_v1';
  SELECT count(*),encode(digest(string_agg(card_id::text,E'\n' ORDER BY card_id::text),'sha256'),'hex') INTO sc,ssha FROM public.card_function_tags WHERE tag='ramp' AND source='deterministic_semantic_v2';
  SELECT count(*),encode(digest(string_agg(card_id::text,E'\n' ORDER BY card_id::text),'sha256'),'hex') INTO jc,jsha FROM public.card_semantic_tags_v2 WHERE source='deterministic_semantic_v2' AND schema_version='semantic_layer_v2_2026_05_18' AND tags @> '[{"tag":"ramp"}]'::jsonb;
  IF hc<>3092 OR hsha<>'34f277dc0d165a1974ad3d75906b2936189429ddcdcc2c01192d31a1d7493c57'
     OR rc<>3124 OR rsha<>'89231cb02e08b0870817e966259390f10549ceec6f434c6786574a3f2266e4da'
     OR sc<>3246 OR ssha<>'3df0ec525741d709408d35648ac31d15d705fd73b43e044421bc782b53f8a13c'
     OR jc<>3246 OR jsha<>'3df0ec525741d709408d35648ac31d15d705fd73b43e044421bc782b53f8a13c' THEN
    RAISE EXCEPTION 'PG874 rollback abort: restored counts/hashes diverged';
  END IF;
END $$;
COMMIT;
