BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('deputy of acquittals', 'exosuit savior', 'jeskai barricade', 'mischievous pup', 'rimekin recluse', 'stickytongue sentinel')
   OR normalized_name LIKE 'deputy of acquittals // %'
   OR normalized_name LIKE 'exosuit savior // %'
   OR normalized_name LIKE 'jeskai barricade // %'
   OR normalized_name LIKE 'mischievous pup // %'
   OR normalized_name LIKE 'rimekin recluse // %'
   OR normalized_name LIKE 'stickytongue sentinel // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg491_self_etb_bounce_new_server_20260705_075431;

COMMIT;
