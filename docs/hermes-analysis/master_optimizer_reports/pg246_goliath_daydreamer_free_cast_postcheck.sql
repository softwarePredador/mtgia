WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('goliath daydreamer', 'Goliath Daydreamer', '715d2c178b304a7c5e6beed655883851', 'battle_rule_v1:65521ad249354a62c78b7c29ab866ecd', '{"ability_kind":"triggered","attack_free_cast_counter_type":"dream","attack_may_cast_owned_exiled_card_with_counter_without_paying_mana":true,"battle_model_scope":"instant_sorcery_from_hand_exile_dream_counter_attack_free_cast_v1","effect":"free_cast","exiled_counter_type":"dream","power":4,"spell_cast_from_hand_card_types":["instant","sorcery"],"spell_cast_from_hand_exile_instead_of_graveyard":true,"toughness":4,"trigger":"instant_sorcery_cast_from_hand_and_attack"}'::jsonb, '{"category":"combo_value","effect":"free_cast","subtype":"cast_without_paying_mana","timing":"triggered_or_resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class GoliathDaydreamer mapped to family free_cast; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg246_goliath_daydreamer_free_cast_20260628_105607) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
