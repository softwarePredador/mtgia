WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('deadly riposte', 'Deadly Riposte', '828dc896bdc14123907a824bc2ea6903', 'battle_rule_v1:91ef332cf9a3564d504b69d3a7e7193d', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":3,"effect":"direct_damage","gain_life":2,"instant":true,"sorcery":false,"target":"tapped_creature","target_constraints":{"card_types":["creature"],"tapped_state":"tapped"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"tapped_creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeadlyRiposte translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('joust through', 'Joust Through', 'e00e2b2e27811d348c98eac6ac8512ab', 'battle_rule_v1:c0803b01326684733246ecf321e2340f', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":1,"damage":3,"effect":"direct_damage","gain_life":1,"instant":true,"sorcery":false,"target":"attacking_or_blocking_creature","target_constraints":{"card_types":["creature"],"combat_state":"attacking_or_blocking"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"attacking_or_blocking_creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JoustThrough translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kiss of death', 'Kiss of Death', 'b4b1b9466bde86a7d4bc39a3f18207f7', 'battle_rule_v1:724158f47f0fc0f1ccfdbbb4ff687eea', '{"amount":4,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":4,"damage":4,"effect":"direct_damage","gain_life":4,"instant":false,"sorcery":true,"target":"opponent_or_planeswalker","target_constraints":{"scope":"opponent_or_planeswalker"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"opponent_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KissOfDeath translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sorin''s vengeance', 'Sorin''s Vengeance', '5401c85c3a83d51677939d3484c39742', 'battle_rule_v1:eb20910b419b6ac97a9e3c0a86b23973', '{"amount":10,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":10,"damage":10,"effect":"direct_damage","gain_life":10,"instant":false,"sorcery":true,"target":"player_or_planeswalker","target_constraints":{"scope":"player_or_planeswalker"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"player_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SorinsVengeance translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('soul shred', 'Soul Shred', 'b37068726ddbb54cdfa6cd28df01557d', 'battle_rule_v1:32a1e9755f09e0d9b05907579b4f153e', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":3,"damage":3,"effect":"direct_damage","gain_life":3,"instant":false,"sorcery":true,"target":"nonblack_creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"nonblack_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SoulShred translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('soul spike', 'Soul Spike', '614c79047afc07dad14f14f488dada0d', 'battle_rule_v1:b30ee9a5fcd603703d248235230ed80f', '{"amount":4,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":4,"damage":4,"effect":"direct_damage","gain_life":4,"instant":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SoulSpike translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spinning darkness', 'Spinning Darkness', '2561e07b514f9ac6f73f3b97b46e8246', 'battle_rule_v1:d291091aff24d2d4909f1594c326313a', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":3,"damage":3,"effect":"direct_damage","gain_life":3,"instant":true,"sorcery":false,"target":"nonblack_creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"nonblack_creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpinningDarkness translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stolen grain', 'Stolen Grain', 'ee81fbfe136dc894be32bf7e9430aeed', 'battle_rule_v1:b704bb09a733d5e521be85ffbe15b4d3', '{"amount":5,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":5,"damage":5,"effect":"direct_damage","gain_life":5,"instant":false,"sorcery":true,"target":"opponent_or_planeswalker","target_constraints":{"scope":"opponent_or_planeswalker"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"opponent_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StolenGrain translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('taste of blood', 'Taste of Blood', '61112b2e9a074b6010ab6ace7cd3657a', 'battle_rule_v1:1111d6f096c488d21ee0546808a14729', '{"amount":1,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":1,"damage":1,"effect":"direct_damage","gain_life":1,"instant":false,"sorcery":true,"target":"player_or_planeswalker","target_constraints":{"scope":"player_or_planeswalker"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"player_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TasteOfBlood translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vampiric touch', 'Vampiric Touch', 'dfebe66697b700444015f0d97a0f3e17', 'battle_rule_v1:62ca1f552078fd5873eada59caf77a96', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":2,"effect":"direct_damage","gain_life":2,"instant":false,"sorcery":true,"target":"opponent_or_planeswalker","target_constraints":{"scope":"opponent_or_planeswalker"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"opponent_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VampiricTouch translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
