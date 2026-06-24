WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('ancestral memories', 'Ancestral Memories', '3aa69ed94731337917538028728d9f35', 'battle_rule_v1:b3cae6304fa06122bbe9e880e6b425c1', '{"ability_kind":"one_shot","battle_model_scope":"look_top_n_pick_m_to_hand_rest_graveyard_v1","effect":"dig_to_hand","instant":false,"look_count":7,"pick_count":2,"remainder_destination":"graveyard","selection_destination":"hand"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","subtype":"library_selection","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class AncestralMemories mapped to family dig_spell; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('scattered thoughts', 'Scattered Thoughts', '7f20a11914b46f22bdaab8546b22b5b6', 'battle_rule_v1:8ca48cc5b636696b151dce8af41e6de3', '{"ability_kind":"one_shot","battle_model_scope":"look_top_n_pick_m_to_hand_rest_graveyard_v1","effect":"dig_to_hand","instant":true,"look_count":4,"pick_count":2,"remainder_destination":"graveyard","selection_destination":"hand"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","subtype":"library_selection","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ScatteredThoughts mapped to family dig_spell; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg164_dig_to_hand_20260624_103413) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
