BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg411_triggered_recursion_to_hand_new_server_triggered_r AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('eternal taskmaster', 'pillardrop warden', 'the unspeakable')
   OR normalized_name LIKE 'eternal taskmaster // %'
   OR normalized_name LIKE 'pillardrop warden // %'
   OR normalized_name LIKE 'the unspeakable // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('eternal taskmaster', 'Eternal Taskmaster', '2d79b92556e0ed8ab221480fa5fd873d', 'battle_rule_v1:4022dff702a96dc4ab9837e68a1f30e0', '{"ability_kind":"triggered","attack_recursion_count":1,"attack_recursion_destination":"hand","attack_recursion_target":"creature","attack_recursion_trigger_cost_colors":["B"],"attack_recursion_trigger_cost_generic":2,"attack_recursion_trigger_cost_mana":"{2}{B}","attack_trigger_graveyard_recursion":true,"battle_model_scope":"xmage_permanent_attack_return_graveyard_card_to_hand_v1","effect":"creature","enters_tapped":true,"instant":false,"sorcery":false,"target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"trigger":"attack","xmage_ability_class":"AttacksTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EternalTaskmaster translated into ManaLoom runtime scope xmage_permanent_attack_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pillardrop warden', 'Pillardrop Warden', 'c32f8c92a5a3cd47b3cd510867bbf5c5', 'battle_rule_v1:decee249f26e77cc845acd6db9ba629a', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"recursion","activated_self_sacrifice_recursion":true,"activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_discard_count":0,"activation_discard_target":null,"activation_requires_sacrifice":true,"activation_requires_tap":true,"activation_timing":"sorcery","battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_hand_v1","count":1,"destination":"hand","effect":"recursion","graveyard_to_hand_destination":"hand","graveyard_to_hand_target":"instant_or_sorcery","graveyard_to_hand_target_count":1,"target":"instant_or_sorcery","target_constraints":{"card_types":["instant","sorcery"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_ability_class":"ActivateAsSorceryActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}],"_keywords_are_self":true,"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_hand_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":true,"activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_discard_count":0,"activation_discard_target":null,"activation_requires_sacrifice":true,"activation_requires_tap":true,"activation_timing":"sorcery","battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_hand_v1","effect":"creature","graveyard_to_hand_activation_cost_colors":[],"graveyard_to_hand_activation_cost_generic":2,"graveyard_to_hand_activation_cost_mana":"{2}","graveyard_to_hand_activation_discard_count":0,"graveyard_to_hand_activation_discard_target":null,"graveyard_to_hand_activation_requires_sacrifice":true,"graveyard_to_hand_activation_requires_tap":true,"graveyard_to_hand_activation_timing":"sorcery","graveyard_to_hand_destination":"hand","graveyard_to_hand_target":"instant_or_sorcery","graveyard_to_hand_target_count":1,"keywords":["reach"],"reach":true,"target":"instant_or_sorcery","target_constraints":{"card_types":["instant","sorcery"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_ability_class":"ActivateAsSorceryActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"instant_or_sorcery"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PillardropWarden translated into ManaLoom runtime scope xmage_permanent_simple_activated_graveyard_to_hand_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated graveyard-to-hand ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('the unspeakable', 'The Unspeakable', 'b1b6b05b9d4aea8f3ac0379433f54829', 'battle_rule_v1:2725808803ad0a91360ce43429ab4063', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_combat_damage_return_graveyard_card_to_hand_v1","combat_damage_player_graveyard_recursion":true,"combat_damage_recursion_count":1,"combat_damage_recursion_destination":"hand","combat_damage_recursion_target":"arcane_card","effect":"creature","flying":true,"instant":false,"keywords":["flying","trample"],"sorcery":false,"target_constraints":{"controller":"self","subtypes":["arcane"],"zone":"graveyard"},"trample":true,"trigger":"combat_damage_to_player","xmage_ability_class":"DealsCombatDamageToAPlayerTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TheUnspeakable translated into ManaLoom runtime scope xmage_creature_combat_damage_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('eternal taskmaster', 'Eternal Taskmaster', '2d79b92556e0ed8ab221480fa5fd873d', 'battle_rule_v1:4022dff702a96dc4ab9837e68a1f30e0', '{"ability_kind":"triggered","attack_recursion_count":1,"attack_recursion_destination":"hand","attack_recursion_target":"creature","attack_recursion_trigger_cost_colors":["B"],"attack_recursion_trigger_cost_generic":2,"attack_recursion_trigger_cost_mana":"{2}{B}","attack_trigger_graveyard_recursion":true,"battle_model_scope":"xmage_permanent_attack_return_graveyard_card_to_hand_v1","effect":"creature","enters_tapped":true,"instant":false,"sorcery":false,"target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"trigger":"attack","xmage_ability_class":"AttacksTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EternalTaskmaster translated into ManaLoom runtime scope xmage_permanent_attack_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pillardrop warden', 'Pillardrop Warden', 'c32f8c92a5a3cd47b3cd510867bbf5c5', 'battle_rule_v1:decee249f26e77cc845acd6db9ba629a', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"recursion","activated_self_sacrifice_recursion":true,"activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_discard_count":0,"activation_discard_target":null,"activation_requires_sacrifice":true,"activation_requires_tap":true,"activation_timing":"sorcery","battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_hand_v1","count":1,"destination":"hand","effect":"recursion","graveyard_to_hand_destination":"hand","graveyard_to_hand_target":"instant_or_sorcery","graveyard_to_hand_target_count":1,"target":"instant_or_sorcery","target_constraints":{"card_types":["instant","sorcery"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_ability_class":"ActivateAsSorceryActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}],"_keywords_are_self":true,"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_hand_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":true,"activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_discard_count":0,"activation_discard_target":null,"activation_requires_sacrifice":true,"activation_requires_tap":true,"activation_timing":"sorcery","battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_hand_v1","effect":"creature","graveyard_to_hand_activation_cost_colors":[],"graveyard_to_hand_activation_cost_generic":2,"graveyard_to_hand_activation_cost_mana":"{2}","graveyard_to_hand_activation_discard_count":0,"graveyard_to_hand_activation_discard_target":null,"graveyard_to_hand_activation_requires_sacrifice":true,"graveyard_to_hand_activation_requires_tap":true,"graveyard_to_hand_activation_timing":"sorcery","graveyard_to_hand_destination":"hand","graveyard_to_hand_target":"instant_or_sorcery","graveyard_to_hand_target_count":1,"keywords":["reach"],"reach":true,"target":"instant_or_sorcery","target_constraints":{"card_types":["instant","sorcery"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_ability_class":"ActivateAsSorceryActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"instant_or_sorcery"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PillardropWarden translated into ManaLoom runtime scope xmage_permanent_simple_activated_graveyard_to_hand_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated graveyard-to-hand ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('the unspeakable', 'The Unspeakable', 'b1b6b05b9d4aea8f3ac0379433f54829', 'battle_rule_v1:2725808803ad0a91360ce43429ab4063', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_combat_damage_return_graveyard_card_to_hand_v1","combat_damage_player_graveyard_recursion":true,"combat_damage_recursion_count":1,"combat_damage_recursion_destination":"hand","combat_damage_recursion_target":"arcane_card","effect":"creature","flying":true,"instant":false,"keywords":["flying","trample"],"sorcery":false,"target_constraints":{"controller":"self","subtypes":["arcane"],"zone":"graveyard"},"trample":true,"trigger":"combat_damage_to_player","xmage_ability_class":"DealsCombatDamageToAPlayerTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TheUnspeakable translated into ManaLoom runtime scope xmage_creature_combat_damage_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('eternal taskmaster', 'Eternal Taskmaster', '2d79b92556e0ed8ab221480fa5fd873d', 'battle_rule_v1:4022dff702a96dc4ab9837e68a1f30e0', '{"ability_kind":"triggered","attack_recursion_count":1,"attack_recursion_destination":"hand","attack_recursion_target":"creature","attack_recursion_trigger_cost_colors":["B"],"attack_recursion_trigger_cost_generic":2,"attack_recursion_trigger_cost_mana":"{2}{B}","attack_trigger_graveyard_recursion":true,"battle_model_scope":"xmage_permanent_attack_return_graveyard_card_to_hand_v1","effect":"creature","enters_tapped":true,"instant":false,"sorcery":false,"target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"trigger":"attack","xmage_ability_class":"AttacksTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EternalTaskmaster translated into ManaLoom runtime scope xmage_permanent_attack_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pillardrop warden', 'Pillardrop Warden', 'c32f8c92a5a3cd47b3cd510867bbf5c5', 'battle_rule_v1:decee249f26e77cc845acd6db9ba629a', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"recursion","activated_self_sacrifice_recursion":true,"activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_discard_count":0,"activation_discard_target":null,"activation_requires_sacrifice":true,"activation_requires_tap":true,"activation_timing":"sorcery","battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_hand_v1","count":1,"destination":"hand","effect":"recursion","graveyard_to_hand_destination":"hand","graveyard_to_hand_target":"instant_or_sorcery","graveyard_to_hand_target_count":1,"target":"instant_or_sorcery","target_constraints":{"card_types":["instant","sorcery"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_ability_class":"ActivateAsSorceryActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}],"_keywords_are_self":true,"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_hand_v1","activated_effect":"recursion","activated_self_sacrifice_recursion":true,"activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_discard_count":0,"activation_discard_target":null,"activation_requires_sacrifice":true,"activation_requires_tap":true,"activation_timing":"sorcery","battle_model_scope":"xmage_permanent_simple_activated_graveyard_to_hand_v1","effect":"creature","graveyard_to_hand_activation_cost_colors":[],"graveyard_to_hand_activation_cost_generic":2,"graveyard_to_hand_activation_cost_mana":"{2}","graveyard_to_hand_activation_discard_count":0,"graveyard_to_hand_activation_discard_target":null,"graveyard_to_hand_activation_requires_sacrifice":true,"graveyard_to_hand_activation_requires_tap":true,"graveyard_to_hand_activation_timing":"sorcery","graveyard_to_hand_destination":"hand","graveyard_to_hand_target":"instant_or_sorcery","graveyard_to_hand_target_count":1,"keywords":["reach"],"reach":true,"target":"instant_or_sorcery","target_constraints":{"card_types":["instant","sorcery"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_ability_class":"ActivateAsSorceryActivatedAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"instant_or_sorcery"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PillardropWarden translated into ManaLoom runtime scope xmage_permanent_simple_activated_graveyard_to_hand_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated graveyard-to-hand ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('the unspeakable', 'The Unspeakable', 'b1b6b05b9d4aea8f3ac0379433f54829', 'battle_rule_v1:2725808803ad0a91360ce43429ab4063', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_combat_damage_return_graveyard_card_to_hand_v1","combat_damage_player_graveyard_recursion":true,"combat_damage_recursion_count":1,"combat_damage_recursion_destination":"hand","combat_damage_recursion_target":"arcane_card","effect":"creature","flying":true,"instant":false,"keywords":["flying","trample"],"sorcery":false,"target_constraints":{"controller":"self","subtypes":["arcane"],"zone":"graveyard"},"trample":true,"trigger":"combat_damage_to_player","xmage_ability_class":"DealsCombatDamageToAPlayerTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TheUnspeakable translated into ManaLoom runtime scope xmage_creature_combat_damage_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
