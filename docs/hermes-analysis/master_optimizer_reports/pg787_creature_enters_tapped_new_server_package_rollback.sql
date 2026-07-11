BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('crooked custodian', 'diregraf ghoul', 'forgotten sentinel', 'rotting legion', 'rusted sentinel', 'scarwood treefolk', 'shambling ghoul', 'unhallowed phalanx', 'wolf cove villager')
   OR normalized_name LIKE 'crooked custodian // %'
   OR normalized_name LIKE 'diregraf ghoul // %'
   OR normalized_name LIKE 'forgotten sentinel // %'
   OR normalized_name LIKE 'rotting legion // %'
   OR normalized_name LIKE 'rusted sentinel // %'
   OR normalized_name LIKE 'scarwood treefolk // %'
   OR normalized_name LIKE 'shambling ghoul // %'
   OR normalized_name LIKE 'unhallowed phalanx // %'
   OR normalized_name LIKE 'wolf cove villager // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg787_creature_enters_tapped_new_server_20260711_210754;

COMMIT;
