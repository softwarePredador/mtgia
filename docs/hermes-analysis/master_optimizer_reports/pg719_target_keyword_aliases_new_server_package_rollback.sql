BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('breach', 'hooded kavu', 'shriek of dread', 'withstand death')
   OR normalized_name LIKE 'breach // %'
   OR normalized_name LIKE 'hooded kavu // %'
   OR normalized_name LIKE 'shriek of dread // %'
   OR normalized_name LIKE 'withstand death // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg719_target_keyword_aliases_new_server_20260710_201249;

COMMIT;
