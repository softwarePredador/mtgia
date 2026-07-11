WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('beastcaller savant', 'Beastcaller Savant', '377d469bc5133f822592179495484481', 'battle_rule_v1:4e1ac64b55d5a6a30387c9e4960a297b', '{"_keywords_are_self":true,"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_restricted_mana_source_permanent_v1","conditional_mana_modes":[{"color":"W","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"U","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"B","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"R","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"G","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"keywords":["haste"],"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["ConditionalAnyColorManaAbility","HasteAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["ConditionalAnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BeastcallerSavant translated into ManaLoom runtime scope xmage_simple_tap_restricted_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('curious homunculus // voracious reader', 'Curious Homunculus // Voracious Reader', '29dca779d4d43708b0dc1a0d599e306f', 'battle_rule_v1:4c4569da91ea463c145f9409f3ff8f67', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_restricted_mana_source_permanent_v1","conditional_mana_modes":[{"color":"C","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["C"],"produces":"C","xmage_ability_classes":["BeginningOfUpkeepTriggeredAbility","ConditionalColorlessManaAbility","ProwessAbility","SimpleStaticAbility"],"xmage_effect_classes":["SpellsCostReductionControllerEffect","TransformSourceEffect"],"xmage_mana_ability_classes":["ConditionalColorlessManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CuriousHomunculus translated into ManaLoom runtime scope xmage_simple_tap_restricted_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('herd heirloom', 'Herd Heirloom', 'f02a5af674eb306b322e0583e61952d5', 'battle_rule_v1:2980bcca26e2eb39bbe1fc936cf1a6ad', '{"_keywords_are_self":true,"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_restricted_mana_source_permanent_v1","conditional_mana_modes":[{"color":"W","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"U","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"B","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"R","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"G","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"keywords":["trample"],"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produces":"WUBRG","xmage_ability_classes":["ConditionalAnyColorManaAbility","DealsCombatDamageToAPlayerTriggeredAbility","SimpleActivatedAbility","TrampleAbility"],"xmage_effect_classes":["DrawCardSourceControllerEffect","GainAbilityTargetEffect"],"xmage_mana_ability_classes":["ConditionalAnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HerdHeirloom translated into ManaLoom runtime scope xmage_simple_tap_restricted_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('humble naturalist', 'Humble Naturalist', '4db6d51e675ae38af560e0dd2eea4cf0', 'battle_rule_v1:02baef79930a6020aa304e70017ac47f', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_restricted_mana_source_permanent_v1","conditional_mana_modes":[{"color":"W","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"U","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"B","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"R","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"G","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["ConditionalAnyColorManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["ConditionalAnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HumbleNaturalist translated into ManaLoom runtime scope xmage_simple_tap_restricted_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ore-rich stalactite // cosmium catalyst', 'Ore-Rich Stalactite // Cosmium Catalyst', 'fdd3a3210d203f4d462e824002d87a05', 'battle_rule_v1:d6089d7e6f331bab1d12cdbc67cedcf8', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_restricted_mana_source_permanent_v1","conditional_mana_modes":[{"color":"R","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produced_mana_symbols":["R"],"produces":"R","xmage_ability_classes":["ConditionalColoredManaAbility","CraftAbility","SimpleActivatedAbility"],"xmage_effect_classes":["CosmiumCatalystEffect","OneShotEffect"],"xmage_mana_ability_classes":["ConditionalColoredManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OreRichStalactite translated into ManaLoom runtime scope xmage_simple_tap_restricted_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pelargir survivor', 'Pelargir Survivor', '3a0f5cdb5f344e9fbda22cf5696f439c', 'battle_rule_v1:74cea72a465b0a2b93ba9caced259133', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_restricted_mana_source_permanent_v1","conditional_mana_modes":[{"color":"W","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"},{"color":"U","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"},{"color":"B","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"},{"color":"R","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"},{"color":"G","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["ConditionalAnyColorManaAbility","SimpleActivatedAbility"],"xmage_effect_classes":["MillCardsTargetEffect"],"xmage_mana_ability_classes":["ConditionalAnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PelargirSurvivor translated into ManaLoom runtime scope xmage_simple_tap_restricted_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vodalian arcanist', 'Vodalian Arcanist', '9be7040c01ffd0f87b7152ae9064475c', 'battle_rule_v1:aaac34c3bb4f25a401d62975f76373f2', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_restricted_mana_source_permanent_v1","conditional_mana_modes":[{"color":"C","mode":"restricted_spell_mana","restriction":"instant_or_sorcery_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["C"],"produces":"C","xmage_ability_classes":["ConditionalColorlessManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["ConditionalColorlessManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VodalianArcanist translated into ManaLoom runtime scope xmage_simple_tap_restricted_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
