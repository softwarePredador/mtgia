BEGIN;

WITH expected(normalized_name, logical_rule_key) AS (
  VALUES
    ('bridgeworks battle', 'battle_rule_v1:d822fc4ce8a0850a7ee20dcee168e8f3'),
    ('hydroelectric specimen', 'battle_rule_v1:88c8f7a7f18d2171c1d200c61f47e6d4'),
    ('selvala, heart of the wilds', 'battle_rule_v1:1ee83f01d2315d8468be5462667233ad'),
    ('devoted druid', 'battle_rule_v1:67f97b25cf58b747257151dada64b9e4'),
    ('birgi, god of storytelling', 'battle_rule_v1:c21762e62b990dbb474be0b5764d71a7'),
    ('fractured powerstone', 'battle_rule_v1:0e90c515e59dff042e41f45158c63e97'),
    ('incubation druid', 'battle_rule_v1:de0ac6ce79a7fff3d4b1f65e91e73d0d'),
    ('delighted halfling', 'battle_rule_v1:3f0dd0a85440805f77ce47815c44214a')
)
DELETE FROM public.card_battle_rules r
USING expected e
WHERE r.normalized_name = e.normalized_name
  AND r.logical_rule_key = e.logical_rule_key;

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg259_exact_ramp_deck_role_repair_20260629_1718;

COMMIT;
