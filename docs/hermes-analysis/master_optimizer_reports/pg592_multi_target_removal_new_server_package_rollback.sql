BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('aether gale', 'captivating gyre', 'curtains'' call', 'dust to dust', 'hex', 'into the core', 'into the void', 'peace and quiet', 'quicksilver geyser', 'rack and ruin', 'rain of salt', 'sea god''s scorn', 'undo', 'violent ultimatum', 'waterwhirl')
   OR normalized_name LIKE 'aether gale // %'
   OR normalized_name LIKE 'captivating gyre // %'
   OR normalized_name LIKE 'curtains'' call // %'
   OR normalized_name LIKE 'dust to dust // %'
   OR normalized_name LIKE 'hex // %'
   OR normalized_name LIKE 'into the core // %'
   OR normalized_name LIKE 'into the void // %'
   OR normalized_name LIKE 'peace and quiet // %'
   OR normalized_name LIKE 'quicksilver geyser // %'
   OR normalized_name LIKE 'rack and ruin // %'
   OR normalized_name LIKE 'rain of salt // %'
   OR normalized_name LIKE 'sea god''s scorn // %'
   OR normalized_name LIKE 'undo // %'
   OR normalized_name LIKE 'violent ultimatum // %'
   OR normalized_name LIKE 'waterwhirl // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg592_multi_target_removal_new_server_20260707_041006;

COMMIT;
