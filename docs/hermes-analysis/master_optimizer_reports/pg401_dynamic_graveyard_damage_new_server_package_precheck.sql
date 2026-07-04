WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('galvanic bombardment', 'Galvanic Bombardment', 'a63030de85a8efbe5d5cfb5812aacad0', 'battle_rule_v1:01661b56bea5a3130cd2584b41e60ad2', '{"amount":0,"battle_model_scope":"xmage_dynamic_graveyard_count_damage_spell_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":2,"damage_per_graveyard_count":1,"effect":"direct_damage","graveyard_count_card_names":["Galvanic Bombardment"],"graveyard_count_scope":"controller_graveyard","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GalvanicBombardment translated into ManaLoom runtime scope xmage_dynamic_graveyard_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow dynamic graveyard-count damage spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ire of kaminari', 'Ire of Kaminari', '7a164fc97eec2cf77b86d03b602ac26c', 'battle_rule_v1:14bbef0a7472d0051f179a1f39198391', '{"amount":0,"battle_model_scope":"xmage_dynamic_graveyard_count_damage_spell_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":0,"damage_per_graveyard_count":1,"effect":"direct_damage","graveyard_count_scope":"controller_graveyard","graveyard_count_subtypes":["arcane"],"instant":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IreOfKaminari translated into ManaLoom runtime scope xmage_dynamic_graveyard_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow dynamic graveyard-count damage spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kindle', 'Kindle', 'daa81fd00aeae9e0b48d50f284a4f46f', 'battle_rule_v1:a9db350295df3f3a11a1a18a541cd671', '{"amount":0,"battle_model_scope":"xmage_dynamic_graveyard_count_damage_spell_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":2,"damage_per_graveyard_count":1,"effect":"direct_damage","graveyard_count_card_names":["Kindle"],"graveyard_count_scope":"all_graveyards","instant":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Kindle translated into ManaLoom runtime scope xmage_dynamic_graveyard_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow dynamic graveyard-count damage spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scrapyard salvo', 'Scrapyard Salvo', '65339ed7621226246a5b84a9f684b333', 'battle_rule_v1:75b7f7990c05194d68d794d77aade7d6', '{"amount":0,"battle_model_scope":"xmage_dynamic_graveyard_count_damage_spell_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":0,"damage_per_graveyard_count":1,"effect":"direct_damage","graveyard_count_card_types":["artifact"],"graveyard_count_scope":"controller_graveyard","instant":false,"sorcery":true,"target":"player_or_planeswalker","target_constraints":{"scope":"player_or_planeswalker"},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"player_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScrapyardSalvo translated into ManaLoom runtime scope xmage_dynamic_graveyard_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow dynamic graveyard-count damage spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
