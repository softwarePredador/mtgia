BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('akki rockspeaker', 'burning-tree emissary', 'priest of gix', 'priest of urabrask')
   OR normalized_name LIKE 'akki rockspeaker // %'
   OR normalized_name LIKE 'burning-tree emissary // %'
   OR normalized_name LIKE 'priest of gix // %'
   OR normalized_name LIKE 'priest of urabrask // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg503_xmage_creature_etb_fixed_mana_new_20260705_114030;

COMMIT;
