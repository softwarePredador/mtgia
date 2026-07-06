BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('triplicate titan', 'trostani''s summoner', 'wurmcoil engine', 'wurmcoil larva')
   OR normalized_name LIKE 'triplicate titan // %'
   OR normalized_name LIKE 'trostani''s summoner // %'
   OR normalized_name LIKE 'wurmcoil engine // %'
   OR normalized_name LIKE 'wurmcoil larva // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg544_multi_trigger_tokens_new_server_pg_20260706_024814;

COMMIT;
