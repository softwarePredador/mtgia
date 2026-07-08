BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('abyssal horror', 'black cat', 'blazing specter', 'brutal nightstalker', 'corrupt court official', 'deadbridge shaman', 'ebon dragon', 'ravenous rats', 'rottenheart ghoul', 'sanity gnawers')
   OR normalized_name LIKE 'abyssal horror // %'
   OR normalized_name LIKE 'black cat // %'
   OR normalized_name LIKE 'blazing specter // %'
   OR normalized_name LIKE 'brutal nightstalker // %'
   OR normalized_name LIKE 'corrupt court official // %'
   OR normalized_name LIKE 'deadbridge shaman // %'
   OR normalized_name LIKE 'ebon dragon // %'
   OR normalized_name LIKE 'ravenous rats // %'
   OR normalized_name LIKE 'rottenheart ghoul // %'
   OR normalized_name LIKE 'sanity gnawers // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg657_target_player_discard_triggers_new_20260708_132140;

COMMIT;
