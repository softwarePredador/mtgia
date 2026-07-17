-- Script para criar a tabela de Cartas e Decks no PostgreSQL

-- Habilita a extensão para gerar UUIDs automaticamente
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. Tabela de Usuários
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL, -- Nunca salvar senha em texto puro!
    display_name TEXT,
    avatar_url TEXT,
    location_state TEXT,
    location_city TEXT,
    trade_notes TEXT,
    fcm_token TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- 1.1 Planos de assinatura (Free/Pro)
CREATE TABLE IF NOT EXISTS user_plans (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    plan_name TEXT NOT NULL DEFAULT 'free', -- free | pro
    status TEXT NOT NULL DEFAULT 'active', -- active | canceled
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    renews_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_user_plans_name CHECK (plan_name IN ('free', 'pro')),
    CONSTRAINT chk_user_plans_status CHECK (status IN ('active', 'canceled'))
);

CREATE INDEX IF NOT EXISTS idx_user_plans_plan_status ON user_plans (plan_name, status);

-- Para bancos existentes (idempotente)
ALTER TABLE users ADD COLUMN IF NOT EXISTS display_name TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS location_state TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS location_city TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS trade_notes TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS fcm_token TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE users ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;
CREATE INDEX IF NOT EXISTS idx_users_active_identity
    ON users (LOWER(email), LOWER(username)) WHERE deleted_at IS NULL;

-- 2. Tabela de Cartas (Otimizada para busca e dados do MTGJSON)
	CREATE TABLE IF NOT EXISTS cards (
	    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	    scryfall_id UUID UNIQUE NOT NULL, -- ID unico da printing no Scryfall
	    oracle_id UUID, -- ID Oracle/Scryfall compartilhado entre printings
	    name TEXT NOT NULL,
	    mana_cost TEXT,
	    type_line TEXT,
	    oracle_text TEXT,
	    colors TEXT[], -- Array de cores ex: {'W', 'U'}
	    color_identity TEXT[], -- Identidade de cor (Commander), ex: {'W','U'}
	    power TEXT, -- Poder impresso quando aplicavel; texto para suportar "*" e variaveis
	    toughness TEXT, -- Resistencia impressa quando aplicavel; texto para suportar "*" e variaveis
	    keywords TEXT[], -- Keywords oficiais do MTGJSON/Scryfall, ex: {'Flying','Trample'}
	    image_url TEXT, -- URL da imagem na Scryfall
	    set_code TEXT,
	    rarity TEXT,
	    layout TEXT,
	    card_faces_json JSONB,
	    ai_description TEXT, -- Cache de explicações da IA
	    price DECIMAL(10,2), -- Preço da carta (integração Scryfall)
	    price_updated_at TIMESTAMP WITH TIME ZONE,
	    collector_number TEXT, -- Número de colecionador (ex: "157")
	    foil BOOLEAN, -- true=foil, false=non-foil, null=desconhecido
	    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
	);

-- Para bancos existentes (idempotente)
ALTER TABLE cards ADD COLUMN IF NOT EXISTS ai_description TEXT;
ALTER TABLE cards ADD COLUMN IF NOT EXISTS price DECIMAL(10,2);
ALTER TABLE cards ADD COLUMN IF NOT EXISTS price_updated_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE cards ADD COLUMN IF NOT EXISTS collector_number TEXT;
ALTER TABLE cards ADD COLUMN IF NOT EXISTS foil BOOLEAN;
ALTER TABLE cards ADD COLUMN IF NOT EXISTS power TEXT;
ALTER TABLE cards ADD COLUMN IF NOT EXISTS toughness TEXT;
ALTER TABLE cards ADD COLUMN IF NOT EXISTS keywords TEXT[];
ALTER TABLE cards ADD COLUMN IF NOT EXISTS oracle_id UUID;
ALTER TABLE cards ADD COLUMN IF NOT EXISTS layout TEXT;
ALTER TABLE cards ADD COLUMN IF NOT EXISTS card_faces_json JSONB;

-- Índice para busca rápida por nome
CREATE INDEX IF NOT EXISTS idx_cards_name ON cards (name);
CREATE INDEX IF NOT EXISTS idx_cards_name_lower ON cards (LOWER(name));
CREATE INDEX IF NOT EXISTS idx_cards_front_name_lower
ON cards (LOWER(split_part(name, ' // ', 1)));
CREATE INDEX IF NOT EXISTS idx_cards_oracle_id ON cards (oracle_id);
CREATE INDEX IF NOT EXISTS idx_cards_layout ON cards (layout);
-- Índice GIN para buscas por identidade (Commander/Brawl)
CREATE INDEX IF NOT EXISTS idx_cards_color_identity ON cards USING GIN (color_identity);
CREATE INDEX IF NOT EXISTS idx_cards_keywords ON cards USING GIN (keywords);

-- 2.1. Tabela de Sets/Edições (para exibir nome e data da edição)
-- Fonte: MTGJSON SetList.json
CREATE TABLE IF NOT EXISTS sets (
    code TEXT PRIMARY KEY, -- Ex: 'UNH'
    name TEXT NOT NULL, -- Ex: 'Unhinged'
    release_date DATE, -- Ex: 2004-11-20
    type TEXT, -- Ex: 'expansion', 'promo'
    block TEXT, -- Ex: 'Ravnica'
    is_online_only BOOLEAN,
    is_foreign_only BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sets_name ON sets (name);

-- 3. Tabela de Legalidade/Banidas (Relacionamento 1:N com Cartas)
-- Ex: Card X -> Commander: Banned
CREATE TABLE IF NOT EXISTS card_legalities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_id UUID REFERENCES cards(id) ON DELETE CASCADE,
    format TEXT NOT NULL, -- 'commander', 'modern', 'standard'
    status TEXT NOT NULL, -- 'legal', 'banned', 'restricted'
    UNIQUE(card_id, format)
);

