# Auditoria de schema — dump-20260923T005128Z contra base-fresca-das-migrations

Gerado por `server/bin/schema_audit.dart` em 2026-09-23T11:32:52.665297Z. Somente leitura: nada foi criado, alterado nem apagado; extras ficam só no relatório.

| | Base (base-fresca-das-migrations) | Alvo (dump-20260923T005128Z) |
| --- | ---: | ---: |
| banco | base | alvo |
| versao_servidor | 17.9 (Homebrew) | 17.9 (Homebrew) |
| schemas | 1 | 2 |
| tabelas | 79 | 1132 |
| views | 6 | 6 |
| colunas | 905 | 18431 |
| chaves_estrangeiras | 98 | 97 |
| indices | 291 | 425 |
| migrations | 58 | 57 |
| ultima_migration | 058 | 057 |

## Resumo das diferenças

| Categoria | Faltando | Sobrando | Divergente |
| --- | ---: | ---: | ---: |
| schemas | 0 | 1 | 0 |
| tabelas | 0 | 20 | 0 |
| views | 0 | 0 | 3 |
| colunas | 5 | 3 | 32 |
| chaves_estrangeiras | 2 | 1 | 4 |
| indices | 3 | 87 | 4 |
| ledger_schema_migrations | 1 | 0 | 0 |

Schemas só no alvo, resumidos (seus objetos não entram nas demais categorias):

- `manaloom_deploy_audit`: 1033 tabelas, 17241 colunas, 50 indices

## schemas

### sobrando (1)

- `manaloom_deploy_audit`

## tabelas

### sobrando (20)

- `public.analysis_sources`
- `public.archetype_patterns`
- `public.card_battle_rules_backup_pg780b_hash_new_server`
- `public.card_battle_rules_backup_pg814_hash_new_server`
- `public.card_deck_profiles`
- `public.card_extended`
- `public.card_rulings_legacy`
- `public.ml_learning_state`
- `public.optimization_analysis_logs`
- `public.pg252_manual_runtime_waiver_promotions_backup`
- `public.pg253_existing_focused_runtime_rule_promotions_backup`
- `public.pg254_blink_static_legacy_runtime_promotions_20260629_backup`
- `public.pg255_fast_mana_runtime_promotions_20260629_backup`
- `public.pg256_treasonous_ogre_life_payment_mana_20260629_backup`
- `public.pg257_phyrexian_censor_static_runtime_20260629_backup`
- `public.pg596b_oracle_hash_backfill_backup`
- `public.posts`
- `public.search_subjects`
- `public.synergy_packages`
- `public.theme_contextual_rules`

## views

### divergente (3)

