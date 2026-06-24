WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('birds of paradise', 'Birds of Paradise', '2119fc1976cfab2480a9d86c57f1859b', 'battle_rule_v1:5d3ec3f1d92cfe2044d0172c4e3765ba', '{"ability_kind":"activated","battle_model_scope":"one_mana_zero_one_flying_any_color_mana_dork_v1","effect":"creature","flying":true,"is_mana_source":true,"mana_produced":1,"power":0,"produces":"WUBRG","toughness":1}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BirdsOfParadise mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('llanowar elves', 'Llanowar Elves', 'fa07d150550fe544837233efd56086ac', 'battle_rule_v1:b4d210018767f5b0a4740adc889beb85', '{"ability_kind":"activated","battle_model_scope":"one_mana_one_one_green_mana_dork_v1","effect":"creature","is_mana_source":true,"mana_produced":1,"power":1,"produces":"G","toughness":1}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class LlanowarElves mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('elvish mystic', 'Elvish Mystic', 'fa07d150550fe544837233efd56086ac', 'battle_rule_v1:b4d210018767f5b0a4740adc889beb85', '{"ability_kind":"activated","battle_model_scope":"one_mana_one_one_green_mana_dork_v1","effect":"creature","is_mana_source":true,"mana_produced":1,"power":1,"produces":"G","toughness":1}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ElvishMystic mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('avacyn''s pilgrim', 'Avacyn''s Pilgrim', 'c7264c311c98ff99b293a96ad9ab2daf', 'battle_rule_v1:123fb4f1873cbd3debade4877e0b6788', '{"ability_kind":"activated","battle_model_scope":"one_mana_one_one_white_mana_dork_v1","effect":"creature","is_mana_source":true,"mana_produced":1,"power":1,"produces":"W","toughness":1}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class AvacynsPilgrim mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('fyndhorn elves', 'Fyndhorn Elves', 'fa07d150550fe544837233efd56086ac', 'battle_rule_v1:b4d210018767f5b0a4740adc889beb85', '{"ability_kind":"activated","battle_model_scope":"one_mana_one_one_green_mana_dork_v1","effect":"creature","is_mana_source":true,"mana_produced":1,"power":1,"produces":"G","toughness":1}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FyndhornElves mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg153_simple_mana_dorks_20260624_081116) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
