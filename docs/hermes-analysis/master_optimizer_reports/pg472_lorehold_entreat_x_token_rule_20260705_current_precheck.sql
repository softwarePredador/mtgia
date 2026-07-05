WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES ('entreat the angels', 'Entreat the Angels', '30f38db3fe030a6002c9a8120d216ec8', 'battle_rule_v1:0ce4d97cb4f226cd2df5f9bdbdebc04e', '{"ability_kind": "one_shot", "battle_model_scope": "xmage_x_create_creature_tokens_spell_v1", "effect": "token_maker", "miracle": true, "miracle_cost": "{X}{W}{W}", "miracle_x_cost_symbol_count": 1, "native_miracle": true, "native_miracle_cost": "{X}{W}{W}", "native_miracle_runtime_status": "blocked_requires_x_miracle_cast_plan", "normal_mana_cost": "{X}{X}{W}{W}{W}", "sorcery": true, "token_colors": ["W"], "token_count_per_x": 1, "token_count_source": "x_value", "token_flying": true, "token_name": "Angel Token", "token_power": 4, "token_subtype": "Angel", "token_toughness": 4, "x_cost_symbol_count": 2, "x_spell": true, "xmage_ability_class": "MiracleAbility", "xmage_dynamic_value_class": "GetXValue", "xmage_effect_class": "CreateTokenEffect", "xmage_token_class": "AngelToken"}'::jsonb, '{"category": "finisher", "effect": "token_maker", "lane": "miracle_finisher", "subtype": "x_miracle_token_finisher"}'::jsonb, 'curated', 0.91, 'needs_review', 'review_only', 'PG472 review-only package: XMage exact class EntreatTheAngels uses CreateTokenEffect, AngelToken, GetXValue, and MiracleAbility. Normal XXWWW X-token runtime is covered, but native miracle XWW still requires an executable X miracle cast plan before auto execution.', 'preserve_existing_rows')
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
    ON lower(c.name) = p.normalized_name
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
    ON r.normalized_name = p.normalized_name
  GROUP BY p.normalized_name
),
expected_rows AS (
  SELECT p.normalized_name, count(r.*) AS expected_rule_rows_before
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON r.normalized_name = p.normalized_name
   AND r.logical_rule_key = p.logical_rule_key
  GROUP BY p.normalized_name
)
SELECT
  p.card_name,
  p.oracle_hash,
  p.logical_rule_key,
  p.review_status AS proposed_review_status,
  p.execution_status AS proposed_execution_status,
  tc.target_card_rows,
  tc.canonical_card_id,
  rr.existing_rule_rows,
  er.expected_rule_rows_before
FROM proposed p
JOIN target_cards tc USING (normalized_name, card_name, oracle_hash)
JOIN rule_rows rr USING (normalized_name)
JOIN expected_rows er USING (normalized_name);
