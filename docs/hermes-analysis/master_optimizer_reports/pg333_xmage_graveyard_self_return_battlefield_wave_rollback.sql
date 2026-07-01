BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('persistent specimen', 'reassembling skeleton', 'tunnel rats')
   OR normalized_name LIKE 'persistent specimen // %'
   OR normalized_name LIKE 'reassembling skeleton // %'
   OR normalized_name LIKE 'tunnel rats // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg333_xmage_graveyard_self_return_battlefield_wave_xmage;

COMMIT;
