WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('aclazotz, deepest betrayal // temple of the dead', 'Aclazotz, Deepest Betrayal // Temple of the Dead', 'b1357b55b4ee3216faca778b2259e04a', 'battle_rule_v1:a29015235c68332879e75484e8b92857', '{"ability_kind":"triggered","battle_model_scope":"opponent_discards_land_create_bat_token_v1","cmc":5.0,"effect":"creature","flying":true,"lifelink":true,"opponent_discard_land_create_token":true,"power":4,"token_colors":["B"],"token_count":1,"token_flying":true,"token_name":"Bat Token","token_power":1,"token_subtype":"Bat","token_toughness":1,"toughness":4,"trigger":"opponent_discard"}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class AclazotzDeepestBetrayal mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('green goblin, nemesis', 'Green Goblin, Nemesis', '4ca8185ef506fd0f03bb0c3969d7aa82', 'battle_rule_v1:c02ded294d7d8154fcfccc25dd1f629a', '{"ability_kind":"triggered","battle_model_scope":"controller_discards_nonland_counter_land_treasure_v1","cmc":4.0,"controller_discard_counter_count":1,"controller_discard_counter_target_subtype":"Goblin","controller_discard_counter_type":"+1/+1","controller_discard_land_create_treasure":true,"controller_discard_nonland_add_plus_one_counter_to_controlled_subtype":true,"controller_discard_treasure_count":1,"controller_discard_treasure_tapped":true,"effect":"creature","flying":true,"power":3,"toughness":3,"trigger":"controller_discard"}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class GreenGoblinNemesis mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg215_discard_counter_bat_20260625_101926) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
