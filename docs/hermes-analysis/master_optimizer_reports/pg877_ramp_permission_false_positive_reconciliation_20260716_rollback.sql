-- MUTATING ROLLBACK. Restores exact PG877 ramp snapshots.

BEGIN;

LOCK TABLE public.cards IN SHARE MODE;
LOCK TABLE public.card_function_tags IN SHARE ROW EXCLUSIVE MODE;
LOCK TABLE public.card_role_scores IN SHARE ROW EXCLUSIVE MODE;
LOCK TABLE public.card_semantic_tags_v2 IN SHARE ROW EXCLUSIVE MODE;
LOCK TABLE public.deck_cards IN SHARE MODE;
LOCK TABLE public.commander_card_usage IN SHARE MODE;

DO $$
BEGIN
  IF to_regclass(
       'manaloom_deploy_audit.pg877_ramp_target_20260716'
     ) IS NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg877_ramp_function_backup_20260716'
     ) IS NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg877_ramp_role_backup_20260716'
     ) IS NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg877_ramp_semantic_backup_20260716'
     ) IS NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg877_ramp_function_untouched_20260716'
     ) IS NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg877_ramp_role_untouched_20260716'
     ) IS NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg877_ramp_semantic_untouched_20260716'
     ) IS NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg877_ramp_preserved_function_20260716'
     ) IS NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg877_ramp_preserved_role_20260716'
     ) IS NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg877_ramp_preserved_semantic_20260716'
     ) IS NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg877_ramp_semantic_post_20260716'
     ) IS NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg877_ramp_deck_refs_20260716'
     ) IS NULL
     OR to_regclass(
       'manaloom_deploy_audit.pg877_ramp_usage_refs_20260716'
     ) IS NULL
  THEN
    RAISE EXCEPTION 'PG877 rollback abort: required audit tables missing';
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.card_function_tags f
    JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
    WHERE f.tag = 'ramp'
      AND f.source IN (
        'deterministic_heuristic_v1',
        'deterministic_semantic_v2'
      )
  ) THEN
    RAISE EXCEPTION 'PG877 rollback abort: target function poststate drifted';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.card_role_scores r
    JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
    WHERE r.role = 'ramp'
      AND r.source = 'deterministic_heuristic_v1'
  ) THEN
    RAISE EXCEPTION 'PG877 rollback abort: target role poststate drifted';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.card_semantic_tags_v2 s
    JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
    WHERE s.source = 'deterministic_semantic_v2'
      AND s.schema_version = 'semantic_layer_v2_2026_05_18'
      AND s.tags @> '[{"tag":"ramp"}]'::jsonb
  ) THEN
    RAISE EXCEPTION 'PG877 rollback abort: target semantic ramp reappeared';
  END IF;

  IF EXISTS (
    (
      SELECT s.*
      FROM public.card_semantic_tags_v2 s
      JOIN manaloom_deploy_audit.pg877_ramp_semantic_backup_20260716 b
        ON b.card_id = s.card_id
        AND b.source = s.source
        AND b.schema_version = s.schema_version
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_semantic_post_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_semantic_post_20260716
      EXCEPT
      SELECT s.*
      FROM public.card_semantic_tags_v2 s
      JOIN manaloom_deploy_audit.pg877_ramp_semantic_backup_20260716 b
        ON b.card_id = s.card_id
        AND b.source = s.source
        AND b.schema_version = s.schema_version
    )
  ) THEN
    RAISE EXCEPTION 'PG877 rollback abort: semantic poststate drifted';
  END IF;

  IF EXISTS (
    (
      SELECT f.*
      FROM public.card_function_tags f
      JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
      WHERE NOT (
        f.tag = 'ramp'
        AND f.source IN (
          'deterministic_heuristic_v1',
          'deterministic_semantic_v2'
        )
      )
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_function_untouched_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_function_untouched_20260716
      EXCEPT
      SELECT f.*
      FROM public.card_function_tags f
      JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
      WHERE NOT (
        f.tag = 'ramp'
        AND f.source IN (
          'deterministic_heuristic_v1',
          'deterministic_semantic_v2'
        )
      )
    )
  ) THEN
    RAISE EXCEPTION 'PG877 rollback abort: untouched function rows changed';
  END IF;

  IF EXISTS (
    (
      SELECT r.*
      FROM public.card_role_scores r
      JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
      WHERE NOT (
        r.role = 'ramp'
        AND r.source = 'deterministic_heuristic_v1'
      )
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_role_untouched_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_role_untouched_20260716
      EXCEPT
      SELECT r.*
      FROM public.card_role_scores r
      JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
      WHERE NOT (
        r.role = 'ramp'
        AND r.source = 'deterministic_heuristic_v1'
      )
    )
  ) THEN
    RAISE EXCEPTION 'PG877 rollback abort: untouched role rows changed';
  END IF;

  IF EXISTS (
    (
      SELECT s.*
      FROM public.card_semantic_tags_v2 s
      JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
      WHERE NOT (
        s.source = 'deterministic_semantic_v2'
        AND s.schema_version = 'semantic_layer_v2_2026_05_18'
        AND s.card_id IN (
          SELECT card_id
          FROM manaloom_deploy_audit.pg877_ramp_semantic_backup_20260716
        )
      )
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_semantic_untouched_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_semantic_untouched_20260716
      EXCEPT
      SELECT s.*
      FROM public.card_semantic_tags_v2 s
      JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
      WHERE NOT (
        s.source = 'deterministic_semantic_v2'
        AND s.schema_version = 'semantic_layer_v2_2026_05_18'
        AND s.card_id IN (
          SELECT card_id
          FROM manaloom_deploy_audit.pg877_ramp_semantic_backup_20260716
        )
      )
    )
  ) THEN
    RAISE EXCEPTION 'PG877 rollback abort: untouched semantic rows changed';
  END IF;

  IF EXISTS (
    (
      SELECT f.*
      FROM public.card_function_tags f
      WHERE f.card_id IN (
        SELECT card_id
        FROM manaloom_deploy_audit.pg877_ramp_preserved_function_20260716
      )
        AND f.tag = 'ramp'
        AND f.source IN (
          'deterministic_heuristic_v1',
          'deterministic_semantic_v2'
        )
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_preserved_function_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_preserved_function_20260716
      EXCEPT
      SELECT f.*
      FROM public.card_function_tags f
      WHERE f.card_id IN (
        SELECT card_id
        FROM manaloom_deploy_audit.pg877_ramp_preserved_function_20260716
      )
        AND f.tag = 'ramp'
        AND f.source IN (
          'deterministic_heuristic_v1',
          'deterministic_semantic_v2'
        )
    )
  ) THEN
    RAISE EXCEPTION 'PG877 rollback abort: preserved function rows changed';
  END IF;

  IF EXISTS (
    (
      SELECT r.*
      FROM public.card_role_scores r
      WHERE r.card_id IN (
        SELECT card_id
        FROM manaloom_deploy_audit.pg877_ramp_preserved_role_20260716
      )
        AND r.role = 'ramp'
        AND r.source = 'deterministic_heuristic_v1'
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_preserved_role_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_preserved_role_20260716
      EXCEPT
      SELECT r.*
      FROM public.card_role_scores r
      WHERE r.card_id IN (
        SELECT card_id
        FROM manaloom_deploy_audit.pg877_ramp_preserved_role_20260716
      )
        AND r.role = 'ramp'
        AND r.source = 'deterministic_heuristic_v1'
    )
  ) THEN
    RAISE EXCEPTION 'PG877 rollback abort: preserved role rows changed';
  END IF;

  IF EXISTS (
    (
      SELECT s.*
      FROM public.card_semantic_tags_v2 s
      WHERE s.card_id IN (
        SELECT card_id
        FROM manaloom_deploy_audit.pg877_ramp_preserved_semantic_20260716
      )
        AND s.source = 'deterministic_semantic_v2'
        AND s.schema_version = 'semantic_layer_v2_2026_05_18'
        AND s.tags @> '[{"tag":"ramp"}]'::jsonb
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_preserved_semantic_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_preserved_semantic_20260716
      EXCEPT
      SELECT s.*
      FROM public.card_semantic_tags_v2 s
      WHERE s.card_id IN (
        SELECT card_id
        FROM manaloom_deploy_audit.pg877_ramp_preserved_semantic_20260716
      )
        AND s.source = 'deterministic_semantic_v2'
        AND s.schema_version = 'semantic_layer_v2_2026_05_18'
        AND s.tags @> '[{"tag":"ramp"}]'::jsonb
    )
  ) THEN
    RAISE EXCEPTION 'PG877 rollback abort: preserved semantic rows changed';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM (
      (
        SELECT dc.*
        FROM public.deck_cards dc
        JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t
          ON t.card_id = dc.card_id
        EXCEPT
        SELECT *
        FROM manaloom_deploy_audit.pg877_ramp_deck_refs_20260716
      )
      UNION ALL
      (
        SELECT *
        FROM manaloom_deploy_audit.pg877_ramp_deck_refs_20260716
        EXCEPT
        SELECT dc.*
        FROM public.deck_cards dc
        JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t
          ON t.card_id = dc.card_id
      )
    ) diff
  ) THEN
    RAISE EXCEPTION 'PG877 rollback abort: deck references changed';
  END IF;

  IF EXISTS (
    WITH target_usage_names AS (
      SELECT DISTINCT
        lower(split_part(name, ' // ', 1)) AS card_name_normalized
      FROM manaloom_deploy_audit.pg877_ramp_target_20260716
    ), current_usage_refs AS (
      SELECT u.*
      FROM public.commander_card_usage u
      JOIN target_usage_names n USING (card_name_normalized)
    )
    SELECT 1
    FROM (
      (SELECT * FROM current_usage_refs
       EXCEPT
       SELECT *
       FROM manaloom_deploy_audit.pg877_ramp_usage_refs_20260716)
      UNION ALL
      (SELECT *
       FROM manaloom_deploy_audit.pg877_ramp_usage_refs_20260716
       EXCEPT
       SELECT * FROM current_usage_refs)
    ) diff
  ) THEN
    RAISE EXCEPTION 'PG877 rollback abort: commander usage references changed';
  END IF;

  IF EXISTS (
    WITH current_target AS (
      SELECT
        c.id AS card_id,
        c.name,
        coalesce(c.type_line, '') AS type_line,
        coalesce(c.oracle_text, '') AS oracle_text,
        coalesce(c.mana_cost, '') AS mana_cost,
        c.cmc,
        t.classification
      FROM manaloom_deploy_audit.pg877_ramp_target_20260716 t
      JOIN public.cards c ON c.id = t.card_id
    )
    SELECT 1
    FROM (
      (SELECT * FROM current_target
       EXCEPT
       SELECT * FROM manaloom_deploy_audit.pg877_ramp_target_20260716)
      UNION ALL
      (SELECT * FROM manaloom_deploy_audit.pg877_ramp_target_20260716
       EXCEPT
       SELECT * FROM current_target)
    ) diff
  ) THEN
    RAISE EXCEPTION 'PG877 rollback abort: target card inputs changed';
  END IF;
