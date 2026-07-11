BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('donatello, turtle techie', 'opal lake gatekeepers', 'resistance squad', 'rhox meditant', 'scholar of stars', 'settlement blacksmith')
   OR normalized_name LIKE 'donatello, turtle techie // %'
   OR normalized_name LIKE 'opal lake gatekeepers // %'
   OR normalized_name LIKE 'resistance squad // %'
   OR normalized_name LIKE 'rhox meditant // %'
   OR normalized_name LIKE 'scholar of stars // %'
   OR normalized_name LIKE 'settlement blacksmith // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg740_conditional_etb_draw_new_server_20260711_041438;

COMMIT;
