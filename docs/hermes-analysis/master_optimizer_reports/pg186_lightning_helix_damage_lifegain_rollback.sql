BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('lightning helix')
   OR normalized_name LIKE 'lightning helix // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg186_lightning_helix_damage_lifegain_20260624_203505;

COMMIT;
