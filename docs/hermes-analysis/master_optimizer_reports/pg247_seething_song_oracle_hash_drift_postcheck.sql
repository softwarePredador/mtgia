SELECT
  count(*) AS target_rows,
  count(*) FILTER (
    WHERE r.oracle_hash = md5(coalesce(c.oracle_text, ''))
      AND r.oracle_hash = 'ccd492289c6f1c14c8fb7a248d7bbf32'
  ) AS matching_oracle_hash_rows,
  count(*) FILTER (
    WHERE r.review_status = 'verified'
      AND r.execution_status = 'auto'
      AND r.effect_json ->> 'effect' = 'ramp_ritual'
      AND r.effect_json ->> 'battle_model_scope' = 'single_shot_red_ritual_v1'
  ) AS verified_auto_scope_rows,
  (SELECT count(*)
   FROM manaloom_deploy_audit.pg247_seething_song_oracle_hash_drift_20260628) AS backup_rows
FROM public.card_battle_rules r
JOIN public.cards c
  ON c.id = r.card_id
WHERE r.normalized_name = 'seething song'
  AND r.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7';

SELECT
  r.normalized_name,
  r.logical_rule_key,
  r.oracle_hash,
  r.review_status,
  r.execution_status,
  r.effect_json ->> 'effect' AS effect,
  r.effect_json ->> 'battle_model_scope' AS battle_model_scope,
  r.updated_at
FROM public.card_battle_rules r
WHERE r.normalized_name = 'seething song'
  AND r.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7';
