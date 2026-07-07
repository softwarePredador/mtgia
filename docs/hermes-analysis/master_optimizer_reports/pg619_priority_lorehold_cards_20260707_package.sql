BEGIN;

WITH verified_rules(normalized_name, logical_rule_key) AS (
  VALUES
    ('farewell', 'battle_rule_v1:c5aef30c5a5904e02c4cfe40957080d3'),
    ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'),
    ('flawless maneuver', 'battle_rule_v1:73622071c1ad89267708f914a0729bf2'),
    ('land tax', 'battle_rule_v1:e3f5f35c6a9ee4fd8c7b9972c4152bef'),
    ('library of leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3'),
    ('lorehold, the historian', 'battle_rule_v1:06d892f8ad75831f785aef6dcedc82b4'),
    ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2'),
    ('swords to plowshares', 'battle_rule_v1:379008f3f03f94258292123453e3041c'),
    ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470'),
    ('teferi''s protection', 'battle_rule_v1:c8b6905f312e06fe599dfb81bf4f3f4a')
)
UPDATE public.card_battle_rules r
SET
  review_status = 'verified',
  oracle_hash = md5(COALESCE(c.oracle_text, '')),
  reviewed_by = 'codex_priority_lorehold_cards_2026_07_07',
  reviewed_at = CURRENT_TIMESTAMP,
  updated_at = CURRENT_TIMESTAMP,
  notes = CASE
    WHEN COALESCE(r.notes, '') LIKE '%Runtime verified on 2026-07-07%'
      THEN r.notes
    ELSE trim(COALESCE(r.notes, '') || ' Runtime verified on 2026-07-07 by test_priority_lorehold_card_runtime.py focused family coverage.')
  END
FROM verified_rules v, public.cards c
WHERE r.normalized_name = v.normalized_name
  AND r.logical_rule_key = v.logical_rule_key
  AND r.card_id = c.id
  AND r.execution_status = 'auto';

WITH thor_card AS (
  SELECT id
  FROM public.cards
  WHERE name = 'Thor, God of Thunder'
  ORDER BY id
  LIMIT 1
)
INSERT INTO public.card_battle_rules (
  normalized_name,
  logical_rule_key,
  card_id,
  card_name,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  execution_status,
  rule_version,
  oracle_hash,
  notes,
  reviewed_by,
  reviewed_at,
  created_at,
  updated_at,
  last_seen_at
)
SELECT
  'thor, god of thunder',
  'battle_rule_v1:280e17ec34ac105baeb6989491c6ff25',
  thor_card.id,
  'Thor, God of Thunder',
  '{
    "cmc": 5.0,
    "effect": "creature",
    "is_creature_permanent": true,
    "power": 5,
    "toughness": 5,
    "flying": true,
    "trigger": "noncreature_spell_cast",
    "trigger_effect": "damage_any_target",
    "trigger_damage_amount_source": "trigger_spell_mana_value",
    "etb_exile_target_from_own_graveyard": true,
    "etb_exile_target_types": ["Equipment", "Instant", "Sorcery"],
    "etb_exiled_card_playable_until_next_turn": true,
    "etb_graveyard_recast_annotation": true,
    "battle_model_scope": "etb_graveyard_impulse_recast_noncreature_spell_damage_any_target_v1"
  }'::jsonb,
  '{
    "category": "engine",
    "effect": "creature",
    "subtype": "noncreature_spell_damage_recursion_payoff",
    "strategy_role": "spell_damage_payoff_and_graveyard_recast"
  }'::jsonb,
  'curated',
  0.900,
  'verified',
  'auto',
  1,
  '0f2238f2ce8e4f2c0bbc2d5cea55f4d7',
  'Runtime verified on 2026-07-07: noncreature spell damage trigger deals trigger spell mana value to any target; ETB graveyard recast branch remains explicit annotation.',
  'codex_priority_lorehold_cards_2026_07_07',
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP
FROM thor_card
ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE SET
  card_id = COALESCE(EXCLUDED.card_id, public.card_battle_rules.card_id),
  card_name = EXCLUDED.card_name,
  effect_json = EXCLUDED.effect_json,
  deck_role_json = EXCLUDED.deck_role_json,
  source = EXCLUDED.source,
  confidence = EXCLUDED.confidence,
  review_status = EXCLUDED.review_status,
  execution_status = EXCLUDED.execution_status,
  oracle_hash = EXCLUDED.oracle_hash,
  notes = EXCLUDED.notes,
  reviewed_by = EXCLUDED.reviewed_by,
  reviewed_at = CURRENT_TIMESTAMP,
  updated_at = CURRENT_TIMESTAMP,
  last_seen_at = CURRENT_TIMESTAMP;

