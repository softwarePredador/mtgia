BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('strafe', 'sunlance')
   OR normalized_name LIKE 'strafe // %'
   OR normalized_name LIKE 'sunlance // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg512_xmage_pg512_nonred_nonwhite_damage_20260705_144951;

COMMIT;
