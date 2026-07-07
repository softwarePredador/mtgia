BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('need for speed', 'selfless savior', 'slobad, goblin tinkerer', 'torch courier', 'vial of poison')
   OR normalized_name LIKE 'need for speed // %'
   OR normalized_name LIKE 'selfless savior // %'
   OR normalized_name LIKE 'slobad, goblin tinkerer // %'
   OR normalized_name LIKE 'torch courier // %'
   OR normalized_name LIKE 'vial of poison // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg618_activated_target_keyword_sacrifice_20260707_134204;

COMMIT;
