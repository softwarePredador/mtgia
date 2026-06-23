WITH target AS (
  SELECT
    'avatar''s wrath'::text AS normalized_name,
    'Avatar''s Wrath'::text AS card_name,
    'battle_rule_v1:2dc2965ea9c97ebdb62c2b351bf29bf5'::text AS logical_rule_key,
    '21a711291b98f2e66a6d94a6c806945d'::text AS expected_oracle_hash,
    '{"airbend_recast_cost":"{2}","airbend_recast_permission":"owner_may_cast_from_exile","airbend_recast_permission_status":"tracked_for_cast_from_exile","airbend_scope":"all_other_creatures","battle_model_scope":"avatars_wrath_airbend_all_other_creatures_nonhand_lock_self_exile_v1","destination":"exile","effect":"airbend_other_creatures","exile_creatures":true,"exiles_self":true,"opponents_non_hand_cast_lock":true,"opponents_non_hand_cast_lock_duration":"until_your_next_turn","sorcery":true,"target":"creature","target_choice":"up_to_one_creature_to_spare","target_scope":"any_creature"}'::jsonb AS expected_effect_json,
    '{"category":"wipe","effect":"airbend_other_creatures","role":"tempo_wipe_nonhand_cast_lock","timing":"sorcery"}'::jsonb AS expected_deck_role_json
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
  (SELECT count(*) FROM public.card_battle_rules r JOIN target t ON r.normalized_name = t.normalized_name AND r.effect_json @> '{"effect":"silence_opponents"}'::jsonb AND r.execution_status <> 'disabled') AS rows_still_claiming_silence_opponents,
  (SELECT count(*) FROM public.card_battle_rules r JOIN target t ON r.normalized_name = t.normalized_name AND r.review_status IN ('verified', 'active') AND r.execution_status IN ('auto', 'executable') AND nullif(r.oracle_hash, '') IS NULL) AS trusted_missing_oracle_hash_rows,
  to_regclass('manaloom_deploy_audit.pg099_avatars_wrath_airbend_rule_20260623_093427') IS NOT NULL AS backup_table_already_exists;

WITH target AS (
  SELECT 'avatar''s wrath'::text AS normalized_name
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
