SELECT
  r.normalized_name,
  r.logical_rule_key,
  c.name AS postgres_card_name,
  c.oracle_text,
  r.oracle_hash AS current_rule_oracle_hash,
  md5(coalesce(c.oracle_text, '')) AS expected_oracle_hash,
  r.review_status,
  r.execution_status,
  r.effect_json ->> 'effect' AS effect,
  r.effect_json ->> 'battle_model_scope' AS battle_model_scope,
  r.deck_role_json,
  r.reviewed_by,
  r.reviewed_at,
  r.updated_at
FROM public.card_battle_rules r
JOIN public.cards c
  ON c.id = r.card_id
WHERE r.normalized_name = 'seething song'
  AND r.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7';

SELECT
  count(*) AS target_rows,
  count(*) FILTER (
    WHERE r.review_status = 'verified'
      AND r.execution_status = 'auto'
      AND r.effect_json ->> 'effect' = 'ramp_ritual'
      AND r.effect_json ->> 'battle_model_scope' = 'single_shot_red_ritual_v1'
      AND md5(coalesce(c.oracle_text, '')) = 'ccd492289c6f1c14c8fb7a248d7bbf32'
  ) AS safe_target_rows,
  count(*) FILTER (
    WHERE r.oracle_hash IS NULL
  ) AS missing_hash_rows
FROM public.card_battle_rules r
JOIN public.cards c
  ON c.id = r.card_id
WHERE r.normalized_name = 'seething song'
  AND r.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7';
