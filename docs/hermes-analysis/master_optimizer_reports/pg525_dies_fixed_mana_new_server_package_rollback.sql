BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('cathodion', 'myr moonvessel', 'su-chi')
   OR normalized_name LIKE 'cathodion // %'
   OR normalized_name LIKE 'myr moonvessel // %'
   OR normalized_name LIKE 'su-chi // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.xmage_pg525_dies_fixed_mana_new_server_p_20260705_192227;

COMMIT;
