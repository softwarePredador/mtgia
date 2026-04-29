-- ========================================
-- ÍNDICES DE PERFORMANCE - MTG Deck Builder
-- ========================================
-- 
-- Este arquivo contém índices para otimizar as queries mais frequentes
-- do sistema. Execute após a criação inicial do schema.
--
-- Como aplicar:
--   psql -U postgres -d mtgdb -f database_indexes.sql
--
-- ========================================

-- ========================================
-- 1. Índices para Decks
-- ========================================

-- Performance para listagem de decks do usuário
-- Query: SELECT * FROM decks WHERE user_id = 'uuid' AND deleted_at IS NULL
CREATE INDEX IF NOT EXISTS idx_decks_user_id 
  ON decks(user_id) 
  WHERE deleted_at IS NULL;

-- Performance para busca de decks por formato
-- Query: SELECT * FROM decks WHERE format = 'commander'
CREATE INDEX IF NOT EXISTS idx_decks_format 
  ON decks(format);

-- ========================================
-- 2. Índices para Deck Cards
-- ========================================

-- Performance para buscar cartas de um deck
-- Query: SELECT * FROM deck_cards WHERE deck_id = 'uuid'
CREATE INDEX IF NOT EXISTS idx_deck_cards_deck_id 
  ON deck_cards(deck_id);

-- Performance para buscar decks que contém uma carta específica
-- Query: SELECT deck_id FROM deck_cards WHERE card_id = 'uuid'
CREATE INDEX IF NOT EXISTS idx_deck_cards_card_id 
  ON deck_cards(card_id);

-- Índice composto para queries de validação
-- Query: SELECT * FROM deck_cards WHERE deck_id = 'uuid' AND card_id = 'uuid'
CREATE INDEX IF NOT EXISTS idx_deck_cards_composite 
  ON deck_cards(deck_id, card_id);

-- ========================================
-- 3. Índices para Card Legalities
-- ========================================

-- Performance para validação de legalidade
-- Query: SELECT status FROM card_legalities WHERE card_id = 'uuid' AND format = 'commander'
CREATE INDEX IF NOT EXISTS idx_card_legalities_lookup 
  ON card_legalities(card_id, format);

-- Índice para buscar todas as cartas banidas de um formato
-- Query: SELECT card_id FROM card_legalities WHERE format = 'commander' AND status = 'banned'
CREATE INDEX IF NOT EXISTS idx_card_legalities_format_status 
  ON card_legalities(format, status);

-- ========================================
-- 4. Índices para Cards (Busca Textual)
-- ========================================

-- Habilitar extensão Trigram para busca fuzzy
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Índice trigram para busca eficiente de nomes de cartas
-- Query: SELECT * FROM cards WHERE name ILIKE '%sol%'
-- Nota: Este índice permite busca com LIKE/ILIKE mesmo com wildcard no início
CREATE INDEX IF NOT EXISTS idx_cards_name_trgm 
  ON cards USING gin (name gin_trgm_ops);

-- Índice para busca case-insensitive exata
-- Query: SELECT * FROM cards WHERE LOWER(name) = 'sol ring'
CREATE INDEX IF NOT EXISTS idx_cards_lower_name 
  ON cards(LOWER(name));

-- Índice para busca por cor
-- Query: SELECT * FROM cards WHERE 'R' = ANY(colors)
CREATE INDEX IF NOT EXISTS idx_cards_colors 
  ON cards USING gin (colors);

-- Índice para busca por tipo
-- Query: SELECT * FROM cards WHERE type_line ILIKE '%creature%'
CREATE INDEX IF NOT EXISTS idx_cards_type_line_trgm 
  ON cards USING gin (type_line gin_trgm_ops);

-- ========================================
-- 5. Índices para Users
-- ========================================

-- Índice único para email (já deve existir via UNIQUE constraint)
-- mas adiciona índice explícito para performance em login
CREATE INDEX IF NOT EXISTS idx_users_email 
  ON users(email);

-- Índice para username (login alternativo)
CREATE INDEX IF NOT EXISTS idx_users_username 
  ON users(username);

-- ========================================
-- 6. Índices para Meta Decks (IA)
-- ========================================

-- Performance para buscar decks meta por formato
CREATE INDEX IF NOT EXISTS idx_meta_decks_format 
  ON meta_decks(format) 
  WHERE deck_list IS NOT NULL;