-- 3.1. Semantica executavel de cartas para o simulador Hermes
-- Fatos oficiais ficam em cards/card_rulings; esta tabela guarda a interpretacao
-- revisavel que o battle/optimizer consegue executar.
CREATE TABLE IF NOT EXISTS card_battle_rules (
    normalized_name TEXT NOT NULL,
    logical_rule_key TEXT NOT NULL,
    card_id UUID REFERENCES cards(id) ON DELETE SET NULL,
    card_name TEXT NOT NULL,
    effect_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    deck_role_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    source TEXT NOT NULL DEFAULT 'curated',
    confidence NUMERIC(4,3) NOT NULL DEFAULT 1.0
      CHECK (confidence >= 0 AND confidence <= 1),
    review_status TEXT NOT NULL DEFAULT 'verified',
    execution_status TEXT NOT NULL DEFAULT 'auto',
    rule_version INTEGER NOT NULL DEFAULT 1 CHECK (rule_version >= 1),
    oracle_hash TEXT,
    notes TEXT,
    reviewed_by TEXT,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_seen_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT chk_card_battle_rules_source CHECK (
      source IN ('manual', 'curated', 'generated', 'heuristic', 'imported')
    ),
    CONSTRAINT chk_card_battle_rules_review_status CHECK (
      review_status IN (
        'verified',
        'active',
        'needs_review',
        'rejected',
        'deprecated'
      )
    ),
    CONSTRAINT chk_card_battle_rules_execution_status CHECK (
      execution_status IN (
        'auto',
        'executable',
        'annotation_only',
        'review_only',
        'disabled'
      )
    ),
    PRIMARY KEY (normalized_name, logical_rule_key)
);

CREATE INDEX IF NOT EXISTS idx_card_battle_rules_normalized_name
ON card_battle_rules (normalized_name);

CREATE INDEX IF NOT EXISTS idx_card_battle_rules_card_id
ON card_battle_rules (card_id);

CREATE INDEX IF NOT EXISTS idx_card_battle_rules_source_status
ON card_battle_rules (source, review_status);

CREATE INDEX IF NOT EXISTS idx_card_battle_rules_effect
ON card_battle_rules USING GIN (effect_json);

CREATE INDEX IF NOT EXISTS idx_card_battle_rules_deck_role
ON card_battle_rules USING GIN (deck_role_json);

CREATE INDEX IF NOT EXISTS idx_card_battle_rules_name_lower
ON card_battle_rules (LOWER(card_name));

-- 4. Tabela de Regras do Jogo (Para consulta e IA)
CREATE TABLE IF NOT EXISTS rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL, -- Ex: "Combat Phase"
    description TEXT NOT NULL, -- Texto completo da regra
    category TEXT, -- Ex: "Turn Structure", "Keywords"
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Índices para busca rápida de regras
CREATE INDEX IF NOT EXISTS idx_rules_title ON rules (title);
CREATE INDEX IF NOT EXISTS idx_rules_category ON rules (category);

-- 5. Tabela de Decks
	CREATE TABLE IF NOT EXISTS decks (
	    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
	    name TEXT NOT NULL,
	    format TEXT NOT NULL,
	    description TEXT,
	    is_public BOOLEAN DEFAULT FALSE,

    -- Preferências do usuário (UX)
    archetype TEXT, -- Ex: "Goblin Tribal", "Voltron", etc.
    bracket INTEGER, -- 1..5 (Commander bracket / power level)
    
	    -- Campos de Análise da IA
	    synergy_score INTEGER DEFAULT 0, -- 0 a 100: Quão consolidado/sinérgico é o deck
	    strengths TEXT, -- Ex: "Ramp rápido, Proteção contra anulações"
	    weaknesses TEXT, -- Ex: "Vulnerável a board wipes, Falta de card draw"

	    -- Snapshot de custo (UX)
	    pricing_currency TEXT DEFAULT 'USD',
	    pricing_total NUMERIC(10,2),
	    pricing_missing_cards INTEGER DEFAULT 0,
	    pricing_updated_at TIMESTAMP WITH TIME ZONE,
	    
	    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	    deleted_at TIMESTAMP WITH TIME ZONE -- Soft delete
	);

-- Backfill/compat: adiciona colunas se o banco já existir (idempotente)
	ALTER TABLE decks ADD COLUMN IF NOT EXISTS archetype TEXT;
	ALTER TABLE decks ADD COLUMN IF NOT EXISTS bracket INTEGER;
	ALTER TABLE decks ADD COLUMN IF NOT EXISTS pricing_currency TEXT DEFAULT 'USD';
	ALTER TABLE decks ADD COLUMN IF NOT EXISTS pricing_total NUMERIC(10,2);
	ALTER TABLE decks ADD COLUMN IF NOT EXISTS pricing_missing_cards INTEGER DEFAULT 0;
	ALTER TABLE decks ADD COLUMN IF NOT EXISTS pricing_updated_at TIMESTAMP WITH TIME ZONE;

-- 6. Tabela de Itens do Deck (Relacionamento N:N entre Deck e Cartas)
CREATE TABLE IF NOT EXISTS deck_cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deck_id UUID REFERENCES decks(id) ON DELETE CASCADE,
    card_id UUID REFERENCES cards(id) ON DELETE CASCADE,
    quantity INTEGER DEFAULT 1,
    is_commander BOOLEAN DEFAULT FALSE,
    condition TEXT DEFAULT 'NM',
    UNIQUE(deck_id, card_id),
    CONSTRAINT chk_deck_cards_condition CHECK (condition IN ('NM', 'LP', 'MP', 'HP', 'DMG'))
);

-- Para bancos existentes (idempotente)
ALTER TABLE deck_cards ADD COLUMN IF NOT EXISTS condition TEXT DEFAULT 'NM';

