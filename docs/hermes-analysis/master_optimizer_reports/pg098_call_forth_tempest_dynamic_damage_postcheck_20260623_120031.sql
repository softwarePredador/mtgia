WITH target AS (
  SELECT
    'call forth the tempest'::text AS normalized_name,
    'battle_rule_v1:f1b2e00fe7ffd5fcdf4d0ab90bdd9739'::text AS logical_rule_key,
    '5e76c466448cabbfd764e746566b41c1'::text AS expected_oracle_hash,
    '{"battle_model_scope":"cascade_cascade_other_spells_mana_value_opponent_creature_damage_v1","cascade_execution_status":"annotation_only_no_cascade_executor","cascade_instances":2,"current_spell_included_in_mana_value_ledger":true,"damage_amount_source":"other_spells_cast_mana_value_this_turn","damage_scope":"opponent_creatures","effect":"damage_wipe"}'::jsonb AS expected_effect_json
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
  (SELECT count(*) FROM public.card_battle_rules r JOIN target t ON r.normalized_name = t.normalized_name AND r.effect_json ? 'token_maker' AND r.execution_status <> 'disabled') AS active_rows_still_claiming_token_maker,
  (SELECT count(*) FROM public.card_battle_rules r JOIN target t ON r.normalized_name = t.normalized_name AND r.review_status IN ('verified', 'active') AND r.execution_status IN ('auto', 'executable') AND nullif(r.oracle_hash, '') IS NULL) AS trusted_missing_oracle_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg098_call_forth_tempest_dynamic_damage_20260623_120031) AS backup_rows;

WITH target AS (
  SELECT 'call forth the tempest'::text AS normalized_name
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
