BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg607_damage_life_target_variants_new_se_20260707_095059 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('deadly riposte', 'joust through', 'kiss of death', 'sorin''s vengeance', 'soul shred', 'soul spike', 'spinning darkness', 'stolen grain', 'taste of blood', 'vampiric touch')
   OR normalized_name LIKE 'deadly riposte // %'
   OR normalized_name LIKE 'joust through // %'
   OR normalized_name LIKE 'kiss of death // %'
   OR normalized_name LIKE 'sorin''s vengeance // %'
   OR normalized_name LIKE 'soul shred // %'
   OR normalized_name LIKE 'soul spike // %'
   OR normalized_name LIKE 'spinning darkness // %'
   OR normalized_name LIKE 'stolen grain // %'
   OR normalized_name LIKE 'taste of blood // %'
   OR normalized_name LIKE 'vampiric touch // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
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
  counts AS (
    SELECT
      p.card_name,
      p.normalized_name,
      p.oracle_hash,
      count(c.id) AS target_card_rows,
      min(c.id::text)::uuid AS canonical_card_id
    FROM proposed p
    LEFT JOIN public.cards c
      ON (
           lower(c.name) = p.normalized_name
           OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
         )
     AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
    GROUP BY p.card_name, p.normalized_name, p.oracle_hash
  )
  SELECT jsonb_agg(counts ORDER BY card_name)
    INTO v_missing
  FROM counts
  WHERE target_card_rows < 1;

  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'XMage batch package abort: expected at least one Oracle-hash-matched card row for every proposed card: %', v_missing;
  END IF;
END $$;

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
deprecated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'XMage batch package: deprecated stale shadow before curated batch rule upsert.')
  FROM proposed p
  WHERE (
        r.normalized_name = p.normalized_name
        OR r.normalized_name LIKE p.normalized_name || ' // %'
      )
    AND p.shadow_handling <> 'preserve_existing_rows'
    AND r.logical_rule_key <> p.logical_rule_key
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows FROM deprecated;

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
  JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
canonical_target_cards AS (
  SELECT
    p.*,
    min(m.card_id::text)::uuid AS card_id,
    min(m.db_card_name) AS db_card_name
  FROM proposed p
  JOIN matched_cards m
    USING (normalized_name, card_name, oracle_hash)
  GROUP BY
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    p.logical_rule_key,
    p.effect_json,
    p.deck_role_json,
    p.source,
    p.confidence,
    p.review_status,
    p.execution_status,
    p.notes,
    p.shadow_handling
),
upserted AS (
  INSERT INTO public.card_battle_rules (
    normalized_name,
    card_id,
    card_name,
    effect_json,
    deck_role_json,
    source,
    confidence,
    review_status,
    rule_version,
    oracle_hash,
    notes,
    reviewed_by,
    reviewed_at,
    created_at,
    updated_at,
    last_seen_at,
    logical_rule_key,
    execution_status
  )
  SELECT
    normalized_name,
    card_id,
    db_card_name,
    effect_json,
    deck_role_json,
    source,
    confidence,
    review_status,
    2,
    oracle_hash,
    notes,
    'codex-xmage-batch',
    now(),
    now(),
    now(),
    now(),
    logical_rule_key,
    execution_status
  FROM canonical_target_cards
  ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE
  SET
    card_id = EXCLUDED.card_id,
    card_name = EXCLUDED.card_name,
    effect_json = EXCLUDED.effect_json,
    deck_role_json = EXCLUDED.deck_role_json,
    source = EXCLUDED.source,
    confidence = EXCLUDED.confidence,
    review_status = EXCLUDED.review_status,
    rule_version = EXCLUDED.rule_version,
    oracle_hash = EXCLUDED.oracle_hash,
    notes = EXCLUDED.notes,
    reviewed_by = EXCLUDED.reviewed_by,
    reviewed_at = EXCLUDED.reviewed_at,
    updated_at = EXCLUDED.updated_at,
    last_seen_at = EXCLUDED.last_seen_at,
    execution_status = EXCLUDED.execution_status
  RETURNING *
)
SELECT count(*) AS upserted_rows FROM upserted;

COMMIT;
