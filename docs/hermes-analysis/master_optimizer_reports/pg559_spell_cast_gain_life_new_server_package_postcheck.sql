WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('contemplation', 'Contemplation', 'd55138f0e38ce89501241de5118b997a', 'battle_rule_v1:63c245df679aa19fe5b18d2e9918493c', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_optional":false,"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Contemplation translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dawnhart geist', 'Dawnhart Geist', '39601a26e7cf06160f3dc44a7a719c47', 'battle_rule_v1:bd9635bdd9fdd90b5cf30c626862d4cb', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"creature","is_creature_permanent":true,"spell_cast_gain_life":true,"spell_cast_gain_life_amount":2,"spell_cast_gain_life_card_types":["enchantment"],"spell_cast_gain_life_optional":false,"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DawnhartGeist translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('god-pharaoh''s faithful', 'God-Pharaoh''s Faithful', 'ef011c7c90c65d91e901cd0fee8838ee', 'battle_rule_v1:95ab090f9dbca17d324bda0a4506f2da', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"creature","is_creature_permanent":true,"spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_optional":false,"spell_cast_gain_life_required_colors":["U","B","R"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GodPharaohsFaithful translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('student of ojutai', 'Student of Ojutai', '0e76bf14b5b22dd719205302193597cf', 'battle_rule_v1:f23e82b45102a808ec3347df3b9e20db', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"creature","is_creature_permanent":true,"spell_cast_gain_life":true,"spell_cast_gain_life_amount":2,"spell_cast_gain_life_optional":false,"trigger":"noncreature_spell_cast","trigger_effect":"gain_life","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StudentOfOjutai translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg559_spell_cast_gain_life_new_server_sp_20260706_100650) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