-- 7. Tabela de Matchups (Counters e Estatísticas)
-- Armazena a vantagem estatística de um deck sobre outro
CREATE TABLE IF NOT EXISTS deck_matchups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deck_id UUID REFERENCES decks(id) ON DELETE CASCADE,
    opponent_deck_id UUID REFERENCES decks(id) ON DELETE CASCADE,
    win_rate FLOAT, -- 0.0 a 1.0 (Ex: 0.75 = 75% de vitória)
    notes TEXT, -- Observações da IA sobre o matchup
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(deck_id, opponent_deck_id)
);

-- 8. Tabela de Simulações de Batalha (Dataset para Machine Learning)
-- Cada linha é uma partida simulada que serve de treino para a IA
CREATE TABLE IF NOT EXISTS battle_simulations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deck_a_id UUID REFERENCES decks(id) ON DELETE SET NULL,
    deck_b_id UUID REFERENCES decks(id) ON DELETE SET NULL,
    simulation_type TEXT NOT NULL DEFAULT 'legacy',
    winner_deck_id UUID REFERENCES decks(id) ON DELETE SET NULL,
    turns_played INTEGER,
    game_log JSONB, -- Log completo passo-a-passo da partida (crucial para RL)
    metrics JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 9. Tabela de Decks do Meta (Crawler)
-- Armazena decks competitivos importados de sites externos (MTGTop8, MTGO)
CREATE TABLE IF NOT EXISTS meta_decks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    format TEXT NOT NULL, -- 'standard', 'commander', etc.
    archetype TEXT, -- Ex: 'Rakdos Midrange', 'Mono Red Aggro'
    commander_name TEXT, -- Derivado para EDH/cEDH sem sobrescrever archetype legado
    partner_commander_name TEXT, -- Segundo comandante quando houver partner/background
    shell_label TEXT, -- Label canonico do shell de comandante
    strategy_archetype TEXT, -- Heuristica separada do shell/rotulo bruto
    source_url TEXT UNIQUE NOT NULL, -- URL de origem para evitar duplicatas
    card_list TEXT NOT NULL, -- Lista de cartas em texto puro (formato de importação)
    placement TEXT, -- Posição no torneio (ex: '1', 'Top 8')
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE meta_decks ADD COLUMN IF NOT EXISTS commander_name TEXT;
ALTER TABLE meta_decks ADD COLUMN IF NOT EXISTS partner_commander_name TEXT;
ALTER TABLE meta_decks ADD COLUMN IF NOT EXISTS shell_label TEXT;
ALTER TABLE meta_decks ADD COLUMN IF NOT EXISTS strategy_archetype TEXT;

-- 9.1. Tabela de candidatos externos Commander (pesquisa web controlada)
-- Armazena listas pesquisadas por agentes/analistas antes de promover para meta_decks.
-- Mantem status de validacao e payload bruto da pesquisa externa.
CREATE TABLE IF NOT EXISTS external_commander_meta_candidates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_name TEXT NOT NULL,
    source_host TEXT,
    source_url TEXT UNIQUE NOT NULL,
    deck_name TEXT NOT NULL,
    commander_name TEXT,
    partner_commander_name TEXT,
    format TEXT NOT NULL DEFAULT 'commander',
    subformat TEXT, -- 'edh' | 'cedh'
    archetype TEXT,
    card_list TEXT NOT NULL,
    placement TEXT,
    color_identity TEXT[] DEFAULT '{}',
    is_commander_legal BOOLEAN,
    validation_status TEXT NOT NULL DEFAULT 'candidate',
    legal_status TEXT,
    validation_notes TEXT,
    research_payload JSONB NOT NULL DEFAULT '{}',
    imported_by TEXT NOT NULL DEFAULT 'copilot_cli_web_agent',
    promoted_to_meta_decks_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_external_commander_meta_status CHECK (
        validation_status IN ('candidate', 'staged', 'validated', 'rejected', 'promoted')
    )
);

CREATE INDEX IF NOT EXISTS idx_external_commander_meta_status
ON external_commander_meta_candidates (validation_status);

CREATE INDEX IF NOT EXISTS idx_external_commander_meta_subformat
ON external_commander_meta_candidates (subformat);

CREATE INDEX IF NOT EXISTS idx_external_commander_meta_commander
ON external_commander_meta_candidates (commander_name);

CREATE INDEX IF NOT EXISTS idx_external_commander_meta_color_identity
ON external_commander_meta_candidates USING GIN (color_identity);

-- 9.2. Decks aprendidos/promovidos por pipelines externos (Hermes/ManaLoom)
-- Fonte runtime do backend para expor listas aprendidas sem depender do Hermes.
CREATE TABLE IF NOT EXISTS commander_learned_decks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    commander_name TEXT NOT NULL,
    commander_name_normalized TEXT NOT NULL,
    deck_name TEXT NOT NULL,
    source_system TEXT NOT NULL,
    source_ref TEXT NOT NULL,
    source_url TEXT,
    archetype TEXT,
    card_list TEXT NOT NULL,
    card_count INTEGER NOT NULL,
    score NUMERIC,
    wincon_primary TEXT,
    wincon_backup TEXT,
    legal_status TEXT,
    notes TEXT,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_active BOOLEAN NOT NULL DEFAULT FALSE,
    promoted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(source_system, source_ref)
);

CREATE INDEX IF NOT EXISTS idx_commander_learned_decks_active
ON commander_learned_decks (commander_name_normalized, is_active, promoted_at DESC, updated_at DESC);

-- 9.1. Eventos de aprendizado para loop Hermes (App -> Hermes)
-- Registra decks criados/salvos no app para o Hermes consumir e aprender.
CREATE TABLE IF NOT EXISTS deck_learning_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deck_id UUID NOT NULL,
    commander_name TEXT,
    format TEXT NOT NULL,
    card_count INTEGER NOT NULL DEFAULT 0,
    source TEXT NOT NULL DEFAULT 'user_created',
    event_data JSONB DEFAULT '{}'::jsonb,
    synced_to_hermes BOOLEAN NOT NULL DEFAULT FALSE,
    synced_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_deck_learning_events_synced
