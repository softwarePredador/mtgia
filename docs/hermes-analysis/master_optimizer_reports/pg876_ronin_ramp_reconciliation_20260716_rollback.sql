-- MUTATING ROLLBACK. Restores the exact PG876 deterministic snapshots.

BEGIN;

LOCK TABLE public.cards IN SHARE MODE;
LOCK TABLE public.card_meta_insights IN SHARE MODE;
LOCK TABLE public.edhrec_card_snapshots IN SHARE MODE;
LOCK TABLE public.card_function_tags IN SHARE ROW EXCLUSIVE MODE;
LOCK TABLE public.card_role_scores IN SHARE ROW EXCLUSIVE MODE;
LOCK TABLE public.card_semantic_tags_v2 IN SHARE MODE;

DO $$
BEGIN
  IF to_regclass(
       'manaloom_deploy_audit.pg876_ronin_target_20260716'
     ) IS NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg876_ronin_function_backup_20260716'
     ) IS NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg876_ronin_role_backup_20260716'
     ) IS NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg876_ronin_function_untouched_20260716'
     ) IS NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg876_ronin_role_untouched_20260716'
     ) IS NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg876_ronin_function_post_20260716'
     ) IS NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg876_ronin_role_post_20260716'
     ) IS NULL THEN
    RAISE EXCEPTION 'PG876 rollback abort: required audit tables are missing';
  END IF;
END $$;

DO $$
DECLARE
  v_target_count bigint;
  v_target_sha text;
BEGIN
  IF EXISTS (
    (
      SELECT f.*
      FROM public.card_function_tags f
      WHERE f.card_id = '115df6db-5280-4223-921b-dc4f591841f2'::uuid
        AND f.source = 'deterministic_heuristic_v1'
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg876_ronin_function_post_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg876_ronin_function_post_20260716
      EXCEPT
      SELECT f.*
      FROM public.card_function_tags f
      WHERE f.card_id = '115df6db-5280-4223-921b-dc4f591841f2'::uuid
        AND f.source = 'deterministic_heuristic_v1'
    )
  ) THEN
    RAISE EXCEPTION 'PG876 rollback abort: current function poststate drifted';
  END IF;

  IF EXISTS (
    (
      SELECT r.*
      FROM public.card_role_scores r
      WHERE r.card_id = '115df6db-5280-4223-921b-dc4f591841f2'::uuid
        AND r.source = 'deterministic_heuristic_v1'
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg876_ronin_role_post_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg876_ronin_role_post_20260716
      EXCEPT
      SELECT r.*
      FROM public.card_role_scores r
      WHERE r.card_id = '115df6db-5280-4223-921b-dc4f591841f2'::uuid
        AND r.source = 'deterministic_heuristic_v1'
    )
  ) THEN
    RAISE EXCEPTION 'PG876 rollback abort: current role poststate drifted';
  END IF;

  IF EXISTS (
    (
      SELECT f.*
      FROM public.card_function_tags f
      WHERE f.card_id = '115df6db-5280-4223-921b-dc4f591841f2'::uuid
        AND f.source <> 'deterministic_heuristic_v1'
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg876_ronin_function_untouched_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg876_ronin_function_untouched_20260716
      EXCEPT
      SELECT f.*
      FROM public.card_function_tags f
      WHERE f.card_id = '115df6db-5280-4223-921b-dc4f591841f2'::uuid
        AND f.source <> 'deterministic_heuristic_v1'
    )
  ) OR EXISTS (
    (
      SELECT r.*
      FROM public.card_role_scores r
      WHERE r.card_id = '115df6db-5280-4223-921b-dc4f591841f2'::uuid
        AND r.source <> 'deterministic_heuristic_v1'
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg876_ronin_role_untouched_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg876_ronin_role_untouched_20260716
      EXCEPT
      SELECT r.*
      FROM public.card_role_scores r
      WHERE r.card_id = '115df6db-5280-4223-921b-dc4f591841f2'::uuid
        AND r.source <> 'deterministic_heuristic_v1'
    )
  ) THEN
    RAISE EXCEPTION 'PG876 rollback abort: a non-target source changed';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.card_semantic_tags_v2 s
    WHERE s.card_id = '115df6db-5280-4223-921b-dc4f591841f2'::uuid
  ) THEN
    RAISE EXCEPTION 'PG876 rollback abort: semantic snapshot appeared';
  END IF;

  WITH meta AS (
    SELECT
      lower(card_name) AS normalized_name,
      max(coalesce(usage_count, 0))::int AS usage_count,
      max(coalesce(meta_deck_count, 0))::int AS meta_deck_count
    FROM public.card_meta_insights
    GROUP BY lower(card_name)
  ), edhrec AS (
    SELECT
      lower(card_name) AS normalized_name,
      max(coalesce(inclusion, 0))::double precision AS inclusion_rate,
      max(coalesce(num_decks, 0))::int AS sample_decks
    FROM public.edhrec_card_snapshots
    WHERE card_name IS NOT NULL
      AND trim(card_name) <> ''
    GROUP BY lower(card_name)
  ), target AS (
    SELECT
      c.id AS card_id,
      c.name,
      coalesce(c.type_line, '') AS type_line,
      coalesce(c.oracle_text, '') AS oracle_text,
      coalesce(c.mana_cost, '') AS mana_cost,
      c.cmc,
      coalesce(c.price_usd::text, '') AS price_usd,
      coalesce(c.price_usd_foil::text, '') AS price_usd_foil,
      coalesce(m.usage_count, 0) AS usage_count,
      coalesce(m.meta_deck_count, 0) AS meta_deck_count,
      coalesce(e.inclusion_rate, 0) AS inclusion_rate,
      coalesce(e.sample_decks, 0) AS sample_decks
    FROM public.cards c
    LEFT JOIN meta m ON m.normalized_name = lower(c.name)
    LEFT JOIN edhrec e ON e.normalized_name = lower(c.name)
    WHERE c.id = '115df6db-5280-4223-921b-dc4f591841f2'::uuid
  )
  SELECT
    count(*),
    encode(digest(string_agg(
      concat_ws(
        '|', card_id::text, name, type_line, oracle_text, mana_cost,
        cmc::text, price_usd, price_usd_foil, usage_count::text,
        meta_deck_count::text, inclusion_rate::text, sample_decks::text
      ), E'\n' ORDER BY card_id::text
    ), 'sha256'), 'hex')
  INTO v_target_count, v_target_sha
  FROM target;

  IF v_target_count <> 1
     OR v_target_sha <>
       '853b46a8324082709733e85a6486098aaf786cc73924cd7e85d6035b0105b3c8'
  THEN
    RAISE EXCEPTION 'PG876 rollback abort: card or scoring input changed';
  END IF;
