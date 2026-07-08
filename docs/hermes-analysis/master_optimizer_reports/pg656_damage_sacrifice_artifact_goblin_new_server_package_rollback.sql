BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('goblin grenade', 'shrapnel blast')
   OR normalized_name LIKE 'goblin grenade // %'
   OR normalized_name LIKE 'shrapnel blast // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg656_damage_sacrifice_artifact_goblin_n_20260708_124341;

COMMIT;