END $$;

INSERT INTO public.card_function_tags (
  card_id, card_name, tag, confidence, source, evidence, updated_at
)
SELECT
  card_id, card_name, tag, confidence, source, evidence, updated_at
FROM manaloom_deploy_audit.pg877_ramp_function_backup_20260716;

INSERT INTO public.card_role_scores (
  card_id, card_name, role, score, format, subformat, bracket_scope,
  budget_tier, source, evidence, updated_at
)
SELECT
  card_id, card_name, role, score, format, subformat, bracket_scope,
  budget_tier, source, evidence, updated_at
FROM manaloom_deploy_audit.pg877_ramp_role_backup_20260716;

DELETE FROM public.card_semantic_tags_v2 s
USING manaloom_deploy_audit.pg877_ramp_semantic_backup_20260716 b
WHERE s.card_id = b.card_id
  AND s.source = b.source
  AND s.schema_version = b.schema_version;

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
FROM manaloom_deploy_audit.pg877_ramp_semantic_backup_20260716;

DO $$
DECLARE
  v_hf_count bigint;
  v_sf_count bigint;
  v_role_count bigint;
  v_semantic_count bigint;
  v_function_full_sha text;
  v_role_full_sha text;
  v_semantic_full_sha text;
BEGIN
  IF EXISTS (
    (
      SELECT f.*
      FROM public.card_function_tags f
      JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
      WHERE f.tag = 'ramp'
        AND f.source IN (
          'deterministic_heuristic_v1',
          'deterministic_semantic_v2'
        )
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_function_backup_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_function_backup_20260716
      EXCEPT
      SELECT f.*
      FROM public.card_function_tags f
      JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
      WHERE f.tag = 'ramp'
        AND f.source IN (
          'deterministic_heuristic_v1',
          'deterministic_semantic_v2'
        )
    )
  ) THEN
    RAISE EXCEPTION 'PG877 rollback abort: function restore differs';
  END IF;

  IF EXISTS (
    (
      SELECT r.*
      FROM public.card_role_scores r
      JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
      WHERE r.role = 'ramp'
        AND r.source = 'deterministic_heuristic_v1'
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_role_backup_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_role_backup_20260716
      EXCEPT
      SELECT r.*
      FROM public.card_role_scores r
      JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
      WHERE r.role = 'ramp'
        AND r.source = 'deterministic_heuristic_v1'
    )
  ) THEN
    RAISE EXCEPTION 'PG877 rollback abort: role restore differs';
  END IF;

  IF EXISTS (
    (
      SELECT s.*
      FROM public.card_semantic_tags_v2 s
      JOIN manaloom_deploy_audit.pg877_ramp_semantic_backup_20260716 b
        ON b.card_id = s.card_id
        AND b.source = s.source
        AND b.schema_version = s.schema_version
      EXCEPT
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_semantic_backup_20260716
    )
    UNION ALL
    (
      SELECT *
      FROM manaloom_deploy_audit.pg877_ramp_semantic_backup_20260716
      EXCEPT
      SELECT s.*
      FROM public.card_semantic_tags_v2 s
      JOIN manaloom_deploy_audit.pg877_ramp_semantic_backup_20260716 b
        ON b.card_id = s.card_id
        AND b.source = s.source
        AND b.schema_version = s.schema_version
    )
  ) THEN
    RAISE EXCEPTION 'PG877 rollback abort: semantic restore differs';
  END IF;

  SELECT
    count(*) FILTER (WHERE source = 'deterministic_heuristic_v1'),
    count(*) FILTER (WHERE source = 'deterministic_semantic_v2'),
    encode(digest(string_agg(
      concat_ws(
        '|', card_id::text, card_name, tag, confidence::text, source,
        evidence,
        coalesce(to_char(
          updated_at AT TIME ZONE 'UTC',
          'YYYY-MM-DD"T"HH24:MI:SS.US'
        ), '')
      ), E'\n' ORDER BY source, card_id::text, tag
    ), 'sha256'), 'hex')
  INTO v_hf_count, v_sf_count, v_function_full_sha
  FROM manaloom_deploy_audit.pg877_ramp_function_backup_20260716;

  SELECT
    count(*),
    encode(digest(string_agg(
      concat_ws(
        '|', card_id::text, card_name, role, score::text, format,
        subformat, bracket_scope, budget_tier, source, evidence,
        coalesce(to_char(
          updated_at AT TIME ZONE 'UTC',
          'YYYY-MM-DD"T"HH24:MI:SS.US'
        ), '')
      ), E'\n' ORDER BY
        card_id::text, format, subformat, bracket_scope, budget_tier
    ), 'sha256'), 'hex')
  INTO v_role_count, v_role_full_sha
  FROM manaloom_deploy_audit.pg877_ramp_role_backup_20260716;

  SELECT
    count(*),
    encode(digest(string_agg(
      concat_ws(
        '|', card_id::text, card_name, schema_version, speed,
        mana_efficiency, card_advantage_type, interaction_scope,
        combo_piece::text, wincon::text, engine::text, payoff::text,
        enabler::text, protection_type, recursion_type,
        role_confidence::text, explanation_reason, tags::text, source,
        coalesce(to_char(
          updated_at AT TIME ZONE 'UTC',
          'YYYY-MM-DD"T"HH24:MI:SS.US'
        ), '')
      ), E'\n' ORDER BY card_id::text
    ), 'sha256'), 'hex')
  INTO v_semantic_count, v_semantic_full_sha
  FROM manaloom_deploy_audit.pg877_ramp_semantic_backup_20260716;

  IF v_hf_count <> 105
     OR v_sf_count <> 105
     OR v_role_count <> 115
     OR v_semantic_count <> 105
     OR v_function_full_sha <>
       '8f885ffcc651b51a24d89e51df566e6f1dff54edd643c59cd99667074488621a'
     OR v_role_full_sha <>
       '0960dfd25538f2cf46888adf1d854831122424102a9596212334f709e68eb062'
     OR v_semantic_full_sha <>
       'f8d4b1ee8fad1e88d5fb9d309ca7577d5345d3fed4c80b6cf125c1f9b537a752'
  THEN
    RAISE EXCEPTION
      'PG877 rollback abort: restored hashes diverged hf=% sf=% r=% s=%',
      v_hf_count, v_sf_count, v_role_count, v_semantic_count;
  END IF;
END $$;

COMMIT;
