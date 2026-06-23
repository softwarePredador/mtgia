WITH target AS (
  SELECT
    'call forth the tempest'::text AS normalized_name,
    'Call Forth the Tempest'::text AS card_name,
    'battle_rule_v1:f1b2e00fe7ffd5fcdf4d0ab90bdd9739'::text AS logical_rule_key,
    '5e76c466448cabbfd764e746566b41c1'::text AS expected_oracle_hash,
    '{"battle_model_scope":"cascade_cascade_other_spells_mana_value_opponent_creature_damage_v1","cascade_execution_status":"annotation_only_no_cascade_executor","cascade_instances":2,"current_spell_included_in_mana_value_ledger":true,"damage_amount_source":"other_spells_cast_mana_value_this_turn","damage_scope":"opponent_creatures","effect":"damage_wipe"}'::jsonb AS expected_effect_json,
    '{"category":"wipe","role":"dynamic_damage_wipe","subtype":"cascade_mana_value_scaled_opponent_creature_damage"}'::jsonb AS expected_deck_role_json
),
card_match AS (
  SELECT c.id, c.name, c.type_line, c.mana_cost, c.cmc,
         md5(coalesce(c.oracle_text, '')) AS card_oracle_hash,
         c.oracle_text
  FROM public.cards c
  JOIN target t ON lower(c.name) = t.normalized_name
)
SELECT
  (SELECT count(*) FROM card_match) AS target_card_rows,
  (SELECT count(*) FROM card_match cm JOIN target t ON cm.card_oracle_hash = t.expected_oracle_hash) AS card_oracle_hash_match_rows,
  (SELECT count(*) FROM public.card_battle_rules r JOIN target t ON r.normalized_name = t.normalized_name AND r.logical_rule_key = t.logical_rule_key) AS new_rule_already_present_rows,
  (SELECT count(*) FROM public.card_battle_rules r JOIN target t ON r.normalized_name = t.normalized_name AND r.logical_rule_key <> t.logical_rule_key AND r.review_status IN ('verified', 'active') AND r.execution_status IN ('auto', 'executable')) AS active_shadow_rows,
  (SELECT count(*) FROM public.card_battle_rules r JOIN target t ON r.normalized_name = t.normalized_name AND r.effect_json ? 'token_maker') AS rows_still_claiming_token_maker,
  (SELECT count(*) FROM public.card_battle_rules r JOIN target t ON r.normalized_name = t.normalized_name AND r.review_status IN ('verified', 'active') AND r.execution_status IN ('auto', 'executable') AND nullif(r.oracle_hash, '') IS NULL) AS trusted_missing_oracle_hash_rows,
  to_regclass('manaloom_deploy_audit.pg098_call_forth_tempest_dynamic_damage_20260623_120031') IS NOT NULL AS backup_table_already_exists;

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
ORDER BY r.updated_at, r.logical_rule_key;
