BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('goblin picker', 'mental discipline', 'merchant of the vale // haggle', 'oread of mountain''s blaze', 'rummaging goblin')
   OR normalized_name LIKE 'goblin picker // %'
   OR normalized_name LIKE 'mental discipline // %'
   OR normalized_name LIKE 'merchant of the vale // haggle // %'
   OR normalized_name LIKE 'oread of mountain''s blaze // %'
   OR normalized_name LIKE 'rummaging goblin // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg468_xmage_permanent_simple_activated_draw_new_server_2;

COMMIT;
