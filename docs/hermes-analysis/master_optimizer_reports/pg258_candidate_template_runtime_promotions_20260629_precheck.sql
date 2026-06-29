WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('reckless handling', 'Reckless Handling', '206f0ccc115c6dc61edaa5f87ca997a6', 'battle_rule_v1:e5047fed8f5800462054cfe3649974c1', '{"ability_kind":"one_shot","battle_model_scope":"artifact_tutor_to_hand_random_discard_damage_if_artifact_discarded_v1","damage_each_opponent_if_artifact_discarded":2,"discard_after_tutor_random":1,"effect":"tutor","instant":false,"random_discard_after_tutor":1,"target":"artifact_to_hand","tutor_destination":"hand"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class RecklessHandling mapped to family tutor; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('demonic counsel', 'Demonic Counsel', '857fecbbacb9ad50a9602bc5a1bb51d0', 'battle_rule_v1:d947b211638d8fab96a9615836c0f1bc', '{"ability_kind":"one_shot","battle_model_scope":"conditional_delirium_restricted_or_any_tutor_to_hand_v1","delirium_graveyard_card_type_count":4,"delirium_target":"any_to_hand","effect":"tutor","instant":false,"target":"demon_to_hand","tutor_destination":"hand"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class DemonicCounsel mapped to family tutor; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('scour for scrap', 'Scour for Scrap', '6cf739118386b7c0328c9a363ef2c964', 'battle_rule_v1:7ea6e0e413068bce5c5301aaeb9c5b16', '{"ability_kind":"one_shot","battle_model_scope":"modal_artifact_tutor_or_artifact_graveyard_to_hand_v1","effect":"modal_spell","instant":true,"mode_max":2,"mode_min":1,"mode_one_target":"artifact_to_hand","mode_two_target":"artifact_from_graveyard_to_hand"}'::jsonb, '{"category":"interaction","effect":"modal_spell","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ScourForScrap mapped to family modal_spell; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('summoner''s pact', 'Summoner''s Pact', '3ba19b6b25147fc51068a4b733881370', 'battle_rule_v1:9bc8bcc764d889e0166de3a46429ddcd', '{"ability_kind":"one_shot","battle_model_scope":"pact_green_creature_tutor_to_hand_delayed_payment_v1","delayed_upkeep_mana_payment":"{2}{G}{G}","delayed_upkeep_payment_status":"annotation_only","effect":"tutor","instant":true,"lose_game_if_unpaid":true,"target":"green_creature_to_hand","tutor_destination":"hand"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SummonersPact mapped to family tutor; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('cloud of faeries', 'Cloud of Faeries', '7e06ce7c0f9bf5b2516e5c433440c291', 'battle_rule_v1:22800c898eb8acf79b50adda432c928d', '{"ability_kind":"triggered","battle_model_scope":"etb_untap_up_to_two_lands_cycling_two_v1","cycling_cost":"{2}","cycling_status":"annotation_only","effect":"untap_land_engine","etb_untap_lands_count":2,"etb_untap_lands_optional":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CloudOfFaeries mapped to family untap_land_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('grinding station', 'Grinding Station', '288857f5e91e9574eff7a561f5d6708e', 'battle_rule_v1:717756665b21129116b06005239d6754', '{"ability_kind":"triggered","activation_requires_sacrifice_permanent":true,"activation_requires_tap":true,"activation_sacrifice_target_type":"artifact","artifact_enters_untap_source":true,"artifact_enters_untap_source_status":"annotation_only","battle_model_scope":"artifact_tap_sacrifice_permanent_target_player_mill_v1","effect":"mill_engine","mill_count":3,"target":"player"}'::jsonb, '{"category":"combo_value","effect":"mill","subtype":"library_mill","timing":"resolution_or_activation"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class GrindingStation mapped to family mill_spell; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
