WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('fate unraveler', 'Fate Unraveler', '00c95435fc1fca776d77acfae1c4f14a', 'battle_rule_v1:b7c666b69b93ec1c06833d417e6a9abb', '{"ability_kind":"triggered","battle_model_scope":"opponent_draws_card_damage_that_player_v1","effect":"creature","opponent_draw_damage_per_card":1,"power":3,"toughness":4,"trigger":"opponent_draw"}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FateUnraveler mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('underworld dreams', 'Underworld Dreams', 'ade82ae73b5e5030f19d03b541b04219', 'battle_rule_v1:601180f3d9a50d4670765427bde20c84', '{"ability_kind":"triggered","battle_model_scope":"opponent_draws_card_damage_that_player_v1","effect":"passive","opponent_draw_damage_per_card":1,"trigger":"opponent_draw"}'::jsonb, '{"category":"support","effect":"passive","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class UnderworldDreams mapped to family passive; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg178_opponent_draw_punishers_20260624_134852) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
