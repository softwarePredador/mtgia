WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('organ hoarder', 'Organ Hoarder', 'c2f297be9e3d0e06dae49b218bf06dc4', 'battle_rule_v1:c78db6f977f2c197ed392b09b6b27854', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1","destination":"hand","effect":"creature","etb_library_look_count":3,"etb_library_pick_count":1,"etb_library_pick_target":"any_card","etb_library_rest_destination":"graveyard","rest_destination":"graveyard","target":"any_card","target_constraints":{"controller":"self","scope":"any_card","zone":"library"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OrganHoarder translated into ManaLoom runtime scope xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sibsig appraiser', 'Sibsig Appraiser', '9d408a209761378f0e6775b2bc1ecaa8', 'battle_rule_v1:b9536bcbbd85f20b8378e7de12d75f0a', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1","destination":"hand","effect":"creature","etb_library_look_count":2,"etb_library_pick_count":1,"etb_library_pick_target":"any_card","etb_library_rest_destination":"graveyard","rest_destination":"graveyard","target":"any_card","target_constraints":{"controller":"self","scope":"any_card","zone":"library"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SibsigAppraiser translated into ManaLoom runtime scope xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sultai soothsayer', 'Sultai Soothsayer', 'bb52caa787d5f836bd84a6ba9d3417ca', 'battle_rule_v1:5527f31e2c1daa1ee88e56c071123e92', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1","destination":"hand","effect":"creature","etb_library_look_count":4,"etb_library_pick_count":1,"etb_library_pick_target":"any_card","etb_library_rest_destination":"graveyard","rest_destination":"graveyard","target":"any_card","target_constraints":{"controller":"self","scope":"any_card","zone":"library"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SultaiSoothsayer translated into ManaLoom runtime scope xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tower geist', 'Tower Geist', '9522ce486df1ae011dc33de1955e5094', 'battle_rule_v1:ce47d20396337f2e63bd4298947f9873', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1","destination":"hand","effect":"creature","etb_library_look_count":2,"etb_library_pick_count":1,"etb_library_pick_target":"any_card","etb_library_rest_destination":"graveyard","flying":true,"keywords":["flying"],"rest_destination":"graveyard","target":"any_card","target_constraints":{"controller":"self","scope":"any_card","zone":"library"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TowerGeist translated into ManaLoom runtime scope xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg339_xmage_etb_library_pick_wave_pg339_xmage_etb_librar) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
