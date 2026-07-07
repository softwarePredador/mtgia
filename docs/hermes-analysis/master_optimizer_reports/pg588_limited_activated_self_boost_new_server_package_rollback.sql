BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('azimaet drake', 'darkthicket wolf', 'drake hatchling', 'fire drake', 'frilled oculus', 'frilled sandwalla', 'ghor-clan bloodscale', 'knight of the skyward eye', 'kraven''s cats', 'plated rootwalla', 'rootwalla', 'setessan griffin', 'snarling wolf', 'spitting drake', 'viashino slaughtermaster', 'wild aesthir')
   OR normalized_name LIKE 'azimaet drake // %'
   OR normalized_name LIKE 'darkthicket wolf // %'
   OR normalized_name LIKE 'drake hatchling // %'
   OR normalized_name LIKE 'fire drake // %'
   OR normalized_name LIKE 'frilled oculus // %'
   OR normalized_name LIKE 'frilled sandwalla // %'
   OR normalized_name LIKE 'ghor-clan bloodscale // %'
   OR normalized_name LIKE 'knight of the skyward eye // %'
   OR normalized_name LIKE 'kraven''s cats // %'
   OR normalized_name LIKE 'plated rootwalla // %'
   OR normalized_name LIKE 'rootwalla // %'
   OR normalized_name LIKE 'setessan griffin // %'
   OR normalized_name LIKE 'snarling wolf // %'
   OR normalized_name LIKE 'spitting drake // %'
   OR normalized_name LIKE 'viashino slaughtermaster // %'
   OR normalized_name LIKE 'wild aesthir // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg588_limited_activated_self_boost_new_s_20260707_030124;

COMMIT;
