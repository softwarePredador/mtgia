BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg723_mana_source_discard_costs_new_serv_20260710_220014 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('bog witch', 'bramble familiar // fetch quest', 'izzet keyrune', 'network terminal', 'skirge familiar', 'starting column')
   OR normalized_name LIKE 'bog witch // %'
   OR normalized_name LIKE 'bramble familiar // fetch quest // %'
   OR normalized_name LIKE 'izzet keyrune // %'
   OR normalized_name LIKE 'network terminal // %'
   OR normalized_name LIKE 'skirge familiar // %'
   OR normalized_name LIKE 'starting column // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bog witch', 'Bog Witch', 'cba4ed150bbd23de0f94252f5d7b5305', 'battle_rule_v1:cc9b88d2a957eadf106872241dc8b486', '{"activation_discard_count":1,"activation_discard_target":"any_card","activation_mana_cost":"{B}","activation_requires_discard_card":true,"activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":3,"permanent_type":"creature","produced_mana_symbols":["B","B","B"],"produces":"B","xmage_effect_classes":[],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BogWitch translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bramble familiar // fetch quest', 'Bramble Familiar // Fetch Quest', 'a59914f9d0ed7af3cda793ca139946a1', 'battle_rule_v1:7574c910d2d459228c8c526ad47869ac', '{"_runtime_partial":true,"_runtime_partial_reason":"Only the XMage mana ability is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"creature","produced_mana_symbols":["G"],"produces":"G","xmage_ability_classes":["GreenManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_effect_classes":["FetchQuestEffect","OneShotEffect","ReturnToHandSourceEffect"],"xmage_mana_ability_classes":["GreenManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["FetchQuestEffect","OneShotEffect","ReturnToHandSourceEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BrambleFamiliar translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('izzet keyrune', 'Izzet Keyrune', '37a98c015cfe212b0b3d3ce9b8dbc9e7', 'battle_rule_v1:397302a8d184a991cf7dc87dde6e2094', '{"_runtime_partial":true,"_runtime_partial_reason":"Only the XMage mana ability is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"artifact","produces":"UR","xmage_ability_classes":["BlueManaAbility","DealsCombatDamageToAPlayerTriggeredAbility","RedManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["DealsCombatDamageToAPlayerTriggeredAbility","SimpleActivatedAbility"],"xmage_effect_classes":["BecomesCreatureSourceEffect","DrawDiscardControllerEffect"],"xmage_mana_ability_classes":["BlueManaAbility","RedManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["DealsCombatDamageToAPlayerTriggeredAbility","SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["BecomesCreatureSourceEffect","DrawDiscardControllerEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IzzetKeyrune translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('network terminal', 'Network Terminal', 'fc6edb1298d7e58a60754909b239ba98', 'battle_rule_v1:e86ddd864393b9f9383252deee30dc58', '{"_runtime_partial":true,"_runtime_partial_reason":"Only the XMage mana ability is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"artifact","produces":"WUBRG","xmage_ability_classes":["AnyColorManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_effect_classes":["DrawDiscardControllerEffect"],"xmage_mana_ability_classes":["AnyColorManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NetworkTerminal translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('skirge familiar', 'Skirge Familiar', '64e60412be4fdf68e746400ccdf3d88b', 'battle_rule_v1:bca1b1499151165d4343361df4396b23', '{"activation_discard_count":1,"activation_discard_target":"any_card","activation_requires_discard_card":true,"activation_requires_tap":false,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"keywords":["flying"],"mana_activation_requires_tap":false,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["B"],"produces":"B","xmage_effect_classes":[],"xmage_mana_ability_classes":["FlyingAbility","SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SkirgeFamiliar translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('starting column', 'Starting Column', 'e581419d19f31ddbc0aebf1e66091441', 'battle_rule_v1:3a94c90daa02788d3e091ac74885910d', '{"_runtime_partial":true,"_runtime_partial_reason":"Only the XMage mana ability is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"artifact","produces":"WUBRG","xmage_ability_classes":["AnyColorManaAbility","MaxSpeedAbility","SimpleActivatedAbility","StartYourEnginesAbility"],"xmage_auxiliary_ability_classes":["MaxSpeedAbility","SimpleActivatedAbility","StartYourEnginesAbility"],"xmage_effect_classes":["DrawDiscardControllerEffect"],"xmage_mana_ability_classes":["AnyColorManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["MaxSpeedAbility","SimpleActivatedAbility","StartYourEnginesAbility"],"xmage_unmodeled_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StartingColumn translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('bog witch', 'Bog Witch', 'cba4ed150bbd23de0f94252f5d7b5305', 'battle_rule_v1:cc9b88d2a957eadf106872241dc8b486', '{"activation_discard_count":1,"activation_discard_target":"any_card","activation_mana_cost":"{B}","activation_requires_discard_card":true,"activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":3,"permanent_type":"creature","produced_mana_symbols":["B","B","B"],"produces":"B","xmage_effect_classes":[],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BogWitch translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bramble familiar // fetch quest', 'Bramble Familiar // Fetch Quest', 'a59914f9d0ed7af3cda793ca139946a1', 'battle_rule_v1:7574c910d2d459228c8c526ad47869ac', '{"_runtime_partial":true,"_runtime_partial_reason":"Only the XMage mana ability is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"creature","produced_mana_symbols":["G"],"produces":"G","xmage_ability_classes":["GreenManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_effect_classes":["FetchQuestEffect","OneShotEffect","ReturnToHandSourceEffect"],"xmage_mana_ability_classes":["GreenManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["FetchQuestEffect","OneShotEffect","ReturnToHandSourceEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BrambleFamiliar translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('izzet keyrune', 'Izzet Keyrune', '37a98c015cfe212b0b3d3ce9b8dbc9e7', 'battle_rule_v1:397302a8d184a991cf7dc87dde6e2094', '{"_runtime_partial":true,"_runtime_partial_reason":"Only the XMage mana ability is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"artifact","produces":"UR","xmage_ability_classes":["BlueManaAbility","DealsCombatDamageToAPlayerTriggeredAbility","RedManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["DealsCombatDamageToAPlayerTriggeredAbility","SimpleActivatedAbility"],"xmage_effect_classes":["BecomesCreatureSourceEffect","DrawDiscardControllerEffect"],"xmage_mana_ability_classes":["BlueManaAbility","RedManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["DealsCombatDamageToAPlayerTriggeredAbility","SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["BecomesCreatureSourceEffect","DrawDiscardControllerEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IzzetKeyrune translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('network terminal', 'Network Terminal', 'fc6edb1298d7e58a60754909b239ba98', 'battle_rule_v1:e86ddd864393b9f9383252deee30dc58', '{"_runtime_partial":true,"_runtime_partial_reason":"Only the XMage mana ability is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"artifact","produces":"WUBRG","xmage_ability_classes":["AnyColorManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_effect_classes":["DrawDiscardControllerEffect"],"xmage_mana_ability_classes":["AnyColorManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NetworkTerminal translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('skirge familiar', 'Skirge Familiar', '64e60412be4fdf68e746400ccdf3d88b', 'battle_rule_v1:bca1b1499151165d4343361df4396b23', '{"activation_discard_count":1,"activation_discard_target":"any_card","activation_requires_discard_card":true,"activation_requires_tap":false,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"keywords":["flying"],"mana_activation_requires_tap":false,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["B"],"produces":"B","xmage_effect_classes":[],"xmage_mana_ability_classes":["FlyingAbility","SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SkirgeFamiliar translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('starting column', 'Starting Column', 'e581419d19f31ddbc0aebf1e66091441', 'battle_rule_v1:3a94c90daa02788d3e091ac74885910d', '{"_runtime_partial":true,"_runtime_partial_reason":"Only the XMage mana ability is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"artifact","produces":"WUBRG","xmage_ability_classes":["AnyColorManaAbility","MaxSpeedAbility","SimpleActivatedAbility","StartYourEnginesAbility"],"xmage_auxiliary_ability_classes":["MaxSpeedAbility","SimpleActivatedAbility","StartYourEnginesAbility"],"xmage_effect_classes":["DrawDiscardControllerEffect"],"xmage_mana_ability_classes":["AnyColorManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["MaxSpeedAbility","SimpleActivatedAbility","StartYourEnginesAbility"],"xmage_unmodeled_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StartingColumn translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('bog witch', 'Bog Witch', 'cba4ed150bbd23de0f94252f5d7b5305', 'battle_rule_v1:cc9b88d2a957eadf106872241dc8b486', '{"activation_discard_count":1,"activation_discard_target":"any_card","activation_mana_cost":"{B}","activation_requires_discard_card":true,"activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":3,"permanent_type":"creature","produced_mana_symbols":["B","B","B"],"produces":"B","xmage_effect_classes":[],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BogWitch translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bramble familiar // fetch quest', 'Bramble Familiar // Fetch Quest', 'a59914f9d0ed7af3cda793ca139946a1', 'battle_rule_v1:7574c910d2d459228c8c526ad47869ac', '{"_runtime_partial":true,"_runtime_partial_reason":"Only the XMage mana ability is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"creature","produced_mana_symbols":["G"],"produces":"G","xmage_ability_classes":["GreenManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_effect_classes":["FetchQuestEffect","OneShotEffect","ReturnToHandSourceEffect"],"xmage_mana_ability_classes":["GreenManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["FetchQuestEffect","OneShotEffect","ReturnToHandSourceEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BrambleFamiliar translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('izzet keyrune', 'Izzet Keyrune', '37a98c015cfe212b0b3d3ce9b8dbc9e7', 'battle_rule_v1:397302a8d184a991cf7dc87dde6e2094', '{"_runtime_partial":true,"_runtime_partial_reason":"Only the XMage mana ability is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"artifact","produces":"UR","xmage_ability_classes":["BlueManaAbility","DealsCombatDamageToAPlayerTriggeredAbility","RedManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["DealsCombatDamageToAPlayerTriggeredAbility","SimpleActivatedAbility"],"xmage_effect_classes":["BecomesCreatureSourceEffect","DrawDiscardControllerEffect"],"xmage_mana_ability_classes":["BlueManaAbility","RedManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["DealsCombatDamageToAPlayerTriggeredAbility","SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["BecomesCreatureSourceEffect","DrawDiscardControllerEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IzzetKeyrune translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('network terminal', 'Network Terminal', 'fc6edb1298d7e58a60754909b239ba98', 'battle_rule_v1:e86ddd864393b9f9383252deee30dc58', '{"_runtime_partial":true,"_runtime_partial_reason":"Only the XMage mana ability is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"artifact","produces":"WUBRG","xmage_ability_classes":["AnyColorManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_effect_classes":["DrawDiscardControllerEffect"],"xmage_mana_ability_classes":["AnyColorManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NetworkTerminal translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('skirge familiar', 'Skirge Familiar', '64e60412be4fdf68e746400ccdf3d88b', 'battle_rule_v1:bca1b1499151165d4343361df4396b23', '{"activation_discard_count":1,"activation_discard_target":"any_card","activation_requires_discard_card":true,"activation_requires_tap":false,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"keywords":["flying"],"mana_activation_requires_tap":false,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["B"],"produces":"B","xmage_effect_classes":[],"xmage_mana_ability_classes":["FlyingAbility","SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SkirgeFamiliar translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('starting column', 'Starting Column', 'e581419d19f31ddbc0aebf1e66091441', 'battle_rule_v1:3a94c90daa02788d3e091ac74885910d', '{"_runtime_partial":true,"_runtime_partial_reason":"Only the XMage mana ability is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"artifact","produces":"WUBRG","xmage_ability_classes":["AnyColorManaAbility","MaxSpeedAbility","SimpleActivatedAbility","StartYourEnginesAbility"],"xmage_auxiliary_ability_classes":["MaxSpeedAbility","SimpleActivatedAbility","StartYourEnginesAbility"],"xmage_effect_classes":["DrawDiscardControllerEffect"],"xmage_mana_ability_classes":["AnyColorManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["MaxSpeedAbility","SimpleActivatedAbility","StartYourEnginesAbility"],"xmage_unmodeled_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StartingColumn translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
