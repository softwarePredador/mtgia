WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('orcish bowmasters', 'Orcish Bowmasters', 'd4bad6405b84c07af1e2cfc69adbb695', 'battle_rule_v1:be12835f3e35436f0165be1b72332b80', '{"ability_kind":"triggered","amass_orcs":1,"battle_model_scope":"flash_etb_or_opponent_extra_draw_damage_any_target_amass_orcs_v1","effect":"creature","etb_or_opponent_extra_draw_damage_any_target":1,"flash":true,"power":1,"toughness":1}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class OrcishBowmasters mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('deathrite shaman', 'Deathrite Shaman', 'cd21617578372b91f014529b4dc88d7d', 'battle_rule_v1:8639d78d048c4d0e7764dde65cbeac26', '{"ability_kind":"activated","battle_model_scope":"graveyard_exile_mana_or_life_shaman_v1","black_tap_exile_instant_or_sorcery_from_graveyard_each_opponent_loses_life":2,"effect":"creature","green_tap_exile_creature_from_graveyard_gain_life":2,"power":1,"tap_exile_land_from_graveyard_add_one_mana_any_color":true,"toughness":2}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class DeathriteShaman mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg132_current_replay_triggered_utility_runtime_restore_2) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