-- Índice para busca textual no nome do deck meta
CREATE INDEX IF NOT EXISTS idx_meta_decks_name_trgm 
  ON meta_decks USING gin (deck_name gin_trgm_ops);

-- ========================================
-- 7. Índices para Battle Simulations (Machine Learning)
-- ========================================

-- Performance para buscar simulações de um deck específico
CREATE INDEX IF NOT EXISTS idx_battle_simulations_deck_a 
  ON battle_simulations(deck_a_id);

CREATE INDEX IF NOT EXISTS idx_battle_simulations_deck_b 
  ON battle_simulations(deck_b_id);

-- Índice para análise de winrate
CREATE INDEX IF NOT EXISTS idx_battle_simulations_winner 
  ON battle_simulations(winner_deck_id);

-- ========================================
-- 8. Índices para Market Movers
-- ========================================

-- Performance para GET /market/movers.
-- Query: leituras por price_date + join por card_id + preço para cálculo de variação.
CREATE INDEX IF NOT EXISTS idx_price_history_date_card_price
  ON price_history(price_date DESC, card_id)
  INCLUDE (price_usd);

-- ========================================
-- 9. Índices para Binder / Marketplace / Trades / Mensagens
-- ========================================

CREATE INDEX IF NOT EXISTS idx_trade_offers_sender_updated
  ON trade_offers(sender_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_trade_offers_receiver_updated
  ON trade_offers(receiver_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_trade_offers_sender_status_updated
  ON trade_offers(sender_id, status, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_trade_offers_receiver_status_updated
  ON trade_offers(receiver_id, status, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_trade_items_offer_direction
  ON trade_items(trade_offer_id, direction);

CREATE INDEX IF NOT EXISTS idx_trade_messages_offer_created
  ON trade_messages(trade_offer_id, created_at);

CREATE INDEX IF NOT EXISTS idx_trade_history_offer_created
  ON trade_status_history(trade_offer_id, created_at);

CREATE INDEX IF NOT EXISTS idx_binder_marketplace_available_created
  ON user_binder_items(created_at DESC)
  WHERE for_trade = TRUE OR for_sale = TRUE;

CREATE INDEX IF NOT EXISTS idx_binder_user_list_name_filters
  ON user_binder_items(user_id, list_type, condition, for_trade, for_sale);

CREATE INDEX IF NOT EXISTS idx_notifications_user_created
  ON notifications(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_notifications_user_unread_created
  ON notifications(user_id, created_at DESC)
  WHERE read_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_direct_messages_conversation_created
  ON direct_messages(conversation_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_direct_messages_unread_by_conversation
  ON direct_messages(conversation_id, sender_id)
  WHERE read_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_conversations_user_a_last
  ON conversations(user_a_id, last_message_at DESC, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_conversations_user_b_last
  ON conversations(user_b_id, last_message_at DESC, created_at DESC);

-- ========================================
-- 10. Verificar Índices Criados
-- ========================================

-- Para verificar se os índices foram criados corretamente:
-- SELECT schemaname, tablename, indexname FROM pg_indexes WHERE schemaname = 'public' ORDER BY tablename, indexname;

-- ========================================
-- 11. Estatísticas e Manutenção
-- ========================================

-- Atualizar estatísticas do PostgreSQL para melhor performance
ANALYZE decks;
ANALYZE deck_cards;
ANALYZE cards;
ANALYZE card_legalities;
ANALYZE users;
ANALYZE meta_decks;
ANALYZE battle_simulations;
ANALYZE price_history;
ANALYZE trade_offers;
ANALYZE trade_items;
ANALYZE trade_messages;
ANALYZE trade_status_history;
ANALYZE user_binder_items;
ANALYZE notifications;
ANALYZE conversations;
ANALYZE direct_messages;

-- ========================================
-- FIM DOS ÍNDICES
-- ========================================

-- Nota de Performance:
-- - Índices GIN (Generalized Inverted Index) são ideais para arrays e busca textual
-- - Índices Trigram (pg_trgm) permitem busca fuzzy eficiente
-- - Índices compostos (múltiplas colunas) otimizam queries com múltiplos filtros
-- - WHERE clauses em índices (partial indexes) economizam espaço e melhoram performance

-- Monitoramento:
-- Para verificar uso de índices:
--   SELECT * FROM pg_stat_user_indexes WHERE schemaname = 'public';
--
-- Para identificar queries lentas:
--   SELECT * FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 10;
