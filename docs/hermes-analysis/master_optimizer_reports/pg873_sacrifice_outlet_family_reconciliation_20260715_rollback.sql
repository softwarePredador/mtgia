-- MUTATING. Requires explicit PostgreSQL approval for this execution.
-- Exact rollback for the PG873 package; aborts if post-apply target rows drifted.
\set ON_ERROR_STOP on
BEGIN;
SET LOCAL statement_timeout = '5min';
SET LOCAL lock_timeout = '15s';

LOCK TABLE public.card_function_tags IN SHARE ROW EXCLUSIVE MODE;
LOCK TABLE public.card_semantic_tags_v2 IN SHARE ROW EXCLUSIVE MODE;

DO $$
DECLARE
  v_h_count bigint;
  v_s_count bigint;
  v_h_sha text;
  v_s_sha text;
  v_deferred_sha text;
  v_bad bigint;
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg873_sac_outlet_expected_20260715') IS NULL
     OR to_regclass('manaloom_deploy_audit.pg873_sac_outlet_function_backup_20260715') IS NULL
     OR to_regclass('manaloom_deploy_audit.pg873_sac_outlet_semantic_backup_20260715') IS NULL
     OR to_regclass('manaloom_deploy_audit.pg873_sac_outlet_deferred_semantic_20260715') IS NULL
     OR to_regclass('manaloom_deploy_audit.pg873_sac_outlet_post_semantic_20260715') IS NULL THEN
    RAISE EXCEPTION 'PG873 rollback abort: audit tables are missing';
  END IF;

  IF (SELECT count(*) FROM manaloom_deploy_audit.pg873_sac_outlet_expected_20260715) <> 1400
     OR (SELECT count(*) FROM manaloom_deploy_audit.pg873_sac_outlet_function_backup_20260715) <> 2737
     OR (SELECT count(*) FROM manaloom_deploy_audit.pg873_sac_outlet_semantic_backup_20260715) <> 1557
     OR (SELECT count(*) FROM manaloom_deploy_audit.pg873_sac_outlet_deferred_semantic_20260715) <> 52
     OR (SELECT count(*) FROM manaloom_deploy_audit.pg873_sac_outlet_post_semantic_20260715) <> 1524 THEN
    RAISE EXCEPTION 'PG873 rollback abort: audit table counts drifted';
  END IF;

  SELECT encode(digest(string_agg(card_id::text, E'\n' ORDER BY card_id::text), 'sha256'), 'hex')
  INTO v_deferred_sha
  FROM manaloom_deploy_audit.pg873_sac_outlet_deferred_semantic_20260715;
  IF v_deferred_sha <> '4f29cbcbbdaa9a10bf285ff808c40ab8f3026367a2b3bc873fd51424cad5b199' THEN
    RAISE EXCEPTION 'PG873 rollback abort: deferred semantic backlog hash drifted';
  END IF;

  SELECT count(*), encode(digest(string_agg(card_id::text, E'\n' ORDER BY card_id::text), 'sha256'), 'hex')
  INTO v_h_count, v_h_sha
  FROM public.card_function_tags
  WHERE tag='sacrifice_outlet' AND source='deterministic_heuristic_v1';
  SELECT count(*), encode(digest(string_agg(card_id::text, E'\n' ORDER BY card_id::text), 'sha256'), 'hex')
  INTO v_s_count, v_s_sha
  FROM public.card_function_tags
  WHERE tag='sacrifice_outlet' AND source='deterministic_semantic_v2';

  IF v_h_count<>716
     OR v_h_sha<>'51272701cdb5b277a2007de43c418c418fab5380409fc16c08ac527fd1ddacbd'
     OR v_s_count<>684
     OR v_s_sha<>'573c94fad8b4ba9d9789daadd506e4ce2b0143dfa0d049eb8687c4c8cd90e8bd' THEN
    RAISE EXCEPTION 'PG873 rollback abort: current function state is not the applied package';
  END IF;

  SELECT count(*) INTO v_bad
  FROM public.card_function_tags
  WHERE tag='sacrifice_outlet'
    AND source IN ('deterministic_heuristic_v1','deterministic_semantic_v2')
    AND (confidence<>0.8 OR evidence IS DISTINCT FROM 'external_activated_sacrifice_outlet_cost');
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'PG873 rollback abort: % current function rows drifted', v_bad;
  END IF;

  IF EXISTS (
    SELECT s.*
    FROM public.card_semantic_tags_v2 s
    JOIN manaloom_deploy_audit.pg873_sac_outlet_post_semantic_20260715 p
      ON p.card_id=s.card_id AND p.source=s.source
    EXCEPT
    SELECT p.* FROM manaloom_deploy_audit.pg873_sac_outlet_post_semantic_20260715 p
  ) OR EXISTS (
    SELECT p.* FROM manaloom_deploy_audit.pg873_sac_outlet_post_semantic_20260715 p
    EXCEPT
    SELECT s.*
    FROM public.card_semantic_tags_v2 s
    JOIN manaloom_deploy_audit.pg873_sac_outlet_post_semantic_20260715 p
      ON p.card_id=s.card_id AND p.source=s.source
  ) THEN
    RAISE EXCEPTION 'PG873 rollback abort: current semantic target rows drifted';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM manaloom_deploy_audit.pg873_sac_outlet_semantic_backup_20260715 b
    WHERE NOT EXISTS (
      SELECT 1 FROM manaloom_deploy_audit.pg873_sac_outlet_post_semantic_20260715 p
      WHERE p.card_id=b.card_id
    )
      AND EXISTS (
        SELECT 1 FROM public.card_semantic_tags_v2 s
        WHERE s.card_id=b.card_id AND s.source='deterministic_semantic_v2'
      )
  ) THEN
    RAISE EXCEPTION 'PG873 rollback abort: a deliberately deleted semantic row reappeared';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM manaloom_deploy_audit.pg873_sac_outlet_deferred_semantic_20260715 d
    JOIN public.card_semantic_tags_v2 s
      ON s.card_id=d.card_id AND s.source='deterministic_semantic_v2'
  ) THEN
    RAISE EXCEPTION 'PG873 rollback abort: deferred semantic backlog changed';
  END IF;
