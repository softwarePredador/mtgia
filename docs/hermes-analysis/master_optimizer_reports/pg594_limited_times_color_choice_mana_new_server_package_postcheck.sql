WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('abzan devotee', 'Abzan Devotee', '9c3a5db4e485b9bbc88ca9674cae5d2d', 'battle_rule_v1:ec27a3244974e2e7cc45b9291344b996', '{"_runtime_partial":true,"_runtime_partial_reason":"Only the XMage limited-times mana ability is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_limit_per_turn":1,"activation_mana_cost":"{1}","activation_requires_tap":false,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":false,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"creature","produces":"WBG","xmage_ability_classes":["LimitedTimesPerTurnActivatedManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_effect_classes":["AddManaFromColorChoicesEffect","ReturnSourceFromGraveyardToHandEffect"],"xmage_mana_ability_classes":["LimitedTimesPerTurnActivatedManaAbility"],"xmage_mana_effect_class":"AddManaFromColorChoicesEffect","xmage_unmodeled_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["ReturnSourceFromGraveyardToHandEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AbzanDevotee translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jeskai devotee', 'Jeskai Devotee', 'ed2d39b9737e32da59835c4f550998ef', 'battle_rule_v1:366a77726fbc36fee6bc986f7d5572f3', '{"_runtime_partial":true,"_runtime_partial_reason":"Only the XMage limited-times mana ability is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_limit_per_turn":1,"activation_mana_cost":"{1}","activation_requires_tap":false,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":false,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"creature","produces":"URW","xmage_ability_classes":["FlurryAbility","LimitedTimesPerTurnActivatedManaAbility"],"xmage_auxiliary_ability_classes":["FlurryAbility"],"xmage_effect_classes":["AddManaFromColorChoicesEffect","BoostSourceEffect"],"xmage_mana_ability_classes":["LimitedTimesPerTurnActivatedManaAbility"],"xmage_mana_effect_class":"AddManaFromColorChoicesEffect","xmage_unmodeled_auxiliary_ability_classes":["FlurryAbility"],"xmage_unmodeled_effect_classes":["BoostSourceEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JeskaiDevotee translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sultai devotee', 'Sultai Devotee', 'f2c9254c4ec58cbfaeeb0f55a6107a14', 'battle_rule_v1:ac00d4cfa40a1f39085818b69fd432d9', '{"ability_kind":"activated_mana","activation_limit_per_turn":1,"activation_mana_cost":"{1}","activation_requires_tap":false,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"keywords":["deathtouch"],"mana_activation_requires_tap":false,"mana_produced":1,"permanent_type":"creature","produces":"BGU","xmage_ability_classes":["DeathtouchAbility","LimitedTimesPerTurnActivatedManaAbility"],"xmage_effect_classes":["AddManaFromColorChoicesEffect"],"xmage_mana_ability_classes":["LimitedTimesPerTurnActivatedManaAbility"],"xmage_mana_effect_class":"AddManaFromColorChoicesEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SultaiDevotee translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('temur devotee', 'Temur Devotee', 'b8d5f929ccf01696c7e8523a5a842d47', 'battle_rule_v1:7a52921eb54b9b61f5cbd0adaf50745f', '{"ability_kind":"activated_mana","activation_limit_per_turn":1,"activation_mana_cost":"{1}","activation_requires_tap":false,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"keywords":["defender"],"mana_activation_requires_tap":false,"mana_produced":1,"permanent_type":"creature","produces":"GUR","xmage_ability_classes":["DefenderAbility","LimitedTimesPerTurnActivatedManaAbility"],"xmage_effect_classes":["AddManaFromColorChoicesEffect"],"xmage_mana_ability_classes":["LimitedTimesPerTurnActivatedManaAbility"],"xmage_mana_effect_class":"AddManaFromColorChoicesEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TemurDevotee translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg594_limited_times_color_choice_mana_ne_20260707_045626) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
