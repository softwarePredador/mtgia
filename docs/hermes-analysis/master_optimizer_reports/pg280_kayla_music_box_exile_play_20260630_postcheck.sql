WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('kayla''s music box', 'Kayla''s Music Box', '348760fb8766d6a7185f9a09df78abd9', 'battle_rule_v1:68e589311ca78d53076e317ab21a4151', '{"ability_kind":"activated","activated_exile_top_card_face_down":true,"activated_play_owned_cards_exiled_with_source_until_eot":true,"activation_cost_mana":"{W}","activation_requires_tap":true,"alternate_zone_permission":true,"battle_model_scope":"artifact_w_tap_exile_top_face_down_tap_play_owned_exiled_until_eot_v1","effect":"free_cast","exiled_card_look_permission_controller_only":true,"legendary":true,"may_cast_without_paying_mana_cost":false,"permanent_type":"artifact","play_from_exile_duration":"until_end_of_turn","play_from_exile_owner_scope":"controller_owned_cards_exiled_with_source","play_from_exile_requires_tap":true,"play_lands_from_exile":true}'::jsonb, '{"category":"combo_value","effect":"free_cast","subtype":"play_from_exile_normal_cost","timing":"activated_alternate_zone_permission"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class KaylasMusicBox mapped to family free_cast; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg280_kayla_music_box_exile_play_20260630_123818) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