- `public.binder_item_availability` — {"base":"VIEW:  WITH item_priority AS (\n         SELECT bi.id AS binder_item_id,\n            bi.user_id,\n            bi.card_id,\n            COALESCE(c.oracle_id, c.id) AS playable_card_id,\n            bi.quantity AS item_quantity,\n            COALESCE(sum(bi.quantity) OVER (PARTITION BY bi.user_id, (COALESCE(c.oracle_id, c.id)) ORDER BY (\n                CASE\n                    WHEN bi.for_trade OR bi.for_sale THEN 0\n                    ELSE 1\n                END), bi.updated_at, bi.id ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0::bigint)::integer AS prior_item_quantity\n           FROM user_binder_items bi\n             JOIN cards c ON c.id = bi.card_id\n          WHERE bi.list_type = 'have'::text\n        )\n SELECT item.binder_item_id,\n    item.user_id,\n    item.card_id,\n    item.playable_card_id,\n    item.item_quantity,\n    availability.owned_quantity,\n    availability.allocated_quantity,\n    availability.committed_trade_quantity,\n    availability.free_quantity,\n    availability.missing_quantity,\n    GREATEST(LEAST(item.item_quantity, availability.free_quantity - item.prior_item_quantity), 0) AS available_quantity\n   FROM item_priority item\n     JOIN collection_availability_snapshot availability ON availability.user_id = item.user_id AND availability.playable_card_id = item.playable_card_id;","alvo":"VIEW:  WITH item_priority AS (\n         SELECT bi.id AS binder_item_id,\n            bi.user_id,\n            bi.card_id,\n            COALESCE(c.oracle_id, c.id) AS playable_card_id,\n            bi.quantity AS item_quantity,\n            COALESCE(sum(bi.quantity) OVER (PARTITION BY bi.user_id, (COALESCE(c.oracle_id, c.id)) ORDER BY (\n                CASE\n                    WHEN bi.for_trade OR bi.for_sale THEN 0\n                    ELSE 1\n                END), bi.updated_at, bi.id ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0::bigint)::integer AS prior_item_quantity\n           FROM user_binder_items bi\n             JOIN cards c ON c.id = bi.card_id\n          WHERE bi.list_type::text = 'have'::text\n        )\n SELECT item.binder_item_id,\n    item.user_id,\n    item.card_id,\n    item.playable_card_id,\n    item.item_quantity,\n    availability.owned_quantity,\n    availability.allocated_quantity,\n    availability.committed_trade_quantity,\n    availability.free_quantity,\n    availability.missing_quantity,\n    GREATEST(LEAST(item.item_quantity, availability.free_quantity - item.prior_item_quantity), 0) AS available_quantity\n   FROM item_priority item\n     JOIN collection_availability_snapshot availability ON availability.user_id = item.user_id AND availability.playable_card_id = item.playable_card_id;"}
- `public.collection_availability_snapshot` — {"base":"VIEW:  WITH owned AS (\n         SELECT bi.user_id,\n            COALESCE(c.oracle_id, c.id) AS playable_card_id,\n            min(c.name) AS canonical_name,\n            COALESCE(sum(bi.quantity), 0::bigint)::integer AS owned_quantity\n           FROM user_binder_items bi\n             JOIN cards c ON c.id = bi.card_id\n          WHERE bi.list_type = 'have'::text\n          GROUP BY bi.user_id, (COALESCE(c.oracle_id, c.id))\n        ), allocated AS (\n         SELECT d.user_id,\n            COALESCE(c.oracle_id, c.id) AS playable_card_id,\n            min(c.name) AS canonical_name,\n            COALESCE(sum(dc.quantity), 0::bigint)::integer AS allocated_quantity\n           FROM decks d\n             JOIN deck_cards dc ON dc.deck_id = d.id\n             JOIN cards c ON c.id = dc.card_id\n          WHERE d.deleted_at IS NULL\n          GROUP BY d.user_id, (COALESCE(c.oracle_id, c.id))\n        ), committed AS (\n         SELECT ti.owner_id AS user_id,\n            COALESCE(c.oracle_id, c.id) AS playable_card_id,\n            min(c.name) AS canonical_name,\n            COALESCE(sum(ti.quantity), 0::bigint)::integer AS committed_trade_quantity\n           FROM trade_items ti\n             JOIN trade_offers trade ON trade.id = ti.trade_offer_id\n             JOIN user_binder_items bi ON bi.id = ti.binder_item_id\n             JOIN cards c ON c.id = bi.card_id\n          WHERE (trade.status = ANY (ARRAY['pending'::text, 'accepted'::text, 'shipped'::text, 'delivered'::text, 'disputed'::text])) AND bi.list_type = 'have'::text\n          GROUP BY ti.owner_id, (COALESCE(c.oracle_id, c.id))\n        ), wanted AS (\n         SELECT bi.user_id,\n            COALESCE(c.oracle_id, c.id) AS playable_card_id,\n            min(c.name) AS canonical_name,\n            COALESCE(sum(bi.quantity), 0::bigint)::integer AS wanted_quantity\n           FROM user_binder_items bi\n             JOIN cards c ON c.id = bi.card_id\n          WHERE bi.list_type = 'want'::text\n          GROUP BY bi.user_id, (COALESCE(c.oracle_id, c.id))\n        ), identities AS (\n         SELECT owned_1.user_id,\n            owned_1.playable_card_id\n           FROM owned owned_1\n        UNION\n         SELECT allocated_1.user_id,\n            allocated_1.playable_card_id\n           FROM allocated allocated_1\n        UNION\n         SELECT committed_1.user_id,\n            committed_1.playable_card_id\n           FROM committed committed_1\n        UNION\n         SELECT wanted_1.user_id,\n            wanted_1.playable_card_id\n           FROM wanted wanted_1\n        )\n SELECT identity.user_id,\n    identity.playable_card_id,\n    COALESCE(owned.canonical_name, allocated.canonical_name, committed.canonical_name, wanted.canonical_name) AS canonical_name,\n    COALESCE(owned.owned_quantity, 0) AS owned_quantity,\n    COALESCE(allocated.allocated_quantity, 0) AS allocated_quantity,\n    COALESCE(committed.committed_trade_quantity, 0) AS committed_trade_quantity,\n    GREATEST(COALESCE(owned.owned_quantity, 0) - COALESCE(allocated.allocated_quantity, 0) - COALESCE(committed.committed_trade_quantity, 0), 0) AS free_quantity,\n    GREATEST(COALESCE(allocated.allocated_quantity, 0) - COALESCE(owned.owned_quantity, 0), 0) AS missing_quantity,\n    COALESCE(wanted.wanted_quantity, 0) AS wanted_quantity,\n    GREATEST(COALESCE(wanted.wanted_quantity, 0) - COALESCE(owned.owned_quantity, 0), 0) AS wanted_missing_quantity\n   FROM identities identity\n     LEFT JOIN owned USING (user_id, playable_card_id)\n     LEFT JOIN allocated USING (user_id, playable_card_id)\n     LEFT JOIN committed USING (user_id, playable_card_id)\n     LEFT JOIN wanted USING (user_id, playable_card_id);","alvo":"VIEW:  WITH owned AS (\n         SELECT bi.user_id,\n            COALESCE(c.oracle_id, c.id) AS playable_card_id,\n            min(c.name) AS canonical_name,\n            COALESCE(sum(bi.quantity), 0::bigint)::integer AS owned_quantity\n           FROM user_binder_items bi\n             JOIN cards c ON c.id = bi.card_id\n          WHERE bi.list_type::text = 'have'::text\n          GROUP BY bi.user_id, (COALESCE(c.oracle_id, c.id))\n        ), allocated AS (\n         SELECT d.user_id,\n            COALESCE(c.oracle_id, c.id) AS playable_card_id,\n            min(c.name) AS canonical_name,\n            COALESCE(sum(dc.quantity), 0::bigint)::integer AS allocated_quantity\n           FROM decks d\n             JOIN deck_cards dc ON dc.deck_id = d.id\n             JOIN cards c ON c.id = dc.card_id\n          WHERE d.deleted_at IS NULL\n          GROUP BY d.user_id, (COALESCE(c.oracle_id, c.id))\n        ), committed AS (\n         SELECT ti.owner_id AS user_id,\n            COALESCE(c.oracle_id, c.id) AS playable_card_id,\n            min(c.name) AS canonical_name,\n            COALESCE(sum(ti.quantity), 0::bigint)::integer AS committed_trade_quantity\n           FROM trade_items ti\n             JOIN trade_offers trade ON trade.id = ti.trade_offer_id\n             JOIN user_binder_items bi ON bi.id = ti.binder_item_id\n             JOIN cards c ON c.id = bi.card_id\n          WHERE (trade.status = ANY (ARRAY['pending'::text, 'accepted'::text, 'shipped'::text, 'delivered'::text, 'disputed'::text])) AND bi.list_type::text = 'have'::text\n          GROUP BY ti.owner_id, (COALESCE(c.oracle_id, c.id))\n        ), wanted AS (\n         SELECT bi.user_id,\n            COALESCE(c.oracle_id, c.id) AS playable_card_id,\n            min(c.name) AS canonical_name,\n            COALESCE(sum(bi.quantity), 0::bigint)::integer AS wanted_quantity\n           FROM user_binder_items bi\n             JOIN cards c ON c.id = bi.card_id\n          WHERE bi.list_type::text = 'want'::text\n          GROUP BY bi.user_id, (COALESCE(c.oracle_id, c.id))\n        ), identities AS (\n         SELECT owned_1.user_id,\n            owned_1.playable_card_id\n           FROM owned owned_1\n        UNION\n         SELECT allocated_1.user_id,\n            allocated_1.playable_card_id\n           FROM allocated allocated_1\n        UNION\n         SELECT committed_1.user_id,\n            committed_1.playable_card_id\n           FROM committed committed_1\n        UNION\n         SELECT wanted_1.user_id,\n            wanted_1.playable_card_id\n           FROM wanted wanted_1\n        )\n SELECT identity.user_id,\n    identity.playable_card_id,\n    COALESCE(owned.canonical_name, allocated.canonical_name, committed.canonical_name, wanted.canonical_name) AS canonical_name,\n    COALESCE(owned.owned_quantity, 0) AS owned_quantity,\n    COALESCE(allocated.allocated_quantity, 0) AS allocated_quantity,\n    COALESCE(committed.committed_trade_quantity, 0) AS committed_trade_quantity,\n    GREATEST(COALESCE(owned.owned_quantity, 0) - COALESCE(allocated.allocated_quantity, 0) - COALESCE(committed.committed_trade_quantity, 0), 0) AS free_quantity,\n    GREATEST(COALESCE(allocated.allocated_quantity, 0) - COALESCE(owned.owned_quantity, 0), 0) AS missing_quantity,\n    COALESCE(wanted.wanted_quantity, 0) AS wanted_quantity,\n    GREATEST(COALESCE(wanted.wanted_quantity, 0) - COALESCE(owned.owned_quantity, 0), 0) AS wanted_missing_quantity\n   FROM identities identity\n     LEFT JOIN owned USING (user_id, playable_card_id)\n     LEFT JOIN allocated USING (user_id, playable_card_id)\n     LEFT JOIN committed USING (user_id, playable_card_id)\n     LEFT JOIN wanted USING (user_id, playable_card_id);"}
- `public.commander_learning_snapshot` — {"base":"VIEW:  WITH active_learned_decks AS (\n         SELECT commander_learned_decks.commander_name_normalized,\n            max(commander_learned_decks.commander_name) AS commander_name,\n            count(*)::integer AS active_learned_deck_count,\n            max(commander_learned_decks.score) AS best_learned_score,\n            max(commander_learned_decks.promoted_at) AS latest_promoted_at,\n            max(commander_learned_decks.updated_at) AS latest_learned_updated_at,\n            array_remove(array_agg(DISTINCT commander_learned_decks.legal_status ORDER BY commander_learned_decks.legal_status), NULL::text) AS learned_legal_statuses,\n            array_remove(array_agg(DISTINCT commander_learned_decks.archetype ORDER BY commander_learned_decks.archetype), NULL::text) AS learned_archetypes,\n            jsonb_agg(jsonb_build_object('deck_name', commander_learned_decks.deck_name, 'archetype', commander_learned_decks.archetype, 'card_count', commander_learned_decks.card_count, 'score', commander_learned_decks.score, 'legal_status', commander_learned_decks.legal_status, 'wincon_primary', commander_learned_decks.wincon_primary, 'wincon_backup', commander_learned_decks.wincon_backup, 'promoted_at', commander_learned_decks.promoted_at, 'updated_at', commander_learned_decks.updated_at) ORDER BY commander_learned_decks.score DESC NULLS LAST, commander_learned_decks.promoted_at DESC NULLS LAST, commander_learned_decks.updated_at DESC) AS active_learned_decks\n           FROM commander_learned_decks\n          WHERE commander_learned_decks.is_active = true AND commander_learned_decks.card_count = 100 AND commander_learned_decks.card_list ~~* (('%'::text || commander_learned_decks.commander_name) || '%'::text)\n          GROUP BY commander_learned_decks.commander_name_normalized\n        ), bridge_names AS (\n         SELECT DISTINCT ON (card_identity_bridge.normalized_lookup_name) card_identity_bridge.normalized_lookup_name,\n            card_identity_bridge.canonical_name\n           FROM card_identity_bridge\n          WHERE card_identity_bridge.normalized_lookup_name IS NOT NULL AND card_identity_bridge.normalized_lookup_name <> ''::text\n          ORDER BY card_identity_bridge.normalized_lookup_name, (card_identity_bridge.source = 'cards'::text) DESC, card_identity_bridge.match_priority, card_identity_bridge.canonical_name\n        ), usage_ranked AS (\n         SELECT ccu.commander_name_normalized,\n            ccu.card_name_normalized,\n            COALESCE(bn.canonical_name, ccu.card_name_normalized) AS canonical_card_name,\n            ccu.usage_count,\n            ccu.last_used_at,\n            row_number() OVER (PARTITION BY ccu.commander_name_normalized ORDER BY ccu.usage_count DESC, ccu.last_used_at DESC, ccu.card_name_normalized) AS rn\n           FROM commander_card_usage ccu\n             LEFT JOIN bridge_names bn ON bn.normalized_lookup_name = ccu.card_name_normalized\n        ), usage_summary AS (\n         SELECT usage_ranked.commander_name_normalized,\n            count(*)::integer AS usage_card_rows,\n            COALESCE(sum(usage_ranked.usage_count), 0::bigint)::integer AS total_usage_count,\n            jsonb_agg(jsonb_build_object('card_name_normalized', usage_ranked.card_name_normalized, 'canonical_card_name', usage_ranked.canonical_card_name, 'usage_count', usage_ranked.usage_count, 'last_used_at', usage_ranked.last_used_at) ORDER BY usage_ranked.usage_count DESC, usage_ranked.last_used_at DESC, usage_ranked.card_name_normalized) FILTER (WHERE usage_ranked.rn <= 50) AS top_usage_cards\n           FROM usage_ranked\n          GROUP BY usage_ranked.commander_name_normalized\n        ), synergy_ranked AS (\n         SELECT ccs.commander_name_normalized,\n            ccs.commander_name,\n            ccs.card_id,\n            ccs.card_name,\n            ccs.role,\n            ccs.score,\n            ccs.source,\n            ccs.evidence_count,\n            ccs.updated_at,\n            row_number() OVER (PARTITION BY ccs.commander_name_normalized ORDER BY ccs.score DESC, ccs.evidence_count DESC, ccs.card_name, ccs.role) AS rn\n           FROM commander_card_synergy ccs\n        ), synergy_summary AS (\n         SELECT synergy_ranked.commander_name_normalized,\n            max(synergy_ranked.commander_name) AS commander_name,\n            count(*)::integer AS synergy_rows,\n            max(synergy_ranked.score) AS best_synergy_score,\n            jsonb_agg(jsonb_build_object('card_id', synergy_ranked.card_id, 'card_name', synergy_ranked.card_name, 'role', synergy_ranked.role, 'score', synergy_ranked.score, 'source', synergy_ranked.source, 'evidence_count', synergy_ranked.evidence_count, 'updated_at', synergy_ranked.updated_at) ORDER BY synergy_ranked.score DESC, synergy_ranked.evidence_count DESC, synergy_ranked.card_name, synergy_ranked.role) FILTER (WHERE synergy_ranked.rn <= 50) AS top_synergy_cards\n           FROM synergy_ranked\n          GROUP BY synergy_ranked.commander_name_normalized\n        ), all_commanders AS (\n         SELECT active_learned_decks.commander_name_normalized\n           FROM active_learned_decks\n        UNION\n         SELECT usage_summary.commander_name_normalized\n           FROM usage_summary\n        UNION\n         SELECT synergy_summary.commander_name_normalized\n           FROM synergy_summary\n        )\n SELECT ac.commander_name_normalized,\n    COALESCE(ld.commander_name, ss.commander_name, ac.commander_name_normalized) AS commander_name,\n    COALESCE(ld.active_learned_deck_count, 0) AS active_learned_deck_count,\n    ld.best_learned_score,\n    ld.latest_promoted_at,\n    ld.latest_learned_updated_at,\n    COALESCE(ld.learned_legal_statuses, ARRAY[]::text[]) AS learned_legal_statuses,\n    COALESCE(ld.learned_archetypes, ARRAY[]::text[]) AS learned_archetypes,\n    COALESCE(ld.active_learned_decks, '[]'::jsonb) AS active_learned_decks,\n    COALESCE(us.usage_card_rows, 0) AS usage_card_rows,\n    COALESCE(us.total_usage_count, 0) AS total_usage_count,\n    COALESCE(us.top_usage_cards, '[]'::jsonb) AS top_usage_cards,\n    COALESCE(ss.synergy_rows, 0) AS synergy_rows,\n    COALESCE(ss.best_synergy_score, 0) AS best_synergy_score,\n    COALESCE(ss.top_synergy_cards, '[]'::jsonb) AS top_synergy_cards,\n    jsonb_build_object('has_active_learned_deck', COALESCE(ld.active_learned_deck_count, 0) > 0, 'has_usage', COALESCE(us.usage_card_rows, 0) > 0, 'has_synergy', COALESCE(ss.synergy_rows, 0) > 0, 'metadata_hidden', true) AS source_coverage\n   FROM all_commanders ac\n     LEFT JOIN active_learned_decks ld ON ld.commander_name_normalized = ac.commander_name_normalized\n     LEFT JOIN usage_summary us ON us.commander_name_normalized = ac.commander_name_normalized\n     LEFT JOIN synergy_summary ss ON ss.commander_name_normalized = ac.commander_name_normalized;","alvo":"VIEW:  WITH active_learned_decks AS (\n         SELECT commander_learned_decks.commander_name_normalized,\n            max(commander_learned_decks.commander_name) AS commander_name,\n            count(*)::integer AS active_learned_deck_count,\n            max(commander_learned_decks.score) AS best_learned_score,\n            max(commander_learned_decks.promoted_at) AS latest_promoted_at,\n            max(commander_learned_decks.updated_at) AS latest_learned_updated_at,\n            array_remove(array_agg(DISTINCT commander_learned_decks.legal_status ORDER BY commander_learned_decks.legal_status), NULL::text) AS learned_legal_statuses,\n            array_remove(array_agg(DISTINCT commander_learned_decks.archetype ORDER BY commander_learned_decks.archetype), NULL::text) AS learned_archetypes,\n            jsonb_agg(jsonb_build_object('deck_name', commander_learned_decks.deck_name, 'archetype', commander_learned_decks.archetype, 'card_count', commander_learned_decks.card_count, 'score', commander_learned_decks.score, 'legal_status', commander_learned_decks.legal_status, 'wincon_primary', commander_learned_decks.wincon_primary, 'wincon_backup', commander_learned_decks.wincon_backup, 'promoted_at', commander_learned_decks.promoted_at, 'updated_at', commander_learned_decks.updated_at) ORDER BY commander_learned_decks.score DESC NULLS LAST, commander_learned_decks.promoted_at DESC NULLS LAST, commander_learned_decks.updated_at DESC) AS active_learned_decks\n           FROM commander_learned_decks\n          WHERE commander_learned_decks.is_active = true\n          GROUP BY commander_learned_decks.commander_name_normalized\n        ), bridge_names AS (\n         SELECT DISTINCT ON (card_identity_bridge.normalized_lookup_name) card_identity_bridge.normalized_lookup_name,\n            card_identity_bridge.canonical_name\n           FROM card_identity_bridge\n          WHERE card_identity_bridge.normalized_lookup_name IS NOT NULL AND card_identity_bridge.normalized_lookup_name <> ''::text\n          ORDER BY card_identity_bridge.normalized_lookup_name, (card_identity_bridge.source = 'cards'::text) DESC, card_identity_bridge.match_priority, card_identity_bridge.canonical_name\n        ), usage_ranked AS (\n         SELECT ccu.commander_name_normalized,\n            ccu.card_name_normalized,\n            COALESCE(bn.canonical_name, ccu.card_name_normalized) AS canonical_card_name,\n            ccu.usage_count,\n            ccu.last_used_at,\n            row_number() OVER (PARTITION BY ccu.commander_name_normalized ORDER BY ccu.usage_count DESC, ccu.last_used_at DESC, ccu.card_name_normalized) AS rn\n           FROM commander_card_usage ccu\n             LEFT JOIN bridge_names bn ON bn.normalized_lookup_name = ccu.card_name_normalized\n        ), usage_summary AS (\n         SELECT usage_ranked.commander_name_normalized,\n            count(*)::integer AS usage_card_rows,\n            COALESCE(sum(usage_ranked.usage_count), 0::bigint)::integer AS total_usage_count,\n            jsonb_agg(jsonb_build_object('card_name_normalized', usage_ranked.card_name_normalized, 'canonical_card_name', usage_ranked.canonical_card_name, 'usage_count', usage_ranked.usage_count, 'last_used_at', usage_ranked.last_used_at) ORDER BY usage_ranked.usage_count DESC, usage_ranked.last_used_at DESC, usage_ranked.card_name_normalized) FILTER (WHERE usage_ranked.rn <= 50) AS top_usage_cards\n           FROM usage_ranked\n          GROUP BY usage_ranked.commander_name_normalized\n        ), synergy_ranked AS (\n         SELECT ccs.commander_name_normalized,\n            ccs.commander_name,\n            ccs.card_id,\n            ccs.card_name,\n            ccs.role,\n            ccs.score,\n            ccs.source,\n            ccs.evidence_count,\n            ccs.updated_at,\n            row_number() OVER (PARTITION BY ccs.commander_name_normalized ORDER BY ccs.score DESC, ccs.evidence_count DESC, ccs.card_name, ccs.role) AS rn\n           FROM commander_card_synergy ccs\n        ), synergy_summary AS (\n         SELECT synergy_ranked.commander_name_normalized,\n            max(synergy_ranked.commander_name) AS commander_name,\n            count(*)::integer AS synergy_rows,\n            max(synergy_ranked.score) AS best_synergy_score,\n            jsonb_agg(jsonb_build_object('card_id', synergy_ranked.card_id, 'card_name', synergy_ranked.card_name, 'role', synergy_ranked.role, 'score', synergy_ranked.score, 'source', synergy_ranked.source, 'evidence_count', synergy_ranked.evidence_count, 'updated_at', synergy_ranked.updated_at) ORDER BY synergy_ranked.score DESC, synergy_ranked.evidence_count DESC, synergy_ranked.card_name, synergy_ranked.role) FILTER (WHERE synergy_ranked.rn <= 50) AS top_synergy_cards\n           FROM synergy_ranked\n          GROUP BY synergy_ranked.commander_name_normalized\n        ), all_commanders AS (\n         SELECT active_learned_decks.commander_name_normalized\n           FROM active_learned_decks\n        UNION\n         SELECT usage_summary.commander_name_normalized\n           FROM usage_summary\n        UNION\n         SELECT synergy_summary.commander_name_normalized\n           FROM synergy_summary\n        )\n SELECT ac.commander_name_normalized,\n    COALESCE(ld.commander_name, ss.commander_name, ac.commander_name_normalized) AS commander_name,\n    COALESCE(ld.active_learned_deck_count, 0) AS active_learned_deck_count,\n    ld.best_learned_score,\n    ld.latest_promoted_at,\n    ld.latest_learned_updated_at,\n    COALESCE(ld.learned_legal_statuses, ARRAY[]::text[]) AS learned_legal_statuses,\n    COALESCE(ld.learned_archetypes, ARRAY[]::text[]) AS learned_archetypes,\n    COALESCE(ld.active_learned_decks, '[]'::jsonb) AS active_learned_decks,\n    COALESCE(us.usage_card_rows, 0) AS usage_card_rows,\n    COALESCE(us.total_usage_count, 0) AS total_usage_count,\n    COALESCE(us.top_usage_cards, '[]'::jsonb) AS top_usage_cards,\n    COALESCE(ss.synergy_rows, 0) AS synergy_rows,\n    COALESCE(ss.best_synergy_score, 0) AS best_synergy_score,\n    COALESCE(ss.top_synergy_cards, '[]'::jsonb) AS top_synergy_cards,\n    jsonb_build_object('has_active_learned_deck', COALESCE(ld.active_learned_deck_count, 0) > 0, 'has_usage', COALESCE(us.usage_card_rows, 0) > 0, 'has_synergy', COALESCE(ss.synergy_rows, 0) > 0, 'metadata_hidden', true) AS source_coverage\n   FROM all_commanders ac\n     LEFT JOIN active_learned_decks ld ON ld.commander_name_normalized = ac.commander_name_normalized\n     LEFT JOIN usage_summary us ON us.commander_name_normalized = ac.commander_name_normalized\n     LEFT JOIN synergy_summary ss ON ss.commander_name_normalized = ac.commander_name_normalized;"}

