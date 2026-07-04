BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('covert operative', 'jhessian infiltrator', 'latch seeker', 'metathran soldier', 'mist-cloaked herald', 'phantom ninja', 'phantom warrior', 'slither blade', 'talas warrior', 'tidal kraken', 'triton shorestalker')
   OR normalized_name LIKE 'covert operative // %'
   OR normalized_name LIKE 'jhessian infiltrator // %'
   OR normalized_name LIKE 'latch seeker // %'
   OR normalized_name LIKE 'metathran soldier // %'
   OR normalized_name LIKE 'mist-cloaked herald // %'
   OR normalized_name LIKE 'phantom ninja // %'
   OR normalized_name LIKE 'phantom warrior // %'
   OR normalized_name LIKE 'slither blade // %'
   OR normalized_name LIKE 'talas warrior // %'
   OR normalized_name LIKE 'tidal kraken // %'
   OR normalized_name LIKE 'triton shorestalker // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg419_xmage_static_cant_be_blocked_new_server_20260704_1;

COMMIT;
