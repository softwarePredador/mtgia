WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('gilanra, caller of wirewood', 'Gilanra, Caller of Wirewood', '2bea3dade1f9f92d10a0dfb71801c5e8', 'battle_rule_v1:fecd3cc5b5678dac55f2dbc16d7d883e', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_with_mana_spent_cast_trigger_v1","conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"mana_spent_cast_trigger":{"effects":[{"count":1,"effect":"draw_cards"}],"mana_value_gte":6,"spell_filter":"mana_value_gte"},"permanent_type":"creature","produced_mana_symbols":["G"],"produces":"G","xmage_ability_classes":["BasicManaAbility","GreenManaAbility","ManaSpentDelayedTriggeredAbility","PartnerAbility"],"xmage_auxiliary_ability_classes":["BasicManaAbility","ManaSpentDelayedTriggeredAbility","PartnerAbility"],"xmage_effect_classes":["CreateDelayedTriggeredAbilityEffect","DrawCardSourceControllerEffect"],"xmage_mana_ability_classes":["GreenManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GilanraCallerOfWirewood translated into ManaLoom runtime scope xmage_simple_tap_mana_source_with_mana_spent_cast_trigger_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lapis orb of dragonkind', 'Lapis Orb of Dragonkind', '3f0548e0ec530c46558c3517ae0bab50', 'battle_rule_v1:305beef99118ac78d750a3a1e4d4eca0', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_with_mana_spent_cast_trigger_v1","conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"mana_spent_cast_trigger":{"effects":[{"count":2,"effect":"scry"}],"spell_filter":"dragon_creature_spell"},"permanent_type":"artifact","produced_mana_symbols":["U"],"produces":"U","xmage_ability_classes":["BasicManaAbility","BlueManaAbility","ManaSpentDelayedTriggeredAbility"],"xmage_auxiliary_ability_classes":["BasicManaAbility","ManaSpentDelayedTriggeredAbility"],"xmage_effect_classes":["CreateDelayedTriggeredAbilityEffect","ScryEffect"],"xmage_mana_ability_classes":["BlueManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LapisOrbOfDragonkind translated into ManaLoom runtime scope xmage_simple_tap_mana_source_with_mana_spent_cast_trigger_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scaled nurturer', 'Scaled Nurturer', 'a91a2e5526969ab5f1997f8f9ae8e03b', 'battle_rule_v1:e6474bc6e59aeffc724328786ec793c7', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_with_mana_spent_cast_trigger_v1","conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"mana_spent_cast_trigger":{"effects":[{"amount":2,"effect":"gain_life"}],"spell_filter":"dragon_creature_spell"},"permanent_type":"creature","produced_mana_symbols":["G"],"produces":"G","xmage_ability_classes":["BasicManaAbility","GreenManaAbility","ManaSpentDelayedTriggeredAbility"],"xmage_auxiliary_ability_classes":["BasicManaAbility","ManaSpentDelayedTriggeredAbility"],"xmage_effect_classes":["CreateDelayedTriggeredAbilityEffect","GainLifeEffect"],"xmage_mana_ability_classes":["GreenManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScaledNurturer translated into ManaLoom runtime scope xmage_simple_tap_mana_source_with_mana_spent_cast_trigger_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