END $$;

DELETE FROM public.card_function_tags f
WHERE f.tag='sacrifice_outlet'
  AND f.source IN ('deterministic_heuristic_v1','deterministic_semantic_v2');

INSERT INTO public.card_function_tags (
  card_id, card_name, tag, confidence, source, evidence, updated_at
)
SELECT card_id, card_name, tag, confidence, source, evidence, updated_at
FROM manaloom_deploy_audit.pg873_sac_outlet_function_backup_20260715;

DELETE FROM public.card_semantic_tags_v2 s
USING manaloom_deploy_audit.pg873_sac_outlet_semantic_backup_20260715 target
WHERE s.card_id=target.card_id
  AND s.source='deterministic_semantic_v2';

INSERT INTO public.card_semantic_tags_v2 (
  card_id, card_name, schema_version, speed, mana_efficiency,
  card_advantage_type, interaction_scope, combo_piece, wincon, engine,
  payoff, enabler, protection_type, recursion_type, role_confidence,
  explanation_reason, tags, source, updated_at
)
SELECT
  card_id, card_name, schema_version, speed, mana_efficiency,
  card_advantage_type, interaction_scope, combo_piece, wincon, engine,
  payoff, enabler, protection_type, recursion_type, role_confidence,
  explanation_reason, tags, source, updated_at
FROM manaloom_deploy_audit.pg873_sac_outlet_semantic_backup_20260715;

DO $$
DECLARE
  v_h_count bigint;
  v_s_count bigint;
  v_h_sha text;
  v_s_sha text;
  v_json_count bigint;
  v_json_sha text;
