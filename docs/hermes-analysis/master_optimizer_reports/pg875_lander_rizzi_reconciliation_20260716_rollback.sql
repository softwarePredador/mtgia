-- MUTATING ROLLBACK. Restores the exact PG875 deterministic snapshots.

BEGIN;

LOCK TABLE public.cards IN SHARE MODE;
LOCK TABLE public.card_meta_insights IN SHARE MODE;
LOCK TABLE public.card_function_tags IN SHARE ROW EXCLUSIVE MODE;
LOCK TABLE public.card_role_scores IN SHARE ROW EXCLUSIVE MODE;
LOCK TABLE public.card_semantic_tags_v2 IN SHARE ROW EXCLUSIVE MODE;

DO $$
BEGIN
  IF to_regclass(
       'manaloom_deploy_audit.pg875_lander_target_20260716'
     ) IS NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg875_lander_function_backup_20260716'
     ) IS NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg875_lander_role_backup_20260716'
     ) IS NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg875_lander_semantic_backup_20260716'
     ) IS NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg875_lander_function_untouched_20260716'
     ) IS NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg875_lander_role_untouched_20260716'
     ) IS NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg875_lander_semantic_untouched_20260716'
     ) IS NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg875_lander_function_post_20260716'
     ) IS NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg875_lander_role_post_20260716'
     ) IS NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg875_lander_semantic_post_20260716'
     ) IS NULL THEN
    RAISE EXCEPTION 'PG875 rollback abort: required audit tables are missing';
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    (
      SELECT f.*
      FROM public.card_function_tags f
      WHERE f.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
        AND f.source IN (
          'deterministic_heuristic_v1', 'deterministic_semantic_v2'
        )
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg875_lander_function_post_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg875_lander_function_post_20260716
      EXCEPT
      SELECT f.*
      FROM public.card_function_tags f
      WHERE f.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
        AND f.source IN (
          'deterministic_heuristic_v1', 'deterministic_semantic_v2'
        )
    )
  ) THEN
    RAISE EXCEPTION 'PG875 rollback abort: current function poststate drifted';
  END IF;

  IF EXISTS (
    (
      SELECT r.*
      FROM public.card_role_scores r
      WHERE r.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
        AND r.source = 'deterministic_heuristic_v1'
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg875_lander_role_post_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg875_lander_role_post_20260716
      EXCEPT
      SELECT r.*
      FROM public.card_role_scores r
      WHERE r.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
        AND r.source = 'deterministic_heuristic_v1'
    )
  ) THEN
    RAISE EXCEPTION 'PG875 rollback abort: current role poststate drifted';
  END IF;

  IF EXISTS (
    (
      SELECT s.*
      FROM public.card_semantic_tags_v2 s
      WHERE s.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
        AND s.source = 'deterministic_semantic_v2'
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg875_lander_semantic_post_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg875_lander_semantic_post_20260716
      EXCEPT
      SELECT s.*
      FROM public.card_semantic_tags_v2 s
      WHERE s.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
        AND s.source = 'deterministic_semantic_v2'
    )
  ) THEN
    RAISE EXCEPTION 'PG875 rollback abort: current semantic poststate drifted';
  END IF;

  IF EXISTS (
    (
      SELECT f.*
      FROM public.card_function_tags f
      WHERE f.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
        AND f.source NOT IN (
          'deterministic_heuristic_v1', 'deterministic_semantic_v2'
        )
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg875_lander_function_untouched_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg875_lander_function_untouched_20260716
      EXCEPT
      SELECT f.*
      FROM public.card_function_tags f
      WHERE f.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
        AND f.source NOT IN (
          'deterministic_heuristic_v1', 'deterministic_semantic_v2'
        )
    )
  ) OR EXISTS (
    (
      SELECT r.*
      FROM public.card_role_scores r
      WHERE r.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
        AND r.source <> 'deterministic_heuristic_v1'
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg875_lander_role_untouched_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg875_lander_role_untouched_20260716
      EXCEPT
      SELECT r.*
      FROM public.card_role_scores r
      WHERE r.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
        AND r.source <> 'deterministic_heuristic_v1'
    )
  ) OR EXISTS (
    (
      SELECT s.*
      FROM public.card_semantic_tags_v2 s
      WHERE s.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
        AND s.source <> 'deterministic_semantic_v2'
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg875_lander_semantic_untouched_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg875_lander_semantic_untouched_20260716
      EXCEPT
      SELECT s.*
      FROM public.card_semantic_tags_v2 s
      WHERE s.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
        AND s.source <> 'deterministic_semantic_v2'
    )
  ) THEN
    RAISE EXCEPTION 'PG875 rollback abort: a non-target source changed';
  END IF;

  IF EXISTS (
    (
      SELECT
        c.id AS card_id,
        c.name,
        coalesce(c.type_line, '') AS type_line,
        coalesce(c.oracle_text, '') AS oracle_text,
        coalesce(c.mana_cost, '') AS mana_cost,
        c.cmc,
        m.usage_count,
        m.meta_deck_count
      FROM public.cards c
      JOIN public.card_meta_insights m
        ON lower(m.card_name) = lower(c.name)
      WHERE c.id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg875_lander_target_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg875_lander_target_20260716
      EXCEPT
      SELECT
        c.id AS card_id,
        c.name,
        coalesce(c.type_line, '') AS type_line,
        coalesce(c.oracle_text, '') AS oracle_text,
        coalesce(c.mana_cost, '') AS mana_cost,
        c.cmc,
        m.usage_count,
        m.meta_deck_count
      FROM public.cards c
      JOIN public.card_meta_insights m
        ON lower(m.card_name) = lower(c.name)
      WHERE c.id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
    )
  ) THEN
    RAISE EXCEPTION 'PG875 rollback abort: card or meta input changed';
  END IF;
