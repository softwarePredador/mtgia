WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('pact of negation', 'Pact of Negation', '262a21c885bcc509fa438d4ba3ead7d8', 'battle_rule_v1:395f96ea9a7b45f017ebef88b456663b', '{"ability_kind":"one_shot","battle_model_scope":"pact_of_negation_delayed_upkeep_counter_v1","delayed_upkeep_mana_payment":"{3}{U}{U}","effect":"counter_spell","instant":true,"lose_game_if_unpaid":true,"target":"spell"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PactOfNegation mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('swan song', 'Swan Song', 'f31d32e77db92d33647a4424c52ade5d', 'battle_rule_v1:9e1a27e7c6c194ebfab6c500503665a6', '{"ability_kind":"one_shot","battle_model_scope":"counter_enchantment_instant_sorcery_spell_target_controller_bird_v1","effect":"counter_spell","instant":true,"target":"enchantment_instant_or_sorcery_spell","target_controller_creates_token":{"colors":["U"],"count":1,"keywords":["flying"],"name":"Bird","power":2,"toughness":2}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SwanSong mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('an offer you can''t refuse', 'An Offer You Can''t Refuse', 'fd5c2cd66bcbe90bb2d072f0146d67b3', 'battle_rule_v1:eafa496b9179d9cbd3350b078d13f17e', '{"ability_kind":"one_shot","battle_model_scope":"counter_noncreature_spell_target_controller_treasure_two_v1","effect":"counter_spell","instant":true,"target":"noncreature_spell","target_controller_creates_treasure":2}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class AnOfferYouCantRefuse mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('refute', 'Refute', '08a27b0252c823f1a0d6532701925010', 'battle_rule_v1:41a3506a6969888f362a122077db87cb', '{"ability_kind":"one_shot","battle_model_scope":"counter_spell_draw_then_discard_v1","draw_then_discard":1,"effect":"counter_spell","instant":true,"target":"spell"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Refute mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('wizard''s retort', 'Wizard''s Retort', 'ff5f40a24723d9dbc7424b86099c51b1', 'battle_rule_v1:642383d239e504a8da473caca3b05597', '{"ability_kind":"one_shot","battle_model_scope":"counter_spell_costs_one_less_if_control_wizard_v1","cost_reduction_generic_if_control_wizard":1,"effect":"counter_spell","instant":true,"target":"spell"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class WizardsRetort mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
),
shadow_rows AS (
  SELECT p.normalized_name, count(r.*) AS would_deprecate_shadow_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON r.normalized_name = p.normalized_name
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
