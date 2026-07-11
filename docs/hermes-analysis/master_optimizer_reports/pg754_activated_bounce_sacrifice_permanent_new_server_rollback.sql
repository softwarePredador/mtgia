BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('barrin, master wizard', 'dispersing orb')
   OR normalized_name LIKE 'barrin, master wizard // %'
   OR normalized_name LIKE 'dispersing orb // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg754_activated_bounce_sacrifice_permane_20260711_100844;

COMMIT;