END $$;

DELETE FROM public.card_function_tags
WHERE card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
  AND source IN (
    'deterministic_heuristic_v1',
    'deterministic_semantic_v2'
  );

INSERT INTO public.card_function_tags (
  card_id, card_name, tag, confidence, source, evidence, updated_at
)
SELECT
  card_id, card_name, tag, confidence, source, evidence, updated_at
FROM manaloom_deploy_audit.pg875_lander_function_backup_20260716;

DELETE FROM public.card_role_scores
WHERE card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
  AND source = 'deterministic_heuristic_v1';

INSERT INTO public.card_role_scores (
  card_id, card_name, role, score, format, subformat, bracket_scope,
  budget_tier, source, evidence, updated_at
)
SELECT
  card_id, card_name, role, score, format, subformat, bracket_scope,
  budget_tier, source, evidence, updated_at
FROM manaloom_deploy_audit.pg875_lander_role_backup_20260716;

DELETE FROM public.card_semantic_tags_v2
WHERE card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
  AND source = 'deterministic_semantic_v2';

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
FROM manaloom_deploy_audit.pg875_lander_semantic_backup_20260716;

DO $$
DECLARE
  v_function_count bigint;
  v_function_sha text;
  v_role_count bigint;
  v_role_sha text;
  v_semantic_count bigint;
  v_semantic_sha text;
BEGIN
  IF EXISTS (
    (
      SELECT f.*
      FROM public.card_function_tags f
      WHERE f.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
        AND f.source IN (
          'deterministic_heuristic_v1', 'deterministic_semantic_v2'
        )
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg875_lander_function_backup_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg875_lander_function_backup_20260716
      EXCEPT
      SELECT f.*
      FROM public.card_function_tags f
      WHERE f.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
        AND f.source IN (
          'deterministic_heuristic_v1', 'deterministic_semantic_v2'
        )
    )
  ) THEN
    RAISE EXCEPTION 'PG875 rollback abort: function restore differs';
  END IF;

  IF EXISTS (
    (
      SELECT r.*
      FROM public.card_role_scores r
      WHERE r.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
        AND r.source = 'deterministic_heuristic_v1'
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg875_lander_role_backup_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg875_lander_role_backup_20260716
      EXCEPT
      SELECT r.*
      FROM public.card_role_scores r
      WHERE r.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
        AND r.source = 'deterministic_heuristic_v1'
    )
  ) THEN
    RAISE EXCEPTION 'PG875 rollback abort: role restore differs';
  END IF;

  IF EXISTS (
    (
      SELECT s.*
      FROM public.card_semantic_tags_v2 s
      WHERE s.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
        AND s.source = 'deterministic_semantic_v2'
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg875_lander_semantic_backup_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg875_lander_semantic_backup_20260716
      EXCEPT
      SELECT s.*
      FROM public.card_semantic_tags_v2 s
      WHERE s.card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
        AND s.source = 'deterministic_semantic_v2'
    )
  ) THEN
    RAISE EXCEPTION 'PG875 rollback abort: semantic restore differs';
  END IF;

  SELECT
    count(*),
    encode(digest(string_agg(
      concat_ws(
        '|', card_id::text, card_name, tag, confidence::text, source,
        evidence
      ), E'\n' ORDER BY source, tag
    ), 'sha256'), 'hex')
  INTO v_function_count, v_function_sha
  FROM public.card_function_tags
  WHERE card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
    AND source IN (
      'deterministic_heuristic_v1', 'deterministic_semantic_v2'
    );

  SELECT
    count(*),
    encode(digest(string_agg(
      concat_ws(
        '|', card_id::text, card_name, role, score::text, format,
        subformat, bracket_scope, budget_tier, source, evidence
      ), E'\n' ORDER BY source, role, format, subformat, bracket_scope,
        budget_tier
    ), 'sha256'), 'hex')
  INTO v_role_count, v_role_sha
  FROM public.card_role_scores
  WHERE card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
    AND source = 'deterministic_heuristic_v1';

  SELECT
    count(*),
    encode(digest(string_agg(
      concat_ws(
        '|', card_id::text, card_name, schema_version, speed,
        mana_efficiency, card_advantage_type, interaction_scope,
        combo_piece::text, wincon::text, engine::text, payoff::text,
        enabler::text, protection_type, recursion_type,
        role_confidence::text, explanation_reason, tags::text, source
      ), E'\n' ORDER BY source, schema_version
    ), 'sha256'), 'hex')
  INTO v_semantic_count, v_semantic_sha
  FROM public.card_semantic_tags_v2
  WHERE card_id = '1f10f7b7-a895-4a76-9d64-7751eced092e'::uuid
    AND source = 'deterministic_semantic_v2';

  IF v_function_count <> 11
     OR v_function_sha <>
       '940bfb92b0dd23af72999cff33de4dfd6de5cbb00581f0edb421c01609e7d2f7'
     OR v_role_count <> 4
     OR v_role_sha <>
       '99f4819e273c273bc5dc15ef8db0251a8c376fa13b0c76029b90596350ea3f6d'
     OR v_semantic_count <> 1
     OR v_semantic_sha <>
       '0fc3a335e8d7184782c666fb4a7b1269cf636b244371cd4aceb5fef9547c66c2'
  THEN
    RAISE EXCEPTION
      'PG875 rollback abort: restored hashes diverged f=% r=% s=%',
      v_function_count, v_role_count, v_semantic_count;
  END IF;
END $$;

COMMIT;
