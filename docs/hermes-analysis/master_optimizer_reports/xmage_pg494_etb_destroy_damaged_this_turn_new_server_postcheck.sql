WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('fathom fleet cutthroat', 'Fathom Fleet Cutthroat', '54287d1bc91a2325e59cb5b8cc87572d', 'battle_rule_v1:997c57587cd2ed55a7bc2ef18efdf3fe', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"opponent","damaged_this_turn":true},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FathomFleetCutthroat translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vraska''s finisher', 'Vraska''s Finisher', 'b96118952d712f3bd93114a8c8429594', 'battle_rule_v1:7dd3b0bd5cb9a4fa81e54a33f392c683', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"],"controller_scope":"opponent","damaged_this_turn":true},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VraskasFinisher translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg494_etb_destroy_damaged_this_turn_new_20260705_083727) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
