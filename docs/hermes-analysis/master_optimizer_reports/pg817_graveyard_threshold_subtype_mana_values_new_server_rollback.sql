BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('first-time flyer', 'syndicate infiltrator')
   OR normalized_name LIKE 'first-time flyer // %'
   OR normalized_name LIKE 'syndicate infiltrator // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg817_graveyard_threshold_subtype_mana_v_20260712_080836;

COMMIT;
