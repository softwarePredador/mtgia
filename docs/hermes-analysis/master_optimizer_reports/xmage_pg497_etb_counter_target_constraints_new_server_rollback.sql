BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('aeronaut cavalry', 'basri''s acolyte', 'earth kingdom soldier', 'felidar savior', 'gavony silversmith', 'jade bearer', 'keen-eyed raven', 'pileated provisioner', 'sanguine glorifier', 'skinrender', 'sterling supplier', 'stromkirk mentor', 'timberland guide', 'vineshaper mystic')
   OR normalized_name LIKE 'aeronaut cavalry // %'
   OR normalized_name LIKE 'basri''s acolyte // %'
   OR normalized_name LIKE 'earth kingdom soldier // %'
   OR normalized_name LIKE 'felidar savior // %'
   OR normalized_name LIKE 'gavony silversmith // %'
   OR normalized_name LIKE 'jade bearer // %'
   OR normalized_name LIKE 'keen-eyed raven // %'
   OR normalized_name LIKE 'pileated provisioner // %'
   OR normalized_name LIKE 'sanguine glorifier // %'
   OR normalized_name LIKE 'skinrender // %'
   OR normalized_name LIKE 'sterling supplier // %'
   OR normalized_name LIKE 'stromkirk mentor // %'
   OR normalized_name LIKE 'timberland guide // %'
   OR normalized_name LIKE 'vineshaper mystic // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.xmage_pg497_etb_counter_target_constrain_20260705_092618;

COMMIT;
