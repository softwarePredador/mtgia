BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('boltwave')
   OR normalized_name LIKE 'boltwave // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg206_damage_each_opponent_20260625_063222;

COMMIT;
