-- Migration: Remove unused write-only tables
-- Date: 2026-05-29
-- Reason: These tables have INSERTs but zero SELECT consumers in production

-- 1. deck_matchups: simulate-matchup writes but never reads
DROP TABLE IF EXISTS deck_matchups;

-- 2. deck_weakness_reports: weakness-analysis writes but never reads
DROP TABLE IF EXISTS deck_weakness_reports;

-- 3. ml_prompt_feedback: only used for COUNT, no actual feedback loop
DROP TABLE IF EXISTS ml_prompt_feedback;

-- Note: commander_reference_decks and commander_reference_deck_cards are
-- intentionally kept as audit lineage for the Commander Reference Corpus.
-- They are raw corpus data that feeds commander_reference_deck_analysis.
