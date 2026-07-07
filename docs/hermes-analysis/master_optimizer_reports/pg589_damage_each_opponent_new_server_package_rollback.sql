BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('breath of malfegor', 'sizzle')
   OR normalized_name LIKE 'breath of malfegor // %'
   OR normalized_name LIKE 'sizzle // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg589_damage_each_opponent_new_server_20260707_031213;

COMMIT;
