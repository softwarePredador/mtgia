# ManaLoom — ERD PostgreSQL gerado

> Extraído de `server/database_setup.sql`, migrations e constantes SQL importadas pelo backend. Confirme o schema aplicado com o gate `tbls` local descartável.

```mermaid
erDiagram
    decks ||--o{ activation_funnel_events : "deck_id -> id"
    users ||--o{ activation_funnel_events : "user_id -> id"
    users ||--o{ ai_generate_jobs : "user_id -> id"
    decks ||--o{ ai_logs : "deck_id -> id"
    users ||--o{ ai_logs : "user_id -> id"
    decks ||--o{ ai_optimize_cache : "deck_id -> id"
    users ||--o{ ai_optimize_cache : "user_id -> id"
    decks ||--o{ ai_optimize_fallback_telemetry : "deck_id -> id"
    users ||--o{ ai_optimize_fallback_telemetry : "user_id -> id"
    decks ||--o{ ai_optimize_jobs : "deck_id -> id"
    users ||--o{ ai_optimize_jobs : "user_id -> id"
    users ||--o{ ai_user_preferences : "user_id -> id"
    decks ||--o{ battle_simulations : "deck_a_id -> id"
    decks ||--o{ battle_simulations : "deck_b_id -> id"
    decks ||--o{ battle_simulations : "winner_deck_id -> id"
    cards ||--o{ card_battle_rules : "card_id -> id"
    cards ||--o{ card_function_tags : "card_id -> id"
    cards ||--o{ card_legalities : "card_id -> id"
    cards ||--o{ card_localized_names : "card_id -> id"
    cards ||--o{ card_role_scores : "card_id -> id"
    cards ||--o{ card_semantic_tags_v2 : "card_id -> id"
    card_combos ||--o{ combo_cards : "combo_id -> id"
    cards ||--o{ commander_card_synergy : "card_id -> id"
    cards ||--o{ commander_reference_card_stats : "card_id -> id"
    cards ||--o{ commander_reference_deck_cards : "card_id -> id"
    commander_reference_decks ||--o{ commander_reference_deck_cards : "source_deck_key -> source_deck_key"
    users ||--o{ content_report_appeals : "appellant_user_id -> id"
    content_reports ||--o{ content_report_appeals : "report_id -> id"
    users ||--o{ content_report_appeals : "reviewed_by -> id"
    users ||--o{ content_reports : "reporter_user_id -> id"
    users ||--o{ content_reports : "reviewed_by -> id"
    users ||--o{ conversations : "user_a_id -> id"
    users ||--o{ conversations : "user_b_id -> id"
    cards ||--o{ deck_cards : "card_id -> id"
    decks ||--o{ deck_cards : "deck_id -> id"
    decks ||--o{ deck_comments : "deck_id -> id"
    users ||--o{ deck_comments : "user_id -> id"
    decks ||--o{ deck_matchups : "deck_id -> id"
    decks ||--o{ deck_matchups : "opponent_deck_id -> id"
    decks ||--o{ deck_optimization_events : "deck_id -> id"
    users ||--o{ deck_optimization_events : "user_id -> id"
    decks ||--o{ deck_weakness_reports : "deck_id -> id"
    users ||--o{ decks : "user_id -> id"
    conversations ||--o{ direct_messages : "conversation_id -> id"
    users ||--o{ direct_messages : "sender_id -> id"
    users ||--o{ email_verification_tokens : "user_id -> id"
    decks ||--o{ ml_prompt_feedback : "deck_id -> id"
    users ||--o{ ml_prompt_feedback : "user_id -> id"
    users ||--o{ moderation_actions : "moderator_user_id -> id"
    content_reports ||--o{ moderation_actions : "report_id -> id"
    users ||--o{ notifications : "user_id -> id"
    users ||--o{ password_reset_tokens : "user_id -> id"
    decks ||--o{ post_game_notes : "deck_id -> id"
    users ||--o{ post_game_notes : "user_id -> id"
    cards ||--o{ price_history : "card_id -> id"
    privacy_keyring ||--o{ privacy_deleted_deck_tombstones : "key_version -> key_version"
    decks ||--o{ shared_deck_reports : "deck_id -> id"
    users ||--o{ shared_deck_reports : "user_id -> id"
    user_binder_items ||--o{ trade_items : "binder_item_id -> id"
    users ||--o{ trade_items : "owner_id -> id"
    trade_offers ||--o{ trade_items : "trade_offer_id -> id"
    users ||--o{ trade_messages : "sender_id -> id"
    trade_offers ||--o{ trade_messages : "trade_offer_id -> id"
    users ||--o{ trade_offers : "receiver_id -> id"
    users ||--o{ trade_offers : "sender_id -> id"
    users ||--o{ trade_status_history : "changed_by -> id"
    trade_offers ||--o{ trade_status_history : "trade_offer_id -> id"
    cards ||--o{ user_binder_items : "card_id -> id"
    users ||--o{ user_binder_items : "user_id -> id"
    users ||--o{ user_block_events : "actor_user_id -> id"
    users ||--o{ user_block_events : "target_user_id -> id"
    users ||--o{ user_blocks : "blocked_id -> id"
    users ||--o{ user_blocks : "blocker_id -> id"
    users ||--o{ user_follows : "follower_id -> id"
    users ||--o{ user_follows : "following_id -> id"
    users ||--o{ user_plans : "user_id -> id"
    account_deletion_receipts {
        datetime completed_at
        string deletion_mode
        uuid id PK
        string policy_version
        json retention_summary
    }
    activation_funnel_events {
        datetime created_at
        uuid deck_id
        string event_name
        string format
        uuid id PK
        json metadata
        string source
        uuid user_id
    }
    ai_generate_jobs {
        string cache_key
        datetime cancelled_at
        datetime created_at
        string error
        string format
        string id PK
        string request_fingerprint
        string request_key
        json result
        number result_status_code
        string stage
        number stage_number
        string status
        number total_stages
        datetime updated_at
        uuid user_id
    }
    ai_logs {
        datetime created_at
        uuid deck_id
        string endpoint
        string error_message
        uuid id PK
        number input_tokens
        number latency_ms
        string model
        number output_tokens
        string prompt_summary
        string response_summary
        boolean success
        uuid user_id
    }
    ai_optimize_cache {
        string cache_key
        datetime created_at
        uuid deck_id
        string deck_signature
        datetime expires_at
        uuid id PK
        json payload
        uuid user_id
    }
    ai_optimize_fallback_telemetry {
        boolean applied
        number candidate_count
        datetime created_at
        uuid deck_id
        uuid id PK
        string mode
        boolean no_candidate
        boolean no_replacement
        number pair_count
        boolean recognized_format
        number replacement_count
        boolean triggered
        uuid user_id
    }
    ai_optimize_jobs {
        string archetype
        datetime cancelled_at
        datetime created_at
        uuid deck_id
        string error
        string id PK
        json quality_error
        string request_fingerprint
        string request_key
        json result
        string stage
        number stage_number
        string status
        number total_stages
        datetime updated_at
        uuid user_id
    }
    ai_user_preferences {
        string budget_tier
        datetime created_at
        boolean keep_theme_default
        string playstyle
        string preferred_archetype
        number preferred_bracket
        string preferred_colors
        datetime updated_at
        uuid user_id PK
    }
    archetype_counters {
        string archetype
        string color_identity
        string counter_archetype
        datetime created_at
        number effectiveness_score
        string format
        string hate_cards
        uuid id PK
        datetime last_synced_at
        string notes
        number priority
    }
    battle_simulations {
        datetime created_at
        uuid deck_a_id
        uuid deck_b_id
        json game_log
        uuid id PK
        json metrics
        string simulation_type
        number turns_played
        uuid winner_deck_id
    }
    card_battle_rules {
        uuid card_id
        string card_name
        number confidence
        datetime created_at
        json deck_role_json
        json effect_json
        string execution_status
        datetime last_seen_at
        string logical_rule_key
        string normalized_name PK
        string notes
        string oracle_hash
        string review_status
        datetime reviewed_at
        string reviewed_by
        number rule_version
        string source
        datetime updated_at
    }
    card_combos {
        number card_count
        string card_names
        string card_oracle_ids
        string color_identity
        string description
        string id PK
        string mana_needed
        string prerequisites
        string produces
        string source
        string status
        datetime updated_at
    }
    card_function_tags {
        uuid card_id
        string card_name
        number confidence
        string evidence
        string source
        string tag
        datetime updated_at
    }
    card_legalities {
        uuid card_id
        string format
        uuid id PK
        string status
    }
    card_localized_names {
        string canonical_name
        uuid card_id
        string collector_number
        string lang
        string normalized_printed_name
        uuid oracle_id
        string printed_name
        uuid scryfall_id
        string set_code
        string source
        datetime updated_at
    }
    card_meta_insights {
        string card_name PK
        string common_archetypes
        string common_formats
        datetime created_at
        datetime last_updated_at
        string learned_role
        number meta_deck_count
        json top_pairs
        number usage_count
        number versatility_score
    }
    card_role_scores {
        string bracket_scope
        string budget_tier
        uuid card_id
        string card_name
        string evidence
        string format
        string role
        number score
        string source
        string subformat
        datetime updated_at
    }
    card_rulings {
        string comment
        string comment_hash
        datetime created_at
        string id PK
        string oracle_id
        datetime published_at
        string ruling_source
        string source
    }
    card_semantic_tags_v2 {
        string card_advantage_type
        uuid card_id
        string card_name
        boolean combo_piece
        boolean enabler
        boolean engine
        string explanation_reason
        string interaction_scope
        string mana_efficiency
        boolean payoff
        string protection_type
        string recursion_type
        number role_confidence
        string schema_version
        string source
        string speed
        json tags
        datetime updated_at
        boolean wincon
    }
    cards {
        string ai_description
        json card_faces_json
        number cmc
        string collector_number
        string color_identity
        string colors
        datetime created_at
        boolean foil
        uuid id PK
        string image_url
        boolean is_reserved
        string keywords
        string layout
        string mana_cost
        string name
        uuid oracle_id
        string oracle_text
        string power
        number price
        string price_source
        datetime price_updated_at
        number price_usd
        number price_usd_foil
        string rarity
    }
    combo_cards {
        string card_name
        string combo_id
        boolean must_be_commander
        string oracle_id
    }
    commander_card_synergy {
        uuid card_id
        string card_name
        string commander_name
        string commander_name_normalized
        string evidence
        number evidence_count
        string role
        number score
        string source
        datetime updated_at
    }
    commander_card_usage {
        string card_name_normalized
        string commander_name_normalized
        datetime last_used_at
        number usage_count
    }
    commander_learned_decks {
        string archetype
        number card_count
        string card_list
        string commander_name
        string commander_name_normalized
        datetime created_at
        string deck_name
        uuid id PK
        boolean is_active
        string legal_status
        json metadata
        string notes
        datetime promoted_at
        number score
        string source_ref
        string source_system
        string source_url
        datetime updated_at
        string wincon_backup
        string wincon_primary
    }
    commander_reference_card_stats {
        uuid card_id
        string card_name
        string card_name_normalized
        string commander_name
        string commander_name_normalized
        string confidence
        number confidence_rank
        number evidence_count
        string package_key
        string role
        number score
        string source
        boolean unresolved
        datetime updated_at
    }
    commander_reference_deck_analysis {
        number accepted_deck_count
        json average_role_counts
        string commander_name
        string commander_name_normalized
        number deck_count
        string source
        json theme_counts
        json top_cards
        datetime updated_at
    }
    commander_reference_deck_cards {
        string board
        uuid card_id
        string card_name
        string card_name_normalized
        boolean off_color
        number quantity
        string role
        string source_deck_key
        boolean unresolved
        datetime updated_at
    }
    commander_reference_decks {
        boolean accepted
        string commander_name
        string commander_name_normalized
        number commander_quantity
        datetime created_at
        string deck_hash
        number main_quantity
        number off_color_count
        string power_lane
        json rejection_reasons
        number resolved_count
        json role_summary
        json singleton_violations
        string source
        string source_deck_key PK
        string source_url
        string theme
        number unresolved_count
        datetime updated_at
    }
    commander_reference_profiles {
        string commander_name PK
        number deck_count
        json profile_json
        string source
        datetime updated_at
    }
    content_report_appeals {
        uuid appellant_user_id
        datetime created_at
        uuid id PK
        string reason
        uuid report_id
        string resolution
        datetime reviewed_at
        uuid reviewed_by
        string status
    }
    content_reports {
        datetime created_at
        string details
        json evidence
        uuid id PK
        number priority
        string reason
        uuid reporter_user_id
        string resolution
        string resolution_action
        datetime reviewed_at
        uuid reviewed_by
        datetime sla_due_at
        string status
        string target_id
        string target_type
        datetime updated_at
    }
    conversations {
        datetime created_at
        uuid id PK
        datetime last_message_at
        uuid user_a_id
        uuid user_b_id
    }
    data_source_snapshots {
        datetime completed_at
        string content_sha256
        string dataset
        number distinct_identity_count
        string id PK
        datetime latest_published_at
        json metadata
        string provider
        number row_count
        string source_etag
        datetime source_updated_at
        string source_uri
        string source_version
        datetime started_at
        string status
    }
    deck_cards {
        uuid card_id
        string condition
        uuid deck_id
        uuid id PK
        boolean is_commander
        number quantity
    }
    deck_comments {
        string body
        datetime created_at
        uuid deck_id
        uuid id PK
        string status
        datetime updated_at
        uuid user_id
    }
    deck_learning_events {
        number card_count
        string commander_name
        datetime created_at
        uuid deck_id
        json event_data
        string format
        uuid id PK
        string source
        datetime synced_at
        boolean synced_to_hermes
    }
    deck_matchups {
        uuid deck_id
        uuid id PK
        string notes
        uuid opponent_deck_id
        datetime updated_at
        string win_rate
    }
    deck_optimization_events {
        json additions
        json after_snapshot
        string archetype
        string battle_message
        string battle_status
        json before_snapshot
        number bracket
        datetime created_at
        uuid deck_id
        string event_type
        uuid id PK
        string intensity
        string mode
        json recommendation_context
        json removals
        json report_payload
        number selected_change_count
        uuid user_id
        string validation_status
    }
    deck_weakness_reports {
        boolean addressed
        boolean auto_detected
        datetime created_at
        uuid deck_id
        string description
        uuid id PK
        string recommendations
        string severity
        string weakness_type
    }
    decks {
        string archetype
        number bracket
        datetime created_at
        datetime deleted_at
        string description
        string format
        uuid id PK
        boolean is_public
        string name
        string pricing_currency
        number pricing_missing_cards
        string pricing_source
        number pricing_total
        datetime pricing_updated_at
        string strengths
        number synergy_score
        uuid user_id
        json validation_reasons
        string validation_state
        datetime validation_updated_at
        string weaknesses
    }
    direct_messages {
        string client_request_id
        uuid conversation_id
        datetime created_at
        uuid id PK
        string message
        string moderation_status
        datetime read_at
        uuid sender_id
    }
    edhrec_card_snapshots {
        string card_name
        string category
        string commander_name
        string commander_slug
        datetime created_at
        string id PK
        string inclusion
        number num_decks
        datetime snapshot_date
        string synergy
    }
    email_verification_tokens {
        datetime consumed_at
        datetime created_at
        datetime expires_at
        uuid id PK
        string token_hash
        uuid user_id
    }
    external_commander_meta_candidates {
        string archetype
        string card_list
        string color_identity
        string commander_name
        datetime created_at
        string deck_name
        string format
        uuid id PK
        string imported_by
        boolean is_commander_legal
        string legal_status
        string partner_commander_name
        string placement
        datetime promoted_to_meta_decks_at
        json research_payload
        string source_host
        string source_name
        string source_url
        string subformat
        datetime updated_at
        string validation_notes
        string validation_status
    }
    format_staples {
        string archetype
        string card_name
        string category
        string color_identity
        datetime created_at
        number edhrec_rank
        string format
        uuid id PK
        boolean is_banned
        datetime last_synced_at
        uuid scryfall_id
    }
    meta_decks {
        string archetype
        string card_list
        string commander_name
        datetime created_at
        string format
        uuid id PK
        string partner_commander_name
        string placement
        string shell_label
        string source_url
        string strategy_archetype
    }
    ml_prompt_feedback {
        string archetype
        string cards_accepted
        string cards_rejected
        string commander_name
        datetime created_at
        uuid deck_id
        number effectiveness_score
        uuid id PK
        string prompt_version
        string user_comment
        uuid user_id
    }
    moderation_actions {
        string action
        datetime created_at
        json evidence
        uuid id PK
        uuid moderator_user_id
        string rationale
        uuid report_id
        string request_id
    }
    notifications {
        string body
        datetime created_at
        uuid id PK
        datetime read_at
        uuid reference_id
        string title
        string type
        uuid user_id
    }
    optimize_rejection_penalties {
        string archetype
        string card_name
        string card_name_normalized
        string commander_name
        string commander_name_normalized
        string evidence
        string function
        number penalty
        number reject_count
        string source
        datetime updated_at
    }
    password_reset_tokens {
        datetime consumed_at
        datetime created_at
        datetime expires_at
        uuid id PK
        string token_hash
        uuid user_id
    }
    post_game_notes {
        datetime created_at
        uuid deck_id
        string deck_snapshot_hash
        datetime deck_version_at
        datetime deleted_at
        string id PK
        json issues
        string notes
        json performed_well
        string play_session_id
        string result
        number revision
        datetime session_ended_at
        datetime session_started_at
        string table_level
        json underperformed
        datetime updated_at
        uuid user_id
    }
    post_game_sync_state {
        number id PK
        datetime watermark
    }
    price_history {
        uuid card_id
        datetime created_at
        uuid id PK
        datetime price_date
        number price_usd
        number price_usd_foil
    }
    privacy_deleted_deck_tombstones {
        string deck_token
        datetime deleted_at
        number key_version
    }
    privacy_keyring {
        datetime created_at
        string hmac_key
        boolean is_active
        number key_version PK
    }
    rate_limit_events {
        string bucket
        datetime created_at
        uuid id PK
        string identifier
    }
    rules {
        string category
        datetime created_at
        string description
        uuid id PK
        string title
    }
    schema_migrations {
        datetime executed_at
        string name
        string version PK
    }
    sets {
        string block
        string code PK
        datetime created_at
        boolean is_foreign_only
        boolean is_online_only
        string name
        datetime release_date
        string type
        datetime updated_at
    }
    shared_deck_reports {
        datetime created_at
        uuid deck_id
        string description
        datetime expires_at
        string id PK
        boolean is_public
        json payload
        string title
        datetime updated_at
        uuid user_id
    }
    sync_log {
        string error_message
        datetime finished_at
        string format
        uuid id PK
        number records_deleted
        number records_inserted
        number records_updated
        datetime started_at
        string status
        string sync_type
    }
    sync_state {
        string key PK
        datetime updated_at
        string value
    }
    trade_items {
        number agreed_price
        uuid binder_item_id
        string direction
        uuid id PK
        uuid owner_id
        number quantity
        uuid trade_offer_id
    }
    trade_messages {
        string attachment_type
        string attachment_url
        string client_request_id
        datetime created_at
        uuid id PK
        string message
        string moderation_status
        uuid sender_id
        uuid trade_offer_id
    }
    trade_offers {
        datetime created_at
        string delivery_method
        uuid id PK
        string message
        number payment_amount
        string payment_currency
        string payment_method
        uuid receiver_id
        uuid sender_id
        string status
        string tracking_code
        string type
        datetime updated_at
    }
    trade_status_history {
        uuid changed_by
        datetime created_at
        uuid id PK
        string new_status
        string notes
        string old_status
        uuid trade_offer_id
    }
    user_binder_items {
        uuid card_id
        string condition
        datetime created_at
        string currency
        boolean for_sale
        boolean for_trade
        uuid id PK
        boolean is_foil
        string language
        string list_type
        string notes
        number price
        number quantity
        datetime updated_at
        uuid user_id
    }
    user_block_events {
        string action
        uuid actor_user_id
        datetime created_at
        uuid id PK
        string reason
        string request_id
        uuid target_user_id
    }
    user_blocks {
        uuid blocked_id
        uuid blocker_id
        datetime created_at
        string reason
    }
    user_follows {
        datetime created_at
        uuid follower_id
        uuid following_id
        uuid id PK
    }
    user_plans {
        string plan_name
        datetime renews_at
        datetime started_at
        string status
        datetime updated_at
        uuid user_id PK
    }
    users {
        number auth_version
        string avatar_url
        string binder_visibility
        datetime created_at
        datetime deleted_at
        string display_name
        string email
        datetime email_verified_at
        string fcm_token
        uuid id PK
        string location_city
        string location_state
        string location_visibility
        string message_visibility
        datetime password_changed_at
        string password_hash
        datetime privacy_accepted_at
        string privacy_version
        string profile_visibility
        datetime terms_accepted_at
        string terms_version
        string trade_notes
        string trade_notes_visibility
        string trade_visibility
    }
```

Tabelas: 73; views: 6; migrations: 51 (latest `051`).
