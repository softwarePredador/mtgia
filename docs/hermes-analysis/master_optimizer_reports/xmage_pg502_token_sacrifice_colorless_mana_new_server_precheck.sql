WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('dread drone', 'Dread Drone', 'a779a0fb75b8dac335613d3efa028f75', 'battle_rule_v1:4977ea2073119ffdc86918b1496b93b1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_count":2,"etb_token_mana_activation_requires_sacrifice":true,"etb_token_mana_activation_requires_tap":false,"etb_token_mana_produced":1,"etb_token_name":"Eldrazi Spawn Token","etb_token_power":0,"etb_token_produced_mana_symbols":["C"],"etb_token_produces":"C","etb_token_sacrifice_for_colorless_mana":true,"etb_token_subtype":"Eldrazi Spawn","etb_token_toughness":1,"token_description":"0/1 colorless Eldrazi Spawn creature token with \"Sacrifice this token: Add {C}.\"","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"EldraziSpawnToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DreadDrone translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('emrakul''s hatcher', 'Emrakul''s Hatcher', '3b806bf1df091419ed95198da66c165e', 'battle_rule_v1:ac512ef260039c67afe5cc63566955c6', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_count":3,"etb_token_mana_activation_requires_sacrifice":true,"etb_token_mana_activation_requires_tap":false,"etb_token_mana_produced":1,"etb_token_name":"Eldrazi Spawn Token","etb_token_power":0,"etb_token_produced_mana_symbols":["C"],"etb_token_produces":"C","etb_token_sacrifice_for_colorless_mana":true,"etb_token_subtype":"Eldrazi Spawn","etb_token_toughness":1,"token_description":"0/1 colorless Eldrazi Spawn creature token with \"Sacrifice this token: Add {C}.\"","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"EldraziSpawnToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EmrakulsHatcher translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kozilek''s predator', 'Kozilek''s Predator', 'a779a0fb75b8dac335613d3efa028f75', 'battle_rule_v1:4977ea2073119ffdc86918b1496b93b1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_count":2,"etb_token_mana_activation_requires_sacrifice":true,"etb_token_mana_activation_requires_tap":false,"etb_token_mana_produced":1,"etb_token_name":"Eldrazi Spawn Token","etb_token_power":0,"etb_token_produced_mana_symbols":["C"],"etb_token_produces":"C","etb_token_sacrifice_for_colorless_mana":true,"etb_token_subtype":"Eldrazi Spawn","etb_token_toughness":1,"token_description":"0/1 colorless Eldrazi Spawn creature token with \"Sacrifice this token: Add {C}.\"","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"EldraziSpawnToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KozileksPredator translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nest invader', 'Nest Invader', 'ea31a3014a52677b8278f66792c7de2d', 'battle_rule_v1:78d896732ea9eefc2e22a28974526cd9', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_count":1,"etb_token_mana_activation_requires_sacrifice":true,"etb_token_mana_activation_requires_tap":false,"etb_token_mana_produced":1,"etb_token_name":"Eldrazi Spawn Token","etb_token_power":0,"etb_token_produced_mana_symbols":["C"],"etb_token_produces":"C","etb_token_sacrifice_for_colorless_mana":true,"etb_token_subtype":"Eldrazi Spawn","etb_token_toughness":1,"token_description":"0/1 colorless Eldrazi Spawn creature token with \"Sacrifice this token: Add {C}.\"","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"EldraziSpawnToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NestInvader translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('skittering invasion', 'Skittering Invasion', '744a28ccbdcf3c2e54fcda739061d6a6', 'battle_rule_v1:e1d250018bb56e6a9c6e3fe2143e5568', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","token_count":5,"token_description":"0/1 colorless Eldrazi Spawn creature token with \"Sacrifice this token: Add {C}.\"","token_mana_activation_requires_sacrifice":true,"token_mana_activation_requires_tap":false,"token_mana_produced":1,"token_name":"Eldrazi Spawn Token","token_power":0,"token_produced_mana_symbols":["C"],"token_produces":"C","token_sacrifice_for_colorless_mana":true,"token_subtype":"Eldrazi Spawn","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"EldraziSpawnToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SkitteringInvasion translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
