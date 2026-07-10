WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('angel''s feather', 'Angel''s Feather', 'ebb29991d0f1a0b0308b4aa8d2470bb6', 'battle_rule_v1:7f669b4064cd3aba79509b3719f22009', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_any_player":true,"spell_cast_gain_life_optional":true,"spell_cast_gain_life_required_colors":["W"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"SpellCastAllTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AngelsFeather translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('demon''s horn', 'Demon''s Horn', '2e519ebb21b2192d902d05c674b66d8e', 'battle_rule_v1:99bad2d1c6a72913caa5a932afb8056d', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_any_player":true,"spell_cast_gain_life_optional":true,"spell_cast_gain_life_required_colors":["B"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"SpellCastAllTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DemonsHorn translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dragon''s claw', 'Dragon''s Claw', '01106f0c718a60bba4eb37ee26b98bc5', 'battle_rule_v1:7c74d4b0b1816df66cdeceb8551b9cdb', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_any_player":true,"spell_cast_gain_life_optional":true,"spell_cast_gain_life_required_colors":["R"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"SpellCastAllTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DragonsClaw translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kraken''s eye', 'Kraken''s Eye', '731908acaaf356b2801492a987f3fdf1', 'battle_rule_v1:d7025bc05f9319aef58aebd511653833', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_any_player":true,"spell_cast_gain_life_optional":true,"spell_cast_gain_life_required_colors":["U"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"KrakensEyeAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KrakensEye translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wurm''s tooth', 'Wurm''s Tooth', '0bd81e8c2b91822db1c7bdd73798d944', 'battle_rule_v1:d9b0b164dd03d62a2e48b0b80af59bbc', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_any_player":true,"spell_cast_gain_life_optional":true,"spell_cast_gain_life_required_colors":["G"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"WurmsToothAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WurmsTooth translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg712_spell_cast_any_player_life_gain_ne_20260710_175213) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
