WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('aura of silence', 'Aura of Silence', '6e4cfd52a9afd82047d39f8b76416eb4', 'battle_rule_v1:1e7e893925d6140639fc794bf2510773', '{"ability_kind":"activated","activation_cost":"sacrifice_self","battle_model_scope":"aura_of_silence_tax_and_sacrifice_removal_waiver_v1","effect":"remove_permanent","target":"artifact_or_enchantment","taxes_opponent_artifact_enchantment_spells":2}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class AuraOfSilence mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('nature''s claim', 'Nature''s Claim', 'c88d03f66daf06b46fd567dca8e34c50', 'battle_rule_v1:0ac8416f2210ff0a8466bfb61e3b4b4e', '{"ability_kind":"one_shot","battle_model_scope":"artifact_or_enchantment_removal_lifegain_v1","effect":"remove_permanent","instant":true,"target":"artifact_or_enchantment","target_controller_gains_life":4}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class NaturesClaim mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('seal of primordium', 'Seal of Primordium', '487c743fec96f43d2e18d90cd1432f22', 'battle_rule_v1:bb89a03f7bba301581f6b3e65a46df96', '{"ability_kind":"activated","activation_cost":"sacrifice_self","battle_model_scope":"activated_sacrifice_self_destroy_artifact_or_enchantment_v1","effect":"remove_permanent","target":"artifact_or_enchantment"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SealOfPrimordium mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ON r.normalized_name = p.normalized_name
   AND r.logical_rule_key = p.logical_rule_key
)
SELECT
  p.card_name,
  p.normalized_name,
  p.logical_rule_key,
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS promoted_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS promoted_verified_auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS promoted_oracle_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg123_artifact_enchantment_targeted_interaction_restore_) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
