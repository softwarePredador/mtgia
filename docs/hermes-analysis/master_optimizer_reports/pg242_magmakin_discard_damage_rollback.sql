BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('magmakin artillerist')
   OR normalized_name LIKE 'magmakin artillerist // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg242_magmakin_discard_damage_20260626_112544;

COMMIT;
