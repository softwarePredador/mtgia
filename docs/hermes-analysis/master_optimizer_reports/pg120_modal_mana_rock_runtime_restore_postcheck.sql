WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('hedron archive', 'Hedron Archive', '0b901e920cec79011b3c835d55d3c859', 'battle_rule_v1:699a8966e4ddb5d8b8a54f57e243bf7f', '{"activated_self_sacrifice_draw":true,"activation_cost_generic":2,"activation_requires_tap":true,"battle_model_scope":"two_mana_rock_self_sacrifice_draw_two_v1","draw_on_self_sacrifice":2,"effect":"ramp_permanent","mana_produced":2,"produces":"C"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent","subtype":"modal_mana_rock","timing":"activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class HedronArchive mapped to family modal_mana_rock; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('mind stone', 'Mind Stone', '8d1c9b62d7e5642df44a61a63de5e240', 'battle_rule_v1:3818b990dbad7de33216aee39fbb14c8', '{"activated_self_sacrifice_draw":true,"activation_cost_generic":1,"activation_requires_tap":true,"battle_model_scope":"mana_rock_self_sacrifice_draw_v1","effect":"ramp_permanent","mana_produced":1,"produces":"C"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent","subtype":"modal_mana_rock","timing":"activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class MindStone mapped to family modal_mana_rock; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('stonespeaker crystal', 'Stonespeaker Crystal', '28a979e8676f38d3fa18b199d3f7802b', 'battle_rule_v1:3b749c5de073394f1c912fa43d8e7c02', '{"activated_exile_target_player_graveyards":true,"activated_self_sacrifice_draw":true,"activation_cost_generic":2,"activation_requires_tap":true,"battle_model_scope":"two_mana_rock_graveyard_hate_cantrip_v1","effect":"ramp_permanent","mana_produced":2,"produces":"C"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent","subtype":"modal_mana_rock","timing":"activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class StonespeakerCrystal mapped to family modal_mana_rock; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg120_modal_mana_rock_runtime_restore_20260623_224532) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
