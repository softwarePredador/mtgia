WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('avoid fate', 'Avoid Fate', '247fe0d287580539b1a5d1d7c4c2c9e3', 'battle_rule_v1:1ab07f98d615423be90bceaf1f36809f', '{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"sorcery":false,"target":"instant_or_aura_spell_targeting_permanent_you_control","target_constraints":{"any_of":[{"spell_types":["instant"]},{"spell_subtypes":["aura"]}],"spell_targets":"permanent_you_control","stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"instant_or_aura_spell_targeting_permanent_you_control","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AvoidFate translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('double negative', 'Double Negative', '8c0e2236e17f1116023c514803871142', 'battle_rule_v1:a28bd14d1761b96b8a5098e10a592d23', '{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"max_targets":2,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"target_count":2,"target_count_max":2,"target_count_min":0,"up_to_count":true,"xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DoubleNegative translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('outwit', 'Outwit', '24613df0ad9bf5d7b822df6729feae90', 'battle_rule_v1:6fb9c8def6ed30ea4fe726171e69e50d', '{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"sorcery":false,"target":"spell_targeting_player","target_constraints":{"spell_targets":"player","stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell_targeting_player","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Outwit translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('second guess', 'Second Guess', '44125098597f0f4640d14aba657de868', 'battle_rule_v1:dc290b2d1a7523365619629d95f138af', '{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"sorcery":false,"target":"spell_second_spell_this_turn","target_constraints":{"spell_order_this_turn":2,"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell_second_spell_this_turn","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SecondGuess translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
)
SELECT
  p.card_name,
  p.normalized_name,
  p.logical_rule_key,
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS promoted_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS promoted_verified_auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS promoted_oracle_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg663_counter_special_stack_constraints_20260708_151831) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
