BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('anarchist', 'archaeomender', 'ardent elementalist', 'auramancer', 'baloth null', 'cartographer', 'elvish regrower', 'golgari findbroker', 'gravedigger', 'izzet chronarch', 'monk idealist', 'moriok scavenger', 'pharika''s mender', 'restoration gearsmith', 'salvager of secrets', 'scrivener', 'stoic builder', 'tilling treefolk', 'treasure hunter', 'trusty packbeast', 'warden of the eye', 'zealous lorecaster')
   OR normalized_name LIKE 'anarchist // %'
   OR normalized_name LIKE 'archaeomender // %'
   OR normalized_name LIKE 'ardent elementalist // %'
   OR normalized_name LIKE 'auramancer // %'
   OR normalized_name LIKE 'baloth null // %'
   OR normalized_name LIKE 'cartographer // %'
   OR normalized_name LIKE 'elvish regrower // %'
   OR normalized_name LIKE 'golgari findbroker // %'
   OR normalized_name LIKE 'gravedigger // %'
   OR normalized_name LIKE 'izzet chronarch // %'
   OR normalized_name LIKE 'monk idealist // %'
   OR normalized_name LIKE 'moriok scavenger // %'
   OR normalized_name LIKE 'pharika''s mender // %'
   OR normalized_name LIKE 'restoration gearsmith // %'
   OR normalized_name LIKE 'salvager of secrets // %'
   OR normalized_name LIKE 'scrivener // %'
   OR normalized_name LIKE 'stoic builder // %'
   OR normalized_name LIKE 'tilling treefolk // %'
   OR normalized_name LIKE 'treasure hunter // %'
   OR normalized_name LIKE 'trusty packbeast // %'
   OR normalized_name LIKE 'warden of the eye // %'
   OR normalized_name LIKE 'zealous lorecaster // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg298_xmage_creature_etb_recursion_wave_20260701_110053;

COMMIT;
