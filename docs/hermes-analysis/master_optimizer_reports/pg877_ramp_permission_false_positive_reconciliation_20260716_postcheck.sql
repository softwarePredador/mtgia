-- READ ONLY. Run only after an explicitly approved PG877 apply.

BEGIN TRANSACTION READ ONLY;

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
), current_deck_refs AS (
  SELECT dc.*
  FROM public.deck_cards dc
  JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t
    ON t.card_id = dc.card_id
), target_usage_names AS (
  SELECT DISTINCT lower(split_part(name, ' // ', 1)) AS card_name_normalized
  FROM manaloom_deploy_audit.pg877_ramp_target_20260716
), current_usage_refs AS (
  SELECT u.*
  FROM public.commander_card_usage u
  JOIN target_usage_names n USING (card_name_normalized)
), current_semantic_post AS (
  SELECT s.*
  FROM public.card_semantic_tags_v2 s
  JOIN manaloom_deploy_audit.pg877_ramp_semantic_backup_20260716 b
    ON b.card_id = s.card_id
    AND b.source = s.source
    AND b.schema_version = s.schema_version
), current_function_untouched AS (
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
), current_role_untouched AS (
  SELECT r.*
  FROM public.card_role_scores r
  JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
  WHERE NOT (
    r.role = 'ramp'
    AND r.source = 'deterministic_heuristic_v1'
  )
), current_semantic_untouched AS (
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
), current_preserved_function AS (
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
), current_preserved_role AS (
  SELECT r.*
  FROM public.card_role_scores r
  WHERE r.card_id IN (
    SELECT card_id
    FROM manaloom_deploy_audit.pg877_ramp_preserved_role_20260716
  )
    AND r.role = 'ramp'
    AND r.source = 'deterministic_heuristic_v1'
), current_preserved_semantic AS (
  SELECT s.*
  FROM public.card_semantic_tags_v2 s
  WHERE s.card_id IN (
    SELECT card_id
    FROM manaloom_deploy_audit.pg877_ramp_preserved_semantic_20260716
  )
    AND s.source = 'deterministic_semantic_v2'
    AND s.schema_version = 'semantic_layer_v2_2026_05_18'
    AND s.tags @> '[{"tag":"ramp"}]'::jsonb
), metrics AS (
  SELECT
    (
      SELECT count(*)
      FROM manaloom_deploy_audit.pg877_ramp_target_20260716
    ) AS target_count,
    (
      SELECT encode(digest(string_agg(
        card_id::text, E'\n' ORDER BY card_id::text
      ), 'sha256'), 'hex')
      FROM manaloom_deploy_audit.pg877_ramp_target_20260716
    ) AS target_id_sha,
    (
      SELECT count(*)
      FROM manaloom_deploy_audit.pg877_ramp_deck_refs_20260716
    ) AS deck_ref_count,
    (
      SELECT count(DISTINCT deck_id)
      FROM manaloom_deploy_audit.pg877_ramp_deck_refs_20260716
    ) AS deck_ref_deck_count,
    (
      SELECT count(DISTINCT card_id)
      FROM manaloom_deploy_audit.pg877_ramp_deck_refs_20260716
    ) AS deck_ref_card_count,
    (
      SELECT encode(digest(string_agg(
        card_id::text, E'\n' ORDER BY card_id::text
      ), 'sha256'), 'hex')
      FROM (
        SELECT DISTINCT card_id
        FROM manaloom_deploy_audit.pg877_ramp_deck_refs_20260716
      ) distinct_deck_cards
    ) AS deck_ref_card_id_sha,
    (
      SELECT encode(digest(string_agg(
        concat_ws(
          '|', id::text, deck_id::text, card_id::text, quantity::text,
          is_commander::text, condition
        ), E'\n' ORDER BY id::text
      ), 'sha256'), 'hex')
      FROM manaloom_deploy_audit.pg877_ramp_deck_refs_20260716
    ) AS deck_ref_full_sha,
    (
      SELECT count(*)
      FROM manaloom_deploy_audit.pg877_ramp_usage_refs_20260716
    ) AS usage_ref_count,
    (
      SELECT count(DISTINCT card_name_normalized)
      FROM manaloom_deploy_audit.pg877_ramp_usage_refs_20260716
    ) AS usage_ref_card_count,
    (
      SELECT coalesce(sum(usage_count), 0)
      FROM manaloom_deploy_audit.pg877_ramp_usage_refs_20260716
    ) AS usage_ref_total,
    (
      SELECT encode(digest(string_agg(
        card_name_normalized, E'\n' ORDER BY card_name_normalized
      ), 'sha256'), 'hex')
      FROM (
        SELECT DISTINCT card_name_normalized
        FROM manaloom_deploy_audit.pg877_ramp_usage_refs_20260716
      ) distinct_usage_cards
    ) AS usage_ref_card_name_sha,
    (
      SELECT encode(digest(string_agg(
        concat_ws(
          '|', commander_name_normalized, card_name_normalized,
          usage_count::text,
          to_char(
            last_used_at AT TIME ZONE 'UTC',
            'YYYY-MM-DD"T"HH24:MI:SS.US'
          )
        ), E'\n' ORDER BY commander_name_normalized, card_name_normalized
      ), 'sha256'), 'hex')
      FROM manaloom_deploy_audit.pg877_ramp_usage_refs_20260716
    ) AS usage_ref_full_sha,
    (
      SELECT count(*)
      FROM manaloom_deploy_audit.pg877_ramp_function_backup_20260716
      WHERE source = 'deterministic_heuristic_v1'
    ) AS heuristic_function_backup_count,
    (
      SELECT count(*)
      FROM manaloom_deploy_audit.pg877_ramp_function_backup_20260716
      WHERE source = 'deterministic_semantic_v2'
    ) AS semantic_function_backup_count,
    (
      SELECT count(*)
      FROM manaloom_deploy_audit.pg877_ramp_role_backup_20260716
    ) AS role_backup_count,
    (
      SELECT count(*)
      FROM manaloom_deploy_audit.pg877_ramp_semantic_backup_20260716
    ) AS semantic_backup_count,
    (
      SELECT count(*)
      FROM manaloom_deploy_audit.pg877_ramp_semantic_backup_20260716
      WHERE jsonb_array_length(tags) = 1
    ) AS semantic_deleted_count,
    (
      SELECT count(*)
      FROM public.card_function_tags f
      JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
      WHERE f.tag = 'ramp'
        AND f.source IN (
          'deterministic_heuristic_v1',
          'deterministic_semantic_v2'
        )
    ) AS bad_function_count,
    (
      SELECT count(*)
      FROM public.card_role_scores r
      JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
      WHERE r.role = 'ramp'
        AND r.source = 'deterministic_heuristic_v1'
    ) AS bad_role_count,
    (
      SELECT count(*)
      FROM public.card_semantic_tags_v2 s
      JOIN manaloom_deploy_audit.pg877_ramp_target_20260716 t USING (card_id)
      WHERE s.source = 'deterministic_semantic_v2'
        AND s.schema_version = 'semantic_layer_v2_2026_05_18'
        AND s.tags @> '[{"tag":"ramp"}]'::jsonb
    ) AS bad_semantic_count,
    (
      SELECT count(*)
      FROM manaloom_deploy_audit.pg877_ramp_semantic_post_20260716
    ) AS semantic_post_count,
    (
      SELECT encode(digest(string_agg(
        concat_ws(
          '|', card_id::text, card_name, schema_version, speed,
          mana_efficiency, card_advantage_type, interaction_scope,
          combo_piece::text, wincon::text, engine::text, payoff::text,
          enabler::text, protection_type, recursion_type,
          role_confidence::text, explanation_reason, tags::text, source
        ), E'\n' ORDER BY card_id::text
      ), 'sha256'), 'hex')
      FROM manaloom_deploy_audit.pg877_ramp_semantic_post_20260716
    ) AS semantic_post_content_sha,
    (
      SELECT count(*)
      FROM (
        (SELECT * FROM current_target
         EXCEPT
         SELECT *
         FROM manaloom_deploy_audit.pg877_ramp_target_20260716)
        UNION ALL
        (SELECT *
         FROM manaloom_deploy_audit.pg877_ramp_target_20260716
         EXCEPT
         SELECT * FROM current_target)
      ) diff
    ) AS target_input_diff,
    (
      SELECT count(*)
      FROM (
        (SELECT * FROM current_deck_refs
         EXCEPT
         SELECT *
         FROM manaloom_deploy_audit.pg877_ramp_deck_refs_20260716)
        UNION ALL
        (SELECT *
         FROM manaloom_deploy_audit.pg877_ramp_deck_refs_20260716
         EXCEPT
         SELECT * FROM current_deck_refs)
      ) diff
    ) AS deck_ref_diff,
    (
      SELECT count(*)
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
    ) AS usage_ref_diff,
    (
      SELECT count(*)
      FROM (
        (SELECT * FROM current_semantic_post
         EXCEPT
         SELECT *
         FROM manaloom_deploy_audit.pg877_ramp_semantic_post_20260716)
        UNION ALL
        (SELECT *
         FROM manaloom_deploy_audit.pg877_ramp_semantic_post_20260716
         EXCEPT
         SELECT * FROM current_semantic_post)
      ) diff
    ) AS semantic_post_diff,
    (
      SELECT count(*)
      FROM (
        (SELECT * FROM current_function_untouched
         EXCEPT
         SELECT *
         FROM manaloom_deploy_audit.pg877_ramp_function_untouched_20260716)
        UNION ALL
        (SELECT *
         FROM manaloom_deploy_audit.pg877_ramp_function_untouched_20260716
         EXCEPT
         SELECT * FROM current_function_untouched)
      ) diff
    ) AS untouched_function_diff,
    (
      SELECT count(*)
      FROM (
        (SELECT * FROM current_role_untouched
         EXCEPT
         SELECT *
         FROM manaloom_deploy_audit.pg877_ramp_role_untouched_20260716)
        UNION ALL
        (SELECT *
         FROM manaloom_deploy_audit.pg877_ramp_role_untouched_20260716
         EXCEPT
         SELECT * FROM current_role_untouched)
      ) diff
    ) AS untouched_role_diff,
    (
      SELECT count(*)
      FROM (
        (SELECT * FROM current_semantic_untouched
         EXCEPT
         SELECT *
         FROM manaloom_deploy_audit.pg877_ramp_semantic_untouched_20260716)
        UNION ALL
        (SELECT *
         FROM manaloom_deploy_audit.pg877_ramp_semantic_untouched_20260716
         EXCEPT
         SELECT * FROM current_semantic_untouched)
      ) diff
    ) AS untouched_semantic_diff,
    (
      SELECT count(*)
      FROM (
        (SELECT * FROM current_preserved_function
         EXCEPT
         SELECT *
         FROM manaloom_deploy_audit.pg877_ramp_preserved_function_20260716)
        UNION ALL
        (SELECT *
         FROM manaloom_deploy_audit.pg877_ramp_preserved_function_20260716
         EXCEPT
         SELECT * FROM current_preserved_function)
      ) diff
    ) AS preserved_function_diff,
    (
      SELECT count(*)
      FROM (
        (SELECT * FROM current_preserved_role
         EXCEPT
         SELECT *
         FROM manaloom_deploy_audit.pg877_ramp_preserved_role_20260716)
        UNION ALL
        (SELECT *
         FROM manaloom_deploy_audit.pg877_ramp_preserved_role_20260716
         EXCEPT
         SELECT * FROM current_preserved_role)
      ) diff
    ) AS preserved_role_diff,
    (
      SELECT count(*)
      FROM (
        (SELECT * FROM current_preserved_semantic
         EXCEPT
         SELECT *
         FROM manaloom_deploy_audit.pg877_ramp_preserved_semantic_20260716)
        UNION ALL
        (SELECT *
         FROM manaloom_deploy_audit.pg877_ramp_preserved_semantic_20260716
         EXCEPT
         SELECT * FROM current_preserved_semantic)
      ) diff
    ) AS preserved_semantic_diff
)
SELECT
  *,
  CASE
    WHEN target_count = 115
      AND target_id_sha =
        'b8e4fa337a747efadfd6cb1ab57ed5796e75de7387f3c85fd39cb3f4e742cc98'
      AND deck_ref_count = 28
      AND deck_ref_deck_count = 24
      AND deck_ref_card_count = 11
      AND deck_ref_card_id_sha =
        '4539610c0a0c1d5b6ec42d92a28afc149ea2f6f208e01d0e005561f9f46a71df'
      AND deck_ref_full_sha =
        '8183fd629f26d7030f1ee5b0b3f9b95516f70a4829838290ec6f37a8d4534dce'
      AND usage_ref_count = 8
      AND usage_ref_card_count = 8
      AND usage_ref_total = 54
      AND usage_ref_card_name_sha =
        '5bfdf040e76b7909be466ce923fad32fe54b01e4247fe0418657e8f440d3585a'
      AND usage_ref_full_sha =
        '42aa361635ba609e18b987a924bf350fbd828c6c0b1ad51821592a4a764413a1'
      AND heuristic_function_backup_count = 105
      AND semantic_function_backup_count = 105
      AND role_backup_count = 115
      AND semantic_backup_count = 105
      AND semantic_deleted_count = 22
      AND bad_function_count = 0
      AND bad_role_count = 0
      AND bad_semantic_count = 0
      AND semantic_post_count = 83
      AND semantic_post_content_sha =
        'd06f7f53ec19b866e6b9e9160af69ca6b977ef623bf72eaf7d0c4926c236d4fa'
      AND target_input_diff = 0
      AND deck_ref_diff = 0
      AND usage_ref_diff = 0
      AND semantic_post_diff = 0
      AND untouched_function_diff = 0
      AND untouched_role_diff = 0
      AND untouched_semantic_diff = 0
      AND preserved_function_diff = 0
      AND preserved_role_diff = 0
      AND preserved_semantic_diff = 0
    THEN 'PG877_POSTCHECK_PASS'
    ELSE 'PG877_POSTCHECK_ABORT_STATE_DRIFT'
  END AS status
FROM metrics;

ROLLBACK;
