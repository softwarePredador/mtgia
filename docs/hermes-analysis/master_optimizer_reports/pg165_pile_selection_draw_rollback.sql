BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('fact or fiction', 'steam augury')
   OR normalized_name LIKE 'fact or fiction // %'
   OR normalized_name LIKE 'steam augury // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg165_pile_selection_draw_20260624_104321;

COMMIT;
