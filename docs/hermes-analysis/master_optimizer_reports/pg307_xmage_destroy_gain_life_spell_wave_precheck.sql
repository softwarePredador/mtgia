WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('appetite for the unnatural', 'Appetite for the Unnatural', 'ff2701341e046cdb32db1fd2d24193f3', 'battle_rule_v1:f25f7f032c8935a2725f03e806412108', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":2,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AppetiteForTheUnnatural translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('cursebreak', 'Cursebreak', 'e8b18bd9c5e41964bd056a95a9599ba6', 'battle_rule_v1:eac90831bff0a6d7d8cc7f79c84dc684', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":2,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"enchantment","target_constraints":{"card_types":["enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Cursebreak translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('drain the well', 'Drain the Well', 'a83cde4e874b76b73ec6952b980c5a5d', 'battle_rule_v1:8c113d532b53977905ddd6205d20b76b', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":2,"destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"land","target_constraints":{"card_types":["land"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DrainTheWell translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('grapple with death', 'Grapple with Death', '2b0b7a6ae97fc371def1be151b9f5a9f', 'battle_rule_v1:5ae5bf64faa291c0d09c85d28201a2c2', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":1,"destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"artifact_or_creature","target_constraints":{"card_types":["artifact","creature"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GrappleWithDeath translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('invoke the divine', 'Invoke the Divine', '1a2e40995c4f7d6463ae7b5ce96cbfe5', 'battle_rule_v1:5d06c51d4005a36bd990d87851d9383c', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":4,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class InvokeTheDivine translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lich''s caress', 'Lich''s Caress', '1f0834667ff74af400f80cd6af6f6f50', 'battle_rule_v1:2151b4f927db86b6035cda9e8968a760', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_creature","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LichsCaress translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('maw of the mire', 'Maw of the Mire', 'af7b53f165c85d1baa6e0670e600763d', 'battle_rule_v1:30ecba357ba66148eab77d3cd4e5e9a6', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":4,"destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"land","target_constraints":{"card_types":["land"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MawOfTheMire translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('natural end', 'Natural End', 'e2ec7d476fb36a631e6ead5c573d45a2', 'battle_rule_v1:1497fb65812c46c78c5b669ff4989524', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NaturalEnd translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ray of dissolution', 'Ray of Dissolution', '3595f82ef93062fd242ae9dc886164c8', 'battle_rule_v1:762898b040728ef22fc560e8c079ec0d', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"enchantment","target_constraints":{"card_types":["enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RayOfDissolution translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sanctify', 'Sanctify', 'e2ec7d476fb36a631e6ead5c573d45a2', 'battle_rule_v1:2bf2d3a044f5bd1745cbac8a72622f30', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":3,"destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Sanctify translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sephiroth''s intervention', 'Sephiroth''s Intervention', '2dffcc424019a833cb2851580aa3694b', 'battle_rule_v1:eeb274765267ef2873eb0b196c027df8', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":2,"destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SephirothsIntervention translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('solemn offering', 'Solemn Offering', '1a2e40995c4f7d6463ae7b5ce96cbfe5', 'battle_rule_v1:a3ed89e31c22fb41043599139d0632cd', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":4,"destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SolemnOffering translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('springsage ritual', 'Springsage Ritual', '1a2e40995c4f7d6463ae7b5ce96cbfe5', 'battle_rule_v1:5d06c51d4005a36bd990d87851d9383c', '{"battle_model_scope":"xmage_destroy_target_and_controller_gain_life_spell_v1","controller_gains_life":4,"destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpringsageRitual translated into ManaLoom runtime scope xmage_destroy_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
