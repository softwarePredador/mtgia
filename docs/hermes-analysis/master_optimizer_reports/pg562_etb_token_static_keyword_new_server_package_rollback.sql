BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('armada wurm', 'aspiring aeronaut', 'attended knight', 'chimney rabble', 'crested herdcaller', 'dragoon''s wyvern', 'elturgard ranger', 'experimental aviator', 'flamekin gildweaver', 'gallant cavalry', 'guarded heir', 'howling giant', 'invasion reinforcements', 'jewel thief', 'knight of the new coalition', 'news helicopter', 'oltec cloud guard', 'pack guardian', 'preening champion', 'prideful parent', 'rapacious dragon', 'resolute reinforcements', 'searchlight companion', 'treetop freedom fighters', 'twin-silk spider', 'valorous steed', 'voice of the provinces')
   OR normalized_name LIKE 'armada wurm // %'
   OR normalized_name LIKE 'aspiring aeronaut // %'
   OR normalized_name LIKE 'attended knight // %'
   OR normalized_name LIKE 'chimney rabble // %'
   OR normalized_name LIKE 'crested herdcaller // %'
   OR normalized_name LIKE 'dragoon''s wyvern // %'
   OR normalized_name LIKE 'elturgard ranger // %'
   OR normalized_name LIKE 'experimental aviator // %'
   OR normalized_name LIKE 'flamekin gildweaver // %'
   OR normalized_name LIKE 'gallant cavalry // %'
   OR normalized_name LIKE 'guarded heir // %'
   OR normalized_name LIKE 'howling giant // %'
   OR normalized_name LIKE 'invasion reinforcements // %'
   OR normalized_name LIKE 'jewel thief // %'
   OR normalized_name LIKE 'knight of the new coalition // %'
   OR normalized_name LIKE 'news helicopter // %'
   OR normalized_name LIKE 'oltec cloud guard // %'
   OR normalized_name LIKE 'pack guardian // %'
   OR normalized_name LIKE 'preening champion // %'
   OR normalized_name LIKE 'prideful parent // %'
   OR normalized_name LIKE 'rapacious dragon // %'
   OR normalized_name LIKE 'resolute reinforcements // %'
   OR normalized_name LIKE 'searchlight companion // %'
   OR normalized_name LIKE 'treetop freedom fighters // %'
   OR normalized_name LIKE 'twin-silk spider // %'
   OR normalized_name LIKE 'valorous steed // %'
   OR normalized_name LIKE 'voice of the provinces // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg562_etb_token_static_keyword_new_serve_20260706_110958;

COMMIT;
