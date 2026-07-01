BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('aven fisher', 'buzz bots', 'darkslick drake', 'exultant cultist', 'feral prowler', 'ithilien kingfisher', 'kingfisher', 'malcator''s watcher', 'messenger drake', 'oculus', 'outlaw medic', 'palace familiar', 'purple-crystal crab', 'riptide crab', 'runewing', 'silverback shaman', 'spore crawler', 'summit sentinel', 'surveilling sprite', 'youthful scholar')
   OR normalized_name LIKE 'aven fisher // %'
   OR normalized_name LIKE 'buzz bots // %'
   OR normalized_name LIKE 'darkslick drake // %'
   OR normalized_name LIKE 'exultant cultist // %'
   OR normalized_name LIKE 'feral prowler // %'
   OR normalized_name LIKE 'ithilien kingfisher // %'
   OR normalized_name LIKE 'kingfisher // %'
   OR normalized_name LIKE 'malcator''s watcher // %'
   OR normalized_name LIKE 'messenger drake // %'
   OR normalized_name LIKE 'oculus // %'
   OR normalized_name LIKE 'outlaw medic // %'
   OR normalized_name LIKE 'palace familiar // %'
   OR normalized_name LIKE 'purple-crystal crab // %'
   OR normalized_name LIKE 'riptide crab // %'
   OR normalized_name LIKE 'runewing // %'
   OR normalized_name LIKE 'silverback shaman // %'
   OR normalized_name LIKE 'spore crawler // %'
   OR normalized_name LIKE 'summit sentinel // %'
   OR normalized_name LIKE 'surveilling sprite // %'
   OR normalized_name LIKE 'youthful scholar // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg301_xmage_creature_dies_draw_wave_20260701_113423;

COMMIT;
