BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('armorcraft judge', 'discerning peddler', 'earthshaker dreadmaw', 'fissure wizard', 'immersturm raider', 'keldon raider', 'plundering predator', 'prophet of the scarab', 'regal force', 'shinestriker', 'viashino racketeer', 'yuyan archers')
   OR normalized_name LIKE 'armorcraft judge // %'
   OR normalized_name LIKE 'discerning peddler // %'
   OR normalized_name LIKE 'earthshaker dreadmaw // %'
   OR normalized_name LIKE 'fissure wizard // %'
   OR normalized_name LIKE 'immersturm raider // %'
   OR normalized_name LIKE 'keldon raider // %'
   OR normalized_name LIKE 'plundering predator // %'
   OR normalized_name LIKE 'prophet of the scarab // %'
   OR normalized_name LIKE 'regal force // %'
   OR normalized_name LIKE 'shinestriker // %'
   OR normalized_name LIKE 'viashino racketeer // %'
   OR normalized_name LIKE 'yuyan archers // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg481_etb_draw_patterns_new_server_20260705_042634;

COMMIT;
