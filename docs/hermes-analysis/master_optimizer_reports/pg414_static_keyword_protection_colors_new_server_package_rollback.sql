BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('abbey gargoyles', 'akroma, angel of wrath', 'aven smokeweaver', 'black knight', 'blood knight', 'cemetery gate', 'cerulean wyvern', 'coast watcher', 'duskrider falcon', 'freewind falcon', 'hazerider drake', 'iridescent angel', 'melesse spirit', 'mirran crusader', 'narwhal', 'nightwind glider', 'paladin en-vec', 'sabertooth nishoba', 'sea sprite', 'silver knight', 'sphinx of the steel wind', 'thermal glider', 'treetop sentinel', 'voice of duty', 'voice of grace', 'voice of law', 'voice of reason', 'voice of truth', 'wall of light', 'weatherseed faeries', 'white knight', 'windreaper falcon')
   OR normalized_name LIKE 'abbey gargoyles // %'
   OR normalized_name LIKE 'akroma, angel of wrath // %'
   OR normalized_name LIKE 'aven smokeweaver // %'
   OR normalized_name LIKE 'black knight // %'
   OR normalized_name LIKE 'blood knight // %'
   OR normalized_name LIKE 'cemetery gate // %'
   OR normalized_name LIKE 'cerulean wyvern // %'
   OR normalized_name LIKE 'coast watcher // %'
   OR normalized_name LIKE 'duskrider falcon // %'
   OR normalized_name LIKE 'freewind falcon // %'
   OR normalized_name LIKE 'hazerider drake // %'
   OR normalized_name LIKE 'iridescent angel // %'
   OR normalized_name LIKE 'melesse spirit // %'
   OR normalized_name LIKE 'mirran crusader // %'
   OR normalized_name LIKE 'narwhal // %'
   OR normalized_name LIKE 'nightwind glider // %'
   OR normalized_name LIKE 'paladin en-vec // %'
   OR normalized_name LIKE 'sabertooth nishoba // %'
   OR normalized_name LIKE 'sea sprite // %'
   OR normalized_name LIKE 'silver knight // %'
   OR normalized_name LIKE 'sphinx of the steel wind // %'
   OR normalized_name LIKE 'thermal glider // %'
   OR normalized_name LIKE 'treetop sentinel // %'
   OR normalized_name LIKE 'voice of duty // %'
   OR normalized_name LIKE 'voice of grace // %'
   OR normalized_name LIKE 'voice of law // %'
   OR normalized_name LIKE 'voice of reason // %'
   OR normalized_name LIKE 'voice of truth // %'
   OR normalized_name LIKE 'wall of light // %'
   OR normalized_name LIKE 'weatherseed faeries // %'
   OR normalized_name LIKE 'white knight // %'
   OR normalized_name LIKE 'windreaper falcon // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg414_static_keyword_protection_colors_new_server_202607;

COMMIT;
