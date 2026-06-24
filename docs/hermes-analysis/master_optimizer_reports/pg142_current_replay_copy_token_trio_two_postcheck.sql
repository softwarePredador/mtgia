WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('jaxis, the troublemaker', 'Jaxis, the Troublemaker', '92a1b679c9eca885a43a49b79f3d6fb7', 'battle_rule_v1:082e6fbdbbb20e5efed4de5cf8ab3bf1', '{"ability_kind":"triggered","battle_model_scope":"copy_target_another_creature_you_control_haste_draw_on_death_sacrifice_end_step_v1","copy_target_types":["creature"],"effect":"copy_creature_token","exclude_source_from_copy_targets":true,"sacrifice_token_at_end_step":true,"target_controller":"own","token_draw_cards_when_this_dies":1,"token_haste":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class JaxisTheTroublemaker mapped to family copy_creature_token; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('rionya, fire dancer', 'Rionya, Fire Dancer', 'ef40defdde750928a8c7425749e9fba6', 'battle_rule_v1:c907c29d4de7bea750538d5110daa852', '{"ability_kind":"triggered","battle_model_scope":"copy_target_another_creature_you_control_x_instant_sorcery_plus_one_haste_exile_end_step_v1","copy_target_types":["creature"],"effect":"copy_creature_token","exclude_source_from_copy_targets":true,"exile_token_at_end_step":true,"target_controller":"own","token_count_source":"instant_or_sorcery_spells_cast_this_turn_plus_one","token_haste":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class RionyaFireDancer mapped to family copy_creature_token; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('the jolly balloon man', 'The Jolly Balloon Man', 'c7f3f2f27d70fe9c5abb53ad64e06dd0', 'battle_rule_v1:e2ff37fab414ef5ed43b5dc17b921f63', '{"ability_kind":"activated","battle_model_scope":"copy_target_another_creature_you_control_balloon_1_1_red_flying_haste_sacrifice_end_step_v1","copy_target_types":["creature"],"effect":"copy_creature_token","exclude_source_from_copy_targets":true,"force_token_creature":true,"sacrifice_token_at_end_step":true,"target_controller":"own","token_extra_colors":["R"],"token_flying":true,"token_haste":true,"token_power":1,"token_subtype":"Balloon","token_toughness":1}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TheJollyBalloonMan mapped to family copy_creature_token; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg142_current_replay_copy_token_trio_two_20260624_042157) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