WITH tag_rows(card_name, tag, confidence, evidence) AS (
  VALUES
    ('Furygale Flocking', 'big_spell', 0.88, 'Oracle/runtime: graveyard-discounted large sorcery.'),
    ('Furygale Flocking', 'token_maker', 0.92, 'Oracle/runtime: creates two 3/3 flying haste Elementals for each opponent.'),
    ('Furygale Flocking', 'payoff', 0.84, 'Oracle/runtime: converts instant/sorcery graveyard density into board pressure.'),
    ('Molecule Man', 'engine', 0.95, 'Oracle/runtime: static nonland hand miracle zero engine.'),
    ('Molecule Man', 'enabler', 0.94, 'Oracle/runtime: enables first-draw miracle casting for nonland cards.'),
    ('Molecule Man', 'combo_piece', 0.88, 'Oracle/runtime: zero-cost miracle engine creates high-ceiling combo lines.'),
    ('Pearl Medallion', 'ramp', 0.90, 'Oracle/XMage: white spell cost reduction functions as color-bound ramp.'),
    ('Pearl Medallion', 'enabler', 0.84, 'Oracle/XMage: reduces cost of white spell sequences.'),
    ('Prismari Pianist', 'token_maker', 0.92, 'Oracle/runtime: instant/sorcery casts create Elemental tokens.'),
    ('Prismari Pianist', 'spellslinger', 0.90, 'Oracle/runtime: payoff is triggered by instant/sorcery casting.'),
    ('Prismari Pianist', 'payoff', 0.86, 'Oracle/runtime: scales token output for mana value 5+ spells.'),
    ('Redirect Lightning', 'protection', 0.86, 'Oracle/runtime: retargets a single-target spell or ability away from key targets.'),
    ('Redirect Lightning', 'removal', 0.78, 'Oracle/runtime: redirection can convert targeted interaction into opposing removal.'),
    ('The Mind Stone', 'ramp', 0.90, 'Oracle/runtime: taps for white mana.'),
    ('The Mind Stone', 'blink', 0.92, 'Oracle/runtime: harnessed infinity ability blinks another nonland permanent at end step.'),
    ('The Mind Stone', 'engine', 0.86, 'Oracle/runtime: repeatable end-step blink engine after harness.'),
    ('The Mind Stone', 'artifact_synergy', 0.80, 'Oracle/runtime: legendary artifact engine.'),
    ('The Scarlet Witch', 'spellslinger', 0.92, 'Oracle/runtime: instant/sorcery mana value 4+ cost reducer.'),
    ('The Scarlet Witch', 'engine', 0.88, 'Oracle/runtime: power-based cost reduction engine.'),
    ('The Scarlet Witch', 'enabler', 0.86, 'Oracle/runtime: enables big instant/sorcery turns.'),
    ('The Scarlet Witch', 'big_spell', 0.84, 'Oracle/runtime: applies to instant/sorcery spells with mana value 4 or greater.'),
    ('Thor, God of Thunder', 'spellslinger', 0.90, 'Oracle/runtime: noncreature spell casts trigger damage.'),
    ('Thor, God of Thunder', 'payoff', 0.90, 'Oracle/runtime: converts noncreature spell mana value into damage.'),
    ('Thor, God of Thunder', 'removal', 0.82, 'Oracle/runtime: damage trigger can target creatures or players.'),
    ('Thor, God of Thunder', 'recursion', 0.78, 'Oracle/runtime: ETB temporary play access for Equipment/instant/sorcery from graveyard.'),
    ('Turbulent Steppe', 'land', 0.95, 'Oracle/XMage: Mountain Plains land identity.'),
    ('Turbulent Steppe', 'ramp', 0.82, 'Oracle/XMage: red/white mana source with conditional tapped entry.')
)
INSERT INTO public.card_function_tags (
  card_id,
  card_name,
  tag,
  confidence,
  source,
  evidence,
  updated_at
)
SELECT
  c.id,
  tag_rows.card_name,
  tag_rows.tag,
  tag_rows.confidence,
  'priority_lorehold_functional_tags_2026_07_07',
  tag_rows.evidence,
  CURRENT_TIMESTAMP