## colunas

### faltando (5)

- `public.card_meta_insights.created_at` — {"base":{"tipo":"timestamp with time zone","not_null":true,"default":"CURRENT_TIMESTAMP"}}
- `public.trade_items.item_snapshot` — {"base":{"tipo":"jsonb","not_null":true,"default":"'{}'::jsonb"}}
- `public.trade_items.snapshot_captured_at` — {"base":{"tipo":"timestamp with time zone","not_null":false,"default":null}}
- `public.trade_items.snapshot_schema_version` — {"base":{"tipo":"text","not_null":true,"default":"'trade_item_snapshot_v1'::text"}}
- `public.trade_items.snapshot_status` — {"base":{"tipo":"text","not_null":true,"default":"'legacy_unavailable'::text"}}

### sobrando (3)

- `public.card_meta_insights.id` — {"alvo":{"tipo":"uuid","not_null":true,"default":"gen_random_uuid()"}}
- `public.cards.edhrec_rank` — {"alvo":{"tipo":"integer","not_null":false,"default":null}}
- `public.ml_prompt_feedback.user_rating` — {"alvo":{"tipo":"integer","not_null":false,"default":null}}

### divergente (32)

- `public.battle_simulations.simulation_type` — {"default":["'legacy'::text",null]}
- `public.card_meta_insights.common_archetypes` — {"not_null":[true,false]}
- `public.card_meta_insights.common_formats` — {"not_null":[true,false]}
- `public.card_meta_insights.last_updated_at` — {"not_null":[true,false]}
- `public.card_meta_insights.meta_deck_count` — {"not_null":[true,false]}
- `public.card_meta_insights.top_pairs` — {"not_null":[true,false]}
- `public.card_meta_insights.usage_count` — {"not_null":[true,false]}
- `public.card_meta_insights.versatility_score` — {"tipo":["numeric(6,3)","double precision"],"not_null":[true,false],"default":["0","0.0"]}
- `public.commander_learned_decks.created_at` — {"not_null":[false,true],"default":["CURRENT_TIMESTAMP","now()"]}
- `public.commander_learned_decks.updated_at` — {"not_null":[false,true],"default":["CURRENT_TIMESTAMP","now()"]}
- `public.conversations.created_at` — {"not_null":[true,false]}
- `public.direct_messages.created_at` — {"not_null":[true,false]}
- `public.ml_prompt_feedback.archetype` — {"not_null":[true,false]}
- `public.ml_prompt_feedback.cards_accepted` — {"not_null":[true,false]}
- `public.ml_prompt_feedback.cards_rejected` — {"not_null":[true,false]}
- `public.ml_prompt_feedback.prompt_version` — {"not_null":[true,false],"default":["'v1.1-hybrid'::text",null]}
- `public.notifications.created_at` — {"not_null":[true,false]}
- `public.trade_messages.created_at` — {"not_null":[true,false]}
- `public.trade_offers.created_at` — {"not_null":[true,false]}
- `public.trade_offers.payment_currency` — {"not_null":[true,false]}
- `public.trade_offers.updated_at` — {"not_null":[true,false]}
- `public.trade_status_history.created_at` — {"not_null":[true,false]}
- `public.user_binder_items.created_at` — {"not_null":[true,false]}
- `public.user_binder_items.currency` — {"not_null":[true,false]}
- `public.user_binder_items.for_sale` — {"not_null":[true,false]}
- `public.user_binder_items.for_trade` — {"not_null":[true,false]}
- `public.user_binder_items.is_foil` — {"not_null":[true,false]}
- `public.user_binder_items.language` — {"not_null":[true,false]}
- `public.user_binder_items.list_type` — {"tipo":["text","character varying(4)"],"default":["'have'::text","'have'::character varying"]}
- `public.user_binder_items.updated_at` — {"not_null":[true,false]}
- `public.users.location_city` — {"tipo":["text","character varying(100)"]}
- `public.users.location_state` — {"tipo":["text","character varying(2)"]}

