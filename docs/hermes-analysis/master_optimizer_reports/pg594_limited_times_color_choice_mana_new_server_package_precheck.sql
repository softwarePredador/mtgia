WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('abzan devotee', 'Abzan Devotee', '9c3a5db4e485b9bbc88ca9674cae5d2d', 'battle_rule_v1:ec27a3244974e2e7cc45b9291344b996', '{"_runtime_partial":true,"_runtime_partial_reason":"Only the XMage limited-times mana ability is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_limit_per_turn":1,"activation_mana_cost":"{1}","activation_requires_tap":false,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":false,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"creature","produces":"WBG","xmage_ability_classes":["LimitedTimesPerTurnActivatedManaAbility","SimpleActivatedAbility"],"xmage_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_effect_classes":["AddManaFromColorChoicesEffect","ReturnSourceFromGraveyardToHandEffect"],"xmage_mana_ability_classes":["LimitedTimesPerTurnActivatedManaAbility"],"xmage_mana_effect_class":"AddManaFromColorChoicesEffect","xmage_unmodeled_auxiliary_ability_classes":["SimpleActivatedAbility"],"xmage_unmodeled_effect_classes":["ReturnSourceFromGraveyardToHandEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AbzanDevotee translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jeskai devotee', 'Jeskai Devotee', 'ed2d39b9737e32da59835c4f550998ef', 'battle_rule_v1:366a77726fbc36fee6bc986f7d5572f3', '{"_runtime_partial":true,"_runtime_partial_reason":"Only the XMage limited-times mana ability is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_limit_per_turn":1,"activation_mana_cost":"{1}","activation_requires_tap":false,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":false,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"creature","produces":"URW","xmage_ability_classes":["FlurryAbility","LimitedTimesPerTurnActivatedManaAbility"],"xmage_auxiliary_ability_classes":["FlurryAbility"],"xmage_effect_classes":["AddManaFromColorChoicesEffect","BoostSourceEffect"],"xmage_mana_ability_classes":["LimitedTimesPerTurnActivatedManaAbility"],"xmage_mana_effect_class":"AddManaFromColorChoicesEffect","xmage_unmodeled_auxiliary_ability_classes":["FlurryAbility"],"xmage_unmodeled_effect_classes":["BoostSourceEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JeskaiDevotee translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sultai devotee', 'Sultai Devotee', 'f2c9254c4ec58cbfaeeb0f55a6107a14', 'battle_rule_v1:ac00d4cfa40a1f39085818b69fd432d9', '{"ability_kind":"activated_mana","activation_limit_per_turn":1,"activation_mana_cost":"{1}","activation_requires_tap":false,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"keywords":["deathtouch"],"mana_activation_requires_tap":false,"mana_produced":1,"permanent_type":"creature","produces":"BGU","xmage_ability_classes":["DeathtouchAbility","LimitedTimesPerTurnActivatedManaAbility"],"xmage_effect_classes":["AddManaFromColorChoicesEffect"],"xmage_mana_ability_classes":["LimitedTimesPerTurnActivatedManaAbility"],"xmage_mana_effect_class":"AddManaFromColorChoicesEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SultaiDevotee translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('temur devotee', 'Temur Devotee', 'b8d5f929ccf01696c7e8523a5a842d47', 'battle_rule_v1:7a52921eb54b9b61f5cbd0adaf50745f', '{"ability_kind":"activated_mana","activation_limit_per_turn":1,"activation_mana_cost":"{1}","activation_requires_tap":false,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"keywords":["defender"],"mana_activation_requires_tap":false,"mana_produced":1,"permanent_type":"creature","produces":"GUR","xmage_ability_classes":["DefenderAbility","LimitedTimesPerTurnActivatedManaAbility"],"xmage_effect_classes":["AddManaFromColorChoicesEffect"],"xmage_mana_ability_classes":["LimitedTimesPerTurnActivatedManaAbility"],"xmage_mana_effect_class":"AddManaFromColorChoicesEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TemurDevotee translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
matched_cards AS (
  SELECT
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    c.id AS card_id,
    c.name AS db_card_name
  FROM proposed p
  LEFT JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
target_cards AS (
  SELECT
    normalized_name,
    card_name,
    oracle_hash,
    count(card_id) AS target_card_rows,
    min(card_id::text)::uuid AS canonical_card_id,
    min(db_card_name) AS canonical_card_name
  FROM matched_cards
  GROUP BY normalized_name, card_name, oracle_hash
),
rule_rows AS (
  SELECT p.normalized_name, count(r.*) AS existing_rule_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
  GROUP BY p.normalized_name
),
expected_rows AS (
  SELECT p.normalized_name, count(r.*) AS expected_rule_rows_before
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
  GROUP BY p.normalized_name
),
shadow_rows AS (
  SELECT p.normalized_name, count(r.*) AS would_deprecate_shadow_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key <> p.logical_rule_key
   AND r.review_status NOT IN ('deprecated', 'rejected')
   AND r.execution_status <> 'disabled'
  GROUP BY p.normalized_name
)
SELECT
  p.card_name,
  p.normalized_name,
  p.oracle_hash,
  p.logical_rule_key,
  p.shadow_handling,
  tc.target_card_rows,
  tc.canonical_card_id,
  rr.existing_rule_rows,
  er.expected_rule_rows_before,
  sr.would_deprecate_shadow_rows
FROM proposed p
JOIN target_cards tc USING (normalized_name, card_name, oracle_hash)
JOIN rule_rows rr USING (normalized_name)
JOIN expected_rows er USING (normalized_name)
JOIN shadow_rows sr USING (normalized_name)
ORDER BY p.card_name;
