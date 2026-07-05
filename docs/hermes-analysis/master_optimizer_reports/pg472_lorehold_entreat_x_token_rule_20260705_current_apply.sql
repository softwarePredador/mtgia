BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg472_lorehold_entreat_x_token_rule_20260705_current AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name = 'entreat the angels';

DO $$
DECLARE
  v_target_rows int;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES ('entreat the angels', 'Entreat the Angels', '30f38db3fe030a6002c9a8120d216ec8', 'battle_rule_v1:0ce4d97cb4f226cd2df5f9bdbdebc04e', '{"ability_kind": "one_shot", "battle_model_scope": "xmage_x_create_creature_tokens_spell_v1", "effect": "token_maker", "miracle": true, "miracle_cost": "{X}{W}{W}", "miracle_x_cost_symbol_count": 1, "native_miracle": true, "native_miracle_cost": "{X}{W}{W}", "native_miracle_runtime_status": "blocked_requires_x_miracle_cast_plan", "normal_mana_cost": "{X}{X}{W}{W}{W}", "sorcery": true, "token_colors": ["W"], "token_count_per_x": 1, "token_count_source": "x_value", "token_flying": true, "token_name": "Angel Token", "token_power": 4, "token_subtype": "Angel", "token_toughness": 4, "x_cost_symbol_count": 2, "x_spell": true, "xmage_ability_class": "MiracleAbility", "xmage_dynamic_value_class": "GetXValue", "xmage_effect_class": "CreateTokenEffect", "xmage_token_class": "AngelToken"}'::jsonb, '{"category": "finisher", "effect": "token_maker", "lane": "miracle_finisher", "subtype": "x_miracle_token_finisher"}'::jsonb, 'curated', 0.91, 'needs_review', 'review_only', 'PG472 review-only package: XMage exact class EntreatTheAngels uses CreateTokenEffect, AngelToken, GetXValue, and MiracleAbility. Normal XXWWW X-token runtime is covered, but native miracle XWW still requires an executable X miracle cast plan before auto execution.', 'preserve_existing_rows')
),
  matched_cards AS (
    SELECT c.id
    FROM proposed p
    JOIN public.cards c
      ON lower(c.name) = p.normalized_name
     AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
  )
  SELECT count(*) INTO v_target_rows FROM matched_cards;

  IF v_target_rows <> 1 THEN
    RAISE EXCEPTION 'PG472 precondition failed: Entreat target card rows=% expected 1', v_target_rows;
  END IF;
END $$;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES ('entreat the angels', 'Entreat the Angels', '30f38db3fe030a6002c9a8120d216ec8', 'battle_rule_v1:0ce4d97cb4f226cd2df5f9bdbdebc04e', '{"ability_kind": "one_shot", "battle_model_scope": "xmage_x_create_creature_tokens_spell_v1", "effect": "token_maker", "miracle": true, "miracle_cost": "{X}{W}{W}", "miracle_x_cost_symbol_count": 1, "native_miracle": true, "native_miracle_cost": "{X}{W}{W}", "native_miracle_runtime_status": "blocked_requires_x_miracle_cast_plan", "normal_mana_cost": "{X}{X}{W}{W}{W}", "sorcery": true, "token_colors": ["W"], "token_count_per_x": 1, "token_count_source": "x_value", "token_flying": true, "token_name": "Angel Token", "token_power": 4, "token_subtype": "Angel", "token_toughness": 4, "x_cost_symbol_count": 2, "x_spell": true, "xmage_ability_class": "MiracleAbility", "xmage_dynamic_value_class": "GetXValue", "xmage_effect_class": "CreateTokenEffect", "xmage_token_class": "AngelToken"}'::jsonb, '{"category": "finisher", "effect": "token_maker", "lane": "miracle_finisher", "subtype": "x_miracle_token_finisher"}'::jsonb, 'curated', 0.91, 'needs_review', 'review_only', 'PG472 review-only package: XMage exact class EntreatTheAngels uses CreateTokenEffect, AngelToken, GetXValue, and MiracleAbility. Normal XXWWW X-token runtime is covered, but native miracle XWW still requires an executable X miracle cast plan before auto execution.', 'preserve_existing_rows')
),
matched_cards AS (
  SELECT
    p.*,
    c.id AS card_id,
    c.name AS db_card_name
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
    1,
    oracle_hash,
    notes,
    'codex-lorehold-pg472',
    now(),
    now(),
    now(),
    now(),
    logical_rule_key,
    execution_status
  FROM matched_cards
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
SELECT count(*) AS review_only_upserted_rows FROM upserted;

COMMIT;
