BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('acid rain', 'anarchy', 'boil', 'boiling seas', 'citywide bust', 'flashfires', 'gale force', 'guan yu''s 1,000-li march', 'marrow shards', 'mass calcify', 'nature''s ruin', 'perish', 'plague wind', 'planar cleansing', 'rain of blades', 'retribution of the meek', 'ritual of soot', 'ruination', 'sandstorm', 'shatterstorm', 'soulscour', 'squall', 'their name is death', 'tsunami', 'virtue''s ruin', 'whipflare')
   OR normalized_name LIKE 'acid rain // %'
   OR normalized_name LIKE 'anarchy // %'
   OR normalized_name LIKE 'boil // %'
   OR normalized_name LIKE 'boiling seas // %'
   OR normalized_name LIKE 'citywide bust // %'
   OR normalized_name LIKE 'flashfires // %'
   OR normalized_name LIKE 'gale force // %'
   OR normalized_name LIKE 'guan yu''s 1,000-li march // %'
   OR normalized_name LIKE 'marrow shards // %'
   OR normalized_name LIKE 'mass calcify // %'
   OR normalized_name LIKE 'nature''s ruin // %'
   OR normalized_name LIKE 'perish // %'
   OR normalized_name LIKE 'plague wind // %'
   OR normalized_name LIKE 'planar cleansing // %'
   OR normalized_name LIKE 'rain of blades // %'
   OR normalized_name LIKE 'retribution of the meek // %'
   OR normalized_name LIKE 'ritual of soot // %'
   OR normalized_name LIKE 'ruination // %'
   OR normalized_name LIKE 'sandstorm // %'
   OR normalized_name LIKE 'shatterstorm // %'
   OR normalized_name LIKE 'soulscour // %'
   OR normalized_name LIKE 'squall // %'
   OR normalized_name LIKE 'their name is death // %'
   OR normalized_name LIKE 'tsunami // %'
   OR normalized_name LIKE 'virtue''s ruin // %'
   OR normalized_name LIKE 'whipflare // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg484_board_wipe_extended_new_server_20260705_053136;

COMMIT;
