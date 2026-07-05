WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES ('entreat the angels', 'Entreat the Angels', '30f38db3fe030a6002c9a8120d216ec8', 'battle_rule_v1:0ce4d97cb4f226cd2df5f9bdbdebc04e', '{"ability_kind": "one_shot", "battle_model_scope": "xmage_x_create_creature_tokens_spell_v1", "effect": "token_maker", "miracle": true, "miracle_cost": "{X}{W}{W}", "miracle_x_cost_symbol_count": 1, "native_miracle": true, "native_miracle_cost": "{X}{W}{W}", "native_miracle_runtime_status": "blocked_requires_x_miracle_cast_plan", "normal_mana_cost": "{X}{X}{W}{W}{W}", "sorcery": true, "token_colors": ["W"], "token_count_per_x": 1, "token_count_source": "x_value", "token_flying": true, "token_name": "Angel Token", "token_power": 4, "token_subtype": "Angel", "token_toughness": 4, "x_cost_symbol_count": 2, "x_spell": true, "xmage_ability_class": "MiracleAbility", "xmage_dynamic_value_class": "GetXValue", "xmage_effect_class": "CreateTokenEffect", "xmage_token_class": "AngelToken"}'::jsonb, '{"category": "finisher", "effect": "token_maker", "lane": "miracle_finisher", "subtype": "x_miracle_token_finisher"}'::jsonb, 'curated', 0.91, 'needs_review', 'review_only', 'PG472 review-only package: XMage exact class EntreatTheAngels uses CreateTokenEffect, AngelToken, GetXValue, and MiracleAbility. Normal XXWWW X-token runtime is covered, but native miracle XWW still requires an executable X miracle cast plan before auto execution.', 'preserve_existing_rows')
)
SELECT
  p.card_name,
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS package_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'needs_review' AND r.execution_status = 'review_only') AS review_only_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS oracle_hash_rows
FROM proposed p
LEFT JOIN public.card_battle_rules r
  ON r.normalized_name = p.normalized_name
GROUP BY p.card_name, p.oracle_hash, p.logical_rule_key;
