BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('brimstone volley', 'cackling flames', 'galvanic blast')
   OR normalized_name LIKE 'brimstone volley // %'
   OR normalized_name LIKE 'cackling flames // %'
   OR normalized_name LIKE 'galvanic blast // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg769_conditional_damage_new_server_cond_20260711_151731;

COMMIT;
