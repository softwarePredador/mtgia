WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('fact or fiction', 'Fact or Fiction', 'da85cd126972897c37373ad25ec5f867', 'battle_rule_v1:b5c5def7cc8d30af6e2c293ea0854a5c', '{"ability_kind":"one_shot","battle_model_scope":"reveal_top_n_split_two_piles_choose_one_hand_rest_graveyard_v1","chooser":"controller","effect":"pile_selection_draw","instant":true,"look_count":5,"pile_count":2,"remainder_destination":"graveyard","selection_destination":"hand","splitter":"opponent"}'::jsonb, '{"category":"draw","effect":"pile_selection_draw","subtype":"two_pile_reveal","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FactOrFiction mapped to family pile_selection_spell; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('steam augury', 'Steam Augury', '9be664a6ecce936cc53df5993a90cdcb', 'battle_rule_v1:e076e7cef34d9f0593c00df3e15059a7', '{"ability_kind":"one_shot","battle_model_scope":"reveal_top_n_split_two_piles_choose_one_hand_rest_graveyard_v1","chooser":"opponent","effect":"pile_selection_draw","instant":true,"look_count":5,"pile_count":2,"remainder_destination":"graveyard","selection_destination":"hand","splitter":"controller"}'::jsonb, '{"category":"draw","effect":"pile_selection_draw","subtype":"two_pile_reveal","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SteamAugury mapped to family pile_selection_spell; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg165_pile_selection_draw_20260624_104321) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
