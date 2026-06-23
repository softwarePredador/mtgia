WITH target AS (
  SELECT
    'dawn''s truce'::text AS normalized_name,
    'battle_rule_v1:74537642d9a7fded7b0e5616b88703ef'::text AS logical_rule_key,
    '9cc2a1e412623ff79367f88b163c5216'::text AS expected_oracle_hash,
    '{"battle_model_scope":"gift_card_you_and_permanents_hexproof_gifted_indestructible_v1","effect":"gift_hexproof_indestructible","gift":"card","gift_card_draw":true,"gift_choice_model":"lowest_visible_threat_opponent","gift_default_promised":true,"gift_grants_permanents_indestructible":true,"grants_permanents_hexproof":true,"grants_player_hexproof":true,"instant":true,"target_scope":"you_and_permanents_you_control"}'::jsonb AS expected_effect_json
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
  (SELECT count(*) FROM public.card_battle_rules r JOIN target t ON r.normalized_name = t.normalized_name AND r.effect_json @> '{"effect":"indestructible"}'::jsonb AND r.execution_status <> 'disabled') AS active_rows_still_claiming_plain_indestructible,
  (SELECT count(*) FROM public.card_battle_rules r JOIN target t ON r.normalized_name = t.normalized_name AND r.review_status IN ('verified', 'active') AND r.execution_status IN ('auto', 'executable') AND nullif(r.oracle_hash, '') IS NULL) AS trusted_missing_oracle_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg103_dawns_truce_gift_hexproof_indestructible_20260623_133226) AS backup_rows;

WITH target AS (
  SELECT 'dawn''s truce'::text AS normalized_name
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