## chaves_estrangeiras

### faltando (2)

- `public.ml_prompt_feedback: FOREIGN KEY (deck_id) REFERENCES decks(id)` — {"base":{"nome":"ml_prompt_feedback_deck_id_fkey","definicao":"FOREIGN KEY (deck_id) REFERENCES decks(id) ON DELETE SET NULL"}}
- `public.ml_prompt_feedback: FOREIGN KEY (user_id) REFERENCES users(id)` — {"base":{"nome":"ml_prompt_feedback_user_id_fkey","definicao":"FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL"}}

### sobrando (1)

- `public.card_deck_profiles: FOREIGN KEY (deck_id) REFERENCES decks(id)` — {"alvo":{"nome":"card_deck_profiles_deck_id_fkey","definicao":"FOREIGN KEY (deck_id) REFERENCES decks(id) ON DELETE SET NULL"}}

### divergente (4)

- `public.direct_messages: FOREIGN KEY (sender_id) REFERENCES users(id)` — {"definicao":["FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE RESTRICT","FOREIGN KEY (sender_id) REFERENCES users(id)"],"nome":["direct_messages_sender_id_fkey","direct_messages_sender_id_fkey"]}
- `public.trade_items: FOREIGN KEY (owner_id) REFERENCES users(id)` — {"definicao":["FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE","FOREIGN KEY (owner_id) REFERENCES users(id)"],"nome":["trade_items_owner_id_fkey","trade_items_owner_id_fkey"]}
- `public.trade_messages: FOREIGN KEY (sender_id) REFERENCES users(id)` — {"definicao":["FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE RESTRICT","FOREIGN KEY (sender_id) REFERENCES users(id)"],"nome":["trade_messages_sender_id_fkey","trade_messages_sender_id_fkey"]}
- `public.trade_status_history: FOREIGN KEY (changed_by) REFERENCES users(id)` — {"definicao":["FOREIGN KEY (changed_by) REFERENCES users(id) ON DELETE RESTRICT","FOREIGN KEY (changed_by) REFERENCES users(id)"],"nome":["trade_status_history_changed_by_fkey","trade_status_history_changed_by_fkey"]}

