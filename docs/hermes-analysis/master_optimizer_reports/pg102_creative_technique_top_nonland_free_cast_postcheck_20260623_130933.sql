WITH target AS (
  SELECT
    'creative technique'::text AS normalized_name,
    'battle_rule_v1:fcb6b63cf730c83aa99760cc53bf3dd9'::text AS logical_rule_key,
    '98c26337370ce75f10e3e529a94b8ef3'::text AS expected_oracle_hash,
    '{"battle_model_scope":"shuffle_reveal_top_nonland_exile_free_cast_with_demonstrate_v1","demonstrate":true,"demonstrate_choice_model":"choose_lowest_visible_threat_opponent","demonstrate_copy_model":"controller_copy_and_chosen_opponent_copy","effect":"exile_top_nonland_free_cast","revealed_card_cast_without_paying_mana":true,"shuffle_before_reveal":true,"sorcery":true,"top_reveal_until":"nonland"}'::jsonb AS expected_effect_json
),
target_card AS (
  SELECT c.id, md5(coalesce(c.oracle_text, '')) AS card_oracle_hash
  FROM public.cards c
  JOIN target t ON lower(c.name) = t.normalized_name
)
SELECT
  (SELECT count(*) FROM target_card) AS target_card_rows,
  (SELECT count(*) FROM target_card c JOIN target t ON c.card_oracle_hash = t.expected_oracle_hash) AS card_oracle_hash_match_rows,
  (SELECT count(*) FROM public.card_battle_rules r JOIN target t ON r.normalized_name = t.normalized_name AND r.logical_rule_key = t.logical_rule_key) AS promoted_rule_rows,
  (SELECT count(*) FROM public.card_battle_rules r JOIN target t ON r.normalized_name = t.normalized_name AND r.logical_rule_key = t.logical_rule_key AND r.review_status = 'verified' AND r.execution_status = 'auto' AND r.source = 'curated') AS promoted_verified_auto_rows,
  (SELECT count(*) FROM public.card_battle_rules r JOIN target t ON r.normalized_name = t.normalized_name AND r.logical_rule_key = t.logical_rule_key AND r.oracle_hash = t.expected_oracle_hash) AS promoted_oracle_hash_rows,
  (SELECT count(*) FROM public.card_battle_rules r JOIN target t ON r.normalized_name = t.normalized_name AND r.logical_rule_key = t.logical_rule_key AND r.effect_json @> t.expected_effect_json) AS promoted_expected_effect_rows,
  (SELECT count(*) FROM public.card_battle_rules r JOIN target t ON r.normalized_name = t.normalized_name AND r.logical_rule_key <> t.logical_rule_key AND r.review_status IN ('verified', 'active') AND r.execution_status IN ('auto', 'executable')) AS active_shadow_rows,
  (SELECT count(*) FROM public.card_battle_rules r JOIN target t ON r.normalized_name = t.normalized_name AND r.effect_json @> '{"effect":"draw_cards"}'::jsonb AND r.execution_status <> 'disabled') AS active_rows_still_claiming_draw_cards,
  (SELECT count(*) FROM public.card_battle_rules r JOIN target t ON r.normalized_name = t.normalized_name AND r.review_status IN ('verified', 'active') AND r.execution_status IN ('auto', 'executable') AND nullif(r.oracle_hash, '') IS NULL) AS trusted_missing_oracle_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg102_creative_technique_top_nonland_free_cast_20260623_130933) AS backup_rows;

WITH target AS (
  SELECT 'creative technique'::text AS normalized_name
)
SELECT
  r.normalized_name,
  r.card_name,
  r.logical_rule_key,
  r.source,
  r.review_status,
  r.execution_status,
  r.confidence,
  r.rule_version,
  r.oracle_hash,
  r.effect_json,
  r.deck_role_json,
  r.notes
FROM public.card_battle_rules r
JOIN target t ON r.normalized_name = t.normalized_name
ORDER BY r.execution_status, r.review_status, r.logical_rule_key;
