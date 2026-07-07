BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('adamaro, first to desire', 'maro', 'masumaro, first to live', 'multani, maro-sorcerer')
   OR normalized_name LIKE 'adamaro, first to desire // %'
   OR normalized_name LIKE 'maro // %'
   OR normalized_name LIKE 'masumaro, first to live // %'
   OR normalized_name LIKE 'multani, maro-sorcerer // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg600_static_hand_count_pt_new_server_pg_20260707_070624;

COMMIT;
