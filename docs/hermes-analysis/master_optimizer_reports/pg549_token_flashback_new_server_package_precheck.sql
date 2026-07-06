WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('army of the damned', 'Army of the Damned', '4905dce455a89e75362d5b0478daa350', 'battle_rule_v1:e101ae8cffb1ad36659191cb37a7f80d', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","flashback_cost":"{7}{B}{B}{B}","flashback_status":"runtime_executor_v1","token_colors":["B"],"token_count":13,"token_description":"2/2 black Zombie creature token","token_name":"Zombie Token","token_power":2,"token_subtype":"Zombie","token_tapped":true,"token_toughness":2,"xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"ZombieToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ArmyOfTheDamned translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('beast attack', 'Beast Attack', '2a291b12d5aec28bc5c60574452d473b', 'battle_rule_v1:20c56778a1992592a9e79070be36ffe0', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","flashback_cost":"{2}{G}{G}{G}","flashback_status":"runtime_executor_v1","token_colors":["G"],"token_count":1,"token_description":"4/4 green Beast creature token","token_name":"Beast Token","token_power":4,"token_subtype":"Beast","token_toughness":4,"xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"Beast44Token"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BeastAttack translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('call of the herd', 'Call of the Herd', '783884211b45c5b76ff4959686b9e366', 'battle_rule_v1:6ba5014e640d21a31f5ebc1f5e9185d5', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","flashback_cost":"{3}{G}","flashback_status":"runtime_executor_v1","token_colors":["G"],"token_count":1,"token_description":"3/3 green Elephant creature token","token_name":"Elephant Token","token_power":3,"token_subtype":"Elephant","token_toughness":3,"xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"ElephantToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CallOfTheHerd translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('chatter of the squirrel', 'Chatter of the Squirrel', '0e2fd068dca30f2569722baaa5ff9e53', 'battle_rule_v1:c0e16a90ce29ded5d1194a4e20dda154', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","flashback_cost":"{1}{G}","flashback_status":"runtime_executor_v1","token_colors":["G"],"token_count":1,"token_description":"1/1 green Squirrel creature token","token_name":"Squirrel Token","token_power":1,"token_subtype":"Squirrel","token_toughness":1,"xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SquirrelToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ChatterOfTheSquirrel translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('crush of wurms', 'Crush of Wurms', 'fef198b6e8474d61347290d37185257e', 'battle_rule_v1:980fed86a6285fffbece2444a59aea6d', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","flashback_cost":"{9}{G}{G}{G}","flashback_status":"runtime_executor_v1","token_colors":["G"],"token_count":3,"token_description":"6/6 green Wurm creature token","token_name":"Wurm Token","token_power":6,"token_subtype":"Wurm","token_toughness":6,"xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"WurmToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CrushOfWurms translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('elephant ambush', 'Elephant Ambush', '68d862f995dc322039a4103300577efa', 'battle_rule_v1:ace48628d5ae36959b46552d369fd486', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","flashback_cost":"{6}{G}{G}","flashback_status":"runtime_executor_v1","token_colors":["G"],"token_count":1,"token_description":"3/3 green Elephant creature token","token_name":"Elephant Token","token_power":3,"token_subtype":"Elephant","token_toughness":3,"xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"ElephantToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ElephantAmbush translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('join the dance', 'Join the Dance', '2ba7a34bd7062658268f7a21fe59548f', 'battle_rule_v1:3eb8c5091faf5fc53be72d36b1eb2196', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","flashback_cost":"{3}{G}{W}","flashback_status":"runtime_executor_v1","token_colors":["W"],"token_count":2,"token_description":"1/1 white Human creature token","token_name":"Human Token","token_power":1,"token_subtype":"Human","token_toughness":1,"xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"HumanToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JoinTheDance translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lingering souls', 'Lingering Souls', 'ef8670b9500a3748b7dcac01007352ee', 'battle_rule_v1:a4c61759b967ecfaccf80a59d38353b3', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","flashback_cost":"{1}{B}","flashback_status":"runtime_executor_v1","token_colors":["W"],"token_count":2,"token_description":"1/1 white Spirit creature token with flying","token_flying":true,"token_keywords":["flying"],"token_name":"Spirit Token","token_power":1,"token_subtype":"Spirit","token_toughness":1,"xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SpiritWhiteToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LingeringSouls translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('moan of the unhallowed', 'Moan of the Unhallowed', '5bd6d795206c41573e35ae75bea8cfc7', 'battle_rule_v1:66a4f2f8592f1a22b703004e3cef386d', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","flashback_cost":"{5}{B}{B}","flashback_status":"runtime_executor_v1","token_colors":["B"],"token_count":2,"token_description":"2/2 black Zombie creature token","token_name":"Zombie Token","token_power":2,"token_subtype":"Zombie","token_toughness":2,"xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"ZombieToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MoanOfTheUnhallowed translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reap the seagraf', 'Reap the Seagraf', 'bc733e8b9b926952dc3b4507e35c6e06', 'battle_rule_v1:a7916f222a9928fbecbb1fa2e0fcb225', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","flashback_cost":"{4}{U}","flashback_status":"runtime_executor_v1","token_colors":["B"],"token_count":1,"token_description":"2/2 black Zombie creature token","token_name":"Zombie Token","token_power":2,"token_subtype":"Zombie","token_toughness":2,"xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"ZombieToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ReapTheSeagraf translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('roar of the wurm', 'Roar of the Wurm', 'cc3761b8b20e3478ff772bd58c173341', 'battle_rule_v1:0f83c527186efe0000b099e4355cfe91', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","flashback_cost":"{3}{G}","flashback_status":"runtime_executor_v1","token_colors":["G"],"token_count":1,"token_description":"6/6 green Wurm creature token","token_name":"Wurm Token","token_power":6,"token_subtype":"Wurm","token_toughness":6,"xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"WurmToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RoarOfTheWurm translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shadowbeast sighting', 'Shadowbeast Sighting', 'c97547d092808a4c795699edc4a6e2f9', 'battle_rule_v1:dc8bc7bd6132e782fac0098d05975c6c', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","flashback_cost":"{6}{G}","flashback_status":"runtime_executor_v1","token_colors":["G"],"token_count":1,"token_description":"4/4 green Beast creature token","token_name":"Beast Token","token_power":4,"token_subtype":"Beast","token_toughness":4,"xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"Beast44Token"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShadowbeastSighting translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
