BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('gleemox')
   OR normalized_name LIKE 'gleemox // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg794_static_info_mana_source_new_server_20260712_000150;

COMMIT;
