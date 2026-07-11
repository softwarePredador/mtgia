BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('annihilating glare', 'deadly precision', 'lash of the balrog', 'lightning axe', 'pumpkin bombardment')
   OR normalized_name LIKE 'annihilating glare // %'
   OR normalized_name LIKE 'deadly precision // %'
   OR normalized_name LIKE 'lash of the balrog // %'
   OR normalized_name LIKE 'lightning axe // %'
   OR normalized_name LIKE 'pumpkin bombardment // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg783_orcost_pay_generic_spell_cost_new_20260711_191856;

COMMIT;