END $$;

DELETE FROM public.card_function_tags
WHERE card_id = '115df6db-5280-4223-921b-dc4f591841f2'::uuid
  AND source = 'deterministic_heuristic_v1';

INSERT INTO public.card_function_tags (
  card_id, card_name, tag, confidence, source, evidence, updated_at
)
SELECT
  card_id, card_name, tag, confidence, source, evidence, updated_at
FROM manaloom_deploy_audit.pg876_ronin_function_backup_20260716;

DELETE FROM public.card_role_scores
WHERE card_id = '115df6db-5280-4223-921b-dc4f591841f2'::uuid
  AND source = 'deterministic_heuristic_v1';

INSERT INTO public.card_role_scores (
  card_id, card_name, role, score, format, subformat, bracket_scope,
  budget_tier, source, evidence, updated_at
)
SELECT
  card_id, card_name, role, score, format, subformat, bracket_scope,
  budget_tier, source, evidence, updated_at
FROM manaloom_deploy_audit.pg876_ronin_role_backup_20260716;

DO $$
DECLARE
  v_function_count bigint;
  v_function_sha text;
  v_role_count bigint;
  v_role_sha text;
BEGIN
  IF EXISTS (
    (
      SELECT f.*
      FROM public.card_function_tags f
      WHERE f.card_id = '115df6db-5280-4223-921b-dc4f591841f2'::uuid
        AND f.source = 'deterministic_heuristic_v1'
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg876_ronin_function_backup_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg876_ronin_function_backup_20260716
      EXCEPT
      SELECT f.*
      FROM public.card_function_tags f
      WHERE f.card_id = '115df6db-5280-4223-921b-dc4f591841f2'::uuid
        AND f.source = 'deterministic_heuristic_v1'
    )
  ) THEN
    RAISE EXCEPTION 'PG876 rollback abort: function restore differs';
  END IF;

  IF EXISTS (
    (
      SELECT r.*
      FROM public.card_role_scores r
      WHERE r.card_id = '115df6db-5280-4223-921b-dc4f591841f2'::uuid
        AND r.source = 'deterministic_heuristic_v1'
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg876_ronin_role_backup_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg876_ronin_role_backup_20260716
      EXCEPT
      SELECT r.*
      FROM public.card_role_scores r
      WHERE r.card_id = '115df6db-5280-4223-921b-dc4f591841f2'::uuid
        AND r.source = 'deterministic_heuristic_v1'
    )
  ) THEN
    RAISE EXCEPTION 'PG876 rollback abort: role restore differs';
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
  WHERE card_id = '115df6db-5280-4223-921b-dc4f591841f2'::uuid
    AND source = 'deterministic_heuristic_v1';

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
  WHERE card_id = '115df6db-5280-4223-921b-dc4f591841f2'::uuid
    AND source = 'deterministic_heuristic_v1';

  IF v_function_count <> 1
     OR v_function_sha <>
       '83d684394dda226d06f4afb55fbb32b150b2d3780aa3856cc339c45abbf03381'
     OR v_role_count <> 0
     OR v_role_sha IS NOT NULL
     OR EXISTS (
       SELECT 1
       FROM public.card_semantic_tags_v2 s
       WHERE s.card_id = '115df6db-5280-4223-921b-dc4f591841f2'::uuid
     )
  THEN
    RAISE EXCEPTION
      'PG876 rollback abort: restored hashes diverged f=% r=%',
      v_function_count, v_role_count;
  END IF;
END $$;

COMMIT;