ON deck_learning_events (synced_to_hermes, created_at);

-- 9.2. Contador de uso real de cartas por comandante (App usage feedback)
-- Alimentado a cada deck salvo. Usado pelo generate/reference pra priorizar
-- cartas com alta adocao real alem das fontes externas (EDHREC, etc).
CREATE TABLE IF NOT EXISTS commander_card_usage (
    commander_name_normalized TEXT NOT NULL,
    card_name_normalized TEXT NOT NULL,
    usage_count INTEGER NOT NULL DEFAULT 1,
    last_used_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (commander_name_normalized, card_name_normalized)
);

CREATE INDEX IF NOT EXISTS idx_commander_card_usage_commander
ON commander_card_usage (commander_name_normalized, usage_count DESC);

-- 10. Tabela de Staples por Formato (Sincronizada via Scryfall API)
-- Armazena as cartas mais populares de cada formato, atualizada semanalmente
-- Para evitar hardcoded staples e manter dados sempre atualizados
CREATE TABLE IF NOT EXISTS format_staples (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_name TEXT NOT NULL,              -- Nome exato da carta (ex: 'Sol Ring')
    format TEXT NOT NULL,                  -- 'commander', 'standard', 'modern', etc.
    archetype TEXT,                        -- 'aggro', 'control', 'combo', 'midrange', NULL = universal
    color_identity TEXT[],                 -- Cores da carta: {'W'}, {'U', 'B'}, etc. NULL = incolor/universal
    edhrec_rank INTEGER,                   -- Rank EDHREC (1 = mais popular)
    category TEXT,                         -- 'ramp', 'draw', 'removal', 'staple', 'finisher', etc.
    scryfall_id UUID,                      -- ID da carta no Scryfall para referência
    is_banned BOOLEAN DEFAULT FALSE,       -- Se foi banida recentemente (atualizado via sync)
    last_synced_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(card_name, format, archetype)   -- Evita duplicatas por formato/arquétipo
);

-- Índices para busca eficiente de staples
CREATE INDEX IF NOT EXISTS idx_format_staples_format ON format_staples (format);
CREATE INDEX IF NOT EXISTS idx_format_staples_archetype ON format_staples (archetype);
CREATE INDEX IF NOT EXISTS idx_format_staples_color ON format_staples USING GIN (color_identity);
CREATE INDEX IF NOT EXISTS idx_format_staples_category ON format_staples (category);
CREATE INDEX IF NOT EXISTS idx_format_staples_rank ON format_staples (edhrec_rank);

-- 11. Tabela de Histórico de Sincronização (Log de Atualizações)
-- Registra quando os dados foram sincronizados para auditoria e debugging
CREATE TABLE IF NOT EXISTS sync_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sync_type TEXT NOT NULL,               -- 'staples', 'banlist', 'meta', 'prices'
    format TEXT,                           -- Formato sincronizado (NULL = todos)
    records_updated INTEGER DEFAULT 0,     -- Quantidade de registros atualizados
    records_inserted INTEGER DEFAULT 0,    -- Quantidade de registros inseridos
    records_deleted INTEGER DEFAULT 0,     -- Quantidade de registros removidos (bans)
    status TEXT NOT NULL,                  -- 'success', 'partial', 'failed'
    error_message TEXT,                    -- Mensagem de erro se houver
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    finished_at TIMESTAMP WITH TIME ZONE
);

