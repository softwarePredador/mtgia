WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('ancestral reminiscence', 'Ancestral Reminiscence', 'dc9032001a319c70dbf9acdf0b806db0', 'battle_rule_v1:73912a4129ba131351a7d72087514070', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":1,"discard_random":false,"draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AncestralReminiscence translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('careful study', 'Careful Study', 'bbc40777c44eb8cca3e6a811ad954178', 'battle_rule_v1:0d2aaf58fe699e4cc5b5c7ebc69a05c1', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":2,"discard_count":2,"discard_random":false,"draw_count":2,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CarefulStudy translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('catalog', 'Catalog', '6948b1421f25b941d769532459028061', 'battle_rule_v1:63b054fc75d44178f8bd4b286a0cbdba', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":2,"discard_count":1,"discard_random":false,"draw_count":2,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Catalog translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('enhanced awareness', 'Enhanced Awareness', 'dc9032001a319c70dbf9acdf0b806db0', 'battle_rule_v1:23c289099aa3f2dabbfeb727d7d654f2', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":1,"discard_random":false,"draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EnhancedAwareness translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('prying eyes', 'Prying Eyes', '6b2ee39107b1b3039a3324c430e6f271', 'battle_rule_v1:7807f21b39fea1cfb17ed8edf4ed891a', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":4,"discard_count":2,"discard_random":false,"draw_count":4,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PryingEyes translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rain of revelation', 'Rain of Revelation', 'dc9032001a319c70dbf9acdf0b806db0', 'battle_rule_v1:23c289099aa3f2dabbfeb727d7d654f2', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":1,"discard_random":false,"draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RainOfRevelation translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('romantic rendezvous', 'Romantic Rendezvous', 'aff53f567af23b5e9fcd03939b26340f', 'battle_rule_v1:2baba243f445a0a2e3e5983394657313', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":2,"discard_count":1,"discard_random":false,"draw_count":2,"draw_discard_order":"discard_then_draw","draw_discard_spell":true,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RomanticRendezvous translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sift', 'Sift', 'dc9032001a319c70dbf9acdf0b806db0', 'battle_rule_v1:73912a4129ba131351a7d72087514070', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":1,"discard_random":false,"draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Sift translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thoughtflare', 'Thoughtflare', '6b2ee39107b1b3039a3324c430e6f271', 'battle_rule_v1:ebc0a01d26b567480a2f083009f64ec3', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":4,"discard_count":2,"discard_random":false,"draw_count":4,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Thoughtflare translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
