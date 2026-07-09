BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg678_counter_replacement_exile_new_serv_20260708_235913 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('assert authority', 'deny existence', 'deny the divine', 'dissipate', 'faerie trickery', 'horribly awry', 'liquify', 'void shatter')
   OR normalized_name LIKE 'assert authority // %'
   OR normalized_name LIKE 'deny existence // %'
   OR normalized_name LIKE 'deny the divine // %'
   OR normalized_name LIKE 'dissipate // %'
   OR normalized_name LIKE 'faerie trickery // %'
   OR normalized_name LIKE 'horribly awry // %'
   OR normalized_name LIKE 'liquify // %'
   OR normalized_name LIKE 'void shatter // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('assert authority', 'Assert Authority', 'e7e55ff661b00c18b06a0440ae09f5c3', 'battle_rule_v1:b93da3b7d54ae3de7cb4445ca5d21f27', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AssertAuthority translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('deny existence', 'Deny Existence', '9ef9d5e5c3a197765e7ed3fc010d4694', 'battle_rule_v1:9a8fc3452aadc7a476e2a80a40933258', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"creature_spell","target_constraints":{"card_types":["creature"],"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"creature_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DenyExistence translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('deny the divine', 'Deny the Divine', '0b49f6a07dfab50146e385e07f91d0cd', 'battle_rule_v1:a93f6af5442ff3883dd9f67b59aabc33', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"creature_or_enchantment_spell","target_constraints":{"card_types":["creature","enchantment"],"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"creature_or_enchantment_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DenyTheDivine translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dissipate', 'Dissipate', '307fb6896c67fa1a3661968432a66241', 'battle_rule_v1:b93da3b7d54ae3de7cb4445ca5d21f27', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Dissipate translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('faerie trickery', 'Faerie Trickery', '191228b05399a640b3409b2bce5a32e5', 'battle_rule_v1:02debaf82ed6175dfb4cd42134317ce8', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"nonfaerie_spell","target_constraints":{"exclude_spell_subtypes":["faerie"],"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"nonfaerie_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FaerieTrickery translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('horribly awry', 'Horribly Awry', '769649f9202fe62cde39074275097cb4', 'battle_rule_v1:7f961c618cf035b3060297e5be43e3a4', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"creature_spell_mana_value_4_or_less","target_constraints":{"card_types":["creature"],"counter_target_mana_value_max":4,"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"creature_spell_mana_value_4_or_less","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HorriblyAwry translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('liquify', 'Liquify', '4c9c8c008370e7284d2f03bc4e614c96', 'battle_rule_v1:2069ef74d49c4461854d1fca3258cbcc', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"spell_mana_value_3_or_less","target_constraints":{"counter_target_mana_value_max":3,"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell_mana_value_3_or_less","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Liquify translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('void shatter', 'Void Shatter', '591fc6fc6eae405e727724e6255ae015', 'battle_rule_v1:b93da3b7d54ae3de7cb4445ca5d21f27', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VoidShatter translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
  counts AS (
    SELECT
      p.card_name,
      p.normalized_name,
      p.oracle_hash,
      count(c.id) AS target_card_rows,
      min(c.id::text)::uuid AS canonical_card_id
    FROM proposed p
    LEFT JOIN public.cards c
      ON (
           lower(c.name) = p.normalized_name
           OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
         )
     AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
    GROUP BY p.card_name, p.normalized_name, p.oracle_hash
  )
  SELECT jsonb_agg(counts ORDER BY card_name)
    INTO v_missing
  FROM counts
  WHERE target_card_rows < 1;

  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'XMage batch package abort: expected at least one Oracle-hash-matched card row for every proposed card: %', v_missing;
  END IF;
END $$;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('assert authority', 'Assert Authority', 'e7e55ff661b00c18b06a0440ae09f5c3', 'battle_rule_v1:b93da3b7d54ae3de7cb4445ca5d21f27', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AssertAuthority translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('deny existence', 'Deny Existence', '9ef9d5e5c3a197765e7ed3fc010d4694', 'battle_rule_v1:9a8fc3452aadc7a476e2a80a40933258', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"creature_spell","target_constraints":{"card_types":["creature"],"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"creature_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DenyExistence translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('deny the divine', 'Deny the Divine', '0b49f6a07dfab50146e385e07f91d0cd', 'battle_rule_v1:a93f6af5442ff3883dd9f67b59aabc33', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"creature_or_enchantment_spell","target_constraints":{"card_types":["creature","enchantment"],"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"creature_or_enchantment_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DenyTheDivine translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dissipate', 'Dissipate', '307fb6896c67fa1a3661968432a66241', 'battle_rule_v1:b93da3b7d54ae3de7cb4445ca5d21f27', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Dissipate translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('faerie trickery', 'Faerie Trickery', '191228b05399a640b3409b2bce5a32e5', 'battle_rule_v1:02debaf82ed6175dfb4cd42134317ce8', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"nonfaerie_spell","target_constraints":{"exclude_spell_subtypes":["faerie"],"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"nonfaerie_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FaerieTrickery translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('horribly awry', 'Horribly Awry', '769649f9202fe62cde39074275097cb4', 'battle_rule_v1:7f961c618cf035b3060297e5be43e3a4', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"creature_spell_mana_value_4_or_less","target_constraints":{"card_types":["creature"],"counter_target_mana_value_max":4,"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"creature_spell_mana_value_4_or_less","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HorriblyAwry translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('liquify', 'Liquify', '4c9c8c008370e7284d2f03bc4e614c96', 'battle_rule_v1:2069ef74d49c4461854d1fca3258cbcc', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"spell_mana_value_3_or_less","target_constraints":{"counter_target_mana_value_max":3,"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell_mana_value_3_or_less","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Liquify translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('void shatter', 'Void Shatter', '591fc6fc6eae405e727724e6255ae015', 'battle_rule_v1:b93da3b7d54ae3de7cb4445ca5d21f27', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VoidShatter translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
deprecated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'XMage batch package: deprecated stale shadow before curated batch rule upsert.')
  FROM proposed p
  WHERE (
        r.normalized_name = p.normalized_name
        OR r.normalized_name LIKE p.normalized_name || ' // %'
      )
    AND p.shadow_handling <> 'preserve_existing_rows'
    AND r.logical_rule_key <> p.logical_rule_key
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows FROM deprecated;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('assert authority', 'Assert Authority', 'e7e55ff661b00c18b06a0440ae09f5c3', 'battle_rule_v1:b93da3b7d54ae3de7cb4445ca5d21f27', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AssertAuthority translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('deny existence', 'Deny Existence', '9ef9d5e5c3a197765e7ed3fc010d4694', 'battle_rule_v1:9a8fc3452aadc7a476e2a80a40933258', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"creature_spell","target_constraints":{"card_types":["creature"],"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"creature_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DenyExistence translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('deny the divine', 'Deny the Divine', '0b49f6a07dfab50146e385e07f91d0cd', 'battle_rule_v1:a93f6af5442ff3883dd9f67b59aabc33', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"creature_or_enchantment_spell","target_constraints":{"card_types":["creature","enchantment"],"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"creature_or_enchantment_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DenyTheDivine translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dissipate', 'Dissipate', '307fb6896c67fa1a3661968432a66241', 'battle_rule_v1:b93da3b7d54ae3de7cb4445ca5d21f27', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Dissipate translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('faerie trickery', 'Faerie Trickery', '191228b05399a640b3409b2bce5a32e5', 'battle_rule_v1:02debaf82ed6175dfb4cd42134317ce8', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"nonfaerie_spell","target_constraints":{"exclude_spell_subtypes":["faerie"],"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"nonfaerie_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FaerieTrickery translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('horribly awry', 'Horribly Awry', '769649f9202fe62cde39074275097cb4', 'battle_rule_v1:7f961c618cf035b3060297e5be43e3a4', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"creature_spell_mana_value_4_or_less","target_constraints":{"card_types":["creature"],"counter_target_mana_value_max":4,"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"creature_spell_mana_value_4_or_less","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HorriblyAwry translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('liquify', 'Liquify', '4c9c8c008370e7284d2f03bc4e614c96', 'battle_rule_v1:2069ef74d49c4461854d1fca3258cbcc', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"spell_mana_value_3_or_less","target_constraints":{"counter_target_mana_value_max":3,"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell_mana_value_3_or_less","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Liquify translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('void shatter', 'Void Shatter', '591fc6fc6eae405e727724e6255ae015', 'battle_rule_v1:b93da3b7d54ae3de7cb4445ca5d21f27', '{"battle_model_scope":"xmage_counter_target_spell_v1","countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_target_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetWithReplacementEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VoidShatter translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
matched_cards AS (
  SELECT
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    c.id AS card_id,
    c.name AS db_card_name
  FROM proposed p
  JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
canonical_target_cards AS (
  SELECT
    p.*,
    min(m.card_id::text)::uuid AS card_id,
    min(m.db_card_name) AS db_card_name
  FROM proposed p
  JOIN matched_cards m
    USING (normalized_name, card_name, oracle_hash)
  GROUP BY
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    p.logical_rule_key,
    p.effect_json,
    p.deck_role_json,
    p.source,
    p.confidence,
    p.review_status,
    p.execution_status,
    p.notes,
    p.shadow_handling
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
    2,
    oracle_hash,
    notes,
    'codex-xmage-batch',
    now(),
    now(),
    now(),
    now(),
    logical_rule_key,
    execution_status
  FROM canonical_target_cards
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
SELECT count(*) AS upserted_rows FROM upserted;

COMMIT;
