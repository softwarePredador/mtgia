WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('biblioplex assistant', 'Biblioplex Assistant', 'fd587c3c46f46820ea55e4163de1f779', 'battle_rule_v1:351e3672438267675e3d8dfe22660aa2', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_put_graveyard_card_on_library_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"library_top","etb_recursion_target":"instant_or_sorcery","etb_recursion_up_to_count":true,"flying":true,"keywords":["flying"],"library_controller":"self","target_constraints":{"card_types":["instant","sorcery"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"PutOnLibraryTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BiblioplexAssistant translated into ManaLoom runtime scope xmage_creature_etb_put_graveyard_card_on_library_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('monastery messenger', 'Monastery Messenger', 'aa82cdb03b699e96db46127f4867a8d0', 'battle_rule_v1:94aaaaf239eae59b262d36160e9c73b4', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_put_graveyard_card_on_library_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"library_top","etb_recursion_target":"noncreature_nonland","etb_recursion_up_to_count":true,"flying":true,"keywords":["flying","vigilance"],"library_controller":"self","target_constraints":{"controller":"self","exclude_card_types":["creature","land"],"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","trigger":"enters_battlefield","vigilance":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"PutOnLibraryTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MonasteryMessenger translated into ManaLoom runtime scope xmage_creature_etb_put_graveyard_card_on_library_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nantuko tracer', 'Nantuko Tracer', '1aec8047a1e4aa805b3237c36e07a9fc', 'battle_rule_v1:484429dec81b99b1ed9ecb46d0b2aceb', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_put_graveyard_card_on_library_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"library_bottom","etb_recursion_target":"any_card","library_controller":"owner","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","target_graveyard_controller":"any","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"PutOnLibraryTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NantukoTracer translated into ManaLoom runtime scope xmage_creature_etb_put_graveyard_card_on_library_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('swiftgear drake', 'Swiftgear Drake', '10a62aaa977503f63b1c8843d8068464', 'battle_rule_v1:f2df6636ba9501997f1d5e6577ff947a', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_put_graveyard_card_on_library_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"library_bottom","etb_recursion_target":"any_card","etb_recursion_up_to_count":true,"flying":true,"haste":true,"keywords":["flying","haste"],"library_controller":"owner","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","target_graveyard_controller":"any","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"PutOnLibraryTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SwiftgearDrake translated into ManaLoom runtime scope xmage_creature_etb_put_graveyard_card_on_library_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg356_xmage_etb_graveyard_to_library_extended_wave_xmage) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
