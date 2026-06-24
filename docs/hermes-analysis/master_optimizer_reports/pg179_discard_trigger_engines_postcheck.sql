WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('feast of sanity', 'Feast of Sanity', '9d3f44ba9a777ab7510132842a854475', 'battle_rule_v1:8783617a8d44c4f2e0242d17976f8828', '{"ability_kind":"triggered","battle_model_scope":"controller_discards_card_damage_any_target_and_gain_life_v1","cmc":4.0,"controller_discard_damage_any_target":1,"controller_discard_gain_life":1,"effect":"passive","trigger":"controller_discard"}'::jsonb, '{"category":"support","effect":"passive","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FeastOfSanity mapped to family passive; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('geth''s grimoire', 'Geth''s Grimoire', '6f91d335d1e146eb8f4f7e034130fa67', 'battle_rule_v1:293ee48b9a46181e885a4e563ef5868c', '{"ability_kind":"triggered","battle_model_scope":"opponent_discards_card_may_draw_v1","cmc":4.0,"draw_on_enter":false,"effect":"draw_engine","opponent_discard_draw_per_card":1,"trigger":"opponent_discard"}'::jsonb, '{"category":"draw","effect":"draw_engine","timing":"static_or_activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class GethsGrimoire mapped to family draw_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('megrim', 'Megrim', '2bb00f8626aef78bae0a72196673b7ec', 'battle_rule_v1:3c0ccb6b440a3128acdd19b58ace0b1e', '{"ability_kind":"triggered","battle_model_scope":"opponent_discards_card_damage_that_player_v1","cmc":3.0,"effect":"passive","opponent_discard_damage_per_card":2,"trigger":"opponent_discard"}'::jsonb, '{"category":"support","effect":"passive","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Megrim mapped to family passive; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg179_discard_trigger_engines_20260624_140220) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
