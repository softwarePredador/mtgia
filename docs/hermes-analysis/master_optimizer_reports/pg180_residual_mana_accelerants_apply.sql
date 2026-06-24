BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg180_residual_mana_accelerants_20260624_140714 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('bloom tender', 'circle of dreams druid', 'ignoble hierarch', 'springleaf drum', 'noble hierarch', 'relic of legends', 'talisman of indulgence', 'moonsnare prototype')
   OR normalized_name LIKE 'bloom tender // %'
   OR normalized_name LIKE 'circle of dreams druid // %'
   OR normalized_name LIKE 'ignoble hierarch // %'
   OR normalized_name LIKE 'springleaf drum // %'
   OR normalized_name LIKE 'noble hierarch // %'
   OR normalized_name LIKE 'relic of legends // %'
   OR normalized_name LIKE 'talisman of indulgence // %'
   OR normalized_name LIKE 'moonsnare prototype // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
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
    AND r.logical_rule_key <> p.logical_rule_key
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows FROM deprecated;

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
    p.notes
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
