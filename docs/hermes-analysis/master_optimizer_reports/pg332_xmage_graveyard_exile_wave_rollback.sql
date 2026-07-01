BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('carrion beetles', 'crypt creeper', 'famished ghoul', 'heap doll', 'rag dealer', 'thraben heretic', 'withered wretch')
   OR normalized_name LIKE 'carrion beetles // %'
   OR normalized_name LIKE 'crypt creeper // %'
   OR normalized_name LIKE 'famished ghoul // %'
   OR normalized_name LIKE 'heap doll // %'
   OR normalized_name LIKE 'rag dealer // %'
   OR normalized_name LIKE 'thraben heretic // %'
   OR normalized_name LIKE 'withered wretch // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg332_xmage_graveyard_exile_wave_xmage_graveyard_exile_w;

COMMIT;
