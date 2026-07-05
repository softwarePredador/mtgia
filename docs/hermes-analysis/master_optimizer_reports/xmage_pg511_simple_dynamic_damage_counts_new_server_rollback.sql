BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('runeflare trap', 'storm seeker', 'sudden impact', 'thunder salvo')
   OR normalized_name LIKE 'runeflare trap // %'
   OR normalized_name LIKE 'storm seeker // %'
   OR normalized_name LIKE 'sudden impact // %'
   OR normalized_name LIKE 'thunder salvo // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg511_xmage_pg511_simple_dynamic_damage_20260705_143220;

COMMIT;
