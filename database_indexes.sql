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
-- 8. Verificar Índices Criados
-- ========================================

-- Para verificar se os índices foram criados corretamente:
-- SELECT schemaname, tablename, indexname FROM pg_indexes WHERE schemaname = 'public' ORDER BY tablename, indexname;

-- ========================================
-- 9. Estatísticas e Manutenção
-- ========================================

-- Atualizar estatísticas do PostgreSQL para melhor performance
ANALYZE decks;
ANALYZE deck_cards;
ANALYZE cards;
ANALYZE card_legalities;
ANALYZE users;
ANALYZE meta_decks;
ANALYZE battle_simulations;

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