-- 11.1. Sync State (Checkpoint do último sync)
-- Armazena estado simples (key/value) para sincronizações incrementais.
CREATE TABLE IF NOT EXISTS sync_state (
    key TEXT PRIMARY KEY,
    value TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 11.2 Tabela de eventos do funil de ativação (Sprint 4)
CREATE TABLE IF NOT EXISTS activation_funnel_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    event_name TEXT NOT NULL,
    format TEXT,
    deck_id UUID REFERENCES decks(id) ON DELETE SET NULL,
    source TEXT,
    metadata JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_activation_funnel_user_created
ON activation_funnel_events (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activation_funnel_event_created
ON activation_funnel_events (event_name, created_at DESC);

-- 12. Tabela de Counters por Arquétipo (Hate Cards e Counter-Strategies)
-- Armazena cartas e estratégias para countar arquétipos específicos
-- Evita hardcoded hate cards e permite atualização dinâmica
CREATE TABLE IF NOT EXISTS archetype_counters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    archetype TEXT NOT NULL,               -- 'graveyard', 'artifacts', 'tokens', 'ramp', 'combo'
    counter_archetype TEXT,                -- Arquétipo que countera (opcional, para matchups)
    hate_cards TEXT[] NOT NULL,            -- Array de nomes de cartas hate
    priority INTEGER DEFAULT 1,            -- 1=essencial, 2=bom ter, 3=situacional
    format TEXT DEFAULT 'commander',       -- Formato aplicável
    color_identity TEXT[],                 -- Cores que podem usar (NULL = qualquer)
    notes TEXT,                            -- Notas explicativas (ex: "Usar contra Muldrotha")
    effectiveness_score INTEGER DEFAULT 5, -- 1-10, quão efetivo é o counter
    last_synced_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Índices para busca eficiente de counters
CREATE INDEX IF NOT EXISTS idx_archetype_counters_archetype ON archetype_counters (archetype);
CREATE INDEX IF NOT EXISTS idx_archetype_counters_format ON archetype_counters (format);
CREATE INDEX IF NOT EXISTS idx_archetype_counters_priority ON archetype_counters (priority);

-- 17. Eventos de Rate Limit Distribuído
-- Permite rate limiting compartilhado entre múltiplas instâncias do backend.
CREATE TABLE IF NOT EXISTS rate_limit_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bucket TEXT NOT NULL, -- ex: auth, ai
    identifier TEXT NOT NULL, -- IP ou identificador de cliente
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_rate_limit_bucket_identifier_created
    ON rate_limit_events (bucket, identifier, created_at DESC);

-- Dados iniciais de hate cards por arquétipo (pode ser expandido via sync)
INSERT INTO archetype_counters (archetype, hate_cards, priority, notes, effectiveness_score) VALUES
    ('graveyard', ARRAY['Rest in Peace', 'Grafdigger''s Cage', 'Soul-Guide Lantern', 'Leyline of the Void', 'Bojuka Bog', 'Tormod''s Crypt', 'Relic of Progenitus'], 1, 'Essencial contra Muldrotha, Meren, Karador', 9),
    ('artifacts', ARRAY['Collector Ouphe', 'Stony Silence', 'Null Rod', 'Vandalblast', 'Kataki, War''s Wage', 'Energy Flux'], 1, 'Essencial contra Urza, Breya, artifact storm', 8),
    ('tokens', ARRAY['Massacre Wurm', 'Rakdos Charm', 'Illness in the Ranks', 'Virulent Plague', 'Echoing Truth', 'Aetherspouts'], 2, 'Bom contra go-wide strategies', 7),
    ('ramp', ARRAY['Confiscate', 'Collector Ouphe', 'Blood Moon', 'Back to Basics', 'Stranglehold', 'Aven Mindcensor'], 2, 'Contra decks que dependem de ramp excessivo', 6),
    ('combo', ARRAY['Rule of Law', 'Deafening Silence', 'Drannith Magistrate', 'Cursed Totem', 'Linvala, Keeper of Silence', 'Torpor Orb'], 1, 'Essencial contra storm e infinite combos', 9),
    ('enchantments', ARRAY['Tranquil Grove', 'Back to Nature', 'Bane of Progress', 'Aura Shards', 'Primeval Light'], 2, 'Contra enchantress e aura-based strategies', 7),
    ('planeswalkers', ARRAY['The Immortal Sun', 'Vampire Hexmage', 'Hex Parasite', 'Pithing Needle', 'Sorcerous Spyglass'], 2, 'Contra superfriends', 7),
    ('voltron', ARRAY['Maze of Ith', 'Fog Bank', 'Ghostly Prison', 'Propaganda', 'Constant Mists', 'Spore Frog'], 2, 'Contra voltron e commander damage', 6),
    ('control', ARRAY['Cavern of Souls', 'Boseiju, Who Shelters All', 'Destiny Spinner', 'Vexing Shusher', 'Defense Grid'], 2, 'Contra counterspell-heavy decks', 7),
    ('aggro', ARRAY['Ensnaring Bridge', 'Crawlspace', 'Silent Arbiter', 'Meekstone', 'Sphere of Safety'], 2, 'Contra creature aggro', 6)
ON CONFLICT DO NOTHING;

-- 13. Tabela de Análise de Fraquezas (Weakness Reports)
-- Armazena análises de fraquezas identificadas em decks
CREATE TABLE IF NOT EXISTS deck_weakness_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deck_id UUID REFERENCES decks(id) ON DELETE CASCADE,
    weakness_type TEXT NOT NULL,           -- 'graveyard_vulnerability', 'low_removal', 'high_curve'
    severity TEXT NOT NULL,                -- 'critical', 'high', 'medium', 'low'
    description TEXT NOT NULL,             -- Descrição legível da fraqueza
    recommendations TEXT[],                -- Array de cartas/ações recomendadas
    auto_detected BOOLEAN DEFAULT TRUE,    -- Se foi detectado automaticamente
    addressed BOOLEAN DEFAULT FALSE,       -- Se já foi tratado pelo usuário
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_weakness_reports_deck ON deck_weakness_reports (deck_id);
CREATE INDEX IF NOT EXISTS idx_weakness_reports_severity ON deck_weakness_reports (severity);

-- 14. Tabela de Logs de IA (Observabilidade)
-- Armazena métricas e resumos das chamadas de IA para debugging e auditoria
CREATE TABLE IF NOT EXISTS ai_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    deck_id UUID REFERENCES decks(id) ON DELETE SET NULL,
    endpoint TEXT NOT NULL,              -- 'optimize', 'complete', 'explain', 'archetypes'
    model TEXT NOT NULL,                 -- 'gpt-4o', 'gpt-4o-mini', etc.
    prompt_summary TEXT,                 -- Resumo do prompt (sem dados sensíveis)
    input_tokens INTEGER,                -- Tokens de entrada (se disponível)
    output_tokens INTEGER,               -- Tokens de saída (se disponível)
    response_summary TEXT,               -- Resumo da resposta
    success BOOLEAN NOT NULL DEFAULT TRUE,
    error_message TEXT,                  -- Mensagem de erro (se falhou)
    latency_ms INTEGER NOT NULL,         -- Tempo total da chamada em ms
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_ai_logs_user ON ai_logs (user_id);
CREATE INDEX IF NOT EXISTS idx_ai_logs_deck ON ai_logs (deck_id);
CREATE INDEX IF NOT EXISTS idx_ai_logs_endpoint ON ai_logs (endpoint);
CREATE INDEX IF NOT EXISTS idx_ai_logs_created ON ai_logs (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_logs_success ON ai_logs (success);

-- 14.0.1 Feedback do pipeline ML/prompt de optimize
-- Recebe feedback automático de qualidade das respostas de /ai/optimize.
CREATE TABLE IF NOT EXISTS ml_prompt_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deck_id UUID REFERENCES decks(id) ON DELETE SET NULL,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    archetype TEXT NOT NULL,
    commander_name TEXT,
    cards_accepted TEXT[] NOT NULL DEFAULT '{}',
    cards_rejected TEXT[] NOT NULL DEFAULT '{}',
    effectiveness_score INTEGER,
    user_comment TEXT,
    prompt_version TEXT NOT NULL DEFAULT 'v1.1-hybrid',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_ml_prompt_feedback_effectiveness_score
        CHECK (effectiveness_score IS NULL OR (effectiveness_score >= 1 AND effectiveness_score <= 10))
);

CREATE INDEX IF NOT EXISTS idx_ml_prompt_feedback_deck_created
    ON ml_prompt_feedback (deck_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ml_prompt_feedback_user_created
    ON ml_prompt_feedback (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ml_prompt_feedback_archetype_created
    ON ml_prompt_feedback (LOWER(archetype), created_at DESC);

-- 14.1 Telemetria de fallback do /ai/optimize (persistente)
-- Registra eficácia do fallback de sugestões vazias para análise histórica.
CREATE TABLE IF NOT EXISTS ai_optimize_fallback_telemetry (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    deck_id UUID REFERENCES decks(id) ON DELETE SET NULL,
    mode TEXT NOT NULL DEFAULT 'optimize',
    recognized_format BOOLEAN NOT NULL DEFAULT FALSE,
    triggered BOOLEAN NOT NULL DEFAULT FALSE,
    applied BOOLEAN NOT NULL DEFAULT FALSE,
    no_candidate BOOLEAN NOT NULL DEFAULT FALSE,
    no_replacement BOOLEAN NOT NULL DEFAULT FALSE,
    candidate_count INTEGER NOT NULL DEFAULT 0,
    replacement_count INTEGER NOT NULL DEFAULT 0,
    pair_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_opt_fallback_created ON ai_optimize_fallback_telemetry (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_opt_fallback_user ON ai_optimize_fallback_telemetry (user_id);
CREATE INDEX IF NOT EXISTS idx_opt_fallback_deck ON ai_optimize_fallback_telemetry (deck_id);
CREATE INDEX IF NOT EXISTS idx_opt_fallback_triggered ON ai_optimize_fallback_telemetry (triggered, applied);

-- 14.1.1 Jobs assíncronos de /ai/optimize persistidos
-- Garante polling consistente mesmo após restart ou múltiplas instâncias.
CREATE TABLE IF NOT EXISTS ai_optimize_jobs (
    id TEXT PRIMARY KEY,
    deck_id UUID NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
    archetype TEXT NOT NULL,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    stage TEXT NOT NULL DEFAULT 'Iniciando...',
    stage_number INTEGER NOT NULL DEFAULT 0,
    total_stages INTEGER NOT NULL DEFAULT 6,
    result JSONB,
    error TEXT,
    quality_error JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_ai_optimize_jobs_status
        CHECK (status IN ('pending', 'processing', 'completed', 'failed'))
);

CREATE INDEX IF NOT EXISTS idx_ai_optimize_jobs_user_updated
    ON ai_optimize_jobs (user_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_ai_optimize_jobs_created
    ON ai_optimize_jobs (created_at DESC);

-- 14.2 Memória de preferências de otimização por usuário
CREATE TABLE IF NOT EXISTS ai_user_preferences (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    preferred_archetype TEXT,
    preferred_bracket INTEGER,
    keep_theme_default BOOLEAN NOT NULL DEFAULT TRUE,
    preferred_colors TEXT[] NOT NULL DEFAULT '{}',
    budget_tier TEXT NOT NULL DEFAULT 'mid',
    playstyle TEXT NOT NULL DEFAULT 'balanced',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_ai_user_preferences_archetype
    ON ai_user_preferences (preferred_archetype);

-- 14.3 Cache de /ai/optimize por assinatura de deck + prompt normalizado
CREATE TABLE IF NOT EXISTS ai_optimize_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cache_key TEXT NOT NULL UNIQUE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    deck_id UUID REFERENCES decks(id) ON DELETE SET NULL,
    deck_signature TEXT NOT NULL,
    payload JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_ai_optimize_cache_expires_at
    ON ai_optimize_cache (expires_at);

CREATE INDEX IF NOT EXISTS idx_ai_optimize_cache_user
    ON ai_optimize_cache (user_id);

CREATE INDEX IF NOT EXISTS idx_ai_optimize_cache_deck
    ON ai_optimize_cache (deck_id);

-- ============================================================
-- SOCIAL: Sistema de Follows
-- ============================================================
CREATE TABLE IF NOT EXISTS user_follows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    follower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_follow UNIQUE (follower_id, following_id),
    CONSTRAINT chk_no_self_follow CHECK (follower_id != following_id)
);

CREATE INDEX IF NOT EXISTS idx_user_follows_follower ON user_follows (follower_id);
CREATE INDEX IF NOT EXISTS idx_user_follows_following ON user_follows (following_id);

-- ============================================================
-- RETENTION: Historico pos-jogo por deck
-- ============================================================
CREATE TABLE IF NOT EXISTS post_game_notes (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    deck_id UUID NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    result TEXT NOT NULL DEFAULT '',
    table_level TEXT NOT NULL DEFAULT '',
    notes TEXT NOT NULL DEFAULT '',
    performed_well JSONB NOT NULL DEFAULT '[]'::jsonb,
    underperformed JSONB NOT NULL DEFAULT '[]'::jsonb,
    issues JSONB NOT NULL DEFAULT '[]'::jsonb,
    play_session_id TEXT,
    session_started_at TIMESTAMP WITH TIME ZONE,
    session_ended_at TIMESTAMP WITH TIME ZONE,
    deck_snapshot_hash TEXT,
    deck_version_at TIMESTAMP WITH TIME ZONE,
    revision BIGINT NOT NULL DEFAULT 1 CHECK (revision > 0),
    deleted_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_post_game_notes_session_order CHECK (
        session_started_at IS NULL
        OR session_ended_at IS NULL
        OR session_ended_at >= session_started_at
    )
);

CREATE INDEX IF NOT EXISTS idx_post_game_notes_deck_created
    ON post_game_notes (deck_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_post_game_notes_user_updated
    ON post_game_notes (user_id, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_post_game_notes_user_sync
    ON post_game_notes (user_id, updated_at, revision);
CREATE INDEX IF NOT EXISTS idx_post_game_notes_tombstones
    ON post_game_notes (user_id, deck_id, updated_at)
    WHERE deleted_at IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_post_game_notes_play_session
    ON post_game_notes (user_id, deck_id, play_session_id)
    WHERE play_session_id IS NOT NULL AND deleted_at IS NULL;

-- Watermark monotono: serializa leitura incremental e mutacoes para que um
-- commit concorrente nunca fique permanentemente antes do cursor devolvido.
CREATE TABLE IF NOT EXISTS post_game_sync_state (
    id SMALLINT PRIMARY KEY CHECK (id = 1),
    watermark TIMESTAMP WITH TIME ZONE NOT NULL
);
INSERT INTO post_game_sync_state (id, watermark)
SELECT 1, GREATEST(
    CURRENT_TIMESTAMP,
    COALESCE(MAX(updated_at), CURRENT_TIMESTAMP)
)
FROM post_game_notes
ON CONFLICT (id) DO UPDATE
SET watermark = GREATEST(
    post_game_sync_state.watermark,
    EXCLUDED.watermark
);

-- PRIVACY: recibo operacional sem identificador do titular.
CREATE TABLE IF NOT EXISTS account_deletion_receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_version TEXT NOT NULL,
    deletion_mode TEXT NOT NULL CHECK (deletion_mode IN ('anonymized')),
    retention_summary JSONB NOT NULL DEFAULT '{}'::jsonb,
    completed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_account_deletion_receipts_completed
    ON account_deletion_receipts (completed_at DESC);

-- Chave interna versionada. O UUID do deck nunca e persistido no tombstone:
-- somente HMAC-SHA256, nao correlacionavel sem esta chave restrita ao banco.
CREATE TABLE IF NOT EXISTS privacy_keyring (
    key_version SMALLINT PRIMARY KEY,
    hmac_key BYTEA NOT NULL CHECK (octet_length(hmac_key) >= 32),
    is_active BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_privacy_keyring_active
    ON privacy_keyring (is_active)
    WHERE is_active = TRUE;
INSERT INTO privacy_keyring (key_version, hmac_key, is_active)
VALUES (1, gen_random_bytes(32), FALSE)
ON CONFLICT (key_version) DO NOTHING;
UPDATE privacy_keyring
SET is_active = TRUE
WHERE key_version = (SELECT MIN(key_version) FROM privacy_keyring)
  AND NOT EXISTS (
      SELECT 1 FROM privacy_keyring WHERE is_active = TRUE
  );

CREATE TABLE IF NOT EXISTS privacy_deleted_deck_tombstones (
    key_version SMALLINT NOT NULL
        REFERENCES privacy_keyring(key_version) ON DELETE RESTRICT,
    deck_token TEXT NOT NULL CHECK (char_length(deck_token) = 64),
    deleted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (key_version, deck_token)
);
CREATE INDEX IF NOT EXISTS idx_privacy_deleted_deck_token
    ON privacy_deleted_deck_tombstones (deck_token);

-- ============================================================
-- GROWTH: Relatorios compartilhaveis
-- ============================================================
CREATE TABLE IF NOT EXISTS shared_deck_reports (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    deck_id UUID REFERENCES decks(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    payload JSONB NOT NULL,
    is_public BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_shared_deck_reports_deck_created
    ON shared_deck_reports (deck_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_shared_deck_reports_public_updated
    ON shared_deck_reports (is_public, updated_at DESC);

-- ============================================================
-- COMMUNITY: Comentarios, feedback publico e moderacao basica
-- ============================================================
CREATE TABLE IF NOT EXISTS deck_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deck_id UUID NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    body TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'visible',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_deck_comments_status CHECK (
        status IN ('visible', 'hidden', 'deleted')
    ),
    CONSTRAINT chk_deck_comments_body_length CHECK (
        char_length(body) BETWEEN 3 AND 1200
    )
);

CREATE INDEX IF NOT EXISTS idx_deck_comments_deck_created
    ON deck_comments (deck_id, created_at DESC)
    WHERE status = 'visible';
CREATE INDEX IF NOT EXISTS idx_deck_comments_user_created
    ON deck_comments (user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS content_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    target_type TEXT NOT NULL,
    target_id TEXT NOT NULL,
    reason TEXT NOT NULL,
    details TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL DEFAULT 'open',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_content_reports_target_type CHECK (
        target_type IN ('deck', 'comment', 'profile', 'binder_item')
    ),
    CONSTRAINT chk_content_reports_reason CHECK (
        reason IN ('spam', 'abuse', 'scam', 'inappropriate', 'copyright', 'other')
    ),
    CONSTRAINT chk_content_reports_status CHECK (
        status IN ('open', 'reviewing', 'resolved', 'dismissed')
    )
);

CREATE INDEX IF NOT EXISTS idx_content_reports_target_status
    ON content_reports (target_type, target_id, status, created_at DESC);

-- Serializa qualquer FK de usuario com a exclusao da conta. Uma escrita que
-- chegar antes sera limpa pela mesma transacao; uma escrita posterior falha.
CREATE OR REPLACE FUNCTION manaloom_require_active_user()
RETURNS trigger
LANGUAGE plpgsql
AS $active_user_function$
DECLARE
    referenced_user_id UUID;
BEGIN
    referenced_user_id := NULLIF(to_jsonb(NEW) ->> TG_ARGV[0], '')::UUID;
    IF referenced_user_id IS NULL THEN
        RETURN NEW;
    END IF;

    PERFORM 1
    FROM users
    WHERE id = referenced_user_id
      AND deleted_at IS NULL
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION USING
            ERRCODE = '23503',
            MESSAGE = 'inactive_user_reference';
    END IF;
    RETURN NEW;
END;
$active_user_function$;

DO $active_user_triggers$
DECLARE
    reference RECORD;
    trigger_name TEXT;
BEGIN
    FOR reference IN
        SELECT constraint_row.oid AS constraint_oid,
               namespace_row.nspname AS schema_name,
               relation_row.relname AS table_name,
               attribute_row.attname AS column_name
        FROM pg_constraint constraint_row
        JOIN pg_class relation_row
          ON relation_row.oid = constraint_row.conrelid
        JOIN pg_namespace namespace_row
          ON namespace_row.oid = relation_row.relnamespace
        JOIN pg_attribute attribute_row
          ON attribute_row.attrelid = relation_row.oid
         AND attribute_row.attnum = constraint_row.conkey[1]
        WHERE constraint_row.contype = 'f'
          AND constraint_row.confrelid = 'users'::regclass
          AND array_length(constraint_row.conkey, 1) = 1
    LOOP
        trigger_name := 'manaloom_active_user_' || reference.constraint_oid;
        EXECUTE format(
            'DROP TRIGGER IF EXISTS %I ON %I.%I',
            trigger_name,
            reference.schema_name,
            reference.table_name
        );
        EXECUTE format(
            'CREATE TRIGGER %I BEFORE INSERT OR UPDATE OF %I ON %I.%I '
            'FOR EACH ROW EXECUTE FUNCTION manaloom_require_active_user(%L)',
            trigger_name,
            reference.column_name,
            reference.schema_name,
            reference.table_name,
            reference.column_name
        );
    END LOOP;
END;
$active_user_triggers$;

CREATE OR REPLACE FUNCTION manaloom_guard_deck_learning_event()
RETURNS trigger
LANGUAGE plpgsql
AS $deck_learning_guard$
DECLARE
    owner_user_id UUID;
BEGIN
    SELECT user_id
    INTO owner_user_id
    FROM decks
    WHERE id = NEW.deck_id;

    IF owner_user_id IS NOT NULL THEN
        PERFORM 1
        FROM users
        WHERE id = owner_user_id
          AND deleted_at IS NULL
        FOR UPDATE;
        IF NOT FOUND THEN
            RAISE EXCEPTION USING
                ERRCODE = '23503',
                MESSAGE = 'inactive_deck_owner_reference';
        END IF;
    ELSIF EXISTS (
        SELECT 1
        FROM privacy_deleted_deck_tombstones tombstone
        JOIN privacy_keyring keyring
          ON keyring.key_version = tombstone.key_version
        WHERE tombstone.deck_token = encode(
            hmac(
                convert_to(NEW.deck_id::text, 'UTF8'),
                keyring.hmac_key,
                'sha256'
            ),
            'hex'
        )
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = '23503',
            MESSAGE = 'deleted_deck_learning_event_rejected';
    END IF;

    RETURN NEW;
END;
$deck_learning_guard$;

CREATE OR REPLACE FUNCTION manaloom_guard_battle_simulation()
RETURNS trigger
LANGUAGE plpgsql
AS $battle_simulation_guard$
DECLARE
    referenced_decks UUID[];
    expected_owner_count INTEGER;
    active_owner_count INTEGER;
    active_owner_id UUID;
BEGIN
    referenced_decks := ARRAY[
        NULLIF(to_jsonb(NEW) ->> 'deck_a_id', '')::UUID,
        NULLIF(to_jsonb(NEW) ->> 'deck_b_id', '')::UUID,
        NULLIF(to_jsonb(NEW) ->> 'winner_deck_id', '')::UUID
    ];

    SELECT COUNT(DISTINCT deck.user_id)::INTEGER
    INTO expected_owner_count
    FROM decks deck
    WHERE deck.id = ANY(referenced_decks);

    active_owner_count := 0;
    FOR active_owner_id IN
        SELECT user_row.id
        FROM users user_row
        WHERE user_row.id IN (
            SELECT DISTINCT deck.user_id
            FROM decks deck
            WHERE deck.id = ANY(referenced_decks)
        )
          AND user_row.deleted_at IS NULL
        ORDER BY user_row.id
        FOR UPDATE
    LOOP
        active_owner_count := active_owner_count + 1;
    END LOOP;

    IF active_owner_count <> expected_owner_count THEN
        RAISE EXCEPTION USING
            ERRCODE = '23503',
            MESSAGE = 'inactive_battle_deck_owner_reference';
    END IF;

    RETURN NEW;
END;
$battle_simulation_guard$;

DO $deck_learning_trigger$
BEGIN
    IF to_regclass('public.deck_learning_events') IS NOT NULL THEN
        DROP TRIGGER IF EXISTS manaloom_guard_deck_learning_event
        ON deck_learning_events;
        CREATE TRIGGER manaloom_guard_deck_learning_event
        BEFORE INSERT OR UPDATE OF deck_id ON deck_learning_events
        FOR EACH ROW
        EXECUTE FUNCTION manaloom_guard_deck_learning_event();
    END IF;
END;
$deck_learning_trigger$;

DO $battle_simulation_trigger$
BEGIN
    IF to_regclass('public.battle_simulations') IS NOT NULL THEN
        DROP TRIGGER IF EXISTS manaloom_guard_battle_simulation
        ON battle_simulations;
        CREATE TRIGGER manaloom_guard_battle_simulation
        BEFORE INSERT OR UPDATE OF deck_a_id, deck_b_id, winner_deck_id
        ON battle_simulations
        FOR EACH ROW
        EXECUTE FUNCTION manaloom_guard_battle_simulation();
    END IF;
END;
$battle_simulation_trigger$;
