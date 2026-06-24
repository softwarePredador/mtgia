BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg181_residual_batch_ready_seven_20260624_143655 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('brass''s bounty', 'bedevil', 'cathartic reunion', 'crackle with power', 'invoke justice', 'steelshaper''s gift', 'locket of yesterdays')
   OR normalized_name LIKE 'brass''s bounty // %'
   OR normalized_name LIKE 'bedevil // %'
   OR normalized_name LIKE 'cathartic reunion // %'
   OR normalized_name LIKE 'crackle with power // %'
   OR normalized_name LIKE 'invoke justice // %'
   OR normalized_name LIKE 'steelshaper''s gift // %'
   OR normalized_name LIKE 'locket of yesterdays // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('brass''s bounty', 'Brass''s Bounty', 'beb029ff5233032656034de922a112f0', 'battle_rule_v1:b5dabaaaba6b2cd47cd998989c11a1fa', '{"ability_kind":"one_shot","battle_model_scope":"single_treasure_creation_v1","effect":"treasure_maker","treasure_count":1}'::jsonb, '{"category":"ramp","effect":"treasure_maker","subtype":"treasure_conversion","timing":"activated_or_resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BrasssBounty mapped to family treasure_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('bedevil', 'Bedevil', '77dcf646b59f535df941f6716b802b26', 'battle_rule_v1:24839f966a77da6656c462aa885ccaa4', '{"ability_kind":"one_shot","battle_model_scope":"targeted_destroy_variant_v1","effect":"removal_destroy","target_constraints":{"card_types":["permanent"]}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Bedevil mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('cathartic reunion', 'Cathartic Reunion', '27da1fd996cc7f3a85a98aea3b6c030b', 'battle_rule_v1:3af05007acd54aabd195ff390b8f082f', '{"ability_kind":"one_shot","battle_model_scope":"source_controller_draw_variant_v1","effect":"draw_cards"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CatharticReunion mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('crackle with power', 'Crackle with Power', 'cf0db23411445756ee792506b48ae35d', 'battle_rule_v1:a939ce51bf83fe086fc16a40d344752d', '{"ability_kind":"one_shot","battle_model_scope":"targeted_damage_variant_v1","effect":"direct_damage","target_constraints":{"scope":"any_target"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CrackleWithPower mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('invoke justice', 'Invoke Justice', 'a98214114b5acd853842ac7590854785', 'battle_rule_v1:13150949864474c123d5a02a7a007722', '{"ability_kind":"one_shot","battle_model_scope":"graveyard_to_battlefield_variant_v1","effect":"recursion","target_constraints":{"card_types":["permanent"],"zone":"graveyard"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class InvokeJustice mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('steelshaper''s gift', 'Steelshaper''s Gift', '8f894c3b42872f60142063c115ef3c9a', 'battle_rule_v1:c7ff42f8ce9a2bca4470fba16cab034a', '{"ability_kind":"one_shot","battle_model_scope":"any_tutor_to_hand_v1","effect":"tutor","instant":false,"target":"any_to_hand"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SteelshapersGift mapped to family tutor; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('locket of yesterdays', 'Locket of Yesterdays', '556810471067d11936662c3406a207c8', 'battle_rule_v1:09662427b256781a39f50dd00ba9735b', '{"ability_kind":"static","applies_to_controller":"source_controller","battle_model_scope":"static_cost_reduction_for_matching_spells_v1","cost_reduction_applies_to":"spells_you_cast","cost_reduction_generic":1,"effect":"static_cost_reduction"}'::jsonb, '{"category":"support","effect":"static_cost_reduction","subtype":"cost_reducer","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class LocketOfYesterdays mapped to family static_cost_reducer; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('brass''s bounty', 'Brass''s Bounty', 'beb029ff5233032656034de922a112f0', 'battle_rule_v1:b5dabaaaba6b2cd47cd998989c11a1fa', '{"ability_kind":"one_shot","battle_model_scope":"single_treasure_creation_v1","effect":"treasure_maker","treasure_count":1}'::jsonb, '{"category":"ramp","effect":"treasure_maker","subtype":"treasure_conversion","timing":"activated_or_resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BrasssBounty mapped to family treasure_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('bedevil', 'Bedevil', '77dcf646b59f535df941f6716b802b26', 'battle_rule_v1:24839f966a77da6656c462aa885ccaa4', '{"ability_kind":"one_shot","battle_model_scope":"targeted_destroy_variant_v1","effect":"removal_destroy","target_constraints":{"card_types":["permanent"]}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Bedevil mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('cathartic reunion', 'Cathartic Reunion', '27da1fd996cc7f3a85a98aea3b6c030b', 'battle_rule_v1:3af05007acd54aabd195ff390b8f082f', '{"ability_kind":"one_shot","battle_model_scope":"source_controller_draw_variant_v1","effect":"draw_cards"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CatharticReunion mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('crackle with power', 'Crackle with Power', 'cf0db23411445756ee792506b48ae35d', 'battle_rule_v1:a939ce51bf83fe086fc16a40d344752d', '{"ability_kind":"one_shot","battle_model_scope":"targeted_damage_variant_v1","effect":"direct_damage","target_constraints":{"scope":"any_target"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CrackleWithPower mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('invoke justice', 'Invoke Justice', 'a98214114b5acd853842ac7590854785', 'battle_rule_v1:13150949864474c123d5a02a7a007722', '{"ability_kind":"one_shot","battle_model_scope":"graveyard_to_battlefield_variant_v1","effect":"recursion","target_constraints":{"card_types":["permanent"],"zone":"graveyard"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class InvokeJustice mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('steelshaper''s gift', 'Steelshaper''s Gift', '8f894c3b42872f60142063c115ef3c9a', 'battle_rule_v1:c7ff42f8ce9a2bca4470fba16cab034a', '{"ability_kind":"one_shot","battle_model_scope":"any_tutor_to_hand_v1","effect":"tutor","instant":false,"target":"any_to_hand"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SteelshapersGift mapped to family tutor; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('locket of yesterdays', 'Locket of Yesterdays', '556810471067d11936662c3406a207c8', 'battle_rule_v1:09662427b256781a39f50dd00ba9735b', '{"ability_kind":"static","applies_to_controller":"source_controller","battle_model_scope":"static_cost_reduction_for_matching_spells_v1","cost_reduction_applies_to":"spells_you_cast","cost_reduction_generic":1,"effect":"static_cost_reduction"}'::jsonb, '{"category":"support","effect":"static_cost_reduction","subtype":"cost_reducer","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class LocketOfYesterdays mapped to family static_cost_reducer; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    AND r.logical_rule_key <> p.logical_rule_key
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows FROM deprecated;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('brass''s bounty', 'Brass''s Bounty', 'beb029ff5233032656034de922a112f0', 'battle_rule_v1:b5dabaaaba6b2cd47cd998989c11a1fa', '{"ability_kind":"one_shot","battle_model_scope":"single_treasure_creation_v1","effect":"treasure_maker","treasure_count":1}'::jsonb, '{"category":"ramp","effect":"treasure_maker","subtype":"treasure_conversion","timing":"activated_or_resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BrasssBounty mapped to family treasure_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('bedevil', 'Bedevil', '77dcf646b59f535df941f6716b802b26', 'battle_rule_v1:24839f966a77da6656c462aa885ccaa4', '{"ability_kind":"one_shot","battle_model_scope":"targeted_destroy_variant_v1","effect":"removal_destroy","target_constraints":{"card_types":["permanent"]}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Bedevil mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('cathartic reunion', 'Cathartic Reunion', '27da1fd996cc7f3a85a98aea3b6c030b', 'battle_rule_v1:3af05007acd54aabd195ff390b8f082f', '{"ability_kind":"one_shot","battle_model_scope":"source_controller_draw_variant_v1","effect":"draw_cards"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CatharticReunion mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('crackle with power', 'Crackle with Power', 'cf0db23411445756ee792506b48ae35d', 'battle_rule_v1:a939ce51bf83fe086fc16a40d344752d', '{"ability_kind":"one_shot","battle_model_scope":"targeted_damage_variant_v1","effect":"direct_damage","target_constraints":{"scope":"any_target"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CrackleWithPower mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('invoke justice', 'Invoke Justice', 'a98214114b5acd853842ac7590854785', 'battle_rule_v1:13150949864474c123d5a02a7a007722', '{"ability_kind":"one_shot","battle_model_scope":"graveyard_to_battlefield_variant_v1","effect":"recursion","target_constraints":{"card_types":["permanent"],"zone":"graveyard"}}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class InvokeJustice mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('steelshaper''s gift', 'Steelshaper''s Gift', '8f894c3b42872f60142063c115ef3c9a', 'battle_rule_v1:c7ff42f8ce9a2bca4470fba16cab034a', '{"ability_kind":"one_shot","battle_model_scope":"any_tutor_to_hand_v1","effect":"tutor","instant":false,"target":"any_to_hand"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SteelshapersGift mapped to family tutor; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('locket of yesterdays', 'Locket of Yesterdays', '556810471067d11936662c3406a207c8', 'battle_rule_v1:09662427b256781a39f50dd00ba9735b', '{"ability_kind":"static","applies_to_controller":"source_controller","battle_model_scope":"static_cost_reduction_for_matching_spells_v1","cost_reduction_applies_to":"spells_you_cast","cost_reduction_generic":1,"effect":"static_cost_reduction"}'::jsonb, '{"category":"support","effect":"static_cost_reduction","subtype":"cost_reducer","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class LocketOfYesterdays mapped to family static_cost_reducer; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    p.notes
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