FROM tag_rows
JOIN public.cards c ON c.name = tag_rows.card_name
ON CONFLICT (card_id, tag, source) DO UPDATE SET
  card_name = EXCLUDED.card_name,
  confidence = EXCLUDED.confidence,
  evidence = EXCLUDED.evidence,
  updated_at = CURRENT_TIMESTAMP;

WITH semantic_rows(
  card_name, speed, mana_efficiency, card_advantage_type, interaction_scope,
  combo_piece, wincon, engine, payoff, enabler, protection_type,
  recursion_type, role_confidence, explanation_reason, tags
) AS (
  VALUES
    ('Furygale Flocking', 'late', 'graveyard_discounted', 'token_board', 'combat_pressure', false, true, false, true, false, 'none', 'none', 0.88, 'Creates evasive hasty Elemental pressure per opponent and discounts from instant/sorcery graveyard density.', $$[{"tag":"big_spell","confidence":0.88,"evidence":"graveyard-discounted large sorcery"},{"tag":"token_maker","confidence":0.92,"evidence":"creates two 3/3 flying haste Elementals for each opponent"},{"tag":"payoff","confidence":0.84,"evidence":"instant/sorcery graveyard density payoff"}]$$::jsonb),
    ('Molecule Man', 'engine', 'miracle_zero', 'cost_cheat', 'none', true, false, true, false, true, 'none', 'none', 0.94, 'Static engine grants miracle zero to nonland cards in hand.', $$[{"tag":"engine","confidence":0.95,"evidence":"nonland hand miracle zero static"},{"tag":"enabler","confidence":0.94,"evidence":"enables miracle casting"},{"tag":"combo_piece","confidence":0.88,"evidence":"zero-cost miracle engine"}]$$::jsonb),
    ('Pearl Medallion', 'early', 'cost_reduction', 'none', 'none', false, false, false, false, true, 'none', 'none', 0.88, 'Color-bound white spell cost reducer.', $$[{"tag":"ramp","confidence":0.90,"evidence":"white spell cost reduction"},{"tag":"enabler","confidence":0.84,"evidence":"supports white spell sequencing"}]$$::jsonb),
    ('Prismari Pianist', 'mid', 'spell_payoff', 'token_board', 'none', false, false, true, true, false, 'none', 'none', 0.89, 'Instant/sorcery cast payoff that creates Elemental tokens and scales for mana value 5+ spells.', $$[{"tag":"token_maker","confidence":0.92,"evidence":"instant/sorcery casts create Elementals"},{"tag":"spellslinger","confidence":0.90,"evidence":"triggered by instant/sorcery casts"},{"tag":"payoff","confidence":0.86,"evidence":"larger payoff for MV 5+ spells"}]$$::jsonb),
    ('Redirect Lightning', 'instant', 'additional_cost_choice', 'none', 'single_target_redirect', false, false, false, false, true, 'redirect', 'none', 0.82, 'Instant-speed retarget effect for a spell or ability with a single target.', $$[{"tag":"protection","confidence":0.86,"evidence":"redirects targeted spell or ability"},{"tag":"removal","confidence":0.78,"evidence":"can redirect targeted interaction offensively"}]$$::jsonb),
    ('The Mind Stone', 'early', 'mana_rock_plus_harness', 'blink_value', 'none', false, false, true, false, true, 'none', 'none', 0.88, 'Legendary artifact mana source that becomes an end-step blink engine after harness.', $$[{"tag":"ramp","confidence":0.90,"evidence":"taps for white mana"},{"tag":"blink","confidence":0.92,"evidence":"harnessed end-step blink"},{"tag":"engine","confidence":0.86,"evidence":"repeatable nonland permanent blink"},{"tag":"artifact_synergy","confidence":0.80,"evidence":"legendary artifact engine"}]$$::jsonb),
    ('The Scarlet Witch', 'mid', 'power_based_cost_reduction', 'cost_reduction', 'none', false, false, true, false, true, 'none', 'none', 0.88, 'Power-based cost reduction engine for high-mana-value instant and sorcery spells.', $$[{"tag":"spellslinger","confidence":0.92,"evidence":"instant/sorcery MV 4+ cost reducer"},{"tag":"engine","confidence":0.88,"evidence":"power-based cost reduction"},{"tag":"enabler","confidence":0.86,"evidence":"enables big spell turns"},{"tag":"big_spell","confidence":0.84,"evidence":"applies to MV 4+ spells"}]$$::jsonb),
    ('Thor, God of Thunder', 'mid', 'spell_damage_payoff', 'temporary_graveyard_access', 'damage_any_target', false, false, true, true, false, 'none', 'temporary_play_from_graveyard', 0.88, 'Noncreature spell damage payoff with annotated ETB temporary graveyard play access.', $$[{"tag":"spellslinger","confidence":0.90,"evidence":"noncreature spell damage trigger"},{"tag":"payoff","confidence":0.90,"evidence":"spell mana value to damage"},{"tag":"removal","confidence":0.82,"evidence":"damage can hit creatures or players"},{"tag":"recursion","confidence":0.78,"evidence":"ETB temporary graveyard play access"}]$$::jsonb),
    ('Turbulent Steppe', 'land', 'conditional_tapped_dual', 'none', 'none', false, false, false, false, true, 'none', 'none', 0.88, 'Red-white Mountain Plains land with conditional tapped entry.', $$[{"tag":"land","confidence":0.95,"evidence":"Mountain Plains land"},{"tag":"ramp","confidence":0.82,"evidence":"red/white mana source"}]$$::jsonb)
)
INSERT INTO public.card_semantic_tags_v2 (
  card_id,
  card_name,
  schema_version,
  speed,
  mana_efficiency,
  card_advantage_type,
  interaction_scope,
  combo_piece,
  wincon,
  engine,
  payoff,
  enabler,
  protection_type,
  recursion_type,
  role_confidence,
  explanation_reason,
  tags,
  source,
  updated_at
)
SELECT
  c.id,
  semantic_rows.card_name,
  'semantic_layer_v2_2026_05_18',
  semantic_rows.speed,
  semantic_rows.mana_efficiency,
  semantic_rows.card_advantage_type,
  semantic_rows.interaction_scope,
  semantic_rows.combo_piece,
  semantic_rows.wincon,
  semantic_rows.engine,
  semantic_rows.payoff,
  semantic_rows.enabler,
  semantic_rows.protection_type,
  semantic_rows.recursion_type,
  semantic_rows.role_confidence,
  semantic_rows.explanation_reason,
  semantic_rows.tags,
  'priority_lorehold_semantic_v2_2026_07_07',
  CURRENT_TIMESTAMP
FROM semantic_rows
JOIN public.cards c ON c.name = semantic_rows.card_name
ON CONFLICT (card_id, source) DO UPDATE SET
  card_name = EXCLUDED.card_name,
  schema_version = EXCLUDED.schema_version,
  speed = EXCLUDED.speed,
  mana_efficiency = EXCLUDED.mana_efficiency,
  card_advantage_type = EXCLUDED.card_advantage_type,
  interaction_scope = EXCLUDED.interaction_scope,
  combo_piece = EXCLUDED.combo_piece,
  wincon = EXCLUDED.wincon,
  engine = EXCLUDED.engine,
  payoff = EXCLUDED.payoff,
  enabler = EXCLUDED.enabler,
  protection_type = EXCLUDED.protection_type,
  recursion_type = EXCLUDED.recursion_type,
  role_confidence = EXCLUDED.role_confidence,
  explanation_reason = EXCLUDED.explanation_reason,
  tags = EXCLUDED.tags,
  updated_at = CURRENT_TIMESTAMP;

COMMIT;
