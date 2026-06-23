WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('pact of negation', 'Pact of Negation', '262a21c885bcc509fa438d4ba3ead7d8', 'battle_rule_v1:395f96ea9a7b45f017ebef88b456663b', '{"ability_kind":"one_shot","battle_model_scope":"pact_of_negation_delayed_upkeep_counter_v1","delayed_upkeep_mana_payment":"{3}{U}{U}","effect":"counter_spell","instant":true,"lose_game_if_unpaid":true,"target":"spell"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PactOfNegation mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('swan song', 'Swan Song', 'f31d32e77db92d33647a4424c52ade5d', 'battle_rule_v1:9e1a27e7c6c194ebfab6c500503665a6', '{"ability_kind":"one_shot","battle_model_scope":"counter_enchantment_instant_sorcery_spell_target_controller_bird_v1","effect":"counter_spell","instant":true,"target":"enchantment_instant_or_sorcery_spell","target_controller_creates_token":{"colors":["U"],"count":1,"keywords":["flying"],"name":"Bird","power":2,"toughness":2}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SwanSong mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('an offer you can''t refuse', 'An Offer You Can''t Refuse', 'fd5c2cd66bcbe90bb2d072f0146d67b3', 'battle_rule_v1:eafa496b9179d9cbd3350b078d13f17e', '{"ability_kind":"one_shot","battle_model_scope":"counter_noncreature_spell_target_controller_treasure_two_v1","effect":"counter_spell","instant":true,"target":"noncreature_spell","target_controller_creates_treasure":2}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class AnOfferYouCantRefuse mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('refute', 'Refute', '08a27b0252c823f1a0d6532701925010', 'battle_rule_v1:41a3506a6969888f362a122077db87cb', '{"ability_kind":"one_shot","battle_model_scope":"counter_spell_draw_then_discard_v1","draw_then_discard":1,"effect":"counter_spell","instant":true,"target":"spell"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Refute mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('wizard''s retort', 'Wizard''s Retort', 'ff5f40a24723d9dbc7424b86099c51b1', 'battle_rule_v1:642383d239e504a8da473caca3b05597', '{"ability_kind":"one_shot","battle_model_scope":"counter_spell_costs_one_less_if_control_wizard_v1","cost_reduction_generic_if_control_wizard":1,"effect":"counter_spell","instant":true,"target":"spell"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class WizardsRetort mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
),
rule_rows AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash,
    r.review_status,
    r.execution_status
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON r.normalized_name = p.normalized_name
   AND r.logical_rule_key = p.logical_rule_key
)
SELECT
  p.card_name,
  p.normalized_name,
  p.logical_rule_key,
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS promoted_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS promoted_verified_auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS promoted_oracle_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg125_counter_variants_runtime_restore_20260623_235642) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
