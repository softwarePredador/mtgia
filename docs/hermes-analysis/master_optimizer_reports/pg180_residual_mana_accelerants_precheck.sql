WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('bloom tender', 'Bloom Tender', '53c650c8e69bf2ce0d4cc005285b434d', 'battle_rule_v1:8e94566195ab70c01276e70051623cb7', '{"ability_kind":"activated","battle_model_scope":"one_one_color_diversity_mana_dork_v1","effect":"creature","is_mana_source":true,"mana_colors_from_controlled_permanents":true,"mana_produced_from_colors_among_permanents":true,"power":1,"produces":"WUBRG","toughness":1}'::jsonb, '{"category":"ramp","effect":"ramp_permanent","subtype":"mana_creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BloomTender mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('circle of dreams druid', 'Circle of Dreams Druid', '6d1aeff2f1a2c28c74054cde37cea58f', 'battle_rule_v1:1b04e8096e5702d2ba0f66645728f226', '{"ability_kind":"activated","battle_model_scope":"two_one_green_per_creature_mana_dork_v1","effect":"creature","is_mana_source":true,"mana_produced_from_controlled_creatures":true,"power":2,"produces":"G","toughness":1}'::jsonb, '{"category":"ramp","effect":"ramp_permanent","subtype":"mana_creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CircleOfDreamsDruid mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('ignoble hierarch', 'Ignoble Hierarch', 'dce5f09110d0296c91f79dd364780729', 'battle_rule_v1:f0668b054043b3db07eeb57e4cbd876e', '{"ability_kind":"activated","battle_model_scope":"one_mana_zero_one_exalted_tricolor_mana_dork_v1","effect":"creature","exalted":true,"is_mana_source":true,"mana_produced":1,"power":0,"produces":"BRG","toughness":1}'::jsonb, '{"category":"ramp","effect":"ramp_permanent","subtype":"mana_creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class IgnobleHierarch mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('springleaf drum', 'Springleaf Drum', 'bc0d67ab4c23dc0ffed1100c30eac1d5', 'battle_rule_v1:b822326189437e5554828b3b6ff001c1', '{"ability_kind":"activated","battle_model_scope":"creature_support_any_color_mana_rock_v1","effect":"ramp_permanent","mana_produced":1,"mana_source_requires_untapped_creature":true,"produces":"WUBRG"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SpringleafDrum mapped to family ramp_permanent; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('noble hierarch', 'Noble Hierarch', '6e78cce29d72fd81331490b36689fd29', 'battle_rule_v1:6039e5bf5989f3ab51feff2948bd0892', '{"ability_kind":"activated","battle_model_scope":"one_mana_zero_one_exalted_tricolor_mana_dork_v1","effect":"creature","exalted":true,"is_mana_source":true,"mana_produced":1,"power":0,"produces":"GWU","toughness":1}'::jsonb, '{"category":"ramp","effect":"ramp_permanent","subtype":"mana_creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class NobleHierarch mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('relic of legends', 'Relic of Legends', '3b506c9dca803c9b34a7a1ed49000ab5', 'battle_rule_v1:4f700f70db9f348cfc3c525b2c08e9d0', '{"ability_kind":"activated","battle_model_scope":"one_any_color_mana_rock_v1","effect":"ramp_permanent","mana_produced":1,"produces":"WUBRG"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class RelicOfLegends mapped to family ramp_permanent; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('talisman of indulgence', 'Talisman of Indulgence', 'b6f7ff0127d1c9fd2c33d81fa54b64f6', 'battle_rule_v1:aafb809ee99cacf080c12f3c92c84e19', '{"ability_kind":"activated","battle_model_scope":"pain_talisman_color_pair_partial_v1","effect":"ramp_permanent","life_for_colored_mana":1,"mana_produced":1,"produces":"CBR"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TalismanOfIndulgence mapped to family ramp_permanent; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('moonsnare prototype', 'Moonsnare Prototype', '7a8aa86fec6e5cbd6e1f9002d6e2c647', 'battle_rule_v1:867f951a27c7284910fe5e6dd23fbc57', '{"ability_kind":"activated","battle_model_scope":"artifact_or_creature_support_colorless_mana_rock_v1","effect":"ramp_permanent","mana_produced":1,"mana_source_requires_untapped_artifact_or_creature":true,"produces":"C"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class MoonsnarePrototype mapped to family ramp_permanent; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