## indices

### faltando (3)

- `public.idx_ml_prompt_feedback_archetype_created` — {"base":{"tabela":"public.ml_prompt_feedback","definicao":"CREATE INDEX ON public.ml_prompt_feedback USING btree (lower(archetype), created_at DESC)"}}
- `public.idx_ml_prompt_feedback_deck_created` — {"base":{"tabela":"public.ml_prompt_feedback","definicao":"CREATE INDEX ON public.ml_prompt_feedback USING btree (deck_id, created_at DESC)"}}
- `public.idx_ml_prompt_feedback_user_created` — {"base":{"tabela":"public.ml_prompt_feedback","definicao":"CREATE INDEX ON public.ml_prompt_feedback USING btree (user_id, created_at DESC)"}}

### sobrando (87)

- `public.analysis_sources_pkey` — {"alvo":{"tabela":"public.analysis_sources","definicao":"CREATE UNIQUE INDEX ON public.analysis_sources USING btree (id)"}}
- `public.analysis_sources_source_file_key` — {"alvo":{"tabela":"public.analysis_sources","definicao":"CREATE UNIQUE INDEX ON public.analysis_sources USING btree (source_file)"}}
- `public.archetype_patterns_pkey` — {"alvo":{"tabela":"public.archetype_patterns","definicao":"CREATE UNIQUE INDEX ON public.archetype_patterns USING btree (id)"}}
- `public.card_battle_rules_backup_pg780b_hash_n_source_review_status_idx` — {"alvo":{"tabela":"public.card_battle_rules_backup_pg780b_hash_new_server","definicao":"CREATE INDEX ON public.card_battle_rules_backup_pg780b_hash_new_server USING btree (source, review_status)"}}
- `public.card_battle_rules_backup_pg780b_hash_new_se_normalized_name_idx` — {"alvo":{"tabela":"public.card_battle_rules_backup_pg780b_hash_new_server","definicao":"CREATE INDEX ON public.card_battle_rules_backup_pg780b_hash_new_server USING btree (normalized_name)"}}
- `public.card_battle_rules_backup_pg780b_hash_new_ser_deck_role_json_idx` — {"alvo":{"tabela":"public.card_battle_rules_backup_pg780b_hash_new_server","definicao":"CREATE INDEX ON public.card_battle_rules_backup_pg780b_hash_new_server USING gin (deck_role_json)"}}
- `public.card_battle_rules_backup_pg780b_hash_new_server_card_id_idx` — {"alvo":{"tabela":"public.card_battle_rules_backup_pg780b_hash_new_server","definicao":"CREATE INDEX ON public.card_battle_rules_backup_pg780b_hash_new_server USING btree (card_id)"}}
- `public.card_battle_rules_backup_pg780b_hash_new_server_effect_json_idx` — {"alvo":{"tabela":"public.card_battle_rules_backup_pg780b_hash_new_server","definicao":"CREATE INDEX ON public.card_battle_rules_backup_pg780b_hash_new_server USING gin (effect_json)"}}
- `public.card_battle_rules_backup_pg780b_hash_new_server_lower_idx` — {"alvo":{"tabela":"public.card_battle_rules_backup_pg780b_hash_new_server","definicao":"CREATE INDEX ON public.card_battle_rules_backup_pg780b_hash_new_server USING btree (lower(card_name))"}}
- `public.card_battle_rules_backup_pg780b_hash_new_server_pkey` — {"alvo":{"tabela":"public.card_battle_rules_backup_pg780b_hash_new_server","definicao":"CREATE UNIQUE INDEX ON public.card_battle_rules_backup_pg780b_hash_new_server USING btree (normalized_name, logical_rule_key)"}}
- `public.card_battle_rules_backup_pg78_normalized_name_logical_rule__idx` — {"alvo":{"tabela":"public.card_battle_rules_backup_pg780b_hash_new_server","definicao":"CREATE UNIQUE INDEX ON public.card_battle_rules_backup_pg780b_hash_new_server USING btree (normalized_name, logical_rule_key)"}}
- `public.card_deck_profiles_pkey` — {"alvo":{"tabela":"public.card_deck_profiles","definicao":"CREATE UNIQUE INDEX ON public.card_deck_profiles USING btree (id)"}}
- `public.card_extended_pkey` — {"alvo":{"tabela":"public.card_extended","definicao":"CREATE UNIQUE INDEX ON public.card_extended USING btree (card_name)"}}
- `public.card_rulings_pkey1` — {"alvo":{"tabela":"public.card_rulings","definicao":"CREATE UNIQUE INDEX ON public.card_rulings USING btree (id)"}}
- `public.idx_analysis_sources_commander` — {"alvo":{"tabela":"public.analysis_sources","definicao":"CREATE INDEX ON public.analysis_sources USING btree (commander_name)"}}
- `public.idx_analysis_sources_type` — {"alvo":{"tabela":"public.analysis_sources","definicao":"CREATE INDEX ON public.analysis_sources USING btree (source_type)"}}
- `public.idx_battle_simulations_created_at` — {"alvo":{"tabela":"public.battle_simulations","definicao":"CREATE INDEX ON public.battle_simulations USING btree (created_at)"}}
- `public.idx_battle_simulations_deck_a_id` — {"alvo":{"tabela":"public.battle_simulations","definicao":"CREATE INDEX ON public.battle_simulations USING btree (deck_a_id)"}}
- `public.idx_battle_simulations_deck_b_id` — {"alvo":{"tabela":"public.battle_simulations","definicao":"CREATE INDEX ON public.battle_simulations USING btree (deck_b_id)"}}
- `public.idx_battle_simulations_winner_deck_id` — {"alvo":{"tabela":"public.battle_simulations","definicao":"CREATE INDEX ON public.battle_simulations USING btree (winner_deck_id)"}}
- `public.idx_binder_list_type` — {"alvo":{"tabela":"public.user_binder_items","definicao":"CREATE INDEX ON public.user_binder_items USING btree (user_id, list_type)"}}
- `public.idx_binder_marketplace_available_created` — {"alvo":{"tabela":"public.user_binder_items","definicao":"CREATE INDEX ON public.user_binder_items USING btree (created_at DESC) WHERE ((for_trade = true) OR (for_sale = true))"}}
- `public.idx_binder_user_list_name_filters` — {"alvo":{"tabela":"public.user_binder_items","definicao":"CREATE INDEX ON public.user_binder_items USING btree (user_id, list_type, condition, for_trade, for_sale)"}}
- `public.idx_card_battle_rules_name_rule_key` — {"alvo":{"tabela":"public.card_battle_rules","definicao":"CREATE UNIQUE INDEX ON public.card_battle_rules USING btree (normalized_name, logical_rule_key)"}}
- `public.idx_card_deck_profiles_card` — {"alvo":{"tabela":"public.card_deck_profiles","definicao":"CREATE INDEX ON public.card_deck_profiles USING btree (card_name)"}}
- `public.idx_card_deck_profiles_commander` — {"alvo":{"tabela":"public.card_deck_profiles","definicao":"CREATE INDEX ON public.card_deck_profiles USING btree (commander_name)"}}
- `public.idx_card_deck_profiles_importance` — {"alvo":{"tabela":"public.card_deck_profiles","definicao":"CREATE INDEX ON public.card_deck_profiles USING btree (importance)"}}
- `public.idx_card_legalities_card_id` — {"alvo":{"tabela":"public.card_legalities","definicao":"CREATE INDEX ON public.card_legalities USING btree (card_id)"}}
- `public.idx_card_legalities_format` — {"alvo":{"tabela":"public.card_legalities","definicao":"CREATE INDEX ON public.card_legalities USING btree (format)"}}
- `public.idx_card_legalities_status` — {"alvo":{"tabela":"public.card_legalities","definicao":"CREATE INDEX ON public.card_legalities USING btree (status)"}}
- `public.idx_card_rulings_name` — {"alvo":{"tabela":"public.card_rulings_legacy","definicao":"CREATE INDEX ON public.card_rulings_legacy USING btree (card_name)"}}
- `public.idx_cards_collector_set` — {"alvo":{"tabela":"public.cards","definicao":"CREATE INDEX ON public.cards USING btree (collector_number, set_code) WHERE (collector_number IS NOT NULL)"}}
- `public.idx_cards_colors` — {"alvo":{"tabela":"public.cards","definicao":"CREATE INDEX ON public.cards USING gin (colors)"}}
- `public.idx_cards_lower_name` — {"alvo":{"tabela":"public.cards","definicao":"CREATE INDEX ON public.cards USING btree (lower(name))"}}
- `public.idx_cards_set_code` — {"alvo":{"tabela":"public.cards","definicao":"CREATE INDEX ON public.cards USING btree (set_code)"}}
- `public.idx_conversations_user_a_last` — {"alvo":{"tabela":"public.conversations","definicao":"CREATE INDEX ON public.conversations USING btree (user_a_id, last_message_at DESC, created_at DESC)"}}
- `public.idx_conversations_user_b_last` — {"alvo":{"tabela":"public.conversations","definicao":"CREATE INDEX ON public.conversations USING btree (user_b_id, last_message_at DESC, created_at DESC)"}}
- `public.idx_deck_cards_card_id` — {"alvo":{"tabela":"public.deck_cards","definicao":"CREATE INDEX ON public.deck_cards USING btree (card_id)"}}
- `public.idx_deck_cards_is_commander` — {"alvo":{"tabela":"public.deck_cards","definicao":"CREATE INDEX ON public.deck_cards USING btree (is_commander)"}}
- `public.idx_deck_matchups_deck_id` — {"alvo":{"tabela":"public.deck_matchups","definicao":"CREATE INDEX ON public.deck_matchups USING btree (deck_id)"}}
- `public.idx_deck_matchups_opponent_deck_id` — {"alvo":{"tabela":"public.deck_matchups","definicao":"CREATE INDEX ON public.deck_matchups USING btree (opponent_deck_id)"}}
- `public.idx_deck_matchups_win_rate` — {"alvo":{"tabela":"public.deck_matchups","definicao":"CREATE INDEX ON public.deck_matchups USING btree (win_rate)"}}
- `public.idx_decks_created_at` — {"alvo":{"tabela":"public.decks","definicao":"CREATE INDEX ON public.decks USING btree (created_at)"}}
- `public.idx_decks_format` — {"alvo":{"tabela":"public.decks","definicao":"CREATE INDEX ON public.decks USING btree (format)"}}
- `public.idx_decks_is_public` — {"alvo":{"tabela":"public.decks","definicao":"CREATE INDEX ON public.decks USING btree (is_public)"}}
- `public.idx_decks_user_public` — {"alvo":{"tabela":"public.decks","definicao":"CREATE INDEX ON public.decks USING btree (user_id, is_public)"}}
- `public.idx_direct_messages_conversation_created` — {"alvo":{"tabela":"public.direct_messages","definicao":"CREATE INDEX ON public.direct_messages USING btree (conversation_id, created_at DESC)"}}
- `public.idx_direct_messages_unread_by_conversation` — {"alvo":{"tabela":"public.direct_messages","definicao":"CREATE INDEX ON public.direct_messages USING btree (conversation_id, sender_id) WHERE (read_at IS NULL)"}}
- `public.idx_meta_decks_commander_name` — {"alvo":{"tabela":"public.meta_decks","definicao":"CREATE INDEX ON public.meta_decks USING btree (commander_name) WHERE ((format = ANY (ARRAY['EDH'::text, 'cEDH'::text])) AND (commander_name IS NOT NULL))"}}
- `public.idx_meta_decks_partner_commander_name` — {"alvo":{"tabela":"public.meta_decks","definicao":"CREATE INDEX ON public.meta_decks USING btree (partner_commander_name) WHERE ((format = ANY (ARRAY['EDH'::text, 'cEDH'::text])) AND (partner_commander_name IS NOT NULL))"}}
- `public.idx_notifications_user_created` — {"alvo":{"tabela":"public.notifications","definicao":"CREATE INDEX ON public.notifications USING btree (user_id, created_at DESC)"}}
- `public.idx_notifications_user_unread_created` — {"alvo":{"tabela":"public.notifications","definicao":"CREATE INDEX ON public.notifications USING btree (user_id, created_at DESC) WHERE (read_at IS NULL)"}}
- `public.idx_oal_commander` — {"alvo":{"tabela":"public.optimization_analysis_logs","definicao":"CREATE INDEX ON public.optimization_analysis_logs USING btree (commander_name)"}}
- `public.idx_oal_effectiveness` — {"alvo":{"tabela":"public.optimization_analysis_logs","definicao":"CREATE INDEX ON public.optimization_analysis_logs USING btree (effectiveness_score)"}}
- `public.idx_oal_mode` — {"alvo":{"tabela":"public.optimization_analysis_logs","definicao":"CREATE INDEX ON public.optimization_analysis_logs USING btree (operation_mode)"}}
- `public.idx_oal_test_run` — {"alvo":{"tabela":"public.optimization_analysis_logs","definicao":"CREATE INDEX ON public.optimization_analysis_logs USING btree (test_run_id)"}}
- `public.idx_oal_timestamp` — {"alvo":{"tabela":"public.optimization_analysis_logs","definicao":"CREATE INDEX ON public.optimization_analysis_logs USING btree (test_timestamp)"}}
- `public.idx_opt_analysis_test_run` — {"alvo":{"tabela":"public.optimization_analysis_logs","definicao":"CREATE INDEX ON public.optimization_analysis_logs USING btree (test_run_id)"}}
- `public.idx_theme_rules_theme` — {"alvo":{"tabela":"public.theme_contextual_rules","definicao":"CREATE INDEX ON public.theme_contextual_rules USING btree (theme)"}}
- `public.idx_trade_history_offer_created` — {"alvo":{"tabela":"public.trade_status_history","definicao":"CREATE INDEX ON public.trade_status_history USING btree (trade_offer_id, created_at)"}}
- `public.idx_trade_items_offer_direction` — {"alvo":{"tabela":"public.trade_items","definicao":"CREATE INDEX ON public.trade_items USING btree (trade_offer_id, direction)"}}
- `public.idx_trade_messages_offer_created` — {"alvo":{"tabela":"public.trade_messages","definicao":"CREATE INDEX ON public.trade_messages USING btree (trade_offer_id, created_at)"}}
- `public.idx_trade_offers_receiver_status_updated` — {"alvo":{"tabela":"public.trade_offers","definicao":"CREATE INDEX ON public.trade_offers USING btree (receiver_id, status, updated_at DESC)"}}
- `public.idx_trade_offers_receiver_updated` — {"alvo":{"tabela":"public.trade_offers","definicao":"CREATE INDEX ON public.trade_offers USING btree (receiver_id, updated_at DESC)"}}
- `public.idx_trade_offers_sender_status_updated` — {"alvo":{"tabela":"public.trade_offers","definicao":"CREATE INDEX ON public.trade_offers USING btree (sender_id, status, updated_at DESC)"}}
- `public.idx_trade_offers_sender_updated` — {"alvo":{"tabela":"public.trade_offers","definicao":"CREATE INDEX ON public.trade_offers USING btree (sender_id, updated_at DESC)"}}
- `public.idx_users_display_name_lower` — {"alvo":{"tabela":"public.users","definicao":"CREATE INDEX ON public.users USING btree (lower(COALESCE(display_name, ''::text)))"}}
- `public.idx_users_email` — {"alvo":{"tabela":"public.users","definicao":"CREATE INDEX ON public.users USING btree (email)"}}
- `public.idx_users_username` — {"alvo":{"tabela":"public.users","definicao":"CREATE INDEX ON public.users USING btree (username)"}}
- `public.idx_users_username_lower` — {"alvo":{"tabela":"public.users","definicao":"CREATE INDEX ON public.users USING btree (lower(username))"}}
- `public.ml_learning_state_pkey` — {"alvo":{"tabela":"public.ml_learning_state","definicao":"CREATE UNIQUE INDEX ON public.ml_learning_state USING btree (id)"}}
- `public.optimization_analysis_logs_pkey` — {"alvo":{"tabela":"public.optimization_analysis_logs","definicao":"CREATE UNIQUE INDEX ON public.optimization_analysis_logs USING btree (id)"}}
- `public.pg596b_oracle_hash_backfill_backup_pkey` — {"alvo":{"tabela":"public.pg596b_oracle_hash_backfill_backup","definicao":"CREATE UNIQUE INDEX ON public.pg596b_oracle_hash_backfill_backup USING btree (card_id, logical_rule_key)"}}
- `public.posts_original_url_key` — {"alvo":{"tabela":"public.posts","definicao":"CREATE UNIQUE INDEX ON public.posts USING btree (original_url)"}}
- `public.posts_pkey` — {"alvo":{"tabela":"public.posts","definicao":"CREATE UNIQUE INDEX ON public.posts USING btree (id)"}}
- `public.search_subjects_pkey` — {"alvo":{"tabela":"public.search_subjects","definicao":"CREATE UNIQUE INDEX ON public.search_subjects USING btree (id)"}}
- `public.search_subjects_topic_key` — {"alvo":{"tabela":"public.search_subjects","definicao":"CREATE UNIQUE INDEX ON public.search_subjects USING btree (topic)"}}
- `public.synergy_packages_pkey` — {"alvo":{"tabela":"public.synergy_packages","definicao":"CREATE UNIQUE INDEX ON public.synergy_packages USING btree (id)"}}
- `public.theme_contextual_rules_pkey` — {"alvo":{"tabela":"public.theme_contextual_rules","definicao":"CREATE UNIQUE INDEX ON public.theme_contextual_rules USING btree (id)"}}
- `public.theme_contextual_rules_theme_function_key` — {"alvo":{"tabela":"public.theme_contextual_rules","definicao":"CREATE UNIQUE INDEX ON public.theme_contextual_rules USING btree (theme, function)"}}
- `public.unique_archetype_format` — {"alvo":{"tabela":"public.archetype_patterns","definicao":"CREATE UNIQUE INDEX ON public.archetype_patterns USING btree (archetype, format)"}}
- `public.unique_card_insight` — {"alvo":{"tabela":"public.card_meta_insights","definicao":"CREATE UNIQUE INDEX ON public.card_meta_insights USING btree (card_name)"}}
- `public.unique_model_version` — {"alvo":{"tabela":"public.ml_learning_state","definicao":"CREATE UNIQUE INDEX ON public.ml_learning_state USING btree (model_version)"}}
- `public.unique_package` — {"alvo":{"tabela":"public.synergy_packages","definicao":"CREATE UNIQUE INDEX ON public.synergy_packages USING btree (package_name)"}}
- `public.uq_binder_user_card_cond_foil_list` — {"alvo":{"tabela":"public.user_binder_items","definicao":"CREATE UNIQUE INDEX ON public.user_binder_items USING btree (user_id, card_id, condition, is_foil, list_type)"}}
- `public.uq_conversation` — {"alvo":{"tabela":"public.conversations","definicao":"CREATE UNIQUE INDEX ON public.conversations USING btree (user_a_id, user_b_id)"}}
- `public.uq_conversation_pair` — {"alvo":{"tabela":"public.conversations","definicao":"CREATE UNIQUE INDEX ON public.conversations USING btree (LEAST(user_a_id, user_b_id), GREATEST(user_a_id, user_b_id))"}}

### divergente (4)

- `public.card_meta_insights_pkey` — {"definicao":["CREATE UNIQUE INDEX ON public.card_meta_insights USING btree (card_name)","CREATE UNIQUE INDEX ON public.card_meta_insights USING btree (id)"]}
- `public.card_rulings_pkey` — {"definicao":["CREATE UNIQUE INDEX ON public.card_rulings USING btree (id)","CREATE UNIQUE INDEX ON public.card_rulings_legacy USING btree (id)"]}
- `public.idx_trade_history_offer` — {"definicao":["CREATE INDEX ON public.trade_status_history USING btree (trade_offer_id, created_at DESC)","CREATE INDEX ON public.trade_status_history USING btree (trade_offer_id)"]}
- `public.idx_trade_messages_offer` — {"definicao":["CREATE INDEX ON public.trade_messages USING btree (trade_offer_id, created_at DESC)","CREATE INDEX ON public.trade_messages USING btree (trade_offer_id)"]}

## ledger_schema_migrations

### faltando (1)

- `058` — {"base":"snapshot_trade_item_identity"}
