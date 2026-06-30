WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('eight-and-a-half-tails', 'Eight-and-a-Half-Tails', '4f6c69b2d534cf39031dbdfc804377ce', 'battle_rule_v1:f7cc24bc3332146a3ab6da1d3397fa39', '{"ability_kind":"activated","activated_protection_status":"runtime_executor_v1","activation_cost":"{1} plus {1}{W}","activation_requires_tap":false,"battle_model_scope":"creature_body_target_permanent_protection_from_white_make_source_white_activation_runtime_v1","can_make_source_white_for_protection":true,"duration":"until_end_of_turn","effect":"creature","is_creature_permanent":true,"oracle_runtime_scope":"targeted_stack_removal_response_protection_activation_runtime_v1","power":2,"protection_activation_timing":"targeted_stack_response","protection_choices":["white"],"protection_target":"target_permanent_you_control","runtime_modeled_effect":"creature_body_plus_targeted_protection_response","source_color_change_target":"target_spell_or_permanent","source_color_change_to":"white","source_must_be_untapped":false,"summoning_sickness_applies_to_activation":false,"tap_activation":false,"targeted_protection_activation_mana_cost":"{2}{W}","toughness":2,"xmage_effect":"SimpleActivatedAbility + GainAbilityTargetEffect(Protection from white) + BecomesColorTargetEffect(white)"}'::jsonb, '{"category":"protection","effect":"creature","subtype":"activated_targeted_protection_response","timing":"activated_response"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class EightAndAHalfTails mapped to family targeted_protection; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg266_eight_tails_targeted_protection_20260630_061624) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
