BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('deeproot waters', 'efficient construction', 'etherium spinner', 'hero of precinct one', 'lys alana huntmaster', 'murmuring mystic', 'sigil of the empty throne', 'talrand, sky summoner', 'third path iconoclast', 'worthy knight')
   OR normalized_name LIKE 'deeproot waters // %'
   OR normalized_name LIKE 'efficient construction // %'
   OR normalized_name LIKE 'etherium spinner // %'
   OR normalized_name LIKE 'hero of precinct one // %'
   OR normalized_name LIKE 'lys alana huntmaster // %'
   OR normalized_name LIKE 'murmuring mystic // %'
   OR normalized_name LIKE 'sigil of the empty throne // %'
   OR normalized_name LIKE 'talrand, sky summoner // %'
   OR normalized_name LIKE 'third path iconoclast // %'
   OR normalized_name LIKE 'worthy knight // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg710_spell_cast_token_maker_new_server_20260710_165748;

COMMIT;
