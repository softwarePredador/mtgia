BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.preview_static_cost_deck607_static_cost_reducer_preview_ AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('pearl medallion', 'the scarlet witch');

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('pearl medallion', 'Pearl Medallion', '77f7f449ee56143d6b63814fecd37176', 'battle_rule_v1:0d857d5b176cc91065a4754f5824ebf2', '{"ability_kind":"static","applies_to_controller":"source_controller","applies_to_spell_colors":["W"],"battle_model_scope":"static_cost_reduction_for_matching_spells_v1","cmc":2.0,"cost_reduction_applies_to":"spells_you_cast","cost_reduction_generic":1,"effect":"static_cost_reduction"}'::jsonb, '{"category":"support","effect":"static_cost_reduction","subtype":"cost_reducer","timing":"static"}'::jsonb, 'curated_xmage_batch_candidate', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PearlMedallion mapped to family static_cost_reducer; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('the scarlet witch', 'The Scarlet Witch', '6129fda2f5ae1f8edad5a2f2e77d05c2', 'battle_rule_v1:0b23c5f26d2bc884b7f506cdd9d422fc', '{"ability_kind":"static","applies_to_card_types":["instant","sorcery"],"applies_to_controller":"source_controller","battle_model_scope":"static_power_based_cost_reduction_for_instant_sorcery_mv4_plus_v1","cmc":3.0,"cost_reduction_amount_source":"source_power","cost_reduction_applies_to":"instant_sorcery_spells_you_cast","effect":"static_cost_reduction","minimum_mana_value":4}'::jsonb, '{"category":"support","effect":"static_cost_reduction","subtype":"cost_reducer","timing":"static"}'::jsonb, 'curated_xmage_batch_candidate', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TheScarletWitch mapped to family static_cost_reducer; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
),
  counts AS (
    SELECT p.card_name, p.normalized_name, p.oracle_hash, count(c.id) AS target_card_rows
    FROM proposed p
    LEFT JOIN public.cards c
      ON lower(c.name) = p.normalized_name
     AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
    GROUP BY p.card_name, p.normalized_name, p.oracle_hash
  )
  SELECT jsonb_agg(counts ORDER BY card_name)
    INTO v_missing
  FROM counts
  WHERE target_card_rows <> 1;

  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'XMage batch package abort: expected exactly one Oracle-hash-matched card row for every proposed card: %', v_missing;
  END IF;
END $$;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('pearl medallion', 'Pearl Medallion', '77f7f449ee56143d6b63814fecd37176', 'battle_rule_v1:0d857d5b176cc91065a4754f5824ebf2', '{"ability_kind":"static","applies_to_controller":"source_controller","applies_to_spell_colors":["W"],"battle_model_scope":"static_cost_reduction_for_matching_spells_v1","cmc":2.0,"cost_reduction_applies_to":"spells_you_cast","cost_reduction_generic":1,"effect":"static_cost_reduction"}'::jsonb, '{"category":"support","effect":"static_cost_reduction","subtype":"cost_reducer","timing":"static"}'::jsonb, 'curated_xmage_batch_candidate', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PearlMedallion mapped to family static_cost_reducer; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('the scarlet witch', 'The Scarlet Witch', '6129fda2f5ae1f8edad5a2f2e77d05c2', 'battle_rule_v1:0b23c5f26d2bc884b7f506cdd9d422fc', '{"ability_kind":"static","applies_to_card_types":["instant","sorcery"],"applies_to_controller":"source_controller","battle_model_scope":"static_power_based_cost_reduction_for_instant_sorcery_mv4_plus_v1","cmc":3.0,"cost_reduction_amount_source":"source_power","cost_reduction_applies_to":"instant_sorcery_spells_you_cast","effect":"static_cost_reduction","minimum_mana_value":4}'::jsonb, '{"category":"support","effect":"static_cost_reduction","subtype":"cost_reducer","timing":"static"}'::jsonb, 'curated_xmage_batch_candidate', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TheScarletWitch mapped to family static_cost_reducer; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
),
deprecated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'XMage batch package: deprecated stale shadow before curated batch rule upsert.')
  FROM proposed p
  WHERE r.normalized_name = p.normalized_name
    AND r.logical_rule_key <> p.logical_rule_key
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows FROM deprecated;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('pearl medallion', 'Pearl Medallion', '77f7f449ee56143d6b63814fecd37176', 'battle_rule_v1:0d857d5b176cc91065a4754f5824ebf2', '{"ability_kind":"static","applies_to_controller":"source_controller","applies_to_spell_colors":["W"],"battle_model_scope":"static_cost_reduction_for_matching_spells_v1","cmc":2.0,"cost_reduction_applies_to":"spells_you_cast","cost_reduction_generic":1,"effect":"static_cost_reduction"}'::jsonb, '{"category":"support","effect":"static_cost_reduction","subtype":"cost_reducer","timing":"static"}'::jsonb, 'curated_xmage_batch_candidate', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PearlMedallion mapped to family static_cost_reducer; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('the scarlet witch', 'The Scarlet Witch', '6129fda2f5ae1f8edad5a2f2e77d05c2', 'battle_rule_v1:0b23c5f26d2bc884b7f506cdd9d422fc', '{"ability_kind":"static","applies_to_card_types":["instant","sorcery"],"applies_to_controller":"source_controller","battle_model_scope":"static_power_based_cost_reduction_for_instant_sorcery_mv4_plus_v1","cmc":3.0,"cost_reduction_amount_source":"source_power","cost_reduction_applies_to":"instant_sorcery_spells_you_cast","effect":"static_cost_reduction","minimum_mana_value":4}'::jsonb, '{"category":"support","effect":"static_cost_reduction","subtype":"cost_reducer","timing":"static"}'::jsonb, 'curated_xmage_batch_candidate', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TheScarletWitch mapped to family static_cost_reducer; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
),
target_cards AS (
  SELECT p.*, c.id AS card_id, c.name AS db_card_name
  FROM proposed p
  JOIN public.cards c
    ON lower(c.name) = p.normalized_name
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
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
  FROM target_cards
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
