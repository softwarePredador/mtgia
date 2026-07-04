BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg426_xmage_flash_auxiliary_residuals_new_server_2026070 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('bear trap', 'defender of chaos', 'defender of law', 'springjaw trap')
   OR normalized_name LIKE 'bear trap // %'
   OR normalized_name LIKE 'defender of chaos // %'
   OR normalized_name LIKE 'defender of law // %'
   OR normalized_name LIKE 'springjaw trap // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bear trap', 'Bear Trap', '96f5bf52ac3ff60d49307eda68e9bbb0', 'battle_rule_v1:f42916e2503558c6d07d0e4248ecfaa4', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"direct_damage","activated_self_sacrifice_damage":true,"activation_cost_colors":[],"activation_cost_generic":3,"activation_cost_mana":"{3}","activation_requires_sacrifice":true,"activation_requires_tap":true,"activation_sacrifice_cost":null,"amount":3,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","damage":3,"effect":"direct_damage","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DamageTargetEffect"}],"_keywords_are_self":true,"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_damage_v1","activated_damage_amount":3,"activated_effect":"direct_damage","activated_self_sacrifice_damage":true,"activation_cost_colors":[],"activation_cost_generic":3,"activation_cost_mana":"{3}","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","effect":"artifact","flash":true,"keywords":["flash"],"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_ability_classes":["FlashAbility","SimpleActivatedAbility"],"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"artifact","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BearTrap translated into ManaLoom runtime scope xmage_permanent_simple_activated_damage_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('defender of chaos', 'Defender of Chaos', '0a5067d02cd8e46a4bcbcc67b9410e61', 'battle_rule_v1:8a6d1d1f78df760eaa3d55060ed162c9', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_colors_creature_v1","effect":"creature","flash":true,"keywords":["flash"],"protection_from":["white"],"protection_from_colors":["white"],"static_effect":"self_protection_from_colors","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DefenderOfChaos translated into ManaLoom runtime scope xmage_static_self_protection_from_colors_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('defender of law', 'Defender of Law', 'fd4214bb098c9fa877e15d35d1a8f26f', 'battle_rule_v1:d63de8e51b839f8f151ea9dc27062ac9', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_colors_creature_v1","effect":"creature","flash":true,"keywords":["flash"],"protection_from":["red"],"protection_from_colors":["red"],"static_effect":"self_protection_from_colors","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DefenderOfLaw translated into ManaLoom runtime scope xmage_static_self_protection_from_colors_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('springjaw trap', 'Springjaw Trap', '0cfb147f3137086ad77e1697c480b0c3', 'battle_rule_v1:4af262b74796a9830c2e46d341bcc49b', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"direct_damage","activated_self_sacrifice_damage":true,"activation_cost_colors":[],"activation_cost_generic":4,"activation_cost_mana":"{4}","activation_requires_sacrifice":true,"activation_requires_tap":true,"activation_sacrifice_cost":null,"amount":3,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","damage":3,"effect":"direct_damage","target":"any_target","target_constraints":{"scope":"any_target"},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DamageTargetEffect"}],"_keywords_are_self":true,"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_damage_v1","activated_damage_amount":3,"activated_effect":"direct_damage","activated_self_sacrifice_damage":true,"activation_cost_colors":[],"activation_cost_generic":4,"activation_cost_mana":"{4}","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","effect":"artifact","flash":true,"keywords":["flash"],"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_ability_class":"SimpleActivatedAbility","xmage_ability_classes":["FlashAbility","SimpleActivatedAbility"],"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"artifact","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpringjawTrap translated into ManaLoom runtime scope xmage_permanent_simple_activated_damage_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('bear trap', 'Bear Trap', '96f5bf52ac3ff60d49307eda68e9bbb0', 'battle_rule_v1:f42916e2503558c6d07d0e4248ecfaa4', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"direct_damage","activated_self_sacrifice_damage":true,"activation_cost_colors":[],"activation_cost_generic":3,"activation_cost_mana":"{3}","activation_requires_sacrifice":true,"activation_requires_tap":true,"activation_sacrifice_cost":null,"amount":3,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","damage":3,"effect":"direct_damage","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DamageTargetEffect"}],"_keywords_are_self":true,"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_damage_v1","activated_damage_amount":3,"activated_effect":"direct_damage","activated_self_sacrifice_damage":true,"activation_cost_colors":[],"activation_cost_generic":3,"activation_cost_mana":"{3}","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","effect":"artifact","flash":true,"keywords":["flash"],"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_ability_classes":["FlashAbility","SimpleActivatedAbility"],"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"artifact","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BearTrap translated into ManaLoom runtime scope xmage_permanent_simple_activated_damage_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('defender of chaos', 'Defender of Chaos', '0a5067d02cd8e46a4bcbcc67b9410e61', 'battle_rule_v1:8a6d1d1f78df760eaa3d55060ed162c9', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_colors_creature_v1","effect":"creature","flash":true,"keywords":["flash"],"protection_from":["white"],"protection_from_colors":["white"],"static_effect":"self_protection_from_colors","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DefenderOfChaos translated into ManaLoom runtime scope xmage_static_self_protection_from_colors_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('defender of law', 'Defender of Law', 'fd4214bb098c9fa877e15d35d1a8f26f', 'battle_rule_v1:d63de8e51b839f8f151ea9dc27062ac9', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_colors_creature_v1","effect":"creature","flash":true,"keywords":["flash"],"protection_from":["red"],"protection_from_colors":["red"],"static_effect":"self_protection_from_colors","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DefenderOfLaw translated into ManaLoom runtime scope xmage_static_self_protection_from_colors_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('springjaw trap', 'Springjaw Trap', '0cfb147f3137086ad77e1697c480b0c3', 'battle_rule_v1:4af262b74796a9830c2e46d341bcc49b', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"direct_damage","activated_self_sacrifice_damage":true,"activation_cost_colors":[],"activation_cost_generic":4,"activation_cost_mana":"{4}","activation_requires_sacrifice":true,"activation_requires_tap":true,"activation_sacrifice_cost":null,"amount":3,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","damage":3,"effect":"direct_damage","target":"any_target","target_constraints":{"scope":"any_target"},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DamageTargetEffect"}],"_keywords_are_self":true,"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_damage_v1","activated_damage_amount":3,"activated_effect":"direct_damage","activated_self_sacrifice_damage":true,"activation_cost_colors":[],"activation_cost_generic":4,"activation_cost_mana":"{4}","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","effect":"artifact","flash":true,"keywords":["flash"],"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_ability_class":"SimpleActivatedAbility","xmage_ability_classes":["FlashAbility","SimpleActivatedAbility"],"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"artifact","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpringjawTrap translated into ManaLoom runtime scope xmage_permanent_simple_activated_damage_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('bear trap', 'Bear Trap', '96f5bf52ac3ff60d49307eda68e9bbb0', 'battle_rule_v1:f42916e2503558c6d07d0e4248ecfaa4', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"direct_damage","activated_self_sacrifice_damage":true,"activation_cost_colors":[],"activation_cost_generic":3,"activation_cost_mana":"{3}","activation_requires_sacrifice":true,"activation_requires_tap":true,"activation_sacrifice_cost":null,"amount":3,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","damage":3,"effect":"direct_damage","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DamageTargetEffect"}],"_keywords_are_self":true,"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_damage_v1","activated_damage_amount":3,"activated_effect":"direct_damage","activated_self_sacrifice_damage":true,"activation_cost_colors":[],"activation_cost_generic":3,"activation_cost_mana":"{3}","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","effect":"artifact","flash":true,"keywords":["flash"],"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_ability_classes":["FlashAbility","SimpleActivatedAbility"],"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"artifact","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BearTrap translated into ManaLoom runtime scope xmage_permanent_simple_activated_damage_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('defender of chaos', 'Defender of Chaos', '0a5067d02cd8e46a4bcbcc67b9410e61', 'battle_rule_v1:8a6d1d1f78df760eaa3d55060ed162c9', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_colors_creature_v1","effect":"creature","flash":true,"keywords":["flash"],"protection_from":["white"],"protection_from_colors":["white"],"static_effect":"self_protection_from_colors","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DefenderOfChaos translated into ManaLoom runtime scope xmage_static_self_protection_from_colors_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('defender of law', 'Defender of Law', 'fd4214bb098c9fa877e15d35d1a8f26f', 'battle_rule_v1:d63de8e51b839f8f151ea9dc27062ac9', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_colors_creature_v1","effect":"creature","flash":true,"keywords":["flash"],"protection_from":["red"],"protection_from_colors":["red"],"static_effect":"self_protection_from_colors","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DefenderOfLaw translated into ManaLoom runtime scope xmage_static_self_protection_from_colors_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('springjaw trap', 'Springjaw Trap', '0cfb147f3137086ad77e1697c480b0c3', 'battle_rule_v1:4af262b74796a9830c2e46d341bcc49b', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"direct_damage","activated_self_sacrifice_damage":true,"activation_cost_colors":[],"activation_cost_generic":4,"activation_cost_mana":"{4}","activation_requires_sacrifice":true,"activation_requires_tap":true,"activation_sacrifice_cost":null,"amount":3,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","damage":3,"effect":"direct_damage","target":"any_target","target_constraints":{"scope":"any_target"},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DamageTargetEffect"}],"_keywords_are_self":true,"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_damage_v1","activated_damage_amount":3,"activated_effect":"direct_damage","activated_self_sacrifice_damage":true,"activation_cost_colors":[],"activation_cost_generic":4,"activation_cost_mana":"{4}","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_damage_v1","effect":"artifact","flash":true,"keywords":["flash"],"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_ability_class":"SimpleActivatedAbility","xmage_ability_classes":["FlashAbility","SimpleActivatedAbility"],"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"artifact","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpringjawTrap translated into ManaLoom runtime scope xmage_permanent_simple_activated_damage_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