BEGIN
  IF EXISTS (
    SELECT f.*
    FROM public.card_function_tags f
    WHERE f.tag='sacrifice_outlet'
      AND f.source IN ('deterministic_heuristic_v1','deterministic_semantic_v2')
    EXCEPT
    SELECT b.* FROM manaloom_deploy_audit.pg873_sac_outlet_function_backup_20260715 b
  ) OR EXISTS (
    SELECT b.* FROM manaloom_deploy_audit.pg873_sac_outlet_function_backup_20260715 b
    EXCEPT
    SELECT f.*
    FROM public.card_function_tags f
    WHERE f.tag='sacrifice_outlet'
      AND f.source IN ('deterministic_heuristic_v1','deterministic_semantic_v2')
  ) THEN
    RAISE EXCEPTION 'PG873 rollback abort: function restore differs from snapshot';
  END IF;

  IF EXISTS (
    SELECT s.*
    FROM public.card_semantic_tags_v2 s
    JOIN manaloom_deploy_audit.pg873_sac_outlet_semantic_backup_20260715 b
      ON b.card_id=s.card_id AND b.source=s.source
    EXCEPT
    SELECT b.* FROM manaloom_deploy_audit.pg873_sac_outlet_semantic_backup_20260715 b
  ) OR EXISTS (
    SELECT b.* FROM manaloom_deploy_audit.pg873_sac_outlet_semantic_backup_20260715 b
    EXCEPT
    SELECT s.*
    FROM public.card_semantic_tags_v2 s
    JOIN manaloom_deploy_audit.pg873_sac_outlet_semantic_backup_20260715 b
      ON b.card_id=s.card_id AND b.source=s.source
  ) OR EXISTS (
    SELECT 1
    FROM public.card_semantic_tags_v2 s
    JOIN manaloom_deploy_audit.pg873_sac_outlet_deferred_semantic_20260715 m
      ON m.card_id=s.card_id
    WHERE s.source='deterministic_semantic_v2'
  ) THEN
    RAISE EXCEPTION 'PG873 rollback abort: semantic restore differs from snapshot';
  END IF;

  SELECT count(*), encode(digest(string_agg(card_id::text, E'\n' ORDER BY card_id::text), 'sha256'), 'hex')
  INTO v_h_count, v_h_sha
  FROM public.card_function_tags
  WHERE tag='sacrifice_outlet' AND source='deterministic_heuristic_v1';
  SELECT count(*), encode(digest(string_agg(card_id::text, E'\n' ORDER BY card_id::text), 'sha256'), 'hex')
  INTO v_s_count, v_s_sha
  FROM public.card_function_tags
  WHERE tag='sacrifice_outlet' AND source='deterministic_semantic_v2';
  SELECT count(*), encode(digest(string_agg(card_id::text, E'\n' ORDER BY card_id::text), 'sha256'), 'hex')
  INTO v_json_count, v_json_sha
  FROM public.card_semantic_tags_v2
  WHERE source='deterministic_semantic_v2'
    AND schema_version='semantic_layer_v2_2026_05_18'
    AND tags @> '[{"tag":"sacrifice_outlet"}]'::jsonb;

  IF v_h_count<>1357
     OR v_h_sha<>'5986c9df6c911b8c8aa24744ccc57c2e93e9d3421b716b7c302f95192f17d046'
     OR v_s_count<>1380
     OR v_s_sha<>'cdc90bbc3d1b55b42050081cb6c1352937a3df4a2187ea0e34434270a3695d7e'
     OR v_json_count<>1380
     OR v_json_sha<>'cdc90bbc3d1b55b42050081cb6c1352937a3df4a2187ea0e34434270a3695d7e' THEN
    RAISE EXCEPTION 'PG873 rollback abort: restored counts/hashes diverged';
  END IF;
END $$;

COMMIT;
