BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('armaggon, future shark', 'final-sting faerie', 'gilt-leaf winnower', 'kraul whipcracker', 'lurking deadeye', 'nekrataal', 'ogre gatecrasher', 'stingerfling spider')
   OR normalized_name LIKE 'armaggon, future shark // %'
   OR normalized_name LIKE 'final-sting faerie // %'
   OR normalized_name LIKE 'gilt-leaf winnower // %'
   OR normalized_name LIKE 'kraul whipcracker // %'
   OR normalized_name LIKE 'lurking deadeye // %'
   OR normalized_name LIKE 'nekrataal // %'
   OR normalized_name LIKE 'ogre gatecrasher // %'
   OR normalized_name LIKE 'stingerfling spider // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg508_xmage_pg508_etb_destroy_residual_n_20260705_131908;

COMMIT;
