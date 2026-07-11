WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('zaxara, the exemplary', 'Zaxara, the Exemplary', 'bdb261d7904dbecf9ddaa6ddb01f9b40', 'battle_rule_v1:58a25a96c5e3a7c34298ed75986ed05a', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_with_x_spell_token_counter_trigger_v1","e2e_x_value":2,"effect":"ramp_permanent","is_mana_source":true,"keywords":["deathtouch"],"mana_activation_requires_tap":true,"mana_produced":2,"permanent_type":"creature","produces":"WUBRG","source_mana_cost":"{1}{B}{G}{U}","source_type_line":"Legendary Creature \u2014 Nightmare Hydra","spell_cast_token_count_source":"fixed","spell_cast_token_maker":true,"spell_cast_token_requires_x_mana_cost":true,"token_colors":["G"],"token_count":1,"token_enters_with_counter_type":"+1/+1","token_enters_with_counters_source":"x_value","token_enters_with_plus_one_counters_from_x":true,"token_name":"Hydra Token","token_power":0,"token_subtype":"Hydra","token_toughness":0,"trigger":"spell_cast","trigger_effect":"token_maker","trigger_token_count":1,"xmage_ability_classes":["DeathtouchAbility","SimpleManaAbility","ZaxaraTheExemplaryHydraTokenAbility"],"xmage_auxiliary_ability_classes":["DeathtouchAbility","ZaxaraTheExemplaryHydraTokenAbility"],"xmage_effect_classes":["AddManaOfAnyColorEffect","OneShotEffect","ZaxaraTheExemplaryHydraTokenEffect"],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ZaxaraTheExemplary translated into ManaLoom runtime scope xmage_simple_tap_mana_source_with_x_spell_token_counter_trigger_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg766_zaxara_new_server_zaxara_x_spell_h_20260711_140715) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
