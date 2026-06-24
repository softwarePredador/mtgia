WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('electroduplicate', 'Electroduplicate', '336afa048144f8fb9a88dfc3b6588f4b', 'battle_rule_v1:e62445a8a1b5b420bad5215efdc00137', '{"ability_kind":"triggered","battle_model_scope":"copy_target_creature_you_control_haste_sacrifice_end_step_v1","copy_target_types":["creature"],"effect":"copy_creature_token","sacrifice_token_at_end_step":true,"target_controller":"own","token_haste":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Electroduplicate mapped to family copy_creature_token; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('pirate''s pillage', 'Pirate''s Pillage', '9c4fbe06104051a2e8b1d295d307b26a', 'battle_rule_v1:f13cb9da00fe7eb3bf0fccef34e64d9e', '{"ability_kind":"one_shot","battle_model_scope":"discard_draw_two_create_two_treasures_v1","draw_count":2,"effect":"treasure_maker","requires_discard_card":true,"treasure_count":2}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PiratesPillage mapped to family treasure_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('strike it rich', 'Strike It Rich', 'ac6a1738bb963034e826d875966ffca4', 'battle_rule_v1:64d1b921f178816f331ef011862f40ae', '{"ability_kind":"one_shot","battle_model_scope":"single_treasure_creation_v1","effect":"treasure_maker","treasure_count":1}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class StrikeItRich mapped to family treasure_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
),
rule_rows AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash,
    r.review_status,
    r.execution_status
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
)
SELECT
  p.card_name,
  p.normalized_name,
  p.logical_rule_key,
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS promoted_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS promoted_verified_auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS promoted_oracle_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg138_current_replay_batch_three_strike_pillage_electrod) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
