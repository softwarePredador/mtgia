BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('aegis of the meek', 'alpha kavu', 'angelic page', 'anointer of champions', 'assembly-worker', 'crenellated wall', 'dwarven lieutenant', 'grassland crusader', 'hate weaver', 'hoof skulkin', 'icatian lieutenant', 'infantry veteran', 'kabuto moth', 'kithkin daggerdare', 'phyrexian debaser', 'serra advocate', 'spirit weaver', 'sword dancer', 'sword of the chosen', 'tuknir deathlock', 'wilderness hypnotist')
   OR normalized_name LIKE 'aegis of the meek // %'
   OR normalized_name LIKE 'alpha kavu // %'
   OR normalized_name LIKE 'angelic page // %'
   OR normalized_name LIKE 'anointer of champions // %'
   OR normalized_name LIKE 'assembly-worker // %'
   OR normalized_name LIKE 'crenellated wall // %'
   OR normalized_name LIKE 'dwarven lieutenant // %'
   OR normalized_name LIKE 'grassland crusader // %'
   OR normalized_name LIKE 'hate weaver // %'
   OR normalized_name LIKE 'hoof skulkin // %'
   OR normalized_name LIKE 'icatian lieutenant // %'
   OR normalized_name LIKE 'infantry veteran // %'
   OR normalized_name LIKE 'kabuto moth // %'
   OR normalized_name LIKE 'kithkin daggerdare // %'
   OR normalized_name LIKE 'phyrexian debaser // %'
   OR normalized_name LIKE 'serra advocate // %'
   OR normalized_name LIKE 'spirit weaver // %'
   OR normalized_name LIKE 'sword dancer // %'
   OR normalized_name LIKE 'sword of the chosen // %'
   OR normalized_name LIKE 'tuknir deathlock // %'
   OR normalized_name LIKE 'wilderness hypnotist // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg853_activated_target_boost_new_server_20260713_002650;

COMMIT;
