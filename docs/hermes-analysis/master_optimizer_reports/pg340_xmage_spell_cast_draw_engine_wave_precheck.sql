WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('beast whisperer', 'Beast Whisperer', '8ae7642655af89139030ceda78968296', 'battle_rule_v1:b9c07681c8beb7442495463ab61fae8a', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_draw_engine_v1","effect":"creature","is_creature_permanent":true,"spell_cast_draw_card_types":["creature"],"spell_cast_draw_count":1,"spell_cast_draw_optional":false,"trigger":"spell_cast","trigger_effect":"draw_cards","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BeastWhisperer translated into ManaLoom runtime scope xmage_spell_cast_draw_engine_v1. This row is package-ready only because the source signature is a narrow permanent with a triggered draw ability on casting matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('enchantress''s presence', 'Enchantress''s Presence', '8ec549b56e8dd63eaa55e354692aeeb0', 'battle_rule_v1:5135086e42d1436acde69e2963049fc2', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_draw_engine_v1","effect":"draw_engine","spell_cast_draw_card_types":["enchantment"],"spell_cast_draw_count":1,"spell_cast_draw_optional":false,"trigger":"spell_cast","trigger_effect":"draw_cards","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EnchantresssPresence translated into ManaLoom runtime scope xmage_spell_cast_draw_engine_v1. This row is package-ready only because the source signature is a narrow permanent with a triggered draw ability on casting matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jhoira, weatherlight captain', 'Jhoira, Weatherlight Captain', '37ce267db9dc6df937d567ec1d86b1ae', 'battle_rule_v1:350f340c89e6be0b8c30b6f51543a1a9', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_draw_engine_v1","effect":"creature","is_creature_permanent":true,"spell_cast_draw_count":1,"spell_cast_draw_optional":false,"spell_cast_draw_requires_historic":true,"trigger":"spell_cast","trigger_effect":"draw_cards","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JhoiraWeatherlightCaptain translated into ManaLoom runtime scope xmage_spell_cast_draw_engine_v1. This row is package-ready only because the source signature is a narrow permanent with a triggered draw ability on casting matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mesa enchantress', 'Mesa Enchantress', '567f73040c2c6c12ef9cbe370ef25d9e', 'battle_rule_v1:246d77743bfb29c4b70446acbdf7911c', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_draw_engine_v1","effect":"creature","is_creature_permanent":true,"spell_cast_draw_card_types":["enchantment"],"spell_cast_draw_count":1,"spell_cast_draw_optional":true,"trigger":"spell_cast","trigger_effect":"draw_cards","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MesaEnchantress translated into ManaLoom runtime scope xmage_spell_cast_draw_engine_v1. This row is package-ready only because the source signature is a narrow permanent with a triggered draw ability on casting matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('primordial sage', 'Primordial Sage', '1bf4c8bc8bf3bf77dea910fa710d6c3e', 'battle_rule_v1:6e687784043e72633218f1ac81c83d19', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_draw_engine_v1","effect":"creature","is_creature_permanent":true,"spell_cast_draw_card_types":["creature"],"spell_cast_draw_count":1,"spell_cast_draw_optional":true,"trigger":"spell_cast","trigger_effect":"draw_cards","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PrimordialSage translated into ManaLoom runtime scope xmage_spell_cast_draw_engine_v1. This row is package-ready only because the source signature is a narrow permanent with a triggered draw ability on casting matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reki, the history of kamigawa', 'Reki, the History of Kamigawa', '8a5d7cafe47bdacd003d08287ec4c329', 'battle_rule_v1:b2a991caf5017bfc3925fb3254d40ec9', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_draw_engine_v1","effect":"creature","is_creature_permanent":true,"spell_cast_draw_count":1,"spell_cast_draw_optional":false,"spell_cast_draw_required_supertypes":["legendary"],"trigger":"spell_cast","trigger_effect":"draw_cards","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RekiTheHistoryOfKamigawa translated into ManaLoom runtime scope xmage_spell_cast_draw_engine_v1. This row is package-ready only because the source signature is a narrow permanent with a triggered draw ability on casting matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('satyr enchanter', 'Satyr Enchanter', '8ec549b56e8dd63eaa55e354692aeeb0', 'battle_rule_v1:8d6ab43180600fed28961266f683b05e', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_draw_engine_v1","effect":"creature","is_creature_permanent":true,"spell_cast_draw_card_types":["enchantment"],"spell_cast_draw_count":1,"spell_cast_draw_optional":false,"trigger":"spell_cast","trigger_effect":"draw_cards","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SatyrEnchanter translated into ManaLoom runtime scope xmage_spell_cast_draw_engine_v1. This row is package-ready only because the source signature is a narrow permanent with a triggered draw ability on casting matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('secrets of the dead', 'Secrets of the Dead', '254b303ea0ace2fce8e81171431a4247', 'battle_rule_v1:2bfb54abfdfe4eb1447e33a4d6090b9f', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_draw_engine_v1","effect":"draw_engine","spell_cast_draw_count":1,"spell_cast_draw_optional":false,"spell_cast_draw_source_zone":"graveyard","trigger":"spell_cast","trigger_effect":"draw_cards","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SecretsOfTheDead translated into ManaLoom runtime scope xmage_spell_cast_draw_engine_v1. This row is package-ready only because the source signature is a narrow permanent with a triggered draw ability on casting matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sram, senior edificer', 'Sram, Senior Edificer', 'c84a07dd8f06a09598531be5727c800f', 'battle_rule_v1:c4ec947e48486c8f8e9e5d627bcc946a', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_draw_engine_v1","effect":"creature","is_creature_permanent":true,"spell_cast_draw_count":1,"spell_cast_draw_optional":false,"spell_cast_draw_required_subtypes":["aura","equipment","vehicle"],"trigger":"spell_cast","trigger_effect":"draw_cards","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SramSeniorEdificer translated into ManaLoom runtime scope xmage_spell_cast_draw_engine_v1. This row is package-ready only because the source signature is a narrow permanent with a triggered draw ability on casting matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tanufel rimespeaker', 'Tanufel Rimespeaker', 'b327d79a760e98113ecf3784b6b72f77', 'battle_rule_v1:2c57ce8c41e8dafab0f386dfd35da302', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_draw_engine_v1","effect":"creature","is_creature_permanent":true,"spell_cast_draw_count":1,"spell_cast_draw_mana_value_min":4,"spell_cast_draw_optional":false,"trigger":"spell_cast","trigger_effect":"draw_cards","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TanufelRimespeaker translated into ManaLoom runtime scope xmage_spell_cast_draw_engine_v1. This row is package-ready only because the source signature is a narrow permanent with a triggered draw ability on casting matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thunderous snapper', 'Thunderous Snapper', 'b727e0656a7ba1875095d876d73f2bc0', 'battle_rule_v1:b160ce1c45e80d9376bcaa588035f4dd', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_draw_engine_v1","effect":"creature","is_creature_permanent":true,"spell_cast_draw_count":1,"spell_cast_draw_mana_value_min":5,"spell_cast_draw_optional":false,"trigger":"spell_cast","trigger_effect":"draw_cards","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThunderousSnapper translated into ManaLoom runtime scope xmage_spell_cast_draw_engine_v1. This row is package-ready only because the source signature is a narrow permanent with a triggered draw ability on casting matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vedalken archmage', 'Vedalken Archmage', '0325adb114c77e90f81676f947fc9b1a', 'battle_rule_v1:23ec59e519653b081be50cdd798bcf75', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_draw_engine_v1","effect":"creature","is_creature_permanent":true,"spell_cast_draw_card_types":["artifact"],"spell_cast_draw_count":1,"spell_cast_draw_optional":false,"trigger":"spell_cast","trigger_effect":"draw_cards","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VedalkenArchmage translated into ManaLoom runtime scope xmage_spell_cast_draw_engine_v1. This row is package-ready only because the source signature is a narrow permanent with a triggered draw ability on casting matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('verduran enchantress', 'Verduran Enchantress', '567f73040c2c6c12ef9cbe370ef25d9e', 'battle_rule_v1:246d77743bfb29c4b70446acbdf7911c', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_draw_engine_v1","effect":"creature","is_creature_permanent":true,"spell_cast_draw_card_types":["enchantment"],"spell_cast_draw_count":1,"spell_cast_draw_optional":true,"trigger":"spell_cast","trigger_effect":"draw_cards","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VerduranEnchantress translated into ManaLoom runtime scope xmage_spell_cast_draw_engine_v1. This row is package-ready only because the source signature is a narrow permanent with a triggered draw ability on casting matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('whirlwind of thought', 'Whirlwind of Thought', '8d1b3def6e90f817443397013093da3a', 'battle_rule_v1:0a5df57593d441fead5b647bead37c3b', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_draw_engine_v1","effect":"draw_engine","spell_cast_draw_count":1,"spell_cast_draw_optional":false,"trigger":"noncreature_spell_cast","trigger_effect":"draw_cards","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WhirlwindOfThought translated into ManaLoom runtime scope xmage_spell_cast_draw_engine_v1. This row is package-ready only because the source signature is a narrow permanent with a triggered draw ability on casting matching spells with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
matched_cards AS (
  SELECT
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    c.id AS card_id,
    c.name AS db_card_name
  FROM proposed p
  LEFT JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
target_cards AS (
  SELECT
    normalized_name,
    card_name,
    oracle_hash,
    count(card_id) AS target_card_rows,
    min(card_id::text)::uuid AS canonical_card_id,
    min(db_card_name) AS canonical_card_name
  FROM matched_cards
  GROUP BY normalized_name, card_name, oracle_hash
),
rule_rows AS (
  SELECT p.normalized_name, count(r.*) AS existing_rule_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
  GROUP BY p.normalized_name
),
expected_rows AS (
  SELECT p.normalized_name, count(r.*) AS expected_rule_rows_before
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
  GROUP BY p.normalized_name
),
shadow_rows AS (
  SELECT p.normalized_name, count(r.*) AS would_deprecate_shadow_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key <> p.logical_rule_key
   AND r.review_status NOT IN ('deprecated', 'rejected')
   AND r.execution_status <> 'disabled'
  GROUP BY p.normalized_name
)
SELECT
  p.card_name,
  p.normalized_name,
  p.oracle_hash,
  p.logical_rule_key,
  p.shadow_handling,
  tc.target_card_rows,
  tc.canonical_card_id,
  rr.existing_rule_rows,
  er.expected_rule_rows_before,
  sr.would_deprecate_shadow_rows
FROM proposed p
JOIN target_cards tc USING (normalized_name, card_name, oracle_hash)
JOIN rule_rows rr USING (normalized_name)
JOIN expected_rows er USING (normalized_name)
JOIN shadow_rows sr USING (normalized_name)
ORDER BY p.card_name;
