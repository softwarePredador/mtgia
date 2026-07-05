BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('neurok commando', 'nine-tail white fox', 'scroll thief', 'soulknife spy', 'stealer of secrets')
   OR normalized_name LIKE 'neurok commando // %'
   OR normalized_name LIKE 'nine-tail white fox // %'
   OR normalized_name LIKE 'scroll thief // %'
   OR normalized_name LIKE 'soulknife spy // %'
   OR normalized_name LIKE 'stealer of secrets // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg480_combat_damage_draw_20260705_040440;

COMMIT;
