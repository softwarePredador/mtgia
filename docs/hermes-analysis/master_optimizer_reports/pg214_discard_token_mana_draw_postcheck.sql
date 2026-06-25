WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('bone miser', 'Bone Miser', 'fd488c9f31f4c6a6a0f6343ff12ed46b', 'battle_rule_v1:470c595610435ab6794ef9ec95c7636f', '{"ability_kind":"triggered","battle_model_scope":"controller_discards_card_type_token_mana_draw_v1","controller_discard_creature_create_token":true,"controller_discard_land_add_mana_amount":2,"controller_discard_land_add_mana_color":"black","controller_discard_noncreature_nonland_draw_cards":1,"effect":"creature","power":4,"token_colors":["B"],"token_count":1,"token_name":"Zombie Token","token_power":2,"token_subtype":"Zombie","token_toughness":2,"toughness":4,"trigger":"controller_discard"}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BoneMiser mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('waste not', 'Waste Not', '895721527ac6fe6536d86e71be74e74d', 'battle_rule_v1:6e985605c5bb457da0b684ed919d469e', '{"ability_kind":"triggered","battle_model_scope":"opponent_discards_card_type_token_mana_draw_v1","effect":"token_maker","opponent_discard_creature_create_token":true,"opponent_discard_land_add_mana_amount":2,"opponent_discard_land_add_mana_color":"black","opponent_discard_noncreature_nonland_draw_cards":1,"token_colors":["B"],"token_count":1,"token_name":"Zombie Token","token_power":2,"token_subtype":"Zombie","token_toughness":2,"trigger":"opponent_discard"}'::jsonb, '{"category":"board_development","effect":"token_maker","timing":"resolution_or_trigger"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class WasteNot mapped to family token_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg214_discard_token_mana_draw_20260625_095341) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
