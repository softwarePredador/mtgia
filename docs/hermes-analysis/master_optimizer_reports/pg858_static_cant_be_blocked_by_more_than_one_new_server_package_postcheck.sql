WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bristling boar', 'Bristling Boar', 'bcb549218b34db88162050d1931b46ac', 'battle_rule_v1:e665aa82549400232d658ee0ea2b3c86', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_by_more_than_one_creature_v1","cant_be_blocked_by_more_than_one":true,"cant_be_blocked_by_more_than_one_creature":true,"effect":"creature","max_blocked_by":1,"max_blockers":1,"static_effect":"self_cant_be_blocked_by_more_than_one_creature","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"CantBeBlockedByMoreThanOneSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BristlingBoar translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_by_more_than_one_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('charging rhino', 'Charging Rhino', 'bcb549218b34db88162050d1931b46ac', 'battle_rule_v1:e665aa82549400232d658ee0ea2b3c86', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_by_more_than_one_creature_v1","cant_be_blocked_by_more_than_one":true,"cant_be_blocked_by_more_than_one_creature":true,"effect":"creature","max_blocked_by":1,"max_blockers":1,"static_effect":"self_cant_be_blocked_by_more_than_one_creature","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"CantBeBlockedByMoreThanOneSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ChargingRhino translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_by_more_than_one_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('huang zhong, shu general', 'Huang Zhong, Shu General', '96580290ff2f3bc38af6e36268c076ed', 'battle_rule_v1:e665aa82549400232d658ee0ea2b3c86', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_by_more_than_one_creature_v1","cant_be_blocked_by_more_than_one":true,"cant_be_blocked_by_more_than_one_creature":true,"effect":"creature","max_blocked_by":1,"max_blockers":1,"static_effect":"self_cant_be_blocked_by_more_than_one_creature","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"CantBeBlockedByMoreThanOneSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HuangZhongShuGeneral translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_by_more_than_one_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ironhoof ox', 'Ironhoof Ox', 'bcb549218b34db88162050d1931b46ac', 'battle_rule_v1:e665aa82549400232d658ee0ea2b3c86', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_by_more_than_one_creature_v1","cant_be_blocked_by_more_than_one":true,"cant_be_blocked_by_more_than_one_creature":true,"effect":"creature","max_blocked_by":1,"max_blockers":1,"static_effect":"self_cant_be_blocked_by_more_than_one_creature","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"CantBeBlockedByMoreThanOneSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IronhoofOx translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_by_more_than_one_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('norwood riders', 'Norwood Riders', 'bcb549218b34db88162050d1931b46ac', 'battle_rule_v1:e665aa82549400232d658ee0ea2b3c86', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_by_more_than_one_creature_v1","cant_be_blocked_by_more_than_one":true,"cant_be_blocked_by_more_than_one_creature":true,"effect":"creature","max_blocked_by":1,"max_blockers":1,"static_effect":"self_cant_be_blocked_by_more_than_one_creature","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"CantBeBlockedByMoreThanOneSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NorwoodRiders translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_by_more_than_one_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stalking tiger', 'Stalking Tiger', 'bcb549218b34db88162050d1931b46ac', 'battle_rule_v1:e665aa82549400232d658ee0ea2b3c86', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_be_blocked_by_more_than_one_creature_v1","cant_be_blocked_by_more_than_one":true,"cant_be_blocked_by_more_than_one_creature":true,"effect":"creature","max_blocked_by":1,"max_blockers":1,"static_effect":"self_cant_be_blocked_by_more_than_one_creature","target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"CantBeBlockedByMoreThanOneSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StalkingTiger translated into ManaLoom runtime scope xmage_static_self_cant_be_blocked_by_more_than_one_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg858_static_cant_be_blocked_by_more_tha_20260713_024015) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
