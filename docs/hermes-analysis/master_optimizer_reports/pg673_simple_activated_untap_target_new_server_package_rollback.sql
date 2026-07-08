BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('arbor elf', 'argothian elder', 'blossom dryad', 'filigree sages', 'fyndhorn brownie', 'greenside watcher', 'jandor''s saddlebags', 'juniper order druid', 'kiora''s follower', 'ley druid', 'magewright''s stone', 'rime tender', 'sculptor of winter', 'seeker of skybreak', 'voltaic construct', 'voyaging satyr')
   OR normalized_name LIKE 'arbor elf // %'
   OR normalized_name LIKE 'argothian elder // %'
   OR normalized_name LIKE 'blossom dryad // %'
   OR normalized_name LIKE 'filigree sages // %'
   OR normalized_name LIKE 'fyndhorn brownie // %'
   OR normalized_name LIKE 'greenside watcher // %'
   OR normalized_name LIKE 'jandor''s saddlebags // %'
   OR normalized_name LIKE 'juniper order druid // %'
   OR normalized_name LIKE 'kiora''s follower // %'
   OR normalized_name LIKE 'ley druid // %'
   OR normalized_name LIKE 'magewright''s stone // %'
   OR normalized_name LIKE 'rime tender // %'
   OR normalized_name LIKE 'sculptor of winter // %'
   OR normalized_name LIKE 'seeker of skybreak // %'
   OR normalized_name LIKE 'voltaic construct // %'
   OR normalized_name LIKE 'voyaging satyr // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg673_simple_activated_untap_target_new_20260708_212158;

COMMIT;
